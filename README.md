# 🦠 MALWARE — Juego de cartas digital

Malware es un juego de cartas digital multijugador para **2 a 6 jugadores**, inspirado en el popular juego de mesa "Virus!". La temática está basada en componentes de computadora y ciberseguridad.

## 🎯 Objetivo del juego
Ser el primero en completar un **equipo con 4 componentes sanos**. Los demás jugadores intentarán infectar tus piezas con fallas, y tú deberás defenderte con reparaciones o blindajes.

---

## 🚀 Estado actual del proyecto
- ✅ **Multijugador LAN:** El Host crea un servidor interno (Shelf) y los invitados se unen vía IP.
- ✅ **Conectividad Fácil:** Generación de **Código QR** para compartir la IP y escáner integrado.
- ✅ **Lógica de Mazo:** Generación, barajeo y reparto automático de cartas (Componentes, Fallas, Reparaciones, Especiales).
- ✅ **Sistema de Turnos:** Sincronización en tiempo real de quién juega en cada momento.
- ✅ **Interfaz Base (Grayboxing):** Pantalla de juego funcional con iconos y colores representativos.

---

## 🛠️ Tecnología
- **Lenguaje:** Dart / Flutter
- **Servidor:** Interno basado en la librería `shelf` (WebSockets).
- **Comunicación:** Mensajes JSON en tiempo real.
- **Plataformas:** Android y Windows (Soporte Cross-play).

---

## 🖥️ Componentes, Fallas y Reparaciones

| Componente | Falla (Virus) | Reparación |
|---|---|---|
| 🧠 Procesador (CPU) | 🔥 Sobrecalentamiento | 🧊 Enfriador |
| 🎮 Tarjeta de Video (GPU) | 👾 Artefactos | 🖥️ Actualizar drivers |
| 💾 Memoria RAM | 💧 Fuga de memoria | 🧹 Limpiar memoria |
| 💿 Disco Duro (SSD/HDD) | 🔵 Pantallazos azules | 💾 Formateo |
| 🔌 Placa Madre (comodín) | ⚠️ BIOS corrupta | ⚙️ Actualizar BIOS |

### Reglas básicas
- **Blindaje:** Dos reparaciones en un mismo componente lo hacen inmune a ataques y robos.
- **Destrucción:** Dos fallas en un mismo componente lo eliminan de tu equipo.
- **Placa Madre:** Es compatible con cualquier tipo de falla o reparación.

---

## 🗂️ Estructura del Código

```
lib/
├── models/
│   ├── carta.dart         # Definición de tipos y propiedades de las cartas.
│   └── jugador.dart       # Estado de los jugadores y sus componentes.
├── services/
│   ├── game_server.dart   # El "cerebro" (Servidor WebSocket del Host).
│   ├── game_client.dart   # Maneja la conexión de cada jugador con el Host.
│   ├── deck_service.dart  # Generador y barajador del mazo.
│   └── network_utils.dart # Utilidades para obtener la IP local.
└── main.dart              # Pantallas (Inicio, Lobby, GameScreen).
```

---

## 📡 Protocolo de Comunicación (JSON)

### Cliente ➡️ Servidor
- `{ "type": "join", "nombre": "..." }`: Unirse al lobby.
- `{ "type": "start_game" }`: Host inicia la partida.
- `{ "type": "play_card", "playerId": "...", "cartaId": "...", "targetPlayerId": "..." }`: Jugar carta.
- `{ "type": "discard", "playerId": "...", "cartaId": "..." }`: Descartar carta.

### Servidor ➡️ Cliente
- `{ "type": "welcome", "yourId": "..." }`: ID asignado al conectar.
- `{ "type": "update", "turnoActualId": "...", "jugadores": [...] }`: Actualización de estado global.
- `{ "type": "game_started", ... }`: Aviso de que la partida ha comenzado.

---

## 🎨 Próximos Pasos
1. Implementar la lógica de **Ataque (Virus)** a rivales.
2. Implementar la lógica de **Reparación y Blindaje**.
3. Programar las **Cartas Especiales** (Malware, Robo de datos, etc.).
4. Sustituir la interfaz básica por las **ilustraciones finales** de las cartas.
