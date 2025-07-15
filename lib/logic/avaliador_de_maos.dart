// lib/logic/avaliador_de_maos.dart
import '../models/carta.dart';

// O enum já tem uma ordem natural de força, do menor para o maior.
enum ForcaDaMao {
  highCard,
  umPar,
  doisPares,
  trinca,
  straight,
  flush,
  fullHouse,
  quadra,
  straightFlush,
  royalFlush,
}

class ResultadoMao {
  final ForcaDaMao forca;
  final List<Valor> valoresRelevantes;

  ResultadoMao({required this.forca, required this.valoresRelevantes});

  // Para facilitar o debug no console
  @override
  String toString() {
    return 'Forca: ${forca.name}, Valores: ${valoresRelevantes.map((v) => v.name).join(', ')}';
  }
}

class AvaliadorDeMaos {
  /// Função principal que recebe 7 cartas e encontra a melhor mão de 5.
  ResultadoMao avaliar(List<Carta> todasAs7Cartas) {
    if (todasAs7Cartas.length < 5) {
      throw ArgumentError('A avaliação precisa de pelo menos 5 cartas.');
    }

    ResultadoMao? melhorMaoEncontrada;

    // Gerar todas as combinações de 5 cartas
    final combinacoes = _gerarCombinacoes(todasAs7Cartas, 5);

    for (final maoDe5 in combinacoes) {
      final resultadoAtual = _avaliarMaoDe5(maoDe5);

      if (melhorMaoEncontrada == null ||
          compararMaos(resultadoAtual, melhorMaoEncontrada) > 0) {
        melhorMaoEncontrada = resultadoAtual;
      }
    }

    return melhorMaoEncontrada!;
  }

  /// Gera todas as combinações possíveis de um determinado tamanho a partir de uma lista.
  List<List<T>> _gerarCombinacoes<T>(List<T> lista, int tamanho) {
    List<List<T>> resultado = [];
    void backtrack(List<T> combinacaoAtual, int inicio) {
      if (combinacaoAtual.length == tamanho) {
        resultado.add(List.from(combinacaoAtual));
        return;
      }
      for (int i = inicio; i < lista.length; i++) {
        combinacaoAtual.add(lista[i]);
        backtrack(combinacaoAtual, i + 1);
        combinacaoAtual.removeLast();
      }
    }

    backtrack([], 0);
    return resultado;
  }

  /// Compara duas mãos e retorna: > 0 se maoA é melhor, < 0 se maoB é melhor, 0 se empate.
  static int compararMaos(ResultadoMao maoA, ResultadoMao maoB) {
    if (maoA.forca.index > maoB.forca.index) return 1;
    if (maoA.forca.index < maoB.forca.index) return -1;

    for (int i = 0; i < maoA.valoresRelevantes.length; i++) {
      if (i >= maoB.valoresRelevantes.length) return 1;
      if (maoA.valoresRelevantes[i].index > maoB.valoresRelevantes[i].index)
        return 1;
      if (maoA.valoresRelevantes[i].index < maoB.valoresRelevantes[i].index)
        return -1;
    }

    if (maoB.valoresRelevantes.length > maoA.valoresRelevantes.length)
      return -1;

    return 0; // Empate
  }

  /// Conta quantas vezes cada valor de carta aparece.
  Map<Valor, int> _contarValores(List<Carta> mao) =>
      mao.fold<Map<Valor, int>>({}, (mapa, carta) {
        mapa[carta.valor] = (mapa[carta.valor] ?? 0) + 1;
        return mapa;
      });

  /// Conta quantas vezes cada naipe aparece.
  Map<Naipe, int> _contarNaipes(List<Carta> mao) =>
      mao.fold<Map<Naipe, int>>({}, (mapa, carta) {
        mapa[carta.naipe] = (mapa[carta.naipe] ?? 0) + 1;
        return mapa;
      });

  /// Verifica se uma mão de 5 cartas ORDENADA é uma sequência.
  bool _verificarStraight(List<Carta> maoDe5Ordenada) {
    // Caso especial: A, 5, 4, 3, 2 (a "roda")
    bool ehRoda =
        maoDe5Ordenada.map((c) => c.valor).toList().toString() ==
        [
          Valor.as,
          Valor.cinco,
          Valor.quatro,
          Valor.tres,
          Valor.dois,
        ].toString();
    if (ehRoda) return true;

    // Caso normal
    for (int i = 0; i < maoDe5Ordenada.length - 1; i++) {
      if (maoDe5Ordenada[i].valor.index !=
          maoDe5Ordenada[i + 1].valor.index + 1) {
        return false;
      }
    }
    return true;
  }

