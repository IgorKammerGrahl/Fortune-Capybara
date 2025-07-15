// lib/models/carta.dart

enum Naipe { copas, ouros, paus, espadas }

// Adicionamos uma extensão para traduzir o Naipe para o nome do arquivo
extension NaipeImageMapping on Naipe {
  String get toFileName {
    switch (this) {
      case Naipe.copas:
        return 'hearts';
      case Naipe.ouros:
        return 'diamonds';
      case Naipe.paus:
        return 'clubs';
      case Naipe.espadas:
        return 'spades';
    }
  }
}

enum Valor {
  dois,
  tres,
  quatro,
  cinco,
  seis,
  sete,
  oito,
  nove,
  dez,
  valete,
  dama,
  rei,
  as,
}

// E uma extensão para traduzir o Valor para o nome do arquivo
extension ValorImageMapping on Valor {
  String get toFileName {
    switch (this) {
      case Valor.as:
        return 'A';
      case Valor.rei:
        return 'K';
      case Valor.dama:
        return 'Q';
      case Valor.valete:
        return 'J';
      case Valor.dez:
        return '10';
      // Para os números de 2 a 9, usamos um truque com o índice do enum
      default:
        // Valor.dois.index é 0. (0 + 2) = 2. padLeft(2, '0') -> "02"
        // Valor.nove.index é 7. (7 + 2) = 9. padLeft(2, '0') -> "09"
        return (this.index + 2).toString().padLeft(2, '0');
    }
  }
}

class Carta {
  final Valor valor;
  final Naipe naipe;

  Carta({required this.valor, required this.naipe});

  String get imagePath {
    // Constrói o caminho de acordo com o seu padrão de arquivos
    return 'assets/images/card_${naipe.toFileName}_${valor.toFileName}.png';
  }

  @override
  String toString() {
    return '${valor.name} de ${naipe.name}';
  }
}
