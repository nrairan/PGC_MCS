import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/frontend/TI-Rol/usuarios/usuario_form_dialog.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';

/// Gestión de usuarios del rol TI: listar, buscar, crear, editar y eliminar.
class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  static const String _recurso = 'usuarios';

  final _api = const HorarioHttpClient();
  final _busqueda = TextEditingController();

  List<UsuarioAdmin> _usuarios = const [];
  bool _cargando = true;
  Object? _error;
  String _consulta = '';
  int? _eliminandoId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  /// Consulta `GET /api/usuarios/`. Con `silencioso` no oculta la lista actual.
  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final datos = await _api.listar(_recurso);
      final lista = datos.map(UsuarioAdmin.fromJson).toList()
        ..sort((a, b) =>
            a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _usuarios = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_usuarios.isNotEmpty) {
        // Se conserva la lista que ya se veía y se informa el fallo.
        setState(() => _cargando = false);
        mostrarMensaje(context, 'No se pudo actualizar la lista: ${mensajeDeError(e)}',
            error: true);
      } else {
        setState(() {
          _cargando = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _abrirFormulario([UsuarioAdmin? usuario]) async {
    final guardado = await mostrarAdminFormulario(
      context,
      builder: (_) => UsuarioFormDialog(usuario: usuario),
    );
    if (guardado != true || !mounted) return;
    mostrarMensaje(
        context, usuario == null ? 'Usuario creado' : 'Usuario actualizado');
    await _cargar(silencioso: true);
  }

  Future<void> _eliminar(UsuarioAdmin u) async {
    final confirmado = await confirmarEliminacion(
      context,
      titulo: 'Eliminar usuario',
      nombre: u.titulo,
      advertencia: u.email.isEmpty
          ? 'Esta acción no se puede deshacer.'
          : 'Se eliminará la cuenta ${u.email}. Esta acción no se puede deshacer.',
    );
    if (!confirmado || !mounted) return;

    setState(() => _eliminandoId = u.id);
    try {
      await _api.eliminar(_recurso, u.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Usuario eliminado');
      await _cargar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        await mostrarEliminacionBloqueada(context, e);
      } else if (e.statusCode == 404) {
        mostrarMensaje(context, 'El usuario ya no existe.', error: true);
        await _cargar(silencioso: true);
      } else {
        mostrarMensaje(context, e.mensaje, error: true);
      }
    } finally {
      if (mounted) setState(() => _eliminandoId = null);
    }
  }

  void _limpiarBusqueda() {
    _busqueda.clear();
    setState(() => _consulta = '');
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _usuarios.where((u) => u.coincide(_consulta)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCS - Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargando ? null : () => _cargar(),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LateralTi(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminEncabezado(
                        titulo: 'Gestión de usuarios',
                        descripcion:
                            'Consulta, crea, edita y elimina las cuentas de coordinadores, gestores, creadores de oportunidades y técnicos.',
                        icono: Icons.people_alt_outlined,
                        etiquetaCrear: 'Nuevo usuario',
                        onCrear: () => _abrirFormulario(),
                        controladorBusqueda: _busqueda,
                        hintBusqueda: 'Buscar por nombre o correo',
                        onBuscar: (v) => setState(() => _consulta = v),
                      ),
                      const SizedBox(height: 12),
                      if (!_cargando && _error == null && _usuarios.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '${filtrados.length} de ${_usuarios.length} usuarios',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AdminEstilos.textoSecundario(context),
                            ),
                          ),
                        ),
                      Expanded(child: _cuerpo(filtrados)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo(List<UsuarioAdmin> filtrados) {
    if (_cargando) {
      return const AdminCargando(mensaje: 'Cargando usuarios…');
    }
    if (_error != null) {
      return AdminError(error: _error!, onReintentar: () => _cargar());
    }
    if (_usuarios.isEmpty) {
      return AdminVacio(
        icono: Icons.people_outline,
        titulo: 'Aún no hay usuarios registrados',
        mensaje: 'Crea el primero con el botón "Nuevo usuario".',
        etiquetaCrear: 'Nuevo usuario',
        onCrear: () => _abrirFormulario(),
      );
    }
    if (filtrados.isEmpty) {
      return AdminSinResultados(
        consulta: _consulta.trim(),
        onLimpiar: _limpiarBusqueda,
      );
    }

    final ocupado = _eliminandoId != null;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtrados.length,
      itemBuilder: (context, i) {
        final u = filtrados[i];
        return AdminTarjeta(
          titulo: u.titulo,
          subtitulo: u.email.isEmpty ? null : u.email,
          icono: Icons.person_outline,
          datos: [
            if (u.nombreCompleto.isNotEmpty && u.username.isNotEmpty)
              AdminDato('Usuario: ${u.username}', icono: Icons.alternate_email),
          ],
          etiquetas: [if (u.rolEtiqueta.isNotEmpty) u.rolEtiqueta],
          tooltipEditar: 'Editar usuario',
          tooltipEliminar: 'Eliminar usuario',
          onEditar: ocupado ? null : () => _abrirFormulario(u),
          onEliminar: ocupado ? null : () => _eliminar(u),
        );
      },
    );
  }
}
