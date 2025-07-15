// lib/models/baralho.dart

import 'dart:math';
import 'carta.dart';

class Baralho {
  List<Carta> cartas = [];

  // Construtor que cria um baralho com 52 cartas
  Baralho() {
    reiniciar();
  }

  void reiniciar() {
    cartas.clear();
    for (var naipe in Naipe.values) {
      for (var valor in Valor.values) {
        cartas.add(Carta(valor: valor, naipe: naipe));
      }
    }
  }

  // Embaralha as cartas
  void embaralhar() {
    cartas.shuffle(Random());
  }

  // Pega a carta do topo do baralho
  Carta? pegarCarta() {
    if (cartas.isNotEmpty) {
      return cartas.removeLast();
    }
    return null;
  }
}
