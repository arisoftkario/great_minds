import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_user_model.dart';
import '../../services/auth_service.dart';

class AdminUserFormDialog extends StatefulWidget {
  final AdminUser? user;

  const AdminUserFormDialog({super.key, this.user});

  @override
  State<AdminUserFormDialog> createState() => _AdminUserFormDialogState();
}

class _AdminUserFormDialogState extends State<AdminUserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _passwordCtrl;
  late AdminRole _role;
  late AdminUserStatus _status;
  bool _obscurePassword = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    _passwordCtrl = TextEditingController();
    _role = user?.role ?? AdminRole.agent;
    _status = user?.status ?? AdminUserStatus.active;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  List<AdminRole> get _availableRoles {
    if (AuthService().isSuperAdmin) {
      return AdminRole.values;
    }
    // Un Admin ne peut créer/modifier que des Agents
    return [AdminRole.agent];
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(<String, dynamic>{
      'email': _emailCtrl.text.trim().toLowerCase(),
      'full_name': _fullNameCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'role': _role,
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier l’utilisateur' : 'Créer un utilisateur agent'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (identifiant de connexion)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: _isEdit
                        ? 'Nouveau mot de passe (optionnel)'
                        : 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (!_isEdit && (v == null || v.length < 4)) {
                      return 'Minimum 4 caractères';
                    }
                    if (_isEdit && v != null && v.isNotEmpty && v.length < 4) {
                      return 'Minimum 4 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AdminRole>(
                  key: ValueKey('role_$_role'),
                  initialValue: _availableRoles.contains(_role) ? _role : AdminRole.agent,
                  decoration: const InputDecoration(
                    labelText: 'Rôle / Autorisation',
                    prefixIcon: Icon(Icons.security_rounded),
                  ),
                  items: _availableRoles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _roleHelpText(_role),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AdminUserStatus>(
                  key: ValueKey('status_$_status'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: AdminUserStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentBlue),
          child: Text(_isEdit ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }

  String _roleHelpText(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Accès total, y compris suppression d’utilisateurs et attribution des rôles Admin.';
      case AdminRole.admin:
        return 'Accès à tous les modules et création d’agents. Ne peut pas supprimer d’utilisateurs.';
      case AdminRole.agent:
        return 'Accès limité : Vue d’ensemble, Publications, Offres et Notifications.';
    }
  }
}
