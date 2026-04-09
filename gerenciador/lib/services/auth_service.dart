import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult(this.success, {this.message});
}

class AuthService {
  AuthService._();

  static const String _userKey = 'user';

  static final AuthService instance = AuthService._();

  Future<AuthResult> login(String email, String password) async {
    try {
      final raw = await ApiClient.instance.post('/users/login', {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;

      final user = AppUser.fromApi(raw);
      if (!user.admin) {
        return const AuthResult(
          false,
          message: 'Você não tem permissão para acessar o gerenciador',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toStorageJson()));
      return const AuthResult(true);
    } on ApiException catch (error) {
      return AuthResult(false, message: error.message);
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.trim().isEmpty) {
      return const AuthResult(false, message: 'Informe um email válido');
    }

    return const AuthResult(
      true,
      message: 'Verifique sua caixa de entrada para redefinir a senha',
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(rawUser) as Map<String, dynamic>;
      return AppUser.fromStorageJson(map);
    } catch (_) {
      // Clear invalid persisted session to avoid startup crash on web refresh.
      await prefs.remove(_userKey);
      return null;
    }
  }
}
