import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'error_state.dart';

const _kHasLoggedIn = 'has_logged_in';
const _kLoggedUserJson = 'logged_user_json';

void main() {
  runApp(const HivisionApp());
}

class AppColors {
  static const wine = Color(0xFF760000);
  static const lightBackground = Color(0xFFF3F3F3);
  static const sidePanel = Color(0xFFD9D0D0);
  static const paleRose = Color(0xFFDDCACA);
  static const textDark = Color(0xFF5C0000);
  static const divider = Color(0xFFE6D9FF);
}

class ApiPatient {
  ApiPatient({
    required this.id,
    required this.name,
    required this.cpf,
    this.lastAppointment,
    this.age,
    this.birthDate,
    this.profession,
    this.maritalStatus,
    this.sexualOrientation,
    this.partnerSerologicalStatus,
  });

  final String id;
  final String name;
  final String cpf;
    final int? age;
    final DateTime? birthDate;
    final String? profession;
    final String? maritalStatus;
    final String? sexualOrientation;
    final String? partnerSerologicalStatus;
  final DateTime? lastAppointment;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ApiPatient.fromJson(Map<String, dynamic> json) {
    String? firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
      return null;
    }

    return ApiPatient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Paciente',

      cpf: json['cpf']?.toString() ?? '',
      lastAppointment: _parseDate(json['lastAppointment']),
      age: int.tryParse(json['age']?.toString() ?? ''),
      birthDate: _parseDate(json['birthDate'] ?? json['birth_date']),
      profession: firstNonEmpty([json['profession'], json['occupation']]),
      maritalStatus: firstNonEmpty([json['maritalStatus'], json['marital_status']]),
      sexualOrientation: firstNonEmpty([json['sexualOrientation'], json['sexual_orientation'], json['orientation']]),
      partnerSerologicalStatus: firstNonEmpty([
        json['partnerSerologicalStatus'],
        json['partner_serological_status'],
        json['concordantPartner'],
      ]),
    );
  }
}

class ApiAppointment {
  ApiAppointment({
    required this.id,
    required this.patientId,
    required this.appointmentDate,
    this.rawData = const {},
  });

  final String id;
  final String patientId;
  final DateTime appointmentDate;
  final Map<String, dynamic> rawData;

  factory ApiAppointment.fromJson(Map<String, dynamic> json) {
    return ApiAppointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      appointmentDate: _parseDate(json['appointmentDate']) ?? DateTime.now(),
      rawData: Map<String, dynamic>.from(json),
    );
  }
}

class ApiClinicLocation {
  ApiClinicLocation({
    required this.id,
    required this.name,
    required this.street,
    required this.streetNumber,
    this.neighborhood,
    this.city,
  });

  final String id;
  final String name;
  final String street;
  final String streetNumber;
  final String? neighborhood;
  final String? city;

  String get fullAddress {
    final parts = [street, streetNumber, neighborhood, city].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  factory ApiClinicLocation.fromJson(Map<String, dynamic> json) {
    return ApiClinicLocation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Local',
      street: json['street']?.toString() ?? '',
      streetNumber: json['streetNumber']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString(),
      city: json['city']?.toString(),
    );
  }
}

class ApiUser {
  ApiUser({required this.id, required this.name, required this.email, this.crm, this.type, this.profilePhotoUrl});

  final String id;
  final String name;
  final String email;
  final String? crm;
  final String? type;
  final String? profilePhotoUrl;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'Profissional';
    return parts.first;
  }

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    String? firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
      return null;
    }

    return ApiUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Profissional',
      email: json['email']?.toString() ?? '',
      crm: json['crm']?.toString(),
      type: json['type']?.toString(),
      profilePhotoUrl: firstNonEmpty([
        json['profilePhotoUrl'],
        json['photoUrl'],
        json['avatarUrl'],
        json['photo'],
        json['imageUrl'],
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'crm': crm,
      'type': type,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }
}

class ApiClient {
  ApiClient();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  List<String> get _baseUrls {
    if (_definedBaseUrl.trim().isNotEmpty) return [_definedBaseUrl.trim()];

    if (Platform.isAndroid) {
      return const ['http://10.0.2.2:3001', 'http://localhost:3001'];
    }

    return const ['http://localhost:3001'];
  }

  Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    Object? lastError;

    for (var i = 0; i < _baseUrls.length; i++) {
      final baseUrl = _baseUrls[i];

      try {
        return await request(baseUrl);
      } catch (error) {
        lastError = error;
        debugPrint('[ApiClient] request failed for $baseUrl: $error');
        if (i == _baseUrls.length - 1) rethrow;
      }
    }

    throw Exception(lastError?.toString() ?? 'Erro de conexão com API');
  }

  Future<List<ApiPatient>> fetchPatients({String? name, String? doctorId}) async {
    final query = <String, String>{};
    if (name != null && name.trim().isNotEmpty) query['name'] = name.trim();
    if (doctorId != null && doctorId.trim().isNotEmpty) query['doctorId'] = doctorId.trim();
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/patients').replace(queryParameters: query.isEmpty ? null : query);
      return http.get(uri);
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar pacientes (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);
    return list.whereType<Map<String, dynamic>>().map(ApiPatient.fromJson).toList();
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
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/patients');
      return http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorId': doctorId,
          'name': name.trim(),
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
          if (lastAppointment != null) 'lastAppointment': lastAppointment.toIso8601String(),
          if (zipCode != null && zipCode.trim().isNotEmpty) 'zipCode': zipCode.trim().replaceAll(RegExp(r'\D'), ''),
          if (street != null && street.trim().isNotEmpty) 'street': street.trim(),
          if (streetNumber != null && streetNumber.trim().isNotEmpty) 'streetNumber': streetNumber.trim(),
          if (neighborhood != null && neighborhood.trim().isNotEmpty) 'neighborhood': neighborhood.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (addressComplement != null && addressComplement.trim().isNotEmpty) 'addressComplement': addressComplement.trim(),
          if (age != null) 'age': age,
          if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
          if (maritalStatus != null && maritalStatus.trim().isNotEmpty) 'maritalStatus': maritalStatus.trim(),
          if (profession != null && profession.trim().isNotEmpty) 'profession': profession.trim(),
          if (previousDiseases != null && previousDiseases.trim().isNotEmpty) 'previousDiseases': previousDiseases.trim(),
          if (allergies != null && allergies.trim().isNotEmpty) 'allergies': allergies.trim(),
          if (medications != null && medications.trim().isNotEmpty) 'medications': medications.trim(),
        }),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiPatient.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao cadastrar paciente');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao cadastrar paciente (${response.statusCode})');
  }

  Future<List<ApiAppointment>> fetchAppointments({String? patientName, String? doctorId}) async {
    final query = <String, String>{};
    if (patientName != null && patientName.trim().isNotEmpty) {
      query['patientName'] = patientName.trim();
    }
    if (doctorId != null && doctorId.trim().isNotEmpty) {
      query['doctorId'] = doctorId.trim();
    }
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/appointments').replace(queryParameters: query.isEmpty ? null : query);
      return http.get(uri);
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar atendimentos (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);
    return list.whereType<Map<String, dynamic>>().map(ApiAppointment.fromJson).toList();
  }

  Future<List<ApiClinicLocation>> fetchClinicLocations({String? doctorId}) async {
    final query = <String, String>{};
    if (doctorId != null && doctorId.trim().isNotEmpty) {
      query['doctorId'] = doctorId.trim();
    }
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/clinic-locations').replace(queryParameters: query.isEmpty ? null : query);
      return http.get(uri);
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao carregar locais (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final list = _extractList(decoded);
    return list.whereType<Map<String, dynamic>>().map(ApiClinicLocation.fromJson).toList();
  }

  Future<ApiUser> login({required String email, required String password}) async {
    debugPrint('[ApiClient] login start for: ${email.trim().toLowerCase()}');
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/users/login');
      debugPrint('[ApiClient] POST $uri');
      return http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('[ApiClient] login success (${response.statusCode})');
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final user = ApiUser.fromJson(decoded);
        if (user.id.trim().isEmpty) {
          throw Exception('Resposta invalida ao realizar login');
        }
        return user;
      }
      throw Exception('Resposta invalida ao realizar login');
    }

    final message = _extractErrorMessage(response.body);
    debugPrint('[ApiClient] login failed (${response.statusCode}): ${message ?? 'sem mensagem'}');
    if (message == 'Invalid credentials') {
      throw Exception('Invalid credentials');
    }

    throw Exception(message ?? 'Erro ao realizar login (${response.statusCode})');
  }

  Future<ApiUser> fetchUserById(String userId) async {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('ID do usuario invalido');
    }

    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/users/$normalizedId');
      return http.get(uri);
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response.body);
      throw Exception(message ?? 'Erro ao carregar usuario (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final user = ApiUser.fromJson(decoded);
      if (user.id.trim().isNotEmpty) {
        return user;
      }
    }
    throw Exception('Resposta invalida ao carregar usuario');
  }

  Future<void> requestForgotPasswordLink({required String email}) async {
    await _postForgotPasswordLink(path: '/users/forgot-password/request-link', email: email);
  }

  Future<void> resendForgotPasswordLink({required String email}) async {
    await _postForgotPasswordLink(path: '/users/forgot-password/resend-link', email: email);
  }

  Future<void> _postForgotPasswordLink({required String path, required String email}) async {
    debugPrint('[ApiClient] forgot-password link start for: ${email.trim().toLowerCase()}');
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl$path');
      debugPrint('[ApiClient] POST $uri');
      return http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('[ApiClient] forgot-password link success (${response.statusCode})');
      return;
    }

    final message = _extractErrorMessage(response.body);
    debugPrint('[ApiClient] forgot-password link failed (${response.statusCode}): ${message ?? 'sem mensagem'}');
    throw Exception(message ?? 'Erro ao solicitar recuperação (${response.statusCode})');
  }

  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/users/forgot-password');
      return http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'resetCode': resetCode.trim(),
          'newPassword': newPassword,
        }),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao redefinir senha (${response.statusCode})');
  }

  Future<ApiUser> register({
    required String name,
    required String cpf,
    required String crm,
    required String email,
    required String password,
  }) async {
    debugPrint('[ApiClient] register start for: ${email.trim().toLowerCase()}');
    final response = await _requestWithFallback((baseUrl) {
      final uri = Uri.parse('$baseUrl/users/doctor');
      debugPrint('[ApiClient] POST $uri');
      return http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'cpf': cpf.trim(),
          'crm': crm.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('[ApiClient] register success (${response.statusCode})');
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiUser.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao cadastrar usuário');
    }

    final message = _extractErrorMessage(response.body);
    debugPrint('[ApiClient] register failed (${response.statusCode}): ${message ?? 'sem mensagem'}');
    throw Exception(message ?? 'Erro ao realizar cadastro (${response.statusCode})');
  }

  String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
      return decoded['data'] as List<dynamic>;
    }
    return const [];
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

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

class HivisionApp extends StatelessWidget {
  const HivisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HIVision',
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
  bool _loading = false;

