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
  HttpServer? _server;
  bool _partidaIniciada = false;
  int _turnoIndex = 0; // Índice del jugador que tiene el turno

  Future<void> startServer() async {
    var handler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      
      webSocket.stream.listen((message) {
        final data = jsonDecode(message);
        _handleMessage(webSocket, data);
      }, onDone: () {
        int index = _clients.indexOf(webSocket);
        if (index != -1) {
          _clients.removeAt(index);
          // Opcional: eliminar jugador de la lista si no ha empezado la partida
        }
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
        
        // Enviar ID privado al que acaba de entrar
        client.sink.add(jsonEncode({
          'type': 'welcome',
          'yourId': myId,
        }));

        _broadcastState('update');
        break;

      case 'start_game':
        if (_jugadores.length >= 2) {
          _iniciarPartida();
        }
        break;
    }
  }

  void _iniciarPartida() {
    _partidaIniciada = true;
    _mazo = DeckService.generarMazo();
    _turnoIndex = 0; // Empieza el primero que se conectó (el Host)

    for (var jugador in _jugadores) {
      jugador.mano = [];
      for (int i = 0; i < 3; i++) {
        if (_mazo.isNotEmpty) {
          jugador.mano.add(_mazo.removeAt(0));
        }
      }
    }

    _broadcastState('game_started');
  }

  void _broadcastState(String type) {
    final state = jsonEncode({
      'type': type,
      'turnoActualId': _jugadores.isNotEmpty ? _jugadores[_turnoIndex].id : null,
      'jugadores': _jugadores.map((j) => j.toJson()).toList(),
    });
    for (var client in _clients) {
      try {
        client.sink.add(state);
      } catch (e) {}
    }
  }
}
