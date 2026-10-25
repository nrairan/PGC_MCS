import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/api_config.dart';
import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/frontend/TI-Rol/horarios.dart';
import 'package:mcs/frontend/widgets/dialogo_eliminar_horario.dart';

/// Servicio falso: devuelve bloques fijos y registra qué ids se eliminan.
class _ServicioFalso implements HorarioVistaService {
  List<BloqueHorarioApi> bloques;
  Object? errorAlEliminar;
  Completer<void>? bloqueo;
  final List<int> eliminados = [];

  _ServicioFalso(this.bloques, {this.errorAlEliminar});

  @override
  String? get authToken => null;

  @override
  Future<Map<String, List<BloqueHorarioApi>>> fetchHorario(String semestre) async =>
      {
        for (final d in kDiasOrden)
          d: d == 'LUN' ? List.of(bloques) : <BloqueHorarioApi>[],
      };

  @override
  Future<void> eliminarHorario(int id) async {
    if (bloqueo != null) await bloqueo!.future;
    if (errorAlEliminar != null) throw errorAlEliminar!;
    eliminados.add(id);
    bloques = bloques.where((b) => b.id != id).toList();
  }
}

const _programacion = BloqueHorarioApi(
  id: 11,
  asignatura: 'Programación I',
  asignaturaId: 1,
  gestor: 'Ana Ruiz',
  gestorId: 5,
  salon: 'A101',
  salonId: 3,
  horaInicio: '07:00:00',
  horaFin: '09:00:00',
);
const _bases = BloqueHorarioApi(
  id: 12,
  asignatura: 'Bases de Datos',
  asignaturaId: 2,
  gestor: 'Luis Pardo',
  gestorId: 6,
  salon: 'B201',
  salonId: 4,
  horaInicio: '09:00:00',
  horaFin: '11:00:00',
);

