import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const HivisionWebApp());
}

class AppColors {
  static const wine = Color(0xFF760000);
  static const lightBackground = Color(0xFFF3F3F3);
  static const sidePanel = Color(0xFFD9D0D0);
  static const paleRose = Color(0xFFDDCACA);
  static const textDark = Color(0xFF5C0000);
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
  static const String _baseUrl = 'http://localhost:3001';

  Future<void> login({required String email, required String password}) async {
    final uri = Uri.parse('$_baseUrl/users/login');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase(), 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final message = _extractErrorMessage(response.body);
    if (message == 'Invalid credentials') {
      throw Exception('Invalid credentials');
    }
    throw Exception(message ?? 'Erro ao realizar login (${response.statusCode})');
  }

  Future<ApiUser> register({
    required String name,
    required String cpf,
    required String crm,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/doctor');
    final response = await http.post(
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiUser.fromJson(decoded);
      }
      throw Exception('Resposta inválida ao cadastrar usuário');
    }

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao realizar cadastro (${response.statusCode})');
  }

  Future<void> requestForgotPasswordLink({required String email}) async {
    await _postForgotPassword(path: '/users/forgot-password/request-link', email: email);
  }

  Future<void> resendForgotPasswordLink({required String email}) async {
    await _postForgotPassword(path: '/users/forgot-password/resend-link', email: email);
  }

  Future<void> _postForgotPassword({required String path, required String email}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao solicitar recuperação (${response.statusCode})');
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

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final message = _extractErrorMessage(response.body);
    throw Exception(message ?? 'Erro ao redefinir senha (${response.statusCode})');
  }

  String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    } catch (_) {
      return null;
    }
    return null;
  }
}

