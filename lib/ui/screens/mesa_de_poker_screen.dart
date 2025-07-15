// lib/ui/screens/mesa_de_poker_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../logic/avaliador_de_maos.dart';
import '../../logic/calculadora_probabilidade.dart';
import '../../models/baralho.dart';
import '../../models/carta.dart';
import '../widgets/carta_widget.dart';

class MesaDePokerScreen extends StatefulWidget {
  const MesaDePokerScreen({Key? key}) : super(key: key);

  @override
  _MesaDePokerScreenState createState() => _MesaDePokerScreenState();
}

class _MesaDePokerScreenState extends State<MesaDePokerScreen> {
  // Estado do Jogo
  Baralho _baralho = Baralho();
  List<Carta> _maoJogador = [];
  List<Carta> _cartasComunitarias = [];
  double _probabilidadeDeVitoria = 0.0;
  bool _calculando = false;

  // Variáveis para gerenciar a partida
  int _fichasJogador = 1000;
  int _fichasOponente = 1000;
  int _pote = 0;
  final int _valorSmallBlind = 10;
  final int _valorBigBlind = 20;
  bool _rodadaEmAndamento = false;

  double _valorAposta = 20.0;

  @override
  void initState() {
    super.initState();
    _iniciarNovaPartida();
  }

  void _iniciarNovaPartida() {
    setState(() {
      _fichasJogador = 1000;
      _fichasOponente = 1000;
      _rodadaEmAndamento = false;
      _limparMesa();
    });
  }

  void _limparMesa() {
    setState(() {
      _cartasComunitarias = [];
      _maoJogador = [];
      _pote = 0;
      _probabilidadeDeVitoria = 0.0;
    });
  }

  void _iniciarNovaRodada() {
    if (_fichasJogador <= _valorBigBlind || _fichasOponente <= _valorBigBlind) {
      _mostrarDialogoDeFimDePartida();
      return;
    }
    _limparMesa();
    setState(() {
      _rodadaEmAndamento = true;
      _fichasJogador -= _valorSmallBlind;
      _fichasOponente -= _valorBigBlind;
      _pote = _valorSmallBlind + _valorBigBlind;
      _valorAposta = _valorBigBlind.toDouble();
      _baralho = Baralho();
      _baralho.embaralhar();
      _maoJogador = [_baralho.pegarCarta()!, _baralho.pegarCarta()!];
    });
  }

  void _calcularProbabilidade() async {
    setState(() => _calculando = true);
    final params = ParametrosCalculo(
      minhaMao: _maoJogador,
      cartasComunitarias: _cartasComunitarias,
      numeroDeOponentes: 1,
    );
    final double probabilidade = await compute(
      calcularProbabilidadeEmBackground,
      params,
    );
    if (mounted)
      setState(() {
        _probabilidadeDeVitoria = probabilidade;
        _calculando = false;
      });
  }

  void _jogadorDesiste() {
    setState(() => _fichasOponente += _pote);
    _mostrarDialogoDeFimDeJogo(
      'Você Desistiu!',
      'O oponente levou o pote de $_pote fichas.',
      'assets/images/mascote_perdendo.png',
    );
  }

  // --- FUNÇÃO CORRIGIDA E UNIFICADA ---
  void _realizarAposta() {
    final int aposta = _valorAposta.round();

    // Verifica se os jogadores têm fichas para a aposta
    if (_fichasJogador < aposta || _fichasOponente < aposta) {
      // Poderíamos mostrar um aviso, mas por enquanto só impedimos a ação
      return;
    }

    // Todas as atualizações de estado acontecem em um único setState
    setState(() {
      // 1. Fichas e pote são atualizados
      _fichasJogador -= aposta;
      _fichasOponente -= aposta; // IA simples: oponente sempre paga
      _pote += (aposta * 2);

      // 2. A lógica para virar as cartas agora está aqui dentro
      if (_cartasComunitarias.isEmpty) {
        // Virar o Flop
        _baralho.pegarCarta();
        _cartasComunitarias.addAll([
          _baralho.pegarCarta()!,
          _baralho.pegarCarta()!,
          _baralho.pegarCarta()!,
        ]);
      } else if (_cartasComunitarias.length == 3) {
        // Virar o Turn
        _baralho.pegarCarta();
        _cartasComunitarias.add(_baralho.pegarCarta()!);
      } else if (_cartasComunitarias.length == 4) {
        // Virar o River
        _baralho.pegarCarta();
        _cartasComunitarias.add(_baralho.pegarCarta()!);
      }

      // 3. Reseta o valor da aposta para a próxima rodada de apostas
      _valorAposta = _valorBigBlind.toDouble();
    });

    // 4. Após a atualização do estado, decidimos o que fazer a seguir
    if (_cartasComunitarias.length == 5) {
      // Se o River foi virado, o jogo acaba
      setState(() => _calculando = false);
      _determinarResultadoFinal();
    } else {
      // Se não, calculamos a probabilidade para a próxima etapa
      _calcularProbabilidade();
    }
  }

  // A função _avancarRodada FOI REMOVIDA

