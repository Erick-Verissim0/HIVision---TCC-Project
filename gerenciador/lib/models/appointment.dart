class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String appointmentDate;
  final int? age;
  final String? sexualOrientation;
  final String? maritalStatus;
  final bool? concordantPartner;
  final String? occupation;
  final String? comorbidities;
  final String? previousDiseases;
  final String? allergy;
  final String? surgeries;
  final String? medicationUse;
  final String? hivDiagnosisDate;
  final String? cardiovascularRisk;
  final String? neoplasmScreening;
  final String? coinfectionScreening;
  final String? immunizations;
  final String? notes;
  final String? zipCode;
  final String? street;
  final String? streetNumber;
  final String? neighborhood;
  final String? city;
  final String? addressComplement;
  final String? currentArt;
  final String? adherence;
  final String? lastViralLoad;
  final String? cd4Nadir;
  final String? virologicalStatus;
  final String? currentRegimen;
  final String? regimenStartDate;
  final String? previousRegimens;
  final String? changeReason;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.appointmentDate,
    this.age,
    this.sexualOrientation,
    this.maritalStatus,
    this.concordantPartner,
    this.occupation,
    this.comorbidities,
    this.previousDiseases,
    this.allergy,
    this.surgeries,
    this.medicationUse,
    this.hivDiagnosisDate,
    this.cardiovascularRisk,
    this.neoplasmScreening,
    this.coinfectionScreening,
    this.immunizations,
    this.notes,
    this.zipCode,
    this.street,
    this.streetNumber,
    this.neighborhood,
    this.city,
    this.addressComplement,
    this.currentArt,
    this.adherence,
    this.lastViralLoad,
    this.cd4Nadir,
    this.virologicalStatus,
    this.currentRegimen,
    this.regimenStartDate,
    this.previousRegimens,
    this.changeReason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      patientId: json['patientId'] as String,
      appointmentDate: json['appointmentDate'] as String,
      age: json['age'] as int?,
      sexualOrientation: json['sexualOrientation'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      concordantPartner: json['concordantPartner'] as bool?,
      occupation: json['occupation'] as String?,
      comorbidities: json['comorbidities'] as String?,
      previousDiseases: json['previousDiseases'] as String?,
      allergy: json['allergy'] as String?,
      surgeries: json['surgeries'] as String?,
      medicationUse: json['medicationUse'] as String?,
      hivDiagnosisDate: json['hivDiagnosisDate'] as String?,
      cardiovascularRisk: json['cardiovascularRisk'] as String?,
      neoplasmScreening: json['neoplasmScreening'] as String?,
      coinfectionScreening: json['coinfectionScreening'] as String?,
      immunizations: json['immunizations'] as String?,
      notes: json['notes'] as String?,
      zipCode: json['zipCode'] as String?,
      street: json['street'] as String?,
      streetNumber: json['streetNumber'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      addressComplement: json['addressComplement'] as String?,
      currentArt: json['currentArt'] as String?,
      adherence: json['adherence'] as String?,
      lastViralLoad: json['lastViralLoad'] as String?,
      cd4Nadir: json['cd4Nadir'] as String?,
      virologicalStatus: json['virologicalStatus'] as String?,
      currentRegimen: json['currentRegimen'] as String?,
      regimenStartDate: json['regimenStartDate'] as String?,
      previousRegimens: json['previousRegimens'] as String?,
      changeReason: json['changeReason'] as String?,
    );
  }
}
