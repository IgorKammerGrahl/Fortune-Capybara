// lib/ui/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O corpo do Scaffold é diretamente um Container com a imagem de fundo.
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            // A imagem é definida aqui, dentro da decoração.
            image: AssetImage('assets/images/fortuneCapivara.png'),

            // ESTA É A PROPRIEDADE CHAVE:
            // Garante que a imagem cubra todo o espaço, mesmo que isso
            // signifique cortar as bordas verticais ou horizontais.
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
