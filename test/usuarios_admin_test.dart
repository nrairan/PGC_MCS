import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/frontend/TI-Rol/usuarios/usuario_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

void main() {
  group('UsuarioAdmin', () {
    final json = {
      'id': 3,
      'username': 'aruiz',
      'email': 'ana.ruiz@ucundinamarca.edu.co',
      'first_name': 'Ana María',
      'last_name': 'Ruiz',
      'rol': 'ES',
      'groups': [],
      'user_permissions': [],
    };

    test('fromJson lee los campos de la API', () {
      final u = UsuarioAdmin.fromJson(json);
      expect(u.id, 3);
      expect(u.titulo, 'Ana María Ruiz');
      expect(u.rolEtiqueta, 'Creador de oportunidades');
    });

    test('sin nombre usa el usuario como título', () {
      final u = UsuarioAdmin.fromJson({...json, 'first_name': '', 'last_name': ''});
      expect(u.titulo, 'aruiz');
      expect(u.nombreCompleto, isEmpty);
    });

    test('los roles son los de la API', () {
      expect(UsuarioAdmin.roles.keys, ['CO', 'GC', 'ES', 'TI']);
    });

    test('la búsqueda ignora mayúsculas y tildes y mira nombre y correo', () {
      final u = UsuarioAdmin.fromJson(json);
      expect(u.coincide(''), isTrue);
      expect(u.coincide('maria'), isTrue);
      expect(u.coincide('RUIZ'), isTrue);
      expect(u.coincide('ana.ruiz@'), isTrue);
      expect(u.coincide('aruiz'), isTrue);
      expect(u.coincide('pedro'), isFalse);
    });
  });

  group('ApiException.desdeRespuesta', () {
    test('400 con errores por campo', () {
      final e = ApiException.desdeRespuesta(
        400,
        '{"email":["Ya existe un usuario con ese correo."],"rol":["No válido","Otro"]}',
        'x',
      );
      expect(e.statusCode, 400);
      expect(e.errores['email'], 'Ya existe un usuario con ese correo.');
      expect(e.errores['rol'], 'No válido Otro');
    });

    test('409 conserva el motivo y las dependencias', () {
      final e = ApiException.desdeRespuesta(
        409,
        '{"error":"No se puede eliminar: tiene registros asociados (1 programas coordinados).",'
        '"codigo":"ELIMINACION_BLOQUEADA","dependencias":{"programas_coordinados":1}}',
        'x',
      );
      expect(e.statusCode, 409);
      expect(e.mensaje, contains('programas coordinados'));
      expect(e.dependencias, {'programas_coordinados': 1});
    });

    test('403 muestra el motivo de la API', () {
      final e = ApiException.desdeRespuesta(
          403, '{"detail":"Solo el rol TI puede crear."}', 'x');
      expect(e.mensaje, 'Solo el rol TI puede crear.');
    });

    test('401 pide iniciar sesión', () {
      final e = ApiException.desdeRespuesta(
          401, '{"detail":"Authentication credentials were not provided."}', 'x');
      expect(e.mensaje, contains('sesión'));
    });

    test('cuerpo inválido usa el mensaje por defecto', () {
      final e = ApiException.desdeRespuesta(500, '<html>', 'Error interno');
      expect(e.mensaje, 'Error interno');
    });
  });

  group('AdminTarjeta', () {
    testWidgets('muestra datos y dispara editar y eliminar', (tester) async {
      var editar = 0;
      var eliminar = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminTarjeta(
            titulo: 'Ana Ruiz',
            subtitulo: 'ana@ucundinamarca.edu.co',
            etiquetas: const ['Técnico de soporte'],
            onEditar: () => editar++,
            onEliminar: () => eliminar++,
          ),
        ),
      ));

      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('ana@ucundinamarca.edu.co'), findsOneWidget);
      expect(find.text('Técnico de soporte'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar'));
      await tester.tap(find.byTooltip('Eliminar'));
      expect(editar, 1);
      expect(eliminar, 1);
    });
  });

  group('confirmarEliminacion', () {
    testWidgets('cancelar devuelve false', (tester) async {
      bool? resultado;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async =>
                  resultado = await confirmarEliminacion(context, nombre: 'Ana'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.textContaining('"Ana"'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(resultado, isFalse);
    });
  });

  group('UsuarioFormDialog', () {
    bool? cerrado;

    Future<void> abrir(WidgetTester tester, {UsuarioAdmin? usuario}) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      cerrado = null;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => cerrado = await mostrarAdminFormulario(
                context,
                builder: (_) => UsuarioFormDialog(usuario: usuario),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('crear valida los campos obligatorios sin llamar a la API',
        (tester) async {
      await abrir(tester);
      expect(find.text('Nuevo usuario'), findsOneWidget);

      await tester.tap(find.text('Crear usuario'));
      await tester.pump();

      expect(find.text('Este campo es obligatorio'), findsNWidgets(3));
      expect(find.text('Selecciona una opción'), findsOneWidget);
    });

    testWidgets('valida correo institucional y contraseña', (tester) async {
      await abrir(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre de usuario *'), 'nuevo');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo institucional *'),
          'nuevo@gmail.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña *'), 'abc');

      await tester.tap(find.text('Crear usuario'));
      await tester.pump();

      expect(find.text('Debe usar un correo @ucundinamarca.edu.co'),
          findsOneWidget);
      expect(find.text('Debe tener al menos 5 caracteres'), findsOneWidget);
    });

    testWidgets('editar precarga los datos pero no la contraseña',
        (tester) async {
      final u = UsuarioAdmin.fromJson({
        'id': 7,
        'username': 'aruiz',
        'email': 'ana@ucundinamarca.edu.co',
        'first_name': 'Ana',
        'last_name': 'Ruiz',
        'rol': 'GC',
      });
      await abrir(tester, usuario: u);

      expect(find.text('Editar usuario'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('aruiz'), findsOneWidget);
      expect(find.text('ana@ucundinamarca.edu.co'), findsOneWidget);
      expect(find.text('Gestor del Conocimiento'), findsOneWidget);

      final password = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Nueva contraseña'));
      expect(password.controller!.text, isEmpty);

      // Sin cambios no se envía nada.
      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      expect(find.text('No hay cambios para guardar.'), findsOneWidget);
      expect(cerrado, isNull);
    });

    testWidgets('cancelar cierra sin guardar', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(UsuarioFormDialog), findsNothing);
      expect(cerrado, isNull);
    });
  });
}