  /// Avalia uma mão específica de 5 cartas.
  ResultadoMao _avaliarMaoDe5(List<Carta> maoDe5) {
    if (maoDe5.length != 5)
      throw ArgumentError('A avaliação só pode ser feita com 5 cartas.');

    maoDe5.sort((a, b) => b.valor.index.compareTo(a.valor.index));

    final contagemValores = _contarValores(maoDe5);
    final contagemNaipes = _contarNaipes(maoDe5);
    final ehFlush = contagemNaipes.containsValue(5);
    final ehStraight = _verificarStraight(maoDe5);

    // 1. Royal/Straight Flush
    if (ehStraight && ehFlush) {
      return ResultadoMao(
        forca: maoDe5.first.valor == Valor.as
            ? ForcaDaMao.royalFlush
            : ForcaDaMao.straightFlush,
        valoresRelevantes: [maoDe5.first.valor],
      );
    }

    // 2. Quadra
    if (contagemValores.containsValue(4)) {
      final valorQuadra = contagemValores.entries
          .firstWhere((e) => e.value == 4)
          .key;
      final kicker = contagemValores.entries
          .firstWhere((e) => e.value == 1)
          .key;
      return ResultadoMao(
        forca: ForcaDaMao.quadra,
        valoresRelevantes: [valorQuadra, kicker],
      );
    }

    // 3. Full House
    if (contagemValores.containsValue(3) && contagemValores.containsValue(2)) {
      final valorTrinca = contagemValores.entries
          .firstWhere((e) => e.value == 3)
          .key;
      final valorPar = contagemValores.entries
          .firstWhere((e) => e.value == 2)
          .key;
      return ResultadoMao(
        forca: ForcaDaMao.fullHouse,
        valoresRelevantes: [valorTrinca, valorPar],
      );
    }

    // 4. Flush
    if (ehFlush) {
      return ResultadoMao(
        forca: ForcaDaMao.flush,
        valoresRelevantes: maoDe5.map((c) => c.valor).toList(),
      );
    }

    // 5. Straight
    if (ehStraight) {
      // Se for a "roda" (A-5), a carta mais alta é o 5.
      final valorMaisAlto =
          maoDe5[0].valor == Valor.as && maoDe5[1].valor == Valor.cinco
          ? Valor.cinco
          : maoDe5[0].valor;
      return ResultadoMao(
        forca: ForcaDaMao.straight,
        valoresRelevantes: [valorMaisAlto],
      );
    }

    // 6. Trinca
    if (contagemValores.containsValue(3)) {
      final valorTrinca = contagemValores.entries
          .firstWhere((e) => e.value == 3)
          .key;
      final kickers = contagemValores.entries
          .where((e) => e.value == 1)
          .map((e) => e.key)
          .toList();
      kickers.sort((a, b) => b.index.compareTo(a.index));
      return ResultadoMao(
        forca: ForcaDaMao.trinca,
        valoresRelevantes: [valorTrinca, ...kickers],
      );
    }

    // 7. Dois Pares
    if (contagemValores.values.where((v) => v == 2).length == 2) {
      final pares = contagemValores.entries
          .where((e) => e.value == 2)
          .map((e) => e.key)
          .toList();
      pares.sort(
        (a, b) => b.index.compareTo(a.index),
      ); // Ordena para ter o par maior primeiro
      final kicker = contagemValores.entries
          .firstWhere((e) => e.value == 1)
          .key;
      return ResultadoMao(
        forca: ForcaDaMao.doisPares,
        valoresRelevantes: [...pares, kicker],
      );
    }

    // 8. Um Par
    if (contagemValores.containsValue(2)) {
      final valorPar = contagemValores.entries
          .firstWhere((e) => e.value == 2)
          .key;
      final kickers = contagemValores.entries
          .where((e) => e.value == 1)
          .map((e) => e.key)
          .toList();
      kickers.sort((a, b) => b.index.compareTo(a.index));
      return ResultadoMao(
        forca: ForcaDaMao.umPar,
        valoresRelevantes: [valorPar, ...kickers],
      );
    }

    // 9. High Card
    return ResultadoMao(
      forca: ForcaDaMao.highCard,
      valoresRelevantes: maoDe5.map((c) => c.valor).toList(),
    );
  }
}
