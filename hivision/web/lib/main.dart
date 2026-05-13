import 'dart:convert';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kHasLoggedIn = 'has_logged_in';
const _kLoggedUserJson = 'logged_user_json';

void main() {
  runApp(const HivisionWebApp());
}

class AppColors {
  static const wine = Color(0xFF760000);
  static const lightBackground = Color(0xFFF3F3F3);
  static const sidePanel = Color(0xFFD9D0D0);
  static const paleRose = Color(0xFFDDCACA);
  static const textDark = Color(0xFF5C0000);
}

class ApiPatient {
  ApiPatient({
    required this.id,
    required this.name,
    required this.cpf,
    this.doctorId = '',
    this.zipCode = '',
    this.street = '',
    this.streetNumber = '',
    this.neighborhood = '',
    this.city = '',
    this.addressComplement = '',
    this.age,
    this.birthDate,
    this.maritalStatus = '',
    this.profession = '',
    this.previousDiseases = '',
    this.allergies = '',
    this.medications = '',
    this.sexualOrientation = '',
    this.partnerSerologicalStatus = '',
    this.cardiovascularRisk = '',
    this.neoplasmScreening = '',
    this.coinfectionScreening = '',
    this.immunizations = '',
    this.boneHealth = '',
    this.hivDiagnosisDate,
    this.cd4Initial,
    this.cd4InitialDate,
    this.cd4Current,
    this.cd4CurrentDate,
    this.currentARV = '',
    this.initialViralLoad,
    this.initialViralLoadDate,
    this.virologicalStatus = '',
    this.treatmentAdherence = '',
    this.therapeuticHistory = '',
    this.surgeries = '',
    this.comorbidities = '',
  });

  final String id;
  final String name;
  final String cpf;
  final String doctorId;
  final String zipCode;
  final String street;
  final String streetNumber;
  final String neighborhood;
  final String city;
  final String addressComplement;
  final int? age;
  final DateTime? birthDate;
  final String maritalStatus;
  final String profession;
  final String previousDiseases;
  final String allergies;
  final String medications;
  final String sexualOrientation;
  final String partnerSerologicalStatus;
  final String cardiovascularRisk;
  final String neoplasmScreening;
  final String coinfectionScreening;
  final String immunizations;
  final String boneHealth;
  final DateTime? hivDiagnosisDate;
  final int? cd4Initial;
  final DateTime? cd4InitialDate;
  final int? cd4Current;
  final DateTime? cd4CurrentDate;
  final String currentARV;
  final int? initialViralLoad;
  final DateTime? initialViralLoadDate;
  final String virologicalStatus;
  final String treatmentAdherence;
  final String therapeuticHistory;
  final String surgeries;
  final String comorbidities;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ApiPatient.fromJson(Map<String, dynamic> json) {
    return ApiPatient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Paciente',
      cpf: json['cpf']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      streetNumber: json['streetNumber']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      addressComplement: json['addressComplement']?.toString() ?? '',
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      birthDate: json['birthDate'] != null ? _parseDate(json['birthDate']) : null,
      maritalStatus: json['maritalStatus']?.toString() ?? '',
      profession: json['profession']?.toString() ?? '',
      previousDiseases: json['previousDiseases']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      medications: json['medications']?.toString() ?? '',
      sexualOrientation: json['sexualOrientation']?.toString() ?? '',
      partnerSerologicalStatus: json['partnerSerologicalStatus']?.toString() ?? '',
      cardiovascularRisk: json['cardiovascularRisk']?.toString() ?? '',
      neoplasmScreening: json['neoplasmScreening']?.toString() ?? '',
      coinfectionScreening: json['coinfectionScreening']?.toString() ?? '',
      immunizations: json['immunizations']?.toString() ?? '',
      boneHealth: json['boneHealth']?.toString() ?? '',
      hivDiagnosisDate: json['hivDiagnosisDate'] != null ? _parseDate(json['hivDiagnosisDate']) : null,
      cd4Initial: json['cd4Initial'] != null ? int.tryParse(json['cd4Initial'].toString()) : null,
      cd4InitialDate: json['cd4InitialDate'] != null ? _parseDate(json['cd4InitialDate']) : null,
      cd4Current: json['cd4Current'] != null ? int.tryParse(json['cd4Current'].toString()) : null,
      cd4CurrentDate: json['cd4CurrentDate'] != null ? _parseDate(json['cd4CurrentDate']) : null,
      currentARV: json['currentARV']?.toString() ?? '',
      initialViralLoad: json['initialViralLoad'] != null ? int.tryParse(json['initialViralLoad'].toString()) : null,
      initialViralLoadDate: json['initialViralLoadDate'] != null ? _parseDate(json['initialViralLoadDate']) : null,
      virologicalStatus: json['virologicalStatus']?.toString() ?? '',
      treatmentAdherence: json['treatmentAdherence']?.toString() ?? '',
      therapeuticHistory: json['therapeuticHistory']?.toString() ?? '',
      surgeries: json['surgeries']?.toString() ?? '',
      comorbidities: json['comorbidities']?.toString() ?? '',
    );
  }
}

class ApiAppointment {
  ApiAppointment({
    required this.id,
    required this.patientId,
    required this.appointmentDate,
    required this.clinicLocationId,
    this.doctorId = '',
    this.clinicLocationName = '',
    this.city = '',
    this.age,
    this.sexualOrientation = '',
    this.maritalStatus = '',
    this.occupation = '',
    this.concordantPartner,
    this.previousDiseases = '',
    this.allergy = '',
    this.medicationUse = '',
    this.comorbidities = '',
    this.surgeries = '',
    this.hivDiagnosisDate,
    this.cd4Nadir = '',
    this.currentArt = '',
    this.virologicalStatus = '',
    this.adherence = '',
    this.currentRegimen = '',
    this.cardiovascularRisk = '',
    this.neoplasmScreening = '',
    this.coinfectionScreening = '',
    this.immunizations = '',
    this.boneHealth = '',
    this.notes = '',
  });

  final String id;
  final String patientId;
  final String clinicLocationId;
  final String clinicLocationName;
  final String doctorId;
  final String city;
  final DateTime appointmentDate;
  final int? age;
  final String sexualOrientation;
  final String maritalStatus;
  final String occupation;
  final bool? concordantPartner;
  final String previousDiseases;
  final String allergy;
  final String medicationUse;
  final String comorbidities;
  final String surgeries;
  final DateTime? hivDiagnosisDate;
  final String cd4Nadir;
  final String currentArt;
  final String virologicalStatus;
  final String adherence;
  final String currentRegimen;
  final String cardiovascularRisk;
  final String neoplasmScreening;
  final String coinfectionScreening;
  final String immunizations;
  final String boneHealth;
  final String notes;

  factory ApiAppointment.fromJson(Map<String, dynamic> json) {
    return ApiAppointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      clinicLocationId: json['clinicLocationId']?.toString() ?? '',
      clinicLocationName: json['clinicLocationName']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      appointmentDate: _parseDate(json['appointmentDate']) ?? DateTime.now(),
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      sexualOrientation: json['sexualOrientation']?.toString() ?? '',
      maritalStatus: json['maritalStatus']?.toString() ?? '',
      occupation: json['occupation']?.toString() ?? '',
      concordantPartner: json['concordantPartner'] is bool
          ? json['concordantPartner'] as bool
          : null,
      previousDiseases: json['previousDiseases']?.toString() ?? '',
      allergy: json['allergy']?.toString() ?? '',
      medicationUse: json['medicationUse']?.toString() ?? '',
      comorbidities: json['comorbidities']?.toString() ?? '',
      surgeries: json['surgeries']?.toString() ?? '',
      hivDiagnosisDate: _parseDate(json['hivDiagnosisDate']),
      cd4Nadir: json['cd4Nadir']?.toString() ?? '',
      currentArt: json['currentArt']?.toString() ?? '',
      virologicalStatus: json['virologicalStatus']?.toString() ?? '',
      adherence: json['adherence']?.toString() ?? '',
      currentRegimen: json['currentRegimen']?.toString() ?? '',
      cardiovascularRisk: json['cardiovascularRisk']?.toString() ?? '',
      neoplasmScreening: json['neoplasmScreening']?.toString() ?? '',
      coinfectionScreening: json['coinfectionScreening']?.toString() ?? '',
      immunizations: json['immunizations']?.toString() ?? '',
      boneHealth: json['boneHealth']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class ApiConsultation {
  ApiConsultation({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.consultationDate,
    this.sexualOrientation = '',
    this.maritalStatus = '',
    this.profession = '',
    this.concordantPartner = '',
    this.previousDiseases = '',
    this.allergies = '',
    this.medications = '',
    this.comorbidities = '',
    this.surgeries = '',
    this.hivStartDate,
    this.cd4Count,
    this.currentTarv = '',
    this.viralLoad,
    this.currentScheme = '',
    this.virologicalStatus = '',
    this.adherence = '',
    this.cardiovascularRisk = '',
    this.neoplasias = '',
    this.coinfections = '',
    this.immunizations = '',
    this.observations = '',
  });

  final String id;
  final String patientId;
  final String doctorId;
  final DateTime consultationDate;
  final String sexualOrientation;
  final String maritalStatus;
  final String profession;
  final String concordantPartner;
  final String previousDiseases;
  final String allergies;
  final String medications;
  final String comorbidities;
  final String surgeries;
  final DateTime? hivStartDate;
  final int? cd4Count;
  final String currentTarv;
  final int? viralLoad;
  final String currentScheme;
  final String virologicalStatus;
  final String adherence;
  final String cardiovascularRisk;
  final String neoplasias;
  final String coinfections;
  final String immunizations;
  final String observations;

  factory ApiConsultation.fromJson(Map<String, dynamic> json) {
    return ApiConsultation(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      consultationDate: _parseDate(json['consultationDate']) ?? DateTime.now(),
      sexualOrientation: json['sexualOrientation']?.toString() ?? '',
      maritalStatus: json['maritalStatus']?.toString() ?? '',
      profession: json['profession']?.toString() ?? '',
      concordantPartner: json['concordantPartner']?.toString() ?? '',
      previousDiseases: json['previousDiseases']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      medications: json['medications']?.toString() ?? '',
      comorbidities: json['comorbidities']?.toString() ?? '',
      surgeries: json['surgeries']?.toString() ?? '',
      hivStartDate: _parseDate(json['hivStartDate']),
      cd4Count: json['cd4Count'] != null ? int.tryParse(json['cd4Count'].toString()) : null,
      currentTarv: json['currentTarv']?.toString() ?? '',
      viralLoad: json['viralLoad'] != null ? int.tryParse(json['viralLoad'].toString()) : null,
      currentScheme: json['currentScheme']?.toString() ?? '',
      virologicalStatus: json['virologicalStatus']?.toString() ?? '',
      adherence: json['adherence']?.toString() ?? '',
      cardiovascularRisk: json['cardiovascularRisk']?.toString() ?? '',
      neoplasias: json['neoplasias']?.toString() ?? '',
      coinfections: json['coinfections']?.toString() ?? '',
      immunizations: json['immunizations']?.toString() ?? '',
      observations: json['observations']?.toString() ?? '',
    );
  }
}

class ApiClinicLocation {
  ApiClinicLocation({
    required this.id,
    required this.doctorId,
    this.name = '',
    this.zipCode = '',
    required this.city,
    required this.street,
    this.streetNumber = '',
    this.neighborhood = '',
    this.addressComplement = '',
  });

  final String id;
  final String doctorId;
  final String name;
  final String zipCode;
  final String city;
  final String street;
  final String streetNumber;
  final String neighborhood;
  final String addressComplement;

  String get displayName {
    if (name.isNotEmpty) return name;
    if (city.isNotEmpty && street.isNotEmpty) return '$street, $city';
    if (city.isNotEmpty) return city;
    if (street.isNotEmpty) return street;
    return 'Local $id';
  }

  factory ApiClinicLocation.fromJson(Map<String, dynamic> json) {
    return ApiClinicLocation(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      streetNumber: json['streetNumber']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      addressComplement: json['addressComplement']?.toString() ?? '',
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

class ApiUser {
  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    this.crm,
    this.type,
    this.image,
  });

  final String id;
  final String name;
  final String email;
  final String? crm;
  final String? type;
  final String? image;

  String get firstName {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Profissional';
    return parts.first;
  }

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Profissional',
      email: json['email']?.toString() ?? '',
      crm: json['crm']?.toString(),
      type: json['type']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'crm': crm,
      'type': type,
      'image': image,
    };
  }
}

class ApiClient {
  static const String _baseUrl = 'http://localhost:3001';

