import 'package:flutter/material.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';

class UltimosCambiosWidget extends StatefulWidget {
  final String? rol;
  final VoidCallback? onVerTodo;

  const UltimosCambiosWidget({
    super.key,
    this.rol,
    this.onVerTodo,
  });

  @override
  State<UltimosCambiosWidget> createState() => _UltimosCambiosWidgetState();
}

class _UltimosCambiosWidgetState extends State<UltimosCambiosWidget> {
  final MetricasService _service = MetricasService();
  late Future<List<ItemHistorial>> _futureCambios;

  @override
  void initState() {
    super.initState();
    _cargarCambios();
  }

  void _cargarCambios() {
    setState(() {
      _futureCambios = _service.fetchUltimosCambios(limit: 5, rol: widget.rol);
    });
  }

  String _formatFecha(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return 'Hace $mins min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} d';
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m $h:$min';
    }
  }

  Widget _buildTipoBadge(TipoAccionHistorial tipo) {
    IconData icon;
    Color color;
    String label;

    switch (tipo) {
      case TipoAccionHistorial.creacion:
        icon = Icons.add_circle_outline;
        color = const Color(0xFF2E7D32);
        label = 'Creación';
        break;
      case TipoAccionHistorial.modificacion:
        icon = Icons.edit_outlined;
        color = const Color(0xFF1976D2);
        label = 'Edición';
        break;
      case TipoAccionHistorial.eliminacion:
        icon = Icons.delete_outline;
        color = const Color(0xFFC62828);
        label = 'Eliminación';
        break;
      case TipoAccionHistorial.conflicto:
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFD84315);
        label = 'Conflicto';
        break;
      case TipoAccionHistorial.login:
        icon = Icons.lock_outline;
        color = const Color(0xFF6A1B9A);
        label = 'Seguridad';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6433).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history_toggle_off,
                        color: Color(0xFF1A6433),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Últimos 5 Cambios del Sistema',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A6433),
                          ),
                        ),
                        Text(
                          'Registro de auditoría y operaciones recientes',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF1A6433)),
                      tooltip: 'Actualizar tabla',
                      onPressed: _cargarCambios,
                    ),
                    if (widget.onVerTodo != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.onVerTodo,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Ver historial completo'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1A6433),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ItemHistorial>>(
              future: _futureCambios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 30),
                          const SizedBox(height: 6),
                          Text('Error al cargar cambios: ${snapshot.error}'),
                        ],
                      ),
                    ),
                  );
                }

                final cambios = snapshot.data ?? [];
                if (cambios.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No hay registros recientes',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 700),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF1A6433).withValues(alpha: 0.06),
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A6433),
                        fontSize: 13,
                      ),
                      dataRowMaxHeight: 52,
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Usuario')),
                        DataColumn(label: Text('Acción')),
                        DataColumn(label: Text('Detalle')),
                        DataColumn(label: Text('Módulo')),
                        DataColumn(label: Text('Fecha / Hora')),
                      ],
                      rows: cambios.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(_buildTipoBadge(item.tipo)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF1A6433).withValues(alpha: 0.15),
                                    child: Text(
                                      item.usuario.isNotEmpty ? item.usuario[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A6433),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.usuario,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                item.accion,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 240),
                                child: Text(
                                  item.detalle,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.entidad,
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatFecha(item.fecha),
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
