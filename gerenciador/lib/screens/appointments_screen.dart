import 'dart:async';

import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/pagination.dart';
import '../models/patient.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/appointment_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_select.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/paginated_controls.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _doctorFilter = TextEditingController();
  final _patientFilter = TextEditingController();
  Timer? _debounce;
  String _lastDoctorFilterText = '';
  String _lastPatientFilterText = '';

  List<Appointment> _appointments = const [];
  List<AppUser> _doctors = const [];
  List<Patient> _patients = const [];
  PaginationMeta? _pagination;
  int _page = 1;
  bool _loading = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _doctorFilter.addListener(_onFilterChanged);
    _patientFilter.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _doctorFilter.dispose();
    _patientFilter.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final currentDoctor = _doctorFilter.text;
    final currentPatient = _patientFilter.text;

    if (currentDoctor == _lastDoctorFilterText && currentPatient == _lastPatientFilterText) {
      return;
    }

    _lastDoctorFilterText = currentDoctor;
    _lastPatientFilterText = currentPatient;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadAppointments(page: 1);
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadAppointments(),
      _loadReferences(),
    ]);
  }

  Future<void> _loadReferences() async {
    try {
      final values = await Future.wait<dynamic>([
        AppointmentService.instance.getDoctors(),
        AppointmentService.instance.getPatients(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _doctors = values[0] as List<AppUser>;
        _patients = values[1] as List<Patient>;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    }
  }

  Future<void> _loadAppointments({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) {
        _page = page;
      }
    });

    try {
      final response = await AppointmentService.instance.getAll(
        page: _page,
        doctorName: _doctorFilter.text,
        patientName: _patientFilter.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = response.data;
        _pagination = response.pagination;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _openAppointmentModal({Appointment? editing}) async {
    final fields = <String, TextEditingController>{
      'doctorId': TextEditingController(text: editing?.doctorId ?? ''),
      'patientId': TextEditingController(text: editing?.patientId ?? ''),
      'appointmentDate': TextEditingController(text: editing?.appointmentDate.split('T').first ?? ''),
      'age': TextEditingController(text: editing?.age?.toString() ?? ''),
      'sexualOrientation': TextEditingController(text: editing?.sexualOrientation ?? ''),
      'maritalStatus': TextEditingController(text: editing?.maritalStatus ?? ''),
      'concordantPartner': TextEditingController(
        text: editing?.concordantPartner == null ? '' : editing!.concordantPartner! ? 'true' : 'false',
      ),
      'occupation': TextEditingController(text: editing?.occupation ?? ''),
      'comorbidities': TextEditingController(text: editing?.comorbidities ?? ''),
      'previousDiseases': TextEditingController(text: editing?.previousDiseases ?? ''),
      'allergy': TextEditingController(text: editing?.allergy ?? ''),
      'surgeries': TextEditingController(text: editing?.surgeries ?? ''),
      'medicationUse': TextEditingController(text: editing?.medicationUse ?? ''),
      'hivDiagnosisDate': TextEditingController(text: editing?.hivDiagnosisDate?.split('T').first ?? ''),
      'cardiovascularRisk': TextEditingController(text: editing?.cardiovascularRisk ?? ''),
      'neoplasmScreening': TextEditingController(text: editing?.neoplasmScreening ?? ''),
      'coinfectionScreening': TextEditingController(text: editing?.coinfectionScreening ?? ''),
      'immunizations': TextEditingController(text: editing?.immunizations ?? ''),
      'notes': TextEditingController(text: editing?.notes ?? ''),
      'zipCode': TextEditingController(text: editing?.zipCode ?? ''),
      'street': TextEditingController(text: editing?.street ?? ''),
      'streetNumber': TextEditingController(text: editing?.streetNumber ?? ''),
      'neighborhood': TextEditingController(text: editing?.neighborhood ?? ''),
      'city': TextEditingController(text: editing?.city ?? ''),
      'addressComplement': TextEditingController(text: editing?.addressComplement ?? ''),
      'currentArt': TextEditingController(text: editing?.currentArt ?? ''),
      'adherence': TextEditingController(text: editing?.adherence ?? ''),
      'lastViralLoad': TextEditingController(text: editing?.lastViralLoad?.split('T').first ?? ''),
      'cd4Nadir': TextEditingController(text: editing?.cd4Nadir ?? ''),
      'virologicalStatus': TextEditingController(text: editing?.virologicalStatus ?? ''),
      'currentRegimen': TextEditingController(text: editing?.currentRegimen ?? ''),
      'regimenStartDate': TextEditingController(text: editing?.regimenStartDate?.split('T').first ?? ''),
      'previousRegimens': TextEditingController(text: editing?.previousRegimens ?? ''),
      'changeReason': TextEditingController(text: editing?.changeReason ?? ''),
    };

    String? localError;

    Widget textField(String key, String label, {int maxLines = 1}) {
      return AppInput(
        controller: fields[key]!,
        label: label,
        maxLines: maxLines,
      );
    }

    await showAppModal<void>(
      context,
      title: editing == null ? 'Criar consulta' : 'Editar consulta',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final doctorId = fields['doctorId']!.text;
          final patientId = fields['patientId']!.text;
          final maritalStatus = fields['maritalStatus']!.text;
          final immunizations = fields['immunizations']!.text;
          final adherence = fields['adherence']!.text;
          final concordantPartner = fields['concordantPartner']!.text;

          List<DropdownMenuItem<String>> mapItems(List<(String, String)> values) {
            return values
                .map((value) => DropdownMenuItem(value: value.$1, child: Text(value.$2)))
                .toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 320,
                    child: AppSelect<String>(
                      label: 'Médico *',
                      value: doctorId.isEmpty ? null : doctorId,
                      onChanged: (value) => setModalState(() => fields['doctorId']!.text = value ?? ''),
                      items: _doctors
                          .map((doctor) => DropdownMenuItem(value: doctor.id, child: Text(doctor.name)))
                          .toList(),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: AppSelect<String>(
                      label: 'Paciente *',
                      value: patientId.isEmpty ? null : patientId,
                      onChanged: (value) => setModalState(() => fields['patientId']!.text = value ?? ''),
                      items: _patients
                          .map((patient) => DropdownMenuItem(value: patient.id, child: Text(patient.name)))
                          .toList(),
                    ),
                  ),
                  SizedBox(width: 220, child: textField('appointmentDate', 'Data da consulta *')),
                  SizedBox(width: 100, child: textField('age', 'Idade')),
                  SizedBox(width: 220, child: textField('sexualOrientation', 'Orientação sexual')),
                  SizedBox(
                    width: 220,
                    child: AppSelect<String>(
                      label: 'Estado civil',
                      value: maritalStatus.isEmpty ? null : maritalStatus,
                      onChanged: (value) => setModalState(() => fields['maritalStatus']!.text = value ?? ''),
                      items: mapItems(const [
                        ('SINGLE', 'Solteiro(a)'),
                        ('MARRIED', 'Casado(a)'),
                        ('DIVORCED', 'Divorciado(a)'),
                        ('WIDOWED', 'Viúvo(a)'),
                        ('STABLE_UNION', 'União estável'),
                        ('OTHER', 'Outro'),
                      ]),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: AppSelect<String>(
                      label: 'Parceiro concordante',
                      value: concordantPartner.isEmpty ? null : concordantPartner,
                      onChanged: (value) => setModalState(() => fields['concordantPartner']!.text = value ?? ''),
                      items: mapItems(const [('true', 'Sim'), ('false', 'Não')]),
                    ),
                  ),
                  SizedBox(width: 220, child: textField('occupation', 'Ocupação')),
                  SizedBox(width: 220, child: textField('hivDiagnosisDate', 'Data diagnóstico HIV')),
                  SizedBox(
                    width: 220,
                    child: AppSelect<String>(
                      label: 'Imunizações',
                      value: immunizations.isEmpty ? null : immunizations,
                      onChanged: (value) => setModalState(() => fields['immunizations']!.text = value ?? ''),
                      items: mapItems(const [
                        ('COMPLETE', 'Completa'),
                        ('INCOMPLETE', 'Incompleta'),
                        ('NOT_INFORMED', 'Não informado'),
                      ]),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: AppSelect<String>(
                      label: 'Adesão',
                      value: adherence.isEmpty ? null : adherence,
                      onChanged: (value) => setModalState(() => fields['adherence']!.text = value ?? ''),
                      items: mapItems(const [
                        ('HIGH', 'Alta'),
                        ('MEDIUM', 'Média'),
                        ('LOW', 'Baixa'),
                        ('NOT_INFORMED', 'Não informado'),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              textField('comorbidities', 'Comorbidades', maxLines: 2),
              const SizedBox(height: 10),
              textField('previousDiseases', 'Doenças anteriores', maxLines: 2),
              const SizedBox(height: 10),
              textField('allergy', 'Alergias', maxLines: 2),
              const SizedBox(height: 10),
              textField('surgeries', 'Cirurgias', maxLines: 2),
              const SizedBox(height: 10),
              textField('medicationUse', 'Uso de medicação', maxLines: 2),
              const SizedBox(height: 10),
              textField('currentArt', 'ART atual'),
              const SizedBox(height: 10),
              textField('lastViralLoad', 'Última carga viral'),
              const SizedBox(height: 10),
              textField('virologicalStatus', 'Status virológico'),
              const SizedBox(height: 10),
              textField('currentRegimen', 'Regime atual'),
              const SizedBox(height: 10),
              textField('regimenStartDate', 'Início do regime'),
              const SizedBox(height: 10),
              textField('previousRegimens', 'Regimes anteriores', maxLines: 2),
              const SizedBox(height: 10),
              textField('changeReason', 'Razão de mudança', maxLines: 2),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: 180, child: textField('zipCode', 'CEP')),
                  SizedBox(width: 260, child: textField('street', 'Rua')),
                  SizedBox(width: 120, child: textField('streetNumber', 'Número')),
                  SizedBox(width: 220, child: textField('neighborhood', 'Bairro')),
                  SizedBox(width: 220, child: textField('city', 'Cidade')),
                  SizedBox(width: 260, child: textField('addressComplement', 'Complemento')),
                ],
              ),
              const SizedBox(height: 10),
              textField('notes', 'Avaliação Clínica Atual', maxLines: 3),
              if (localError != null) ...[
                const SizedBox(height: 10),
                Text(localError!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    title: 'Cancelar',
                    round: true,
                    color: Colors.red,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    title: 'Salvar',
                    round: true,
                    color: const Color(0xFF2E7D32),
                    onPressed: () async {
                      final doctor = fields['doctorId']!.text.trim();
                      final patient = fields['patientId']!.text.trim();
                      final appointmentDate = fields['appointmentDate']!.text.trim();

                      if (doctor.isEmpty || patient.isEmpty) {
                        setModalState(() => localError = 'Selecione médico e paciente');
                        return;
                      }

                      if (appointmentDate.isEmpty) {
                        setModalState(() => localError = 'Data da consulta é obrigatória');
                        return;
                      }

                      final zip = fields['zipCode']!.text.trim();
                      if (zip.isNotEmpty && zip.length != 8) {
                        setModalState(() => localError = 'CEP deve conter 8 dígitos');
                        return;
                      }

                      String? optionalDate(String key) {
                        final raw = fields[key]!.text.trim();
                        if (raw.isEmpty) {
                          return null;
                        }
                        return DateTime.parse(raw).toIso8601String();
                      }

                      String? optionalText(String key) {
                        final raw = fields[key]!.text.trim();
                        return raw.isEmpty ? null : raw;
                      }

                      final payload = {
                        'doctorId': doctor,
                        'patientId': patient,
                        'appointmentDate': DateTime.parse(appointmentDate).toIso8601String(),
                        'age': int.tryParse(fields['age']!.text.trim()),
                        'sexualOrientation': optionalText('sexualOrientation'),
                        'maritalStatus': optionalText('maritalStatus'),
                        'concordantPartner': fields['concordantPartner']!.text.trim().isEmpty
                            ? null
                            : fields['concordantPartner']!.text.trim() == 'true',
                        'occupation': optionalText('occupation'),
                        'comorbidities': optionalText('comorbidities'),
                        'previousDiseases': optionalText('previousDiseases'),
                        'allergy': optionalText('allergy'),
                        'surgeries': optionalText('surgeries'),
                        'medicationUse': optionalText('medicationUse'),
                        'hivDiagnosisDate': optionalDate('hivDiagnosisDate'),
                        'cardiovascularRisk': optionalText('cardiovascularRisk'),
                        'neoplasmScreening': optionalText('neoplasmScreening'),
                        'coinfectionScreening': optionalText('coinfectionScreening'),
                        'immunizations': optionalText('immunizations'),
                        'notes': optionalText('notes'),
                        'zipCode': optionalText('zipCode')?.replaceAll(RegExp(r'\D'), ''),
                        'street': optionalText('street'),
                        'streetNumber': optionalText('streetNumber'),
                        'neighborhood': optionalText('neighborhood'),
                        'city': optionalText('city'),
                        'addressComplement': optionalText('addressComplement'),
                        'currentArt': optionalText('currentArt'),
                        'adherence': optionalText('adherence'),
                        'lastViralLoad': optionalDate('lastViralLoad'),
                        'cd4Nadir': optionalText('cd4Nadir'),
                        'virologicalStatus': optionalText('virologicalStatus'),
                        'currentRegimen': optionalText('currentRegimen'),
                        'regimenStartDate': optionalDate('regimenStartDate'),
                        'previousRegimens': optionalText('previousRegimens'),
                        'changeReason': optionalText('changeReason'),
                      };

                      try {
                        if (editing == null) {
                          await AppointmentService.instance.create(payload);
                        } else {
                          await AppointmentService.instance.update(editing.id, payload);
                        }

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        setState(() {
                          _success = editing == null
                              ? 'Consulta criada com sucesso!'
                              : 'Consulta atualizada com sucesso!';
                        });
                        _loadAppointments(page: 1);
                      } on FormatException {
                        setModalState(() => localError = 'Data inválida. Use YYYY-MM-DD');
                      } on ApiException catch (error) {
                        setModalState(() => localError = error.message);
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    for (final controller in fields.values) {
      controller.dispose();
    }
  }

  Future<void> _openRemoveModal(Appointment appointment) async {
    await showAppModal<void>(
      context,
      title: 'Remover consulta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deseja realmente remover a consulta de ${appointment.appointmentDate.split('T').first}?'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                child: AppButton(
                  title: 'Sim',
                  round: true,
                  color: const Color(0xFF428F01),
                  onPressed: () async {
                    try {
                      await AppointmentService.instance.delete(appointment.id);
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _success = 'Consulta removida com sucesso!');
                      _loadAppointments(page: _page);
                    } on ApiException catch (error) {
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _error = error.message);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: AppButton(
                  title: 'Não',
                  round: true,
                  color: Colors.red,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorNames = {for (final doctor in _doctors) doctor.id: doctor.name};
    final patientNames = {for (final patient in _patients) patient.id: patient.name};

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 220,
                      child: AppInput(
                        controller: _doctorFilter,
                        label: 'Doutor',
                        hintText: 'Digite o nome do doutor',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppInput(
                        controller: _patientFilter,
                        label: 'Paciente',
                        hintText: 'Digite o nome do paciente',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                title: 'Nova consulta',
                round: true,
                icon: Icons.add,
                onPressed: () => _openAppointmentModal(),
              ),
            ],
          ),
          if (_success != null) ...[
            const SizedBox(height: 10),
            FeedbackBanner(message: _success!, success: true),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            FeedbackBanner(message: _error!, success: false),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: AppLoader(size: 50))
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Doutor')),
                        DataColumn(label: Text('Paciente')),
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Cidade')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: _appointments
                          .map(
                            (appointment) => DataRow(
                              cells: [
                                DataCell(Text(doctorNames[appointment.doctorId] ?? '-')),
                                DataCell(Text(patientNames[appointment.patientId] ?? '-')),
                                DataCell(Text(appointment.appointmentDate.split('T').first)),
                                DataCell(Text(appointment.city ?? '-')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _openAppointmentModal(editing: appointment),
                                        icon: const Icon(Icons.edit, color: Color(0xFF1AAB67)),
                                      ),
                                      IconButton(
                                        onPressed: () => _openRemoveModal(appointment),
                                        icon: const Icon(Icons.delete, color: Color(0xFFED1B2D)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          if (_pagination != null && _pagination!.totalPages >= 2) ...[
            const SizedBox(height: 10),
            PaginatedControls(
              pagination: _pagination!,
              onPageChange: (page) => _loadAppointments(page: page),
            ),
          ],
        ],
      ),
    );
  }
}
