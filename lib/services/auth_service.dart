import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_user_model.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String _accessToken = '';
  String _currentUserId = '';
  String _currentEmail = '';
  String _currentFullName = '';
  AdminRole _currentRole = AdminRole.agent;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  String get accessToken => _accessToken;
  String get currentUserId => _currentUserId;
  String get currentEmail => _currentEmail;
  String get currentFullName => _currentFullName;
  String get currentUsername =>
      _currentFullName.isNotEmpty ? _currentFullName : _currentEmail;
  AdminRole get currentRole => _currentRole;
  String? get lastError => _lastError;

  static const String _tokenKey = 'gm_jwt_access_token';
  static const String _userIdKey = 'gm_jwt_user_id';
  static const String _emailKey = 'gm_jwt_email';
  static const String _fullNameKey = 'gm_jwt_full_name';
  static const String _roleKey = 'gm_jwt_role';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey) ?? '';
      _currentUserId = prefs.getString(_userIdKey) ?? '';
      _currentEmail = prefs.getString(_emailKey) ?? '';
      _currentFullName = prefs.getString(_fullNameKey) ?? '';
      _currentRole = AdminRole.fromApi(prefs.getString(_roleKey) ?? 'agent');

      if (_accessToken.isNotEmpty) {
        ApiClient().setAccessToken(_accessToken);
        // Valider le token auprès de l'API
        try {
          final me = await ApiClient().get('/auth/me');
          if (me is Map<String, dynamic>) {
            final user = AdminUser.fromJson(me);
            _currentUserId = user.id;
            _currentEmail = user.email;
            _currentFullName = user.fullName;
            _currentRole = user.role;
            _isAuthenticated = true;
            await _persistSession();
          } else {
            await logout();
          }
        } catch (_) {
          // Token invalide / API indisponible : on garde la session locale
          // pour permettre un retry, mais on marque authentifié seulement si token présent
          _isAuthenticated = true;
        }
      } else {
        _isAuthenticated = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
    }
  }

  bool canAccess(AdminModule module) {
    switch (_currentRole) {
      case AdminRole.superAdmin:
      case AdminRole.admin:
        return true;
      case AdminRole.agent:
        switch (module) {
          case AdminModule.overview:
          case AdminModule.publications:
          case AdminModule.offers:
          case AdminModule.notifications:
            return true;
          case AdminModule.orders:
          case AdminModule.subscribers:
          case AdminModule.settings:
          case AdminModule.users:
            return false;
        }
    }
  }

  bool get canManageUsers =>
      _currentRole == AdminRole.superAdmin || _currentRole == AdminRole.admin;

  bool get isSuperAdmin => _currentRole == AdminRole.superAdmin;

  bool get isAgent => _currentRole == AdminRole.agent;

  /// Connexion via FastAPI JWT. Retourne true en cas de succès.
  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      final data = await ApiClient().post(
        '/auth/login',
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
        auth: false,
      );

      if (data is! Map<String, dynamic>) {
        _lastError = 'Réponse invalide du serveur.';
        return false;
      }

      _accessToken = data['access_token'] as String? ?? '';
      if (_accessToken.isEmpty) {
        _lastError = 'Token manquant dans la réponse.';
        return false;
      }

      ApiClient().setAccessToken(_accessToken);
      _currentUserId = data['user_id'] as String? ?? '';
      _currentEmail = data['email'] as String? ?? email.trim().toLowerCase();
      _currentFullName = data['full_name'] as String? ?? '';
      _currentRole = AdminRole.fromApi(data['role'] as String? ?? 'agent');
      _isAuthenticated = true;

      await _persistSession();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('Login API error: ${e.message}');
      return false;
    } catch (e) {
      _lastError = 'Une erreur est survenue. Veuillez réessayer.';
      debugPrint('Error during login: $e');
      return false;
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _accessToken);
    await prefs.setString(_userIdKey, _currentUserId);
    await prefs.setString(_emailKey, _currentEmail);
    await prefs.setString(_fullNameKey, _currentFullName);
    await prefs.setString(_roleKey, _currentRole.apiValue);
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _accessToken = '';
    _currentUserId = '';
    _currentEmail = '';
    _currentFullName = '';
    _currentRole = AdminRole.agent;
    _lastError = null;
    ApiClient().setAccessToken(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_fullNameKey);
      await prefs.remove(_roleKey);
    } catch (e) {
      debugPrint('Error clearing auth: $e');
    }

    notifyListeners();
  }
}
