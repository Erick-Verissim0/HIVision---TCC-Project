import '../config/app_config.dart';
import '../models/pagination.dart';
import '../models/patient.dart';
import '../models/user.dart';
import 'api_client.dart';

class PatientService {
  PatientService._();

  static final PatientService instance = PatientService._();

  Future<PaginatedResponse<Patient>> getAll({
    required int page,
    String name = '',
    String cpf = '',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': AppConfig.pageSize,
      if (name.trim().isNotEmpty) 'name': name.trim(),
      if (cpf.trim().isNotEmpty) 'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
    };

    final raw = await ApiClient.instance.get('/patients', query: query);
    return ApiClient.instance.toPaginated<Patient>(
      raw,
      (json) => Patient.fromJson(json),
    );
  }

  Future<List<AppUser>> getDoctors() async {
    final raw = await ApiClient.instance.get('/users') as List<dynamic>;
    return raw
        .map((item) => AppUser.fromApi(item as Map<String, dynamic>))
        .where((user) => !user.admin)
        .toList();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await ApiClient.instance.post('/patients', payload);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await ApiClient.instance.patch('/patients/$id', payload);
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/patients/$id');
  }
}
