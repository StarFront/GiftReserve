import 'package:giflist/models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://your-backend-url.com/api';
  
  // Para simular el almacenamiento local
  static User? _currentUser;

  // Login
  Future<User> login({required String email, required String password}) async {
    try {
      // TODO: Implementar llamada real a tu backend AWS
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/login'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'email': email, 'password': password}),
      // );
      
      // Por ahora, simulamos una respuesta exitosa
      // Si el email contiene "host", lo tratamos como host
      final role = email.toLowerCase().contains('host') ? 'host' : 'guest';
      
      _currentUser = User(
        id: '123',
        email: email,
        name: email.split('@')[0],
        role: role,
      );
      
      return _currentUser!;
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // Registro
  Future<User> register({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      // TODO: Implementar llamada real a tu backend AWS
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/register'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': email,
      //     'name': name,
      //     'password': password,
      //     'role': 'guest', // El invitado siempre es guest
      //   }),
      // );
      
      // Por ahora, simulamos una respuesta exitosa
      _currentUser = User(
        id: '456',
        email: email,
        name: name,
        role: 'guest',
      );
      
      return _currentUser!;
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    return _currentUser;
  }

  // Logout
  void logout() {
    _currentUser = null;
  }

  // Verificar si el usuario está autenticado
  bool isAuthenticated() {
    return _currentUser != null;
  }
}
