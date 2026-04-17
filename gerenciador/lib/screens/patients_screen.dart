import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pagination.dart';
import '../models/patient.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/patient_service.dart';
import '../utils/masking.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_select.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/paginated_controls.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _nameFilter = TextEditingController();
  final _cpfFilter = TextEditingController();
  Timer? _debounce;
  String _lastNameFilterText = '';
  String _lastCpfFilterText = '';

  List<Patient> _patients = const [];
  List<AppUser> _doctors = const [];
  PaginationMeta? _pagination;
  int _page = 1;
  bool _loading = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _nameFilter.addListener(_onFilterChanged);
    _cpfFilter.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFilter.dispose();
    _cpfFilter.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final currentName = _nameFilter.text;
    final currentCpf = _cpfFilter.text;

    if (currentName == _lastNameFilterText && currentCpf == _lastCpfFilterText) {
      return;
    }

    _lastNameFilterText = currentName;
    _lastCpfFilterText = currentCpf;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadPatients(page: 1);
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDoctors(),
      _loadPatients(),
    ]);
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await PatientService.instance.getDoctors();
      if (!mounted) {
        return;
      }
      setState(() => _doctors = doctors);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    }
  }

  Future<void> _loadPatients({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) {
        _page = page;
      }
    });

    try {
      final response = await PatientService.instance.getAll(
        page: _page,
        name: _nameFilter.text,
        cpf: _cpfFilter.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _patients = response.data;
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

  Future<void> _openPatientModal({Patient? editing}) async {
    final doctorIdController = TextEditingController(text: editing?.doctorId ?? (_doctors.isNotEmpty ? _doctors.first.id : ''));
    final nameController = TextEditingController(text: editing?.name ?? '');
    final cpfController = TextEditingController(text: editing == null ? '' : formatCpf(editing.cpf));
    final lastAppointmentController = TextEditingController(
      text: editing?.lastAppointment?.split('T').first ?? '',
    );
    String? localError;

    await showAppModal<void>(
      context,
      title: editing == null ? 'Criar paciente' : 'Editar paciente',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSelect<String>(
                label: 'Médico *',
                value: doctorIdController.text.isEmpty ? null : doctorIdController.text,
                onChanged: (value) {
                  setModalState(() => doctorIdController.text = value ?? '');
                },
                items: _doctors
                    .map(
                      (doctor) => DropdownMenuItem<String>(
                        value: doctor.id,
                        child: Text(doctor.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              AppInput(controller: nameController, label: 'Nome *'),
              const SizedBox(height: 10),
              AppInput(
                controller: cpfController,
                label: 'CPF *',
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length <= 11) {
                    cpfController.value = TextEditingValue(
                      text: formatCpf(digits),
                      selection: TextSelection.collapsed(offset: formatCpf(digits).length),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              AppInput(
                controller: lastAppointmentController,
                label: 'Última consulta (YYYY-MM-DD)',
              ),
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
                      final doctorId = doctorIdController.text.trim();
                      final name = nameController.text.trim();
                      final cpfDigits = cpfController.text.replaceAll(RegExp(r'\D'), '');

                      if (doctorId.isEmpty) {
                        setModalState(() => localError = 'Selecione um médico');
                        return;
                      }

                      if (name.isEmpty) {
                        setModalState(() => localError = 'Informe o nome do paciente');
                        return;
                      }

                      if (cpfDigits.length != 11) {
                        setModalState(() => localError = 'CPF deve conter 11 dígitos');
                        return;
                      }

                      final payload = {
                        'doctorId': doctorId,
                        'name': name,
                        'cpf': cpfDigits,
                        if (lastAppointmentController.text.trim().isNotEmpty)
                          'lastAppointment': DateTime.parse(lastAppointmentController.text.trim()).toIso8601String(),
                      };

                      try {
                        if (editing == null) {
                          await PatientService.instance.create(payload);
                        } else {
                          await PatientService.instance.update(editing.id, payload);
                        }

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        setState(() {
                          _success = editing == null
                              ? 'Paciente criado com sucesso!'
                              : 'Paciente atualizado com sucesso!';
                        });
                        _loadPatients(page: 1);
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

    doctorIdController.dispose();
    nameController.dispose();
    cpfController.dispose();
    lastAppointmentController.dispose();
  }

  Future<void> _openRemoveModal(Patient patient) async {
    await showAppModal<void>(
      context,
      title: 'Remover paciente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deseja realmente remover o paciente ${patient.name}?'),
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
                      await PatientService.instance.delete(patient.id);
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _success = 'Paciente removido com sucesso!');
                      _loadPatients(page: _page);
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
    final doctorNames = {
      for (final doctor in _doctors) doctor.id: doctor.name,
    };

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
                      width: 260,
                      child: AppInput(
                        controller: _nameFilter,
                        label: 'Nome',
                        hintText: 'Digite o nome do paciente',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppInput(
                        controller: _cpfFilter,
                        label: 'CPF',
                        hintText: 'Digite o CPF',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                title: 'Novo paciente',
                round: true,
                icon: Icons.add,
                onPressed: () => _openPatientModal(),
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
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('CPF')),
                        DataColumn(label: Text('Última consulta')),
                        DataColumn(label: Text('Médico')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: _patients
                          .map(
                            (patient) => DataRow(
                              cells: [
                                DataCell(Text(maskNameForTable(patient.name))),
                                DataCell(Text(maskCpfForTable(patient.cpf))),
                                DataCell(Text(toDateOnly(patient.lastAppointment))),
                                DataCell(Text(doctorNames[patient.doctorId] ?? '-')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _openPatientModal(editing: patient),
                                        icon: const Icon(Icons.edit, color: Color(0xFF1AAB67)),
                                      ),
                                      IconButton(
                                        onPressed: () => _openRemoveModal(patient),
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
          if (_pagination != null && (_pagination!.totalPages >= 2)) ...[
            const SizedBox(height: 10),
            PaginatedControls(
              pagination: _pagination!,
              onPageChange: (page) => _loadPatients(page: page),
            ),
          ],
        ],
      ),
    );
  }
}
