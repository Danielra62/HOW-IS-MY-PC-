import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/main.dart';

void main() {
  testWidgets('Prueba de humo: Carga de pantalla de inicio', (WidgetTester tester) async {
    // Construye nuestra app y dispara un frame.
    await tester.pumpWidget(const MalwareGame());

    // Verifica que aparezca el título del juego.
    expect(find.text('🦠 MALWARE'), findsOneWidget);

    // Verifica que existan los botones de Host y Unirse.
    expect(find.text('CREAR PARTIDA (HOST)'), findsOneWidget);
    expect(find.text('UNIRSE A PARTIDA'), findsOneWidget);

    // Verifica que el campo de nombre tenga un valor inicial (no esté vacío).
    expect(find.textContaining('Jugador'), findsOneWidget);
  });
}
