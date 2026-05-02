import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kHasLoggedIn = 'has_logged_in';

void main() {
  runApp(const HivisionApp());
}

class AppColors {
  static const wine = Color(0xFF760000);
  static const lightBackground = Color(0xFFF3F3F3);
  static const paleRose = Color(0xFFDDCACA);
  static const textDark = Color(0xFF5C0000);
  static const divider = Color(0xFFE6D9FF);
}

class ApiPatient {
  ApiPatient({required this.id, required this.name, required this.cpf, this.lastAppointment});

  final String id;
  final String name;
  final String cpf;
  final DateTime? lastAppointment;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ApiPatient.fromJson(Map<String, dynamic> json) {
    return ApiPatient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Paciente',
      cpf: json['cpf']?.toString() ?? '',
      lastAppointment: _parseDate(json['lastAppointment']),
    );
  }
}

class ApiAppointment {
  ApiAppointment({required this.id, required this.patientId, required this.appointmentDate});

  final String id;
  final String patientId;
  final DateTime appointmentDate;

  factory ApiAppointment.fromJson(Map<String, dynamic> json) {
    return ApiAppointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      appointmentDate: _parseDate(json['appointmentDate']) ?? DateTime.now(),
    );
  }
}

class ApiUser {
  ApiUser({required this.id, required this.name, required this.email, this.crm, this.type});

  final String id;
  final String name;
  final String email;
  final String? crm;
  final String? type;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
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
    );
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

  Future<List<ApiPatient>> fetchPatients({String? name}) async {
    final query = <String, String>{};
    if (name != null && name.trim().isNotEmpty) query['name'] = name.trim();
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

  Future<List<ApiAppointment>> fetchAppointments({String? patientName}) async {
    final query = <String, String>{};
    if (patientName != null && patientName.trim().isNotEmpty) {
      query['patientName'] = patientName.trim();
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

  Future<void> login({required String email, required String password}) async {
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
      return;
    }

    final message = _extractErrorMessage(response.body);
    debugPrint('[ApiClient] login failed (${response.statusCode}): ${message ?? 'sem mensagem'}');
    if (message == 'Invalid credentials') {
      throw Exception('Invalid credentials');
    }

    throw Exception(message ?? 'Erro ao realizar login (${response.statusCode})');
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

      if (!mounted) return;

      if (hasLoggedIn) {
        navigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HivisionShell()),
        );
        return;
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
                  style: TextStyle(color: AppColors.textDark, fontSize: 56, fontWeight: FontWeight.w700),
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

    try {
      await _apiClient.login(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasLoggedIn, true);
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
      MaterialPageRoute(builder: (_) => const HivisionShell()),
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
                      style: TextStyle(color: AppColors.textDark, fontSize: 48, fontWeight: FontWeight.w700),
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
                        fontSize: 40,
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
                      style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700),
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
                      style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700),
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
                      style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700),
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
      await prefs.setBool(_kHasLoggedIn, true);
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
                      style: TextStyle(color: AppColors.textDark, fontSize: 48, fontWeight: FontWeight.w700),
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
                        fontSize: 36,
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

class HivisionShell extends StatefulWidget {
  const HivisionShell({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  State<HivisionShell> createState() => _HivisionShellState();
}

class _HivisionShellState extends State<HivisionShell> {
  int _index = 0;
  ApiPatient? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        onNewConsultation: _openNewConsultation,
        onNewPatient: _openNewPatient,
        currentUser: widget.currentUser,
      ),
      PatientsScreen(onOpenDetail: _openPatientDetail),
      DocumentsScreen(selectedPatient: _selectedPatient),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onChanged: (newIndex) => setState(() => _index = newIndex),
      ),
    );
  }

  void _openNewConsultation() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewConsultationScreen()));
  }

  void _openNewPatient() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewPatientScreen()));
  }

  void _openPatientDetail(ApiPatient patient) {
    setState(() => _selectedPatient = patient);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: patient)));
  }
}

class DashboardData {
  DashboardData({required this.appointments, required this.patientNames});

