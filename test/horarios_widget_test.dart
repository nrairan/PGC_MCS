import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/frontend/formularios/formulario_horario.dart';

void main() {
  final asignaturasTest = [
    {'id': 1, 'codigo': 'SIS101', 'nombre': 'Programación Básica'},
    {'id': 2, 'codigo': 'CAI1002020202', 'nombre': 'COMUNICACIÓN Y LECTURA CRÍTICA I'},
  ];

  final gestoresTest = [
    {'id': 10, 'first_name': 'Carlos', 'last_name': 'Gómez', 'username': 'cgomez'},
  ];

  final salonesTest = [
    const SalonItem(id: 1, codigo: 'S-101', capacidad: 30, edificio: 'Edificio Central'),
    const SalonItem(id: 2, codigo: 'S-102', capacidad: 40, edificio: 'Edificio Central'),
  ];

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('HorarioForm muestra campos obligatorios y selector de salón', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestableWidget(
        HorarioForm(
          asignaturasIniciales: asignaturasTest,
          gestoresIniciales: gestoresTest,
          salonesIniciales: salonesTest,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crear Horario'), findsOneWidget);
    expect(find.text('Validar Disponibilidad'), findsOneWidget);
    expect(find.text('Guardar Horario'), findsOneWidget);

    // Debe mostrar la etiqueta de salón obligatorio
    expect(find.text('Salón de clases (Obligatorio) *'), findsOneWidget);
  });

  testWidgets('Al intentar guardar sin seleccionar salón se muestra advertencia', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestableWidget(
        HorarioForm(
          asignaturasIniciales: asignaturasTest,
          gestoresIniciales: gestoresTest,
          salonesIniciales: salonesTest,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Presionar Guardar Horario sin haber seleccionado salón
    await tester.tap(find.text('Guardar Horario'));
    await tester.pumpAndSettle();

    // Debe desplegarse la advertencia de salón obligatorio
    expect(find.text('Advertencia: El salón de clases es obligatorio.'), findsOneWidget);
  });

  testWidgets('Al seleccionar un CAI se bloquea la modificación y se aplica horario fijo', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestableWidget(
        HorarioForm(
          asignaturasIniciales: asignaturasTest,
          gestoresIniciales: gestoresTest,
          salonesIniciales: salonesTest,
          horarioParaEditar: {
            'id': 99,
            'asignatura': 2, // CAI1002020202
            'asignatura_id': 2,
            'gestor': 10,
            'gestor_id': 10,
            'salon': 1,
            'semestre': '1',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Debe mostrar el banner de Núcleo CAI
    expect(find.textContaining('Núcleo CAI detectado'), findsOneWidget);
    expect(find.text('Día (Fijo CAI)'), findsOneWidget);
    expect(find.text('Hora Inicio (Fija CAI)'), findsOneWidget);
    expect(find.text('Hora Fin (Fija CAI)'), findsOneWidget);
  });
}
