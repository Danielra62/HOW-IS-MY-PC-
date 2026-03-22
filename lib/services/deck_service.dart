import '../models/carta.dart';
import 'dart:math';

class DeckService {
  static List<Carta> generarMazo() {
    List<Carta> mazo = [];
    int idCounter = 0;

    // Componentes (5 de cada uno, excepto la Placa Madre que suele ser menos)
    final componentes = {
      'cpu': '🧠 Procesador (CPU)',
      'gpu': '🎮 Tarjeta de Video (GPU)',
      'ram': '💾 Memoria RAM',
      'ssd': '💿 Disco Duro (SSD)',
      'motherboard': '🔌 Placa Madre (Comodín)',
    };

    componentes.forEach((subtipo, nombre) {
      int cantidad = (subtipo == 'motherboard') ? 4 : 5;
      for (int i = 0; i < cantidad; i++) {
        mazo.add(Carta(id: '${idCounter++}', nombre: nombre, tipo: TipoCarta.componente, subtipo: subtipo));
      }
    });

    // Fallas y Reparaciones (4 de cada una)
    final fallas = {
      'cpu': '🔥 Sobrecalentamiento',
      'gpu': '👾 Artefactos',
      'ram': '💧 Fuga de memoria',
      'ssd': '🔵 Pantallazo azul',
      'motherboard': '⚠️ BIOS corrupta',
    };

    final reparaciones = {
      'cpu': '🧊 Enfriador',
      'gpu': '🖥️ Actualizar drivers',
      'ram': '🧹 Limpiar memoria',
      'ssd': '💾 Formateo',
      'motherboard': '⚙️ Actualizar BIOS',
    };

    fallas.forEach((subtipo, nombre) {
      for (int i = 0; i < 4; i++) {
        mazo.add(Carta(id: '${idCounter++}', nombre: nombre, tipo: TipoCarta.falla, subtipo: subtipo));
      }
    });

    reparaciones.forEach((subtipo, nombre) {
      for (int i = 0; i < 4; i++) {
        mazo.add(Carta(id: '${idCounter++}', nombre: nombre, tipo: TipoCarta.reparacion, subtipo: subtipo));
      }
    });

    // Especiales
    final especiales = [
      '🦠 Malware', '🔄 Robo de datos', '🔃 Transferencia', '💣 Hackeo', 
      '⏸️ Cuelgue', '♻️ Reinicio', '🤝 Intercambio de archivos'
    ];

    for (var nombre in especiales) {
      for (int i = 0; i < 2; i++) {
        mazo.add(Carta(id: '${idCounter++}', nombre: nombre, tipo: TipoCarta.especial, subtipo: nombre.toLowerCase()));
      }
    }

    mazo.shuffle(Random());
    return mazo;
  }
}
