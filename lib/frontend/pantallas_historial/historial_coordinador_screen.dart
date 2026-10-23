import 'package:flutter/material.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';

class HistorialCoordinadorScreen extends StatefulWidget {
  const HistorialCoordinadorScreen({super.key});

  @override
  State<HistorialCoordinadorScreen> createState() => _HistorialCoordinadorScreenState();
}

class _HistorialCoordinadorScreenState extends State<HistorialCoordinadorScreen> {
  final MetricasService _service = MetricasService();
  final ScrollController _scrollController = ScrollController();

  final List<ItemHistorial> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  String _filtroTipo = 'TODOS';

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
        rol: 'CO',
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
          SnackBar(content: Text('Error al cargar historial: $e')),
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
        rol: 'CO',
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
    if (_filtroTipo == 'TODOS') return _items;
    return _items.where((i) {
      if (_filtroTipo == 'CREACION') return i.tipo == TipoAccionHistorial.creacion;
      if (_filtroTipo == 'MODIFICACION') return i.tipo == TipoAccionHistorial.modificacion;
      if (_filtroTipo == 'CONFLICTO') return i.tipo == TipoAccionHistorial.conflicto;
      return true;
    }).toList();
  }

  Color _getColorForTipo(TipoAccionHistorial tipo) {
    switch (tipo) {
      case TipoAccionHistorial.creacion:
        return const Color(0xFF2E7D32);
      case TipoAccionHistorial.modificacion:
        return const Color(0xFF1976D2);
      case TipoAccionHistorial.eliminacion:
        return const Color(0xFFC62828);
      case TipoAccionHistorial.conflicto:
        return const Color(0xFFD84315);
      case TipoAccionHistorial.login:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData _getIconForTipo(TipoAccionHistorial tipo) {
    switch (tipo) {
      case TipoAccionHistorial.creacion:
        return Icons.add_circle_outline;
      case TipoAccionHistorial.modificacion:
        return Icons.edit_note;
      case TipoAccionHistorial.eliminacion:
        return Icons.delete_outline;
      case TipoAccionHistorial.conflicto:
        return Icons.warning_amber_rounded;
      case TipoAccionHistorial.login:
        return Icons.security;
    }
  }

  String _formatFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _itemsFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Horarios'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const MenuLateral(),
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
                              'Historial de Programación Académica',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Trazabilidad de asignación de horarios, gestores y resolución de cruces',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refrescar'),
                        onPressed: _cargarPrimeraPagina,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Barra de filtros por tipo
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('TODOS', 'Todos los eventos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('CREACION', 'Creaciones de Horario'),
                        const SizedBox(width: 8),
                        _buildFilterChip('MODIFICACION', 'Modificaciones / CAI'),
                        const SizedBox(width: 8),
                        _buildFilterChip('CONFLICTO', 'Conflictos Detectados'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista paginada con Infinite Scroll
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtrados.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history_toggle_off,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No se encontraron registros para este filtro',
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
                                                    Text('Cargando más eventos...'),
                                                  ],
                                                )
                                              : const Text(
                                                  'Has llegado al final del historial',
                                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                                ),
                                        ),
                                      );
                                    }

                                    final item = filtrados[index];
                                    final color = _getColorForTipo(item.tipo);
                                    final icon = _getIconForTipo(item.tipo);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: color.withValues(alpha: 0.12),
                                          radius: 22,
                                          child: Icon(icon, color: color, size: 24),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.accion,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.entidad,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[800],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 6),
                                            Text(
                                              item.detalle,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.person_outline,
                                                    size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.usuario,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Icon(Icons.access_time,
                                                    size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatFecha(item.fecha),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
    final isSelected = _filtroTipo == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _filtroTipo = key;
          });
        }
      },
      selectedColor: const Color(0xFF1A6433),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
