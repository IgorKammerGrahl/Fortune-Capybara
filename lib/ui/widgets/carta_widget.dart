// lib/ui/widgets/carta_widget.dart

import 'package:flutter/material.dart';
import '../../models/carta.dart';

class CartaWidget extends StatelessWidget {
  final Carta? carta;

  const CartaWidget({Key? key, this.carta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se a carta não for nula, usa o caminho gerado.
    // Se for nula, usa o seu 'card_empty.png' como placeholder.
    final String imagePath = carta?.imagePath ?? 'assets/images/card_empty.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.asset(
        imagePath,
        width: 70,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Este builder de erro é SUPER útil agora.
          // Se uma imagem não carregar, é porque o nome do arquivo está errado!
          print('Erro ao carregar imagem: $imagePath'); // Ajuda a debugar
          return Container(
            width: 70,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      ),
    );
  }
}