  Future<List<ApiPatient>> fetchPatients({String? doctorId}) async {
    final uri = Uri.parse('$_baseUrl/patients').replace(
      queryParameters: {
        if (doctorId != null && doctorId.trim().isNotEmpty)
          'doctorId': doctorId.trim(),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar pacientes ({response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApiPatient.fromJson)
        .toList();
  }

  Future<ApiPatient> createPatient({
    required String doctorId,
    required String name,
    required String cpf,
    DateTime? lastAppointment,
    String? zipCode,
    String? street,
    String? streetNumber,
    String? neighborhood,
    String? city,
    String? addressComplement,
    int? age,
    DateTime? birthDate,
    String? maritalStatus,
    String? profession,
    String? previousDiseases,
    String? allergies,
    String? medications,
  }) async {
    final uri = Uri.parse('$_baseUrl/patients');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctorId': doctorId,
        'name': name.trim(),
        'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
        if (lastAppointment != null)
          'lastAppointment': lastAppointment.toIso8601String(),
        if (zipCode != null && zipCode.trim().isNotEmpty)
          'zipCode': zipCode.trim().replaceAll(RegExp(r'\D'), ''),
        if (street != null && street.trim().isNotEmpty) 'street': street.trim(),
        if (streetNumber != null && streetNumber.trim().isNotEmpty)
          'streetNumber': streetNumber.trim(),
        if (neighborhood != null && neighborhood.trim().isNotEmpty)
          'neighborhood': neighborhood.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (addressComplement != null && addressComplement.trim().isNotEmpty)
          'addressComplement': addressComplement.trim(),
        if (age != null) 'age': age,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (maritalStatus != null && maritalStatus.trim().isNotEmpty)
          'maritalStatus': maritalStatus.trim(),
        if (profession != null && profession.trim().isNotEmpty)
          'profession': profession.trim(),
        if (previousDiseases != null && previousDiseases.trim().isNotEmpty)
          'previousDiseases': previousDiseases.trim(),
        if (allergies != null && allergies.trim().isNotEmpty)
          'allergies': allergies.trim(),
        if (medications != null && medications.trim().isNotEmpty)
          'medications': medications.trim(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiPatient.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao cadastrar paciente');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(
      message ?? 'Erro ao cadastrar paciente (${response.statusCode})',
    );
  }

  Future<ApiPatient> updatePatient({
    required String id,
    String? name,
    String? cpf,
    int? age,
    DateTime? birthDate,
    String? maritalStatus,
    String? profession,
    String? previousDiseases,
    String? allergies,
    String? medications,
    String? boneHealth,
  }) async {
    final uri = Uri.parse('$_baseUrl/patients/$id');
    final response = await http.patch(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (cpf != null && cpf.trim().isNotEmpty)
          'cpf': cpf.trim().replaceAll(RegExp(r'\D'), ''),
        if (age != null) 'age': age,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (maritalStatus != null) 'maritalStatus': maritalStatus.trim(),
        if (profession != null) 'profession': profession.trim(),
        if (previousDiseases != null)
          'previousDiseases': previousDiseases.trim(),
        if (allergies != null) 'allergies': allergies.trim(),
        if (medications != null) 'medications': medications.trim(),
        if (boneHealth != null) 'boneHealth': boneHealth.trim(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiPatient.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao atualizar paciente');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(
      message ?? 'Erro ao atualizar paciente (${response.statusCode})',
    );
  }

  Future<List<ApiAppointment>> fetchAppointments({String? patientId, String? doctorId}) async {
    final uri = Uri.parse('$_baseUrl/appointments').replace(
      queryParameters: {
        if (patientId != null && patientId.trim().isNotEmpty)
          'patientId': patientId.trim(),
        if (doctorId != null && doctorId.trim().isNotEmpty)
          'doctorId': doctorId.trim(),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar atendimentos (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApiAppointment.fromJson)
        .toList();
  }

  Future<ApiAppointment> createAppointment({
    required String doctorId,
    required String patientId,
    required String clinicLocationId,
    required DateTime appointmentDate,
    int? age,
    String? sexualOrientation,
    String? maritalStatus,
    bool? concordantPartner,
    String? occupation,
    String? comorbidities,
    String? previousDiseases,
    String? allergy,
    String? surgeries,
    String? medicationUse,
    DateTime? hivDiagnosisDate,
    String? cardiovascularRisk,
    String? neoplasmScreening,
    String? coinfectionScreening,
    String? immunizations,
    String? boneHealth,
    String? notes,
    String? currentArt,
    String? adherence,
    String? cd4Nadir,
    String? virologicalStatus,
    String? currentRegimen,
  }) async {
    final uri = Uri.parse('$_baseUrl/appointments');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctorId': doctorId,
        'patientId': patientId,
        'clinicLocationId': clinicLocationId,
        'appointmentDate': appointmentDate.toIso8601String(),
        if (age != null) 'age': age,
        if (sexualOrientation != null && sexualOrientation.trim().isNotEmpty)
          'sexualOrientation': sexualOrientation.trim(),
        if (maritalStatus != null && maritalStatus.trim().isNotEmpty)
          'maritalStatus': maritalStatus.trim(),
        if (concordantPartner != null) 'concordantPartner': concordantPartner,
        if (occupation != null && occupation.trim().isNotEmpty)
          'occupation': occupation.trim(),
        if (comorbidities != null && comorbidities.trim().isNotEmpty)
          'comorbidities': comorbidities.trim(),
        if (previousDiseases != null && previousDiseases.trim().isNotEmpty)
          'previousDiseases': previousDiseases.trim(),
        if (allergy != null && allergy.trim().isNotEmpty)
          'allergy': allergy.trim(),
        if (surgeries != null && surgeries.trim().isNotEmpty)
          'surgeries': surgeries.trim(),
        if (medicationUse != null && medicationUse.trim().isNotEmpty)
          'medicationUse': medicationUse.trim(),
        if (hivDiagnosisDate != null)
          'hivDiagnosisDate': hivDiagnosisDate.toIso8601String(),
        if (cardiovascularRisk != null && cardiovascularRisk.trim().isNotEmpty)
          'cardiovascularRisk': cardiovascularRisk.trim(),
        if (neoplasmScreening != null && neoplasmScreening.trim().isNotEmpty)
          'neoplasmScreening': neoplasmScreening.trim(),
        if (coinfectionScreening != null && coinfectionScreening.trim().isNotEmpty)
          'coinfectionScreening': coinfectionScreening.trim(),
        if (immunizations != null && immunizations.trim().isNotEmpty)
          'immunizations': immunizations.trim(),
        if (boneHealth != null && boneHealth.trim().isNotEmpty)
          'boneHealth': boneHealth.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (currentArt != null && currentArt.trim().isNotEmpty)
          'currentArt': currentArt.trim(),
        if (adherence != null && adherence.trim().isNotEmpty)
          'adherence': adherence.trim(),
        if (cd4Nadir != null && cd4Nadir.trim().isNotEmpty)
          'cd4Nadir': cd4Nadir.trim(),
        if (virologicalStatus != null && virologicalStatus.trim().isNotEmpty)
          'virologicalStatus': virologicalStatus.trim(),
        if (currentRegimen != null && currentRegimen.trim().isNotEmpty)
          'currentRegimen': currentRegimen.trim(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiAppointment.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao salvar consulta');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao salvar consulta (${response.statusCode})');
  }

  Future<List<ApiClinicLocation>> fetchClinicLocations() async {
    final uri = Uri.parse('$_baseUrl/clinic-locations');
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar locais (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApiClinicLocation.fromJson)
        .toList();
  }

  Future<ApiClinicLocation> createClinicLocation({
    required String doctorId,
    String? name,
    required String zipCode,
    required String street,
    required String streetNumber,
    String? neighborhood,
    String? city,
    String? addressComplement,
  }) async {
    final uri = Uri.parse('$_baseUrl/clinic-locations');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctorId': doctorId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'zipCode': zipCode.replaceAll(RegExp(r'\D'), ''),
        'street': street.trim(),
        'streetNumber': streetNumber.trim(),
        if (neighborhood != null && neighborhood.trim().isNotEmpty)
          'neighborhood': neighborhood.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (addressComplement != null && addressComplement.trim().isNotEmpty)
          'addressComplement': addressComplement.trim(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiClinicLocation.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao cadastrar local');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao cadastrar local (${response.statusCode})');
  }

  Future<ApiClinicLocation> updateClinicLocation({
    required String id,
    String? name,
    String? zipCode,
    String? street,
    String? streetNumber,
    String? neighborhood,
    String? city,
    String? addressComplement,
  }) async {
    final uri = Uri.parse('$_baseUrl/clinic-locations/$id');
    final response = await http.patch(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (name != null) 'name': name.trim().isEmpty ? null : name.trim(),
        if (zipCode != null) 'zipCode': zipCode.replaceAll(RegExp(r'\D'), ''),
        if (street != null) 'street': street.trim(),
        if (streetNumber != null) 'streetNumber': streetNumber.trim(),
        if (neighborhood != null)
          'neighborhood': neighborhood.trim().isEmpty ? null : neighborhood.trim(),
        if (city != null) 'city': city.trim().isEmpty ? null : city.trim(),
        if (addressComplement != null)
          'addressComplement': addressComplement.trim().isEmpty
              ? null
              : addressComplement.trim(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiClinicLocation.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao atualizar local');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao atualizar local (${response.statusCode})');
  }

  Future<void> deleteClinicLocation(String id) async {
    final uri = Uri.parse('$_baseUrl/clinic-locations/$id');
    final response = await http.delete(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao excluir local (${response.statusCode})');
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
      return decoded['data'] as List<dynamic>;
    }
    return const [];
  }

  Future<ApiUser> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/login');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiUser.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao realizar login');
    }

    final message = _extractErrorMessage(response.body);
    if (message == 'Invalid credentials') {
      throw Exception('Invalid credentials');
    }
    throw Exception(
      message ?? 'Erro ao realizar login (${response.statusCode})',
    );
  }

  Future<ApiUser> fetchUserById(String userId) async {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('ID do usuario invalido');
    }

    final uri = Uri.parse('$_baseUrl/users/$normalizedId');
    final response = await http.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final user = ApiUser.fromJson(decoded);
        if (user.id.trim().isNotEmpty) {
          return user;
        }
      }
      throw Exception('Resposta inválida ao carregar usuário');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao carregar usuário (${response.statusCode})');
  }

  Future<ApiUser> register({
    required String name,
    required String cpf,
    required String crm,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/doctor');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'cpf': cpf.trim().replaceAll(RegExp(r'\D'), ''),
        'crm': crm.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiUser.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao cadastrar usuário');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(
      message ?? 'Erro ao realizar cadastro (${response.statusCode})',
    );
  }

  Future<void> requestForgotPasswordLink({required String email}) async {
    await _postForgotPassword(
      path: '/users/forgot-password/request-link',
      email: email,
    );
  }

  Future<void> resendForgotPasswordLink({required String email}) async {
    await _postForgotPassword(
      path: '/users/forgot-password/resend-link',
      email: email,
    );
  }

  Future<void> _postForgotPassword({
    required String path,
    required String email,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final message = _extractErrorMessage(response.body);
    throw Exception(
      message ?? 'Erro ao solicitar recuperação (${response.statusCode})',
    );
  }

  Future<ApiUser> updateProfile({
    required String userId,
    required String currentPassword,
    required String newPassword,
    String? name,
    String? email,
    String? image,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/profile/$userId');
    final bodyMap = <String, dynamic>{
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    if (name != null && name.trim().isNotEmpty) bodyMap['name'] = name.trim();
    if (email != null && email.trim().isNotEmpty)
      bodyMap['email'] = email.trim().toLowerCase();
    if (image != null && image.trim().isNotEmpty)
      bodyMap['image'] = image.trim();
    final response = await http.patch(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(bodyMap),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return ApiUser.fromJson(decoded);
      throw Exception('Resposta inválida ao atualizar perfil');
    }
    final message = _extractErrorMessage(response.body);
    throw Exception(
      message ?? 'Erro ao atualizar perfil (${response.statusCode})',
    );
  }

  Future<ApiUser> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/forgot-password');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'resetCode': resetCode.trim(),
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiUser.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao redefinir senha');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(
      message ?? 'Erro ao redefinir senha (${response.statusCode})',
    );
  }

  String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty)
        return message.first.toString();
    } catch (_) {
      return null;
    }
    return null;
  }
}

class HivisionWebApp extends StatelessWidget {
  const HivisionWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HIVision Web',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AppColors.lightBackground,
        fontFamily: 'SF Pro Display',
      ),
      home: const EntryScreen(),
    );
  }
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLogin());
  }

  Future<void> _checkLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLoggedIn = prefs.getBool(_kHasLoggedIn) ?? false;
      final loggedUser = _readLoggedUserFromPrefs(prefs);
      if (!mounted) return;
      if (hasLoggedIn && loggedUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HivisionShell(currentUser: loggedUser),
          ),
        );
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TapGestureRecognizer _signupTapRecognizer = TapGestureRecognizer();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signupTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Informe email e senha.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    late final ApiUser loggedUser;
    try {
      loggedUser = await _apiClient.login(email: email, password: password);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'O E-mail ou Senha estão incorretos.';
      });
      return;
    }

    if (!mounted) return;

    // Persist session in background so storage issues do not block navigation.
    Future<void>(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await _persistLoggedUser(prefs, loggedUser);
      } catch (_) {}
    });

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HivisionShell(currentUser: loggedUser)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(
        logoAsset: 'assets/images/group_21.png',
      ),
      lightBottomContent: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          return SizedBox(
            width: screenWidth * 0.8,
            child: const Text(
              'Este software foi desenvolvido em parceria com o Centro de Inovação Tecnológica do Cesmac e trata-se de um produto de dissertação do Programa de Pós-graduação Profissional em Biotecnologia em Saúde Humana e Animal da Universidade Estadual do Ceará em associação com o Centro Universitário Cesmac.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
      darkHeaderImage: 'assets/images/group_20.png',
      title: 'Bem-vindo(a)!',
      subtitle: '',
      fields: [
        _AuthField(
          label: 'Email',
          compact: true,
          child: _AuthTextField(
            controller: _emailController,
            hint: 'exemplo@dominio.com',
            compact: true,
          ),
        ),
        _AuthField(
          label: 'Senha',
          compact: true,
          child: _AuthTextField(
            controller: _passwordController,
            hint: 'Senha',
            obscure: true,
            compact: true,
          ),
        ),
      ],
      footer: null,
      onSubmit: null,
      submitText: '',
      loading: _loading,
      centerPanelContent: true,
      showPanelBrand: false,
      customButtons: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ForgotPasswordScreen(
                  initialEmail: _emailController.text.trim(),
                ),
              ),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 14),
              SizedBox(width: 6),
              Text(
                'Esqueci minha senha',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFFFDCDC),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 14),
        _AuthButton(
          text: 'Entrar',
          loading: _loading,
          onPressed: _loading ? null : _submit,
        ),
        const SizedBox(height: 32),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              children: [
                const TextSpan(text: 'Não tem conta? '),
                TextSpan(
                  text: 'Cadastre-se',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Color(0xFFFFD600),
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: _signupTapRecognizer
                    ..onTap = () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiClient _apiClient = ApiClient();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _crmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _crmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final name = _nameController.text.trim();
    final cpf = _cpfController.text.trim();
    final crm = _crmController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty ||
        cpf.isEmpty ||
        crm.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      setState(() => _error = 'Preencha todos os campos.');
      return;
    }

    final normalizedCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (normalizedCpf.length != 11) {
      setState(() => _error = 'CPF inválido. Informe 11 números.');
      return;
    }

    if (RegExp(r'^(\d)\1{10}$').hasMatch(normalizedCpf)) {
      setState(() => _error = 'CPF inválido.');
      return;
    }

    if (password != confirm) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    late final ApiUser createdUser;
    try {
      createdUser = await _apiClient.register(
        name: name,
        cpf: normalizedCpf,
        crm: crm,
        email: email,
        password: password,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await _persistLoggedUser(prefs, createdUser);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HivisionShell(currentUser: createdUser),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(
        logoAsset: 'assets/images/group_21.png',
      ),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Cadastrar-se',
      subtitle: '',
      fields: [
        _AuthField(
          label: 'Nome Completo:',
          compact: true,
          child: _AuthTextField(
            controller: _nameController,
            hint: 'Nome completo',
            compact: true,
          ),
        ),
        _AuthField(
          label: 'CPF:',
          compact: true,
          child: _AuthTextField(
            controller: _cpfController,
            hint: '000.000.000-00',
            compact: true,
            keyboardType: TextInputType.number,
            inputFormatters: [CpfInputFormatter()],
          ),
        ),
        _AuthField(
          label: 'CRM:',
          compact: true,
          child: _AuthTextField(
            controller: _crmController,
            hint: 'CRM',
            compact: true,
          ),
        ),
        _AuthField(
          label: 'Email:',
          compact: true,
          child: _AuthTextField(
            controller: _emailController,
            hint: 'exemplo@dominio.com',
            compact: true,
          ),
        ),
        _AuthField(
          label: 'Senha:',
          compact: true,
          child: _AuthTextField(
            controller: _passwordController,
            hint: 'Senha',
            obscure: true,
            compact: true,
          ),
        ),
        _AuthField(
          label: 'Confirmar senha:',
          compact: true,
          child: _AuthTextField(
            controller: _confirmController,
            hint: 'Senha',
            obscure: true,
            compact: true,
          ),
        ),
      ],
      footer: _error == null
          ? null
          : Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFFFDCDC),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
      onSubmit: _loading ? null : _submit,
      submitText: 'Criar Conta',
      loading: _loading,
      showPanelBrand: false,
      compact: true,
      centerPanelContent: true,
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  late final TextEditingController _emailController;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiClient.requestForgotPasswordLink(email: email);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível solicitar recuperação.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordConfirmationScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(
        logoAsset: 'assets/images/group_21.png',
      ),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Esqueceu a senha?',
      subtitle:
          'Digite o e-mail cadastrado e enviaremos um código para você criar uma nova senha.',
      fields: [
        _AuthField(
          label: 'Email',
          compact: true,
          child: _AuthTextField(
            controller: _emailController,
            hint: 'Digite seu email',
            compact: true,
          ),
        ),
      ],
      footer: null,
      onSubmit: null,
      submitText: '',
      loading: _loading,
      showPanelBrand: false,
      centerPanelContent: true,
      centerTitle: true,
      compact: true,
      customButtons: [
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFFFDCDC),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 42,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: 180,
              height: 42,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.textDark,
                        ),
                      )
                    : const Text(
                        'Enviar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ForgotPasswordConfirmationScreen extends StatefulWidget {
  const ForgotPasswordConfirmationScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotPasswordConfirmationScreen> createState() =>
      _ForgotPasswordConfirmationScreenState();
}

class _ForgotPasswordConfirmationScreenState
    extends State<ForgotPasswordConfirmationScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _loading = false;

  Future<void> _resend() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _apiClient.resendForgotPasswordLink(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail reenviado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao reenviar e-mail.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(
        logoAsset: 'assets/images/group_21.png',
      ),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Confirmar e-mail',
      subtitle: '',
      fields: const [],
      customButtons: [
        Center(child: Image.asset('assets/images/Frame 194.png', width: 140)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Enviamos um código para: ${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Por favor, verifique sua caixa de entrada para verificar se o e-mail chegou.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
          ),
        ),
        const SizedBox(height: 24),
        _AuthButton(
          text: 'Recebi o e-mail',
          small: true,
          slim: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewPasswordScreen(email: widget.email),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _AuthButton(
          text: _loading ? 'Reenviando...' : 'Reenviar E-mail',
          small: true,
          slim: true,
          onPressed: _loading ? null : _resend,
        ),
      ],
      onSubmit: null,
      submitText: 'Continuar',
      loading: false,
      showPanelBrand: false,
      centerPanelContent: true,
      centerTitle: true,
      compact: true,
    );
  }
}

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final code = _codeController.text.trim();
    final pass = _newPasswordController.text;
    final confirm = _confirmController.text;

    if (code.replaceAll(RegExp(r'\D'), '').length != 6) {
      setState(() => _error = 'Código deve ter 6 dígitos.');
      return;
    }

    if (pass.length < 6) {
      setState(() => _error = 'Senha deve ter no mínimo 6 caracteres.');
      return;
    }

    if (pass != confirm) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    late final ApiUser loggedUser;
    try {
      loggedUser = await _apiClient.resetPassword(
        email: widget.email,
        resetCode: code,
        newPassword: pass,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível redefinir a senha.';
      });
      return;
    }

    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await _persistLoggedUser(prefs, loggedUser);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HivisionShell(currentUser: loggedUser)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(
        logoAsset: 'assets/images/group_21.png',
      ),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Criar Nova Senha',
      subtitle:
          'Crie uma senha forte para manter sua conta protegida. Depois é só salvar e voltar ao aplicativo.',
      fields: [
        _AuthField(
          label: 'Código de recuperação',
          compact: true,
          child: _AuthTextField(
            controller: _codeController,
            hint: '000000',
            compact: true,
          ),
        ),
        _AuthField(
          label: 'Nova senha',
          compact: true,
          child: _AuthTextField(
            controller: _newPasswordController,
            hint: 'Nova senha',
            obscure: true,
            compact: true,
          ),
        ),
        _AuthField(
          label: 'Confirmar senha',
          compact: true,
          child: _AuthTextField(
            controller: _confirmController,
            hint: 'Confirmar senha',
            obscure: true,
            compact: true,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/check.png',
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF45B36B),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Mínimo de 6 caracteres',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      footer: null,
      onSubmit: null,
      submitText: '',
      loading: false,
      showPanelBrand: false,
      centerPanelContent: true,
      centerSubtitle: false,
      compact: true,
      customButtons: [
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFFFDCDC),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    backgroundColor: AppColors.wine,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.textDark,
                          ),
                        )
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthSplitLayout extends StatelessWidget {
  const _AuthSplitLayout({
    required this.lightContent,
    required this.darkHeaderImage,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onSubmit,
    required this.submitText,
    required this.loading,
    this.footer,
    this.customButtons,
    this.centerPanelContent = false,
    this.centerTitle = false,
    this.centerSubtitle,
    this.showPanelBrand = true,
    this.compact = false,
    this.lightBottomContent,
  });

  final Widget lightContent;
  final Widget? lightBottomContent;
  final String darkHeaderImage;
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final VoidCallback? onSubmit;
  final String submitText;
  final bool loading;
  final Widget? footer;
  final List<Widget>? customButtons;
  final bool centerPanelContent;
  final bool centerTitle;
  final bool? centerSubtitle;
  final bool showPanelBrand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final formColumn = Column(
      crossAxisAlignment: centerPanelContent
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (showPanelBrand) ...[
          Row(
            mainAxisAlignment: centerPanelContent
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Image.asset(darkHeaderImage, width: 48),
              const SizedBox(width: 10),
              const Text(
                'HIVision',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Align(
          alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
          child: Text(
            title,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 36.0 : 48.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: (centerSubtitle ?? centerPanelContent)
                ? TextAlign.center
                : TextAlign.start,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 14.0 : 17.0,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 18),
        ...fields,
        if (footer != null) ...[const SizedBox(height: 14), footer!],
        const SizedBox(height: 20),
        if (customButtons != null)
          ...customButtons!
        else
          _AuthButton(
            text: submitText,
            loading: loading,
            onPressed: onSubmit,
            small: compact,
          ),
      ],
    );

    final formContent = centerPanelContent
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: formColumn,
            ),
          )
        : formColumn;

    final panel = Container(
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: formContent,
            ),
          );
        },
      ),
    );

    final lightPanel = Container(
      color: AppColors.lightBackground,
      child: lightBottomContent != null
          ? Stack(
              children: [
                Center(child: lightContent),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.04,
                      left: MediaQuery.of(context).size.width * 0.02,
                      right: MediaQuery.of(context).size.width * 0.02,
                    ),
                    child: lightBottomContent,
                  ),
                ),
              ],
            )
          : Center(child: lightContent),
    );

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: lightPanel),
          Expanded(flex: 2, child: panel),
        ],
      ),
    );
  }
}

