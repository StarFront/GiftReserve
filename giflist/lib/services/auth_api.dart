import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:giflist/models/user_model.dart';

class AuthApi {
  static const String baseUrl = 'https://ryk54ty6o6.execute-api.us-east-2.amazonaws.com/prod';
  static const String _userKey = 'user_json_v1';
  final storage = const FlutterSecureStorage();
  static User? _currentUser;

  User? getCurrentUser() => _currentUser;

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token inválido');
    String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final bytes = base64.decode(payload);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Future<void> _persistUser(Map<String, dynamic> map) async {
    await storage.write(key: _userKey, value: jsonEncode(map));
  }

  Future<void> restoreSession() async {
    final raw = await storage.read(key: _userKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _currentUser = User(
        id: map['id'] as String,
        email: map['email'] as String,
        name: map['name'] as String,
        role: map['role'] as String,
        token: map['access_token'] as String?,
      );
    } catch (_) {
      await storage.delete(key: _userKey); // limpiar corrupto
    }
  }

  /// Registro
  Future<void> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al registrar: ${response.body}");
    }
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error en login: ${response.body}');
    }

    // Respuesta envuelve JSON dentro de body (string)
    final outer = jsonDecode(response.body) as Map<String, dynamic>;
    final innerBody = jsonDecode(outer['body'] as String) as Map<String, dynamic>;
    final authResult = innerBody['AuthenticationResult'] as Map<String, dynamic>;

    final accessToken = authResult['AccessToken'] as String;
    final idToken = authResult['IdToken'] as String;
    final refreshToken = authResult['RefreshToken'] as String?;

    final claims = _decodeJwt(idToken);
    final role = (claims['custom:role'] as String?) ?? 'guest';
    final name = (claims['name'] as String?) ?? email.split('@').first;
    final realEmail = (claims['email'] as String?) ?? email;
    final id = (claims['sub'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString();

    _currentUser = User(
      id: id,
      email: realEmail,
      name: name,
      role: role,
      token: accessToken,
    );

    final userMap = {
      'id': id,
      'email': realEmail,
      'name': name,
      'role': role,
      'access_token': accessToken,
      'id_token': idToken,
      'refresh_token': refreshToken,
    };
    await _persistUser(userMap);
  }

  /// Verifica si el usuario está logueado
  Future<bool> isAuthenticated() async {
    final raw = await storage.read(key: _userKey);
    return raw != null;
  }
  Future<void> confirmUser({
  required String email,
  required String code,
}) async {
  final url = Uri.parse('$baseUrl/confirm');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'code': code,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Error al confirmar usuario: ${response.body}");
  }
}

    Future<void> confirmAccount({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/confirm');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al confirmar cuenta: ${response.body}");
    }
  }

  Future<void> resendCode({required String email}) async {
    final url = Uri.parse('$baseUrl/resend');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al reenviar código: ${response.body}");
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await storage.delete(key: _userKey);
    _currentUser = null;
  }
}
