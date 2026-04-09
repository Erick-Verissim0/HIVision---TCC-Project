import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'models/user.dart';
import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const HivisionManagerApp());
}

class HivisionManagerApp extends StatefulWidget {
  const HivisionManagerApp({super.key});

  @override
  State<HivisionManagerApp> createState() => _HivisionManagerAppState();
}

class _HivisionManagerAppState extends State<HivisionManagerApp> {
  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    AppUser? user;
    try {
      user = await AuthService.instance.currentUser();
    } catch (_) {
      user = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = user != null;
      _checkingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HIVision Gerenciador',
      theme: AppTheme.light,
      home: _checkingAuth
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isAuthenticated
              ? AdminShell(
                  onLogout: () => setState(() => _isAuthenticated = false),
                )
              : LoginScreen(
                  onLogged: () => setState(() => _isAuthenticated = true),
                ),
    );
  }
}
