import 'dart:convert';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/jugador.dart';
import 'dart:io';

class GameServer {
  final List<WebSocketChannel> _clients = [];
  final List<Jugador> _jugadores = [];
  HttpServer? _server;

  Future<void> startServer() async {
    var handler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      
      webSocket.stream.listen((message) {
        final data = jsonDecode(message);
        _handleMessage(webSocket, data);
      }, onDone: () {
        _clients.remove(webSocket);
        // Aquí podrías agregar lógica para cuando un jugador se desconecta
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
        final nuevoJugador = Jugador(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nombre: data['nombre'],
          esHost: _jugadores.isEmpty,
          componentes: {
            'cpu': null, 'gpu': null, 'ram': null, 'ssd': null, 'motherboard': null
          },
        );
        _jugadores.add(nuevoJugador);
        _broadcastState();
        break;
    }
  }

  void _broadcastState() {
    final state = jsonEncode({
      'type': 'update',
      'jugadores': _jugadores.map((j) => j.toJson()).toList(),
    });
    for (var client in _clients) {
      try {
        client.sink.add(state);
      } catch (e) {
        // Ignorar errores de envío
      }
    }
  }
}
