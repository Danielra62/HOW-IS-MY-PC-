import 'carta.dart';

enum EstadoComponente { sano, danado, blindado, destruido }

class EstadoPieza {
  EstadoComponente estado;
  int fallas;
  int reparaciones;

  EstadoPieza({
    this.estado = EstadoComponente.sano,
    this.fallas = 0,
    this.reparaciones = 0,
  });

  factory EstadoPieza.fromJson(Map<String, dynamic> json) {
    return EstadoPieza(
      estado: EstadoComponente.values.firstWhere((e) => e.name == json['estado']),
      fallas: json['fallas'] ?? 0,
      reparaciones: json['reparaciones'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'estado': estado.name,
    'fallas': fallas,
    'reparaciones': reparaciones,
  };
}

class Jugador {
  final String id;
  final String nombre;
  final bool esHost;
  bool bloqueado; // Para el efecto "Cuelgue"
  List<Carta> mano;
  Map<String, EstadoPieza?> componentes; // cpu, gpu, ram, ssd, motherboard

  Jugador({
    required this.id,
    required this.nombre,
    this.esHost = false,
    this.bloqueado = false,
    this.mano = const [],
    required this.componentes,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) {
    var componentesMap = json['componentes'] as Map<String, dynamic>;
    return Jugador(
      id: json['id'],
      nombre: json['nombre'],
      esHost: json['es_host'] ?? false,
      bloqueado: json['bloqueado'] ?? false,
      mano: (json['mano'] as List).map((c) => Carta.fromJson(c)).toList(),
      componentes: componentesMap.map(
        (key, value) => MapEntry(key, value == null ? null : EstadoPieza.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'es_host': esHost,
    'bloqueado': bloqueado,
    'mano': mano.map((c) => c.toJson()).toList(),
    'componentes': componentes.map((key, value) => MapEntry(key, value?.toJson())),
  };
}
