import '../config/app_config.dart';
import '../models/pagination.dart';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  Future<PaginatedResponse<AppUser>> getAll({
    required int page,
    String name = '',
    String email = '',
    String admin = '-1',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': AppConfig.pageSize,
      if (name.trim().isNotEmpty) 'name': name.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (admin == '0' || admin == '1') 'admin': admin,
    };

    final raw = await ApiClient.instance.get('/users', query: query);
    return ApiClient.instance.toPaginated<AppUser>(
      raw,
      (json) => AppUser.fromApi(json),
    );
  }

  Future<AppUser> getById(String id) async {
    final raw = await ApiClient.instance.get('/users/$id') as Map<String, dynamic>;
    return AppUser.fromApi(raw);
  }

  Future<void> create({
    required String name,
    required String email,
    required String password,
    required String type,
    String? cpf,
    String? crm,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'password': password,
      if (type == 'doctor') 'cpf': cpf,
      if (type == 'doctor') 'crm': crm,
    };

    await ApiClient.instance.post(
      type == 'admin' ? '/users/admin' : '/users/doctor',
      payload,
    );
  }

  Future<void> updateProfile({
    required String id,
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? cpf,
  }) async {
    await ApiClient.instance.patch('/users/profile/$id', {
      'name': name,
      'email': email,
      if (currentPassword != null && currentPassword.isNotEmpty)
        'currentPassword': currentPassword,
      if (newPassword != null && newPassword.isNotEmpty)
        'newPassword': newPassword,
      if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
    });
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/users/$id');
  }
}