class HivisionWebApp extends StatelessWidget {
  const HivisionWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HIVision Web',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AppColors.lightBackground,
        fontFamily: 'SF Pro Display',
      ),
      home: const LoginScreen(),
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
  final TapGestureRecognizer _signupTapRecognizer = TapGestureRecognizer();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signupTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Informe email e senha.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiClient.login(email: email, password: password);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'O E-mail ou Senha estão incorretos.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HivisionShell()));
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(logoAsset: 'assets/images/group_21.png'),
      darkHeaderImage: 'assets/images/group_20.png',
      title: 'Bem-Vindo',
      subtitle: '',
      fields: [
        _AuthField(label: 'Email', compact: true, child: _AuthTextField(controller: _emailController, hint: 'exemplo@dominio.com', compact: true)),
        _AuthField(label: 'Senha', compact: true, child: _AuthTextField(controller: _passwordController, hint: 'Senha', obscure: true, compact: true)),
      ],
      footer: null,
      onSubmit: null,
      submitText: '',
      loading: _loading,
      centerPanelContent: true,
      showPanelBrand: false,
      customButtons: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _emailController.text.trim())),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 14),
              SizedBox(width: 6),
              Text('Esqueci minha senha', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Color(0xFFFFDCDC), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        _AuthButton(text: 'Entrar', small: true, loading: _loading, onPressed: _loading ? null : _submit),
        const SizedBox(height: 32),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              children: [
                const TextSpan(text: 'Não tem conta? '),
                TextSpan(
                  text: 'Cadastre-se',
                  style: const TextStyle(decoration: TextDecoration.underline, color: AppColors.paleRose),
                  recognizer: _signupTapRecognizer
                    ..onTap = () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiClient _apiClient = ApiClient();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _crmController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _crmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final name = _nameController.text.trim();
    final cpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');
    final crm = _crmController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if ([name, crm, email, password, confirm].any((v) => v.isEmpty)) {
      setState(() => _error = 'Preencha todos os campos.');
      return;
    }

    if (password != confirm) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    late final ApiUser createdUser;
    try {
      createdUser = await _apiClient.register(name: name, cpf: cpf, crm: crm, email: email, password: password);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível realizar cadastro.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HivisionShell(currentUser: createdUser)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(logoAsset: 'assets/images/group_21.png'),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Cadastrar-se',
      subtitle: '',
      fields: [
        _AuthField(label: 'Nome Completo:', compact: true, child: _AuthTextField(controller: _nameController, hint: 'Nome completo', compact: true)),
        _AuthField(label: 'CRM:', compact: true, child: _AuthTextField(controller: _crmController, hint: 'CRM', compact: true)),
        _AuthField(label: 'Email:', compact: true, child: _AuthTextField(controller: _emailController, hint: 'exemplo@dominio.com', compact: true)),
        _AuthField(label: 'Senha:', compact: true, child: _AuthTextField(controller: _passwordController, hint: 'Senha', obscure: true, compact: true)),
        _AuthField(
          label: 'Confirmar senha:',
          compact: true,
          child: _AuthTextField(controller: _confirmController, hint: 'Senha', obscure: true, compact: true),
        ),
      ],
      footer: _error == null
          ? null
          : Text(_error!, style: const TextStyle(color: Color(0xFFFFDCDC), fontSize: 13, fontWeight: FontWeight.w600)),
      onSubmit: _loading ? null : _submit,
      submitText: 'Criar Conta',
      loading: _loading,
      showPanelBrand: false,
      compact: true,
      centerPanelContent: true,
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
  String? _error;

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
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiClient.requestForgotPasswordLink(email: email);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível solicitar recuperação.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ForgotPasswordConfirmationScreen(email: email)));
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(logoAsset: 'assets/images/group_21.png'),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Esqueceu a senha?',
      subtitle: 'Digite o e-mail cadastrado e enviaremos um código para você criar uma nova senha.',
      fields: [
        _AuthField(label: 'Email', compact: true, child: _AuthTextField(controller: _emailController, hint: 'Digite seu email', compact: true)),
      ],
      footer: null,
      onSubmit: null,
      submitText: '',
      loading: _loading,
      showPanelBrand: false,
      centerPanelContent: true,
      compact: true,
      customButtons: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFFFDCDC), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 42,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: 180,
              height: 42,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.textDark))
                    : const Text('Enviar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
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
  bool _loading = false;

  Future<void> _resend() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _apiClient.resendForgotPasswordLink(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail reenviado com sucesso.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao reenviar e-mail.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(logoAsset: 'assets/images/group_21.png'),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Confirmar e-mail',
      subtitle: '',
      fields: const [],
      customButtons: [
        Center(
          child: Image.asset('assets/images/Frame 194.png', width: 140),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Enviamos um código para: ${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
          ),
        ),
        const SizedBox(height: 24),
        _AuthButton(text: 'Recebi o e-mail', small: true, slim: true, onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewPasswordScreen(email: widget.email)));
        }),
        const SizedBox(height: 10),
        _AuthButton(text: _loading ? 'Reenviando...' : 'Reenviar E-mail', small: true, slim: true, onPressed: _loading ? null : _resend),
      ],
      onSubmit: null,
      submitText: 'Continuar',
      loading: false,
      showPanelBrand: false,
      centerPanelContent: true,
      compact: true,
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
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final code = _codeController.text.trim();
    final pass = _newPasswordController.text;
    final confirm = _confirmController.text;

    if (code.replaceAll(RegExp(r'\D'), '').length != 6) {
      setState(() => _error = 'Código deve ter 6 dígitos.');
      return;
    }

    if (pass.length < 6) {
      setState(() => _error = 'Senha deve ter no mínimo 6 caracteres.');
      return;
    }

    if (pass != confirm) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiClient.resetPassword(email: widget.email, resetCode: code, newPassword: pass);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível redefinir a senha.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HivisionShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSplitLayout(
      lightContent: const _HivisionLogoBlock(logoAsset: 'assets/images/group_21.png'),
      darkHeaderImage: 'assets/images/group_21.png',
      title: 'Criar Nova Senha',
      subtitle: '',
      fields: [
        _AuthField(label: 'Código de recuperação', compact: true, child: _AuthTextField(controller: _codeController, hint: '000000', compact: true)),
        _AuthField(label: 'Nova senha', compact: true, child: _AuthTextField(controller: _newPasswordController, hint: 'Nova senha', obscure: true, compact: true)),
        _AuthField(label: 'Confirmar senha', compact: true, child: _AuthTextField(controller: _confirmController, hint: 'Confirmar senha', obscure: true, compact: true)),
      ],
      footer: null,
      onSubmit: null,
      submitText: '',
      loading: false,
      showPanelBrand: false,
      centerPanelContent: true,
      compact: true,
      customButtons: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFFFDCDC), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.textDark))
                      : const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    backgroundColor: AppColors.wine,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthSplitLayout extends StatelessWidget {
  const _AuthSplitLayout({
    required this.lightContent,
    required this.darkHeaderImage,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.onSubmit,
    required this.submitText,
    required this.loading,
    this.footer,
    this.customButtons,
    this.winePanelOnLeft = false,
    this.centerPanelContent = false,
    this.showPanelBrand = true,
    this.compact = false,
  });

  final Widget lightContent;
  final String darkHeaderImage;
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final VoidCallback? onSubmit;
  final String submitText;
  final bool loading;
  final Widget? footer;
  final List<Widget>? customButtons;
  final bool winePanelOnLeft;
  final bool centerPanelContent;
  final bool showPanelBrand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final formColumn = Column(
      crossAxisAlignment: centerPanelContent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (showPanelBrand) ...[
          Row(
            mainAxisAlignment: centerPanelContent ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Image.asset(darkHeaderImage, width: 48),
              const SizedBox(width: 10),
              const Text(
                'HIVision',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Text(title, style: TextStyle(color: Colors.white, fontSize: compact ? 36.0 : 48.0, fontWeight: FontWeight.w700)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(subtitle, textAlign: centerPanelContent ? TextAlign.center : TextAlign.start, style: TextStyle(color: Colors.white, fontSize: compact ? 14.0 : 17.0, height: 1.3)),
        ],
        const SizedBox(height: 18),
        ...fields,
        if (footer != null) ...[
          const SizedBox(height: 14),
          footer!,
        ],
        const SizedBox(height: 20),
        if (customButtons != null)
          ...customButtons!
        else
          _AuthButton(text: submitText, loading: loading, onPressed: onSubmit, small: compact),
      ],
    );

    final formContent = centerPanelContent
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: formColumn,
            ),
          )
        : formColumn;

    final panel = Container(
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: formContent,
            ),
          );
        },
      ),
    );

    final lightPanel = Container(
      color: AppColors.lightBackground,
      child: Center(child: lightContent),
    );

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (winePanelOnLeft) Expanded(flex: 2, child: panel),
          Expanded(flex: 3, child: lightPanel),
          if (!winePanelOnLeft) Expanded(flex: 2, child: panel),
        ],
      ),
    );
  }
}

