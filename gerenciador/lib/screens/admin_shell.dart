import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/side_menu.dart';
import 'appointments_screen.dart';
import 'locations_screen.dart';
import 'patients_screen.dart';
import 'users_screen.dart';

class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminShell({super.key, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AppUser? _currentUser;
  int _selectedIndex = 0;
  final Map<int, Widget> _cachedScreens = {
    0: const UsersScreen(),
  };
  static const List<String> _titles = [
    'Usuários',
    'Pacientes',
    'Consultas',
    'Locais',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.currentUser();
    if (!mounted) {
      return;
    }
    setState(() => _currentUser = user);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    widget.onLogout();
  }

  Future<void> _openEditProfile() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    String? localError;

    await showAppModal<void>(
      context,
      title: 'Editar perfil',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            children: [
              AppInput(controller: nameController, label: 'Nome *'),
              const SizedBox(height: 10),
              AppInput(controller: emailController, label: 'Email *'),
              const SizedBox(height: 10),
              AppInput(
                controller: currentPasswordController,
                label: 'Senha atual *',
                password: true,
              ),
              const SizedBox(height: 10),
              AppInput(
                controller: newPasswordController,
                label: 'Nova senha *',
                password: true,
              ),
              if (localError != null) ...[
                const SizedBox(height: 10),
                Text(localError!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    title: 'Cancelar',
                    round: true,
                    color: Colors.red,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    title: 'Salvar',
                    round: true,
                    color: const Color(0xFF2E7D32),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final currentPassword = currentPasswordController.text;
                      final newPassword = newPasswordController.text;

                      if (name.isEmpty || email.isEmpty) {
                        setModalState(
                          () => localError = 'Nome e email são obrigatórios',
                        );
                        return;
                      }

                      if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
                        setModalState(
                          () => localError = 'Senha atual e nova senha são obrigatórias',
                        );
                        return;
                      }

                      if (newPassword.length < 6) {
                        setModalState(
                          () => localError = 'A nova senha deve ter no mínimo 6 caracteres',
                        );
                        return;
                      }

                      try {
                        await UserService.instance.updateProfile(
                          id: user.id,
                          name: name,
                          email: email,
                          currentPassword: currentPassword,
                          newPassword: newPassword,
                        );

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        _loadUser();
                      } on ApiException catch (error) {
                        setModalState(() => localError = error.message);
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  Widget _buildBody() {
    final children = List<Widget>.generate(
      _titles.length,
      (index) => _cachedScreens[index] ?? const SizedBox.shrink(),
    );

    return IndexedStack(
      index: _selectedIndex,
      children: children,
    );
  }

  void _handleSelectScreen(int index) {
    if (!_cachedScreens.containsKey(index)) {
      _cachedScreens[index] = switch (index) {
        0 => const UsersScreen(),
        1 => const PatientsScreen(),
        2 => const AppointmentsScreen(),
        3 => const LocationsScreen(),
        _ => const UsersScreen(),
      };
    }

    setState(() => _selectedIndex = index);

    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _titles[_selectedIndex],
      menu: SideMenu(
        currentUser: _currentUser,
        selectedIndex: _selectedIndex,
        onSelect: _handleSelectScreen,
        onEditProfile: _openEditProfile,
        onLogout: _logout,
      ),
      body: _buildBody(),
    );
  }
}
