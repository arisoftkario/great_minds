import '../models/admin_user_model.dart';
import 'api_client.dart';

class AdminUsersService {
  static final AdminUsersService _instance = AdminUsersService._internal();
  factory AdminUsersService() => _instance;
  AdminUsersService._internal();

  Future<List<AdminUser>> listUsers({
    AdminRole? role,
    AdminUserStatus? status,
  }) async {
    final query = <String, String>{};
    if (role != null) query['role'] = role.apiValue;
    if (status != null) query['status'] = status.apiValue;

    final data = await ApiClient().get(
      '/admin/users',
      query: query.isEmpty ? null : query,
    );

    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();
  }

  Future<AdminUser> createUser({
    required String email,
    required String fullName,
    required String password,
    required AdminRole role,
    AdminUserStatus status = AdminUserStatus.active,
  }) async {
    final data = await ApiClient().post(
      '/admin/users',
      body: {
        'email': email.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'password': password,
        'role': role.apiValue,
        'status': status.apiValue,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse invalide lors de la création.');
    }
    return AdminUser.fromJson(data);
  }

  Future<AdminUser> updateUser({
    required String userId,
    String? email,
    String? fullName,
    String? password,
    AdminRole? role,
    AdminUserStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email.trim().toLowerCase();
    if (fullName != null) body['full_name'] = fullName.trim();
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (role != null) body['role'] = role.apiValue;
    if (status != null) body['status'] = status.apiValue;

    final data = await ApiClient().patch('/admin/users/$userId', body: body);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse invalide lors de la mise à jour.');
    }
    return AdminUser.fromJson(data);
  }

  Future<void> deleteUser(String userId) async {
    await ApiClient().delete('/admin/users/$userId');
  }

  Future<AdminUser> setStatus(String userId, AdminUserStatus status) async {
    return updateUser(userId: userId, status: status);
  }
}