  final List<ApiAppointment> appointments;
  final Map<String, String> patientNames;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNewConsultation,
    required this.onNewPatient,
    this.currentUser,
  });

  final VoidCallback onNewConsultation;
  final VoidCallback onNewPatient;
  final ApiUser? currentUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<DashboardData> _loadDashboard() async {
    final patients = await _api.fetchPatients();
    final appointments = await _api.fetchAppointments();
    final patientNames = {for (final p in patients) p.id: p.name};
    return DashboardData(appointments: appointments, patientNames: patientNames);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(currentUser: widget.currentUser),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                    const Expanded(
                      child: _ActionChip(icon: Icons.map_outlined, label: 'Locais...'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SearchRow(),
                const SizedBox(height: 26),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Atendimentos Recentes',
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                    ),
                    Text('Ordenar por', style: TextStyle(fontSize: 34, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<DashboardData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.wine));
                      }
                      if (snapshot.hasError) {
                        return _ErrorState(
                          message: 'Falha ao carregar atendimentos do backend.',
                          onRetry: () => setState(() => _future = _loadDashboard()),
                        );
                      }

                      final data = snapshot.data!;
                      final sorted = [...data.appointments]
                        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
                      if (sorted.isEmpty) {
                        return const _EmptyState(message: 'Nenhum atendimento encontrado no backend.');
                      }

                      return ListView.builder(
                        itemCount: sorted.length > 8 ? 8 : sorted.length,
                        itemBuilder: (_, index) {
                          final appointment = sorted[index];
                          final patientName = data.patientNames[appointment.patientId] ?? 'Paciente';
                          return _RecentItem(name: patientName, date: appointment.appointmentDate);
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

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key, required this.onOpenDetail});

  final ValueChanged<ApiPatient> onOpenDetail;

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
    return _api.fetchPatients(name: _searchController.text);
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
        Container(
          color: AppColors.wine,
          padding: const EdgeInsets.fromLTRB(20, 62, 20, 20),
          child: const Row(
            children: [
              Icon(Icons.arrow_back, color: Colors.white, size: 30),
              Spacer(),
              Text('Pacientes', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700)),
              SizedBox(width: 30),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                _SearchRow(controller: _searchController, onFilterTap: _refreshSearch, onSubmitted: (_) => _refreshSearch()),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                      child: Text('Lista de Pacientes',
                          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ),
                    Text('Ordenar por', style: TextStyle(fontSize: 36, color: AppColors.textDark)),
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
                        return _ErrorState(
                          message: 'Falha ao carregar pacientes do backend.',
                          onRetry: _refreshSearch,
                        );
                      }

                      final patients = snapshot.data!;
                      if (patients.isEmpty) {
                        return const _EmptyState(message: 'Nenhum paciente encontrado no backend.');
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

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.patient});

  final ApiPatient patient;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
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
    final appointments = await _api.fetchAppointments();
    return appointments.where((a) => a.patientId == widget.patient.id).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF0DFF1),
            padding: const EdgeInsets.fromLTRB(20, 62, 20, 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 30),
                ),
                const Spacer(),
                const Text('Paciente - Detalhe',
                    style: TextStyle(color: AppColors.textDark, fontSize: 38, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.wine,
                    child: Text(widget.patient.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.patient.name,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(child: _PrimaryPillButton(label: 'Nova consulta')),
                      SizedBox(width: 12),
                      Expanded(child: _PrimaryPillButton(label: 'Exames')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Expanded(child: _PrimaryPillButton(label: 'Encominhamento')),
                      SizedBox(width: 12),
                      Expanded(child: _PrimaryPillButton(label: 'Receitas')),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Historico',
                        style: TextStyle(fontSize: 50, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3A))),
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
                        return _ErrorState(
                          message: 'Falha ao carregar historico do backend.',
                          onRetry: () => setState(() => _future = _loadAppointments()),
                        );
                      }

                      final history = snapshot.data!;
                      if (history.isEmpty) {
                        return const _EmptyState(message: 'Sem consultas para este paciente no backend.');
                      }

                      return Column(
                        children: history.map((entry) {
                          return _HistoryCard(
                            title: 'Consulta',
                            date: _formatDateTime(entry.appointmentDate),
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
      bottomNavigationBar: const AppBottomNav(index: 1),
    );
  }
}

class NewPatientScreen extends StatelessWidget {
  const NewPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                children: const [
                  Text('Novo paciente',
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  SizedBox(height: 18),
                  DesignField(text: 'Nome completo: **************'),
                  DesignField(text: 'CPF: ***********'),
                  DesignField(text: 'Idade: **'),
                  DesignField(text: 'Estado civil: ************'),
                  DesignField(text: 'Profissao: *************'),
                  DesignField(text: 'Doencas previas: **************'),
                  DesignField(text: 'Alergias: ***************'),
                  DesignField(text: 'Medicamentos: **************'),
                  SizedBox(height: 8),
                  PrimaryActionButton(text: 'Salvar'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(index: 1),
    );
  }
}

class NewConsultationScreen extends StatelessWidget {
  const NewConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Center(
                    child: Text('Nova consulta',
                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ),
                  SizedBox(height: 26),
                  Text('Dados gerais:',
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  SizedBox(height: 10),
                  DesignField(text: 'Nome completo: **************'),
                  DesignField(text: 'Orientacao sexual: ***********'),
                  DesignField(text: 'Idade: **'),
                  DesignField(text: 'Estado civil: ************'),
                  DesignField(text: 'Profissao: *************'),
                  DesignField(text: 'Par concordante: ***********'),
                  SizedBox(height: 8),
                  PrimaryActionButton(text: 'Proximo'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(index: 0),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, this.selectedPatient});

  final ApiPatient? selectedPatient;

  @override
  Widget build(BuildContext context) {
    final patient = selectedPatient;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.arrow_back, color: AppColors.textDark, size: 28),
                    SizedBox(width: 10),
                    Text('Documentos',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 24),
                if (patient == null)
                  const _EmptyState(message: 'Selecione um paciente para visualizar os documentos.')
                else
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: AppColors.wine))),
                          child: SizedBox(width: 56, height: 56, child: Center(child: Text(patient.initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.name, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 14, color: AppColors.textDark),
                              const SizedBox(width: 4),
                              Text(_formatCpf(patient.cpf), style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Documentos disponiveis para esse CPF\nsao:',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 14),
                const PrimaryActionButton(text: 'Relatorio Medico'),
                const PrimaryActionButton(text: 'Receita'),
                const PrimaryActionButton(text: 'Encaminhamento'),
                PrimaryActionButton(
                  text: 'Atestado Medico',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CertificateScreen()));
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

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 28),
                      ),
                      const Expanded(
                        child: Text('Atestado Medico',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
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
      bottomNavigationBar: const AppBottomNav(index: 2),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kHasLoggedIn);
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
        const AppHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                Text('Configurações',
                    style: TextStyle(fontSize: 54, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final greetingName = currentUser?.firstName ?? 'Dra Luiza';

    return Container(
      width: double.infinity,
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.wine, size: 30),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ola, $greetingName',
                style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w700),
              ),
              const Text('17/03/2026', style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, this.onChanged});

  final int index;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomIcon(
            icon: Icons.home_outlined,
            selected: index == 0,
            onTap: () => onChanged?.call(0),
          ),
          _BottomIcon(
            icon: Icons.group_outlined,
            selected: index == 1,
            onTap: () => onChanged?.call(1),
          ),
          _BottomIcon(
            icon: Icons.content_copy_outlined,
            selected: index == 2,
            onTap: () => onChanged?.call(2),
          ),
          _BottomIcon(
            icon: Icons.settings_outlined,
            selected: index == 3,
            onTap: () => onChanged?.call(3),
          ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({required this.icon, required this.selected, this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Icon(icon, color: selected ? AppColors.wine : Colors.white, size: 22),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.wine, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDark, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({this.controller, this.onFilterTap, this.onSubmitted});

  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onSubmitted;

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
                const Icon(Icons.search, color: AppColors.textDark),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
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
        const SizedBox(width: 14),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(22),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.wine,
            child: Icon(Icons.tune, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({required this.name, required this.date});

  final String name;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
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

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: AppColors.wine, borderRadius: BorderRadius.circular(28)),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.wine, width: 0.7))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF2F2F2F))),
                const SizedBox(height: 8),
                Text(' $date', style: const TextStyle(fontSize: 16, color: Color(0xFF2F2F2F))),
                const SizedBox(height: 2),
                const Text(' Endereco: Rua das Acacias,\n245 - Bairro Farol, Maceio - AL',
                    style: TextStyle(fontSize: 16, color: Color(0xFF2F2F2F))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _RoundIconButton(icon: Icons.upload_outlined, onTap: () {}),
              const SizedBox(height: 10),
              _RoundIconButton(icon: Icons.remove_red_eye_outlined, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: AppColors.wine, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.wine, foregroundColor: Colors.white),
            child: const Text('Tentar novamente'),
          ),
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