class _HivisionLogoBlock extends StatelessWidget {
  const _HivisionLogoBlock({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(logoAsset, width: 120),
        const SizedBox(height: 12),
        const Text(
          'HIVision',
          style: TextStyle(fontSize: 56, color: AppColors.wine, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({required this.label, required this.child, this.compact = false});

  final String label;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: compact ? 13.0 : 17.0, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({required this.controller, required this.hint, this.obscure = false, this.compact = false});

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 14.0 : 18.0;
    final vPad = compact ? 8.0 : 12.0;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF888888), fontSize: fontSize),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.text, this.onPressed, this.loading = false, this.small = false, this.slim = false});

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool small;
  final bool slim;

  @override
  Widget build(BuildContext context) {
    final height = small ? 42.0 : 54.0;
    final fontSize = small ? 16.0 : 24.0;
    final loaderSize = small ? 16.0 : 20.0;

    final button = SizedBox(
      width: slim ? 220 : double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paleRose,
          foregroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: loading
            ? SizedBox(
                width: loaderSize,
                height: loaderSize,
                child: const CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.textDark),
              )
            : Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
      ),
    );

    return slim ? Center(child: button) : button;
  }
}

class HivisionShell extends StatefulWidget {
  const HivisionShell({super.key, this.currentUser});

