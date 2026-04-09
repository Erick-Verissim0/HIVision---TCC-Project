import '../config/app_config.dart';
import '../models/clinic_location.dart';
import '../models/pagination.dart';
import '../models/user.dart';
import 'api_client.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<PaginatedResponse<ClinicLocation>> getAll({
    required int page,
    String city = '',
    String street = '',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': AppConfig.pageSize,
      if (city.trim().isNotEmpty) 'city': city.trim(),
      if (street.trim().isNotEmpty) 'street': street.trim(),
    };

    final raw = await ApiClient.instance.get('/clinic-locations', query: query);
    return ApiClient.instance.toPaginated<ClinicLocation>(
      raw,
      (json) => ClinicLocation.fromJson(json),
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
    await ApiClient.instance.post('/clinic-locations', payload);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await ApiClient.instance.patch('/clinic-locations/$id', payload);
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/clinic-locations/$id');
  }
}
