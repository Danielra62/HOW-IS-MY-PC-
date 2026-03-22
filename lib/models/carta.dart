enum TipoCarta { componente, falla, reparacion, especial }

class Carta {
  final String id;
  final String nombre;
  final TipoCarta tipo;
  final String? subtipo; // cpu, gpu, ram, ssd, motherboard

  Carta({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.subtipo,
  });

  factory Carta.fromJson(Map<String, dynamic> json) {
    return Carta(
      id: json['id'],
      nombre: json['nombre'],
      tipo: TipoCarta.values.firstWhere((e) => e.name == json['tipo']),
      subtipo: json['subtipo'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'tipo': tipo.name,
    'subtipo': subtipo,
  };
}
