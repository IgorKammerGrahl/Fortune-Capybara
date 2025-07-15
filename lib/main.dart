// lib/main.dart
import 'package:flutter/material.dart';
// Mude o import para a splash screen
import 'ui/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Probabilidade App',
      theme: ThemeData(primarySwatch: Colors.green),
      // A tela inicial do app agora é a SplashScreen
      home: const SplashScreen(),
    );
  }
}
