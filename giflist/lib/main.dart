import 'package:flutter/material.dart';
import 'package:giflist/screens/auth_screen.dart';
import 'package:giflist/screens/home_screen.dart';
import 'package:giflist/services/auth_api.dart';

late final AuthApi _authApi;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _authApi = AuthApi();
  await _authApi.restoreSession();
  final user = _authApi.getCurrentUser();
  final initialRoute = user == null
      ? '/auth'
      : (user.role == 'admin' ? '/home' : '/home'); // ambas por ahora usan HomeScreen
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiftList',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E8C),
        ),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

