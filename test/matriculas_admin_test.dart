import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/frontend/TI-Rol/academico/matricula_form_dialog.dart';
import 'package:mcs/frontend/TI-Rol/usuarios/usuarios_admin_screen.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

void main() {
  group('MatriculaAdmin', () {
    final estudiante = UsuarioAdmin.fromJson({
      'id': 4, 'username': 'elena', 'email': 'elena@ucundinamarca.edu.co',
      'first_name': 'Elena', 'last_name': 'Ríos', 'rol': 'ES',
    });
    final nucleo = NucleoAdmin.fromJson(
      {
        'id': 9, 'codigo': 'MAT1', 'nombre': 'Matemáticas', 'programa': 1,
        'creditos': 3, 'horas_semana': 4, 'gestores': [],
      },
      programas: {1: 'Sistemas'},
    );
    final json = {'id': 1, 'estudiante': 4, 'asignatura': 9, 'semestre': '2'};

    test('resuelve estudiante, asignatura y programa', () {
      final m = MatriculaAdmin.fromJson(json,
          estudiantes: {4: estudiante}, nucleos: {9: nucleo});
      expect(m.estudianteNombre, 'Elena Ríos');
      expect(m.estudianteCorreo, 'elena@ucundinamarca.edu.co');
      expect(m.asignaturaNombre, 'Matemáticas');
      expect(m.programaNombre, 'Sistemas');
      expect(m.semestre, '2');
    });

    test('si faltan los datos relacionados no inventa nombres', () {
      final m = MatriculaAdmin.fromJson(json);
      expect(m.estudianteNombre, isNull);
      expect(m.asignaturaNombre, isNull);
      expect(m.estudianteId, 4);
      expect(m.asignaturaId, 9);
    });

    test('búsqueda por estudiante, asignatura, programa y semestre', () {
      final m = MatriculaAdmin.fromJson(json,
          estudiantes: {4: estudiante}, nucleos: {9: nucleo});
      expect(m.coincide('rios'), isTrue);
      expect(m.coincide('matematicas'), isTrue);
      expect(m.coincide('sistemas'), isTrue);
      expect(m.coincide('mat1'), isTrue);
      expect(m.coincide('zzz'), isFalse);
    });
  });

  group('MatriculaFormDialog', () {
    Future<void> abrir(WidgetTester tester, Widget dialogo) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  mostrarAdminFormulario(context, builder: (_) => dialogo),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('crear valida selectores y semestre', (tester) async {
      await abrir(tester, const MatriculaFormDialog());
      expect(find.text('Nueva matrícula'), findsOneWidget);

      await tester.tap(find.text('Crear matrícula'));
      await tester.pump();
      expect(find.text('Selecciona una opción'), findsNWidgets(2));
      expect(find.text('Este campo es obligatorio'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Semestre *'), '12345678901');
      await tester.tap(find.text('Crear matrícula'));
      await tester.pump();
      expect(find.text('Máximo 10 caracteres'), findsOneWidget);
    });

    testWidgets('editar precarga el semestre y no envía sin cambios',
        (tester) async {
      const m = MatriculaAdmin(
          id: 1, estudianteId: 4, asignaturaId: 9, semestre: '3');
      await abrir(tester, const MatriculaFormDialog(matricula: m));
      expect(find.text('Editar matrícula'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      expect(find.text('No hay cambios para guardar.'), findsOneWidget);
    });
  });

  group('Navegación del menú TI', () {
    testWidgets('cada entrada abre su pantalla administrativa', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: UsuariosAdminScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Gestión de usuarios'), findsOneWidget);

      const destinos = {
        'Salones': 'Gestión de salones',
        'Programas': 'Gestión de programas',
        'Núcleos temáticos': 'Gestión de núcleos temáticos',
        'Matrículas': 'Gestión de matrículas',
      };
      for (final d in destinos.entries) {
        await tester.tap(find.text(d.key));
        await tester.pumpAndSettle();
        expect(find.text(d.value), findsOneWidget, reason: d.key);
        // Sin servidor la pantalla muestra su estado de error, sin excepciones.
        expect(find.byType(AdminError), findsOneWidget, reason: d.key);
        expect(tester.takeException(), isNull, reason: d.key);
      }
    });
  });
}
