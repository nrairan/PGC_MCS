import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/admin/admin_estilos.dart';

/// Línea secundaria de una [AdminTarjeta]: texto con icono opcional.
class AdminDato {
  final String texto;
  final IconData? icono;

  const AdminDato(this.texto, {this.icono});
}

/// Tarjeta horizontal para mostrar un registro con acciones a la derecha.
///
/// No asume ningún campo: cada entidad entrega su `titulo`, un `subtitulo`
/// opcional, líneas de `datos` y `etiquetas` (chips). Si `onEditar` u
/// `onEliminar` son null, el botón correspondiente no se muestra.
class AdminTarjeta extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<AdminDato> datos;
  final List<String> etiquetas;
  final IconData? icono;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final String tooltipEditar;
  final String tooltipEliminar;

  const AdminTarjeta({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.datos = const [],
    this.etiquetas = const [],
    this.icono,
    this.onEditar,
    this.onEliminar,
    this.tooltipEditar = 'Editar',
    this.tooltipEliminar = 'Eliminar',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secundario = AdminEstilos.textoSecundario(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: AdminEstilos.verde),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icono != null) ...[
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AdminEstilos.verde.withValues(alpha: 0.1),
                        child: Icon(icono, color: AdminEstilos.verde, size: 20),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitulo!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: secundario),
                            ),
                          ],
                          if (datos.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                for (final d in datos) _FilaDato(dato: d),
                              ],
                            ),
                          ],
                          if (etiquetas.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final e in etiquetas) _Etiqueta(texto: e),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onEditar != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: tooltipEditar,
                        onPressed: onEditar,
                      ),
                    if (onEliminar != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AdminEstilos.peligro,
                        ),
                        tooltip: tooltipEliminar,
                        onPressed: onEliminar,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final AdminDato dato;

  const _FilaDato({required this.dato});

  @override
  Widget build(BuildContext context) {
    final color = AdminEstilos.textoSecundario(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dato.icono != null) ...[
          Icon(dato.icono, size: 14, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            dato.texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: color),
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AdminEstilos.verde.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AdminEstilos.verde,
        ),
      ),
    );
  }
}