  Future<void> _handleEnter() async {
    if (_loading) return;

    setState(() => _loading = true);
    var navigated = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLoggedIn = prefs.getBool(_kHasLoggedIn) ?? false;
      final loggedUser = _readLoggedUserFromPrefs(prefs);

      if (!mounted) return;

      if (hasLoggedIn && loggedUser != null && loggedUser.id.trim().isNotEmpty) {
        navigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HivisionShell(currentUser: loggedUser)),
        );
        return;
      }

      if (hasLoggedIn) {
        await prefs.remove(_kHasLoggedIn);
        await prefs.remove(_kLoggedUserJson);
      }

      navigated = true;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (_) {
      if (!mounted) return;

      navigated = true;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } finally {
      if (mounted && !navigated) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/group_21.png',
                  width: 92,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'HIVision',
                  style: TextStyle(color: AppColors.textDark, fontSize: 34, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleEnter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (_loading)
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 18),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Este software foi desenvolvido em parceria com o Centro de Inovação Tecnológica do Cesmac e trata-se de um produto de dissertação do Programa de Pós-graduação Profissional em Biotecnologia em Saúde Humana e Animal da Universidade Estadual do Ceará em associação com o Centro Universitário Cesmac.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
  final TapGestureRecognizer _cadastreTapRecognizer = TapGestureRecognizer();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cadastreTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.trim().isEmpty) {
      setState(() {
        _errorMessage = 'É necessário preencher os campos para logar.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    late final ApiUser loggedUser;
    try {
      loggedUser = await _apiClient.login(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await _persistLoggedUser(prefs, loggedUser);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString();
      setState(() {
        _loading = false;
        if (message.contains('Invalid credentials')) {
          _errorMessage = 'Email ou senha inválidos.';
        } else if (message.contains('SocketException') ||
            message.contains('Connection refused') ||
            message.contains('Failed host lookup') ||
            message.contains('timed out')) {
          _errorMessage = 'O E-mail ou Senha estão incorretos.';
        } else {
          _errorMessage = 'O E-mail ou Senha estão incorretos.';
        }
      });
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HivisionShell(currentUser: loggedUser)),
    );
  }

  Future<void> _forgotPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/group_21.png',
                      width: 52,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'HIVision',
                      style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.wine,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const Text(
                      'Bem-vindo(a)!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Email:',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: 'exemplo@dominio.com', controller: _emailController),
                    const SizedBox(height: 20),
                    const Text(
                      'Senha:',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: 'Senha', obscure: true, controller: _passwordController),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _forgotPassword,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Esqueci minha senha', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9E1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD9D9), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFEAEA), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFFFEAEA),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.paleRose,
                          foregroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(42),
                            side: const BorderSide(color: Colors.white, width: 2.5),
                          ),
                          minimumSize: const Size.fromHeight(52),
                          elevation: 0,
                        ),
                        onPressed: _loading ? null : _login,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            if (_loading)
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 18),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 150),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                          children: [
                            const TextSpan(text: 'Não tem conta? '),
                            TextSpan(
                              text: 'Cadastre-se',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Color(0xFFFFD600),
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: _cadastreTapRecognizer
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
  String? _errorMessage;

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
      setState(() => _errorMessage = 'Informe um e-mail válido.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _apiClient.requestForgotPasswordLink(email: email);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _loading = false;
        _errorMessage = message.contains('User not found')
            ? 'Não encontramos conta para este e-mail.'
            : 'Não foi possível solicitar recuperação de senha.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ForgotPasswordConfirmationScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wine,
      body: SafeArea(bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.wine,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/group_20.png', width: 52, fit: BoxFit.contain),
                    const SizedBox(width: 10),
                    const Text(
                      'HIVision',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.lightBackground,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Esqueceu a senha?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textDark, fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Digite o e-mail cadastrado e enviaremos um código para você criar uma nova senha.',
                      style: TextStyle(color: Color(0xFF222222), fontSize: 20, height: 1.2),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Email',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        hintText: 'Digite seu email',
                        hintStyle: const TextStyle(color: Color(0xFF777777), fontSize: 22),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFAAAAAA)),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF9E1A1A), fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.wine,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(42)),
                            elevation: 0,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Text('Enviar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                              if (_loading)
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 18),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordConfirmationScreen extends StatefulWidget {
  const ForgotPasswordConfirmationScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotPasswordConfirmationScreen> createState() => _ForgotPasswordConfirmationScreenState();
}

class _ForgotPasswordConfirmationScreenState extends State<ForgotPasswordConfirmationScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _resending = false;

  Future<void> _resend() async {
    if (_resending) return;

    setState(() => _resending = true);
    try {
      await _apiClient.resendForgotPasswordLink(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail reenviado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível reenviar o e-mail.'),
          backgroundColor: Color(0xFF9E1A1A),
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wine,
      body: SafeArea(bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.wine,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/group_20.png', width: 52, fit: BoxFit.contain),
                    const SizedBox(width: 10),
                    const Text(
                      'HIVision',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.lightBackground,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Transform.translate(
                          offset: const Offset(0, -34),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Confirmar e-mail',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Icon(Icons.mark_email_read_outlined, color: AppColors.textDark, size: 80),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'Enviamos um código de recuperação para:',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Color(0xFF222222)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Verifique sua caixa de entrada e use o código para definir sua nova senha.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Color(0xFF222222), height: 1.2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NewPasswordScreen(email: widget.email),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.wine,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            elevation: 0,
                          ),
                          child: const Text('Recebi o e-mail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _resending ? null : _resend,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.paleRose,
                            foregroundColor: AppColors.textDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            elevation: 0,
                          ),
                          child: _resending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.textDark),
                                )
                              : const Text('Reenviar E-mail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final resetCode = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (resetCode.isEmpty) {
      setState(() => _errorMessage = 'Informe o código recebido no e-mail.');
      return;
    }

    if (resetCode.replaceAll(RegExp(r'\D'), '').length != 6) {
      setState(() => _errorMessage = 'O código deve conter 6 dígitos.');
      return;
    }

    if (newPassword.trim().isEmpty || confirmPassword.trim().isEmpty) {
      setState(() => _errorMessage = 'Preencha os dois campos de senha.');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'A nova senha deve ter no mínimo 6 caracteres.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _apiClient.resetPassword(
        email: widget.email,
        resetCode: resetCode,
        newPassword: newPassword,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível redefinir a senha.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wine,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.wine,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/group_20.png', width: 52, fit: BoxFit.contain),
                    const SizedBox(width: 10),
                    const Text(
                      'HIVision',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.lightBackground,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Criar nova senha',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textDark, fontSize: 34, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Crie uma senha forte para manter sua conta protegida. Depois é só salvar e voltar ao aplicativo.',
                        style: TextStyle(color: Color(0xFF222222), fontSize: 18, height: 1.25),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Código de recuperação',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _RoundedInput(
                        hint: '000000',
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nova senha',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _RoundedInput(
                        hint: 'Nova senha',
                        obscure: true,
                        controller: _newPasswordController,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Confirmar senha',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _RoundedInput(
                        hint: 'Confirmar senha',
                        obscure: true,
                        controller: _confirmPasswordController,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/check.png',
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.check_circle, size: 18, color: Color(0xFF45B36B)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mínimo de 6 caracteres',
                            style: TextStyle(color: Color(0xFF444444), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF9E1A1A), fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: _loading
                                    ? null
                                    : () {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.wine,
                                  side: const BorderSide(color: AppColors.wine, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(42)),
                                ),
                                child: const Text('Cancelar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.wine,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(42)),
                                  elevation: 0,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Text('Salvar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                    if (_loading)
                                      const Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 14),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Header é branco, então ícones da status bar em preto
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _crmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_loading) return;

    final name = _nameController.text.trim();
    final cpf = _cpfController.text.trim();
    final crm = _crmController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || cpf.isEmpty || crm.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'É necessário preencher todos os campos.';
      });
      return;
    }

    final cpfDigits = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfDigits.length != 11) {
      setState(() {
        _errorMessage = 'CPF inválido. Informe 11 dígitos.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'As senhas não coincidem.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    late final ApiUser createdUser;

    try {
      createdUser = await _apiClient.register(
        name: name,
        cpf: cpfDigits,
        crm: crm,
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await _persistLoggedUser(prefs, createdUser);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      final normalizedMessage = message.toLowerCase();
      setState(() {
        _loading = false;
        if (message.contains('SocketException') ||
            message.contains('Connection refused') ||
            message.contains('Failed host lookup') ||
            message.contains('timed out')) {
          _errorMessage = 'Não foi possível conectar ao backend.';
        } else if (normalizedMessage.contains('email já existe') ||
            normalizedMessage.contains('email already in use')) {
          _errorMessage = 'Este e-mail já está cadastrado.';
        } else if (normalizedMessage.contains('cpf já existe') ||
            normalizedMessage.contains('cpf already in use')) {
          _errorMessage = 'Este CPF já está cadastrado.';
        } else {
          _errorMessage = 'Não foi possível realizar o cadastro.';
        }
      });
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HivisionShell(currentUser: createdUser)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/group_21.png',
                      width: 52,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'HIVision',
                      style: TextStyle(color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.wine,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const Text(
                      'Cadastrar-se',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Nome Completo:',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: '', controller: _nameController),
                    const SizedBox(height: 20),
                    const Text(
                      'CPF:',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(
                      hint: '000.000.000-00',
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_CpfInputFormatter()],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'CRM:',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: '', controller: _crmController),
                    const SizedBox(height: 20),
                    const Text(
                      'Email:',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: 'exemplo@dominio.com', controller: _emailController),
                    const SizedBox(height: 20),
                    const Text(
                      'Senha:',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: 'Senha', obscure: true, controller: _passwordController),
                    const SizedBox(height: 20),
                    const Text(
                      'Confirmar senha:',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _RoundedInput(hint: 'Senha', obscure: true, controller: _confirmPasswordController),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9E1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD9D9), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFEAEA), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFFFEAEA),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.paleRose,
                          foregroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(42),
                            side: const BorderSide(color: Colors.white, width: 3),
                          ),
                          minimumSize: const Size.fromHeight(60),
                          elevation: 0,
                        ),
                        onPressed: _loading ? null : _register,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text('Criar Conta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            if (_loading)
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 18),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MobileSection {
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

class HivisionShell extends StatefulWidget {
  const HivisionShell({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  State<HivisionShell> createState() => _HivisionShellState();
}

class _HivisionShellState extends State<HivisionShell> {
  ApiUser? _effectiveCurrentUser;
  _MobileSection _section = _MobileSection.home;
  _MobileSection _lastSection = _MobileSection.home;
  List<_MobileSection> _navigationHistory = [_MobileSection.home];
  _PatientsPane _patientsPane = _PatientsPane.registered;
  _ConsultationPane _consultationPane = _ConsultationPane.registered;
  _LocationsPane _locationsPane = _LocationsPane.registered;
  ApiPatient? _selectedApiPatient;
  ApiPatient? _selectedConsultationPatient;
  bool _isMiddlePanelOpen = false;
  String _mobileSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _effectiveCurrentUser = widget.currentUser;
    _hydrateCurrentUserFromPrefs();
  }

  Future<void> _hydrateCurrentUserFromPrefs() async {
    final currentId = _effectiveCurrentUser?.id.trim() ?? '';
    if (currentId.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final loggedUser = _readLoggedUserFromPrefs(prefs);
    if (!mounted || loggedUser == null) return;

    setState(() {
      _effectiveCurrentUser = loggedUser;
    });
  }

  void _navigateToSection(_MobileSection section) {
    setState(() {
      if (_section != section) {
        _lastSection = _section;
        _navigationHistory.add(section);
      }
      _section = section;
      _mobileSearchTerm = '';
      _isMiddlePanelOpen = section != _MobileSection.home &&
          section != _MobileSection.profile &&
          section != _MobileSection.reports;
      if (section != _MobileSection.patients) {
        _selectedApiPatient = null;
      }
      if (section == _MobileSection.patients) {
        _patientsPane = _PatientsPane.registered;
      }
      if (section == _MobileSection.consultation) {
        _consultationPane = _ConsultationPane.registered;
        _selectedConsultationPatient = null;
      }
      if (section == _MobileSection.locations) {
        _locationsPane = _LocationsPane.registered;
      }
    });
  }

  void _goBackSection() {
    setState(() {
      if (_navigationHistory.length > 1) {
        _navigationHistory.removeLast();
        final previous = _navigationHistory.last;
        _lastSection = _section;
        _section = previous;
        _mobileSearchTerm = '';
        _isMiddlePanelOpen = previous != _MobileSection.home &&
            previous != _MobileSection.profile &&
            previous != _MobileSection.reports;
        if (previous != _MobileSection.patients) {
          _selectedApiPatient = null;
        }
        if (previous == _MobileSection.patients) {
          _patientsPane = _PatientsPane.registered;
        }
        if (previous == _MobileSection.consultation) {
          _consultationPane = _ConsultationPane.registered;
        }
        if (previous == _MobileSection.locations) {
          _locationsPane = _LocationsPane.registered;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Renderiza conteúdo baseado na seção
    final mainContent = _buildMainContent();

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.wine,
          elevation: 0,
          toolbarHeight: 50,
          title: const Text(
            'HIVision',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: mainContent,
        drawer: _buildMobileDrawer(),
      );
    }

    // Para telas maiores, usa layout similar ao Web
    return Scaffold(
      body: Row(
        children: [
          _MobileSidebar(
            section: _section,
            onSelect: (section) {
              _navigateToSection(section);
            },
          ),
          if (_isMiddlePanelOpen &&
              _section != _MobileSection.home &&
              _section != _MobileSection.profile &&
              _section != _MobileSection.reports)
            _MobileMiddlePanel(
              section: _section,
              currentUser: _effectiveCurrentUser,
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
            child: mainContent,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_section) {
      case _MobileSection.home:
        return HomeScreen(
          onNewConsultation: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewConsultationScreen(currentUser: _effectiveCurrentUser),
              ),
            );
          },
          onNewPatient: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewPatientScreen(currentUser: _effectiveCurrentUser),
              ),
            );
          },
          onLocations: () {
            _navigateToSection(_MobileSection.locations);
          },
          currentUser: _effectiveCurrentUser,
        );
      case _MobileSection.patients:
        return PatientsScreen(
          onOpenDetail: _openPatientDetail,
          currentUser: _effectiveCurrentUser,
          onBack: _goBackSection,
        );
      case _MobileSection.consultation:
        return ConsultationsScreen(
          currentUser: _effectiveCurrentUser,
          onBack: _goBackSection,
        );
      case _MobileSection.reports:
        return DocumentsScreen(
          onBack: _goBackSection,
          currentUser: _effectiveCurrentUser,
        );
      case _MobileSection.locations:
        return ClinicLocationsScreen(
          currentUser: _effectiveCurrentUser,
          onBack: _goBackSection,
        );
      case _MobileSection.profile:
        return SettingsScreen(onBack: _goBackSection);
    }
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        color: AppColors.wine,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/group_20_menu.png',
                      width: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HIVision',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30),
              Expanded(
                child: ListView(
                  children: [
                    _MobileDrawerItem(
                      icon: Icons.home_outlined,
                      label: 'Início',
                      active: _section == _MobileSection.home,
                      onTap: () {
                        _navigateToSection(_MobileSection.home);
                        Navigator.pop(context);
                      },
                    ),
                    _MobileDrawerItem(
                      icon: Icons.groups_outlined,
                      label: 'Pacientes',
                      active: _section == _MobileSection.patients,
                      onTap: () {
                        _navigateToSection(_MobileSection.patients);
                        Navigator.pop(context);
                      },
                    ),
                    _MobileDrawerItem(
                      icon: Icons.medical_services_outlined,
                      label: 'Consultas',
                      active: _section == _MobileSection.consultation,
                      onTap: () {
                        _navigateToSection(_MobileSection.consultation);
                        Navigator.pop(context);
                      },
                    ),
                    _MobileDrawerItem(
                      icon: Icons.location_on_outlined,
                      label: 'Locais',
                      active: _section == _MobileSection.locations,
                      onTap: () {
                        _navigateToSection(_MobileSection.locations);
                        Navigator.pop(context);
                      },
                    ),
                    _MobileDrawerItem(
                      icon: Icons.content_copy_outlined,
                      label: 'Relatórios',
                      active: _section == _MobileSection.reports,
                      onTap: () {
                        _navigateToSection(_MobileSection.reports);
                        Navigator.pop(context);
                      },
                    ),
                    _MobileDrawerItem(
                      icon: Icons.badge_outlined,
                      label: 'Meu Perfil',
                      active: _section == _MobileSection.profile,
                      onTap: () {
                        _navigateToSection(_MobileSection.profile);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30),
              _MobileDrawerItem(
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
  }

  void _openPatientDetail(ApiPatient patient) {
    setState(() => _selectedApiPatient = patient);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: patient, currentUser: _effectiveCurrentUser)));
  }
}

class _MobileSidebar extends StatelessWidget {
  const _MobileSidebar({required this.section, required this.onSelect});

  final _MobileSection section;
  final ValueChanged<_MobileSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: AppColors.wine,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Image.asset(
                        'assets/images/group_20_menu.png',
                        width: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MobileSidebarItem(
                      icon: Icons.home_outlined,
                      label: 'Início',
                      active: section == _MobileSection.home,
                      onTap: () => onSelect(_MobileSection.home),
                    ),
                    _MobileSidebarItem(
                      icon: Icons.groups_outlined,
                      label: 'Pacientes',
                      active: section == _MobileSection.patients,
                      onTap: () => onSelect(_MobileSection.patients),
                    ),
                    _MobileSidebarItem(
                      icon: Icons.medical_services_outlined,
                      label: 'Consultas',
                      active: section == _MobileSection.consultation,
                      onTap: () => onSelect(_MobileSection.consultation),
                    ),
                    _MobileSidebarItem(
                      icon: Icons.location_on_outlined,
                      label: 'Locais',
                      active: section == _MobileSection.locations,
                      onTap: () => onSelect(_MobileSection.locations),
                    ),
                    _MobileSidebarItem(
                      icon: Icons.content_copy_outlined,
                      label: 'Relatórios',
                      active: section == _MobileSection.reports,
                      onTap: () => onSelect(_MobileSection.reports),
                    ),
                    _MobileSidebarItem(
                      icon: Icons.badge_outlined,
                      label: 'Perfil',
                      active: section == _MobileSection.profile,
                      onTap: () => onSelect(_MobileSection.profile),
                    ),
                    const Spacer(),
                    _MobileSidebarItem(
                      icon: Icons.logout,
                      label: 'Sair',
                      active: false,
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(_kHasLoggedIn);
                        await prefs.remove(_kLoggedUserJson);
                        final context = GlobalKey<State>().currentContext;
                        if (context != null && context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (_) => false,
                          );
                        }
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

class _MobileSidebarItem extends StatelessWidget {
  const _MobileSidebarItem({
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
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 104,
          height: 64,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDDD2D2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 15),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: 9,
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

class _MobileDrawerItem extends StatelessWidget {
  const _MobileDrawerItem({
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
    return ListTile(
      leading: Icon(icon, color: fg),
      title: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 14,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      tileColor: active ? const Color(0xFFDDD2D2) : Colors.transparent,
      onTap: onTap,
    );
  }
}

class _MobileMiddlePanel extends StatelessWidget {
  const _MobileMiddlePanel({
    required this.section,
    required this.currentUser,
    required this.patientsPane,
    required this.consultationPane,
    required this.locationsPane,
    required this.onPatientsPaneChanged,
    required this.onConsultationPaneChanged,
    required this.onLocationsPaneChanged,
    required this.onClose,
  });

  final _MobileSection section;
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
    return Container(
      width: 160,
      color: AppColors.sidePanel,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (section == _MobileSection.patients) ...[
            _MobileMiddlePanelItem(
              label: 'Novo Paciente',
              active: patientsPane == _PatientsPane.newPatient,
              onTap: () => onPatientsPaneChanged(_PatientsPane.newPatient),
            ),
            _MobileMiddlePanelItem(
              label: 'Cadastrados',
              active: patientsPane == _PatientsPane.registered,
              onTap: () => onPatientsPaneChanged(_PatientsPane.registered),
            ),
          ] else if (section == _MobileSection.consultation) ...[
            _MobileMiddlePanelItem(
              label: 'Nova Consulta',
              active: consultationPane == _ConsultationPane.newConsultation,
              onTap: () => onConsultationPaneChanged(_ConsultationPane.newConsultation),
            ),
            _MobileMiddlePanelItem(
              label: 'Consultas',
              active: consultationPane == _ConsultationPane.registered,
              onTap: () => onConsultationPaneChanged(_ConsultationPane.registered),
            ),
          ] else if (section == _MobileSection.locations) ...[
            _MobileMiddlePanelItem(
              label: 'Novo Local',
              active: locationsPane == _LocationsPane.newLocation,
              onTap: () => onLocationsPaneChanged(_LocationsPane.newLocation),
            ),
            _MobileMiddlePanelItem(
              label: 'Cadastrados',
              active: locationsPane == _LocationsPane.registered,
              onTap: () => onLocationsPaneChanged(_LocationsPane.registered),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileMiddlePanelItem extends StatelessWidget {
  const _MobileMiddlePanelItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.wine : AppColors.textDark,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          fontSize: 11,
        ),
      ),
      tileColor: active ? AppColors.paleRose : Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      onTap: onTap,
    );
  }
}

class DashboardData {
  DashboardData({required this.appointments, required this.patientsById});

  final List<ApiAppointment> appointments;
  final Map<String, ApiPatient> patientsById;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNewConsultation,
    required this.onNewPatient,
    required this.onLocations,
    this.currentUser,
  });

  final VoidCallback onNewConsultation;
  final VoidCallback onNewPatient;
  final VoidCallback onLocations;
  final ApiUser? currentUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<DashboardData> _loadDashboard({String? patientName}) async {
    final doctorId = widget.currentUser?.id;
    if (doctorId == null || doctorId.trim().isEmpty) {
      return DashboardData(appointments: const [], patientsById: const {});
    }
    final patients = await _api.fetchPatients(doctorId: doctorId);
    final appointments = await _api.fetchAppointments(
      doctorId: doctorId,
      patientName: patientName,
    );
    final patientsById = {for (final p in patients) p.id: p};
    return DashboardData(appointments: appointments, patientsById: patientsById);
  }

  void _refreshRecentSearch() {
    setState(() {
      final searchTerm = _searchController.text.trim();
      _future = _loadDashboard(patientName: searchTerm.isEmpty ? null : searchTerm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(currentUser: widget.currentUser),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionChip(icon: Icons.medical_services_outlined, label: 'Nova\nconsulta', onTap: widget.onNewConsultation),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionChip(icon: Icons.person_add_alt_1, label: 'Novo\npaciente', onTap: widget.onNewPatient),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionChip(icon: Icons.map_outlined, label: 'Locais', onTap: widget.onLocations),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SearchRow(
                  controller: _searchController,
                  onSearchTap: _refreshRecentSearch,
                  onChanged: (_) => _refreshRecentSearch(),
                  onSubmitted: (_) => _refreshRecentSearch(),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EDED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDFCACA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.textDark, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Atendimentos recentes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FutureBuilder<DashboardData>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: CircularProgressIndicator(color: AppColors.wine),
                      );
                    }
                    if (snapshot.hasError) {
                      return ErrorState(
                        message: 'Falha ao carregar atendimentos do backend.',
                        onRetry: () => setState(() => _future = _loadDashboard()),
                      );
                    }

                    final data = snapshot.data!;
                    final sorted = [...data.appointments]
                      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
                    if (sorted.isEmpty) {
                        return EmptyState(message: 'Nenhum atendimento encontrado no backend.');
                    }

                    return Column(
                      children: sorted.take(8).map((appointment) {
                        final patient = data.patientsById[appointment.patientId];
                        final patientName = patient?.name ?? 'Paciente';
                        return _RecentItem(
                          name: patientName,
                          date: appointment.appointmentDate,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RecentAppointmentDetailScreen(
                                  appointment: appointment,
                                  patient: patient,
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
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

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key, required this.onOpenDetail, this.currentUser, required this.onBack});

  final ValueChanged<ApiPatient> onOpenDetail;
  final ApiUser? currentUser;
  final VoidCallback onBack;

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final ApiClient _api = ApiClient();
  late Future<List<ApiPatient>> _future;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ApiPatient>> _loadPatients() {
    final doctorId = widget.currentUser?.id;
    if (doctorId == null || doctorId.trim().isEmpty) return Future.value(const []);
    return _api.fetchPatients(name: _searchController.text, doctorId: widget.currentUser?.id);
  }

  void _refreshSearch() {
    setState(() {
      _future = _loadPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeaderBar(title: 'Pacientes', onBack: widget.onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _SearchRow(
                        controller: _searchController,
                        onSearchTap: _refreshSearch,
                        onChanged: (_) => _refreshSearch(),
                        onSubmitted: (_) => _refreshSearch(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NewPatientScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wine,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text(
                          'Novo paciente',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
                        return const Center(child: CircularProgressIndicator(color: AppColors.wine));
                      }
                      if (snapshot.hasError) {
                        return ErrorState(
                          message: 'Falha ao carregar pacientes do backend.',
                          onRetry: _refreshSearch,
                        );
                      }

                      final patients = snapshot.data!;
                      if (patients.isEmpty) {
                        return EmptyState(message: 'Nenhum paciente encontrado no backend.');
                      }

                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (_, index) {
                          final patient = patients[index];
                          return InkWell(
                            onTap: () => widget.onOpenDetail(patient),
                            child: _PatientListItem(
                              initials: patient.initials,
                              name: patient.name,
                              document: _formatCpf(patient.cpf),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsultationsData {
  _ConsultationsData({
    required this.appointments,
    required this.patientNames,
    required this.clinicLocationsById,
    required this.patientsById,
  });

  final List<ApiAppointment> appointments;
  final Map<String, String> patientNames;
  final Map<String, ApiClinicLocation> clinicLocationsById;
  final Map<String, ApiPatient> patientsById;
}

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key, this.currentUser, required this.onBack});

  final ApiUser? currentUser;
  final VoidCallback onBack;

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  final ApiClient _api = ApiClient();
  late Future<_ConsultationsData> _future;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _loadAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_ConsultationsData> _loadAppointments() async {
    final doctorId = widget.currentUser?.id;
    if (doctorId == null || doctorId.trim().isEmpty) {
      return _ConsultationsData(appointments: const [], patientNames: {}, clinicLocationsById: {}, patientsById: {});
    }

    // Carregar pacientes, consultas e locais em paralelo
    final patientsFuture = _api.fetchPatients();
    final appointmentsFuture = _api.fetchAppointments(doctorId: doctorId);
    final locationsFuture = _api.fetchClinicLocations(doctorId: doctorId);

    final results = await Future.wait([
      patientsFuture,
      appointmentsFuture,
      locationsFuture,
    ]);

    final patients = results[0] as List<ApiPatient>;
    var appointments = results[1] as List<ApiAppointment>;
    final locations = results[2] as List<ApiClinicLocation>;

    // Filtrar por nome de paciente se houver busca
    if (_searchController.text.trim().isNotEmpty) {
      final searchTerm = _searchController.text.trim().toLowerCase();
      appointments = appointments.where((apt) {
        final patient = patients.firstWhere(
          (p) => p.id == apt.patientId,
          orElse: () => ApiPatient(id: '', name: '', cpf: ''),
        );
        return patient.name.toLowerCase().contains(searchTerm);
      }).toList();
    }

    // Ordenar por data descendente (mais recentes primeiro)
    appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    // Criar mapas para acesso rápido
    final patientNames = {for (final p in patients) p.id: p.name};
    final clinicLocationsById = {for (final l in locations) l.id: l};
    final patientsById = {for (final p in patients) p.id: p};

    return _ConsultationsData(
      appointments: appointments,
      patientNames: patientNames,
      clinicLocationsById: clinicLocationsById,
      patientsById: patientsById,
    );
  }

  void _refreshSearch() {
    setState(() {
      _future = _loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeaderBar(title: 'Consultas', onBack: widget.onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _SearchRow(
                        controller: _searchController,
                        onSearchTap: _refreshSearch,
                        onChanged: (_) => _refreshSearch(),
                        onSubmitted: (_) => _refreshSearch(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NewConsultationScreen(),
                            ),
                          ).then((_) {
                            _refreshSearch();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wine,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Nova consulta',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<_ConsultationsData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.wine));
                      }
                      if (snapshot.hasError) {
                        return ErrorState(
                          message: 'Falha ao carregar consultas do backend.',
                          onRetry: _refreshSearch,
                        );
                      }

                      final data = snapshot.data!;
                      if (data.appointments.isEmpty) {
                        return EmptyState(message: 'Nenhuma consulta encontrada no backend.');
                      }

                      return ListView.builder(
                        itemCount: data.appointments.length,
                        itemBuilder: (_, index) {
                          final appointment = data.appointments[index];
                          final patientName = data.patientNames[appointment.patientId] ?? 'Paciente desconhecido';
                          final locationId = appointment.rawData['clinicLocationId']?.toString();
                          final locationName = locationId != null
                              ? (data.clinicLocationsById[locationId]?.name ?? 'Local não informado')
                              : 'Local não informado';
                          final dateStr = _formatDateTime(appointment.appointmentDate);
                          final patient = data.patientsById[appointment.patientId];

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecentAppointmentDetailScreen(
                                    appointment: appointment,
                                    patient: patient,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                              child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.transparent,
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: AppColors.wine))),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Center(
                                        child: Text(
                                          _getInitials(patientName),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
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
                                      Text(patientName, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, color: Color(0xFF8C78F9), size: 14),
                                          const SizedBox(width: 4),
                                          Text(dateStr, style: const TextStyle(fontSize: 14, color: Color(0xFF8D8D8D))),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Color(0xFF8C78F9), size: 14),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(locationName, style: const TextStyle(fontSize: 14, color: Color(0xFF8D8D8D)), overflow: TextOverflow.ellipsis),
                                          ),
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
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.patient, this.currentUser});

  final ApiPatient patient;
  final ApiUser? currentUser;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class RecentAppointmentDetailScreen extends StatelessWidget {
  const RecentAppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.patient,
    this.currentUser,
  });

  final ApiAppointment appointment;
  final ApiPatient? patient;
  final ApiUser? currentUser;

  Map<String, String> get _fieldLabels => {
    'age': 'Idade',
    'occupation': 'Ocupação',
    'maritalStatus': 'Status relacional',
    'sexualOrientation': 'Orientação sexual',
    'concordantPartner': 'Status sorológico do parceiro',
    'hivDiagnosisDate': 'Data do diagnóstico do HIV',
    'cd4Nadir': 'CD4+ Atual',
    'currentArt': 'TARV atual',
    'lastViralLoad': 'Carga viral inicial',
    'virologicalStatus': 'Status virológico',
    'adherence': 'Adeão ao tratamento',
    'currentRegimen': 'Esquema atual',
    'cardiovascularRisk': 'Risco cardiovascular',
    'neoplasmScreening': 'Rastreamento de neoplasias',
    'coinfectionScreening': 'Rastreamento de coinfecções',
    'immunizations': 'Imunizações',
    'boneHealth': 'Saúde óssea',
    'previousDiseases': 'Doenças prévias relevantes',
    'allergy': 'Alergias',
    'surgeries': 'Cirurgias',
    'comorbidities': 'Comorbidades',
    'medicationUse': 'Uso de medicamentos',
    'notes': 'Observações clínicas',
  };

  List<String> get _novaConsultaFields => ['age', 'occupation', 'maritalStatus', 'sexualOrientation', 'concordantPartner'];

  Map<String, List<String>> get _fieldCategories => {
    'Status Clínico e Terapêutico do HIV': ['hivDiagnosisDate', 'cd4Nadir', 'currentArt', 'lastViralLoad', 'virologicalStatus', 'adherence', 'currentRegimen'],
    'Rastreamento e prevenção': ['cardiovascularRisk', 'neoplasmScreening', 'coinfectionScreening', 'immunizations', 'boneHealth'],
    'Histórico clínico': ['previousDiseases', 'allergy', 'surgeries', 'comorbidities', 'medicationUse'],
    'Observações': ['notes'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 28),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Atendimento recente',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailInfoCard(label: 'Paciente', value: patient?.name ?? 'Paciente não identificado'),
              _DetailInfoCard(label: 'Data', value: _formatDateTime(appointment.appointmentDate)),
              if (appointment.rawData['clinicLocationName'] != null)
                _DetailInfoCard(label: 'Local de consulta', value: appointment.rawData['clinicLocationName'].toString()),
              const SizedBox(height: 20),
              ..._buildNovaConsultaFields(),
              const SizedBox(height: 20),
              ..._buildCategories(),
            ],
          ),
        ),
      ),
    );
  }

List<Widget> _buildNovaConsultaFields() {
    final widgets = <Widget>[];
    for (final fieldName in _novaConsultaFields) {
      final value = appointment.rawData[fieldName];
      if (value == null || (value is String && value.trim().isEmpty)) continue;
      final label = _fieldLabels[fieldName] ?? fieldName;
      widgets.add(_DetailInfoCard(label: label, value: _stringifyValue(value)));
    }
    return widgets;
  }

  List<Widget> _buildCategories() {
    final widgets = <Widget>[];
    for (final categoryEntry in _fieldCategories.entries) {
      final categoryName = categoryEntry.key;
      final fieldNames = categoryEntry.value;
      final hasData = fieldNames.any((fn) => _hasFieldValue(fn));
      if (!hasData) continue;

      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFB3261E),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            categoryName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));

      for (final fieldName in fieldNames) {
        final value = appointment.rawData[fieldName];
        if (value == null || (value is String && value.trim().isEmpty)) continue;
        final label = _fieldLabels[fieldName] ?? fieldName;
        widgets.add(_DetailInfoCard(label: label, value: _stringifyValue(value)));
      }
      widgets.add(const SizedBox(height: 16));
    }
    if (widgets.isEmpty) {
      widgets.add(EmptyState(message: 'Nenhum dado disponível para este atendimento.'));
    }
    return widgets;
  }

  bool _hasFieldValue(String fieldName) {
    final value = appointment.rawData[fieldName];
    if (value == null) return false;
    if (value is String && value.trim().isEmpty) return false;
    if (value is List && value.isEmpty) return false;
    if (value is Map && value.isEmpty) return false;
    return true;
  }

  static String _stringifyValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (value is List) return value.isEmpty ? '-' : value.map((e) => e.toString()).join(', ');
    if (value is Map) return value.isEmpty ? '-' : jsonEncode(value);
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({required this.label, required this.value});

  final String label;
  final String value;

  Widget _formatLabel(String text) {
    if (text.contains('CD4')) {
      return RichText(
        text: TextSpan(
          children: [
            const TextSpan(text: 'CD'),
            TextSpan(
              text: '4',
              style: const TextStyle(fontSize: 14),
            ),
            TextSpan(
              text: '+',
              style: const TextStyle(fontSize: 10, fontFeatures: [FontFeature.superscripts()]),
            ),
            if (text != 'CD4')
              TextSpan(
                text: text.replaceFirst('CD4', ''),
                style: const TextStyle(fontSize: 14),
              ),
          ],
          style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
    }
    return Text(
      text,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formatLabel(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF333333), fontSize: 15, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final ApiClient _api = ApiClient();
  late Future<List<ApiAppointment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAppointments();
  }

  Future<List<ApiAppointment>> _loadAppointments() async {
    final doctorId = widget.currentUser?.id;
    if (doctorId == null || doctorId.trim().isEmpty) return const [];
    final appointments = await _api.fetchAppointments(doctorId: doctorId);
    return appointments.where((a) => a.patientId == widget.patient.id).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  String _historySubtitle(ApiAppointment appointment) {
    final notes = appointment.rawData['notes']?.toString().trim() ?? '';
    if (notes.isNotEmpty) return notes;
    final reason = appointment.rawData['reason']?.toString().trim() ?? '';
    if (reason.isNotEmpty) return reason;
    return 'Toque para ver os detalhes desta consulta';
  }

  String _consultationOrderLabel(int index) {
    const ordinals = [
      'Primeira consulta',
      'Segunda consulta',
      'Terceira consulta',
      'Quarta consulta',
      'Quinta consulta',
      'Sexta consulta',
      'Sétima consulta',
      'Oitava consulta',
      'Nona consulta',
      'Décima consulta',
    ];
    if (index < ordinals.length) return ordinals[index];
    return '${index + 1}ª consulta';
  }

  void _openDocumentEditor(String documentType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDocumentEditorScreen(
          documentType: documentType,
          patient: widget.patient,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _openNewConsultation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewConsultationScreen(
          currentUser: widget.currentUser,
          initialPatient: widget.patient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.wine,
            padding: const EdgeInsets.fromLTRB(20, 42, 20, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const Expanded(
                  child: Text(
                    'Paciente - Detalhe',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.wine,
                        child: Text(widget.patient.initials,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.patient.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PatientDetailActionButton(
                    text: 'Nova consulta',
                    icon: Icons.medical_services_outlined,
                    onPressed: _openNewConsultation,
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Histórico',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3A))),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<ApiAppointment>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: AppColors.wine),
                        );
                      }
                      if (snapshot.hasError) {
                        return ErrorState(
                          message: 'Falha ao carregar historico do backend.',
                          onRetry: () => setState(() => _future = _loadAppointments()),
                        );
                      }

                      final history = [...snapshot.data!]
                        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
                      if (history.isEmpty) {
                        return EmptyState(message: 'Sem consultas para este paciente no backend.');
                      }

                      return Column(
                        children: history.asMap().entries.map((entryMap) {
                          final index = entryMap.key;
                          final orderIndex = history.length - 1 - index;
                          final entry = entryMap.value;
                          return _HistoryCard(
                            title: _consultationOrderLabel(orderIndex),
                            date: _formatDateTime(entry.appointmentDate),
                            subtitle: _historySubtitle(entry),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecentAppointmentDetailScreen(
                                    appointment: entry,
                                    patient: widget.patient,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final ApiClient _api = ApiClient();
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

  bool _saving = false;
  String? _error;

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

  DateTime? _parseOptionalDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(trimmed);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final parsed = DateTime.tryParse('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
      if (parsed != null && parsed.day == day && parsed.month == month && parsed.year == year) {
        return parsed;
      }
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    final cpfFormatted = _cpfCtrl.text.trim();
    final cpfDigits = cpfFormatted.replaceAll(RegExp(r'\D'), '');
    final doctorId = widget.currentUser?.id ?? '';

    if (name.isEmpty) {
      setState(() => _error = 'O campo Nome completo é obrigatório.');
      return;
    }
    if (cpfDigits.length != 11) {
      setState(() => _error = 'CPF inválido. Use 11 dígitos.');
      return;
    }
    if (doctorId.isEmpty) {
      setState(() => _error = 'Não foi possível identificar o médico logado.');
      return;
    }

    final lastAppointment = _parseOptionalDate(_lastAppointmentCtrl.text);
    if (_lastAppointmentCtrl.text.trim().isNotEmpty && lastAppointment == null) {
      setState(() => _error = 'Data da última consulta inválida. Use DD/MM/AAAA.');
      return;
    }

    final birthDate = _parseOptionalDate(_birthDateCtrl.text);
    if (_birthDateCtrl.text.trim().isNotEmpty && birthDate == null) {
      setState(() => _error = 'Data de nascimento inválida. Use DD/MM/AAAA.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _api.createPatient(
        doctorId: doctorId,
        name: name,
        cpf: cpfDigits,
        lastAppointment: lastAppointment,
        zipCode: _zipCodeCtrl.text,
        street: _streetCtrl.text,
        streetNumber: _streetNumberCtrl.text,
        neighborhood: _neighborhoodCtrl.text,
        city: _cityCtrl.text,
        addressComplement: _addressComplementCtrl.text,
        age: _ageCtrl.text.trim().isEmpty ? null : int.tryParse(_ageCtrl.text.trim()),
        birthDate: birthDate,
        maritalStatus: _maritalStatusCtrl.text,
        profession: _professionCtrl.text,
        previousDiseases: _previousDiseasesCtrl.text,
        allergies: _allergiesCtrl.text,
        medications: _medicationsCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente salvo com sucesso.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  ),
                  const Expanded(
                    child: Text(
                      'Novo paciente',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.wine),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 10),
              _NewPatientCategoryCard(
                title: 'Dados principais',
                children: [
                  _NewPatientDesignInput(label: 'Nome completo', controller: _nameCtrl, isRequired: true),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(
                    label: 'CPF',
                    controller: _cpfCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [_CpfInputFormatter()],
                    isRequired: true,
                  ),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(
                    label: 'Data da última consulta',
                    controller: _lastAppointmentCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [_DateInputFormatter()],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NewPatientCategoryCard(
                title: 'Informações do paciente',
                children: [
                  _NewPatientDesignInput(label: 'Idade', controller: _ageCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(
                    label: 'Data de nascimento',
                    controller: _birthDateCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [_DateInputFormatter()],
                  ),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Estado civil', controller: _maritalStatusCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Ocupação', controller: _professionCtrl),
                ],
              ),
              const SizedBox(height: 12),
              _NewPatientCategoryCard(
                title: 'Histórico clínico',
                children: [
                  _NewPatientDesignInput(label: 'Doenças prévias', controller: _previousDiseasesCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Alergias', controller: _allergiesCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Medicamentos', controller: _medicationsCtrl),
                ],
              ),
              const SizedBox(height: 12),
              _NewPatientCategoryCard(
                title: 'Endereço',
                children: [
                  _NewPatientDesignInput(label: 'CEP', controller: _zipCodeCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Logradouro', controller: _streetCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Número', controller: _streetNumberCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Bairro', controller: _neighborhoodCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Município', controller: _cityCtrl),
                  const SizedBox(height: 10),
                  _NewPatientDesignInput(label: 'Complemento', controller: _addressComplementCtrl),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    shadowColor: const Color(0x553D0000),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Text('Salvar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewConsultationScreen extends StatefulWidget {
  const NewConsultationScreen({super.key, this.currentUser, this.initialPatient});

  final ApiUser? currentUser;
  final ApiPatient? initialPatient;

  @override
  State<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends State<NewConsultationScreen> {
  int _step = 0;
  final _api = ApiClient();

  // Step 1 — Dados gerais
  final _nameCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _cpfFocusNode = FocusNode();
  List<ApiPatient> _patients = [];
  List<ApiPatient> _filteredPatients = [];
  bool _loadingPatients = true;
  bool _suppressNoPatientMessage = false;
  bool _isSelectingPatientSuggestion = false;
  ApiClinicLocation? _selectedLocation;
  List<ApiClinicLocation> _locations = [];
  bool _loadingLocations = true;
  final _ageCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _relationalStatusCtrl = TextEditingController();
  final _sexualOrientationCtrl = TextEditingController();
  final _partnerSerologicalStatusCtrl = TextEditingController();

  // Step 2 — Rastreamento e prevenção
  final _cardiovascularRiskCtrl = TextEditingController();
  final _neoplasiaCtrl = TextEditingController();
  final _coinfectionsCtrl = TextEditingController();
  final _immunizationsCtrl = TextEditingController();
  final _boneHealthCtrl = TextEditingController();

  // Step 3 — Status Clínico e Terapêutico do HIV
  final _hivDiagnosisDateCtrl = TextEditingController();
  final _cd4InitialCtrl = TextEditingController();
  final _cd4CurrentCtrl = TextEditingController();
  final _tarvCtrl = TextEditingController();
  final _viralLoadInitialCtrl = TextEditingController();
  final _virologicalStatusCtrl = TextEditingController();
  final _treatmentAdherenceCtrl = TextEditingController();

  // Step 4 — Histórico clínico
  final _comorbiditiesCtrl = TextEditingController();
  final _previousDiseasesCtrl = TextEditingController();
  final _therapeuticHistoryCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _surgeriesCtrl = TextEditingController();

  // Step 5 — Observações
  final _observationsCtrl = TextEditingController();

  static const _stepTitles = [
    'Dados gerais',
    'Rastreamento e prevenção',
    'Status Clínico e Terapêutico do HIV',
    'Histórico clínico',
    'Observações',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
    _cpfCtrl.addListener(_onCpfChanged);
    _prefillFromInitialPatient();
    _loadPatients();
    _loadLocations();
  }

  void _prefillFromInitialPatient() {
    final patient = widget.initialPatient;
    if (patient == null) return;

    _applyPatientToGeneralData(patient);
  }

  void _applyPatientToGeneralData(ApiPatient patient) {
    _isSelectingPatientSuggestion = true;

    _nameCtrl.text = patient.name;
    _cpfCtrl.text = _formatCpf(patient.cpf);
    if (patient.age != null) {
      _ageCtrl.text = patient.age.toString();
    } else {
      _ageCtrl.clear();
    }
    if (patient.birthDate != null) {
      _birthDateCtrl.text = _formatDate(patient.birthDate!);
    } else {
      _birthDateCtrl.clear();
    }
    final profession = patient.profession?.trim() ?? '';
    if (profession.isNotEmpty) {
      _occupationCtrl.text = profession;
    } else {
      _occupationCtrl.clear();
    }
    final maritalStatus = patient.maritalStatus?.trim() ?? '';
    if (maritalStatus.isNotEmpty) {
      _relationalStatusCtrl.text = maritalStatus;
    } else {
      _relationalStatusCtrl.clear();
    }
    final sexualOrientation = patient.sexualOrientation?.trim() ?? '';
    if (sexualOrientation.isNotEmpty) {
      _sexualOrientationCtrl.text = sexualOrientation;
    } else {
      _sexualOrientationCtrl.clear();
    }
    final partnerSerologicalStatus = patient.partnerSerologicalStatus?.trim() ?? '';
    if (partnerSerologicalStatus.isNotEmpty) {
      _partnerSerologicalStatusCtrl.text = partnerSerologicalStatus;
    } else {
      _partnerSerologicalStatusCtrl.clear();
    }

    _nameCtrl.selection = TextSelection.collapsed(offset: _nameCtrl.text.length);
    _cpfCtrl.selection = TextSelection.collapsed(offset: _cpfCtrl.text.length);
    _isSelectingPatientSuggestion = false;
    _applyPatientFilter();
  }

  Future<void> _openPreventCalculator() async {
    const url =
        'https://professional-heart-org.translate.goog/en/guidelines-and-statements/prevent-calculator?_x_tr_sl=en&_x_tr_tl=pt&_x_tr_hl=pt&_x_tr_pto=tc';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a calculadora PREVENT.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatCpf(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return '${digits.substring(0, 3)}.${digits.substring(3)}';
    if (digits.length <= 9) return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _api.fetchPatients(doctorId: widget.currentUser?.id);
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loadingPatients = false;
      });
      _applyPatientFilter();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _patients = [];
        _filteredPatients = [];
        _loadingPatients = false;
      });
    }
  }

  void _onNameChanged() {
    if (_isSelectingPatientSuggestion) {
      _applyPatientFilter();
      return;
    }
    _suppressNoPatientMessage = false;
    _applyPatientFilter();
  }

  void _onCpfChanged() {
    if (_isSelectingPatientSuggestion) {
      _applyPatientFilter();
      return;
    }
    _suppressNoPatientMessage = false;
    _applyPatientFilter();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _applyPatientFilter() {
    final nameQuery = _nameCtrl.text.trim().toLowerCase();
    if (nameQuery.isEmpty) {
      if (mounted) {
        setState(() => _filteredPatients = []);
      }
      return;
    }

    final filtered = _patients
        .where((p) {
          final patientName = p.name.toLowerCase();
          return patientName.contains(nameQuery);
        })
        .take(8)
        .toList();
    if (mounted) {
      setState(() => _filteredPatients = filtered);
    }
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _api.fetchClinicLocations(doctorId: widget.currentUser?.id);
      if (mounted) setState(() { _locations = locations; _loadingLocations = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _cpfCtrl.removeListener(_onCpfChanged);
    _nameFocusNode.dispose();
    _cpfFocusNode.dispose();
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _ageCtrl.dispose();
    _birthDateCtrl.dispose();
    _occupationCtrl.dispose();
    _relationalStatusCtrl.dispose();
    _sexualOrientationCtrl.dispose();
    _partnerSerologicalStatusCtrl.dispose();
    _cardiovascularRiskCtrl.dispose();
    _neoplasiaCtrl.dispose();
    _coinfectionsCtrl.dispose();
    _immunizationsCtrl.dispose();
    _boneHealthCtrl.dispose();
    _hivDiagnosisDateCtrl.dispose();
    _cd4InitialCtrl.dispose();
    _cd4CurrentCtrl.dispose();
    _tarvCtrl.dispose();
    _viralLoadInitialCtrl.dispose();
    _virologicalStatusCtrl.dispose();
    _treatmentAdherenceCtrl.dispose();
    _comorbiditiesCtrl.dispose();
    _previousDiseasesCtrl.dispose();
    _therapeuticHistoryCtrl.dispose();
    _allergiesCtrl.dispose();
    _surgeriesCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  Widget _buildNameFieldWithSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nome completo *',
          style: TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          focusNode: _nameFocusNode,
          style: const TextStyle(fontSize: 16, color: AppColors.wine),
          decoration: InputDecoration(
            hintText: 'Nome completo',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A5A5A), fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFF7F3F3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.wine, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'CPF',
          style: TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cpfCtrl,
          focusNode: _cpfFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: const [_CpfInputFormatter()],
          style: const TextStyle(fontSize: 16, color: AppColors.wine),
          decoration: InputDecoration(
            hintText: 'CPF',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A5A5A), fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFF7F3F3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.wine, width: 1.5),
            ),
          ),
        ),
        if (_nameCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (_loadingPatients)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Carregando pacientes...',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A5A5A)),
              ),
            )
          else if (_filteredPatients.isEmpty)
            ...[
              if (!_suppressNoPatientMessage)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Nenhum paciente encontrado para os dados informados.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A5A5A)),
                  ),
                ),
            ]
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9C6F6F), width: 1.0),
              ),
              child: Column(
                children: _filteredPatients
                    .map(
                      (patient) => ListTile(
                        dense: true,
                        title: Text(
                          patient.name,
                          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        ),
                        subtitle: Text(
                          _formatCpf(patient.cpf),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A5A5A)),
                        ),
                        onTap: () {
                          _suppressNoPatientMessage = true;
                          _applyPatientToGeneralData(patient);
                          FocusScope.of(context).unfocus();
                          setState(() => _filteredPatients = []);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ],
    );
  }

  void _onBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _onNext() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildLocationField() {
    final displayText = _selectedLocation?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Local da consulta', style: TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: (_loadingLocations || _locations.isEmpty)
              ? null
              : () async {
                  final selected = await showDialog<ApiClinicLocation>(
                    context: context,
                    builder: (ctx) => SimpleDialog(
                      title: const Text('Local da consulta',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.wine)),
                      children: _locations
                          .map((loc) => SimpleDialogOption(
                                onPressed: () => Navigator.of(ctx).pop(loc),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(loc.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text(loc.fullAddress,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  );
                  if (selected != null) setState(() => _selectedLocation = selected);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF9C6F6F), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _loadingLocations
                      ? const Text('Carregando locais...',
                          style: TextStyle(fontSize: 14, color: Color(0xFF8A5A5A)))
                      : Text(
                          displayText ?? 'Local da consulta',
                          style: TextStyle(
                            fontSize: displayText != null ? 16 : 14,
                            color: displayText != null ? AppColors.wine : const Color(0xFF8A5A5A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                if (_loadingLocations)
                  const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wine))
                else
                  const Icon(Icons.arrow_drop_down, color: AppColors.wine),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(fontSize: 16, color: AppColors.wine),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A5A5A), fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFF7F3F3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.wine, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return _NewPatientCategoryCard(title: _stepTitles[0], children: [
      _buildNameFieldWithSuggestions(),
      const SizedBox(height: 10),
      _buildLocationField(),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Idade', controller: _ageCtrl, keyboardType: TextInputType.number),
      const SizedBox(height: 10),
      _NewPatientDesignInput(
        label: 'Data de nascimento',
        controller: _birthDateCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: const [_DateInputFormatter()],
      ),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Ocupação', controller: _occupationCtrl),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Status relacional', controller: _relationalStatusCtrl),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Orientação sexual', controller: _sexualOrientationCtrl),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Status sorológico do parceiro', controller: _partnerSerologicalStatusCtrl),
    ]);
  }

  Widget _buildStep2() {
    return _NewPatientCategoryCard(title: _stepTitles[1], children: [
      _buildMultilineInput('Risco cardiovascular', _cardiovascularRiskCtrl),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: _openPreventCalculator,
          child: const Text(
            'Calculadora PREVENT',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.wine,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _buildMultilineInput('Rastreamento de neoplasias', _neoplasiaCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Rastreamento de coinfecções', _coinfectionsCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Imunizações', _immunizationsCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Saúde óssea', _boneHealthCtrl),
    ]);
  }

  Widget _buildStep3() {
    return _NewPatientCategoryCard(title: _stepTitles[2], children: [
      _NewPatientDesignInput(
        label: 'Data do diagnóstico do HIV',
        controller: _hivDiagnosisDateCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: const [_DateInputFormatter()],
      ),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'CD4+ Inicial', controller: _cd4InitialCtrl, keyboardType: TextInputType.number),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'CD4+ Atual', controller: _cd4CurrentCtrl, keyboardType: TextInputType.number),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'TARV atual', controller: _tarvCtrl),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Carga viral inicial', controller: _viralLoadInitialCtrl, keyboardType: TextInputType.number),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Status virológico', controller: _virologicalStatusCtrl),
      const SizedBox(height: 10),
      _NewPatientDesignInput(label: 'Adesão ao tratamento', controller: _treatmentAdherenceCtrl),
    ]);
  }

  Widget _buildStep4() {
    return _NewPatientCategoryCard(title: _stepTitles[3], children: [
      _buildMultilineInput('Comorbidades', _comorbiditiesCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Doenças prévias relevantes', _previousDiseasesCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Histórico terapêutico', _therapeuticHistoryCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Alergias', _allergiesCtrl),
      const SizedBox(height: 10),
      _buildMultilineInput('Cirurgias', _surgeriesCtrl),
    ]);
  }

  Widget _buildStep5() {
    return _NewPatientCategoryCard(title: _stepTitles[4], children: [
      _buildMultilineInput('Observações', _observationsCtrl),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _onBack,
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  ),
                  const Expanded(
                    child: Text(
                      'Nova consulta',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.wine),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.wine : const Color(0xFFD9B8B8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Builder(builder: (_) {
                  switch (_step) {
                    case 0: return _buildStep1();
                    case 1: return _buildStep2();
                    case 2: return _buildStep3();
                    case 3: return _buildStep4();
                    default: return _buildStep5();
                  }
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.wine,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.wine, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Voltar',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paleRose,
                        foregroundColor: AppColors.textDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.wine, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _step < 4 ? 'Próximo' : 'Finalizar',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewClinicLocationScreen extends StatefulWidget {
  const NewClinicLocationScreen({super.key});

  @override
  State<NewClinicLocationScreen> createState() => _NewClinicLocationScreenState();
}

class _NewClinicLocationScreenState extends State<NewClinicLocationScreen> {
  final _zipCodeCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _streetNumberCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();

  @override
  void dispose() {
    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _streetNumberCtrl.dispose();
    _cityCtrl.dispose();
    _complementCtrl.dispose();
    super.dispose();
  }

  InputDecoration _locationInputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A5A5A), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.wine, width: 1.2),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.wine,
        elevation: 0,
        toolbarHeight: 50,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
        title: const Text(
          'HIVision',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _SectionHeaderBar(
            title: 'Novo local',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cadastrar novo local de\natendimento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _requiredLabel('Digite o CEP'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _zipCodeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [_ZipCodeInputFormatter()],
                      style: const TextStyle(fontSize: 16, color: AppColors.wine),
                      decoration: _locationInputDecoration(hint: ''),
                    ),
                    const SizedBox(height: 10),
                    _requiredLabel('Logradouro:'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _streetCtrl,
                      style: const TextStyle(fontSize: 16, color: AppColors.wine),
                      decoration: _locationInputDecoration(hint: ''),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _requiredLabel('Bairro:'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _requiredLabel('Nº'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _neighborhoodCtrl,
                            style: const TextStyle(fontSize: 16, color: AppColors.wine),
                            decoration: _locationInputDecoration(hint: ''),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _streetNumberCtrl,
                            style: const TextStyle(fontSize: 16, color: AppColors.wine),
                            decoration: _locationInputDecoration(hint: ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _requiredLabel('Município:'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cityCtrl,
                      style: const TextStyle(fontSize: 16, color: AppColors.wine),
                      decoration: _locationInputDecoration(hint: ''),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Complemento:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _complementCtrl,
                      style: const TextStyle(fontSize: 16, color: AppColors.wine),
                      decoration: _locationInputDecoration(hint: ''),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.wine),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: AppColors.wine, fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.wine,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Salvar',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClinicLocationsScreen extends StatefulWidget {
  const ClinicLocationsScreen({super.key, this.currentUser, this.onBack});

  final ApiUser? currentUser;
  final VoidCallback? onBack;

  @override
  State<ClinicLocationsScreen> createState() => _ClinicLocationsScreenState();
}

class _ClinicLocationsScreenState extends State<ClinicLocationsScreen> {
  final ApiClient _api = ApiClient();
  late Future<List<ApiClinicLocation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadLocations();
  }

  Future<List<ApiClinicLocation>> _loadLocations() async {
    final doctorId = widget.currentUser?.id;
    if (doctorId == null || doctorId.trim().isEmpty) {
      return const [];
    }
    return _api.fetchClinicLocations(doctorId: doctorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SectionHeaderBar(
              title: 'Locais',
              onBack: widget.onBack ?? () => Navigator.of(context).pop(),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Meus Locais de\natendimentos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NewClinicLocationScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white, size: 20),
                          label: const Text(
                            'Novo local',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.wine,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Locations List
                    FutureBuilder<List<ApiClinicLocation>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.wine),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  'Erro ao carregar locais',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _future = _loadLocations());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.wine,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }

                        final locations = snapshot.data ?? [];

                        if (locations.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'Nenhum local cadastrado',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: List.generate(
                            locations.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index < locations.length - 1 ? 12 : 0,
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 320,
                                  child: _LocationCard(location: locations[index]),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final ApiClinicLocation location;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1D4D4),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A1919),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on, size: 12, color: Color(0xFFC2453B)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Endereço: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6F1F1F),
                          height: 1.35,
                        ),
                      ),
                      TextSpan(
                        text: location.fullAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B3535),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.access_time, size: 12, color: Color(0xFF8D8D8D)),
              ),
              SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Funcionamento: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6F1F1F),
                          height: 1.35,
                        ),
                      ),
                      TextSpan(
                        text: 'Seg - Sex, das 07h às 18h',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B5151),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Sábado, das 08h às 12h',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B5151),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, this.selectedPatient, this.currentUser, this.onBack});

  final ApiPatient? selectedPatient;
  final ApiUser? currentUser;
  final VoidCallback? onBack;

  void _openDocumentEditor(BuildContext context, String documentType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDocumentEditorScreen(
          documentType: documentType,
          currentUser: currentUser,
          prefillData: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeaderBar(
          title: 'Relatórios',
          onBack: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Documentos disponíveis para esse CPF\nsão:',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6A1D1D), height: 1.25),
                  ),
                ),
                const SizedBox(height: 10),
                _ReportsMenuButton(
                  text: 'Relatório Médico',
                  onPressed: () => _openDocumentEditor(context, 'Relatório Médico'),
                ),
                _ReportsMenuButton(
                  text: 'Receituário Médico',
                  onPressed: () => _openDocumentEditor(context, 'Receituário Médico'),
                ),
                _ReportsMenuButton(
                  text: 'Encaminhamento',
                  onPressed: () => _openDocumentEditor(context, 'Encaminhamento'),
                ),
                _ReportsMenuButton(
                  text: 'Atestado Médico Geral',
                  onPressed: () => _openDocumentEditor(context, 'Atestado Médico Geral'),
                ),
                _ReportsMenuButton(
                  text: 'Atestado da Doença',
                  onPressed: () => _openDocumentEditor(context, 'Atestado da Doença'),
                ),
                _ReportsMenuButton(
                  text: 'Declaração de Comparecimento',
                  onPressed: () => _openDocumentEditor(context, 'Declaração de Comparecimento'),
                ),
                _ReportsMenuButton(
                  text: 'Encaminhamento ao CRIE',
                  onPressed: () => _openDocumentEditor(context, 'Encaminhamento ao CRIE'),
                ),
                _ReportsMenuButton(
                  text: 'Solicitação de Exames',
                  onPressed: () => _openDocumentEditor(context, 'Solicitação de Exames'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsMenuButton extends StatelessWidget {
  const _ReportsMenuButton({required this.text, this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD8C7C7),
            foregroundColor: const Color(0xFF5A1919),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
              side: const BorderSide(color: Color(0xFFA17070), width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _SectionHeaderBar(
            title: 'Atestado Médico',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const DesignField(text: 'Atesto por meio desse que :\n******************************'),
                  const DesignField(text: 'Nome completo: **************'),
                  const DesignField(text: 'CPF: ***********'),
                  const DesignField(text: 'Idade: **'),
                  const DesignField(text: 'Data: ******'),
                  const DesignField(text: 'CID: ******'),
                  const SizedBox(height: 6),
                  const PrimaryActionButton(text: 'Preenchimento Automatico'),
                  const PrimaryActionButton(text: 'Gerar PDF'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kHasLoggedIn);
      await prefs.remove(_kLoggedUserJson);
    } catch (_) {
    }

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeaderBar(
          title: 'Meu Perfil',
          onBack: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                Text('Configurações',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                SizedBox(height: 10),
                _SettingCard(title: 'Perfil', description: 'Dados do profissional: nome, registro (CRM) e\ncontato'),
                _SettingCard(
                    title: 'Segurança',
                    description: 'Senha, biometria, autenticação em 2 fatores e\ncontrole de acesso.'),
                _SettingCard(
                    title: 'Clínica',
                    description: 'Informações do consultório: nome, CNPJ,\nendereço, horários e convênios.'),
                _SettingCard(
                    title: 'Notificações', description: 'Lembretes de consultas e alertas importantes'),
                _SettingCard(title: 'Aparência', description: 'Tema, idioma e personalização do app.'),
                SizedBox(height: 4),
                PrimaryActionButton(text: 'Sair e Salvar'),
                PrimaryActionButton(text: 'Deslogar', onPressed: () => _logout(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderBar extends StatelessWidget {
  const _SectionHeaderBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayText = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final profilePhoto = currentUser?.profilePhotoUrl?.trim();
    final hasRemotePhoto = profilePhoto != null && profilePhoto.isNotEmpty;
    final ImageProvider avatarProvider = hasRemotePhoto
        ? NetworkImage(profilePhoto)
        : const AssetImage('assets/images/group_21.png');
    final fullName = (currentUser?.name ?? '').trim();
    final parts = fullName
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
    final displayName = parts.isEmpty
      ? 'Nome Sobrenome'
      : (parts.length == 1 ? parts.first : '${parts.first} ${parts.last}');

    return Container(
      width: double.infinity,
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: avatarProvider,
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá Dr(a) $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                ),
                Text(todayText, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewPatientDesignInput extends StatelessWidget {
  const _NewPatientDesignInput({
    required this.label,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.isRequired = false,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRequired)
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                ),
                const TextSpan(
                  text: ' *',
                  style: TextStyle(fontSize: 14, color: Color(0xFFD32F2F), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
        else
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 16, color: AppColors.wine),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A5A5A), fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFFF7F3F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF9C6F6F), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.wine, width: 1.5),
        ),
      ),
        ),
      ],
    );
  }
}

class _NewPatientCategoryCard extends StatelessWidget {
  const _NewPatientCategoryCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.wine),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  const _DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = rawDigits.length > 8 ? rawDigits.substring(0, 8) : rawDigits;

    String formatted;
    if (digits.length <= 2) {
      formatted = digits;
    } else if (digits.length <= 4) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  const _RoundedInput({
    required this.hint,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: TextAlign.left,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF979797), fontSize: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  const _CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = rawDigits.length > 11 ? rawDigits.substring(0, 11) : rawDigits;

    String formatted;
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 6) {
      formatted = '${digits.substring(0, 3)}.${digits.substring(3)}';
    } else if (digits.length <= 9) {
      formatted = '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    } else {
      formatted = '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ZipCodeInputFormatter extends TextInputFormatter {
  const _ZipCodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = rawDigits.length > 8 ? rawDigits.substring(0, 8) : rawDigits;

    String formatted;
    if (digits.length <= 5) {
      formatted = digits;
    } else {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.wine, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textDark, size: 21),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({this.controller, this.onSearchTap, this.onSubmitted, this.onChanged});

  final TextEditingController? controller;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.wine, width: 1),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.search, color: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      hintText: 'Procurar paciente',
                      hintStyle: TextStyle(color: Color(0xFF8D8D8D), fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({required this.name, required this.date, this.onTap});

  final String name;
  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              child: DecoratedBox(
                decoration: const BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: AppColors.wine))),
                child: SizedBox(width: 48, height: 48, child: Center(child: Text(_buildInitials(name), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: AppColors.textDark),
                      const SizedBox(width: 4),
                      Text(_formatDateTime(date), style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientListItem extends StatelessWidget {
  const _PatientListItem({required this.initials, required this.name, required this.document});

  final String initials;
  final String name;
  final String document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            child: DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: AppColors.wine))),
              child: SizedBox(width: 48, height: 48, child: Center(child: Text(initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: Color(0xFF8C78F9), size: 14),
                    const SizedBox(width: 4),
                    Text(document, style: const TextStyle(fontSize: 14, color: Color(0xFF8D8D8D))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.title, required this.date, this.subtitle, this.onTap});

  final String title;
  final String date;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9C5C5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2F2F2F))),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 15, color: Color(0xFF2F2F2F))),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF5A5A5A)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.wine, size: 30),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailActionButton extends StatelessWidget {
  const _PatientDetailActionButton({required this.text, required this.icon, this.onPressed});

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColors.wine,
          foregroundColor: Colors.white,
          shadowColor: const Color(0x553D0000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        icon: Icon(icon, size: 19),
        label: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class PatientDocumentEditorScreen extends StatefulWidget {
  const PatientDocumentEditorScreen({
    super.key,
    required this.documentType,
    this.patient,
    this.currentUser,
    this.prefillData = true,
  });

  final String documentType;
  final ApiPatient? patient;
  final ApiUser? currentUser;
  final bool prefillData;

  @override
  State<PatientDocumentEditorScreen> createState() => _PatientDocumentEditorScreenState();
}

class _PatientDocumentEditorScreenState extends State<PatientDocumentEditorScreen> {
  final ApiClient _api = ApiClient();
  late final TextEditingController _patientNameCtrl;
  late final TextEditingController _cpfCtrl;
  late final TextEditingController _doctorNameCtrl;
  late final TextEditingController _crmCtrl;
  late final TextEditingController _dateCtrl;
  late final Map<String, TextEditingController> _extraFieldCtrls;

  String get _loggedDoctorCrm => (widget.currentUser?.crm ?? '').trim();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final patient = widget.patient;
    _patientNameCtrl = TextEditingController(
      text: widget.prefillData ? (patient?.name ?? '') : '',
    );
    _cpfCtrl = TextEditingController(
      text: widget.prefillData && patient != null ? _formatCpf(patient.cpf) : '',
    );
    _doctorNameCtrl = TextEditingController(
      text: widget.prefillData ? (widget.currentUser?.name ?? '') : '',
    );
    _crmCtrl = TextEditingController(text: widget.prefillData ? _loggedDoctorCrm : '');
    _dateCtrl = TextEditingController(
      text: widget.prefillData
          ? '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
          : '',
    );
    _extraFieldCtrls = {};
    for (final field in _fieldsForDocument(widget.documentType)) {
      if (_isBaseFieldKey(field.key)) continue;
      _extraFieldCtrls[field.key] = TextEditingController(
        text: widget.prefillData ? _defaultExtraFieldValue(field.key) : '',
      );
    }
    if (widget.prefillData) {
      _hydrateDoctorDataFromPrefsIfNeeded();
      _hydrateDoctorDataFromApiIfNeeded();
    }
  }

  Future<void> _hydrateDoctorDataFromPrefsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedUser = _readLoggedUserFromPrefs(prefs);
    if (!mounted || loggedUser == null) return;

    final fallbackName = loggedUser.name.trim();
    final fallbackCrm = (loggedUser.crm ?? '').trim();

    if (_doctorNameCtrl.text.trim().isEmpty && fallbackName.isNotEmpty) {
      _doctorNameCtrl.text = fallbackName;
    }
    if (fallbackCrm.isNotEmpty && _crmCtrl.text.trim() != fallbackCrm) {
      _crmCtrl.text = fallbackCrm;
    }
  }

  Future<void> _hydrateDoctorDataFromApiIfNeeded() async {
    var userId = widget.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final loggedUser = _readLoggedUserFromPrefs(prefs);
      userId = loggedUser?.id.trim() ?? '';
    }
    if (userId.isEmpty) return;

    try {
      final freshUser = await _api.fetchUserById(userId);
      if (!mounted) return;

      final freshName = freshUser.name.trim();
      final freshCrm = (freshUser.crm ?? '').trim();

      if (_doctorNameCtrl.text.trim().isEmpty && freshName.isNotEmpty) {
        _doctorNameCtrl.text = freshName;
      }
      if (freshCrm.isNotEmpty && _crmCtrl.text.trim() != freshCrm) {
        _crmCtrl.text = freshCrm;
      }

      if (freshUser.id.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await _persistLoggedUser(prefs, freshUser);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _cpfCtrl.dispose();
    _doctorNameCtrl.dispose();
    _crmCtrl.dispose();
    _dateCtrl.dispose();
    for (final ctrl in _extraFieldCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _downloadDocument() async {
    debugPrint('[PDF] Starting download process...');
    try {
      final regularFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final doc = pw.Document();

      // Gerar PDF baseado no tipo de documento
      final pageContent = _buildDocumentPage(regularFont, boldFont);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (context) => pageContent,
        ),
      );

      final bytes = await doc.save();
      debugPrint('[PDF] Generated PDF with ${bytes.length} bytes');
      final fileName = '${_safeName(widget.documentType)}_${_safeName(_patientNameCtrl.text)}_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('[PDF] Attempting to save with filename: $fileName');
      final savedPath = await _savePdf(bytes, fileName);
      debugPrint('[PDF] Save result: $savedPath');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF salvo em: $savedPath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('[PDF] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    }
  }

  pw.Widget _buildDocumentPage(pw.Font regularFont, pw.Font boldFont) {
    final padding = 40.0;
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    switch (widget.documentType) {
      case 'Relatório Médico':
        return _buildRelatorioMedico(theme, padding);
      case 'Receituário Médico':
        return _buildReceituarioMedico(theme, padding);
      case 'Encaminhamento':
        return _buildEncaminhamento(theme, padding);
      case 'Atestado Médico Geral':
        return _buildAtestadoMedico(theme, padding);
      case 'Atestado da Doença':
        return _buildAtestadoDoenca(theme, padding);
      case 'Declaração de Comparecimento':
        return _buildDeclaracao(theme, padding);
      case 'Encaminhamento ao CRIE':
        return _buildEncaminhamentoCRIE(theme, padding);
      case 'Solicitação de Exames':
        return _buildSolicitacaoExames(theme, padding);
      default:
        return _buildRelatorioMedico(theme, padding);
    }
  }

  pw.Widget _buildRelatorioMedico(pw.ThemeData theme, double padding) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('RELATÓRIO MÉDICO DE SITUAÇÃO CLÍNICA'),
          pw.SizedBox(height: 40),
          _buildLinedFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 10),
          _buildLinedFieldRow('CPF:', _cpfCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 448),
          _buildLinedFieldRow('Nome do médico', _doctorNameCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 16),
          _buildLinedFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 10),
          _buildFieldRow('Assinatura:', '', width: 206),
          pw.SizedBox(height: 10),
          _buildFieldRow('Data:', _dateCtrl.text.trim(), width: 206),
        ],
      ),
    );
  }

  pw.Widget _buildReceituarioMedico(pw.ThemeData theme, double padding) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('RECEITUÁRIO MÉDICO'),
          pw.SizedBox(height: 40),
          _buildLinedFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 206),
          _buildLinedFieldRow('CPF:', _cpfCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 448),
          _buildLinedFieldRow('Nome do médico:', _doctorNameCtrl.text.trim(), width: 206),
          _buildLinedFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          _buildFieldRow('Assinatura:', '', width: 206),
          _buildFieldRow('Data:', _dateCtrl.text.trim(), width: 206),
        ],
      ),
    );
  }

  pw.Widget _buildEncaminhamento(pw.ThemeData theme, double padding) {
    final especialidade = _controllerForField('especialidade').text.trim();
    final acompanhamento = _controllerForField('acompanhamento').text.trim();
    final comorbidades = _controllerForField('comorbidades').text.trim();
    final medicacoes = _controllerForField('medicacoes').text.trim();
    final examesRealizados = _controllerForField('exames_realizados').text.trim();
    final justificativa = _controllerForField('justificativa').text.trim();

    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('ENCAMINHAMENTO MÉDICO', fontSize: 15),
          pw.SizedBox(height: 34),
          _buildLinedFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 320),
          _buildLinedFieldRow('CPF:', _cpfCtrl.text.trim(), width: 200),
          pw.SizedBox(height: 32),
          pw.Text('Encaminho  paciente para avaliação em:', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 10),
          _buildLinedFieldRow('Especialidade:', especialidade, width: 300),
          pw.SizedBox(height: 14),
          pw.Text('Resumo clínico:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Paciente em acompanhamento por:', style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(top: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 1)),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 24),
          _buildLinedFieldRow('Comorbidades:', comorbidades, width: 300),
          pw.SizedBox(height: 18),
          _buildLinedFieldRow('Medicações em uso:', medicacoes, width: 286),
          pw.SizedBox(height: 18),
          _buildLinedFieldRow('Exames já realizados:', examesRealizados, width: 280),
          pw.SizedBox(height: 38),
          _buildLinedFieldRow('Justificativa:', justificativa, width: 304),
          pw.SizedBox(height: 32),
          _buildLinedFieldRow('Nome do médico', _doctorNameCtrl.text.trim(), width: 300),
          _buildLinedFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 14),
          _buildLinedFieldRow('Assinatura:', '', width: 190),
          pw.Text('Data: ${_dateCtrl.text.trim()}', style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _buildAtestadoMedico(pw.ThemeData theme, double padding) {
    final dias = _controllerForField('dias').text.trim();
    final diasExtenso = _controllerForField('dias_extenso').text.trim();
    final dataInicio = _controllerForField('data_inicio').text.trim();
    final cid = _controllerForField('cid').text.trim();

    return pw.Container(
      padding: pw.EdgeInsets.fromLTRB(padding, padding, padding, padding + 80),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('ATESTADO MÉDICO', fontSize: 15),
          pw.SizedBox(height: 34),
          _buildLinedFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 320),
          _buildLinedFieldRow('CPF:', _cpfCtrl.text.trim(), width: 180),
          pw.SizedBox(height: 34),
          pw.Row(
            children: [
              pw.Text('Atesto, para os devidos fins, que o(a) Sr.(a) ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 220,
                height: 16,
                alignment: pw.Alignment.bottomCenter,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(_patientNameCtrl.text.trim(), style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('encontra-se sob cuidados médicos, necessitando de afastamento de suas atividades', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('laborais por ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 34,
                height: 16,
                alignment: pw.Alignment.bottomCenter,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(dias, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Text('(', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 84,
                height: 16,
                alignment: pw.Alignment.bottomCenter,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(diasExtenso, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Text(') dias, a partir de ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 100,
                height: 16,
                alignment: pw.Alignment.bottomCenter,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(dataInicio, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Text('.', style: pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('O paciente encontra-se orientado quanto ao tratamento e acompanhamento.', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 28),
          _buildLinedFieldRow('CID:', cid, width: 120),
          pw.SizedBox(height: 100),
          _buildLinedFieldRow('Nome do médico', _doctorNameCtrl.text.trim(), width: 310),
          _buildLinedFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 14),
          _buildLinedFieldRow('Assinatura:', '', width: 160),
          _buildLinedFieldRow('Data:', _dateCtrl.text.trim(), width: 120),
        ],
      ),
    );
  }

  pw.Widget _buildAtestadoDoenca(pw.ThemeData theme, double padding) {
    final cd4Value = _controllerForField('cd4').text.trim();
    final cd4Date = _controllerForField('cd4_data').text.trim();
    final viralLoadValue = _controllerForField('carga_viral').text.trim();
    final viralLoadDate = _controllerForField('carga_viral_data').text.trim();
    final tarvValue = _controllerForField('tarv').text.trim();
    final esquemaValue = _controllerForField('esquema').text.trim();
    final comorbidades = _controllerForField('comorbidades_associadas').text.trim();

    final tarvNormalized = tarvValue
        .toLowerCase()
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('à', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .trim();

    String tarvDisplay = '[ ] Sim [ ] Não';
    if (tarvNormalized == 'sim') {
      tarvDisplay = '[X] Sim [ ] Não';
    } else if (tarvNormalized == 'nao' || tarvNormalized == 'não') {
      tarvDisplay = '[ ] Sim [X] Não';
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('ATESTADO MÉDICO', fontSize: 15),
          pw.SizedBox(height: 28),
          _buildLinedFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 320),
          _buildLinedFieldRow('CPF:', _cpfCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 20),
          pw.Text(
            'Atesto, para os devidos fins, que o(a) paciente acima identificado(a) encontra-se em acompanhamento médico especializado, necessitando de seguimento clínico periódico, realização de exames e adesão terapêutica contínua.',
            style: pw.TextStyle(fontSize: 12, height: 1.5),
          ),
          pw.Text(
            '________________ de Infecção pelo vírus da imunodeficiência humana - HIV.',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Text('CID-10: B24', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Text('CD4+: ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 95,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(cd4Value, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Text(' células/mm³   Data do exame: ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 95,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(cd4Date, style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Text('Carga viral: ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 140,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(viralLoadValue, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Text('   Data do exame: ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 95,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(viralLoadDate, style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text('Em uso de TARV: $tarvDisplay', style: pw.TextStyle(fontSize: 12)),
          pw.Row(
            children: [
              pw.Text('Esquema: ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 260,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(esquemaValue, style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Text('Comorbidades associadas: ', style: pw.TextStyle(fontSize: 12)),
              pw.Container(
                width: 230,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(comorbidades, style: pw.TextStyle(fontSize: 12)),
              ),
            ],
          ),
          pw.SizedBox(height: 42),
          pw.Text(_doctorNameCtrl.text.trim(), style: pw.TextStyle(fontSize: 12)),
          _buildLinedFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 14),
          _buildLinedFieldRow('Assinatura:', '', width: 206),
          _buildLinedFieldRow('Data:', _dateCtrl.text.trim(), width: 120),
        ],
      ),
    );
  }

  pw.Widget _buildDeclaracao(pw.ThemeData theme, double padding) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'DECLARAÇÃO DE COMPARECIMENTO',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15),
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Row(children: [
            pw.Text('Nome: ', style: pw.TextStyle(fontSize: 12)),
            pw.Container(
              width: 320,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Text(_controllerForField('patient_name').text.trim(), style: pw.TextStyle(fontSize: 12)),
            ),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Text('CPF: ', style: pw.TextStyle(fontSize: 12)),
            pw.Container(
              width: 206,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Text(_controllerForField('cpf').text.trim(), style: pw.TextStyle(fontSize: 12)),
            ),
          ]),
          pw.SizedBox(height: 18),
          pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
              children: [
                pw.TextSpan(text: 'Declaro, para os devidos fins, que o(a) Sr.(a) '),
                pw.WidgetSpan(
                  child: pw.Container(
                    width: 140,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Text(_controllerForField('nome_comparecimento').text.trim(), style: pw.TextStyle(fontSize: 12)),
                  ),
                ),
                pw.TextSpan(text: '\ncompareceu a atendimento médico nesta unidade de saúde na data de '),
                pw.WidgetSpan(
                  child: pw.Container(
                    width: 80,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Text(_dateCtrl.text.trim(), style: pw.TextStyle(fontSize: 12)),
                  ),
                ),
                pw.TextSpan(text: ', no período '),
                pw.WidgetSpan(
                  child: pw.Container(
                    width: 120,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Text(_controllerForField('periodo').text.trim(), style: pw.TextStyle(fontSize: 12)),
                  ),
                ),
                pw.TextSpan(text: '.'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'A presente declaração é fornecida para fins de comprovação de comparecimento,\nnão contendo informações clínicas, conforme normas éticas e de sigilo médico.',
            style: pw.TextStyle(fontSize: 11, height: 1.3),
          ),
          pw.SizedBox(height: 40),
          pw.Text(_controllerForField('doctor_name').text.trim(), style: pw.TextStyle(fontSize: 12)),
          pw.Row(children: [
            pw.Text('CRM/UF: ', style: pw.TextStyle(fontSize: 12)),
            pw.Container(
              width: 206,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Text(_controllerForField('crm_uf').text.trim(), style: pw.TextStyle(fontSize: 12)),
            ),
          ]),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            pw.Text('Assinatura: ', style: pw.TextStyle(fontSize: 12)),
            pw.Container(
              width: 206,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
            ),
          ]),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            pw.Text('Data: ', style: pw.TextStyle(fontSize: 12)),
            pw.Container(
              width: 120,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Text(_dateCtrl.text.trim(), style: pw.TextStyle(fontSize: 12)),
            ),
          ]),
        ],
      ),
    );
  }

  pw.Widget _buildEncaminhamentoCRIE(pw.ThemeData theme, double padding) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('ENCAMINHAMENTO AO CRIE - CENTRO DE REFERÊNCIA PARA IMUNOBIOLÓGICOS ESPECIAIS', fontSize: 13),
          pw.SizedBox(height: 24),
          _buildFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 206),
          _buildFieldRow('CPF:', _cpfCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 24),
          pw.Text(
            'Encaminho o paciente acima identificado ao Centro de Referência para Imunobiológicos Especiais (CRIE) para avaliação e possível administração de imunobiológico especiais.',
            style: pw.TextStyle(fontSize: 13, height: 1.7),
          ),
          pw.SizedBox(height: 24),
          _buildLinedFieldRow('Condição clínica / diagnóstico/CID:', '', width: 206),
          pw.SizedBox(height: 24),
          pw.Text('Resumo clínico relevante:'),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            height: 18,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            height: 18,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            height: 18,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
          ),
          pw.SizedBox(height: 42),
          pw.Text(_doctorNameCtrl.text.trim()),
          _buildLinedFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 14),
          _buildFieldRow('Assinatura:', '', width: 206),
          pw.SizedBox(height: 14),
          _buildFieldRow('Data:', _dateCtrl.text.trim(), width: 206),
        ],
      ),
    );
  }

  pw.Widget _buildSolicitacaoExames(pw.ThemeData theme, double padding) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTitleRow('SOLICITAÇÃO DE EXAMES', fontSize: 13),
          pw.SizedBox(height: 28),
          _buildLinedFieldRow('Nome:', _patientNameCtrl.text.trim(), width: 206),
          _buildLinedFieldRow('CPF:', _cpfCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 28),
          pw.Text('Solicito:'),
          pw.SizedBox(height: 4),
          _buildFieldRow('', '', width: double.infinity, maxLines: 12),
          pw.SizedBox(height: 14),
          _buildFieldRow('Indicação clínica:', '', width: 206),
          pw.SizedBox(height: 14),
          pw.Text(_doctorNameCtrl.text.trim()),
          _buildFieldRow('CRM/UF:', _crmCtrl.text.trim(), width: 206),
          pw.SizedBox(height: 14),
          _buildFieldRow('Assinatura:', '', width: 206),
          pw.SizedBox(height: 14),
          _buildFieldRow('Data:', _dateCtrl.text.trim(), width: 206),
        ],
      ),
    );
  }

  pw.Widget _buildTitleRow(String title, {double fontSize = 22}) {
    return pw.Center(
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _getUnderscores(double width) {
    final charWidth = 8.5;
    if (width == double.infinity) {
      return '_' * 80; // Para largura infinita, usar um número padrão grande
    }
    final count = ((width - 20) / charWidth).toInt();
    return '_' * (count > 0 ? count : 5);
  }

  String _getDatePlaceholder() {
    return '____/____/________';
  }

  String _getDateValue(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? _getDatePlaceholder() : trimmedValue;
  }

  pw.Widget _buildLinedFieldRow(String label, String value, {double width = 206}) {
    final fieldTextStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.normal);
    final normalizedValue = value.trim();

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: widget.documentType == 'Relatório Médico' ? 0 : 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$label ', style: fieldTextStyle),
          pw.Container(
            width: width,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(normalizedValue, style: fieldTextStyle),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFieldRow(String label, String value, {double width = double.infinity, int maxLines = 1}) {
    final isDateField = label.toLowerCase().startsWith('data');
    final isSignatureField = label.toLowerCase().startsWith('assinatura');
    final isMultiLine = maxLines > 1;
    final normalizedValue = value.trim();
    final fieldValue = isDateField ? _getDateValue(normalizedValue) : normalizedValue;
    final fieldTextStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.normal);

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: widget.documentType == 'Relatório Médico' ? 0 : 10),
      child: isSignatureField
          ? pw.Row(
              children: [
                pw.Text('Assinatura:', style: fieldTextStyle),
                pw.SizedBox(width: 8),
                pw.Container(
                  width: width,
                  margin: const pw.EdgeInsets.only(top: 8),
                  child: pw.Text(_getUnderscores(width), style: fieldTextStyle),
                ),
              ],
            )
          : isMultiLine
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (label.isNotEmpty)
                      pw.Text('$label', style: fieldTextStyle),
                    if (label.isNotEmpty)
                      pw.SizedBox(height: 4),
                    if (normalizedValue.isNotEmpty)
                      pw.Container(
                        width: width,
                        child: pw.Text(normalizedValue, style: fieldTextStyle),
                      )
                    else
                      pw.SizedBox(height: maxLines * 22),
                  ],
                )
              : pw.Row(
                  children: [
                    pw.Text('$label ', style: fieldTextStyle),
                    pw.Container(
                      width: width,
                      child: pw.Text(
                        fieldValue.isEmpty ? _getUnderscores(width) : fieldValue,
                        style: fieldTextStyle,
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<String> _savePdf(Uint8List bytes, String fileName) async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      debugPrint('[PDF] Detected desktop platform: ${Platform.operatingSystem}');
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      debugPrint('[PDF] HOME env: $home');
      Directory targetDir;

      if (home != null && home.trim().isNotEmpty) {
        final downloads = Directory('$home${Platform.pathSeparator}Downloads');
        targetDir = await downloads.exists() ? downloads : Directory(home);
        debugPrint('[PDF] Desktop target dir: ${targetDir.path}');
      } else {
        targetDir = Directory.current;
        debugPrint('[PDF] Using current directory: ${targetDir.path}');
      }

      final file = File('${targetDir.path}${Platform.pathSeparator}$fileName.pdf');
      debugPrint('[PDF] Writing to: ${file.path}');
      await file.writeAsBytes(bytes, flush: true);
      final fileExists = await file.exists();
      debugPrint('[PDF] File exists after write: $fileExists');
      return file.path;
    }

    if (Platform.isAndroid) {
      debugPrint('[PDF] Attempting Android Downloads...');
      final androidDownloadsPath = await _trySaveInAndroidDownloads(bytes, fileName);
      if (androidDownloadsPath != null) {
        debugPrint('[PDF] Successfully saved to Android: $androidDownloadsPath');
        return androidDownloadsPath;
      }
      debugPrint('[PDF] Android Downloads failed, trying fallback');
    }

    if (Platform.isIOS) {
      debugPrint('[PDF] Attempting iOS/Mac Downloads...');
      final hostDownloadsPath = await _trySaveInMacDownloads(bytes, fileName);
      if (hostDownloadsPath != null) {
        debugPrint('[PDF] Successfully saved to Mac: $hostDownloadsPath');
        return hostDownloadsPath;
      }
      debugPrint('[PDF] Mac Downloads failed, trying fallback');
    }

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return 'Downloads/Arquivos do dispositivo';
  }

  Future<String?> _trySaveInMacDownloads(Uint8List bytes, String fileName) async {
    debugPrint('[PDF] _trySaveInMacDownloads called');

    // Tentar primeiro ~/Downloads (ambiente de desenvolvimento)
    List<String> possibleDownloadPaths = [];

    final home = Platform.environment['HOME'];
    debugPrint('[PDF] HOME: $home');
    if (home != null && home.startsWith('/Users/')) {
      possibleDownloadPaths.add('$home${Platform.pathSeparator}Downloads');
    }

    final user = Platform.environment['USER'];
    debugPrint('[PDF] USER: $user');
    if (user != null && user.trim().isNotEmpty) {
      possibleDownloadPaths.add('/Users/$user${Platform.pathSeparator}Downloads');
    }

    debugPrint('[PDF] Trying Downloads paths: $possibleDownloadPaths');
    for (final path in possibleDownloadPaths) {
      try {
        final downloadsDir = Directory(path);
        final exists = await downloadsDir.exists();
        debugPrint('[PDF] Downloads path exists: $path = $exists');
        if (exists) {
          final file = File('${downloadsDir.path}${Platform.pathSeparator}$fileName.pdf');
          debugPrint('[PDF] Writing to Downloads: ${file.path}');
          await file.writeAsBytes(bytes, flush: true);
          final fileExists = await file.exists();
          debugPrint('[PDF] File exists after write: $fileExists (${file.lengthSync()} bytes)');
          return file.path;
        }
      } catch (e) {
        debugPrint('[PDF] Error trying path $path: $e');
      }
    }

    // Se falhar, usar path_provider Documents (fallback para simulador)
    try {
      debugPrint('[PDF] Downloading paths failed, trying path_provider.getApplicationDocumentsDirectory()...');
      final docsDir = await getApplicationDocumentsDirectory();
      debugPrint('[PDF] Documents directory: ${docsDir.path}');
      final file = File('${docsDir.path}${Platform.pathSeparator}$fileName.pdf');
      debugPrint('[PDF] Writing to: ${file.path}');
      await file.writeAsBytes(bytes, flush: true);
      final fileExists = await file.exists();
      debugPrint('[PDF] File exists after write: $fileExists (${file.lengthSync()} bytes)');
      return file.path;
    } catch (e) {
      debugPrint('[PDF] path_provider failed: $e');
    }

    debugPrint('[PDF] All Mac paths failed');
    return null;
  }

  Future<String?> _trySaveInAndroidDownloads(Uint8List bytes, String fileName) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) return null;
      final file = File('${downloadsDir.path}${Platform.pathSeparator}$fileName.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _safeName(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'documento' : cleaned;
  }

  bool _isBaseFieldKey(String key) {
    return key == 'patient_name' ||
        key == 'cpf' ||
        key == 'doctor_name' ||
        key == 'crm_uf' ||
      key == 'date';
  }

  TextEditingController _controllerForField(String key) {
    switch (key) {
      case 'patient_name':
        return _patientNameCtrl;
      case 'cpf':
        return _cpfCtrl;
      case 'doctor_name':
        return _doctorNameCtrl;
      case 'crm_uf':
        if (widget.prefillData && _crmCtrl.text.trim().isEmpty && _loggedDoctorCrm.isNotEmpty) {
          _crmCtrl.text = _loggedDoctorCrm;
        }
        return _crmCtrl;
      case 'date':
        return _dateCtrl;
      default:
        return _extraFieldCtrls[key]!;
    }
  }

  String _defaultExtraFieldValue(String key) {
    switch (key) {
      case 'assinatura':
        return '';
      case 'nome_comparecimento':
        return widget.patient?.name ?? '';
      default:
        return '';
    }
  }

  List<_DocFieldDef> _fieldsForDocument(String documentType) {
    switch (documentType) {
      case 'Relatório Médico':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('doctor_name', 'Nome do médico'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      case 'Receituário Médico':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('doctor_name', 'Nome do médico'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      case 'Encaminhamento':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('especialidade', 'Especialidade'),
          _DocFieldDef('acompanhamento', 'Paciente em acompanhamento por'),
          _DocFieldDef('comorbidades', 'Comorbidades'),
          _DocFieldDef('medicacoes', 'Medicações em uso'),
          _DocFieldDef('exames_realizados', 'Exames já realizados'),
          _DocFieldDef('justificativa', 'Justificativa'),
          _DocFieldDef('doctor_name', 'Nome do médico'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      case 'Atestado Médico Geral':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('dias', 'Dias de afastamento'),
          _DocFieldDef('dias_extenso', 'Dias por extenso'),
          _DocFieldDef('data_inicio', 'Data de início (dd/mm/aaaa)'),
          _DocFieldDef('cid', 'CID'),
          _DocFieldDef('doctor_name', 'Nome do médico'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      case 'Atestado da Doença':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('diagnostico_em', 'Diagnóstico em'),
          _DocFieldDef('cd4', 'CD4+'),
          _DocFieldDef('cd4_data', 'Data exame CD4+ (dd/mm/aaaa)'),
          _DocFieldDef('carga_viral', 'Carga viral'),
          _DocFieldDef('carga_viral_data', 'Data exame carga viral (dd/mm/aaaa)'),
          _DocFieldDef('tarv', 'Em uso de TARV (Sim/Não)'),
          _DocFieldDef('esquema', 'Esquema'),
          _DocFieldDef('comorbidades_associadas', 'Comorbidades associadas'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      case 'Declaração de Comparecimento':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('nome_comparecimento', 'Sr.(a)'),
          _DocFieldDef('data_comparecimento', 'Data comparecimento (dd/mm/aaaa)'),
          _DocFieldDef('periodo', 'Período'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data (dd/mm/aaaa)'),
        ];
      case 'Encaminhamento ao CRIE':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('condicao_clinica', 'Condição clínica / diagnóstico/CID'),
          _DocFieldDef('resumo_clinico', 'Resumo clínico relevante', maxLines: 5),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      case 'Solicitação de Exames':
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('solicito', 'Solicito', maxLines: 8),
          _DocFieldDef('indicacao_clinica', 'Indicação clínica'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('assinatura', 'Assinatura'),
          _DocFieldDef('date', 'Data'),
        ];
      default:
        return const [
          _DocFieldDef('patient_name', 'Nome'),
          _DocFieldDef('cpf', 'CPF'),
          _DocFieldDef('doctor_name', 'Nome do médico'),
          _DocFieldDef('crm_uf', 'CRM/UF'),
          _DocFieldDef('date', 'Data'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.wine,
        foregroundColor: Colors.white,
        title: Text(widget.documentType),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._fieldsForDocument(widget.documentType).expand(
              (field) => [
                _DocumentField(
                  label: field.label,
                  controller: _controllerForField(field.key),
                  maxLines: field.maxLines,
                  keyboardType: field.key == 'cpf' ? TextInputType.number : null,
                ),
                const SizedBox(height: 10),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadDocument,
                icon: const Icon(Icons.download),
                label: const Text('Baixar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocFieldDef {
  const _DocFieldDef(this.key, this.label, {this.maxLines = 1});

  final String key;
  final String label;
  final int maxLines;
}

class _DocumentField extends StatelessWidget {
  const _DocumentField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.wine)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF9C6F6F))),
          ),
        ),
      ],
    );
  }
}

class DesignField extends StatelessWidget {
  const DesignField({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wine, width: 1),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.w500)),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({super.key, required this.text, this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ElevatedButton(
          onPressed: onPressed ?? () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.paleRose,
            foregroundColor: AppColors.textDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.wine, width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.wine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, color: AppColors.textDark, fontWeight: FontWeight.w700)),
          Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
        ],
      ),
    );
  }
}




String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}


String _formatCpf(String cpfDigits) {
  final digits = cpfDigits.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return cpfDigits;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
}

String _buildInitials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '--';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
