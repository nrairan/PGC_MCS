import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/admin/admin_estilos.dart';

/// Encabezado de una pantalla administrativa: título, descripción corta,
/// botón verde para crear y, opcionalmente, barra de búsqueda.
///
/// La barra de búsqueda solo aparece si se entrega `controladorBusqueda`.
class AdminEncabezado extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final String? etiquetaCrear;
  final VoidCallback? onCrear;
  final TextEditingController? controladorBusqueda;
  final String hintBusqueda;
  final ValueChanged<String>? onBuscar;

  const AdminEncabezado({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.etiquetaCrear,
    this.onCrear,
    this.controladorBusqueda,
    this.hintBusqueda = 'Buscar',
    this.onBuscar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mostrarCrear = onCrear != null && etiquetaCrear != null;

    final botonCrear = mostrarCrear
        ? ElevatedButton.icon(
            onPressed: onCrear,
            icon: const Icon(Icons.add),
            label: Text(etiquetaCrear!),
            style: AdminEstilos.botonPrincipal(),
          )
        : null;

    final cabecera = Row(
      children: [
        CircleAvatar(
          backgroundColor: AdminEstilos.verde.withValues(alpha: 0.1),
          child: Icon(icono, color: AdminEstilos.verde),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AdminEstilos.textoSecundario(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final estrecho = c.maxWidth < 560;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (estrecho || botonCrear == null) ...[
                  cabecera,
                  if (botonCrear != null) ...[
                    const SizedBox(height: 12),
                    botonCrear,
                  ],
                ] else
                  Row(
                    children: [
                      Expanded(child: cabecera),
                      const SizedBox(width: 16),
                      botonCrear,
                    ],
                  ),
                if (controladorBusqueda != null) ...[
                  const SizedBox(height: 14),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controladorBusqueda!,
                    builder: (context, value, _) => TextField(
                      controller: controladorBusqueda,
                      onChanged: onBuscar,
                      decoration: InputDecoration(
                        hintText: hintBusqueda,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  controladorBusqueda!.clear();
                                  onBuscar?.call('');
                                },
                              ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
