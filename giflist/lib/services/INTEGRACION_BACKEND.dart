// GUÍA DE INTEGRACIÓN CON BACKEND AWS
// Este archivo es solo documentación de referencia
// 
// El auth_service.dart actualmente usa mockups
// Cuando integres con backend AWS, reemplaza los métodos con llamadas HTTP reales
// 
// INSTRUCCIONES:
// 1. Añade a pubspec.yaml:
//    dependencies:
//      http: ^1.1.0
//
// 2. Actualiza auth_service.dart con las llamadas HTTP
//
// EJEMPLO DE LLAMADA:
// 
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// 
// Future<User> login({required String email, required String password}) async {
//   final response = await http.post(
//     Uri.parse('https://tu-backend.com/api/auth/login'),
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode({'email': email, 'password': password}),
//   );
//   ...
// }
