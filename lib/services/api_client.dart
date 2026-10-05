import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool auth = true, bool jsonBody = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final detail = body['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.toString();
        }
      }
    } catch (_) {}
    return 'Erreur serveur (${response.statusCode}).';
  }

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) async {
    try {
      final response = await http.get(_uri(path, query), headers: _headers(auth: auth));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiClient GET error: $e');
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez que l’API FastAPI est démarrée.',
      );
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await http.post(
        _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiClient POST error: $e');
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez que l’API FastAPI est démarrée.',
      );
    }
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await http.patch(
        _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiClient PATCH error: $e');
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez que l’API FastAPI est démarrée.',
      );
    }
  }

  Future<void> delete(String path, {bool auth = true}) async {
    try {
      final response = await http.delete(_uri(path), headers: _headers(auth: auth));
      if (response.statusCode == 204 || response.statusCode == 200) return;
      throw ApiException(_extractErrorMessage(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiClient DELETE error: $e');
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez que l’API FastAPI est démarrée.',
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: 401,
      );
    }
    if (response.statusCode == 403) {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: 403,
      );
    }

    throw ApiException(
      _extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }
}
