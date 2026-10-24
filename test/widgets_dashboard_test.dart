import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/frontend/widgets/ultimos_cambios_widget.dart';
import 'package:mcs/frontend/widgets/graficos/graficos_coordinador.dart';
import 'package:mcs/frontend/pantallas_historial/historial_coordinador_screen.dart';
import 'package:mcs/frontend/pantallas_historial/historial_ti_screen.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';

void main() {
  testWidgets('UltimosCambiosWidget muestra encabezado y tabla', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UltimosCambiosWidget(rol: 'CO'),
          ),
        ),
      ),
    );

    expect(find.text('Últimos 5 Cambios del Sistema'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Acción'), findsOneWidget);
  });

  testWidgets('GraficoHorariosPorDia renderiza tarjeta y título de clases', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              height: 400,
              child: GraficoHorariosPorDia(semestre: '1'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Distribución Semanal de Clases'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('HistorialCoordinadorScreen incluye MenuLateral', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: HistorialCoordinadorScreen(),
      ),
    );

    await tester.pump();
    expect(find.byType(MenuLateral), findsOneWidget);
    expect(find.text('Historial de Programación Académica'), findsOneWidget);

    // Drenar el temporizador del fallback paginado
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });

  testWidgets('HistorialTiScreen incluye LateralTi y no MenuLateral', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: HistorialTiScreen(),
      ),
    );

    await tester.pump();
    expect(find.byType(LateralTi), findsOneWidget);
    expect(find.byType(MenuLateral), findsNothing);
    expect(find.text('Historial de Auditoría y Logs TI'), findsOneWidget);

    // Drenar el temporizador del fallback paginado
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });
}
