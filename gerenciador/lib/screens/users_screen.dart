import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pagination.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_select.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/paginated_controls.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _nameFilter = TextEditingController();
  final _emailFilter = TextEditingController();
  String _adminFilter = '-1';
  String _lastNameFilterText = '';
  String _lastEmailFilterText = '';

  List<AppUser> _users = const [];
  PaginationMeta? _pagination;
  int _page = 1;
  bool _loading = true;
  String? _success;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _nameFilter.addListener(_onFilterChanged);
    _emailFilter.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameFilter.dispose();
    _emailFilter.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final currentName = _nameFilter.text;
    final currentEmail = _emailFilter.text;

    // TextEditingController listeners also fire on focus/selection changes.
    if (currentName == _lastNameFilterText && currentEmail == _lastEmailFilterText) {
      return;
    }

    _lastNameFilterText = currentName;
    _lastEmailFilterText = currentEmail;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadUsers(page: 1);
    });
  }

  Future<void> _loadUsers({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) {
        _page = page;
      }
    });

    try {
      final response = await UserService.instance.getAll(
        page: _page,
        name: _nameFilter.text,
        email: _emailFilter.text,
        admin: _adminFilter,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _users = response.data;
        _pagination = response.pagination;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _openCreateUserModal() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final cpfController = TextEditingController();
    final crmController = TextEditingController();
    String type = 'doctor';
    String? localError;

    await showAppModal<void>(
      context,
      title: 'Criar usuário',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dados do usuário',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              AppInput(controller: nameController, label: 'Nome *'),
              const SizedBox(height: 10),
              AppInput(controller: emailController, label: 'Email *'),
              const SizedBox(height: 10),
              AppInput(
                controller: passwordController,
                label: 'Senha *',
                password: true,
              ),
              const SizedBox(height: 10),
              AppSelect<String>(
                label: 'Tipo *',
                value: type,
                onChanged: (value) {
                  setModalState(() {
                    type = value ?? 'doctor';
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
              ),
              if (type == 'doctor') ...[
                const SizedBox(height: 10),
                AppInput(controller: cpfController, label: 'CPF *'),
                const SizedBox(height: 10),
                AppInput(controller: crmController, label: 'CRM *'),
              ],
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
                      final password = passwordController.text;
                      final cpf = cpfController.text.replaceAll(RegExp(r'\D'), '');
                      final crm = crmController.text.trim();

                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                        setModalState(() => localError = 'Nome, email e senha são obrigatórios');
                        return;
                      }

                      if (password.length < 6) {
                        setModalState(() => localError = 'A senha deve ter no mínimo 6 caracteres');
                        return;
                      }

                      if (type == 'doctor' && cpf.length != 11) {
                        setModalState(() => localError = 'CPF deve conter 11 dígitos');
                        return;
                      }

                      if (type == 'doctor' && crm.isEmpty) {
                        setModalState(() => localError = 'CRM é obrigatório para médico');
                        return;
                      }

                      try {
                        await UserService.instance.create(
                          name: name,
                          email: email,
                          password: password,
                          type: type,
                          cpf: type == 'doctor' ? cpf : null,
                          crm: type == 'doctor' ? crm : null,
                        );
                        if (!mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                        setState(() => _success = 'Usuário criado com sucesso!');
                        _loadUsers(page: 1);
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
    passwordController.dispose();
    cpfController.dispose();
    crmController.dispose();
  }

  Future<void> _openRemoveUserDialog(AppUser user) async {
    await showAppModal<void>(
      context,
      title: 'Remover usuário',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deseja realmente remover o usuário ${user.name} (${user.email})?'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                child: AppButton(
                  title: 'Sim',
                  round: true,
                  color: const Color(0xFF428F01),
                  onPressed: () async {
                    try {
                      await UserService.instance.delete(user.id);
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _success = 'Usuário removido com sucesso!');
                      _loadUsers(page: 1);
                    } on ApiException catch (error) {
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _error = error.message);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: AppButton(
                  title: 'Não',
                  round: true,
                  color: Colors.red,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEditUserDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final cpfController = TextEditingController(text: user.cpf ?? '');
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    String? localError;

    await showAppModal<void>(
      context,
      title: 'Editar usuário',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(controller: nameController, label: 'Nome *'),
              const SizedBox(height: 10),
              AppInput(controller: emailController, label: 'Email *'),
              if (!user.admin) ...[
                const SizedBox(height: 10),
                AppInput(controller: cpfController, label: 'CPF'),
              ],
              const SizedBox(height: 10),
              AppInput(
                controller: currentPasswordController,
                label: 'Senha atual',
                password: true,
              ),
              const SizedBox(height: 10),
              AppInput(
                controller: newPasswordController,
                label: 'Nova senha',
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
                      final cpf = cpfController.text.replaceAll(RegExp(r'\D'), '');
                      final currentPassword = currentPasswordController.text;
                      final newPassword = newPasswordController.text;

                      if (name.isEmpty || email.isEmpty) {
                        setModalState(() => localError = 'Nome e email são obrigatórios');
                        return;
                      }

                      if (newPassword.isNotEmpty && newPassword.length < 6) {
                        setModalState(() => localError = 'A nova senha deve ter no mínimo 6 caracteres');
                        return;
                      }

                      if (newPassword.isNotEmpty && currentPassword.isEmpty) {
                        setModalState(() => localError = 'Informe a senha atual para alterar a senha');
                        return;
                      }

                      try {
                        await UserService.instance.updateProfile(
                          id: user.id,
                          name: name,
                          email: email,
                          currentPassword: currentPassword,
                          newPassword: newPassword,
                          cpf: user.admin ? null : cpf,
                        );

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        setState(() => _success = 'Usuário atualizado com sucesso!');
                        _loadUsers(page: _page);
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
    cpfController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: AppInput(
                        controller: _nameFilter,
                        label: 'Nome',
                        hintText: 'Digite o nome do usuário',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppInput(
                        controller: _emailFilter,
                        label: 'Email',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppSelect<String>(
                        label: 'Administrador',
                        value: _adminFilter,
                        onChanged: (value) {
                          setState(() => _adminFilter = value ?? '-1');
                          _loadUsers(page: 1);
                        },
                        items: const [
                          DropdownMenuItem(value: '-1', child: Text('Todos')),
                          DropdownMenuItem(value: '1', child: Text('Sim')),
                          DropdownMenuItem(value: '0', child: Text('Não')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                title: 'Novo usuário',
                round: true,
                icon: Icons.add,
                onPressed: _openCreateUserModal,
              ),
            ],
          ),
          if (_success != null) ...[
            const SizedBox(height: 10),
            FeedbackBanner(message: _success!, success: true),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            FeedbackBanner(message: _error!, success: false),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: AppLoader(size: 50))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nome')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Admin')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: _users
                            .map(
                              (user) => DataRow(
                                cells: [
                                  DataCell(Text(user.name)),
                                  DataCell(Text(user.email)),
                                  DataCell(Text(user.admin ? 'ADMINISTRADOR' : 'MÉDICO')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _openEditUserDialog(user),
                                          icon: const Icon(Icons.edit, color: Color(0xFF1AAB67)),
                                        ),
                                        IconButton(
                                          onPressed: () => _openRemoveUserDialog(user),
                                          icon: const Icon(Icons.delete, color: Color(0xFFED1B2D)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
          ),
          if (_pagination != null && (_pagination!.totalPages >= 2)) ...[
            const SizedBox(height: 10),
            PaginatedControls(
              pagination: _pagination!,
              onPageChange: (page) => _loadUsers(page: page),
            ),
          ],
        ],
      ),
    );
  }
}
