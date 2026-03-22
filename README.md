# 🦠 MALWARE — Juego de cartas digital

## ¿Qué es este proyecto?
Malware es un juego de cartas digital multijugador inspirado en el juego de mesa "Virus!".
La temática está basada en componentes de computadora. El objetivo es ser el primero en tener
**4 componentes sanos** en tu equipo. Los demás jugadores intentarán impedirlo lanzándote
fallas a tus componentes.

El juego funciona en **red local (LAN)**. Un jugador hace de host (servidor) y los demás
se conectan ingresando su IP. El host también puede jugar normalmente.

---

## 🛠️ Stack tecnológico

| Parte | Tecnología |
|---|---|
| App (cliente) | Flutter (Android + Windows) |
| Servidor | Node.js + WebSockets (librería `ws`) |
| Comunicación | WebSockets en JSON |
| Textos / i18n | Archivos `.arb` en carpeta `l10n/` |

---

## 🗂️ Estructura de archivos

```
malware/
│
├── server/                         ← Servidor Node.js
│   ├── index.js                    ← Punto de entrada, arranca el servidor WebSocket
│   ├── gameState.js                ← Estado global de la partida
│   ├── validaciones.js             ← Reglas del juego (qué jugadas son legales)
│   ├── cartas.js                   ← Definición de todas las cartas del mazo
│   ├── mazo.js                     ← Lógica de barajar, repartir y robar cartas
│   └── package.json
│
└── app/                            ← App Flutter
    ├── pubspec.yaml
    └── lib/
        ├── main.dart               ← Punto de entrada de la app
        │
        ├── l10n/                   ← ⭐ TEXTOS SEPARADOS PARA TRADUCCIÓN
        │   ├── app_es.arb          ← Español (idioma base)
        │   └── app_en.arb          ← Inglés (u otros idiomas a futuro)
        │
        ├── models/                 ← Clases de datos
        │   ├── carta.dart          ← Modelo de una carta
        │   ├── jugador.dart        ← Modelo de un jugador
        │   ├── componente.dart     ← Modelo de un componente (cpu, gpu, etc.)
        │   └── partida.dart        ← Modelo del estado completo de la partida
        │
        ├── services/
        │   └── websocket_service.dart  ← Toda la comunicación con el servidor
        │
        └── screens/                ← Pantallas de la app
            ├── inicio_screen.dart      ← Pantalla inicial (Crear / Unirse)
            ├── lobby_screen.dart       ← Sala de espera antes de iniciar
            ├── juego_screen.dart       ← Pantalla principal del juego
            └── ganador_screen.dart     ← Pantalla de victoria
```

---

## 🃏 Cartas del juego

### Componentes (el jugador necesita 4 para ganar)

| Componente | Color |
|---|---|
| 🧠 Procesador (CPU) | Rojo |
| 🎮 Tarjeta de Video (GPU) | Verde |
| 💾 Memoria RAM | Azul |
| 💿 Disco Duro (SSD/HDD) | Amarillo |
| 🔌 Placa Madre | Morado (comodín, compatible con cualquier falla/reparación) |

Un jugador solo puede tener **un componente de cada color** en su equipo.
Si un componente recibe **dos fallas**, queda destruido y se pierde.
Si un componente recibe **dos reparaciones**, queda **blindado** (inmune a ataques y robos).

---

### Fallas (atacan los componentes del rival)

| Carta | Componente que daña |
|---|---|
| 🔥 Sobrecalentamiento | Procesador (CPU) |
| 👾 Artefactos | Tarjeta de Video (GPU) |
| 💧 Fuga de memoria | Memoria RAM |
| 🔵 Pantallazos azules | Disco Duro (SSD/HDD) |
| ⚠️ BIOS corrupta | Placa Madre |

---

### Reparaciones (curan los componentes propios)

| Carta | Repara |
|---|---|
| 🧊 Enfriador | Procesador (CPU) |
| 🖥️ Actualizar drivers | Tarjeta de Video (GPU) |
| 🧹 Limpiar memoria | Memoria RAM |
| 💾 Formateo | Disco Duro (SSD/HDD) |
| ⚙️ Actualizar BIOS | Placa Madre |

---

### Cartas especiales (acciones)

| Carta | Qué hace |
|---|---|
| 🦠 Malware | Propaga una falla a **todos** los rivales al mismo tiempo |
| 🔄 Robo de datos | Roba un componente del equipo de otro jugador |
| 🔃 Transferencia | Intercambia un componente tuyo con uno de un rival |
| 💣 Hackeo | Destruye un componente **blindado** de un rival |
| ⏸️ Cuelgue | El rival seleccionado se salta su próximo turno |
| ♻️ Reinicio | **Todos** los jugadores descartan su mano y roban cartas nuevas |
| 🤝 Intercambio de archivos | Cambias toda tu mano con la de otro jugador |

---

## 📡 Comunicación Cliente ↔ Servidor (WebSockets en JSON)

### Mensajes del cliente al servidor

```json
// Unirse a la partida
{ "accion": "unirse", "nombre": "Juan" }

// Iniciar la partida (solo el host)
{ "accion": "iniciar_partida" }

// Jugar una carta de falla sobre un rival
{ "accion": "jugar_carta", "tipo": "falla", "carta": "sobrecalentamiento", "objetivo_jugador": "jugador_2", "componente": "cpu" }

// Jugar una carta de reparación sobre tu propio componente
{ "accion": "jugar_carta", "tipo": "reparacion", "carta": "enfriador", "componente": "cpu" }

// Jugar una carta especial
{ "accion": "jugar_carta", "tipo": "especial", "carta": "cuelgue", "objetivo_jugador": "jugador_3" }
```

### Mensajes del servidor a los clientes

