enum AdminRole {
  superAdmin,
  admin,
  agent;

  static AdminRole fromApi(String value) {
    switch (value) {
      case 'super_admin':
        return AdminRole.superAdmin;
      case 'admin':
        return AdminRole.admin;
      case 'agent':
      default:
        return AdminRole.agent;
    }
  }

  String get apiValue {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.agent:
        return 'agent';
    }
  }

  String get label {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.agent:
        return 'Agent';
    }
  }
}

enum AdminUserStatus {
  active,
  suspended,
  pending;

  static AdminUserStatus fromApi(String value) {
    switch (value) {
      case 'suspended':
        return AdminUserStatus.suspended;
      case 'pending':
        return AdminUserStatus.pending;
      case 'active':
      default:
        return AdminUserStatus.active;
    }
  }

  String get apiValue {
    switch (this) {
      case AdminUserStatus.active:
        return 'active';
      case AdminUserStatus.suspended:
        return 'suspended';
      case AdminUserStatus.pending:
        return 'pending';
    }
  }

  String get label {
    switch (this) {
      case AdminUserStatus.active:
        return 'Actif';
      case AdminUserStatus.suspended:
        return 'Suspendu';
      case AdminUserStatus.pending:
        return 'En attente';
    }
  }
}

/// Modules du dashboard admin (pour le contrôle d'accès).
enum AdminModule {
  overview,
  publications,
  offers,
  orders,
  notifications,
  subscribers,
  settings,
  users,
}

class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final AdminRole role;
  final AdminUserStatus status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: AdminRole.fromApi(json['role'] as String? ?? 'agent'),
      status: AdminUserStatus.fromApi(json['status'] as String? ?? 'active'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson({required String password}) => {
        'email': email,
        'full_name': fullName,
        'role': role.apiValue,
        'status': status.apiValue,
        'password': password,
      };

  Map<String, dynamic> toUpdateJson({String? password}) {
    final map = <String, dynamic>{
      'email': email,
      'full_name': fullName,
      'role': role.apiValue,
      'status': status.apiValue,
    };
    if (password != null && password.isNotEmpty) {
      map['password'] = password;
    }
    return map;
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? fullName,
    AdminRole? role,
    AdminUserStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
