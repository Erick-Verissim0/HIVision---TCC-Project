import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_modal.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogged;

  const LoginScreen({super.key, required this.onLogged});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();

  String? _error;
  String? _message;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    final result = await AuthService.instance.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _error = result.message ?? 'Email ou senha inválidos';
      });
      return;
    }

    widget.onLogged();
  }

  Future<void> _openResetPasswordModal() async {
    _resetEmailController.text = _emailController.text;

    await showAppModal<void>(
      context,
      title: 'Esqueci a senha',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset('assets/images/reset-password.png', height: 120),
          const SizedBox(height: 12),
          const Text(
            'Digite seu email e clique em "Enviar" para receber as instruções de redefinição de senha.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppInput(
            controller: _resetEmailController,
            label: 'Email',
            hintText: 'Digite seu email',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: 'Cancelar',
                  round: true,
                  color: Colors.red,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  title: 'Enviar',
                  round: true,
                  onPressed: () async {
                    final result = await AuthService.instance
                        .resetPassword(_resetEmailController.text);
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _message = result.message;
                      _error = result.success ? null : result.message;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            Expanded(
              child: Container(
                color: const Color(0xFFF2F3F0),
                child: Center(
                  child: Image.asset('assets/images/logo-login.png', width: 520),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Entrar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      AppInput(
                        controller: _emailController,
                        label: 'EMAIL',
                        hintText: 'Digite seu email',
                      ),
                      const SizedBox(height: 8),
                      AppInput(
                        controller: _passwordController,
                        label: 'SENHA',
                        password: true,
                        hintText: 'Digite sua senha',
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _openResetPasswordModal,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      if (_message != null)
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.green),
                        ),
                      const SizedBox(height: 8),
                      AppButton(
                        title: _isLoading ? 'Entrando...' : 'Entrar',
                        round: true,
                        disabled: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Não tem uma conta? Contate o desenvolvedor',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
