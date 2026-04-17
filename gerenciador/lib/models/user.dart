class AppUser {
  final String id;
  final String name;
  final String email;
  final String? cpf;
  final String? crm;
  final bool admin;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.cpf,
    this.crm,
    required this.admin,
  });

  factory AppUser.fromApi(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      cpf: json['cpf'] as String?,
      crm: json['crm'] as String?,
      admin: (json['type'] as String?) == 'admin' || (json['admin'] == true),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': admin ? 'admin' : 'doctor',
    };
  }

  factory AppUser.fromStorageJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      cpf: null,
      crm: null,
      admin: (json['type'] as String?) == 'admin',
    );
  }
}
