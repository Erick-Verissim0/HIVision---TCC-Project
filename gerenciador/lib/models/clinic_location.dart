class ClinicLocation {
  final String id;
  final String doctorId;
  final String zipCode;
  final String street;
  final String streetNumber;
  final String? neighborhood;
  final String? city;
  final String? addressComplement;

  const ClinicLocation({
    required this.id,
    required this.doctorId,
    required this.zipCode,
    required this.street,
    required this.streetNumber,
    this.neighborhood,
    this.city,
    this.addressComplement,
  });

  factory ClinicLocation.fromJson(Map<String, dynamic> json) {
    return ClinicLocation(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      zipCode: json['zipCode'] as String,
      street: json['street'] as String,
      streetNumber: json['streetNumber'] as String,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      addressComplement: json['addressComplement'] as String?,
    );
  }
}
