// lib/logic/calculadora_probabilidade.dart

import '../models/carta.dart';
import '../models/baralho.dart';
import 'avaliador_de_maos.dart';

class CalculadoraDeProbabilidade {
  final int numeroDeSimulacoes;
  final AvaliadorDeMaos _avaliador = AvaliadorDeMaos();

  CalculadoraDeProbabilidade({this.numeroDeSimulacoes = 10000});

  double calcular({
    required List<Carta> minhaMao,
    required List<Carta> cartasComunitarias,
    required int numeroDeOponentes,
  }) {
    int vitorias = 0;
    int empates = 0;
    List<Carta> cartasConhecidas = [...minhaMao, ...cartasComunitarias];

    for (int i = 0; i < numeroDeSimulacoes; i++) {
      Baralho baralhoSimulacao = Baralho();
      baralhoSimulacao.cartas.removeWhere(
        (carta) => cartasConhecidas.any(
          (c) => c.valor == carta.valor && c.naipe == carta.naipe,
        ),
      );
      baralhoSimulacao.embaralhar();

      List<Carta> cartasComunitariasSimuladas = List.from(cartasComunitarias);
      while (cartasComunitariasSimuladas.length < 5) {
        cartasComunitariasSimuladas.add(baralhoSimulacao.pegarCarta()!);
      }

      List<List<Carta>> maosOponentes = [];
      for (int j = 0; j < numeroDeOponentes; j++) {
        maosOponentes.add([
          baralhoSimulacao.pegarCarta()!,
          baralhoSimulacao.pegarCarta()!,
        ]);
      }

      ResultadoMao minhaMelhorMao = _avaliador.avaliar([
        ...minhaMao,
        ...cartasComunitariasSimuladas,
      ]);

      // A LINHA "bool euPerdiEstaRodada = false;" FOI REMOVIDA DAQUI.

      List<ResultadoMao> melhoresMaosOponentes = [];
      for (var maoOponente in maosOponentes) {
        melhoresMaosOponentes.add(
          _avaliador.avaliar([...maoOponente, ...cartasComunitariasSimuladas]),
        );
      }

      // Se não houver oponentes, a vitória é 100% (caso raro, mas bom tratar)
      if (melhoresMaosOponentes.isEmpty) {
        vitorias++;
        continue; // Pula para a próxima simulação
      }

      ResultadoMao melhorMaoAdversaria = melhoresMaosOponentes.reduce((
        atual,
        proximo,
      ) {
        return AvaliadorDeMaos.compararMaos(atual, proximo) >= 0
            ? atual
            : proximo;
      });

      final resultadoDaComparacao = AvaliadorDeMaos.compararMaos(
        minhaMelhorMao,
        melhorMaoAdversaria,
      );

      if (resultadoDaComparacao > 0) {
        vitorias++;
      } else if (resultadoDaComparacao == 0) {
        empates++;
      }
    }

    if (numeroDeSimulacoes == 0) return 0.0;

    return ((vitorias + (empates / 2)) / numeroDeSimulacoes) * 100.0;
  }
}

class ParametrosCalculo {
  final List<Carta> minhaMao;
  final List<Carta> cartasComunitarias;
  final int numeroDeOponentes;

  ParametrosCalculo({
    required this.minhaMao,
    required this.cartasComunitarias,
    required this.numeroDeOponentes,
  });
}

// Esta é a função que será executada no Isolate
double calcularProbabilidadeEmBackground(ParametrosCalculo params) {
  // Dentro do isolate, criamos uma nova instância da calculadora
  final calculadora = CalculadoraDeProbabilidade();
  return calculadora.calcular(
    minhaMao: params.minhaMao,
    cartasComunitarias: params.cartasComunitarias,
    numeroDeOponentes: params.numeroDeOponentes,
  );
}
