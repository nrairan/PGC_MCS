import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/frontend/widgets/admin/admin_encabezado.dart';
import 'package:mcs/frontend/widgets/admin/admin_estados.dart';
import 'package:mcs/frontend/widgets/admin/admin_estilos.dart';
import 'package:mcs/frontend/widgets/admin/admin_formulario.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';

/// Pantalla administrativa genérica del rol TI: menú lateral, encabezado con
/// búsqueda y botón de crear, lista de tarjetas y estados de carga, error,
/// vacío y sin resultados. Cada entidad aporta sus datos y su formulario.
///
/// Mantiene la misma estructura y comportamiento que la pantalla de usuarios.
class AdminCrudPagina<T> extends StatefulWidget {
  final String tituloBarra;
  final String titulo;
  final String descripcion;
  final IconData icono;
  final String etiquetaCrear;
  final String hintBusqueda;

  /// Plural para el contador ("3 de 10 programas").
  final String plural;
  final String tituloVacio;
  final String? mensajeVacio;
  final String tituloEliminar;
  final String mensajeCreado;
  final String mensajeActualizado;
  final String mensajeEliminado;
  final String mensajeYaNoExiste;

  /// Consulta los registros reales (puede combinar varios endpoints).
  final Future<List<T>> Function() cargar;
  final bool Function(T item, String consulta) coincide;

  /// Construye la tarjeta; los callbacks son null mientras hay una operación en curso.
  final Widget Function(T item, VoidCallback? onEditar, VoidCallback? onEliminar)
      tarjeta;

  /// Formulario en modo creación (`null`) o edición. Debe cerrarse con `true`
  /// solo cuando la API confirme el guardado.
  final Widget Function(T? item) formulario;

  /// Envía el DELETE. Debe lanzar [ApiException] si la API lo rechaza.
  final Future<void> Function(T item) eliminar;
  final String Function(T item) nombreEliminar;
  final String? Function(T item)? advertenciaEliminar;

  const AdminCrudPagina({
    super.key,
    required this.tituloBarra,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.etiquetaCrear,
    required this.hintBusqueda,
    required this.plural,
    required this.tituloVacio,
    required this.tituloEliminar,
    required this.mensajeCreado,
    required this.mensajeActualizado,
    required this.mensajeEliminado,
    required this.mensajeYaNoExiste,
    required this.cargar,
    required this.coincide,
    required this.tarjeta,
    required this.formulario,
    required this.eliminar,
    required this.nombreEliminar,
    this.mensajeVacio,
    this.advertenciaEliminar,
  });

  @override
  State<AdminCrudPagina<T>> createState() => _AdminCrudPaginaState<T>();
}

class _AdminCrudPaginaState<T> extends State<AdminCrudPagina<T>> {
  final _busqueda = TextEditingController();

  List<T> _items = <T>[];
  bool _cargando = true;
  Object? _error;
  String _consulta = '';
  bool _ocupado = false;

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

  /// Con `silencioso` no oculta la lista actual mientras recarga.
  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final lista = await widget.cargar();
      if (!mounted) return;
      setState(() {
        _items = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_items.isNotEmpty) {
        setState(() => _cargando = false);
        mostrarMensaje(
          context,
          'No se pudo actualizar la lista: ${mensajeDeError(e)}',
          error: true,
        );
      } else {
        setState(() {
          _cargando = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _abrirFormulario([T? item]) async {
    final guardado = await mostrarAdminFormulario(
      context,
      builder: (_) => widget.formulario(item),
    );
    if (guardado != true || !mounted) return;
    mostrarMensaje(
      context,
      item == null ? widget.mensajeCreado : widget.mensajeActualizado,
    );
    await _cargar(silencioso: true);
  }

  Future<void> _eliminar(T item) async {
    final confirmado = await confirmarEliminacion(
      context,
      titulo: widget.tituloEliminar,
      nombre: widget.nombreEliminar(item),
      advertencia: widget.advertenciaEliminar?.call(item),
    );
    if (!confirmado || !mounted) return;

    setState(() => _ocupado = true);
    try {
      await widget.eliminar(item);
      if (!mounted) return;
      mostrarMensaje(context, widget.mensajeEliminado);
      await _cargar(silencioso: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        await mostrarEliminacionBloqueada(context, e);
      } else if (e.statusCode == 404) {
        mostrarMensaje(context, widget.mensajeYaNoExiste, error: true);
        await _cargar(silencioso: true);
      } else {
        mostrarMensaje(context, e.mensaje, error: true);
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _limpiarBusqueda() {
    _busqueda.clear();
    setState(() => _consulta = '');
  }

  @override
  Widget build(BuildContext context) {
    final filtrados =
        _items.where((i) => widget.coincide(i, _consulta)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tituloBarra),
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
                        titulo: widget.titulo,
                        descripcion: widget.descripcion,
                        icono: widget.icono,
                        etiquetaCrear: widget.etiquetaCrear,
                        onCrear: () => _abrirFormulario(),
                        controladorBusqueda: _busqueda,
                        hintBusqueda: widget.hintBusqueda,
                        onBuscar: (v) => setState(() => _consulta = v),
                      ),
                      const SizedBox(height: 12),
                      if (!_cargando && _error == null && _items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '${filtrados.length} de ${_items.length} ${widget.plural}',
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

  Widget _cuerpo(List<T> filtrados) {
    if (_cargando) {
      return AdminCargando(mensaje: 'Cargando ${widget.plural}…');
    }
    if (_error != null) {
      return AdminError(error: _error!, onReintentar: () => _cargar());
    }
    if (_items.isEmpty) {
      return AdminVacio(
        icono: widget.icono,
        titulo: widget.tituloVacio,
        mensaje: widget.mensajeVacio ??
            'Crea el primero con el botón "${widget.etiquetaCrear}".',
        etiquetaCrear: widget.etiquetaCrear,
        onCrear: () => _abrirFormulario(),
      );
    }
    if (filtrados.isEmpty) {
      return AdminSinResultados(
        consulta: _consulta.trim(),
        onLimpiar: _limpiarBusqueda,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtrados.length,
      itemBuilder: (context, i) {
        final item = filtrados[i];
        return widget.tarjeta(
          item,
          _ocupado ? null : () => _abrirFormulario(item),
          _ocupado ? null : () => _eliminar(item),
        );
      },
    );
  }
}
