import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. GRÁFICO DE BARRAS: Horarios programados por día (Lunes a Sábado)
// ─────────────────────────────────────────────────────────────────────────────

class GraficoHorariosPorDia extends StatefulWidget {
  final String semestre;
  const GraficoHorariosPorDia({super.key, this.semestre = '1'});

  @override
  State<GraficoHorariosPorDia> createState() => _GraficoHorariosPorDiaState();
}

class _GraficoHorariosPorDiaState extends State<GraficoHorariosPorDia> {
  final MetricasService _service = MetricasService();
  late Future<List<HorarioDiaMetrica>> _futureDatos;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void didUpdateWidget(covariant GraficoHorariosPorDia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semestre != widget.semestre) {
      _cargarDatos();
    }
  }

  void _cargarDatos() {
    setState(() {
      _futureDatos = _service.fetchHorariosPorDia(semestre: widget.semestre);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución Semanal de Clases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6433),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semestre ${widget.semestre} • Horarios asignados',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF1A6433)),
                  tooltip: 'Actualizar gráfico',
                  onPressed: _cargarDatos,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: FutureBuilder<List<HorarioDiaMetrica>>(
                future: _futureDatos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 36),
                          const SizedBox(height: 8),
                          Text('Error al cargar datos: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No hay datos de horarios disponibles'));
                  }

                  final maxY = data
                      .map((e) => e.cantidadClases.toDouble())
                      .fold(0.0, (prev, curr) => curr > prev ? curr : prev);
                  final adjustedMaxY = (maxY < 10) ? 12.0 : (maxY + 3).ceilToDouble();

                  return BarChart(
                    BarChartData(
                      maxY: adjustedMaxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1A6433),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final dia = data[group.x.toInt()].diaNombre;
                            return BarTooltipItem(
                              '$dia\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: '${rod.toY.toInt()} clases',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (FlTouchEvent event, barTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                barTouchResponse == null ||
                                barTouchResponse.spot == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    data[index].dia,
                                    style: TextStyle(
                                      color: _touchedIndex == index
                                          ? const Color(0xFF1A6433)
                                          : Colors.grey[700],
                                      fontWeight: _touchedIndex == index
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              if (value == value.roundToDouble() && value >= 0) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.18),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(data.length, (i) {
                        final isTouched = i == _touchedIndex;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].cantidadClases.toDouble(),
                              color: isTouched
                                  ? const Color(0xFF0F3E1E)
                                  : const Color(0xFF1A6433),
                              width: 22,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: adjustedMaxY,
                                color: Colors.grey.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. GRÁFICO CIRCULAR (DONUT): Estado de los Horarios (Completos, Pendientes, Conflictos)
// ─────────────────────────────────────────────────────────────────────────────

class GraficoEstadoHorarios extends StatefulWidget {
  const GraficoEstadoHorarios({super.key});

  @override
  State<GraficoEstadoHorarios> createState() => _GraficoEstadoHorariosState();
}

class _GraficoEstadoHorariosState extends State<GraficoEstadoHorarios> {
  final MetricasService _service = MetricasService();
  late Future<EstadoHorariosMetrica> _futureEstado;
  int _touchedSectionIndex = -1;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  void _cargarEstado() {
    setState(() {
      _futureEstado = _service.fetchEstadoHorarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado General de Horarios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6433),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progreso de asignación y cruces detectados',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF1A6433)),
                  tooltip: 'Actualizar estado',
                  onPressed: _cargarEstado,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: FutureBuilder<EstadoHorariosMetrica>(
                future: _futureEstado,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final metrica = snapshot.data ??
                      const EstadoHorariosMetrica(completados: 16, pendientes: 6, conConflictos: 2);
                  final total = metrica.total > 0 ? metrica.total : 1;

                  return Row(
                    children: [
                      // Donut Chart
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedSectionIndex = -1;
                                    return;
                                  }
                                  _touchedSectionIndex =
                                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: [
                              _buildSection(
                                index: 0,
                                value: metrica.completados.toDouble(),
                                total: total,
                                color: const Color(0xFF2E7D32), // Verde
                                title: '${metrica.completados}',
                              ),
                              _buildSection(
                                index: 1,
                                value: metrica.pendientes.toDouble(),
                                total: total,
                                color: const Color(0xFF1976D2), // Azul
                                title: '${metrica.pendientes}',
                              ),
                              _buildSection(
                                index: 2,
                                value: metrica.conConflictos.toDouble(),
                                total: total,
                                color: const Color(0xFFD32F2F), // Rojo
                                title: '${metrica.conConflictos}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Leyenda interactiva
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(
                              color: const Color(0xFF2E7D32),
                              label: 'Completos',
                              count: metrica.completados,
                              pct: ((metrica.completados / total) * 100).round(),
                              isSelected: _touchedSectionIndex == 0,
                            ),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                              color: const Color(0xFF1976D2),
                              label: 'Pendientes',
                              count: metrica.pendientes,
                              pct: ((metrica.pendientes / total) * 100).round(),
                              isSelected: _touchedSectionIndex == 1,
                            ),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                              color: const Color(0xFFD32F2F),
                              label: 'Conflictos',
                              count: metrica.conConflictos,
                              pct: ((metrica.conConflictos / total) * 100).round(),
                              isSelected: _touchedSectionIndex == 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildSection({
    required int index,
    required double value,
    required int total,
    required Color color,
    required String title,
  }) {
    final isTouched = index == _touchedSectionIndex;
    final radius = isTouched ? 55.0 : 45.0;
    final fontSize = isTouched ? 16.0 : 13.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: title,
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
    required int pct,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                Text(
                  '$count ($pct%)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
