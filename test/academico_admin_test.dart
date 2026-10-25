import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/frontend/TI-Rol/academico/nucleo_form_dialog.dart';
import 'package:mcs/frontend/TI-Rol/academico/programa_form_dialog.dart';
import 'package:mcs/frontend/TI-Rol/academico/salon_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

void main() {
  group('Modelos académicos', () {
    test('ProgramaAdmin resuelve el coordinador y busca por él', () {
      final p = ProgramaAdmin.fromJson(
        {'id': 1, 'nombre': 'Ingeniería de Sistemas', 'codigo': 'ISC', 'coordinador': 7},
        coordinadores: {7: 'Carla Mora'},
      );
      expect(p.coordinadorNombre, 'Carla Mora');
      expect(p.coincide('ingenieria'), isTrue);
      expect(p.coincide('mora'), isTrue);
      expect(p.coincide('isc'), isTrue);
      expect(p.coincide('derecho'), isFalse);
    });

    test('ProgramaAdmin sin coordinador no inventa nombre', () {
      final p = ProgramaAdmin.fromJson(
          {'id': 1, 'nombre': 'X', 'codigo': 'X1', 'coordinador': null});
      expect(p.coordinadorId, isNull);
      expect(p.coordinadorNombre, isNull);
    });

    test('SalonAdmin lee capacidad, edificio y tipo', () {
      final s = SalonAdmin.fromJson({
        'id': 2, 'codigo': 'G101', 'capacidad': 35, 'edificio': 'Bloque G', 'tipo': 'COMP',
      });
      expect(s.capacidad, 35);
      expect(s.tipoEtiqueta, 'Sala de cómputo');
      expect(s.coincide('bloque g'), isTrue);
      expect(SalonAdmin.tipos.keys, ['AULA', 'COMP']);
    });

    test('NucleoAdmin resuelve programa y gestores', () {
      final n = NucleoAdmin.fromJson(
        {
          'id': 3, 'codigo': 'MAT1', 'nombre': 'Matemáticas', 'programa': 1,
          'gestores': [5, 6], 'creditos': 3, 'semestre': '2',
          'horas_semana': 4, 'requiere_sala_computo': true,
        },
        programas: {1: 'Sistemas'},
        gestores: {5: 'Gael Pardo'},
      );
      expect(n.programaNombre, 'Sistemas');
      expect(n.gestorIds, [5, 6]);
      expect(n.gestoresNombres, ['Gael Pardo']); // el 6 no está en la lista: no se inventa
      expect(n.requiereSalaComputo, isTrue);
      expect(n.coincide('pardo'), isTrue);
      expect(n.coincide('sistemas'), isTrue);
    });
  });

  group('AdminCrudPagina', () {
    Future<void> montar(
      WidgetTester tester, {
      required Future<List<String>> Function() cargar,
      Future<void> Function(String)? eliminar,
    }) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(
        home: AdminCrudPagina<String>(
          tituloBarra: 'Barra',
          titulo: 'Gestión de elementos',
          descripcion: 'Descripción',
          icono: Icons.list,
          etiquetaCrear: 'Nuevo elemento',
          hintBusqueda: 'Buscar',
          plural: 'elementos',
          tituloVacio: 'No hay elementos',
          tituloEliminar: 'Eliminar elemento',
          mensajeCreado: 'Creado',
          mensajeActualizado: 'Actualizado',
          mensajeEliminado: 'Eliminado',
          mensajeYaNoExiste: 'Ya no existe',
          cargar: cargar,
          coincide: (x, q) => x.toLowerCase().contains(q.trim().toLowerCase()),
          nombreEliminar: (x) => x,
          eliminar: eliminar ?? (_) async {},
          formulario: (_) => const SizedBox(),
          tarjeta: (x, onEditar, onEliminar) =>
              AdminTarjeta(titulo: x, onEditar: onEditar, onEliminar: onEliminar),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('lista, busca, cancela y confirma la eliminación', (tester) async {
      final datos = ['Alfa', 'Beta'];
      final eliminados = <String>[];
      var cargas = 0;
      await montar(
        tester,
        cargar: () async {
          cargas++;
          return List.of(datos);
        },
        eliminar: (x) async {
          eliminados.add(x);
          datos.remove(x);
        },
      );

      expect(find.text('Gestión de elementos'), findsOneWidget);
      expect(find.text('Alfa'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('2 de 2 elementos'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'alf');
      await tester.pump();
      expect(find.text('Beta'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Sin resultados'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Cancelar: no hay solicitud.
      await tester.tap(find.byTooltip('Eliminar').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('"Alfa"'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(eliminados, isEmpty);

      // Confirmar: elimina y recarga la lista.
      await tester.tap(find.byTooltip('Eliminar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(eliminados, ['Alfa']);
      expect(find.text('Alfa'), findsNothing);
      expect(cargas, 2);
    });

    testWidgets('muestra el motivo cuando la API bloquea la eliminación',
        (tester) async {
      await montar(
        tester,
        cargar: () async => ['Alfa'],
        eliminar: (_) async => throw const ApiException(
          'No se puede eliminar: tiene registros asociados (2 horarios).',
          statusCode: 409,
        ),
      );
      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('No se puede eliminar'), findsOneWidget);
      expect(find.textContaining('2 horarios'), findsOneWidget);
      expect(find.text('Alfa'), findsOneWidget); // no se quitó de la lista
    });

    testWidgets('estado vacío', (tester) async {
      await montar(tester, cargar: () async => []);
      expect(find.text('No hay elementos'), findsOneWidget);
    });

    testWidgets('error de conexión con opción de reintentar', (tester) async {
      await montar(
        tester,
        cargar: () async => throw ApiException.conexion('sin red'),
      );
      expect(find.text('Sin conexión con el servidor'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('Formularios', () {
    Future<void> abrir(WidgetTester tester, Widget dialogo) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarAdminFormulario(context, builder: (_) => dialogo),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('programa: valida obligatorios y código', (tester) async {
      await abrir(tester, const ProgramaFormDialog());
      await tester.tap(find.text('Crear programa'));
      await tester.pump();
      expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
      expect(find.text('Selecciona una opción'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código *'), 'A B');
      await tester.tap(find.text('Crear programa'));
      await tester.pump();
      expect(find.textContaining('alfanumérico'), findsOneWidget);
    });

    testWidgets('programa: editar precarga los datos', (tester) async {
      const p = ProgramaAdmin(
          id: 1, nombre: 'Sistemas', codigo: 'ISC', coordinadorId: 7);
      await abrir(tester, const ProgramaFormDialog(programa: p));
      expect(find.text('Editar programa'), findsOneWidget);
      expect(find.text('Sistemas'), findsOneWidget);
      expect(find.text('ISC'), findsOneWidget);
      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      expect(find.text('No hay cambios para guardar.'), findsOneWidget);
    });

    testWidgets('salón: valida obligatorios y capacidad mínima', (tester) async {
      await abrir(tester, const SalonFormDialog());
      await tester.tap(find.text('Crear salón'));
      await tester.pump();
      expect(find.text('Este campo es obligatorio'), findsNWidgets(3));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Capacidad *'), '5');
      await tester.tap(find.text('Crear salón'));
      await tester.pump();
      expect(find.text('La capacidad mínima es 10'), findsOneWidget);
    });

    testWidgets('salón: editar precarga los datos', (tester) async {
      const s = SalonAdmin(
          id: 1, codigo: 'G101', capacidad: 30, edificio: 'Bloque G', tipo: 'COMP');
      await abrir(tester, const SalonFormDialog(salon: s));
      expect(find.text('Editar salón'), findsOneWidget);
      expect(find.text('G101'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Sala de cómputo'), findsOneWidget);
    });

    testWidgets('núcleo: valida obligatorios, créditos y horas', (tester) async {
      await abrir(tester, const NucleoFormDialog());
      await tester.tap(find.text('Crear núcleo'));
      await tester.pump();
      expect(find.text('Este campo es obligatorio'), findsNWidgets(4));
      expect(find.text('Selecciona una opción'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Créditos *'), '9');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Horas por semana *'), '41');
      await tester.tap(find.text('Crear núcleo'));
      await tester.pump();
      expect(find.text('Los créditos deben estar entre 1 y 6'), findsOneWidget);
      expect(find.text('Las horas por semana no pueden superar 40'), findsOneWidget);
    });
  });
}
