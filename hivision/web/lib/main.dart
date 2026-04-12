import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const HIVisionWebApp());
}

class WebColors {
  static const wine = Color(0xFF75182B);
  static const lightBackground = Color(0xFFFAF5EE);
}

class ApiClient {
  static const String _baseUrl = 'http://localhost:3001';

  Future<void> requestForgotPasswordCode(String email) async {
    final uri = Uri.parse('$_baseUrl/users/forgot-password/request-link');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_extractErrorMessage(response.body) ?? 'Erro ao solicitar recuperação.');
  }

  Future<void> resendForgotPasswordCode(String email) {
    return requestForgotPasswordCode(email);
  }

  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/forgot-password');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'resetCode': resetCode.trim(),
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_extractErrorMessage(response.body) ?? 'Erro ao redefinir senha.');
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) return message;
        if (message is List && message.isNotEmpty) return message.first.toString();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class HIVisionWebApp extends StatelessWidget {
  const HIVisionWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HIVision Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: WebColors.wine),
        scaffoldBackgroundColor: WebColors.lightBackground,
      ),
      home: const ForgotPasswordScreen(),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

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
      await _apiClient.requestForgotPasswordCode(email);
    } catch (error) {
      if (!mounted) return;
      final text = error.toString();
      setState(() {
        _loading = false;
        if (text.contains('User not found')) {
          _errorMessage = 'Não encontramos conta para este e-mail.';
        } else {
          _errorMessage = 'Não foi possível enviar o código de recuperação.';
        }
      });
      return;
    }

    if (!mounted) return;

    setState(() => _loading = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailConfirmationScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Esqueci minha senha',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: WebColors.wine),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text('E-mail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Digite seu e-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: WebColors.wine, foregroundColor: Colors.white),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Text('Enviar código', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _resending = false;
  String? _errorMessage;

  Future<void> _resend() async {
    if (_resending) return;

    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      await _apiClient.resendForgotPasswordCode(widget.email);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _errorMessage = 'Não foi possível reenviar o código.';
      });
      return;
    }

    if (!mounted) return;

    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código reenviado com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Confirme seu e-mail',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: WebColors.wine),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Enviamos um código de recuperação para:',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Use esse código para definir uma nova senha.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NewPasswordScreen(email: widget.email),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: WebColors.wine, foregroundColor: Colors.white),
                      child: const Text('Recebi o e-mail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _resending ? null : _resend,
                      style: ElevatedButton.styleFrom(backgroundColor: WebColors.wine, foregroundColor: Colors.white),
                      child: _resending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Text('Reenviar e-mail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

    if (resetCode.replaceAll(RegExp(r'\D'), '').length != 6) {
      setState(() => _errorMessage = 'O código deve conter 6 dígitos.');
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
    } catch (error) {
      if (!mounted) return;
      final text = error.toString();
      setState(() {
        _loading = false;
        if (text.contains('inválido') || text.contains('expirado')) {
          _errorMessage = 'Código inválido ou expirado.';
        } else if (text.contains('User not found')) {
          _errorMessage = 'Não encontramos conta para este e-mail.';
        } else {
          _errorMessage = 'Não foi possível redefinir a senha.';
        }
      });
      return;
    }

    if (!mounted) return;

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha atualizada com sucesso!')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WebHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nova senha',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: WebColors.wine),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Conta: ${widget.email}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text('Código de recuperação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '000000', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  const Text('Nova senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Digite a nova senha', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  const Text('Confirmar senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Digite novamente', border: OutlineInputBorder()),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: WebColors.wine, foregroundColor: Colors.white),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Text('Salvar nova senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebHomeScreen extends StatelessWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Home',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: WebColors.wine),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Senha atualizada com sucesso!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WebColors.wine,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Voltar para recuperação de senha'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
