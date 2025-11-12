import 'package:flutter/material.dart';
import 'package:giflist/screens/auth_screen.dart';
import 'package:giflist/screens/home_screen.dart';
import 'package:giflist/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiftList',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E8C), // Rosa principal
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    // Si el usuario está autenticado, ir a home, si no, a auth
    if (authService.isAuthenticated()) {
      return HomeScreen();
    } else {
      return const AuthScreen();
    }
  }
}
