import 'package:Hakim/api_service.dart';
import 'package:flutter/material.dart';
import 'package:Hakim/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // ← changed from LoginPage
    );
  }
}