void main() {
  tearDown(SesionApi.limpiar);

  group('Permiso de interfaz', () {
    test('solo CO y TI ven la acción de eliminar', () {
      for (final rol in ['CO', 'TI']) {
        SesionApi.rol = rol;
        expect(SesionApi.puedeEliminarHorarios, isTrue, reason: rol);
      }
      for (final rol in ['GC', 'ES', null]) {
        SesionApi.rol = rol;
        expect(SesionApi.puedeEliminarHorarios, isFalse, reason: '$rol');
      }
    });
  });

  group('mensajeErrorEliminarHorario', () {
    test('cubre 400, 401, 403, 404, 500 y conexión', () {
      expect(
        mensajeErrorEliminarHorario(
            const ApiException('Datos inválidos.', statusCode: 400)),
        'Datos inválidos.',
      );
      expect(
        mensajeErrorEliminarHorario(const ApiException(
            'Tu sesión no está iniciada o expiró. Inicia sesión de nuevo.',
            statusCode: 401)),
        contains('sesión'),
      );
      expect(
        mensajeErrorEliminarHorario(const ApiException(
            'Solo los roles CO y TI pueden modificar horarios.',
            statusCode: 403)),
        'Solo los roles CO y TI pueden modificar horarios.',
      );
      expect(
        mensajeErrorEliminarHorario(
            const ApiException('No Horario matches the given query.', statusCode: 404)),
        'El horario ya no existe o no pertenece a tu programa.',
      );
      expect(
        mensajeErrorEliminarHorario(
            const ApiException('<html>', statusCode: 500)),
        'Error interno del servidor. Intenta más tarde.',
      );
      expect(
        mensajeErrorEliminarHorario(ApiException.conexion('Sin conexión con la API.')),
        'Sin conexión con la API.',
      );
      expect(mensajeErrorEliminarHorario(StateError('x')), contains('No se pudo'));
    });
  });

  group('DialogoEliminarHorario', () {
    Future<void> abrir(
      WidgetTester tester,
      Future<String?> Function() onEliminar, {
      required void Function(bool?) alCerrar,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => alCerrar(await mostrarDialogoEliminarHorario(
                context,
                asignatura: 'Programación I',
                dia: 'Lunes',
                horaInicio: '07:00',
                horaFin: '09:00',
                salon: 'A101',
                gestor: 'Ana Ruiz',
                onEliminar: onEliminar,
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra los datos reales de la clase', (tester) async {
      await abrir(tester, () async => null, alCerrar: (_) {});
      expect(find.text('Programación I'), findsOneWidget);
      expect(find.text('Lunes'), findsOneWidget);
      expect(find.text('07:00 – 09:00'), findsOneWidget);
      expect(find.text('Salón A101'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Eliminar horario'), findsNWidgets(2)); // título y botón
    });

    testWidgets('cancelar no envía ninguna solicitud', (tester) async {
      var llamadas = 0;
      bool? resultado = true;
      await abrir(tester, () async {
        llamadas++;
        return null;
      }, alCerrar: (r) => resultado = r);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(llamadas, 0);
      expect(resultado, isNull);
      expect(find.byType(DialogoEliminarHorario), findsNothing);
    });

    testWidgets('confirmar con éxito cierra devolviendo true', (tester) async {
      var llamadas = 0;
      bool? resultado;
      await abrir(tester, () async {
        llamadas++;
        return null;
      }, alCerrar: (r) => resultado = r);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar horario'));
      await tester.pumpAndSettle();
      expect(llamadas, 1);
      expect(resultado, isTrue);
      expect(find.byType(DialogoEliminarHorario), findsNothing);
    });

    testWidgets('muestra carga y evita solicitudes duplicadas', (tester) async {
      var llamadas = 0;
      final espera = Completer<String?>();
      await abrir(tester, () {
        llamadas++;
        return espera.future;
      }, alCerrar: (_) {});

      final boton = find.widgetWithText(ElevatedButton, 'Eliminar horario');
      await tester.tap(boton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Eliminando…'), findsOneWidget);
      // Con la solicitud en curso, los botones están bloqueados.
      await tester.tap(find.text('Eliminando…'));
      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      expect(llamadas, 1);
      expect(find.byType(DialogoEliminarHorario), findsOneWidget);

      espera.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(DialogoEliminarHorario), findsNothing);
    });

    testWidgets('si la API rechaza, sigue abierto y muestra el motivo',
        (tester) async {
      bool? resultado;
      var cerrado = false;
      await abrir(tester, () async => 'Solo los roles CO y TI pueden modificar horarios.',
          alCerrar: (r) {
        resultado = r;
        cerrado = true;
      });
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar horario'));
      await tester.pumpAndSettle();
      expect(find.text('Solo los roles CO y TI pueden modificar horarios.'),
          findsOneWidget);
      expect(find.byType(DialogoEliminarHorario), findsOneWidget);
      expect(cerrado, isFalse);
      expect(resultado, isNull);
    });
  });

  group('HorariosScreen', () {
    Future<_ServicioFalso> abrir(
      WidgetTester tester, {
      String? rol,
      Object? errorAlEliminar,
    }) async {
      SesionApi.rol = rol;
      final servicio = _ServicioFalso([_programacion, _bases],
          errorAlEliminar: errorAlEliminar);
      await tester.pumpWidget(MaterialApp(home: HorariosScreen(servicio: servicio)));
      await tester.pumpAndSettle();
      return servicio;
    }

    testWidgets('1. TI y CO ven editar y eliminar en cada horario', (tester) async {
      for (final rol in ['TI', 'CO']) {
        await abrir(tester, rol: rol);
        expect(find.byTooltip('Editar horario'), findsNWidgets(2), reason: rol);
        expect(find.byTooltip('Eliminar horario'), findsNWidgets(2), reason: rol);
      }
    });

    testWidgets('GC, ES y sin rol no ven eliminar, pero conservan editar',
        (tester) async {
      for (final rol in ['GC', 'ES', null]) {
        await abrir(tester, rol: rol);
        expect(find.byTooltip('Eliminar horario'), findsNothing, reason: '$rol');
        expect(find.byTooltip('Editar horario'), findsNWidgets(2), reason: '$rol');
      }
    });

    testWidgets('2. la confirmación muestra los datos del horario elegido',
        (tester) async {
      final servicio = await abrir(tester, rol: 'TI');
      await tester.tap(find.byTooltip('Eliminar horario').last);
      await tester.pumpAndSettle();

      expect(find.byType(DialogoEliminarHorario), findsOneWidget);
      expect(find.text('Lunes'), findsWidgets);
      expect(find.text('09:00 – 11:00'), findsOneWidget);
      expect(find.text('Salón B201'), findsWidgets);
      expect(find.text('Luis Pardo'), findsWidgets);
      expect(servicio.eliminados, isEmpty); // nada se elimina al pulsar la papelera
    });

    testWidgets('3. cancelar no modifica nada', (tester) async {
      final servicio = await abrir(tester, rol: 'TI');
      await tester.tap(find.byTooltip('Eliminar horario').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.eliminados, isEmpty);
      expect(find.text('Programación I'), findsOneWidget);
      expect(find.text('Bases de Datos'), findsOneWidget);
    });

    testWidgets('4 y 5. confirmar elimina solo ese horario y quita su tarjeta',
        (tester) async {
      final servicio = await abrir(tester, rol: 'CO');
      await tester.tap(find.byTooltip('Eliminar horario').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar horario'));
      await tester.pumpAndSettle();

      expect(servicio.eliminados, [11]); // el id del horario, no el de la asignatura
      expect(find.text('Programación I'), findsNothing);
      expect(find.text('Bases de Datos'), findsOneWidget);
      expect(find.text('Horario eliminado'), findsOneWidget);
    });

    testWidgets('6. un error de la API no produce falsa confirmación',
        (tester) async {
      final servicio = await abrir(
        tester,
        rol: 'CO',
        errorAlEliminar: const ApiException(
          'Solo los roles CO y TI pueden modificar horarios.',
          statusCode: 403,
        ),
      );
      await tester.tap(find.byTooltip('Eliminar horario').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar horario'));
      await tester.pumpAndSettle();

      expect(servicio.eliminados, isEmpty);
      expect(find.text('Solo los roles CO y TI pueden modificar horarios.'),
          findsOneWidget);
      expect(find.text('Horario eliminado'), findsNothing);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Programación I'), findsOneWidget); // la tarjeta se conserva
      expect(find.text('Bases de Datos'), findsOneWidget);
    });

    testWidgets('7. el botón de editar sigue disponible tras eliminar',
        (tester) async {
      await abrir(tester, rol: 'TI');
      await tester.tap(find.byTooltip('Eliminar horario').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar horario'));
      await tester.pumpAndSettle();

      final editar = tester.widget<IconButton>(find.widgetWithIcon(
          IconButton, Icons.edit_outlined));
      expect(editar.onPressed, isNotNull);
      expect(find.byTooltip('Editar horario'), findsOneWidget);
    });
  });
}
