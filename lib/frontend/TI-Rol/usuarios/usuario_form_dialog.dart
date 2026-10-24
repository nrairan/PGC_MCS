import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Formulario para crear o editar un usuario (modo edición si `usuario != null`).
///
/// Se cierra con `true` solo cuando la API confirma el guardado. Si la API
/// rechaza la solicitud, permanece abierto con los datos escritos y muestra el
/// motivo. La contraseña nunca se precarga.
class UsuarioFormDialog extends StatefulWidget {
  final UsuarioAdmin? usuario;

  const UsuarioFormDialog({super.key, this.usuario});

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  static const String _recurso = 'usuarios';
  static const String _dominio = '@ucundinamarca.edu.co';

  /// Etiquetas de los campos de la API para los mensajes de error.
  static const Map<String, String> _etiquetas = {
    'username': 'Usuario',
    'email': 'Correo',
    'password': 'Contraseña',
    'first_name': 'Nombre',
    'last_name': 'Apellido',
    'rol': 'Rol',
  };

  final _api = const HorarioHttpClient();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _username;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();
  String? _rol;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _apellido = TextEditingController(text: u?.apellido ?? '');
    _username = TextEditingController(text: u?.username ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _rol = (u != null && UsuarioAdmin.roles.containsKey(u.rol)) ? u.rol : null;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ── Validaciones (reflejan las del serializer de Django) ─────────────────

  String? _validarEmail(String v) =>
      v.endsWith(_dominio) ? null : 'Debe usar un correo $_dominio';

  String? _validarPassword(String v) {
    if (v.length < 5) return 'Debe tener al menos 5 caracteres';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe incluir una letra mayúscula';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Debe incluir un número';
    return null;
  }

  String? _maximo(String v, int n) =>
      v.length > n ? 'Máximo $n caracteres' : null;

  // ── Envío ────────────────────────────────────────────────────────────────

  /// Campos a enviar. En edición solo viajan los que cambiaron.
  Map<String, dynamic> _datos() {
    final u = widget.usuario;
    final d = <String, dynamic>{};

    void poner(String clave, String nuevo, String? actual) {
      if (_esEdicion) {
        if (nuevo != actual) d[clave] = nuevo;
      } else if (nuevo.isNotEmpty) {
        d[clave] = nuevo;
      }
    }

    poner('first_name', _nombre.text.trim(), u?.nombre);
    poner('last_name', _apellido.text.trim(), u?.apellido);
    poner('username', _username.text.trim(), u?.username);
    poner('email', _email.text.trim(), u?.email);
    if (!_esEdicion || _rol != u?.rol) d['rol'] = _rol;
    if (_password.text.isNotEmpty) d['password'] = _password.text;
    return d;
  }

  String _mensajeDe(ApiException e) {
    if (e.errores.isEmpty) return e.mensaje;
    return e.errores.entries.map((x) {
      final etiqueta = _etiquetas[x.key];
      return etiqueta == null ? x.value : '$etiqueta: ${x.value}';
    }).join('\n');
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final datos = _datos();
    if (_esEdicion && datos.isEmpty) {
      setState(() => _error = 'No hay cambios para guardar.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (_esEdicion) {
        await _api.actualizar(_recurso, widget.usuario!.id, datos);
      } else {
        await _api.crear(_recurso, datos);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = _mensajeDe(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar el usuario. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libre = !_guardando;
    return AdminFormulario(
      titulo: _esEdicion ? 'Editar usuario' : 'Nuevo usuario',
      descripcion: _esEdicion
          ? 'Modifica los datos de la cuenta. Deja la contraseña vacía para conservar la actual.'
          : 'Registra una cuenta con su correo institucional y su rol.',
      icono: _esEdicion
          ? Icons.manage_accounts_outlined
          : Icons.person_add_alt_1_outlined,
      esEdicion: _esEdicion,
      formKey: _formKey,
      errorGeneral: _error,
      guardando: _guardando,
      onGuardar: _guardar,
      textoGuardar: _esEdicion ? 'Guardar cambios' : 'Crear usuario',
      campos: [
        AdminCampoTexto(
          controller: _nombre,
          etiqueta: 'Nombre',
          icono: Icons.badge_outlined,
          habilitado: libre,
          validador: (v) => _maximo(v, 150),
        ),
        AdminCampoTexto(
          controller: _apellido,
          etiqueta: 'Apellido',
          icono: Icons.badge_outlined,
          habilitado: libre,
          validador: (v) => _maximo(v, 150),
        ),
        AdminCampoTexto(
          controller: _username,
          etiqueta: 'Nombre de usuario',
          obligatorio: true,
          icono: Icons.alternate_email,
          habilitado: libre,
          validador: (v) => _maximo(v, 150),
        ),
        AdminCampoTexto(
          controller: _email,
          etiqueta: 'Correo institucional',
          obligatorio: true,
          hint: 'usuario$_dominio',
          icono: Icons.email_outlined,
          teclado: TextInputType.emailAddress,
          habilitado: libre,
          validador: _validarEmail,
        ),
        AdminCampoTexto(
          controller: _password,
          etiqueta: _esEdicion ? 'Nueva contraseña' : 'Contraseña',
          obligatorio: !_esEdicion,
          ayuda: _esEdicion
              ? 'Opcional. Mínimo 5 caracteres, una mayúscula y un número.'
              : 'Mínimo 5 caracteres, una mayúscula y un número.',
          icono: Icons.lock_outline,
          oculto: true,
          habilitado: libre,
          validador: _validarPassword,
        ),
        AdminSelector<String>(
          valor: _rol,
          etiqueta: 'Rol',
          obligatorio: true,
          icono: Icons.verified_user_outlined,
          opciones: [
            for (final e in UsuarioAdmin.roles.entries)
              AdminOpcion<String>(e.key, e.value),
          ],
          onChanged: libre ? (v) => setState(() => _rol = v) : null,
        ),
      ],
    );
  }
}
