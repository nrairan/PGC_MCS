import 'package:flutter/material.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';

class HistorialTiScreen extends StatefulWidget {
  const HistorialTiScreen({super.key});

  @override
  State<HistorialTiScreen> createState() => _HistorialTiScreenState();
}

class _HistorialTiScreenState extends State<HistorialTiScreen> {
  final MetricasService _service = MetricasService();
  final ScrollController _scrollController = ScrollController();

  final List<ItemHistorial> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  String _filtroEntidad = 'TODAS';

  @override
  void initState() {
    super.initState();
    _cargarPrimeraPagina();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasNextPage) {
      _cargarSiguientePagina();
    }
  }

  Future<void> _cargarPrimeraPagina() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _items.clear();
      _hasNextPage = true;
    });

    try {
      final res = await _service.fetchHistorialPaginado(
        page: 1,
        pageSize: _pageSize,
        rol: 'TI',
      );

      setState(() {
        _items.addAll(res.items);
        _hasNextPage = res.hasNextPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al consultar logs TI: $e')),
        );
      }
    }
  }

  Future<void> _cargarSiguientePagina() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final res = await _service.fetchHistorialPaginado(
        page: nextPage,
        pageSize: _pageSize,
        rol: 'TI',
      );

      setState(() {
        _currentPage = nextPage;
        _items.addAll(res.items);
        _hasNextPage = res.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  List<ItemHistorial> get _itemsFiltrados {
    if (_filtroEntidad == 'TODAS') return _items;
    return _items.where((i) {
      return i.entidad.toUpperCase().contains(_filtroEntidad.toUpperCase());
    }).toList();
  }

  Color _getColorForTipo(TipoAccionHistorial tipo) {
    switch (tipo) {
      case TipoAccionHistorial.creacion:
        return const Color(0xFF2E7D32);
      case TipoAccionHistorial.modificacion:
        return const Color(0xFF0288D1);
      case TipoAccionHistorial.eliminacion:
        return const Color(0xFFD32F2F);
      case TipoAccionHistorial.conflicto:
        return const Color(0xFFE65100);
      case TipoAccionHistorial.login:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData _getIconForTipo(TipoAccionHistorial tipo) {
    switch (tipo) {
      case TipoAccionHistorial.creacion:
        return Icons.person_add_outlined;
      case TipoAccionHistorial.modificacion:
        return Icons.build_circle_outlined;
      case TipoAccionHistorial.eliminacion:
        return Icons.delete_forever_outlined;
      case TipoAccionHistorial.conflicto:
        return Icons.warning_amber_rounded;
      case TipoAccionHistorial.login:
        return Icons.lock_clock_outlined;
    }
  }

  String _formatFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min:$s';
  }

  void _mostrarDetalleDialog(ItemHistorial item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getIconForTipo(item.tipo),
                color: _getColorForTipo(item.tipo),
              ),
              const SizedBox(width: 8),
              const Text('Registro de Auditoría'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow('ID Evento:', '#${item.id}'),
              _buildDialogRow('Usuario / Operador:', item.usuario),
              _buildDialogRow('Acción Ejecutada:', item.accion),
              _buildDialogRow('Módulo / Entidad:', item.entidad),
              _buildDialogRow('Timestamp:', _formatFecha(item.fecha)),
              const Divider(height: 20),
              const Text(
                'Detalle Técnico:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  item.detalle,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _itemsFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Auditoría'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Menú lateral exclusivo para el rol de TI
          const LateralTi(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historial de Auditoría y Logs TI',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Seguimiento a operaciones CRUD de usuarios, salones, seguridad y servidor',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar Logs'),
                        onPressed: _cargarPrimeraPagina,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Barra de Filtros
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('TODAS', 'Todos los Módulos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Usuarios', 'Módulo Usuarios'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Salones', 'Módulo Salones'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Seguridad', 'Seguridad y Auth'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Sistema', 'Servicios / Red'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista con Infinite Scroll
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtrados.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shield_outlined,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No hay registros de auditoría para este módulo',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _cargarPrimeraPagina,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: filtrados.length + (_hasNextPage ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == filtrados.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                                        child: Center(
                                          child: _isLoadingMore
                                              ? const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text('Recuperando logs adicionales...'),
                                                  ],
                                                )
                                              : const Text(
                                                  'Fin del registro de auditoría',
                                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                                ),
                                        ),
                                      );
                                    }

                                    final item = filtrados[index];
                                    final color = _getColorForTipo(item.tipo);
                                    final icon = _getIconForTipo(item.tipo);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        onTap: () => _mostrarDetalleDialog(item),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: color.withValues(alpha: 0.12),
                                          radius: 20,
                                          child: Icon(icon, color: color, size: 22),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.accion,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.entidad,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              item.detalle,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.badge_outlined,
                                                    size: 13, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.usuario,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Icon(Icons.schedule,
                                                    size: 13, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatFecha(item.fecha),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filtroEntidad == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _filtroEntidad = key;
          });
        }
      },
      selectedColor: const Color(0xFF1B5E20),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
