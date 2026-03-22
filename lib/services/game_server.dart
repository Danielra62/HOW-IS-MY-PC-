import 'dart:convert';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/jugador.dart';
import '../models/carta.dart';
import 'deck_service.dart';
import 'dart:io';

class GameServer {
  final List<WebSocketChannel> _clients = [];
  final List<Jugador> _jugadores = [];
  List<Carta> _mazo = [];
  List<Carta> _descarte = [];
  HttpServer? _server;
  bool _partidaIniciada = false;
  int _turnoIndex = 0;

  Future<void> startServer() async {
    var handler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      
      webSocket.stream.listen((message) {
        final data = jsonDecode(message);
        _handleMessage(webSocket, data);
      }, onDone: () {
        _clients.remove(webSocket);
      });
    });

    _server = await shelf_io.serve(handler, '0.0.0.0', 8080);
    print('Servidor iniciado en ${_server!.address.address}:${_server!.port}');
  }

  void stopServer() {
    _server?.close();
  }

  void _handleMessage(WebSocketChannel client, Map<String, dynamic> data) {
    switch (data['type']) {
      case 'join':
        if (_partidaIniciada) return;
        String myId = 'player_${_jugadores.length}_${DateTime.now().millisecondsSinceEpoch}';
        final nuevoJugador = Jugador(
          id: myId,
          nombre: data['nombre'],
          esHost: _jugadores.isEmpty,
          componentes: {
            'cpu': null, 'gpu': null, 'ram': null, 'ssd': null, 'motherboard': null
          },
        );
        _jugadores.add(nuevoJugador);
        client.sink.add(jsonEncode({'type': 'welcome', 'yourId': myId}));
        _broadcastState('update');
        break;

      case 'start_game':
        if (_jugadores.length >= 2) _iniciarPartida();
        break;

      case 'play_card':
        _procesarJugada(data['playerId'], data['cartaId'], data['targetPlayerId']);
        break;

      case 'discard':
        _procesarDescarte(data['playerId'], data['cartaId']);
        break;
    }
  }

  void _iniciarPartida() {
    _partidaIniciada = true;
    _mazo = DeckService.generarMazo();
    _turnoIndex = 0;
    for (var jugador in _jugadores) {
      jugador.mano = [];
      for (int i = 0; i < 3; i++) {
        if (_mazo.isNotEmpty) jugador.mano.add(_mazo.removeAt(0));
      }
    }
    _broadcastState('game_started');
  }

  void _procesarJugada(String playerId, String cartaId, String? targetPlayerId) {
    final jugador = _jugadores.firstWhere((j) => j.id == playerId);
    if (_jugadores[_turnoIndex].id != playerId) return; // No es su turno

    final carta = jugador.mano.firstWhere((c) => c.id == cartaId);
    bool jugadaValida = false;

    if (carta.tipo == TipoCarta.componente) {
      // Regla: Solo un componente de cada tipo y que no esté ya ocupado
      if (jugador.componentes[carta.subtipo] == null) {
        jugador.componentes[carta.subtipo!] = EstadoPieza(estado: EstadoComponente.sano);
        jugadaValida = true;
      }
    }

    if (jugadaValida) {
      _finalizarTurno(jugador, carta);
    }
  }

  void _procesarDescarte(String playerId, String cartaId) {
    final jugador = _jugadores.firstWhere((j) => j.id == playerId);
    if (_jugadores[_turnoIndex].id != playerId) return;

    final carta = jugador.mano.firstWhere((c) => c.id == cartaId);
    _finalizarTurno(jugador, carta);
  }

  void _finalizarTurno(Jugador jugador, Carta cartaUsada) {
    jugador.mano.remove(cartaUsada);
    _descarte.add(cartaUsada);

    // Robar nueva carta
    if (_mazo.isEmpty && _descarte.isNotEmpty) {
      _mazo = List.from(_descarte)..shuffle();
      _descarte.clear();
    }
    if (_mazo.isNotEmpty) {
      jugador.mano.add(_mazo.removeAt(0));
    }

    // Siguiente turno
    _turnoIndex = (_turnoIndex + 1) % _jugadores.length;
    _broadcastState('update');
  }

  void _broadcastState(String type) {
    final state = jsonEncode({
      'type': type,
      'turnoActualId': _jugadores.isNotEmpty ? _jugadores[_turnoIndex].id : null,
      'jugadores': _jugadores.map((j) => j.toJson()).toList(),
    });
    for (var client in _clients) {
      try { client.sink.add(state); } catch (e) {}
    }
  }
}