  final ApiUser? currentUser;

  @override
  State<HivisionShell> createState() => _HivisionShellState();
}

enum _DesktopSection { profile, patients, reports, consultation, settings, notifications }
enum _PatientsPane { newPatient, registered }

class _PatientSummary {
  const _PatientSummary({required this.initials, required this.name, required this.lastVisit});

  final String initials;
  final String name;
  final String lastVisit;
}

class _HivisionShellState extends State<HivisionShell> {
  _DesktopSection _section = _DesktopSection.patients;
  _PatientsPane _patientsPane = _PatientsPane.registered;
  _PatientSummary? _selectedPatient;

  final List<_PatientSummary> _patients = const [
    _PatientSummary(initials: 'LS', name: 'Lucas Sampaio', lastVisit: '17/03/2026 14:35'),
    _PatientSummary(initials: 'AB', name: 'Ana Beatriz', lastVisit: '13/03/2026 09:10'),
    _PatientSummary(initials: 'CD', name: 'Carlos Duarte', lastVisit: '12/03/2026 16:22'),
    _PatientSummary(initials: 'MA', name: 'Maria Almeida', lastVisit: '11/03/2026 11:05'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            section: _section,
            onSelect: (section) {
              setState(() {
                _section = section;
                if (section != _DesktopSection.patients) {
                  _selectedPatient = null;
                }
              });
            },
          ),
          _DesktopMiddlePanel(
            section: _section,
            currentUser: widget.currentUser,
            patientsPane: _patientsPane,
            onPatientsPaneChanged: (pane) {
              setState(() {
                _patientsPane = pane;
                if (pane != _PatientsPane.registered) {
                  _selectedPatient = null;
                }
              });
            },
          ),
          Expanded(
            child: _DesktopMainArea(
              section: _section,
              patientsPane: _patientsPane,
              patients: _patients,
              selectedPatient: _selectedPatient,
              onSelectPatient: (patient) => setState(() => _selectedPatient = patient),
              onBackFromPatient: () => setState(() => _selectedPatient = null),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.section, required this.onSelect});

  final _DesktopSection section;
  final ValueChanged<_DesktopSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 212,
      color: AppColors.wine,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Image.asset('assets/images/frame_22.png', width: 140, fit: BoxFit.contain),
          ),
          const SizedBox(height: 18),
          _DesktopSidebarItem(
            icon: Icons.badge_outlined,
            label: 'Meu Perfil',
            active: section == _DesktopSection.profile,
            onTap: () => onSelect(_DesktopSection.profile),
          ),
          _DesktopSidebarItem(
            icon: Icons.groups_outlined,
            label: 'Pacientes',
            active: section == _DesktopSection.patients,
            onTap: () => onSelect(_DesktopSection.patients),
          ),
          _DesktopSidebarItem(
            icon: Icons.content_copy_outlined,
            label: 'Relatórios',
            active: section == _DesktopSection.reports,
            onTap: () => onSelect(_DesktopSection.reports),
          ),
          _DesktopSidebarItem(
            icon: Icons.medical_services_outlined,
            label: 'Consulta',
            active: section == _DesktopSection.consultation,
            onTap: () => onSelect(_DesktopSection.consultation),
          ),
          _DesktopSidebarItem(
            icon: Icons.settings_outlined,
            label: 'Configuração',
            active: section == _DesktopSection.settings,
            onTap: () => onSelect(_DesktopSection.settings),
          ),
          _DesktopSidebarItem(
            icon: Icons.notifications_none_outlined,
            label: 'Notificações',
            active: section == _DesktopSection.notifications,
            onTap: () => onSelect(_DesktopSection.notifications),
          ),
          const Spacer(),
          _DesktopSidebarItem(
            icon: Icons.logout,
            label: 'Sair',
            active: false,
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  const _DesktopSidebarItem({
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
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 204,
          height: 88,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDDD2D2) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopMiddlePanel extends StatelessWidget {
  const _DesktopMiddlePanel({
    required this.section,
    this.currentUser,
    required this.patientsPane,
    required this.onPatientsPaneChanged,
  });

  final _DesktopSection section;
  final ApiUser? currentUser;
  final _PatientsPane patientsPane;
  final ValueChanged<_PatientsPane> onPatientsPaneChanged;

  @override
  Widget build(BuildContext context) {
    final greetingName = currentUser?.name ?? 'Dra Luiza Siqueira';
    return SizedBox(
      width: 340,
      child: Container(
        color: AppColors.sidePanel,
        padding: const EdgeInsets.fromLTRB(26, 30, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.wine,
                  child: Text(_buildInitials(greetingName), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Olá,', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      Text(greetingName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), maxLines: 2),
                      const SizedBox(height: 3),
                      const Text('17/03/2026', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            if (section == _DesktopSection.patients) ...[
              _DesktopMiddleItem(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Novo Paciente',
                active: patientsPane == _PatientsPane.newPatient,
                onTap: () => onPatientsPaneChanged(_PatientsPane.newPatient),
              ),
              const SizedBox(height: 8),
              _DesktopMiddleItem(
                icon: Icons.groups_outlined,
                label: 'Pacientes Cadastrados',
                active: patientsPane == _PatientsPane.registered,
                onTap: () => onPatientsPaneChanged(_PatientsPane.registered),
              ),
            ] else if (section == _DesktopSection.settings || section == _DesktopSection.profile) ...[
              const _DesktopMiddleItem(icon: Icons.dashboard_outlined, label: 'Inicio', active: false),
              const SizedBox(height: 8),
              const _DesktopMiddleItem(icon: Icons.groups_outlined, label: 'Pacientes', active: false),
              const SizedBox(height: 8),
              const _DesktopMiddleItem(icon: Icons.history, label: 'Histórico', active: false),
              const SizedBox(height: 8),
              const _DesktopMiddleItem(icon: Icons.tune_outlined, label: 'Configurações', active: true),
            ],
            const Spacer(),
            Row(
              children: const [
                Icon(Icons.logout, color: AppColors.textDark, size: 20),
                SizedBox(width: 8),
                Text('Sair', style: TextStyle(color: AppColors.textDark, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMiddleItem extends StatelessWidget {
  const _DesktopMiddleItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.wine : Colors.transparent;
    final fg = active ? Colors.white : const Color(0xFF2E2E2E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _DesktopMainArea extends StatelessWidget {
  const _DesktopMainArea({
    required this.section,
    required this.patientsPane,
    required this.patients,
    required this.selectedPatient,
    required this.onSelectPatient,
    required this.onBackFromPatient,
  });

  final _DesktopSection section;
  final _PatientsPane patientsPane;
  final List<_PatientSummary> patients;
  final _PatientSummary? selectedPatient;
  final ValueChanged<_PatientSummary> onSelectPatient;
  final VoidCallback onBackFromPatient;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.wine,
          padding: const EdgeInsets.fromLTRB(34, 20, 34, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Color(0xFF888888), size: 24),
                      SizedBox(width: 10),
                      Text('Procurar paciente', style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.tune, color: AppColors.wine, size: 24),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.lightBackground,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (section == _DesktopSection.patients) {
      if (patientsPane == _PatientsPane.newPatient) {
        return const _NewPatientDesktopForm();
      }
      if (selectedPatient != null) {
        return _PatientProfileDesktop(patient: selectedPatient!, onBack: onBackFromPatient);
      }
      return _PatientsListDesktop(patients: patients, onSelectPatient: onSelectPatient);
    }

    if (section == _DesktopSection.settings || section == _DesktopSection.profile) {
      return const _SettingsDesktop();
    }

    if (section == _DesktopSection.consultation) {
      return const _DesktopPlaceholder(
        title: 'Nova Consulta',
        subtitle: 'Tela inserida no padrão Desktop. Próximo passo: formulário completo da consulta.',
      );
    }

    if (section == _DesktopSection.reports) {
      return const _DesktopPlaceholder(
        title: 'Relatórios',
        subtitle: 'Tela inserida no padrão Desktop. Próximo passo: integração com geração de documentos.',
      );
    }

    return const _DesktopPlaceholder(
      title: 'Notificações',
      subtitle: 'Tela inserida no padrão Desktop para manter consistência visual com as artes.',
    );
  }
}

class _PatientsListDesktop extends StatelessWidget {
  const _PatientsListDesktop({required this.patients, required this.onSelectPatient});

  final List<_PatientSummary> patients;
  final ValueChanged<_PatientSummary> onSelectPatient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DesktopSectionHeader(title: 'Configuração'),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: Text('Lista de pacientes', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700))),
            Text('Ordenar por', style: TextStyle(fontSize: 24, color: AppColors.textDark)),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: patients.length,
            separatorBuilder: (_, __) => const Divider(color: Color(0x99B58F8F), thickness: 1),
            itemBuilder: (_, index) {
              final patient = patients[index];
              return InkWell(
                onTap: () => onSelectPatient(patient),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.transparent,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x99B58F8F))),
                          child: Center(
                            child: Text(
                              patient.initials.substring(0, 1),
                              style: const TextStyle(fontSize: 20, color: AppColors.textDark, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(patient.name, style: const TextStyle(fontSize: 22, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PatientProfileDesktop extends StatelessWidget {
  const _PatientProfileDesktop({required this.patient, required this.onBack});

  final _PatientSummary patient;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DesktopSectionHeader(title: 'Perfil do Paciente', onBack: onBack),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x99B58F8F))),
                            child: Center(
                              child: Text(patient.initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                            Text(patient.lastVisit, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Informações Gerais do Paciente:', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    const _DesktopInfoCard(
                      text: 'Nome: Lucas sampaio\nCPF: 22.515.544.77\nIdade: 32\nEstado civil: Solteiro\nProfissão: Padeiro',
                    ),
                    const SizedBox(height: 10),
                    const Text('Histórico:', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const _DesktopInfoCard(
                      text: 'Doenças prévias: Sim\nDoença: Diabetes\nAlergias: Ácaros\nMedicamentos: Glifage\nComorbidades: Não\nCirurgias: Não',
                    ),
                    const SizedBox(height: 10),
                    const Text('HIV', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const _DesktopInfoCard(
                      text: 'Diagnóstico: Positivo\nData: 12/12/2025\nCarga viral: 40\nCD4: 1700\nTARV:\nEsquema atual:\nStatus virológico:\nAdesão ao tratamento:',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x99B58F8F)))),
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Rastreamento:', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      _DesktopInfoCard(
                        text: 'Risco cardiovascular:\nRastreamento de neoplasquetas:\nRastreamento de coinfecções:\nImunização:',
                      ),
                      SizedBox(height: 10),
                      Text('Endereco', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      _DesktopInfoCard(text: 'CEP:\nLogradouro:\nMunicípio:\nBairro:\nNúmero:\nComplemento:'),
                      SizedBox(height: 12),
                      _DesktopMainButton(text: 'Nova consulta', icon: Icons.medical_services_outlined),
                      SizedBox(height: 18),
                      Text('Documentos disponiveis para esse CPF são:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      SizedBox(height: 10),
                      _DesktopMainButton(text: 'Relatório Médico'),
                      SizedBox(height: 8),
                      _DesktopMainButton(text: 'Receita'),
                      SizedBox(height: 8),
                      _DesktopMainButton(text: 'Encaminhamento'),
                      SizedBox(height: 8),
                      _DesktopMainButton(text: 'Atestado Médico'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsDesktop extends StatelessWidget {
  const _SettingsDesktop();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DesktopSectionHeader(title: 'Perfil'),
          const SizedBox(height: 12),
          Container(
            height: 102,
            decoration: BoxDecoration(color: AppColors.sidePanel, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.wine,
                  child: Text('LS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Luiza Siqueira', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                    Text('CRM: XXXXXXX-AL', style: TextStyle(fontSize: 14, color: Color(0xFF747474))),
                  ],
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.wine, borderRadius: BorderRadius.circular(22)),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Sair', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Alterar dados do perfil', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 20),
          const _DesktopFormLabel('Nome completo:'),
          const _DesktopLargeInput(hint: 'Luiza Maria da Costa'),
          const SizedBox(height: 8),
          const _DesktopFormLabel('E-mail:'),
          const _DesktopLargeInput(hint: 'exemplo@dominio.com'),
          const SizedBox(height: 8),
          const _DesktopFormLabel('CRM:'),
          const _DesktopLargeInput(hint: '******'),
          const SizedBox(height: 8),
          const _DesktopFormLabel('Senha:'),
          const _DesktopLargeInput(hint: '***********'),
          const SizedBox(height: 20),
          const _DesktopMainButton(text: 'Alterar dados'),
        ],
      ),
    );
  }
}

class _NewPatientDesktopForm extends StatelessWidget {
  const _NewPatientDesktopForm();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _DesktopSectionHeader(title: 'Novo Paciente'),
          SizedBox(height: 16),
          Text('Cadastro de paciente', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
          SizedBox(height: 16),
          _DesktopFormLabel('Nome completo:'),
          _DesktopLargeInput(hint: 'Digite o nome'),
          SizedBox(height: 8),
          _DesktopFormLabel('CPF:'),
          _DesktopLargeInput(hint: '000.000.000-00'),
          SizedBox(height: 8),
          _DesktopFormLabel('Idade:'),
          _DesktopLargeInput(hint: '00'),
          SizedBox(height: 8),
          _DesktopFormLabel('Estado civil:'),
          _DesktopLargeInput(hint: 'Digite o estado civil'),
          SizedBox(height: 8),
          _DesktopFormLabel('Profissão:'),
          _DesktopLargeInput(hint: 'Digite a profissão'),
          SizedBox(height: 18),
          _DesktopMainButton(text: 'Salvar paciente'),
        ],
      ),
    );
  }
}

class _DesktopSectionHeader extends StatelessWidget {
  const _DesktopSectionHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 30))
        else
          const SizedBox(width: 44),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(bottom: 7),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x99B58F8F)))),
            child: Text(title, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
        ),
      ],
    );
  }
}

class _DesktopInfoCard extends StatelessWidget {
  const _DesktopInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x99A45A5A))),
      child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.textDark, height: 1.25)),
    );
  }
}

class _DesktopFormLabel extends StatelessWidget {
  const _DesktopFormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 24, color: AppColors.textDark, fontWeight: FontWeight.w500));
  }
}

class _DesktopLargeInput extends StatelessWidget {
  const _DesktopLargeInput({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF7A1717), width: 1.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(hint, style: const TextStyle(fontSize: 18, color: Color(0xFF8E8E8E))),
      ),
    );
  }
}

class _DesktopMainButton extends StatelessWidget {
  const _DesktopMainButton({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFC4B2B2),
        border: Border.all(color: const Color(0xFF7A1717)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.textDark, size: 18),
            const SizedBox(width: 8),
          ],
          Text(text, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DesktopPlaceholder extends StatelessWidget {
  const _DesktopPlaceholder({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesktopSectionHeader(title: title),
        const SizedBox(height: 18),
        Text(subtitle, style: const TextStyle(fontSize: 22, color: AppColors.textDark)),
      ],
    );
  }
}

String _buildInitials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '--';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
