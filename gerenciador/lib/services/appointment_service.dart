import '../config/app_config.dart';
import '../models/appointment.dart';
import '../models/pagination.dart';
import '../models/patient.dart';
import '../models/user.dart';
import 'api_client.dart';

class AppointmentService {
  AppointmentService._();

  static final AppointmentService instance = AppointmentService._();

  Future<PaginatedResponse<Appointment>> getAll({
    required int page,
    String doctorName = '',
    String patientName = '',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': AppConfig.pageSize,
      if (doctorName.trim().isNotEmpty) 'doctorName': doctorName.trim(),
      if (patientName.trim().isNotEmpty) 'patientName': patientName.trim(),
    };

    final raw = await ApiClient.instance.get('/appointments', query: query);
    return ApiClient.instance.toPaginated<Appointment>(
      raw,
      (json) => Appointment.fromJson(json),
    );
  }

  Future<List<AppUser>> getDoctors() async {
    final raw = await ApiClient.instance.get('/users', query: {'admin': '0'}) as List<dynamic>;
    return raw.map((item) => AppUser.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<Patient>> getPatients() async {
    final raw = await ApiClient.instance.get('/patients') as List<dynamic>;
    return raw.map((item) => Patient.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await ApiClient.instance.post('/appointments', payload);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await ApiClient.instance.patch('/appointments/$id', payload);
  }

  Future<void> delete(String id) async {
    await ApiClient.instance.delete('/appointments/$id');
  }
}