```json
// Estado actualizado (se envía a todos tras cada acción)
{ "evento": "actualizar_estado", "estado": { ...estado completo... } }

// Aviso de turno
{ "evento": "tu_turno", "jugador_id": "jugador_1" }

// Alguien ganó
{ "evento": "ganador", "jugador": "Juan" }

// Jugada inválida
{ "evento": "error", "mensaje": "No puedes jugar esa carta aquí" }
```

---

## 🧠 Estado del juego (estructura JSON en el servidor)

```json
{
  "partida": {
    "estado": "esperando | en_juego | terminada",
    "turno_actual": "jugador_id",
    "mazo": [],
    "descarte": []
  },
  "jugadores": [
    {
      "id": "jugador_1",
      "nombre": "Juan",
      "es_host": true,
      "bloqueado": false,
      "mano": ["carta1", "carta2", "carta3"],
      "componentes": {
        "cpu":         { "estado": "sano | dañado | blindado | destruido", "fallas": 0, "reparaciones": 0 },
        "gpu":         { "estado": "sano | dañado | blindado | destruido", "fallas": 0, "reparaciones": 0 },
        "ram":         { "estado": "sano | dañado | blindado | destruido", "fallas": 0, "reparaciones": 0 },
        "ssd":         { "estado": "sano | dañado | blindado | destruido", "fallas": 0, "reparaciones": 0 },
        "motherboard": { "estado": "sano | dañado | blindado | destruido", "fallas": 0, "reparaciones": 0 }
      }
    }
  ]
}
```

---

## ✅ Validaciones que debe hacer el servidor

| Validación | Detalle |
|---|---|
| ¿Es el turno del jugador? | Solo puede jugar quien tiene el turno activo |
| ¿La carta está en su mano? | No se puede jugar una carta que no se tiene |
| ¿El componente objetivo es válido? | No se puede colocar un componente duplicado |
| ¿La falla es compatible con el componente? | Cada falla solo daña su componente correspondiente |
| ¿El componente está blindado? | Solo la carta "Hackeo" puede afectar un componente blindado |
| ¿El jugador está bloqueado? | Un jugador con "Cuelgue" activo se salta su turno automáticamente |
| ¿Hay un ganador? | Verificar si algún jugador tiene 4 componentes sanos tras cada jugada |

---

## 🎮 Flujo de una jugada (paso a paso)

```
1. El cliente envía la carta que quiere jugar
2. El servidor valida si la jugada es legal
3. El servidor actualiza el estado del juego
4. El servidor envía el estado actualizado a TODOS los jugadores
5. El servidor verifica si alguien ganó
6. El servidor pasa el turno al siguiente jugador
```

---

## 🌐 Sistema de textos e internacionalización (i18n)

Todos los textos visibles en la app están en archivos `.arb` dentro de `lib/l10n/`.
Para traducir el juego a otro idioma, solo hay que crear un nuevo archivo `.arb`
(por ejemplo `app_pt.arb` para portugués) y traducir los valores.

### Ejemplo de archivo `app_es.arb`
```json
{
  "titulo_juego": "Malware",
  "boton_crear_partida": "Crear partida",
  "boton_unirse": "Unirse a partida",
  "placeholder_ip": "Ingresa la IP del host",
  "esperando_jugadores": "Esperando jugadores...",
  "tu_turno": "¡Es tu turno!",
  "carta_sobrecalentamiento": "Sobrecalentamiento",
  "carta_artefactos": "Artefactos",
  "carta_fuga_memoria": "Fuga de memoria",
  "carta_pantallazos_azules": "Pantallazos azules",
  "carta_bios_corrupta": "BIOS corrupta",
  "carta_enfriador": "Enfriador",
  "carta_actualizar_drivers": "Actualizar drivers",
  "carta_limpiar_memoria": "Limpiar memoria",
  "carta_formateo": "Formateo",
  "carta_actualizar_bios": "Actualizar BIOS",
  "carta_malware": "Malware",
  "carta_robo_datos": "Robo de datos",
  "carta_transferencia": "Transferencia",
  "carta_hackeo": "Hackeo",
  "carta_cuelgue": "Cuelgue",
  "carta_reinicio": "Reinicio",
  "carta_intercambio_archivos": "Intercambio de archivos",
  "componente_cpu": "Procesador",
  "componente_gpu": "Tarjeta de Video",
  "componente_ram": "Memoria RAM",
  "componente_ssd": "Disco Duro",
  "componente_motherboard": "Placa Madre",
  "estado_sano": "Sano",
  "estado_dañado": "Dañado",
  "estado_blindado": "Blindado",
  "estado_destruido": "Destruido",
  "mensaje_ganador": "{nombre} ¡ganó la partida!",
  "error_turno": "No es tu turno",
  "error_carta_invalida": "Jugada no válida"
}
```

---

## 🚀 Cómo iniciar una partida

1. El **host** corre el servidor: `node server/index.js`
2. El **host** abre la app y presiona **"Crear partida"** (se conecta automáticamente)
3. Los **demás jugadores** abren la app, presumen **"Unirse a partida"** e ingresan la IP del host
4. Todos llegan al **lobby** y esperan
5. El **host** presiona **"Iniciar partida"**
6. ¡A jugar!

---

## 📌 Notas importantes para el desarrollo

- El servidor corre en el puerto `8080` por defecto
- El host se conecta a `localhost` (127.0.0.1), los demás a la IP local del host (ej: 192.168.1.10)
- Si el host cierra la app, la partida termina para todos
- El mazo debe barajarse aleatoriamente al iniciar cada partida
- Cada jugador empieza con **3 cartas** en mano y roba 1 al final de cada turno
- La carta "Malware" (especial) da nombre al juego y es la más poderosa