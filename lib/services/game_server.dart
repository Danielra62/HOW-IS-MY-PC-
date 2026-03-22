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

    // Usamos shared: true para evitar el error de puerto ocupado al reiniciar rápido
    _server = await shelf_io.serve(handler, '0.0.0.0', 8080, shared: true);
    print('Servidor iniciado en ${_server!.address.address}:${_server!.port}');
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _partidaIniciada = false;
    print('Servidor detenido');
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

      case 'add_dummies':
        if (_partidaIniciada) return;
        for (int i = 1; i <= 2; i++) {
          _jugadores.add(Jugador(
            id: 'bot_$i',
            nombre: 'Bot Virtual $i',
            componentes: {'cpu': null, 'gpu': null, 'ram': null, 'ssd': null, 'motherboard': null},
          ));
        }
        _broadcastState('update');
        break;

      case 'start_game':
        if (_jugadores.length >= 2) _iniciarPartida();
        break;

      case 'play_card':
        _procesarJugada(data['playerId'], data['cartaId'], data['targetPlayerId'], data['targetSubtipo']);
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

  void _procesarJugada(String playerId, String cartaId, String? targetPlayerId, String? targetSubtipo) {
    if (_jugadores[_turnoIndex].id != playerId) return; 
    
    final jugador = _jugadores.firstWhere((j) => j.id == playerId);
    final carta = jugador.mano.firstWhere((c) => c.id == cartaId);
    bool jugadaValida = false;

    if (carta.tipo == TipoCarta.componente) {
      if (jugador.componentes[carta.subtipo] == null) {
        jugador.componentes[carta.subtipo!] = EstadoPieza(estado: EstadoComponente.sano);
        jugadaValida = true;
      }
    } 
    else if (carta.tipo == TipoCarta.falla && targetPlayerId != null) {
      final rival = _jugadores.firstWhere((j) => j.id == targetPlayerId);
      final piezaRival = rival.componentes[carta.subtipo];
      if (piezaRival != null && piezaRival.estado != EstadoComponente.blindado) {
        if (piezaRival.estado == EstadoComponente.sano) {
          piezaRival.estado = EstadoComponente.danado;
          piezaRival.fallas = 1;
          jugadaValida = true;
        } else if (piezaRival.estado == EstadoComponente.danado) {
          rival.componentes[carta.subtipo!] = null;
          jugadaValida = true;
        }
      }
    }
    else if (carta.tipo == TipoCarta.reparacion) {
      final piezaPropia = jugador.componentes[carta.subtipo];
      if (piezaPropia != null) {
        if (piezaPropia.estado == EstadoComponente.danado) {
          piezaPropia.estado = EstadoComponente.sano;
          piezaPropia.fallas = 0;
          jugadaValida = true;
        } else if (piezaPropia.estado == EstadoComponente.sano) {
          piezaPropia.estado = EstadoComponente.blindado;
          piezaPropia.reparaciones = 2;
          jugadaValida = true;
        }
      }
    }
    else if (carta.tipo == TipoCarta.especial) {
      jugadaValida = _ejecutarEspecial(jugador, carta, targetPlayerId, targetSubtipo);
    }

    if (jugadaValida) {
      _finalizarTurno(jugador, carta);
      _verificarGanador();
    }
  }

  bool _ejecutarEspecial(Jugador jugador, Carta carta, String? targetPlayerId, String? targetSubtipo) {
    String slug = carta.subtipo?.toLowerCase() ?? "";
    if (slug.contains('malware')) {
      for (var rival in _jugadores) {
        if (rival.id == jugador.id) continue;
        for (var pieza in rival.componentes.values) {
          if (pieza != null && pieza.estado == EstadoComponente.sano) {
            pieza.estado = EstadoComponente.danado;
            pieza.fallas = 1;
            break; 
          }
        }
      }
      return true;
    }
    if (slug.contains('robo') && targetPlayerId != null && targetSubtipo != null) {
      final rival = _jugadores.firstWhere((j) => j.id == targetPlayerId);
      final piezaRival = rival.componentes[targetSubtipo];
      if (piezaRival != null && piezaRival.estado != EstadoComponente.blindado && jugador.componentes[targetSubtipo] == null) {
        jugador.componentes[targetSubtipo] = piezaRival;
        rival.componentes[targetSubtipo] = null;
        return true;
      }
    }
    if (slug.contains('reinicio')) {
      for (var j in _jugadores) {
        _descarte.addAll(j.mano);
        j.mano = [];
        for (int i = 0; i < 3; i++) {
          if (_mazo.isNotEmpty) j.mano.add(_mazo.removeAt(0));
        }
      }
      return true;
    }
    if (slug.contains('hackeo') && targetPlayerId != null && targetSubtipo != null) {
      final rival = _jugadores.firstWhere((j) => j.id == targetPlayerId);
      final piezaRival = rival.componentes[targetSubtipo];
      if (piezaRival != null && piezaRival.estado == EstadoComponente.blindado) {
        rival.componentes[targetSubtipo] = null;
        return true;
      }
    }
    if (slug.contains('cuelgue') && targetPlayerId != null) {
      final rival = _jugadores.firstWhere((j) => j.id == targetPlayerId);
      rival.bloqueado = true;
      return true;
    }
    if (slug.contains('intercambio') && targetPlayerId != null) {
      final rival = _jugadores.firstWhere((j) => j.id == targetPlayerId);
      List<Carta> tempMano = List.from(jugador.mano);
      tempMano.remove(carta);
      jugador.mano = List.from(rival.mano);
      rival.mano = tempMano;
      return true;
    }
    return false;
  }

  void _verificarGanador() {
    for (var j in _jugadores) {
      int sanos = j.componentes.values.where((p) => p != null && (p.estado == EstadoComponente.sano || p.estado == EstadoComponente.blindado)).length;
      if (sanos >= 4) {
        _broadcastState('victory', winnerName: j.nombre);
        _partidaIniciada = false;
      }
    }
  }

  void _procesarDescarte(String playerId, String cartaId) {
    final jugador = _jugadores.firstWhere((j) => j.id == playerId);
    if (_jugadores[_turnoIndex].id != playerId) return;
    final carta = jugador.mano.firstWhere((c) => c.id == cartaId);
    _finalizarTurno(jugador, carta);
  }

  void _finalizarTurno(Jugador jugador, Carta cartaUsada) {
    if (jugador.mano.contains(cartaUsada)) {
      jugador.mano.remove(cartaUsada);
      _descarte.add(cartaUsada);
    }
    if (_mazo.isEmpty && _descarte.isNotEmpty) {
      _mazo = List.from(_descarte)..shuffle();
      _descarte.clear();
    }
    while (jugador.mano.length < 3 && _mazo.isNotEmpty) {
      jugador.mano.add(_mazo.removeAt(0));
    }
    do {
      _turnoIndex = (_turnoIndex + 1) % _jugadores.length;
      if (_jugadores[_turnoIndex].bloqueado) {
        _jugadores[_turnoIndex].bloqueado = false;
        _broadcastState('update');
      } else {
        break;
      }
    } while (true);
    _broadcastState('update');
  }

  void _broadcastState(String type, {String? winnerName}) {
    final state = jsonEncode({
      'type': type,
      'winnerName': winnerName,
      'turnoActualId': _jugadores.isNotEmpty ? _jugadores[_turnoIndex].id : null,
      'jugadores': _jugadores.map((j) => j.toJson()).toList(),
    });
    for (var client in _clients) {
      try { client.sink.add(state); } catch (e) {}
    }
  }
}
