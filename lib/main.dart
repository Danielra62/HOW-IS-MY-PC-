import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/network_utils.dart';
import 'services/game_server.dart';
import 'services/game_client.dart';
import 'models/jugador.dart';

void main() {
  runApp(const MalwareGame());
}

class MalwareGame extends StatelessWidget {
  const MalwareGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malware Game',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Jugador ${DateTime.now().millisecond}");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🦠 MALWARE',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tu Nombre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _startHost(),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('CREAR PARTIDA (HOST)'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _joinGame(),
                style: OutlinedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('UNIRSE A PARTIDA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startHost() async {
    final ip = await NetworkUtils.getLocalIP();
    if (ip == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la IP local. Revisa tu conexión.')),
      );
      return;
    }

    final server = GameServer();
    await server.startServer();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(
          ip: ip,
          nombre: _nameController.text,
          isHost: true,
          server: server,
        ),
      ),
    );
  }

  void _joinGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinScreen(nombre: _nameController.text),
      ),
    );
  }
}

class JoinScreen extends StatefulWidget {
  final String nombre;
  const JoinScreen({super.key, required this.nombre});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _ipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'IP del Host',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanQR,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_ipController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LobbyScreen(
                        ip: _ipController.text,
                        nombre: widget.nombre,
                        isHost: false,
                      ),
                    ),
                  );
                }
              },
              child: const Text('CONECTAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    if (result != null) {
      setState(() => _ipController.text = result);
    }
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanea la IP del Host')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

class LobbyScreen extends StatefulWidget {
  final String ip;
  final String nombre;
  final bool isHost;
  final GameServer? server;

  const LobbyScreen({
    super.key,
    required this.ip,
    required this.nombre,
    required this.isHost,
    this.server,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final GameClient _client = GameClient();
  List<Jugador> _jugadores = [];

  @override
  void initState() {
    super.initState();
    _client.onMessageReceived = (data) {
      if (data['type'] == 'update') {
        setState(() {
          _jugadores = (data['jugadores'] as List)
              .map((j) => Jugador.fromJson(j))
              .toList();
        });
      }
    };
    _client.connect(widget.ip, widget.nombre);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby de Espera')),
      body: Center(
        child: Column(
          children: [
            if (widget.isHost) ...[
              const SizedBox(height: 20),
              const Text('Comparte este QR con tus amigos:',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              QrImageView(
                data: widget.ip,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 10),
              Text('IP: ${widget.ip}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(height: 40),
            ],
            const Text('Jugadores Conectados:', style: TextStyle(fontSize: 20)),
            Expanded(
              child: ListView.builder(
                itemCount: _jugadores.length,
                itemBuilder: (context, index) {
                  final j = _jugadores[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.greenAccent),
                    title: Text(j.nombre + (j.esHost ? " (HOST)" : "")),
                  );
                },
              ),
            ),
            if (widget.isHost)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton(
                  onPressed: _jugadores.length >= 2
                      ? () {
                          // TODO: Implementar cambio a pantalla de juego
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: const Text('INICIAR PARTIDA'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _client.disconnect();
    if (widget.isHost) widget.server?.stopServer();
    super.dispose();
  }
}
