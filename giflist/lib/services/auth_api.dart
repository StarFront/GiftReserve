import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:giflist/models/user_model.dart';

class AuthApi {
  static const String baseUrl = 'https://ryk54ty6o6.execute-api.us-east-2.amazonaws.com/prod';
  final storage = const FlutterSecureStorage();
  static User? _currentUser;

  User? getCurrentUser() => _currentUser;

  Future<void> setCurrentUser({
    required String email,
    String? name,
    String role = 'guest',
  }) async {
    final token = await storage.read(key: 'token');
    _currentUser = User(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: email,
      name: name ?? (email.split('@').first),
      role: role,
      token: token,
    );
    await storage.write(key: 'email', value: email);
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
  Future<Map<String, dynamic>> login({
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
      throw Exception("Error en login: ${response.body}");
    }

    final data = jsonDecode(response.body);

    // Guarda token (o lo que Cognito envíe)
    await storage.write(key: 'token', value: data['access_token']);
    await storage.write(key: 'email', value: email);

    // Configura usuario en memoria (nombre si viene en data)
    await setCurrentUser(
      email: email,
      name: (data is Map && data['name'] is String) ? data['name'] as String : null,
    );

    return data as Map<String, dynamic>;
  }

  /// Verifica si el usuario está logueado
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'token');
    return token != null;
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
    await storage.delete(key: 'token');
    await storage.delete(key: 'email');
    _currentUser = null;
  }
}
