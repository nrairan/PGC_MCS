import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/CO-Rol/nucleos_coordinador_screen.dart';
import 'package:mcs/frontend/CO-Rol/programa_coordinador_screen.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';
import 'package:mcs/frontend/widgets/programa_coordinador_banner.dart';

/// Cliente HTTP falso: devuelve lo que la API devolvería para un coordinador
/// (el servidor ya filtra por programa) y registra las consultas.
class _ApiFalsa extends HorarioHttpClient {
  final List<Map<String, dynamic>> programas;
  final List<Map<String, dynamic>> asignaturas;
  final Object? error;
  final List<String> llamadas = [];
  final List<Map<String, String>?> filtrosUsados = [];

  _ApiFalsa({
    this.programas = const [],
    this.asignaturas = const [],
    this.error,
  });

  @override
  Future<List<Map<String, dynamic>>> listar(String ruta,
      {Map<String, String>? filtros}) async {
    llamadas.add(ruta);
    filtrosUsados.add(filtros);
    if (error != null) throw error!;
    switch (ruta) {
      case 'programa':
        return programas;
      case 'asignaturas':
        return asignaturas;
      case 'usuarios':
        // Los gestores son un recurso compartido: incluyen gestores de otros programas.
        return filtros?['rol'] == 'GC'
            ? [
                {'id': 7, 'username': 'gestor7', 'first_name': 'Gina', 'last_name': 'Gómez', 'rol': 'GC', 'email': 'g7@ucundinamarca.edu.co'},
                {'id': 8, 'username': 'gestor8', 'first_name': 'Hugo', 'last_name': 'Herrera', 'rol': 'GC', 'email': 'g8@ucundinamarca.edu.co'},
              ]
            : [
                {'id': 4, 'username': 'coord', 'first_name': 'Carla', 'last_name': 'Pérez', 'rol': 'CO', 'email': 'c@ucundinamarca.edu.co'},
              ];
      default:
        return [];
    }
  }
}

final _programa = {'id': 1, 'nombre': 'Ingeniería de Sistemas', 'codigo': 'IS01', 'coordinador': 4};
final _nucleos = [
  {'id': 10, 'codigo': 'IS101', 'nombre': 'Programación I', 'programa': 1, 'gestores': [7], 'creditos': 3, 'horas_semana': 4, 'semestre': '1', 'requiere_sala_computo': true},
  {'id': 11, 'codigo': 'IS102', 'nombre': 'Bases de Datos', 'programa': 1, 'gestores': [8], 'creditos': 3, 'horas_semana': 0, 'semestre': '2', 'requiere_sala_computo': false},
];

Future<void> _montar(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(1600, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(home: pantalla));
  await tester.pumpAndSettle();
}

void main() {
  group('Banner del programa del coordinador', () {
    testWidgets('muestra el programa que devuelve la API', (tester) async {
      final api = _ApiFalsa(programas: [_programa]);
      await _montar(
          tester,
          Scaffold(
              body: ProgramaCoordinadorBanner(servicio: AcademicoAdminService(api))));
      expect(find.textContaining('Ingeniería de Sistemas (IS01)'), findsOneWidget);
    });

    testWidgets('sin programa asignado muestra un aviso claro', (tester) async {
      final api = _ApiFalsa();
      await _montar(
          tester,
          Scaffold(
              body: ProgramaCoordinadorBanner(servicio: AcademicoAdminService(api))));
      expect(find.textContaining('no tiene un programa asignado'), findsOneWidget);
    });

    testWidgets('un error de la API se informa y permite reintentar', (tester) async {
      final api = _ApiFalsa(
          error: const ApiException('Tu sesión expiró.', statusCode: 401));
      await _montar(
          tester,
          Scaffold(
              body: ProgramaCoordinadorBanner(servicio: AcademicoAdminService(api))));
      expect(find.textContaining('No se pudo consultar tu programa'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('Núcleos del coordinador', () {
    testWidgets('lista solo lo que devuelve la API y resuelve gestores compartidos',
        (tester) async {
      final api = _ApiFalsa(programas: [_programa], asignaturas: _nucleos);
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));

      expect(find.text('Programación I'), findsOneWidget);
      expect(find.text('Bases de Datos'), findsOneWidget);
      expect(find.textContaining('Gina'), findsOneWidget); // gestor de otro programa
      expect(find.text('Sala de cómputo'), findsOneWidget);
      expect(find.textContaining('sin definir'), findsOneWidget);
    });

    testWidgets('no ofrece crear, editar ni eliminar', (tester) async {
      final api = _ApiFalsa(programas: [_programa], asignaturas: _nucleos);
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.text('Nuevo núcleo'), findsNothing);
    });

    testWidgets('el cliente no envía el programa: lo decide el servidor', (tester) async {
      final api = _ApiFalsa(programas: [_programa], asignaturas: _nucleos);
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));
      for (final f in api.filtrosUsados) {
        expect(f?.containsKey('programa') ?? false, isFalse);
      }
    });

    testWidgets('sin programa asignado no se presenta información', (tester) async {
      final api = _ApiFalsa();
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.text('Sin programa asignado'), findsOneWidget);
      expect(find.byType(AdminTarjeta), findsNothing);
    });

    testWidgets('programa sin núcleos muestra lista vacía', (tester) async {
      final api = _ApiFalsa(programas: [_programa]);
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.textContaining('aún no tiene núcleos temáticos'), findsOneWidget);
    });

    testWidgets('error de permisos se distingue de un error de conexión', (tester) async {
      final api = _ApiFalsa(
          error: const ApiException('Sin permiso.', statusCode: 403));
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.text('No tienes permiso para ver esta información'), findsOneWidget);
    });

    testWidgets('error de conexión se informa y no se muestra como lista vacía',
        (tester) async {
      final api = _ApiFalsa(error: ApiException.conexion('Sin red.'));
      await _montar(tester, NucleosCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.text('Sin conexión con el servidor'), findsOneWidget);
      expect(find.textContaining('aún no tiene núcleos temáticos'), findsNothing);
    });
  });

  group('Programa del coordinador', () {
    testWidgets('muestra únicamente su programa y no permite cambiarlo', (tester) async {
      final api = _ApiFalsa(programas: [_programa]);
      await _montar(tester, ProgramaCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.byType(AdminTarjeta), findsOneWidget);
      expect(find.text('Ingeniería de Sistemas'), findsWidgets);
      expect(find.text('Código: IS01'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('sin programa asignado lo indica', (tester) async {
      final api = _ApiFalsa();
      await _montar(tester, ProgramaCoordinadorScreen(servicio: AcademicoAdminService(api)));
      expect(find.text('No tienes un programa asignado'), findsOneWidget);
    });
  });

  group('Conflictos con otros programas', () {
    test('el conflicto con una clase ajena llega sin datos privados', () {
      final c = ConflictoHorario.fromJson({
        'tipo': 'SALON_OCUPADO',
        'mensaje': 'El salón B201 ya tiene una clase asignada el MAR de 07:00 a 09:00.',
        'horario_id': null,
      });
      expect(c.tipo, 'SALON_OCUPADO');
      expect(c.horarioConflictoId, isNull);
      expect(c.mensaje, contains('B201'));
    });
  });
}
