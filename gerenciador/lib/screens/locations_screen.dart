import 'dart:async';

import 'package:flutter/material.dart';

import '../models/clinic_location.dart';
import '../models/pagination.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_select.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/paginated_controls.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _cityFilter = TextEditingController();
  final _streetFilter = TextEditingController();
  Timer? _debounce;
  String _lastCityFilterText = '';
  String _lastStreetFilterText = '';

  List<ClinicLocation> _locations = const [];
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
    _cityFilter.addListener(_onFilterChanged);
    _streetFilter.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityFilter.dispose();
    _streetFilter.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final currentCity = _cityFilter.text;
    final currentStreet = _streetFilter.text;

    if (currentCity == _lastCityFilterText && currentStreet == _lastStreetFilterText) {
      return;
    }

    _lastCityFilterText = currentCity;
    _lastStreetFilterText = currentStreet;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadLocations(page: 1);
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDoctors(),
      _loadLocations(),
    ]);
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await LocationService.instance.getDoctors();
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

  Future<void> _loadLocations({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) {
        _page = page;
      }
    });

    try {
      final response = await LocationService.instance.getAll(
        page: _page,
        city: _cityFilter.text,
        street: _streetFilter.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locations = response.data;
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

  Future<void> _openLocationModal({ClinicLocation? editing}) async {
    String selectedDoctorId = editing?.doctorId ?? (_doctors.isNotEmpty ? _doctors.first.id : '');
    final zipCodeController = TextEditingController(text: editing?.zipCode ?? '');
    final streetController = TextEditingController(text: editing?.street ?? '');
    final numberController = TextEditingController(text: editing?.streetNumber ?? '');
    final neighborhoodController = TextEditingController(text: editing?.neighborhood ?? '');
    final cityController = TextEditingController(text: editing?.city ?? '');
    final complementController = TextEditingController(text: editing?.addressComplement ?? '');
    String? localError;

    await showAppModal<void>(
      context,
      title: editing == null ? 'Criar local' : 'Editar local',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSelect<String>(
                label: 'Médico *',
                value: selectedDoctorId.isEmpty ? null : selectedDoctorId,
                onChanged: (value) => setModalState(() => selectedDoctorId = value ?? ''),
                items: _doctors
                    .map(
                      (doctor) => DropdownMenuItem(
                        value: doctor.id,
                        child: Text(doctor.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              AppInput(
                controller: zipCodeController,
                label: 'CEP *',
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length <= 8) {
                    zipCodeController.value = TextEditingValue(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              AppInput(controller: streetController, label: 'Rua *'),
              const SizedBox(height: 10),
              AppInput(controller: numberController, label: 'Número *'),
              const SizedBox(height: 10),
              AppInput(controller: neighborhoodController, label: 'Bairro'),
              const SizedBox(height: 10),
              AppInput(controller: cityController, label: 'Cidade'),
              const SizedBox(height: 10),
              AppInput(controller: complementController, label: 'Complemento'),
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
                      final zipCode = zipCodeController.text.trim();
                      final street = streetController.text.trim();
                      final number = numberController.text.trim();

                      if (selectedDoctorId.isEmpty) {
                        setModalState(() => localError = 'Selecione um médico');
                        return;
                      }

                      if (zipCode.length != 8) {
                        setModalState(() => localError = 'CEP deve conter 8 dígitos');
                        return;
                      }

                      if (street.isEmpty || number.isEmpty) {
                        setModalState(() => localError = 'Rua e número são obrigatórios');
                        return;
                      }

                      final payload = {
                        'doctorId': selectedDoctorId,
                        'zipCode': zipCode,
                        'street': street,
                        'streetNumber': number,
                        if (neighborhoodController.text.trim().isNotEmpty)
                          'neighborhood': neighborhoodController.text.trim(),
                        if (cityController.text.trim().isNotEmpty) 'city': cityController.text.trim(),
                        if (complementController.text.trim().isNotEmpty)
                          'addressComplement': complementController.text.trim(),
                      };

                      try {
                        if (editing == null) {
                          await LocationService.instance.create(payload);
                        } else {
                          await LocationService.instance.update(editing.id, payload);
                        }

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        setState(() {
                          _success = editing == null
                              ? 'Local criado com sucesso!'
                              : 'Local atualizado com sucesso!';
                        });
                        _loadLocations(page: 1);
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

    zipCodeController.dispose();
    streetController.dispose();
    numberController.dispose();
    neighborhoodController.dispose();
    cityController.dispose();
    complementController.dispose();
  }

  Future<void> _openRemoveModal(ClinicLocation location) async {
    await showAppModal<void>(
      context,
      title: 'Remover local',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deseja realmente remover o local ${location.street}, ${location.streetNumber}?'),
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
                      await LocationService.instance.delete(location.id);
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _success = 'Local removido com sucesso!');
                      _loadLocations(page: _page);
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
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              title: 'Novo local',
              round: true,
              icon: Icons.add,
              onPressed: () => _openLocationModal(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: AppInput(
                  controller: _cityFilter,
                  label: 'Cidade',
                  hintText: 'Digite o nome da cidade',
                ),
              ),
              SizedBox(
                width: 220,
                child: AppInput(
                  controller: _streetFilter,
                  label: 'Rua',
                  hintText: 'Digite o nome da rua',
                ),
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
                        DataColumn(label: Text('Médico')),
                        DataColumn(label: Text('CEP')),
                        DataColumn(label: Text('Endereço')),
                        DataColumn(label: Text('Cidade')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: _locations
                          .map(
                            (location) => DataRow(
                              cells: [
                                DataCell(Text(doctorNames[location.doctorId] ?? '-')),
                                DataCell(Text(location.zipCode)),
                                DataCell(Text('${location.street}, ${location.streetNumber}')),
                                DataCell(Text(location.city ?? '-')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _openLocationModal(editing: location),
                                        icon: const Icon(Icons.edit, color: Color(0xFF1AAB67)),
                                      ),
                                      IconButton(
                                        onPressed: () => _openRemoveModal(location),
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
              onPageChange: (page) => _loadLocations(page: page),
            ),
          ],
        ],
      ),
    );
  }
}
