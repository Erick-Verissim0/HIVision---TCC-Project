class Patient {
  final String id;
  final String doctorId;
  final String name;
  final String cpf;
  final String? lastAppointment;

  const Patient({
    required this.id,
    required this.doctorId,
    required this.name,
    required this.cpf,
    this.lastAppointment,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      name: json['name'] as String,
      cpf: json['cpf'] as String,
      lastAppointment: json['lastAppointment'] as String?,
    );
  }
}
