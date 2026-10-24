import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/frontend/widgets/admin/admin_estilos.dart';

/// Texto legible para cualquier error capturado al llamar a la API.
String mensajeDeError(Object error) =>
    error is ApiException ? error.mensaje : 'Ocurrió un error inesperado.';

/// Muestra un aviso breve (SnackBar). `error: true` lo pinta en rojo.
void mostrarMensaje(BuildContext context, String mensaje,
    {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? AdminEstilos.peligro : AdminEstilos.verde,
      ),
    );
}

/// Estado: cargando datos.
class AdminCargando extends StatelessWidget {
  final String mensaje;

  const AdminCargando({super.key, this.mensaje = 'Cargando…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AdminEstilos.verde),
          const SizedBox(height: 14),
          Text(mensaje,
              style: TextStyle(color: AdminEstilos.textoSecundario(context))),
        ],
      ),
    );
  }
}

class _EstadoBase extends StatelessWidget {
  final IconData icono;
  final Color? color;
  final String titulo;
  final String? mensaje;
  final List<Widget> acciones;

  const _EstadoBase({
    required this.icono,
    required this.titulo,
    this.color,
    this.mensaje,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminEstilos.verde;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: c.withValues(alpha: 0.1),
                child: Icon(icono, color: c, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: c,
                ),
              ),
              if (mensaje != null) ...[
                const SizedBox(height: 6),
                Text(
                  mensaje!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminEstilos.textoSecundario(context),
                  ),
                ),
              ],
              if (acciones.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...acciones,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado: la lista no tiene registros todavía.
class AdminVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? etiquetaCrear;
  final VoidCallback? onCrear;

  const AdminVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.etiquetaCrear,
    this.onCrear,
  });

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: icono,
      titulo: titulo,
      mensaje: mensaje,
      acciones: [
        if (onCrear != null && etiquetaCrear != null)
          ElevatedButton.icon(
            onPressed: onCrear,
            icon: const Icon(Icons.add),
            label: Text(etiquetaCrear!),
            style: AdminEstilos.botonPrincipal(),
          ),
      ],
    );
  }
}

/// Estado: hay registros, pero ninguno coincide con la búsqueda o el filtro.
class AdminSinResultados extends StatelessWidget {
  final String consulta;
  final VoidCallback? onLimpiar;

  const AdminSinResultados({super.key, this.consulta = '', this.onLimpiar});

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: Icons.search_off,
      titulo: 'Sin resultados',
      mensaje: consulta.isEmpty
          ? 'Ningún registro coincide con los filtros aplicados.'
          : 'Ningún registro coincide con "$consulta".',
      acciones: [
        if (onLimpiar != null)
          OutlinedButton.icon(
            onPressed: onLimpiar,
            icon: const Icon(Icons.close),
            label: const Text('Limpiar búsqueda'),
          ),
      ],
    );
  }
}

/// Estado: error al cargar. Distingue falta de conexión de un error de la API.
class AdminError extends StatelessWidget {
  final Object error;
  final VoidCallback? onReintentar;

  const AdminError({super.key, required this.error, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final e = error;
    final conexion = e is ApiException && e.esConexion;
    final codigo = e is ApiException ? e.statusCode : null;

    return _EstadoBase(
      icono: conexion ? Icons.wifi_off : Icons.error_outline,
      color: AdminEstilos.peligro,
      titulo: conexion
          ? 'Sin conexión con el servidor'
          : 'La API devolvió un error${codigo != null ? ' ($codigo)' : ''}',
      mensaje: mensajeDeError(error),
      acciones: [
        if (onReintentar != null)
          ElevatedButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: AdminEstilos.botonPrincipal(),
          ),
      ],
    );
  }
}

/// Aviso de error dentro de un formulario o panel (no ocupa toda la pantalla).
class AdminBannerError extends StatelessWidget {
  final String mensaje;

  const AdminBannerError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF5350)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: AdminEstilos.peligro, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB71C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ventana de confirmación antes de eliminar (RNF005).
///
/// Devuelve `true` solo si el usuario confirma explícitamente.
Future<bool> confirmarEliminacion(
  BuildContext context, {
  required String nombre,
  String titulo = 'Confirmar eliminación',
  String? advertencia,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Icon(Icons.delete_outline, color: AdminEstilos.peligro),
          const SizedBox(width: 10),
          Expanded(child: Text(titulo)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Seguro que deseas eliminar "$nombre"?'),
            const SizedBox(height: 8),
            Text(
              advertencia ?? 'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 13,
                color: AdminEstilos.textoSecundario(ctx),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminEstilos.peligro,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
  return confirmado == true;
}

/// Informa que la API bloqueó la eliminación por registros asociados (409).
Future<void> mostrarEliminacionBloqueada(
    BuildContext context, ApiException error) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.block, color: AdminEstilos.peligro),
          SizedBox(width: 10),
          Expanded(child: Text('No se puede eliminar')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(error.mensaje),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: AdminEstilos.botonPrincipal(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
