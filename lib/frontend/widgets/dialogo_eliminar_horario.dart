import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart'
    show AdminBannerError, AdminEstilos;

/// Pide confirmación antes de eliminar un horario y ejecuta la eliminación
/// dentro del propio diálogo, de modo que mientras la solicitud está en curso
/// se muestra un indicador y los botones quedan bloqueados (sin solicitudes
/// duplicadas).
///
/// Devuelve `true` solo si la API confirmó la eliminación; `null` si el
/// usuario canceló. Si la API rechaza la operación, el diálogo permanece abierto
/// con el motivo y la tarjeta no se toca.
///
/// `onEliminar` envía el DELETE y devuelve `null` si tuvo éxito o el mensaje de
/// error que debe mostrarse.
Future<bool?> mostrarDialogoEliminarHorario(
  BuildContext context, {
  required String asignatura,
  required String dia,
  required String horaInicio,
  required String horaFin,
  required Future<String?> Function() onEliminar,
  String? salon,
  String? gestor,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DialogoEliminarHorario(
      asignatura: asignatura,
      dia: dia,
      horaInicio: horaInicio,
      horaFin: horaFin,
      salon: salon,
      gestor: gestor,
      onEliminar: onEliminar,
    ),
  );
}

class DialogoEliminarHorario extends StatefulWidget {
  final String asignatura;
  final String dia;
  final String horaInicio;
  final String horaFin;
  final String? salon;
  final String? gestor;
  final Future<String?> Function() onEliminar;

  const DialogoEliminarHorario({
    super.key,
    required this.asignatura,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.onEliminar,
    this.salon,
    this.gestor,
  });

  @override
  State<DialogoEliminarHorario> createState() => _DialogoEliminarHorarioState();
}

class _DialogoEliminarHorarioState extends State<DialogoEliminarHorario> {
  bool _eliminando = false;
  String? _error;

  Future<void> _confirmar() async {
    if (_eliminando) return; // evita solicitudes duplicadas
    setState(() {
      _eliminando = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.onEliminar();
    } catch (_) {
      error = 'No se pudo eliminar el horario. Intenta de nuevo.';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _eliminando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final secundario = AdminEstilos.textoSecundario(context);
    return PopScope(
      canPop: !_eliminando,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AdminEstilos.peligro),
            SizedBox(width: 10),
            Expanded(child: Text('Eliminar horario')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  AdminBannerError(mensaje: _error!),
                  const SizedBox(height: 12),
                ],
                const Text('¿Seguro que deseas eliminar esta clase?'),
                const SizedBox(height: 10),
                Text(
                  widget.asignatura,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _Dato(Icons.calendar_today_outlined, widget.dia),
                _Dato(Icons.schedule,
                    '${widget.horaInicio} – ${widget.horaFin}'),
                if (widget.salon != null)
                  _Dato(Icons.room_outlined, 'Salón ${widget.salon}'),
                if (widget.gestor != null)
                  _Dato(Icons.person_outline, widget.gestor!),
                const SizedBox(height: 10),
                Text(
                  'Se liberarán el salón y la franja horaria. '
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 13, color: secundario),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed:
                _eliminando ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: _eliminando ? null : _confirmar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminEstilos.peligro,
              foregroundColor: Colors.white,
            ),
            icon: _eliminando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(_eliminando ? 'Eliminando…' : 'Eliminar horario'),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    final color = AdminEstilos.textoSecundario(context);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
