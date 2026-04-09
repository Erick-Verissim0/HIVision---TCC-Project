import 'package:flutter/material.dart';

import '../models/user.dart';

class SideMenu extends StatelessWidget {
  final AppUser? currentUser;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  const SideMenu({
    super.key,
    required this.currentUser,
    required this.selectedIndex,
    required this.onSelect,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      (label: 'Usuários', icon: Icons.group),
      (label: 'Pacientes', icon: Icons.person),
      (label: 'Consultas', icon: Icons.calendar_month),
      (label: 'Locais', icon: Icons.location_on),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFDFC), Color(0xFFFFF6F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(right: BorderSide(color: Color(0xFFEAD7CF))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0DDD5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GERENCIADOR HEB',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF5C1711),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'HIVISION',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A6C64),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${currentUser?.name ?? 'Administrador'} (${currentUser?.email ?? 'admin@admin.com'})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A3E3B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onEditProfile,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3E3B),
                        foregroundColor: const Color(0xFFFFFFFF),
                        side: const BorderSide(color: Color(0xFFEFD2C8)),
                      ),
                      child: const Text('Editar perfil'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < items.length; i += 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? const Color(0xFFFFE9E1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: i == selectedIndex
                              ? const Color(0xFF7A251D)
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        items[i].icon,
                        color: i == selectedIndex
                            ? const Color(0xFF7A251D)
                            : const Color(0xFF6E5A55),
                      ),
                      title: Text(
                        items[i].label,
                        style: TextStyle(
                          fontWeight: i == selectedIndex
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: i == selectedIndex
                              ? const Color(0xFF7A251D)
                              : const Color(0xFF4A3E3B),
                        ),
                      ),
                      onTap: () => onSelect(i),
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1EC),
                  foregroundColor: const Color(0xFF9B1717),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