class _HivisionLogoBlock extends StatelessWidget {
  const _HivisionLogoBlock({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(logoAsset, width: 120),
        const SizedBox(height: 12),
        const Text(
          'HIVision',
          style: TextStyle(
            fontSize: 56,
            color: AppColors.wine,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.child,
    this.compact = false,
  });

  final String label;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 13.0 : 17.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.compact = false,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool compact;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 14.0 : 18.0;
    final vPad = compact ? 8.0 : 12.0;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF888888),
          fontSize: fontSize,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.text,
    this.onPressed,
    this.loading = false,
    this.small = false,
    this.slim = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool small;
  final bool slim;

  @override
  Widget build(BuildContext context) {
    final height = small ? 36.0 : 48.0;
    final fontSize = small ? 14.0 : 20.0;
    final loaderSize = small ? 14.0 : 18.0;

    final button = SizedBox(
      width: slim ? 220 : double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paleRose,
          foregroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: loading
            ? SizedBox(
                width: loaderSize,
                height: loaderSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.textDark,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );

    return slim ? Center(child: button) : button;
  }
}

class DashboardData {
  DashboardData({
    required this.appointments,
    required this.patientNames,
    required this.patients,
    this.clinicLocationsById = const {},
  });

  final List<ApiAppointment> appointments;
  final Map<String, String> patientNames;
  final List<ApiPatient> patients;
  final Map<String, ApiClinicLocation> clinicLocationsById;
}

class HivisionShell extends StatefulWidget {
  const HivisionShell({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  State<HivisionShell> createState() => _HivisionShellState();
}

enum _DesktopSection {
  home,
  profile,
  patients,
  reports,
  consultation,
  locations,
}

enum _PatientsPane { newPatient, registered }

enum _ConsultationPane { newConsultation, registered }

enum _LocationsPane { newLocation, registered }

class _HivisionShellState extends State<HivisionShell> {
  _DesktopSection _section = _DesktopSection.home;
  _PatientsPane _patientsPane = _PatientsPane.registered;
  _ConsultationPane _consultationPane = _ConsultationPane.registered;
  _LocationsPane _locationsPane = _LocationsPane.registered;
  ApiPatient? _selectedApiPatient;
  ApiPatient? _selectedConsultationPatient;
  bool _isMiddlePanelOpen = false;
  String _desktopSearchTerm = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            section: _section,
            onSelect: (section) {
              setState(() {
                _section = section;
                _desktopSearchTerm = '';
                _isMiddlePanelOpen =
                    section != _DesktopSection.home &&
                    section != _DesktopSection.profile &&
                    section != _DesktopSection.reports;
                if (section != _DesktopSection.patients) {
                  _selectedApiPatient = null;
                }
                if (section == _DesktopSection.patients) {
                  _patientsPane = _PatientsPane.registered;
                }
                if (section == _DesktopSection.consultation) {
                  _consultationPane = _ConsultationPane.registered;
                  _selectedConsultationPatient = null;
                }
                if (section == _DesktopSection.locations) {
                  _locationsPane = _LocationsPane.registered;
                }
              });
            },
          ),
          if (_isMiddlePanelOpen &&
              _section != _DesktopSection.home &&
              _section != _DesktopSection.profile &&
              _section != _DesktopSection.reports)
            _DesktopMiddlePanel(
              section: _section,
              currentUser: widget.currentUser,
              patientsPane: _patientsPane,
              consultationPane: _consultationPane,
              locationsPane: _locationsPane,
              onPatientsPaneChanged: (pane) {
                setState(() {
                  _patientsPane = pane;
                  if (pane != _PatientsPane.registered) {
                    _selectedApiPatient = null;
                  }
                });
              },
              onConsultationPaneChanged: (pane) {
                setState(() {
                  _consultationPane = pane;
                  if (pane != _ConsultationPane.newConsultation) {
                    _selectedConsultationPatient = null;
                  }
                });
              },
              onLocationsPaneChanged: (pane) {
                setState(() {
                  _locationsPane = pane;
                });
              },
              onClose: () => setState(() => _isMiddlePanelOpen = false),
            ),
          Expanded(
            child: _DesktopMainArea(
              section: _section,
              currentUser: widget.currentUser,
              patientsPane: _patientsPane,
              consultationPane: _consultationPane,
              locationsPane: _locationsPane,
              selectedApiPatient: _selectedApiPatient,
              onSelectApiPatient: (patient) =>
                  setState(() => _selectedApiPatient = patient),
              onBackFromPatient: () =>
                  setState(() {
                    _selectedApiPatient = null;
                    _desktopSearchTerm = '';
                  }),
              middlePanelOpen: _isMiddlePanelOpen,
              onOpenMiddlePanel: () {
                if (_section == _DesktopSection.home ||
                    _section == _DesktopSection.profile ||
                    _section == _DesktopSection.reports) {
                  return;
                }
                setState(() => _isMiddlePanelOpen = true);
              },
              searchTerm: _desktopSearchTerm,
              onSearchChanged: (value) => setState(() => _desktopSearchTerm = value),
              onSectionChanged: (s) => setState(() {
                _section = s;
                _desktopSearchTerm = '';
                _isMiddlePanelOpen =
                    s != _DesktopSection.home &&
                    s != _DesktopSection.profile &&
                    s != _DesktopSection.reports;
                if (s != _DesktopSection.patients) _selectedApiPatient = null;
                if (s == _DesktopSection.patients) {
                  _patientsPane = _PatientsPane.registered;
                }
                if (s == _DesktopSection.consultation) {
                  _consultationPane = _ConsultationPane.registered;
                  _selectedConsultationPatient = null;
                }
                if (s != _DesktopSection.consultation) {
                  _selectedConsultationPatient = null;
                }
                if (s == _DesktopSection.locations) {
                  _locationsPane = _LocationsPane.registered;
                }
              }),
              onGoToNewConsultation: () => setState(() {
                _section = _DesktopSection.consultation;
                _desktopSearchTerm = '';
                _consultationPane = _ConsultationPane.newConsultation;
                _selectedConsultationPatient = null;
                _isMiddlePanelOpen = true;
              }),
              onGoToNewPatient: () => setState(() {
                _section = _DesktopSection.patients;
                _desktopSearchTerm = '';
                _patientsPane = _PatientsPane.newPatient;
                _selectedApiPatient = null;
                _isMiddlePanelOpen = true;
              }),
              onGoToNewLocation: () => setState(() {
                _section = _DesktopSection.locations;
                _desktopSearchTerm = '';
                _locationsPane = _LocationsPane.newLocation;
                _isMiddlePanelOpen = true;
              }),
              onPatientCreated: () => setState(() {
                _section = _DesktopSection.patients;
                _desktopSearchTerm = '';
                _patientsPane = _PatientsPane.registered;
                _selectedApiPatient = null;
                _isMiddlePanelOpen = true;
              }),
              selectedConsultationPatient: _selectedConsultationPatient,
              onOpenNewConsultationForPatient: (patient) => setState(() {
                _selectedConsultationPatient = patient;
                _section = _DesktopSection.consultation;
                _desktopSearchTerm = '';
                _consultationPane = _ConsultationPane.newConsultation;
                _isMiddlePanelOpen = true;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.section, required this.onSelect});

  final _DesktopSection section;
  final ValueChanged<_DesktopSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 212,
      color: AppColors.wine,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/group_20.png',
                            width: 36,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'HIVision',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DesktopSidebarItem(
                      icon: Icons.home_outlined,
                      label: 'Início',
                      active: section == _DesktopSection.home,
                      onTap: () => onSelect(_DesktopSection.home),
                    ),
                    _DesktopSidebarItem(
                      icon: Icons.groups_outlined,
                      label: 'Pacientes',
                      active: section == _DesktopSection.patients,
                      onTap: () => onSelect(_DesktopSection.patients),
                    ),
                    _DesktopSidebarItem(
                      icon: Icons.medical_services_outlined,
                      label: 'Consultas',
                      active: section == _DesktopSection.consultation,
                      onTap: () => onSelect(_DesktopSection.consultation),
                    ),
                    _DesktopSidebarItem(
                      icon: Icons.location_on_outlined,
                      label: 'Locais',
                      active: section == _DesktopSection.locations,
                      onTap: () => onSelect(_DesktopSection.locations),
                    ),
                    _DesktopSidebarItem(
                      icon: Icons.content_copy_outlined,
                      label: 'Relatórios',
                      active: section == _DesktopSection.reports,
                      onTap: () => onSelect(_DesktopSection.reports),
                    ),
                    _DesktopSidebarItem(
                      icon: Icons.badge_outlined,
                      label: 'Meu Perfil',
                      active: section == _DesktopSection.profile,
                      onTap: () => onSelect(_DesktopSection.profile),
                    ),
                    const Spacer(),
                    _DesktopSidebarItem(
                      icon: Icons.logout,
                      label: 'Sair',
                      active: false,
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(_kHasLoggedIn);
                        await prefs.remove(_kLoggedUserJson);
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  const _DesktopSidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.wine : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 204,
          height: 88,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDDD2D2) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopMiddlePanel extends StatelessWidget {
  const _DesktopMiddlePanel({
    required this.section,
    this.currentUser,
    required this.patientsPane,
    required this.consultationPane,
    required this.locationsPane,
    required this.onPatientsPaneChanged,
    required this.onConsultationPaneChanged,
    required this.onLocationsPaneChanged,
    required this.onClose,
  });

  final _DesktopSection section;
  final ApiUser? currentUser;
  final _PatientsPane patientsPane;
  final _ConsultationPane consultationPane;
  final _LocationsPane locationsPane;
  final ValueChanged<_PatientsPane> onPatientsPaneChanged;
  final ValueChanged<_ConsultationPane> onConsultationPaneChanged;
  final ValueChanged<_LocationsPane> onLocationsPaneChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final greetingName = _buildFirstAndLastName(
      currentUser?.name ?? 'Luiza Siqueira',
    );
    final imageProvider = _resolveAvatarImageProvider(currentUser?.image);
    final hasImage = imageProvider != null;
    final now = DateTime.now();
    final todayStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return SizedBox(
      width: 340,
      child: Container(
        color: AppColors.sidePanel,
        padding: const EdgeInsets.fromLTRB(26, 30, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.wine,
                  backgroundImage: imageProvider,
                  child: hasImage
                      ? null
                      : Text(
                          _buildInitials(greetingName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, Dr(a) $greetingName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 3),
                      Text(todayStr, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            if (section == _DesktopSection.patients) ...[
              _DesktopMiddleItem(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Novo Paciente',
                active: patientsPane == _PatientsPane.newPatient,
                onTap: () => onPatientsPaneChanged(_PatientsPane.newPatient),
              ),
              const SizedBox(height: 8),
              _DesktopMiddleItem(
                icon: Icons.groups_outlined,
                label: 'Pacientes Cadastrados',
                active: patientsPane == _PatientsPane.registered,
                onTap: () => onPatientsPaneChanged(_PatientsPane.registered),
              ),
            ] else if (section == _DesktopSection.consultation) ...[
              _DesktopMiddleItem(
                icon: Icons.add_circle_outline,
                label: 'Nova consulta',
                active: consultationPane == _ConsultationPane.newConsultation,
                onTap: () => onConsultationPaneChanged(
                  _ConsultationPane.newConsultation,
                ),
              ),
              const SizedBox(height: 8),
              _DesktopMiddleItem(
                icon: Icons.medical_services_outlined,
                label: 'Consultas',
                active: consultationPane == _ConsultationPane.registered,
                onTap: () =>
                    onConsultationPaneChanged(_ConsultationPane.registered),
              ),
            ] else if (section == _DesktopSection.locations) ...[
              _DesktopMiddleItem(
                icon: Icons.add_location_alt_outlined,
                label: 'Novo local',
                active: locationsPane == _LocationsPane.newLocation,
                onTap: () => onLocationsPaneChanged(_LocationsPane.newLocation),
              ),
              const SizedBox(height: 8),
              _DesktopMiddleItem(
                icon: Icons.location_on_outlined,
                label: 'Locais cadastrados',
                active: locationsPane == _LocationsPane.registered,
                onTap: () => onLocationsPaneChanged(_LocationsPane.registered),
              ),
            ] else if (section == _DesktopSection.profile) ...[
              const _DesktopMiddleItem(
                icon: Icons.manage_accounts_outlined,
                label: 'Alterar dados do perfil',
                active: true,
              ),
            ],
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.close, color: AppColors.textDark, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Fechar',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMiddleItem extends StatelessWidget {
  const _DesktopMiddleItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.wine : Colors.transparent;
    final fg = active ? Colors.white : const Color(0xFF2E2E2E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMainArea extends StatelessWidget {
  const _DesktopMainArea({
    required this.section,
    this.currentUser,
    required this.patientsPane,
    required this.consultationPane,
    required this.locationsPane,
    required this.selectedApiPatient,
    required this.onSelectApiPatient,
    required this.onBackFromPatient,
    required this.middlePanelOpen,
    required this.onOpenMiddlePanel,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.onSectionChanged,
    required this.onGoToNewConsultation,
    required this.onGoToNewPatient,
    required this.onGoToNewLocation,
    required this.onPatientCreated,
    required this.selectedConsultationPatient,
    required this.onOpenNewConsultationForPatient,
  });

  final _DesktopSection section;
  final ApiUser? currentUser;
  final _PatientsPane patientsPane;
  final _ConsultationPane consultationPane;
  final _LocationsPane locationsPane;
  final ApiPatient? selectedApiPatient;
  final ValueChanged<ApiPatient> onSelectApiPatient;
  final VoidCallback onBackFromPatient;
  final bool middlePanelOpen;
  final VoidCallback onOpenMiddlePanel;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_DesktopSection> onSectionChanged;
  final VoidCallback onGoToNewConsultation;
  final VoidCallback onGoToNewPatient;
  final VoidCallback onGoToNewLocation;
  final VoidCallback onPatientCreated;
  final ApiPatient? selectedConsultationPatient;
  final ValueChanged<ApiPatient> onOpenNewConsultationForPatient;

  @override
  Widget build(BuildContext context) {
    final hasSubTabs =
        section == _DesktopSection.patients ||
        section == _DesktopSection.consultation ||
        section == _DesktopSection.locations;
    final expandSearchBar = hasSubTabs && middlePanelOpen;
    final searchHint = _searchHintForSection(section);
    final isNewPatientScreen = section == _DesktopSection.patients && patientsPane == _PatientsPane.newPatient;
    final isNewConsultationScreen =
      section == _DesktopSection.consultation &&
      consultationPane == _ConsultationPane.newConsultation;
    final isNewLocationScreen =
      section == _DesktopSection.locations &&
      locationsPane == _LocationsPane.newLocation;
    final isWhiteBackgroundScreen =
      isNewPatientScreen || isNewConsultationScreen || isNewLocationScreen;

    return Column(
      children: [
        Container(
          color: AppColors.wine,
          padding: const EdgeInsets.fromLTRB(34, 20, 34, 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: expandSearchBar ? double.infinity : null,
                child: ConstrainedBox(
                  constraints: expandSearchBar
                      ? const BoxConstraints()
                      : const BoxConstraints(maxWidth: 520),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: TextField(
                      key: ValueKey(section),
                      onChanged: onSearchChanged,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF888888),
                          size: 22,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                        hintText: searchHint,
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF888888),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
              // Left-aligned doctor info on top of the stack
              if (!middlePanelOpen)
                Row(children: [_CollapsedDoctorInfo(currentUser: currentUser)]),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: isWhiteBackgroundScreen ? Colors.white : AppColors.lightBackground,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  String _searchHintForSection(_DesktopSection section) {
    switch (section) {
      case _DesktopSection.home:
        return 'Buscar pacientes do médico';
      case _DesktopSection.patients:
        return 'Buscar pacientes do médico';
      case _DesktopSection.consultation:
        return 'Buscar consultas do médico';
      case _DesktopSection.locations:
        return 'Buscar locais do médico';
      case _DesktopSection.reports:
        return 'Buscar relatórios do médico';
      case _DesktopSection.profile:
        return 'Buscar';
    }
  }

  Widget _buildMainContent() {
    if (section == _DesktopSection.home) {
      return _HomeSectionContent(
        onSectionChanged: onSectionChanged,
        onGoToNewConsultation: onGoToNewConsultation,
        onGoToNewPatient: onGoToNewPatient,
        onGoToNewLocation: onGoToNewLocation,
        searchTerm: searchTerm,
        onSelectApiPatient: onSelectApiPatient,
        currentUser: currentUser,
      );
    }

    if (section == _DesktopSection.patients) {
      if (patientsPane == _PatientsPane.newPatient) {
        return _NewPatientDesktopForm(
          currentUser: currentUser,
          onPatientCreated: onPatientCreated,
          isSubTabOpen: middlePanelOpen,
        );
      }
      if (selectedApiPatient != null) {
        return _ApiPatientProfileDesktop(
          patient: selectedApiPatient!,
          currentUser: currentUser,
          onBack: onBackFromPatient,
          onNewConsultation: () =>
              onOpenNewConsultationForPatient(selectedApiPatient!),
        );
      }
      return _ApiPatientsListDesktop(
        currentUser: currentUser,
        searchTerm: searchTerm,
        onSelectPatient: onSelectApiPatient,
      );
    }

    if (section == _DesktopSection.profile) {
      return _SettingsDesktop(currentUser: currentUser);
    }

    if (section == _DesktopSection.consultation) {
      if (consultationPane == _ConsultationPane.newConsultation) {
        return _NewConsultationDesktopForm(
          currentUser: currentUser,
          initialPatient: selectedConsultationPatient,
        );
      }
      return _ConsultationSectionContent(
        currentUser: currentUser,
        searchTerm: searchTerm,
      );
    }

    if (section == _DesktopSection.locations) {
      if (locationsPane == _LocationsPane.newLocation) {
        return _NewLocationDesktopForm(currentUser: currentUser);
      }
      return _LocationsSectionContent(
        currentUser: currentUser,
        searchTerm: searchTerm,
      );
    }

    if (section == _DesktopSection.reports) {
      return _ReportsSectionContent(
        currentUser: currentUser,
        searchTerm: searchTerm,
      );
    }

    return const _DesktopPlaceholder(
      title: 'HIVision',
      subtitle: 'Selecione uma opção no menu para continuar.',
    );
  }
}

class _CollapsedDoctorInfo extends StatelessWidget {
  const _CollapsedDoctorInfo({this.currentUser});

  final ApiUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final greetingName = _buildFirstAndLastName(
      currentUser?.name ?? 'Luiza Siqueira',
    );
    final imageProvider = _resolveAvatarImageProvider(currentUser?.image);
    final hasImage = imageProvider != null;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          backgroundImage: imageProvider,
          child: hasImage
              ? null
              : Text(
                  _buildInitials(greetingName),
                  style: const TextStyle(
                    color: AppColors.wine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, Dr(a) $greetingName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeSectionContent extends StatefulWidget {
  const _HomeSectionContent({
    required this.onSectionChanged,
    required this.onGoToNewConsultation,
    required this.onGoToNewPatient,
    required this.onGoToNewLocation,
    required this.searchTerm,
    required this.onSelectApiPatient,
    this.currentUser,
  });

  final ValueChanged<_DesktopSection> onSectionChanged;
  final VoidCallback onGoToNewConsultation;
  final VoidCallback onGoToNewPatient;
  final VoidCallback onGoToNewLocation;
  final String searchTerm;
  final ValueChanged<ApiPatient> onSelectApiPatient;
  final ApiUser? currentUser;

  @override
  State<_HomeSectionContent> createState() => _HomeSectionContentState();
}

class _HomeSectionContentState extends State<_HomeSectionContent> {
  final ApiClient _api = ApiClient();
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<DashboardData> _loadDashboard() async {
    final patients = await _api.fetchPatients();
    final allAppointments = await _api.fetchAppointments();
    final allClinicLocations = await _api.fetchClinicLocations();
    final doctorId = widget.currentUser?.id ?? '';
    final appointments = doctorId.isEmpty
        ? allAppointments
        : allAppointments.where((a) => a.doctorId == doctorId).toList();
    final clinicLocations = doctorId.isEmpty
        ? allClinicLocations
        : allClinicLocations.where((c) => c.doctorId == doctorId).toList();
    final patientNames = {for (final p in patients) p.id: p.name};
    final clinicLocationsById = {for (final c in clinicLocations) c.id: c};
    final doctorPatients = patients
        .where((p) => doctorId.isEmpty || p.doctorId == doctorId)
        .toList();
    return DashboardData(
      appointments: appointments,
      patientNames: patientNames,
      patients: doctorPatients,
      clinicLocationsById: clinicLocationsById,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DesktopSectionHeader(title: 'Início'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 130),
              child: Row(
                children: [
                  Expanded(
                    child: _HomeActionCard(
                      icon: Icons.medical_services_outlined,
                      label: 'Nova\nconsulta',
                      onTap: widget.onGoToNewConsultation,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HomeActionCard(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Novo\npaciente',
                      onTap: widget.onGoToNewPatient,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HomeActionCard(
                      icon: Icons.location_on_outlined,
                      label: 'Locais',
                      onTap: widget.onGoToNewLocation,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.only(left: 42),
              child: Text(
                'Atendimentos Recentes',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<DashboardData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.wine),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Falha ao carregar atendimentos do backend.',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                setState(() => _future = _loadDashboard()),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final sorted = [...data.appointments]
                    ..sort(
                      (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
                    );

                  if (sorted.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum atendimento encontrado.',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: sorted.length > 8 ? 8 : sorted.length,
                    separatorBuilder: (_, i) =>
                        const Divider(color: Color(0x99B58F8F), thickness: 1),
                    itemBuilder: (_, index) {
                      final appointment = sorted[index];
                      final patientName =
                          data.patientNames[appointment.patientId] ??
                          'Paciente';
                      final clinicLocation =
                          data.clinicLocationsById[appointment.clinicLocationId];
                      final clinicLocationText =
                          appointment.clinicLocationName.isNotEmpty
                          ? appointment.clinicLocationName
                          : (clinicLocation?.displayName ?? 'Local não informado');
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _ConsultationDetailsPage(
                                appointment: appointment,
                                patientName: patientName,
                                clinicLocationText: clinicLocationText,
                                backButtonText: 'Voltar para tela de inicio',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(42, 8, 0, 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0x99B58F8F),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _buildInitials(patientName),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 14,
                                          color: AppColors.textDark,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _formatDateTime(
                                            appointment.appointmentDate,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        if (clinicLocationText.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColors.textDark,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            clinicLocationText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // Patient search overlay shown when user types in the search bar
        if (widget.searchTerm.trim().isNotEmpty)
          FutureBuilder<DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final query = widget.searchTerm.trim().toLowerCase();
              final patients = snapshot.data!.patients
                  .where((p) => p.name.toLowerCase().contains(query))
                  .toList();
              return _PatientSearchOverlay(
                patients: patients,
                onSelectPatient: (patient) {
                  widget.onSelectApiPatient(patient);
                  widget.onSectionChanged(_DesktopSection.patients);
                },
              );
            },
          ),
      ],
    );
  }
}

class _HomeUserSummaryCard extends StatelessWidget {
  const _HomeUserSummaryCard({this.currentUser});

  final ApiUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final displayName = _buildFirstAndLastName(
      currentUser?.name ?? 'Profissional',
    );
    final imageProvider = _resolveAvatarImageProvider(currentUser?.image);
    final hasImage = imageProvider != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sidePanel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.wine,
            backgroundImage: imageProvider,
            child: hasImage
                ? null
                : Text(
                    _buildInitials(displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFA3A3), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A760000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF7DCDC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD9B0B0)),
              ),
              child: Icon(icon, color: AppColors.textDark, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiPatientsListDesktop extends StatefulWidget {
  const _ApiPatientsListDesktop({
    this.currentUser,
    required this.searchTerm,
    required this.onSelectPatient,
  });

  final ApiUser? currentUser;
  final String searchTerm;
  final ValueChanged<ApiPatient> onSelectPatient;

  @override
  State<_ApiPatientsListDesktop> createState() =>
      _ApiPatientsListDesktopState();
}

class _ApiPatientsListDesktopState extends State<_ApiPatientsListDesktop> {
  final ApiClient _api = ApiClient();
  late Future<List<ApiPatient>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPatients();
  }

  Future<List<ApiPatient>> _loadPatients() async {
    final doctorId = widget.currentUser?.id ?? '';
    final allPatients = await _api.fetchPatients();
    if (doctorId.isEmpty) return allPatients;
    return allPatients.where((p) => p.doctorId == doctorId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DesktopSectionHeader(title: 'Configuração'),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Lista de pacientes',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<ApiPatient>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar pacientes: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final query = widget.searchTerm.trim().toLowerCase();
              final patients = (snapshot.data ?? [])
                  .where(
                    (p) =>
                        query.isEmpty || p.name.toLowerCase().contains(query),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.name.trim().toLowerCase().compareTo(
                        b.name.trim().toLowerCase(),
                      ),
                );

              final groupedPatients = <String, List<ApiPatient>>{};
              for (final patient in patients) {
                final cleanName = patient.name.trim();
                final letter =
                    cleanName.isEmpty ? '#' : cleanName[0].toUpperCase();
                groupedPatients.putIfAbsent(letter, () => []).add(patient);
              }
              final groupKeys = groupedPatients.keys.toList()..sort();

              if (patients.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum paciente encontrado.',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: groupKeys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (_, index) {
                  final groupLetter = groupKeys[index];
                  final groupItems = groupedPatients[groupLetter]!;
                  final isSinglePatientGroup = groupItems.length == 1;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          margin: EdgeInsets.only(
                            top: isSinglePatientGroup ? 0 : 18,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x99B58F8F)),
                          ),
                          child: Center(
                            child: Text(
                              groupLetter,
                              style: const TextStyle(
                                fontSize: 22,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index != 0)
                                const Divider(
                                  color: Color(0x99B58F8F),
                                  thickness: 1,
                                  height: 1,
                                ),
                              SizedBox(
                                height: isSinglePatientGroup ? 0 : 10,
                              ),
                              ...groupItems.map(
                                (patient) => InkWell(
                                  onTap: () => widget.onSelectPatient(patient),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10,
                                      left: 4,
                                      right: 2,
                                    ),
                                    child: Text(
                                      patient.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: Color(0xFF141414),
                                        fontWeight: FontWeight.w500,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> _openDocument(
  ApiPatient patient,
  ApiUser? currentUser,
  String documentType, {
  bool prefillDate = true,
}) async {
  var resolvedUser = currentUser;
  final currentCrm = (resolvedUser?.crm ?? '').trim();
  final currentUserId = resolvedUser?.id.trim() ?? '';

  if (currentCrm.isEmpty && currentUserId.isNotEmpty) {
    try {
      resolvedUser = await ApiClient().fetchUserById(currentUserId);
    } catch (_) {}
  }

  final now = DateTime.now();
  final currentDate = prefillDate
      ? '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
      : '';
  final doctorName = resolvedUser?.name ?? 'Médico Responsável';
  final doctorCrm = (resolvedUser?.crm ?? '').trim();
  final birthDateStr = patient.birthDate != null ? _formatDate(patient.birthDate!) : '-';

  const sharedStyles = '''
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: 'Times New Roman', Times, serif;
            margin: 0;
            padding: 40px;
            color: #000;
            background: white;
        }
        .no-print {
            margin-bottom: 20px;
            text-align: center;
        }
        .print-button {
            background: #7A1717;
            color: white;
            border: none;
            padding: 10px 22px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 15px;
            font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .title {
            text-align: center;
            font-size: 22px;
            font-weight: bold;
            margin-bottom: 40px;
            letter-spacing: 0.8px;
        }
        .content {
            min-height: calc(100vh - 120px);
            position: relative;
        }
        .field {
            display: flex;
            align-items: baseline;
            gap: 6px;
            margin-bottom: 14px;
            font-size: 15px;
        }
        .field strong {
            white-space: nowrap;
            font-size: 15px;
        }
        .field-line {
            display: inline-block;
            width: 40%;
            border-bottom: 1px solid #000;
            padding-bottom: 2px;
            vertical-align: middle;
            min-height: 20px;
            outline: none;
        }
        .field-line:focus { background: #fffbe6; }
        .free-text {
            width: 100%;
            min-height: 120px;
            border: 1px dashed #aaa;
            padding: 8px;
            font-family: inherit;
            font-size: 15px;
            line-height: 1.8;
            outline: none;
        }
        .free-text:focus { background: #fffbe6; border-color: #7A1717; }
        .footer {
            position: absolute;
            bottom: 40px;
            left: 0;
            right: 0;
            font-size: 15px;
        }
        .footer .field { margin-bottom: 18px; }
        .edit-hint {
            font-size: 12px;
            color: #888;
            margin-bottom: 16px;
            text-align: center;
            font-style: italic;
        }
        @media print {
            .no-print { display: none; }
            .field-line:focus, .free-text:focus { background: transparent; }
            .free-text { border: none; padding: 0; }
            .edit-hint { display: none; }
            .content { min-height: unset; }
            .footer { position: relative; bottom: unset; margin-top: 40px; }
        }
    ''';

  const sharedScript = '''
        function printDoc() { window.print(); }
    ''';

  String htmlContent = '';

  switch (documentType) {
    case 'Relatório Médico':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>$sharedStyles</style>
    <script>$sharedScript</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="content">
        <div class="title" style="margin-top: 60px;">RELATÓRIO MÉDICO DE SITUAÇÃO CLÍNICA</div>

        <div class="field" style="margin-top: 40px;">
            <strong>Nome do paciente:</strong>
            <span class="field-line" contenteditable="true">${patient.name}</span>
        </div>
        <div class="field">
            <strong>CPF:</strong>
            <span class="field-line" contenteditable="true">${patient.cpf}</span>
        </div>

        <div class="free-text" contenteditable="true" style="min-height:200px; margin-top: 28px;"></div>

        <div class="footer" style="position: relative; bottom: unset; margin-top: 420px;">
            <div class="field">
                <strong>Nome do médico:</strong>
                <span class="field-line" contenteditable="true">$doctorName</span>
            </div>
            <div class="field">
                <strong>CRM/UF:</strong>
                <span class="field-line" contenteditable="true">$doctorCrm</span>
            </div>
            <div class="field">
                <strong>Assinatura:</strong>
                <span class="field-line"></span>
            </div>
            <div class="field">
                <strong>Data:</strong>
                <span contenteditable="true">$currentDate</span>
            </div>
        </div>
    </div>
</body>
</html>
      ''';
      break;

    case 'Receita':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>$sharedStyles</style>
    <script>$sharedScript</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="content">
        <div class="title" style="margin-top: 60px;">RECEITUÁRIO MÉDICO</div>

        <div class="field" style="margin-top: 40px;">
            <strong>Nome do paciente:</strong>
            <span class="field-line" contenteditable="true">${patient.name}</span>
        </div>
        <div class="field">
            <strong>CPF:</strong>
            <span class="field-line" contenteditable="true">${patient.cpf}</span>
        </div>

        <div class="free-text" contenteditable="true" style="min-height:200px; margin-top: 28px;"></div>

        <div class="footer" style="position: relative; bottom: unset; margin-top: 420px;">
            <div class="field">
                <strong>Nome do médico:</strong>
                <span class="field-line" contenteditable="true">$doctorName</span>
            </div>
            <div class="field">
                <strong>CRM/UF:</strong>
                <span class="field-line" contenteditable="true">$doctorCrm</span>
            </div>
            <div class="field">
                <strong>Assinatura:</strong>
                <span class="field-line"></span>
            </div>
            <div class="field">
                <strong>Data:</strong>
                <span contenteditable="true">$currentDate</span>
            </div>
        </div>
    </div>
</body>
</html>
      ''';
      break;

    case 'Encaminhamento':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Encaminhamento Médico</title>
    <style>
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 60px 40px 40px 40px;
            color: #000;
            background: white;
            font-size: 14px;
        }
        .no-print { margin-bottom: 20px; text-align: center; }
        .print-button {
            background: #7A1717; color: white; border: none;
            padding: 10px 22px; border-radius: 6px; cursor: pointer;
            font-size: 15px; font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .edit-hint { font-size: 12px; color: #888; margin-bottom: 16px; text-align: center; font-style: italic; }
        .title {
            text-align: center;
            font-size: 15px;
            font-weight: bold;
            margin-bottom: 36px;
            letter-spacing: 0.5px;
        }
        .section-title {
            color: #c0392b;
            font-size: 17px;
            font-weight: bold;
            margin-top: 28px;
            margin-bottom: 14px;
        }
        .fl {
            display: inline-block;
            border-bottom: 1px solid #000;
            min-height: 18px;
            outline: none;
            vertical-align: bottom;
        }
        .fl:focus { background: #fffbe6; }
        .fl-long { width: 420px; }
        .fl-medium { width: 260px; }
        .fl-short { width: 160px; }
        .row { margin-bottom: 10px; font-size: 14px; }
        .divider { border: none; border-top: 1px solid #555; margin: 18px 0; }
        @media print {
            .no-print { display: none; }
            .edit-hint { display: none; }
            .fl:focus { background: transparent; }
        }
    </style>
    <script>function printDoc() { window.print(); }</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="title">ENCAMINHAMENTO MÉDICO</div>

    <div class="row"><strong>Nome do paciente:</strong> <span class="fl fl-long" contenteditable="true">${patient.name}</span></div>
    <div class="row"><strong>CPF:</strong> <span class="fl fl-medium" contenteditable="true">${patient.cpf}</span></div>

    <br><br><br>

    <div class="row">Encaminho&nbsp;&nbsp;paciente para avaliação em:</div>

    <div class="row" style="margin-top: 18px;"><strong>Especialidade:</strong> <span class="fl fl-long" contenteditable="true"></span></div>

    <div class="row" style="margin-top: 22px;"><strong>Resumo clínico:</strong></div>
    <div class="row" style="margin-top: 30px;">Paciente em acompanhamento por: <span class="fl fl-long" contenteditable="true"></span></div>

    <hr class="divider" style="margin-top: 30px;">

    <div class="row" style="margin-top: 42px;">Comorbidades:<span class="fl fl-long" contenteditable="true"></span></div>
    <div class="row" style="margin-top: 42px;">Medicações em uso: <span class="fl fl-long" contenteditable="true"></span></div>
    <div class="row" style="margin-top: 42px;">Exames já realizados:<span class="fl fl-long" contenteditable="true"></span></div>

    <br>

    <div class="row" style="margin-top: 42px;"><strong>Justificativa:</strong> <span class="fl fl-long" contenteditable="true"></span></div>

    <br><br>

    <div class="row">Nome do médico <span class="fl fl-long" contenteditable="true">$doctorName</span></div>
    <div class="row">CRM/UF: <span class="fl fl-medium" contenteditable="true">$doctorCrm</span></div>

    <br>

    <div class="row">Assinatura: <span class="fl fl-medium" contenteditable="true"></span></div>
    <div class="row">Data: <span contenteditable="true">$currentDate</span></div>
</body>
</html>
      ''';
      break;

    case 'Atestado Médico':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Atestado Médico</title>
    <style>
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 60px 40px 40px 40px;
            color: #000;
            background: white;
            font-size: 14px;
        }
        .no-print { margin-bottom: 20px; text-align: center; }
        .print-button {
            background: #7A1717; color: white; border: none;
            padding: 10px 22px; border-radius: 6px; cursor: pointer;
            font-size: 15px; font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .edit-hint { font-size: 12px; color: #888; margin-bottom: 16px; text-align: center; font-style: italic; }
        .title { text-align: center; font-size: 15px; font-weight: bold; margin-bottom: 36px; }
        .fl {
            display: inline-block;
            border-bottom: 1px solid #000;
            min-height: 18px;
            outline: none;
            vertical-align: bottom;
        }
        .fl:focus { background: #fffbe6; }
        .fl-long { width: 420px; }
        .fl-medium { width: 150px; }
        .fl-short { width: 60px; }
        .fl-date { width: 50px; }
        .row { margin-bottom: 8px; font-size: 14px; }
        @media print {
            .no-print { display: none; }
            .edit-hint { display: none; }
            .fl:focus { background: transparent; }
        }
    </style>
    <script>function printDoc() { window.print(); }</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="title">ATESTADO MÉDICO</div>

    <div class="row"><strong>Nome:</strong> <span class="fl fl-long" contenteditable="true">${patient.name}</span></div>
    <div class="row"><strong>CPF:</strong> <span class="fl fl-medium" contenteditable="true">${patient.cpf}</span></div>

    <br><br><br>

    <div class="row">
        Atesto, para os devidos fins, que o(a) Sr.(a) <span class="fl fl-long" contenteditable="true">${patient.name}</span>
    </div>
    <div class="row">
        encontra-se sob cuidados médicos, necessitando de afastamento de suas atividades
    </div>
    <div class="row">
        laborais por <span class="fl fl-short" contenteditable="true"></span>
        (<span class="fl fl-medium" contenteditable="true"></span>)
        dias, a partir de <span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span>.
    </div>

    <br>

    <div class="row">O paciente encontra-se orientado quanto ao tratamento e acompanhamento.</div>

    <br><br>

    <div class="row">CID: <span class="fl fl-medium" contenteditable="true"></span></div>

    <br><br><br>

    <div class="row">Nome do médico <span class="fl fl-long" contenteditable="true">$doctorName</span></div>
    <div class="row">CRM/UF: <span class="fl fl-medium" contenteditable="true">$doctorCrm</span></div>

    <br>

    <div class="row">Assinatura: <span class="fl fl-medium" contenteditable="true"></span></div>
    <div class="row">Data: <span contenteditable="true">$currentDate</span></div>
</body>
</html>
      ''';
      break;

    case 'Atestado da Doença':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: 'Times New Roman', Times, serif;
            margin: 0;
            padding: 60px 40px 40px 40px;
            color: #000;
            background: white;
            font-size: 14px;
        }
        .no-print { margin-bottom: 20px; text-align: center; }
        .print-button {
            background: #7A1717; color: white; border: none;
            padding: 10px 22px; border-radius: 6px; cursor: pointer;
            font-size: 15px; font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .edit-hint { font-size: 12px; color: #888; margin-bottom: 16px; text-align: center; font-style: italic; }
        .title { text-align: center; font-size: 16px; font-weight: bold; margin-bottom: 40px; }
        .fl {
            display: inline-block;
            border-bottom: 1px solid #000;
            min-height: 18px;
            outline: none;
            vertical-align: bottom;
        }
        .fl-long { width: 420px; }
        .fl-medium { width: 220px; }
        .fl-short { width: 120px; }
        .fl-date { width: 40px; text-align: center; }
        .row { margin-bottom: 8px; font-size: 14px; }
        @media print { .no-print { display: none; } }
    </style>
    <script>function printDoc() { window.print(); }</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="title">ATESTADO MÉDICO</div>

    <div class="row"><strong>Nome do paciente:</strong> <span class="fl fl-long" contenteditable="true">${patient.name}</span></div>
    <div class="row"><strong>CPF:</strong> <span class="fl fl-medium" contenteditable="true">${patient.cpf}</span></div>

    <br><br>

    <p style="margin: 0 0 20px 0; line-height: 1.7;">
        Atesto, para os devidos fins, que o(a) paciente acima identificado(a) encontra-se em
        acompanhamento médico especializado, necessitando de seguimento clínico periódico,
        realização de exames e adesão terapêutica contínua. Com diagnóstico em
        <span class="fl fl-short" contenteditable="true"></span>
        de Infecção pelo vírus da imunodeficiência humana – HIV.
    </p>

    <div class="row" style="margin-top: 16px;">CID-10: B24</div>

    <br>

    <div class="row">CD4: <span class="fl" contenteditable="true" style="width:100px;"></span> células/mm³ &nbsp; Data do exame: <span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span></div>
    <div class="row">Carga viral: <span class="fl" contenteditable="true" style="width:200px;"></span> &nbsp; Data do exame: <span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span></div>
    <div class="row">Em uso de TARV: □ Sim □ Não</div>
    <div class="row">Esquema: <span class="fl" contenteditable="true" style="width:360px;"></span></div>

    <br>

    <div class="row">Comorbidades associadas: <span class="fl" contenteditable="true" style="width:340px;"></span></div>

    <br><br><br><br><br><br><br>

    <div class="row">$doctorName</div>
    <div class="row">CRM/UF: <span class="fl fl-medium" contenteditable="true">$doctorCrm</span></div>

    <br>

    <div class="row">Assinatura: <span class="fl" contenteditable="true" style="width:340px;"></span></div>
    <div class="row">Data: $currentDate</div>
</body>
</html>
      ''';
      break;

    case 'Declaração de Comparecimento':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: 'Times New Roman', Times, serif;
            margin: 0;
            padding: 60px 40px 40px 40px;
            color: #000;
            background: white;
            font-size: 14px;
        }
        .no-print { margin-bottom: 20px; text-align: center; }
        .print-button {
            background: #7A1717; color: white; border: none;
            padding: 10px 22px; border-radius: 6px; cursor: pointer;
            font-size: 15px; font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .edit-hint { font-size: 12px; color: #888; margin-bottom: 16px; text-align: center; font-style: italic; }
        .title { text-align: center; font-size: 15px; font-weight: bold; margin-bottom: 40px; }
        .fl {
            display: inline-block;
            border-bottom: 1px solid #000;
            min-height: 18px;
            outline: none;
            vertical-align: bottom;
        }
        .fl-long { width: 380px; }
        .fl-medium { width: 220px; }
        .fl-short { width: 80px; }
        .fl-date { width: 45px; text-align: center; }
        .row { margin-bottom: 6px; font-size: 14px; }
        p { margin: 0 0 16px 0; line-height: 1.7; }
        @media print { .no-print { display: none; } }
    </style>
    <script>function printDoc() { window.print(); }</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="title">DECLARAÇÃO DE COMPARECIMENTO</div>

    <div class="row"><strong>Nome do paciente:</strong> <span class="fl fl-long" contenteditable="true">${patient.name}</span></div>
    <div class="row"><strong>CPF:</strong> <span class="fl fl-medium" contenteditable="true">${patient.cpf}</span></div>

    <br>

    <p>
        Declaro, para os devidos fins, que o(a) Sr.(a)<span class="fl fl-long" contenteditable="true" style="margin-left:4px;"></span><br>
        compareceu a atendimento médico nesta unidade de saúde na data de<span class="fl fl-date" contenteditable="true" style="margin-left:4px;"></span>/<span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span>, no período <span class="fl fl-medium" contenteditable="true"></span>.
    </p>

    <p>
        A presente declaração é fornecida para fins de comprovação de comparecimento,<br>
        não contendo informações clínicas, conforme normas éticas e de sigilo médico.
    </p>

    <br><br><br><br>

    <div class="row">$doctorName</div>
    <div class="row">CRM/UF: <span class="fl fl-medium" contenteditable="true">$doctorCrm</span></div>

    <br>

    <div class="row">Assinatura: <span class="fl" contenteditable="true" style="width:280px;"></span></div>

    <br>

    <div class="row">Data: <span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span>/<span class="fl fl-date" contenteditable="true"></span></div>
</body>
</html>
      ''';
      break;

    case 'Encaminhamento ao CRIE':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 60px 40px 40px 40px;
            color: #000;
            background: white;
            font-size: 13px;
        }
        .no-print { margin-bottom: 20px; text-align: center; }
        .print-button {
            background: #7A1717; color: white; border: none;
            padding: 10px 22px; border-radius: 6px; cursor: pointer;
            font-size: 15px; font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .edit-hint { font-size: 12px; color: #888; margin-bottom: 16px; text-align: center; font-style: italic; }
        .title { font-size: 13px; font-weight: bold; margin-bottom: 24px; }
        .fl {
            display: inline-block;
            border-bottom: 1px solid #000;
            min-height: 18px;
            outline: none;
            vertical-align: bottom;
        }
        .fl-long { width: 400px; }
        .fl-medium { width: 200px; }
        .fl-short { width: 100px; }
        .row { margin-bottom: 6px; font-size: 13px; }
        .free-text {
            display: block;
            width: 100%;
            border-bottom: 1px solid #000;
            min-height: 22px;
            outline: none;
            margin-bottom: 8px;
        }
        @media print { .no-print { display: none; } }
    </style>
    <script>function printDoc() { window.print(); }</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="title">ENCAMINHAMENTO AO CRIE – CENTRO DE REFERÊNCIA PARA IMUNOBIOLÓGICOS ESPECIAIS</div>

    <br>

    <div class="row"><strong>Nome do paciente:</strong> <span class="fl fl-long" contenteditable="true">${patient.name}</span></div>
    <div class="row"><strong>CPF:</strong> <span class="fl fl-medium" contenteditable="true">${patient.cpf}</span></div>

    <br><br>

    <p style="margin: 0 0 24px 0; line-height: 1.7; font-size: 13px;">
        Encaminho o paciente acima identificado ao <strong>Centro de Referência para Imunobiológicos Especiais (CRIE)</strong> para avaliação e possível administração de imunobiológico especiais, conforme indicação clínica e liberação dos imunobiológicos especiais, conforme protocolos vigentes do PNI/MS.
    </p>

    <div class="row" style="margin-bottom: 24px;"><strong>Condição clínica / diagnóstico/CID:</strong> <span class="fl" contenteditable="true" style="width:320px;"></span></div>

    <br>

    <div style="margin-bottom: 8px;"><strong>Resumo clínico relevante:</strong></div>
    <div class="free-text" contenteditable="true"></div>
    <div class="free-text" contenteditable="true"></div>
    <div class="free-text" contenteditable="true"></div>

    <br><br>

    <div class="row">$doctorName</div>
    <div class="row">CRM/UF: <span class="fl fl-medium" contenteditable="true">$doctorCrm</span></div>

    <br>

    <div class="row">Assinatura: <span class="fl" contenteditable="true" style="width:280px;"></span></div>

    <br>

    <div class="row">Data: $currentDate</div>
</body>
</html>
      ''';
      break;

    case 'Solicitação de Exames':
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <style>
        @page { margin: 0; }
        * { box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 60px 40px 40px 40px;
            color: #000;
            background: white;
            font-size: 13px;
        }
        .no-print { margin-bottom: 20px; text-align: center; }
        .print-button {
            background: #7A1717; color: white; border: none;
            padding: 10px 22px; border-radius: 6px; cursor: pointer;
            font-size: 15px; font-weight: bold;
        }
        .print-button:hover { background: #5d1212; }
        .edit-hint { font-size: 12px; color: #888; margin-bottom: 16px; text-align: center; font-style: italic; }
        .title { text-align: center; font-size: 13px; font-weight: bold; margin-bottom: 28px; }
        .fl {
            display: inline-block;
            border-bottom: 1px solid #000;
            min-height: 18px;
            outline: none;
            vertical-align: bottom;
        }
        .fl-long { width: 400px; }
        .fl-medium { width: 200px; }
        .fl-short { width: 100px; }
        .row { margin-bottom: 4px; font-size: 13px; }
        @media print { .no-print { display: none; } }
    </style>
    <script>function printDoc() { window.print(); }</script>
</head>
<body>
    <div class="no-print">
        <button class="print-button" onclick="printDoc()">🖨️ Imprimir / Baixar PDF</button>
    </div>
    <p class="edit-hint no-print">Clique nos campos para editar antes de imprimir.</p>

    <div class="title">SOLICITAÇÃO DE EXAMES</div>

    <div class="row"><strong>Nome do paciente:</strong> <span class="fl fl-long" contenteditable="true">${patient.name}</span></div>
    <div class="row"><strong>CPF:</strong> <span class="fl fl-medium" contenteditable="true">${patient.cpf}</span></div>

    <br><br><br>

    <div style="margin-bottom: 6px;">Solicito:</div>
    <div contenteditable="true" style="outline:none; min-height:220px; line-height:1.8;"></div>

    <br>

    <div class="row"><strong>Indicação clínica:</strong><span class="fl" contenteditable="true" style="width:360px;"></span></div>

    <br>

    <div class="row">$doctorName</div>
    <div class="row">CRM/UF: <span class="fl fl-medium" contenteditable="true">$doctorCrm</span></div>

    <br>

    <div class="row">Assinatura: <span class="fl" contenteditable="true" style="width:280px;"></span></div>

    <br>

    <div class="row">Data: $currentDate</div>
</body>
</html>
      ''';
      break;
  }

  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
}

class _ApiPatientProfileDesktop extends StatefulWidget {
  const _ApiPatientProfileDesktop({
    required this.patient,
    this.currentUser,
    required this.onBack,
    required this.onNewConsultation,
  });

  final ApiPatient patient;
  final ApiUser? currentUser;
  final VoidCallback onBack;
  final VoidCallback onNewConsultation;

  @override
  State<_ApiPatientProfileDesktop> createState() =>
      _ApiPatientProfileDesktopState();
}

class _ApiPatientProfileDesktopState extends State<_ApiPatientProfileDesktop> {
  final ApiClient _api = ApiClient();
  late Future<List<ApiAppointment>> _consultationsFuture;
  late ApiPatient _patientData;
  String? _editingPatientField;
  TextEditingController? _patientEditingController;
  bool _savingPatientField = false;

  @override
  void initState() {
    super.initState();
    _patientData = widget.patient;
    _consultationsFuture = _api.fetchAppointments(patientId: widget.patient.id);
  }

  @override
  void didUpdateWidget(covariant _ApiPatientProfileDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient.id != widget.patient.id) {
      _patientData = widget.patient;
      _consultationsFuture = _api.fetchAppointments(patientId: widget.patient.id);
    }
  }

  @override
  void dispose() {
    _patientEditingController?.dispose();
    super.dispose();
  }

  DateTime? _parseOptionalDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final ddmmyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final match = ddmmyyyy.firstMatch(trimmed);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final parsed = DateTime.tryParse(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      );
      if (parsed != null &&
          parsed.day == day &&
          parsed.month == month &&
          parsed.year == year) {
        return parsed;
      }
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  void _startEditPatientField(String field, String value) {
    _patientEditingController?.dispose();
    setState(() {
      _editingPatientField = field;
      _patientEditingController = TextEditingController(text: value);
    });
  }

  void _cancelEditPatientField() {
    _patientEditingController?.dispose();
    setState(() {
      _editingPatientField = null;
      _patientEditingController = null;
      _savingPatientField = false;
    });
  }

  Future<void> _savePatientField(String field) async {
    final controller = _patientEditingController;
    if (controller == null) return;
    final rawValue = controller.text.trim();

    try {
      setState(() => _savingPatientField = true);
      ApiPatient updated;

      switch (field) {
        case 'name':
          if (rawValue.isEmpty) throw Exception('Nome é obrigatório.');
          updated = await _api.updatePatient(id: _patientData.id, name: rawValue);
          break;
        case 'cpf':
          final normalized = rawValue.replaceAll(RegExp(r'\D'), '');
          if (normalized.length != 11) {
            throw Exception('CPF inválido. Informe 11 números.');
          }
          updated = await _api.updatePatient(id: _patientData.id, cpf: normalized);
          break;
        case 'age':
          final parsed = rawValue.isEmpty ? null : int.tryParse(rawValue);
          if (rawValue.isNotEmpty && parsed == null) {
            throw Exception('Idade inválida.');
          }
          updated = await _api.updatePatient(id: _patientData.id, age: parsed);
          break;
        case 'birthDate':
          final parsedDate = _parseOptionalDate(rawValue);
          if (rawValue.isNotEmpty && parsedDate == null) {
            throw Exception('Data de nascimento inválida. Use DD/MM/AAAA.');
          }
          updated = await _api.updatePatient(
            id: _patientData.id,
            birthDate: parsedDate,
          );
          break;
        case 'maritalStatus':
          updated = await _api.updatePatient(
            id: _patientData.id,
            maritalStatus: rawValue,
          );
          break;
        case 'profession':
          updated = await _api.updatePatient(
            id: _patientData.id,
            profession: rawValue,
          );
          break;
        default:
          throw Exception('Campo inválido para edição.');
      }

      if (!mounted) return;
      setState(() {
        _patientData = updated;
      });
      _cancelEditPatientField();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo atualizado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingPatientField = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }


  Widget _buildPatientGeneralInfoCard({
    required ApiPatient patient,
    required String cpfText,
    required String ageText,
    required String birthDateText,
    required String maritalStatusText,
    required String professionText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção: Nova Consulta
        _buildSectionCard(
          title: 'Nova Consulta',
          fields: [
            ('Nome Completo', patient.name, 'name', 'Nome completo'),
            ('Idade', ageText, 'age', 'Idade'),
            ('Data de nascimento', birthDateText == '-' ? '' : birthDateText, 'birthDate', 'DD/MM/AAAA'),
            ('Ocupação', patient.profession, 'profession', 'Profissão'),
            ('Status relacional', patient.maritalStatus, 'maritalStatus', 'Estado civil'),
            ('Orientação Sexual', patient.sexualOrientation, 'sexualOrientation', 'Orientação sexual'),
            ('Status sorológico do parceiro', patient.partnerSerologicalStatus, 'partnerSerologicalStatus', 'Status sorológico'),
          ],
        ),
        const SizedBox(height: 16),
        // Seção: Rastreamento e prevenção
        _buildSectionCard(
          title: 'Rastreamento e prevenção',
          editable: false,
          fields: [
            ('Risco cardiovascular', patient.cardiovascularRisk, 'cardiovascularRisk', 'Ex: Baixo, Médio, Alto'),
            ('Rastreamento de neoplasias', patient.neoplasmScreening, 'neoplasmScreening', 'Informações'),
            ('Rastreamento de coinfecções', patient.coinfectionScreening, 'coinfectionScreening', 'Informações'),
            ('Imunizações', patient.immunizations, 'immunizations', 'Vacinas realizadas'),
            ('Saúde óssea', patient.boneHealth, 'boneHealth', 'Informações'),
          ],
        ),
        const SizedBox(height: 16),
        // Seção: Status Clínico e Terapêutico do HIV
        _buildSectionCard(
          title: 'Status Clínico e Terapêutico do HIV',
          editable: false,
          fields: [
            ('Data do diagnóstico do HIV', patient.hivDiagnosisDate != null ? _formatDate(patient.hivDiagnosisDate!) : '-', 'hivDiagnosisDate', 'DD/MM/AAAA'),
            ('CD4+ Inicial', '${patient.cd4Initial ?? '-'} (${patient.cd4InitialDate != null ? _formatDate(patient.cd4InitialDate!) : '-'})', 'cd4Initial', 'Valor CD4+'),
            ('CD4+ Atual', '${patient.cd4Current ?? '-'} (${patient.cd4CurrentDate != null ? _formatDate(patient.cd4CurrentDate!) : '-'})', 'cd4Current', 'Valor CD4+'),
            ('TARV atual', patient.currentARV, 'currentARV', 'Medicamentos'),
            ('Carga viral inicial', '${patient.initialViralLoad ?? '-'} (${patient.initialViralLoadDate != null ? _formatDate(patient.initialViralLoadDate!) : '-'})', 'initialViralLoad', 'Valor'),
            ('Status virológico', patient.virologicalStatus, 'virologicalStatus', 'Indetectável, Detectável'),
            ('Adesão ao tratamento', patient.treatmentAdherence, 'treatmentAdherence', 'Boa, Média, Baixa'),
          ],
        ),
        const SizedBox(height: 16),
        // Seção: Histórico clínico
        _buildSectionCard(
          title: 'Histórico clínico',
          editable: false,
          fields: [
            ('Doenças prévias relevantes', patient.previousDiseases, 'previousDiseases', 'Doenças'),
            ('Histórico terapêutico', patient.therapeuticHistory, 'therapeuticHistory', 'Histórico'),
            ('Alergias', patient.allergies, 'allergies', 'Alergias'),
            ('Cirurgias', patient.surgeries, 'surgeries', 'Cirurgias realizadas'),
            ('Comorbidades', patient.comorbidities, 'comorbidities', 'Outras condições'),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<(String label, String value, String field, String hint)> fields,
    bool editable = true,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x99A45A5A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0x0CA45A5A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA45A5A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < fields.length; i++)
                  Column(
                    children: [
                      _buildCardFieldRow(
                        label: fields[i].$1,
                        value: fields[i].$2,
                        field: fields[i].$3,
                        hint: fields[i].$4,
                        isLast: i == fields.length - 1,
                        editable: editable,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFieldRow({
    required String label,
    required String value,
    required String field,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? hint,
    bool isLast = false,
    bool editable = true,
  }) {
    final isEditing = editable && _editingPatientField == field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isEditing)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: _buildLabelSpan(label, value),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (editable)
              IconButton(
                tooltip: 'Editar $label',
                constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                padding: EdgeInsets.zero,
                iconSize: 22,
                onPressed: _savingPatientField
                    ? null
                    : () => _startEditPatientField(field, value),
                icon: const Icon(Icons.edit, color: AppColors.wine),
              ),
            ],
          ),
        if (isEditing && _patientEditingController != null) ...[
          _EditableInput(
            controller: _patientEditingController!,
            hint: hint ?? label,
            keyboardType: keyboardType,
            inputFormatters: formatters,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _savingPatientField ? null : _cancelEditPatientField,
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFFA45A5A))),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA45A5A)),
                onPressed: _savingPatientField
                    ? null
                    : () => _savePatientField(field),
                child: _savingPatientField
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ],
        if (!isLast) const SizedBox(height: 6),
      ],
    );
  }

  String _latestNonEmptyString(
    List<ApiAppointment> appointments,
    String Function(ApiAppointment item) selector,
  ) {
    var value = '';
    final sorted = [...appointments]
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    for (final item in sorted) {
      final current = selector(item).trim();
      if (current.isNotEmpty) value = current;
    }
    return value.isNotEmpty ? value : '-';
  }

  TextSpan _buildLabelSpan(String label, String value) {
    const defaultStyle = TextStyle(
      fontSize: 18,
      color: AppColors.textDark,
      height: 1.25,
      fontWeight: FontWeight.w500,
    );

    if (label.contains('CD4+')) {
      final parts = label.split('CD4+');
      return TextSpan(
        style: defaultStyle,
        children: [
          if (parts[0].isNotEmpty) TextSpan(text: parts[0]),
          TextSpan(
            text: 'CD4',
            style: defaultStyle,
          ),
          TextSpan(
            text: '+',
            style: defaultStyle.copyWith(fontSize: 12),
          ),
          if (parts.length > 1 && parts[1].isNotEmpty) TextSpan(text: parts[1]),
          TextSpan(text: ': ${value.isEmpty ? '-' : value}'),
        ],
      );
    }
    return TextSpan(
      text: '$label: ${value.isEmpty ? '-' : value}',
      style: defaultStyle,
    );
  }

  String _latestDate(
    List<ApiAppointment> appointments,
    DateTime? Function(ApiAppointment item) selector,
  ) {
    DateTime? value;
    final sorted = [...appointments]
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    for (final item in sorted) {
      final current = selector(item);
      if (current != null) value = current;
    }
    return value != null ? _formatDate(value) : '-';
  }

  void _generateDocument(String documentType) {
    _openDocument(_patientData, widget.currentUser, documentType);
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patientData;
    final initials = _buildInitials(patient.name);
    final cpfText = patient.cpf;
    final patientAgeText = patient.age?.toString() ?? '-';
    final birthDateText =
      patient.birthDate != null ? _formatDate(patient.birthDate!) : '-';
    final patientMaritalStatusText =
      patient.maritalStatus.trim().isNotEmpty ? patient.maritalStatus : '-';
    final patientProfessionText =
      patient.profession.trim().isNotEmpty ? patient.profession : '-';
    final patientPreviousDiseasesText =
      patient.previousDiseases.trim().isNotEmpty
      ? patient.previousDiseases
      : '-';
    final patientAllergiesText =
      patient.allergies.trim().isNotEmpty ? patient.allergies : '-';
    final patientMedicationsText =
      patient.medications.trim().isNotEmpty ? patient.medications : '-';
    final zipCodeText = patient.zipCode.isNotEmpty ? patient.zipCode : '-';
    final streetText = patient.street.isNotEmpty ? patient.street : '-';
    final cityText = patient.city.isNotEmpty ? patient.city : '-';
    final neighborhoodText =
      patient.neighborhood.isNotEmpty ? patient.neighborhood : '-';
    final streetNumberText =
      patient.streetNumber.isNotEmpty ? patient.streetNumber : '-';
    final complementText =
      patient.addressComplement.isNotEmpty ? patient.addressComplement : '-';
    return FutureBuilder<List<ApiAppointment>>(
      future: _consultationsFuture,
      builder: (context, snapshot) {
        final appointments = snapshot.data ?? const <ApiAppointment>[];

        final ageText = patientAgeText == '-' ? '' : patientAgeText;
        final maritalStatusText =
            patientMaritalStatusText == '-' ? '' : patientMaritalStatusText;
        final professionText =
            patientProfessionText == '-' ? '' : patientProfessionText;
        final previousDiseasesText = _latestNonEmptyString(
          appointments,
          (a) => a.previousDiseases,
        );
        final allergiesText = _latestNonEmptyString(appointments, (a) => a.allergy);
        final medicationsText = _latestNonEmptyString(
          appointments,
          (a) => a.medicationUse,
        );
        final hivStartDateText = _latestDate(appointments, (a) => a.hivDiagnosisDate);
        final cd4Text = _latestNonEmptyString(appointments, (a) => a.cd4Nadir);
        final currentTarvText = _latestNonEmptyString(appointments, (a) => a.currentArt);
        final currentSchemeText = _latestNonEmptyString(
          appointments,
          (a) => a.currentRegimen,
        );
        final virologicalStatusText = _latestNonEmptyString(
          appointments,
          (a) => a.virologicalStatus,
        );
        final adherenceText = _latestNonEmptyString(appointments, (a) => a.adherence);
        final cardioRiskText = _latestNonEmptyString(
          appointments,
          (a) => a.cardiovascularRisk,
        );
        final neoplasiaText = _latestNonEmptyString(
          appointments,
          (a) => a.neoplasmScreening,
        );
        final coinfectionText = _latestNonEmptyString(
          appointments,
          (a) => a.coinfectionScreening,
        );
        final immunizationsText = _latestNonEmptyString(
          appointments,
          (a) => a.immunizations,
        );
        final notesText = _latestNonEmptyString(appointments, (a) => a.notes);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DesktopSectionHeader(title: 'Perfil do Paciente', onBack: widget.onBack),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: Colors.transparent,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0x99B58F8F),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                patient.name,
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Informações Gerais do Paciente:',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _ConsultationHighlightedSectionTitle('Dados gerais'),
                        const SizedBox(height: 8),
                        _buildPatientGeneralInfoCard(
                          patient: patient,
                          cpfText: cpfText,
                          ageText: ageText,
                          birthDateText: birthDateText,
                          maritalStatusText: maritalStatusText,
                          professionText: professionText,
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Color(0x99B58F8F))),
                      ),
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ConsultationHighlightedSectionTitle('Avaliação Clínica Atual'),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final withNotes = ([...appointments]
                                ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate)))
                                .where((a) => a.notes.trim().isNotEmpty)
                                .toList();
                              if (withNotes.isEmpty) {
                                return const _DesktopInfoCard(text: 'Nenhuma observação registrada.');
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final appt in withNotes) ...[
                                    _DesktopInfoCard(
                                      text: 'Consulta dia ${_formatDate(appt.appointmentDate)}:\n${appt.notes.trim()}',
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Endereço',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DesktopInfoCard(
                            text: 'CEP: $zipCodeText\nLogradouro: $streetText\nMunicípio: $cityText\nBairro: $neighborhoodText\nNúmero: $streetNumberText\nComplemento: $complementText',
                          ),
                          const SizedBox(height: 12),
                          _DesktopMainButton(
                            text: 'Nova consulta',
                            icon: Icons.medical_services_outlined,
                            onTap: widget.onNewConsultation,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Documentos disponíveis para esse CPF são:',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DesktopMainButton(
                            text: 'Relatório Médico',
                            icon: Icons.description_outlined,
                            onTap: () => _generateDocument('Relatório Médico'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Receituário Médico',
                            icon: Icons.receipt_long_outlined,
                            onTap: () => _generateDocument('Receita'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Encaminhamento',
                            icon: Icons.forward_outlined,
                            onTap: () => _generateDocument('Encaminhamento'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Atestado Médico Geral',
                            icon: Icons.medical_information_outlined,
                            onTap: () => _generateDocument('Atestado Médico'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Atestado da Doença',
                            icon: Icons.sick_outlined,
                            onTap: () => _generateDocument('Atestado da Doença'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Declaração de Comparecimento',
                            icon: Icons.event_available_outlined,
                            onTap: () => _generateDocument('Declaração de Comparecimento'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Encaminhamento ao CRIE',
                            icon: Icons.local_hospital_outlined,
                            onTap: () => _generateDocument('Encaminhamento ao CRIE'),
                          ),
                          const SizedBox(height: 8),
                          _DesktopMainButton(
                            text: 'Solicitação de Exames',
                            icon: Icons.biotech_outlined,
                            onTap: () => _generateDocument('Solicitação de Exames'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationsSectionContent extends StatefulWidget {
  const _LocationsSectionContent({this.currentUser, required this.searchTerm});

  final ApiUser? currentUser;
  final String searchTerm;

  @override
  State<_LocationsSectionContent> createState() =>
      _LocationsSectionContentState();
}

class _LocationsSectionContentState extends State<_LocationsSectionContent> {
  final ApiClient _api = ApiClient();
  late Future<List<ApiClinicLocation>> _future;
  ApiClinicLocation? _selectedLocation;
  String? _editingLocationField;
  TextEditingController? _locationEditingController;
  bool _savingLocationField = false;

  @override
  void initState() {
    super.initState();
    _future = _loadLocations();
  }

  Future<List<ApiClinicLocation>> _loadLocations() async {
    final all = await _api.fetchClinicLocations();
    final doctorId = widget.currentUser?.id ?? '';
    if (doctorId.isEmpty) return all;
    return all.where((l) => l.doctorId == doctorId).toList();
  }

  @override
  void dispose() {
    _locationEditingController?.dispose();
    super.dispose();
  }

  void _openLocationDetails(ApiClinicLocation location) {
    _locationEditingController?.dispose();
    setState(() {
      _selectedLocation = location;
      _editingLocationField = null;
      _locationEditingController = null;
    });
  }

  void _startEditLocationField(String field, String value) {
    _locationEditingController?.dispose();
    setState(() {
      _editingLocationField = field;
      _locationEditingController = TextEditingController(text: value);
    });
  }

  void _cancelEditLocationField() {
    _locationEditingController?.dispose();
    setState(() {
      _editingLocationField = null;
      _locationEditingController = null;
      _savingLocationField = false;
    });
  }

  Future<void> _saveLocationField(String field) async {
    final location = _selectedLocation;
    final controller = _locationEditingController;
    if (location == null || controller == null) return;

    final value = controller.text.trim();

    try {
      setState(() => _savingLocationField = true);
      ApiClinicLocation updated;

      switch (field) {
        case 'name':
          updated = await _api.updateClinicLocation(
            id: location.id,
            name: value,
          );
          break;
        case 'zipCode':
          final normalized = value.replaceAll(RegExp(r'\D'), '');
          if (normalized.length != 8) {
            throw Exception('CEP inválido. Informe 8 números.');
          }
          updated = await _api.updateClinicLocation(
            id: location.id,
            zipCode: normalized,
          );
          break;
        case 'street':
          if (value.isEmpty) throw Exception('Logradouro é obrigatório.');
          updated = await _api.updateClinicLocation(id: location.id, street: value);
          break;
        case 'streetNumber':
          if (value.isEmpty) throw Exception('Número é obrigatório.');
          updated = await _api.updateClinicLocation(
            id: location.id,
            streetNumber: value,
          );
          break;
        case 'neighborhood':
          updated = await _api.updateClinicLocation(
            id: location.id,
            neighborhood: value,
          );
          break;
        case 'city':
          updated = await _api.updateClinicLocation(id: location.id, city: value);
          break;
        case 'addressComplement':
          updated = await _api.updateClinicLocation(
            id: location.id,
            addressComplement: value,
          );
          break;
        default:
          throw Exception('Campo inválido para edição.');
      }

      if (!mounted) return;
      setState(() {
        _selectedLocation = updated;
        _future = _loadLocations();
      });
      _cancelEditLocationField();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo do local atualizado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingLocationField = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmAndDeleteSelectedLocation() async {
    final location = _selectedLocation;
    if (location == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir local'),
          content: const Text(
            'Tem certeza que deseja deletar este local?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _savingLocationField = true);
      await _api.deleteClinicLocation(location.id);
      if (!mounted) return;
      setState(() {
        _selectedLocation = null;
        _editingLocationField = null;
        _future = _loadLocations();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local excluído com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingLocationField = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _savingLocationField = false);
    }
  }

  Widget _buildLocationDisplayField({
    required String field,
    required String label,
    required String value,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    final isEditing = _editingLocationField == field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isEditing)
              IconButton(
                tooltip: 'Editar $label',
                constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                padding: EdgeInsets.zero,
                iconSize: 22,
                onPressed: _savingLocationField
                    ? null
                    : () => _startEditLocationField(field, value),
                icon: const Icon(Icons.edit, color: AppColors.wine),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isEditing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB58F8F)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (isEditing && _locationEditingController != null) ...[
          _EditableInput(
            controller: _locationEditingController!,
            hint: hint ?? label,
            keyboardType: keyboardType,
            inputFormatters: formatters,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _savingLocationField ? null : _cancelEditLocationField,
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFFA45A5A))),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA45A5A)),
                onPressed: _savingLocationField
                    ? null
                    : () => _saveLocationField(field),
                child: _savingLocationField
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLocationDetailChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1C9C9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.wine),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showingDetails = _selectedLocation != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesktopSectionHeader(
          title: showingDetails ? 'Detalhes do local' : 'Locais',
          onBack: showingDetails
              ? () {
                  _cancelEditLocationField();
                  setState(() => _selectedLocation = null);
                }
              : null,
        ),
        const SizedBox(height: 14),
        Text(
          showingDetails ? 'Informações do local' : 'Locais de atendimento',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<ApiClinicLocation>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar locais: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final allLocations = snapshot.data ?? const <ApiClinicLocation>[];
              ApiClinicLocation? selected = _selectedLocation;
              if (selected != null) {
                final selectedId = selected.id;
                final selectedState = _selectedLocation;
                for (final item in allLocations) {
                  if (item.id == selectedId) {
                    selected = item;
                    if (selectedState != null &&
                        (item.id != selectedState.id ||
                            item.street != selectedState.street ||
                            item.city != selectedState.city ||
                            item.zipCode != selectedState.zipCode ||
                            item.streetNumber != selectedState.streetNumber ||
                            item.neighborhood != selectedState.neighborhood ||
                            item.addressComplement != selectedState.addressComplement)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedLocation = item);
                      });
                    }
                    break;
                  }
                }
              }

              if (selected != null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9BCBC)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected.name.isNotEmpty
                                            ? selected.name
                                            : selected.displayName,
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: AppColors.wine,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              selected.displayName,
                                              style: const TextStyle(
                                                color: Color(0xFF6B6B6B),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0x1AF44336),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Excluir local',
                                    onPressed: _savingLocationField
                                        ? null
                                        : _confirmAndDeleteSelectedLocation,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildLocationDetailChip(
                                  icon: Icons.badge_outlined,
                                  label: selected.name.isNotEmpty
                                      ? 'Com nome personalizado'
                                      : 'Sem nome personalizado',
                                ),
                                _buildLocationDetailChip(
                                  icon: Icons.pin_drop_outlined,
                                  label: 'CEP: ${selected.zipCode.isEmpty ? '-' : selected.zipCode}',
                                ),
                                _buildLocationDetailChip(
                                  icon: Icons.home_work_outlined,
                                  label: selected.city.isEmpty
                                      ? 'Município não informado'
                                      : selected.city,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        runSpacing: 14,
                        spacing: 16,
                        children: [
                          SizedBox(
                            width: 350,
                            child: _buildLocationDisplayField(
                              field: 'name',
                              label: 'Nome do local',
                              value: selected.name,
                              hint: 'Ex: Consultório Centro',
                            ),
                          ),
                          SizedBox(
                            width: 240,
                            child: _buildLocationDisplayField(
                              field: 'zipCode',
                              label: 'CEP',
                              value: selected.zipCode,
                              hint: '00000-000',
                              keyboardType: TextInputType.number,
                              formatters: [CepInputFormatter()],
                            ),
                          ),
                          SizedBox(
                            width: 430,
                            child: _buildLocationDisplayField(
                              field: 'street',
                              label: 'Logradouro',
                              value: selected.street,
                              hint: 'Digite o logradouro',
                            ),
                          ),
                          SizedBox(
                            width: 170,
                            child: _buildLocationDisplayField(
                              field: 'streetNumber',
                              label: 'Número',
                              value: selected.streetNumber,
                              hint: 'Número',
                            ),
                          ),
                          SizedBox(
                            width: 290,
                            child: _buildLocationDisplayField(
                              field: 'neighborhood',
                              label: 'Bairro',
                              value: selected.neighborhood,
                              hint: 'Digite o bairro',
                            ),
                          ),
                          SizedBox(
                            width: 290,
                            child: _buildLocationDisplayField(
                              field: 'city',
                              label: 'Município',
                              value: selected.city,
                              hint: 'Digite o município',
                            ),
                          ),
                          SizedBox(
                            width: 420,
                            child: _buildLocationDisplayField(
                              field: 'addressComplement',
                              label: 'Complemento',
                              value: selected.addressComplement,
                              hint: 'Complemento',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              final query = widget.searchTerm.trim().toLowerCase();
              final locations = allLocations.where((loc) {
                if (query.isEmpty) return true;
                return loc.displayName.toLowerCase().contains(query) ||
                    loc.street.toLowerCase().contains(query);
              }).toList();
              if (locations.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum local de atendimento cadastrado.',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: locations.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Color(0x99B58F8F), thickness: 1),
                itemBuilder: (_, index) {
                  final loc = locations[index];
                  return InkWell(
                    onTap: () => _openLocationDetails(loc),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.wine,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.displayName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  loc.street,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF777777),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewLocationDesktopForm extends StatefulWidget {
  const _NewLocationDesktopForm({this.currentUser});

  final ApiUser? currentUser;

  @override
  State<_NewLocationDesktopForm> createState() => _NewLocationDesktopFormState();
}

class _NewLocationDesktopFormState extends State<_NewLocationDesktopForm> {
  final _nameCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _streetNumberCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressComplementCtrl = TextEditingController();
  final _apiClient = ApiClient();

  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _streetNumberCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _addressComplementCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired() {
    if (_zipCodeCtrl.text.trim().isEmpty) return 'CEP';
    if (_streetCtrl.text.trim().isEmpty) return 'Logradouro';
    if (_streetNumberCtrl.text.trim().isEmpty) return 'Número';
    return null;
  }

  Future<void> _save() async {
    final requiredField = _validateRequired();
    if (requiredField != null) {
      setState(() {
        _errorMsg = 'O campo $requiredField é obrigatório.';
      });
      return;
    }

    final doctorId = widget.currentUser?.id ?? '';
    if (doctorId.isEmpty) {
      setState(() {
        _errorMsg = 'Não foi possível identificar o médico logado.';
      });
      return;
    }

    final normalizedZip = _zipCodeCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (normalizedZip.length != 8) {
      setState(() {
        _errorMsg = 'CEP inválido. Informe 8 números.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await _apiClient.createClinicLocation(
        doctorId: doctorId,
        name: _nameCtrl.text,
        zipCode: _zipCodeCtrl.text,
        street: _streetCtrl.text,
        streetNumber: _streetNumberCtrl.text,
        neighborhood: _neighborhoodCtrl.text,
        city: _cityCtrl.text,
        addressComplement: _addressComplementCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local cadastrado com sucesso.')),
      );
      _nameCtrl.clear();
      _zipCodeCtrl.clear();
      _streetCtrl.clear();
      _streetNumberCtrl.clear();
      _neighborhoodCtrl.clear();
      _cityCtrl.clear();
      _addressComplementCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DesktopSectionHeader(title: 'Novo local'),
          const SizedBox(height: 16),
          const Text(
            'Cadastro de local de atendimento',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: 'Campos obrigatórios estão marcados com ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  runSpacing: 14,
                  spacing: 16,
                  children: [
                    SizedBox(
                      width: 350,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DesktopFormLabel('Nome do local (opcional):'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _nameCtrl,
                            hint: 'Ex: Consultório Centro',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RequiredDesktopFormLabel('CEP'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _zipCodeCtrl,
                            hint: '00000-000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [CepInputFormatter()],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 430,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RequiredDesktopFormLabel('Logradouro'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _streetCtrl,
                            hint: 'Digite o logradouro',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RequiredDesktopFormLabel('Número'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _streetNumberCtrl,
                            hint: 'Número',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 290,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DesktopFormLabel('Bairro (opcional):'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _neighborhoodCtrl,
                            hint: 'Digite o bairro',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 290,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DesktopFormLabel('Município (opcional):'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _cityCtrl,
                            hint: 'Digite o município',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DesktopFormLabel('Complemento (opcional):'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _addressComplementCtrl,
                            hint: 'Complemento',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: _loading ? null : _save,
                  child: Container(
                    width: 220,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _loading ? const Color(0xFFB0B0B0) : AppColors.wine,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Salvar local',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSectionContent extends StatelessWidget {
  const _ReportsSectionContent({this.currentUser, required this.searchTerm});

  final ApiUser? currentUser;
  final String searchTerm;

  static const _docs = [
    ('Relatório Médico', Icons.description_outlined),
    ('Receituário Médico', Icons.receipt_long_outlined),
    ('Encaminhamento', Icons.forward_outlined),
    ('Atestado Médico Geral', Icons.medical_information_outlined),
    ('Atestado da Doença', Icons.sick_outlined),
    ('Declaração de Comparecimento', Icons.event_available_outlined),
    ('Encaminhamento ao CRIE', Icons.local_hospital_outlined),
    ('Solicitação de Exames', Icons.biotech_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final query = searchTerm.trim().toLowerCase();
    final blankPatient = ApiPatient(id: '', name: '', cpf: '');

    final filtered = _docs.where((doc) {
      if (query.isEmpty) return true;
      return doc.$1.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DesktopSectionHeader(title: 'Relatórios'),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.only(left: 42),
          child: Text(
            'Relatórios',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 42),
          child: Text(
            'Clique em um relatório para abrir e preencher os campos.',
            style: TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum relatório encontrado.',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(42, 0, 42, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0x99B58F8F), thickness: 1),
                  itemBuilder: (_, index) {
                    final (label, icon) = filtered[index];
                    final docKey =
                        label == 'Receituário Médico' ? 'Receita' :
                        label == 'Atestado Médico Geral' ? 'Atestado Médico' :
                        label;
                    return InkWell(
                      onTap: () => _openDocument(
                        blankPatient,
                        currentUser,
                        docKey,
                        prefillDate: false,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Icon(icon, color: AppColors.wine, size: 26),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.wine,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.wine,
                                ),
                              ),
                            ),
                            const Icon(Icons.open_in_new,
                                color: AppColors.wine, size: 18),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SettingsDesktop extends StatefulWidget {
  const _SettingsDesktop({this.currentUser});
  final ApiUser? currentUser;
  @override
  State<_SettingsDesktop> createState() => _SettingsDesktopState();
}

class _SettingsDesktopState extends State<_SettingsDesktop> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _showNewPasswordField = false;
  bool _loading = false;
  String? _errorMsg;
  String? _successMsg;
  bool _nameEnabled = false;
  bool _emailEnabled = false;
  bool _currentPassEnabled = false;
  bool _newPassEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.currentUser?.name ?? '';
    _emailCtrl.text = widget.currentUser?.email ?? '';
    _imageCtrl.text = widget.currentUser?.image ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _imageCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  ImageProvider? _resolveImageProvider(String? value) {
    return _resolveAvatarImageProvider(value);
  }

  String _mimeFromExtension(String? ext) {
    final e = (ext ?? '').toLowerCase();
    if (e == 'png') return 'image/png';
    if (e == 'jpg' || e == 'jpeg') return 'image/jpeg';
    if (e == 'gif') return 'image/gif';
    if (e == 'webp') return 'image/webp';
    return 'image/png';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _errorMsg = 'Nao foi possivel ler a imagem selecionada.';
        _successMsg = null;
      });
      return;
    }
    final mime = _mimeFromExtension(file.extension);
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() {
      _imageCtrl.text = dataUrl;
      _errorMsg = null;
    });
  }

  Future<void> _save() async {
    final currentPass = _currentPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();

    if (!_currentPassEnabled || currentPass.isEmpty) {
      setState(() {
        _errorMsg =
            'Clique no ícone de editar na "Senha atual" e digite sua senha para salvar.';
        _successMsg = null;
      });
      return;
    }

    if (currentPass.length < 6) {
      setState(() {
        _errorMsg = 'A senha atual deve ter no mínimo 6 caracteres.';
        _successMsg = null;
      });
      return;
    }

    if (_showNewPasswordField && _newPassEnabled) {
      if (newPass.isEmpty) {
        setState(() {
          _errorMsg = 'Digite a nova senha.';
          _successMsg = null;
        });
        return;
      }
      if (newPass.length < 6) {
        setState(() {
          _errorMsg = 'A nova senha deve ter no mínimo 6 caracteres.';
          _successMsg = null;
        });
        return;
      }
      if (newPass == currentPass) {
        setState(() {
          _errorMsg = 'A nova senha deve ser diferente da senha atual.';
          _successMsg = null;
        });
        return;
      }
    }

    final passwordToSave = (_showNewPasswordField && _newPassEnabled)
        ? newPass
        : currentPass;

    // Always send existing image if no new one was selected
    final existingImage = widget.currentUser?.image;
    final imageToSave = _imageCtrl.text.trim().isNotEmpty
        ? _imageCtrl.text.trim()
        : existingImage;

    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });
    try {
      await ApiClient().updateProfile(
        userId: widget.currentUser!.id,
        currentPassword: currentPass,
        newPassword: passwordToSave,
        name: _nameEnabled && _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : null,
        email: _emailEnabled && _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : null,
        image: imageToSave,
      );
      setState(() {
        _successMsg = 'Dados atualizados com sucesso!';
        _loading = false;
        _nameEnabled = false;
        _emailEnabled = false;
        _currentPassEnabled = false;
        _newPassEnabled = false;
        _showNewPasswordField = false;
      });
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final isWrongPassword =
          msg.toLowerCase().contains('invalid credentials') ||
          msg.toLowerCase().contains('wrong password') ||
          msg.toLowerCase().contains('incorrect') ||
          msg.toLowerCase().contains('unauthorized') ||
          msg.toLowerCase().contains('senha');
      setState(() {
        _errorMsg = isWrongPassword
            ? 'Senha atual incorreta. Verifique e tente novamente.'
            : msg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.currentUser?.name ?? 'Médico';
    final crm = widget.currentUser?.crm ?? '—';
    final imageUrl = _imageCtrl.text.trim().isEmpty
        ? null
        : _imageCtrl.text.trim();
    final imageProvider = _resolveImageProvider(imageUrl);
    final initials = _initials(name);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DesktopSectionHeader(title: 'Meu Perfil'),
          const SizedBox(height: 24),
          // Doctor info card with Sair button
          Container(
            height: 102,
            decoration: BoxDecoration(
              color: AppColors.sidePanel,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.wine,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CRM: $crm',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF747474),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.wine,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.white, size: 15),
                        SizedBox(width: 8),
                        Text(
                          'Sair',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Page title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.wine.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_outlined,
                    color: AppColors.wine,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Alterar dados do perfil',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Form card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DesktopFormLabel('Nome completo:'),
                _EditableInput(
                  controller: _nameCtrl,
                  hint: 'Seu nome completo',
                  enabled: _nameEnabled,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _nameEnabled
                          ? Icons.lock_open_outlined
                          : Icons.edit_outlined,
                      color: AppColors.wine,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _nameEnabled = !_nameEnabled),
                  ),
                ),
                const SizedBox(height: 16),
                const _DesktopFormLabel('E-mail:'),
                _EditableInput(
                  controller: _emailCtrl,
                  hint: 'exemplo@dominio.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: _emailEnabled,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _emailEnabled
                          ? Icons.lock_open_outlined
                          : Icons.edit_outlined,
                      color: AppColors.wine,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _emailEnabled = !_emailEnabled),
                  ),
                ),
                const SizedBox(height: 16),
                const _DesktopFormLabel('Imagem de perfil:'),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF7A1717),
                            width: 1.1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Text(
                          _imageCtrl.text.trim().isEmpty
                              ? 'Nenhuma imagem selecionada'
                              : 'Imagem selecionada com sucesso',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.wine,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.upload_file,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Selecionar imagem',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _DesktopFormLabel('Senha atual:'),
                _EditableInput(
                  controller: _currentPassCtrl,
                  hint: '••••••••••',
                  obscure: true,
                  enabled: _currentPassEnabled,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _currentPassEnabled
                          ? Icons.lock_open_outlined
                          : Icons.edit_outlined,
                      color: AppColors.wine,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _currentPassEnabled = !_currentPassEnabled;
                      if (!_currentPassEnabled) _currentPassCtrl.clear();
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(
                    () => _showNewPasswordField = !_showNewPasswordField,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DDDD),
                      border: Border.all(
                        color: const Color(0xFF7A1717),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          color: AppColors.textDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showNewPasswordField
                              ? 'Cancelar alteracao de senha'
                              : 'Alterar senha',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showNewPasswordField) ...[
                  const SizedBox(height: 16),
                  const _DesktopFormLabel('Nova senha:'),
                  _EditableInput(
                    controller: _newPassCtrl,
                    hint: '••••••••••',
                    obscure: true,
                    enabled: _newPassEnabled,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _newPassEnabled
                            ? Icons.lock_open_outlined
                            : Icons.edit_outlined,
                        color: AppColors.wine,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _newPassEnabled = !_newPassEnabled;
                        if (!_newPassEnabled) _newPassCtrl.clear();
                      }),
                    ),
                  ),
                ],
                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                if (_successMsg != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _successMsg!,
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _loading ? null : _save,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _loading
                          ? const Color(0xFFB0B0B0)
                          : AppColors.wine,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Salvar alterações',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableInput extends StatelessWidget {
  const _EditableInput({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.enabled = true,
    this.suffixIcon,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool enabled;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled ? const Color(0xFF7A1717) : const Color(0xFFCCCCCC),
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(10),
        color: enabled ? Colors.white : const Color(0xFFF5F5F5),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        readOnly: !enabled,
        style: TextStyle(
          fontSize: 18,
          color: enabled ? AppColors.textDark : const Color(0xFF9E9E9E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 18, color: Color(0xFF8E8E8E)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _NewPatientDesktopForm extends StatefulWidget {
  const _NewPatientDesktopForm({
    this.currentUser,
    required this.onPatientCreated,
    required this.isSubTabOpen,
  });

  final ApiUser? currentUser;
  final VoidCallback onPatientCreated;
  final bool isSubTabOpen;

  @override
  State<_NewPatientDesktopForm> createState() => _NewPatientDesktopFormState();
}

class _NewPatientDesktopFormState extends State<_NewPatientDesktopForm> {
  final _nameCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _lastAppointmentCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _streetNumberCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressComplementCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _maritalStatusCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _previousDiseasesCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _apiClient = ApiClient();

  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _lastAppointmentCtrl.dispose();
    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _streetNumberCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _addressComplementCtrl.dispose();
    _ageCtrl.dispose();
    _birthDateCtrl.dispose();
    _maritalStatusCtrl.dispose();
    _professionCtrl.dispose();
    _previousDiseasesCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired() {
    if (_nameCtrl.text.trim().isEmpty) return 'Nome completo';
    if (_cpfCtrl.text.trim().isEmpty) return 'CPF';
    return null;
  }

  DateTime? _parseOptionalDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final ddmmyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final match = ddmmyyyy.firstMatch(trimmed);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final parsed = DateTime.tryParse(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      );
      if (parsed != null &&
          parsed.day == day &&
          parsed.month == month &&
          parsed.year == year) {
        return parsed;
      }
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  Future<void> _save() async {
    final requiredField = _validateRequired();
    if (requiredField != null) {
      setState(() {
        _errorMsg = 'O campo $requiredField é obrigatório.';
      });
      return;
    }

    final doctorId = widget.currentUser?.id ?? '';
    if (doctorId.isEmpty) {
      setState(() {
        _errorMsg = 'Não foi possível identificar o médico logado.';
      });
      return;
    }

    final formattedCpf = _cpfCtrl.text.trim();
    final cpfPattern = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');
    if (!cpfPattern.hasMatch(formattedCpf)) {
      setState(() {
        _errorMsg = 'CPF inválido. Use o padrão 000.000.000-00.';
      });
      return;
    }

    final normalizedCpf = formattedCpf.replaceAll(RegExp(r'\D'), '');
    if (normalizedCpf.length != 11) {
      setState(() {
        _errorMsg = 'CPF inválido. Informe 11 números.';
      });
      return;
    }

    final parsedLastAppointment = _parseOptionalDate(_lastAppointmentCtrl.text);
    if (_lastAppointmentCtrl.text.trim().isNotEmpty &&
        parsedLastAppointment == null) {
      setState(() {
        _errorMsg = 'Data da última consulta inválida. Use DD/MM/AAAA.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await _apiClient.createPatient(
        doctorId: doctorId,
        name: _nameCtrl.text,
        cpf: normalizedCpf,
        lastAppointment: parsedLastAppointment,
        zipCode: _zipCodeCtrl.text,
        street: _streetCtrl.text,
        streetNumber: _streetNumberCtrl.text,
        neighborhood: _neighborhoodCtrl.text,
        city: _cityCtrl.text,
        addressComplement: _addressComplementCtrl.text,
        age: _ageCtrl.text.trim().isEmpty ? null : int.tryParse(_ageCtrl.text),
        birthDate: _parseOptionalDate(_birthDateCtrl.text),
        maritalStatus: _maritalStatusCtrl.text,
        profession: _professionCtrl.text,
        previousDiseases: _previousDiseasesCtrl.text,
        allergies: _allergiesCtrl.text,
        medications: _medicationsCtrl.text,
      );

      if (!mounted) return;
      widget.onPatientCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente salvo com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DesktopSectionHeader(title: 'Novo Paciente'),
          const SizedBox(height: 16),
          const Text(
            'Cadastro de paciente',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: 'Campos obrigatórios estão marcados com ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  runSpacing: 16,
                  spacing: 16,
                  children: [
                    SizedBox(
                      width: 520,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RequiredDesktopFormLabel('Nome completo'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _nameCtrl,
                            hint: 'Digite o nome completo',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 520 : 360,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RequiredDesktopFormLabel('CPF'),
                          const SizedBox(height: 8),
                          _EditableInput(
                            controller: _cpfCtrl,
                            hint: '000.000.000-00',
                            keyboardType: TextInputType.number,
                            inputFormatters: [CpfInputFormatter()],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: widget.isSubTabOpen ? 520 : 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DesktopFormLabel('Data da última consulta (opcional):'),
                      const SizedBox(height: 8),
                      _EditableInput(
                        controller: _lastAppointmentCtrl,
                        hint: 'DD/MM/AAAA',
                        keyboardType: TextInputType.number,
                        inputFormatters: [DateInputFormatter()],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _DesktopFormLabel('Informações do paciente (opcional):'),
                const SizedBox(height: 8),
                Wrap(
                  runSpacing: 14,
                  spacing: 16,
                  children: [
                    SizedBox(
                      width: widget.isSubTabOpen ? 180 : 150,
                      child: _EditableInput(
                        controller: _ageCtrl,
                        hint: 'Idade',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 220 : 190,
                      child: _EditableInput(
                        controller: _birthDateCtrl,
                        hint: 'Nascimento (DD/MM/AAAA)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [DateInputFormatter()],
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 320 : 250,
                      child: _EditableInput(
                        controller: _maritalStatusCtrl,
                        hint: 'Estado civil',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 320 : 250,
                      child: _EditableInput(
                        controller: _professionCtrl,
                        hint: 'Ocupação',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _DesktopFormLabel('Histórico clínico (opcional):'),
                const SizedBox(height: 8),
                Wrap(
                  runSpacing: 14,
                  spacing: 16,
                  children: [
                    SizedBox(
                      width: widget.isSubTabOpen ? 410 : 330,
                      child: _EditableInput(
                        controller: _previousDiseasesCtrl,
                        hint: 'Doenças prévias',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 320 : 260,
                      child: _EditableInput(
                        controller: _allergiesCtrl,
                        hint: 'Alergias',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 320 : 260,
                      child: _EditableInput(
                        controller: _medicationsCtrl,
                        hint: 'Medicamentos em uso',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _DesktopFormLabel('Endereço (opcional):'),
                const SizedBox(height: 8),
                Wrap(
                  runSpacing: 14,
                  spacing: 16,
                  children: [
                    SizedBox(
                      width: widget.isSubTabOpen ? 250 : 220,
                      child: _EditableInput(
                        controller: _zipCodeCtrl,
                        hint: 'CEP',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CepInputFormatter()],
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 390 : 300,
                      child: _EditableInput(
                        controller: _streetCtrl,
                        hint: 'Logradouro',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 180 : 140,
                      child: _EditableInput(
                        controller: _streetNumberCtrl,
                        hint: 'Número',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 300 : 240,
                      child: _EditableInput(
                        controller: _neighborhoodCtrl,
                        hint: 'Bairro',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 300 : 240,
                      child: _EditableInput(
                        controller: _cityCtrl,
                        hint: 'Município',
                      ),
                    ),
                    SizedBox(
                      width: widget.isSubTabOpen ? 420 : 320,
                      child: _EditableInput(
                        controller: _addressComplementCtrl,
                        hint: 'Complemento',
                      ),
                    ),
                  ],
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: _loading ? null : _save,
                  child: Container(
                    width: 240,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _loading
                          ? const Color(0xFFB0B0B0)
                          : AppColors.wine,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Salvar paciente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _RequiredDesktopFormLabel extends StatelessWidget {
  const _RequiredDesktopFormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$text: ',
        style: const TextStyle(
          fontSize: 24,
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DesktopSectionHeader extends StatelessWidget {
  const _DesktopSectionHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textDark,
              size: 30,
            ),
          )
        else
          const SizedBox(width: 44),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(bottom: 7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x99B58F8F))),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopInfoCard extends StatelessWidget {
  const _DesktopInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x99A45A5A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textDark,
          height: 1.25,
        ),
      ),
    );
  }
}

class _DesktopFormLabel extends StatelessWidget {
  const _DesktopFormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DesktopMainButton extends StatelessWidget {
  const _DesktopMainButton({required this.text, this.icon, this.onTap});

  final String text;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFC4B2B2),
          border: Border.all(color: const Color(0xFF7A1717)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textDark, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopPlaceholder extends StatelessWidget {
  const _DesktopPlaceholder({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesktopSectionHeader(title: title),
        const SizedBox(height: 18),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 22, color: AppColors.textDark),
        ),
      ],
    );
  }
}

// ─────────────── Patient Search Overlay ───────────────

class _PatientSearchOverlay extends StatelessWidget {
  const _PatientSearchOverlay({
    required this.patients,
    required this.onSelectPatient,
  });

  final List<ApiPatient> patients;
  final ValueChanged<ApiPatient> onSelectPatient;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 340),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: patients.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhum paciente encontrado.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, index) {
                    final patient = patients[index];
                    return InkWell(
                      onTap: () => onSelectPatient(patient),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.wine,
                          child: Text(
                            patient.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          patient.cpf,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// ─────────────── Consultation Section ───────────────

enum _ConsultSortMode { recent, alphabetical, byLocation, byDate }

class _ConsultationSectionContent extends StatefulWidget {
  const _ConsultationSectionContent({
    this.currentUser,
    required this.searchTerm,
  });

  final ApiUser? currentUser;
  final String searchTerm;

  @override
  State<_ConsultationSectionContent> createState() =>
      _ConsultationSectionContentState();
}

class _ConsultationSectionContentState
    extends State<_ConsultationSectionContent> {
  final ApiClient _api = ApiClient();
  late Future<DashboardData> _future;
  _ConsultSortMode _sortMode = _ConsultSortMode.recent;
  String? _selectedClinicLocationId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<DashboardData> _loadData() async {
    final patients = await _api.fetchPatients();
    final allAppointments = await _api.fetchAppointments();
    final allClinicLocations = await _api.fetchClinicLocations();
    final doctorId = widget.currentUser?.id ?? '';
    final appointments = doctorId.isEmpty
        ? allAppointments
        : allAppointments.where((a) => a.doctorId == doctorId).toList();
    final clinicLocations = doctorId.isEmpty
        ? allClinicLocations
        : allClinicLocations.where((c) => c.doctorId == doctorId).toList();
    final patientNames = {for (final p in patients) p.id: p.name};
    final clinicLocationsById = {for (final c in clinicLocations) c.id: c};
    final doctorPatientIds = appointments.map((a) => a.patientId).toSet();
    final doctorPatients = patients
        .where((p) => doctorPatientIds.contains(p.id))
        .toList();
    return DashboardData(
      appointments: appointments,
      patientNames: patientNames,
      patients: doctorPatients,
      clinicLocationsById: clinicLocationsById,
    );
  }

  List<ApiAppointment> _applyFiltersAndSort(
    List<ApiAppointment> appointments,
    Map<String, String> patientNames,
  ) {
    var list = [...appointments];

    if (_sortMode == _ConsultSortMode.byLocation &&
        _selectedClinicLocationId != null &&
        _selectedClinicLocationId!.isNotEmpty) {
      list = list
          .where((a) => a.clinicLocationId == _selectedClinicLocationId)
          .toList();
    }

    if (_sortMode == _ConsultSortMode.byDate) {
      if (_startDate != null) {
        list = list
            .where((a) => !a.appointmentDate.isBefore(_startDate!))
            .toList();
      }
      if (_endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        list = list.where((a) => !a.appointmentDate.isAfter(endOfDay)).toList();
      }
    }

    switch (_sortMode) {
      case _ConsultSortMode.alphabetical:
        list.sort((a, b) {
          final aName = (patientNames[a.patientId] ?? '').toLowerCase();
          final bName = (patientNames[b.patientId] ?? '').toLowerCase();
          return aName.compareTo(bName);
        });
        break;
      case _ConsultSortMode.recent:
      case _ConsultSortMode.byLocation:
      case _ConsultSortMode.byDate:
        list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
        break;
    }

    return list;
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DesktopSectionHeader(title: 'Consulta'),
        const SizedBox(height: 12),
        _ConsultSortBar(
          sortMode: _sortMode,
          onSortChanged: (mode) => setState(() {
            _sortMode = mode;
            _selectedClinicLocationId = null;
            _startDate = null;
            _endDate = null;
          }),
        ),
        FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            if (_sortMode == _ConsultSortMode.byLocation) {
              final locationFilters = snapshot.data!.clinicLocationsById.values
                  .map(
                    (location) => _LocationFilterOption(
                      id: location.id,
                      label: location.displayName,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.label.toLowerCase().compareTo(b.label.toLowerCase()),
                );
              return _LocationFilterBar(
                locations: locationFilters,
                selectedLocationId: _selectedClinicLocationId,
                onLocationSelected: (locationId) =>
                    setState(() => _selectedClinicLocationId = locationId),
              );
            }
            if (_sortMode == _ConsultSortMode.byDate) {
              return _DateRangeBar(
                startDate: _startDate,
                endDate: _endDate,
                onPickStart: () => _pickDate(true),
                onPickEnd: () => _pickDate(false),
                onClear: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 42),
          child: Text(
            'Atendimentos',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.wine),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Falha ao carregar atendimentos.',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _future = _loadData()),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final query = widget.searchTerm.trim().toLowerCase();
              final visible =
                  _applyFiltersAndSort(
                    data.appointments,
                    data.patientNames,
                  ).where((appointment) {
                    if (query.isEmpty) return true;
                    final patientName =
                        (data.patientNames[appointment.patientId] ?? '')
                            .toLowerCase();
                    final city = appointment.city.toLowerCase();
                    final dateText = _formatDateTime(
                      appointment.appointmentDate,
                    ).toLowerCase();
                    return patientName.contains(query) ||
                        city.contains(query) ||
                        dateText.contains(query);
                  }).toList();

              if (visible.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum atendimento encontrado.',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, i) =>
                    const Divider(color: Color(0x99B58F8F), thickness: 1),
                itemBuilder: (_, index) {
                  final appointment = visible[index];
                  final patientName =
                      data.patientNames[appointment.patientId] ?? 'Paciente';
                  final clinicLocation =
                      data.clinicLocationsById[appointment.clinicLocationId];
                  final clinicLocationText = appointment.clinicLocationName.isNotEmpty
                      ? appointment.clinicLocationName
                      : (clinicLocation?.displayName ?? 'Local não informado');

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _ConsultationDetailsPage(
                            appointment: appointment,
                            patientName: patientName,
                            clinicLocationText: clinicLocationText,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(42, 8, 0, 8),
                      child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x99B58F8F),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _buildInitials(patientName),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: AppColors.textDark,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatDateTime(
                                      appointment.appointmentDate,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  if (clinicLocationText.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textDark,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      clinicLocationText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConsultationDetailsPage extends StatelessWidget {
  const _ConsultationDetailsPage({
    required this.appointment,
    required this.patientName,
    required this.clinicLocationText,
    this.backButtonText = 'Voltar para consultas',
  });

  final ApiAppointment appointment;
  final String patientName;
  final String clinicLocationText;
  final String backButtonText;

  String _boolLabel(bool? value) {
    if (value == null) return '';
    return value ? 'Sim' : 'Não';
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return '';
    return _formatDate(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(backButtonText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Detalhes da consulta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 1050;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftColumn(),
                            const SizedBox(height: 20),
                            _buildRightColumn(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLeftColumn()),
                          const SizedBox(width: 24),
                          Container(width: 2, color: const Color(0xFFB58F8F)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildRightColumn()),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ConsultationHighlightedSectionTitle('Nova Consulta'),
        const SizedBox(height: 8),
        _ConsultationReadOnlyField(label: 'Nome completo', value: patientName),
        _ConsultationReadOnlyField(label: 'Local da consulta', value: clinicLocationText),
        _ConsultationReadOnlyField(
          label: 'Idade',
          value: appointment.age?.toString() ?? '',
        ),
        _ConsultationReadOnlyField(label: 'Ocupação', value: appointment.occupation),
        _ConsultationReadOnlyField(label: 'Status relacional', value: appointment.maritalStatus),
        _ConsultationReadOnlyField(
          label: 'Orientação sexual',
          value: appointment.sexualOrientation,
        ),
        _ConsultationReadOnlyField(
          label: 'Status sorológico do parceiro',
          value: _boolLabel(appointment.concordantPartner),
        ),
        const SizedBox(height: 12),
        const _ConsultationHighlightedSectionTitle('Rastreamento e prevenção'),
        const SizedBox(height: 8),
        _ConsultationReadOnlyField(
          label: 'Risco cardiovascular',
          value: appointment.cardiovascularRisk,
        ),
        _ConsultationReadOnlyField(
          label: 'Rastreamento de neoplasias',
          value: appointment.neoplasmScreening,
        ),
        _ConsultationReadOnlyField(
          label: 'Rastreamento de coinfecções',
          value: appointment.coinfectionScreening,
        ),
        _ConsultationReadOnlyField(
          label: 'Imunizações',
          value: appointment.immunizations,
        ),
        _ConsultationReadOnlyField(
          label: 'Saúde óssea',
          value: appointment.boneHealth,
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ConsultationHighlightedSectionTitle('Status Clínico e Terapêutico do HIV'),
        const SizedBox(height: 8),
        _ConsultationReadOnlyField(
          label: 'Data do diagnóstico do HIV',
          value: _dateLabel(appointment.hivDiagnosisDate),
        ),
        _ConsultationReadOnlyField(label: 'CD4+ Atual', value: appointment.cd4Nadir),
        _ConsultationReadOnlyField(label: 'TARV atual', value: appointment.currentArt),
        _ConsultationReadOnlyField(
          label: 'Carga viral inicial',
          value: '',
        ),
        _ConsultationReadOnlyField(
          label: 'Status virológico',
          value: appointment.virologicalStatus,
        ),
        _ConsultationReadOnlyField(
          label: 'Adesão ao tratamento',
          value: appointment.adherence,
        ),
        _ConsultationReadOnlyField(
          label: 'Esquema atual',
          value: appointment.currentRegimen,
        ),
        const SizedBox(height: 12),
        const _ConsultationHighlightedSectionTitle('Histórico clínico'),
        const SizedBox(height: 8),
        _ConsultationReadOnlyField(
          label: 'Doenças prévias relevantes',
          value: appointment.previousDiseases,
        ),
        _ConsultationReadOnlyField(label: 'Alergias', value: appointment.allergy),
        _ConsultationReadOnlyField(label: 'Cirurgias', value: appointment.surgeries),
        _ConsultationReadOnlyField(
          label: 'Comorbidades',
          value: appointment.comorbidities,
        ),
        _ConsultationReadOnlyField(
          label: 'Uso de medicamentos',
          value: appointment.medicationUse,
        ),
        const SizedBox(height: 10),
        const _ConsultationHighlightedSectionTitle('Avaliação Clínica Atual'),
        const SizedBox(height: 8),
        _ConsultationReadOnlyField(
          label: 'Avaliação Clínica Atual',
          value: appointment.notes,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _ConsultationReadOnlyField extends StatelessWidget {
  const _ConsultationReadOnlyField({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;
    final displayValue = value.isNotEmpty ? value : 'Não informado';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        constraints: BoxConstraints(minHeight: isMultiline ? 118 : 52),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.1),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF5F5F5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7D6161),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 18,
                color: value.isNotEmpty
                    ? const Color(0xFF4B4B4B)
                    : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewConsultationDesktopForm extends StatelessWidget {
  const _NewConsultationDesktopForm({
    this.currentUser,
    this.initialPatient,
  });

  final ApiUser? currentUser;
  final ApiPatient? initialPatient;

  @override
  Widget build(BuildContext context) {
    return _NewConsultationDesktopFormContent(
      currentUser: currentUser,
      initialPatient: initialPatient,
    );
  }
}

class _NewConsultationDesktopFormContent extends StatefulWidget {
  const _NewConsultationDesktopFormContent({
    this.currentUser,
    this.initialPatient,
  });

  final ApiUser? currentUser;
  final ApiPatient? initialPatient;

  @override
  State<_NewConsultationDesktopFormContent> createState() =>
      _NewConsultationDesktopFormContentState();
}

class _NewConsultationDesktopFormContentState
    extends State<_NewConsultationDesktopFormContent> {
  final _apiClient = ApiClient();
  final _patientNameCtrl = TextEditingController();
  final _patientCpfCtrl = TextEditingController();
  final _patientNameFocus = FocusNode();
  final _patientCpfFocus = FocusNode();
  final _sexualOrientationCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _maritalStatusCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _concordantPartnerCtrl = TextEditingController();
  final _previousDiseasesCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _comorbiditiesCtrl = TextEditingController();
  final _surgeriesCtrl = TextEditingController();
  final _hivStartDateCtrl = TextEditingController();
  final _cd4Ctrl = TextEditingController();
  final _currentTarvCtrl = TextEditingController();
  final _viralLoadCtrl = TextEditingController();
  final _currentSchemeCtrl = TextEditingController();
  final _virologicalStatusCtrl = TextEditingController();
  final _adherenceCtrl = TextEditingController();
  final _cardioRiskCtrl = TextEditingController();
  final _neoplasiasCtrl = TextEditingController();
  final _coinfectionsCtrl = TextEditingController();
  final _immunizationsCtrl = TextEditingController();
  final _boneHealthCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();

  bool _submitting = false;
  List<ApiPatient> _doctorPatients = const [];
  List<ApiClinicLocation> _doctorClinicLocations = const [];
  String? _selectedClinicLocationId;
  ApiPatient? _selectedPatient;
  bool _showPatientSuggestions = false;

  String _dateToText(DateTime? value) => value == null ? '' : _formatDate(value);

  String _intToText(int? value) => value?.toString() ?? '';

  void _applyPatientToForm(ApiPatient patient) {
    _patientNameCtrl.text = patient.name;
    _patientCpfCtrl.text = _formatCpf(patient.cpf);
    _ageCtrl.text = _intToText(patient.age);
    _birthDateCtrl.text = _dateToText(patient.birthDate);
    _maritalStatusCtrl.text = patient.maritalStatus;
    _professionCtrl.text = patient.profession;
    _sexualOrientationCtrl.text = patient.sexualOrientation;
    _concordantPartnerCtrl.text = patient.partnerSerologicalStatus;
    _previousDiseasesCtrl.text = patient.previousDiseases;
    _allergiesCtrl.text = patient.allergies;
    _medicationsCtrl.text = patient.medications;
    _comorbiditiesCtrl.text = patient.comorbidities;
    _surgeriesCtrl.text = patient.surgeries;

    _hivStartDateCtrl.text = _dateToText(patient.hivDiagnosisDate);
    _cd4Ctrl.text = _intToText(patient.cd4Current ?? patient.cd4Initial);
    _currentTarvCtrl.text = patient.currentARV;
    _viralLoadCtrl.text = _intToText(patient.initialViralLoad);
    _currentSchemeCtrl.text = patient.therapeuticHistory;
    _virologicalStatusCtrl.text = patient.virologicalStatus;
    _adherenceCtrl.text = patient.treatmentAdherence;

    _cardioRiskCtrl.text = patient.cardiovascularRisk;
    _neoplasiasCtrl.text = patient.neoplasmScreening;
    _coinfectionsCtrl.text = patient.coinfectionScreening;
    _immunizationsCtrl.text = patient.immunizations;
    _boneHealthCtrl.text = patient.boneHealth;
    _observationsCtrl.text = '';
  }

  @override
  void initState() {
    super.initState();
    final patient = widget.initialPatient;
    if (patient != null) {
      _selectedPatient = patient;
      _applyPatientToForm(patient);
    }
    _loadDoctorPatients();
    _loadDoctorClinicLocations();
  }

  Future<void> _loadDoctorPatients() async {
    final doctorId = widget.currentUser?.id ?? '';
    if (doctorId.isEmpty) return;

    try {
      final allPatients = await _apiClient.fetchPatients();
      if (!mounted) return;
      setState(() {
        _doctorPatients = allPatients
            .where((p) => p.doctorId == doctorId)
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _doctorPatients = const [];
      });
    }
  }

  Future<void> _loadDoctorClinicLocations() async {
    final doctorId = widget.currentUser?.id ?? '';
    if (doctorId.isEmpty) return;

    try {
      final allLocations = await _apiClient.fetchClinicLocations();
      if (!mounted) return;
      final doctorLocations = allLocations
          .where((l) => l.doctorId == doctorId)
          .toList()
        ..sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      setState(() {
        _doctorClinicLocations = doctorLocations;
        if (_selectedClinicLocationId == null && doctorLocations.length == 1) {
          _selectedClinicLocationId = doctorLocations.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _doctorClinicLocations = const [];
      });
    }
  }

  List<ApiPatient> _filteredPatientSuggestions() {
    final nameQuery = _patientNameCtrl.text.trim().toLowerCase();
    if (nameQuery.isEmpty) return const [];
    final filtered = _doctorPatients.where((p) {
      return p.name.toLowerCase().contains(nameQuery);
    }).toList();
    return filtered.take(8).toList();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _formatCpf(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return '${digits.substring(0, 3)}.${digits.substring(3)}';
    if (digits.length <= 9) return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  void _selectPatientSuggestion(ApiPatient patient) {
    setState(() {
      _selectedPatient = patient;
      _applyPatientToForm(patient);
      _patientNameCtrl.selection = TextSelection.collapsed(
        offset: _patientNameCtrl.text.length,
      );
      _showPatientSuggestions = false;
    });
    _patientNameFocus.unfocus();
    _patientCpfFocus.unfocus();
  }

  DateTime? _parseOptionalDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final ddmmyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final match = ddmmyyyy.firstMatch(trimmed);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final parsed = DateTime.tryParse(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      );
      if (parsed != null &&
          parsed.day == day &&
          parsed.month == month &&
          parsed.year == year) {
        return parsed;
      }
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  bool? _mapConcordantPartner(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == 'sim' || normalized == 'true' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'nao' || normalized == 'não' || normalized == 'false' || normalized == 'no') {
      return false;
    }
    return null;
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientCpfCtrl.dispose();
    _patientNameFocus.dispose();
    _patientCpfFocus.dispose();
    _sexualOrientationCtrl.dispose();
    _ageCtrl.dispose();
    _birthDateCtrl.dispose();
    _maritalStatusCtrl.dispose();
    _professionCtrl.dispose();
    _concordantPartnerCtrl.dispose();
    _previousDiseasesCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _comorbiditiesCtrl.dispose();
    _surgeriesCtrl.dispose();
    _hivStartDateCtrl.dispose();
    _cd4Ctrl.dispose();
    _currentTarvCtrl.dispose();
    _viralLoadCtrl.dispose();
    _currentSchemeCtrl.dispose();
    _virologicalStatusCtrl.dispose();
    _adherenceCtrl.dispose();
    _cardioRiskCtrl.dispose();
    _neoplasiasCtrl.dispose();
    _coinfectionsCtrl.dispose();
    _immunizationsCtrl.dispose();
    _boneHealthCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNextStep() async {
    if (_patientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome completo do paciente.')),
      );
      return;
    }

    if (_digitsOnly(_patientCpfCtrl.text).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o CPF do paciente.')),
      );
      return;
    }

    final doctorId = widget.currentUser?.id ?? '';
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível identificar o médico logado.')),
      );
      return;
    }

    final normalizedCpf = _digitsOnly(_patientCpfCtrl.text);
    ApiPatient? patient = _selectedPatient;
    if (patient == null || _digitsOnly(patient.cpf) != normalizedCpf) {
      for (final candidate in _doctorPatients) {
        if (candidate.doctorId == doctorId &&
            _digitsOnly(candidate.cpf) == normalizedCpf) {
          patient = candidate;
          break;
        }
      }
    }

    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paciente não encontrado para o CPF informado.',
          ),
        ),
      );
      return;
    }

    if (_doctorClinicLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhum local cadastrado. Cadastre um local antes de criar a consulta.',
          ),
        ),
      );
      return;
    }

    if (_selectedClinicLocationId == null || _selectedClinicLocationId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o local da consulta.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _apiClient.createAppointment(
        doctorId: doctorId,
        patientId: patient.id,
        clinicLocationId: _selectedClinicLocationId!,
        appointmentDate: DateTime.now(),
        age: _ageCtrl.text.trim().isEmpty ? null : int.tryParse(_ageCtrl.text),
        sexualOrientation: _sexualOrientationCtrl.text,
        maritalStatus: _maritalStatusCtrl.text,
        concordantPartner: _mapConcordantPartner(_concordantPartnerCtrl.text),
        occupation: _professionCtrl.text,
        comorbidities: _comorbiditiesCtrl.text,
        previousDiseases: _previousDiseasesCtrl.text,
        allergy: _allergiesCtrl.text,
        surgeries: _surgeriesCtrl.text,
        medicationUse: _medicationsCtrl.text,
        hivDiagnosisDate: _parseOptionalDate(_hivStartDateCtrl.text),
        cardiovascularRisk: _cardioRiskCtrl.text,
        neoplasmScreening: _neoplasiasCtrl.text,
        coinfectionScreening: _coinfectionsCtrl.text,
        immunizations: _immunizationsCtrl.text,
        boneHealth: _boneHealthCtrl.text,
        notes: _observationsCtrl.text,
        currentArt: _currentTarvCtrl.text,
        adherence: _adherenceCtrl.text,
        cd4Nadir: _cd4Ctrl.text,
        virologicalStatus: _virologicalStatusCtrl.text,
        currentRegimen: _currentSchemeCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta salva com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DesktopSectionHeader(title: 'Nova consulta'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: 'Campos obrigatórios estão marcados com ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 1050;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeftColumn(),
                          const SizedBox(height: 20),
                          _buildRightColumn(),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildLeftColumn()),
                        const SizedBox(width: 24),
                        Container(width: 2, color: const Color(0xFFB58F8F)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildRightColumn()),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ConsultationHighlightedSectionTitle('Dados gerais'),
        const SizedBox(height: 8),
        _ConsultationInputField(
          label: 'Nome completo',
          controller: _patientNameCtrl,
          requiredField: true,
          focusNode: _patientNameFocus,
          onChanged: (_) {
            setState(() {
              if (_selectedPatient?.name.trim().toLowerCase() !=
                  _patientNameCtrl.text.trim().toLowerCase()) {
                _selectedPatient = null;
              }
              _showPatientSuggestions = _patientNameCtrl.text.trim().isNotEmpty;
            });
          },
        ),
        _ConsultationInputField(
          label: 'CPF',
          controller: _patientCpfCtrl,
          requiredField: true,
          focusNode: _patientCpfFocus,
          keyboardType: TextInputType.number,
          inputFormatters: [CpfInputFormatter()],
          onChanged: (_) {
            setState(() {
              if (_selectedPatient != null &&
                  _digitsOnly(_selectedPatient!.cpf) !=
                      _digitsOnly(_patientCpfCtrl.text)) {
                _selectedPatient = null;
              }
              _showPatientSuggestions = _patientNameCtrl.text.trim().isNotEmpty;
            });
          },
        ),
        if (_showPatientSuggestions)
          _PatientSuggestionsDropdown(
            patients: _filteredPatientSuggestions(),
            onSelected: _selectPatientSuggestion,
          ),
        _ConsultationLocationDropdownField(
          label: 'Local da consulta',
          requiredField: true,
          selectedId: _selectedClinicLocationId,
          locations: _doctorClinicLocations,
          onChanged: (value) =>
              setState(() => _selectedClinicLocationId = value),
        ),
        _ConsultationInputField(
          label: 'Idade',
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _ConsultationInputField(
          label: 'Data de nascimento',
          controller: _birthDateCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [DateInputFormatter()],
        ),
        _ConsultationInputField(label: 'Ocupação', controller: _professionCtrl),
        _ConsultationInputField(
          label: 'Status relacional',
          controller: _maritalStatusCtrl,
        ),
        _ConsultationInputField(
          label: 'Orientação sexual',
          controller: _sexualOrientationCtrl,
        ),
        _ConsultationInputField(
          label: 'Status sorológico do parceiro',
          controller: _concordantPartnerCtrl,
        ),
        const SizedBox(height: 12),
        const _ConsultationHighlightedSectionTitle('Rastreamento e prevenção'),
        const SizedBox(height: 8),
        _ConsultationInputField(
          label: 'Risco cardiovascular',
          controller: _cardioRiskCtrl,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calculadora PREVENT',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => html.window.open(
                      'https://professional-heart-org.translate.goog/en/guidelines-and-statements/prevent-calculator?_x_tr_sl=en&_x_tr_tl=pt&_x_tr_hl=pt&_x_tr_pto=tc',
                      '_blank',
                    ),
                    child: const Text(
                      'https://professional-heart-org.translate.goog/en/guidelines-and-statements/prevent-calculator?_x_tr_sl=en&_x_tr_tl=pt&_x_tr_hl=pt&_x_tr_pto=tc',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.wine,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ConsultationInputField(
          label: 'Rastreamento de neoplasias',
          controller: _neoplasiasCtrl,
        ),
        _ConsultationInputField(
          label: 'Rastreamento de coinfecções',
          controller: _coinfectionsCtrl,
        ),
        _ConsultationInputField(
          label: 'Imunizações',
          controller: _immunizationsCtrl,
        ),
        _ConsultationInputField(
          label: 'Saúde óssea',
          controller: _boneHealthCtrl,
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ConsultationHighlightedSectionTitle('Status Clínico e Terapêutico do HIV'),
        const SizedBox(height: 8),
        _ConsultationInputField(
          label: 'Data do diagnóstico do HIV',
          controller: _hivStartDateCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [DateInputFormatter()],
        ),
        _ConsultationInputField(
          label: 'CD4+ Atual',
          controller: _cd4Ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _ConsultationInputField(label: 'TARV atual', controller: _currentTarvCtrl),
        _ConsultationInputField(
          label: 'Carga viral inicial',
          controller: _viralLoadCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _ConsultationInputField(label: 'Status virológico', controller: _virologicalStatusCtrl),
        _ConsultationInputField(label: 'Adesão ao tratamento', controller: _adherenceCtrl),
        _ConsultationInputField(label: 'Esquema atual', controller: _currentSchemeCtrl),
        const SizedBox(height: 12),
        const _ConsultationHighlightedSectionTitle('Histórico clínico'),
        const SizedBox(height: 8),
        _ConsultationInputField(
          label: 'Doenças prévias relevantes',
          controller: _previousDiseasesCtrl,
        ),
        _ConsultationInputField(label: 'Alergias', controller: _allergiesCtrl),
        _ConsultationInputField(
          label: 'Cirurgias',
          controller: _surgeriesCtrl,
        ),
        _ConsultationInputField(label: 'Comorbidades', controller: _comorbiditiesCtrl),
        _ConsultationInputField(
          label: 'Uso de medicamentos',
          controller: _medicationsCtrl,
        ),
        const SizedBox(height: 10),
        const _ConsultationHighlightedSectionTitle('Avaliação Clínica Atual'),
        const SizedBox(height: 8),
        _ConsultationInputField(
          label: 'Avaliação Clínica Atual',
          controller: _observationsCtrl,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _submitting ? null : _onNextStep,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: _submitting ? const Color(0xFFB0B0B0) : const Color(0xFFC4B2B2),
              border: Border.all(color: const Color(0xFF7A1717)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Cadastrar Consulta',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsultationHighlightedSectionTitle extends StatelessWidget {
  const _ConsultationHighlightedSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2CACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationLocationDropdownField extends StatelessWidget {
  const _ConsultationLocationDropdownField({
    required this.label,
    required this.selectedId,
    required this.locations,
    required this.onChanged,
    this.requiredField = false,
  });

  final String label;
  final String? selectedId;
  final List<ApiClinicLocation> locations;
  final ValueChanged<String?> onChanged;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final hintText = requiredField ? '$label *:' : '$label:';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF7A1717), width: 1.1),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            hint: Text(
              hintText,
              style: const TextStyle(fontSize: 18, color: Color(0xFF8E8E8E)),
            ),
            items: locations
                .map(
                  (location) => DropdownMenuItem<String>(
                    value: location.id,
                    child: Text(
                      location.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: locations.isEmpty ? null : onChanged,
          ),
        ),
      ),
    );
  }
}

class _ConsultationInputField extends StatelessWidget {
  const _ConsultationInputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.requiredField = false,
    this.focusNode,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool requiredField;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;
    final hintText = '$label:';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: !isMultiline
          ? _EditableInput(
              controller: controller,
              hint: hintText,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              focusNode: focusNode,
              onChanged: onChanged,
              suffixIcon: requiredField
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : null,
            )
          : Container(
              constraints: const BoxConstraints(minHeight: 118),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF7A1717), width: 1.1),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                maxLines: maxLines,
                style: const TextStyle(fontSize: 18, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8E8E8E),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
    );
  }
}

class _PatientSuggestionsDropdown extends StatelessWidget {
  const _PatientSuggestionsDropdown({
    required this.patients,
    required this.onSelected,
  });

  final List<ApiPatient> patients;
  final ValueChanged<ApiPatient> onSelected;

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDBC1C1)),
        ),
        child: const Text(
          'Nenhum paciente encontrado.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBC1C1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patients.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                onSelected(patient);
              },
              hoverColor: const Color(0xFFF5E8E8),
              highlightColor: const Color(0xFFE8D4D4),
              splashColor: const Color(0xFFE8D4D4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConsultSortBar extends StatelessWidget {
  const _ConsultSortBar({required this.sortMode, required this.onSortChanged});

  final _ConsultSortMode sortMode;
  final ValueChanged<_ConsultSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Ordenar por:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          _SortChip(
            label: 'Recentes',
            active: sortMode == _ConsultSortMode.recent,
            onTap: () => onSortChanged(_ConsultSortMode.recent),
          ),
          _SortChip(
            label: 'A–Z',
            active: sortMode == _ConsultSortMode.alphabetical,
            onTap: () => onSortChanged(_ConsultSortMode.alphabetical),
          ),
          _SortChip(
            label: 'Local',
            active: sortMode == _ConsultSortMode.byLocation,
            onTap: () => onSortChanged(_ConsultSortMode.byLocation),
          ),
          _SortChip(
            label: 'Data',
            active: sortMode == _ConsultSortMode.byDate,
            onTap: () => onSortChanged(_ConsultSortMode.byDate),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.wine : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _LocationFilterOption {
  const _LocationFilterOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _LocationFilterBar extends StatelessWidget {
  const _LocationFilterBar({
    required this.locations,
    required this.selectedLocationId,
    required this.onLocationSelected,
  });

  final List<_LocationFilterOption> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onLocationSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _SortChip(
            label: 'Todos',
            active: selectedLocationId == null,
            onTap: () => onLocationSelected(null),
          ),
          ...locations.map(
            (location) => _SortChip(
              label: location.label,
              active: selectedLocationId == location.id,
              onTap: () => onLocationSelected(location.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeBar extends StatelessWidget {
  const _DateRangeBar({
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 10),
      child: Row(
        children: [
          _DatePickerButton(
            label: startDate != null
                ? 'De: ${_formatDate(startDate!)}'
                : 'Data início',
            onTap: onPickStart,
          ),
          const SizedBox(width: 10),
          _DatePickerButton(
            label: endDate != null
                ? 'Até: ${_formatDate(endDate!)}'
                : 'Data fim',
            onTap: onPickEnd,
          ),
          if (startDate != null || endDate != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.clear, size: 16, color: AppColors.textDark),
                    SizedBox(width: 4),
                    Text(
                      'Limpar',
                      style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.wine),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.wine,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

String _buildInitials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '--';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _buildFirstAndLastName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'Profissional';
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last}';
}

ImageProvider? _resolveAvatarImageProvider(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;

  final cached = _avatarImageProviderCache[raw];
  if (cached != null) return cached;

  ImageProvider? provider;

  if (raw.startsWith('data:image')) {
    final commaIndex = raw.indexOf(',');
    if (commaIndex <= 0) return null;
    final b64 = raw.substring(commaIndex + 1);
    try {
      final bytes = base64Decode(b64);
      provider = MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
    provider = NetworkImage(raw);
  } else {
    try {
      final bytes = base64Decode(raw);
      provider = MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  _avatarImageProviderCache[raw] = provider;
  return provider;
}

final Map<String, ImageProvider> _avatarImageProviderCache =
    <String, ImageProvider>{};

Future<void> _persistLoggedUser(SharedPreferences prefs, ApiUser user) async {
  await prefs.setBool(_kHasLoggedIn, true);
  await prefs.setString(_kLoggedUserJson, jsonEncode(user.toJson()));
}

ApiUser? _readLoggedUserFromPrefs(SharedPreferences prefs) {
  final rawJson = prefs.getString(_kLoggedUserJson);
  if (rawJson == null || rawJson.trim().isEmpty) return null;

  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is Map<String, dynamic>) {
      return ApiUser.fromJson(decoded);
    }
  } catch (_) {
    return null;
  }

  return null;
}