  void _determinarResultadoFinal() {
    final baralhoFinal = Baralho();
    final cartasConhecidas = [..._maoJogador, ..._cartasComunitarias];
    baralhoFinal.cartas.removeWhere(
      (c) => cartasConhecidas.any(
        (c2) => c.valor == c2.valor && c.naipe == c2.naipe,
      ),
    );
    baralhoFinal.embaralhar();
    final maoOponente = [
      baralhoFinal.pegarCarta()!,
      baralhoFinal.pegarCarta()!,
    ];
    final avaliador = AvaliadorDeMaos();
    final minhaMelhorMao = avaliador.avaliar([
      ..._maoJogador,
      ..._cartasComunitarias,
    ]);
    final melhorMaoOponente = avaliador.avaliar([
      ...maoOponente,
      ..._cartasComunitarias,
    ]);

    final resultado = AvaliadorDeMaos.compararMaos(
      minhaMelhorMao,
      melhorMaoOponente,
    );

    String titulo;
    String mensagem;
    String imagePath;
    int fichasJogadorDelta = 0;
    int fichasOponenteDelta = 0;

    if (resultado > 0) {
      titulo = 'Você Venceu a Rodada! 🎉';
      mensagem = 'Você ganhou $_pote fichas!';
      imagePath = 'assets/images/mascote_ganhando.png';
      fichasJogadorDelta = _pote;
    } else if (resultado < 0) {
      titulo = 'Você Perdeu a Rodada 😥';
      mensagem = 'O oponente ganhou $_pote fichas.';
      imagePath = 'assets/images/mascote_perdendo.png';
      fichasOponenteDelta = _pote;
    } else {
      titulo = 'Empate!';
      mensagem = 'O pote de $_pote fichas foi dividido.';
      imagePath = 'assets/images/mascote_ganhando.png';
      final metadeDoPote = (_pote / 2).round();
      fichasJogadorDelta = metadeDoPote;
      fichasOponenteDelta = _pote - metadeDoPote;
    }

    // Primeiro, atualizamos o estado das fichas na tela
    setState(() {
      _fichasJogador += fichasJogadorDelta;
      _fichasOponente += fichasOponenteDelta;
    });

    // --- LÓGICA DE CORREÇÃO AQUI ---
    // Após a distribuição das fichas, verificamos se o jogo acabou.
    // Usamos um valor menor que o Big Blind como condição de derrota.
    if (_fichasJogador < _valorBigBlind || _fichasOponente < _valorBigBlind) {
      // Usamos um pequeno atraso para que o jogador veja a atualização
      // final das fichas antes do diálogo de fim de partida aparecer.
      Future.delayed(const Duration(milliseconds: 1500), () {
        _mostrarDialogoDeFimDePartida();
      });
    } else {
      // Se o jogo NÃO acabou, mostramos o diálogo normal de fim de rodada.
      _mostrarDialogoDeFimDeJogo(titulo, mensagem, imagePath);
    }
  }

  Future<void> _mostrarDialogoDeFimDeJogo(
    String titulo,
    String mensagem,
    String imagePath,
  ) async {
    setState(() => _rodadaEmAndamento = false);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(imagePath, height: 180, fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Próxima Rodada',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _iniciarNovaRodada();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoDeFimDePartida() async {
    final bool jogadorVenceu = _fichasJogador > _fichasOponente;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(jogadorVenceu ? 'VOCÊ VENCEU A PARTIDA!' : 'Fim de Jogo'),
          content: Text(jogadorVenceu ? 'Parabéns!' : 'Você ficou sem fichas.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Jogar Nova Partida'),
              onPressed: () {
                Navigator.of(context).pop();
                _iniciarNovaPartida();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPainelDeAcoes() {
    // Garante que o slider não quebre se as fichas forem menores que o blind
    final double maxAposta =
        _fichasJogador.toDouble() > _valorBigBlind.toDouble()
        ? _fichasJogador.toDouble()
        : _valorBigBlind.toDouble();

    return Column(
      children: [
        Text(
          "Valor da Aposta: ${_valorAposta.round()}",
          style: TextStyle(fontSize: 16),
        ),
        Slider(
          value: _valorAposta,
          min: _valorBigBlind.toDouble(),
          max: maxAposta,
          divisions: (_fichasJogador > _valorBigBlind)
              ? (_fichasJogador - _valorBigBlind) ~/ 10
              : null,
          label: _valorAposta.round().toString(),
          onChanged: (double value) {
            setState(() {
              // Garante que o valor da aposta não ultrapasse as fichas do jogador
              if (value <= _fichasJogador) {
                _valorAposta = value;
              } else {
                _valorAposta = _fichasJogador.toDouble();
              }
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _jogadorDesiste,
              child: const Text('Desistir'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            ),
            ElevatedButton(
              onPressed: _realizarAposta,
              child: Text(
                _cartasComunitarias.isEmpty ? 'Apostar e Ver Flop' : 'Apostar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partida de Poker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _iniciarNovaPartida,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    'Oponente: $_fichasOponente fichas',
                    style: TextStyle(fontSize: 18, color: Colors.red[300]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pote: $_pote',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Cartas da Mesa (Board)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CartaWidget(
                          carta: index < _cartasComunitarias.length
                              ? _cartasComunitarias[index]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _calculando
                        ? const CircularProgressIndicator()
                        : Text(
                            _rodadaEmAndamento && _cartasComunitarias.isNotEmpty
                                ? '${_probabilidadeDeVitoria.toStringAsFixed(2)}% de chance de ganhar'
                                : '',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                  ),
                  Text(
                    'Sua Mão',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CartaWidget(
                          carta: _maoJogador.isNotEmpty ? _maoJogador[0] : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CartaWidget(
                          carta: _maoJogador.isNotEmpty ? _maoJogador[1] : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    'Você: $_fichasJogador fichas',
                    style: TextStyle(fontSize: 18, color: Colors.green[300]),
                  ),
                  const SizedBox(height: 16),
                  if (!_rodadaEmAndamento)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Iniciar Rodada',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: _iniciarNovaRodada,
                    )
                  else
                    _buildPainelDeAcoes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
