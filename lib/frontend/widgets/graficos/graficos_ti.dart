import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. GRÁFICO CIRCULAR: Distribución de Usuarios por Rol (TI)
// ─────────────────────────────────────────────────────────────────────────────

class GraficoUsuariosPorRol extends StatefulWidget {
  const GraficoUsuariosPorRol({super.key});

  @override
  State<GraficoUsuariosPorRol> createState() => _GraficoUsuariosPorRolState();
}

class _GraficoUsuariosPorRolState extends State<GraficoUsuariosPorRol> {
  final MetricasService _service = MetricasService();
  late Future<List<RolUsuarioMetrica>> _futureRoles;
  int _touchedIndex = -1;

  final Map<String, Color> _coloresRol = {
    'CO': const Color(0xFF1B5E20), // Verde oscuro
    'GC': const Color(0xFF0288D1), // Azul
    'TI': const Color(0xFFF57C00), // Naranja
    'ES': const Color(0xFF7B1FA2), // Púrpura
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _futureRoles = _service.fetchUsuariosPorRol();
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
                        'Usuarios por Rol',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6433),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cuentas registradas en la base de datos',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF1A6433)),
                  tooltip: 'Actualizar',
                  onPressed: _cargarDatos,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 230,
              child: FutureBuilder<List<RolUsuarioMetrica>>(
                future: _futureRoles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('Sin usuarios registrados'));
                  }

                  final totalUsuarios = data.fold(0, (sum, item) => sum + item.total);

                  return Row(
                    children: [
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
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex =
                                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 38,
                            sections: List.generate(data.length, (i) {
                              final item = data[i];
                              final isTouched = i == _touchedIndex;
                              final radius = isTouched ? 50.0 : 42.0;
                              final color = _coloresRol[item.rol] ?? Colors.teal;

                              return PieChartSectionData(
                                color: color,
                                value: item.total.toDouble(),
                                title: '${item.total}',
                                radius: radius,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(data.length, (i) {
                            final item = data[i];
                            final color = _coloresRol[item.rol] ?? Colors.teal;
                            final pct = totalUsuarios > 0
                                ? ((item.total / totalUsuarios) * 100).round()
                                : 0;
                            final isSelected = i == _touchedIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${item.nombreRol}: ${item.total} ($pct%)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. GRÁFICO DE BARRAS: Salones y Capacidad por Edificio (TI)
// ─────────────────────────────────────────────────────────────────────────────

class GraficoSalonesPorEdificio extends StatefulWidget {
  const GraficoSalonesPorEdificio({super.key});

  @override
  State<GraficoSalonesPorEdificio> createState() => _GraficoSalonesPorEdificioState();
}

class _GraficoSalonesPorEdificioState extends State<GraficoSalonesPorEdificio> {
  final MetricasService _service = MetricasService();
  late Future<List<SalonEdificioMetrica>> _futureSalones;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _futureSalones = _service.fetchSalonesPorEdificio();
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
                        'Infraestructura: Salones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6433),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cantidad de aulas disponibles por bloque',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF1A6433)),
                  tooltip: 'Actualizar',
                  onPressed: _cargarDatos,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 230,
              child: FutureBuilder<List<SalonEdificioMetrica>>(
                future: _futureSalones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('Sin datos de infraestructura'));
                  }

                  final maxSalones = data
                      .map((e) => e.cantidadSalones.toDouble())
                      .fold(0.0, (prev, curr) => curr > prev ? curr : prev);
                  final adjustedMax = (maxSalones < 8) ? 10.0 : (maxSalones + 2).ceilToDouble();

                  return BarChart(
                    BarChartData(
                      maxY: adjustedMax,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF0F3E1E),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final edif = data[group.x.toInt()];
                            return BarTooltipItem(
                              '${edif.edificio}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: '${rod.toY.toInt()} salones • Cap: ~${edif.capacidadPromedio}p',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
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
                                final label = data[index].edificio.replaceAll('Bloque ', 'Blq ');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: _touchedIndex == index
                                          ? const Color(0xFF1A6433)
                                          : Colors.grey[700],
                                      fontWeight: _touchedIndex == index
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 11,
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
                            reservedSize: 28,
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
                        getDrawingHorizontalLine: (_) => FlLine(
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
                              toY: data[i].cantidadSalones.toDouble(),
                              color: isTouched
                                  ? const Color(0xFFF57C00)
                                  : const Color(0xFF1976D2),
                              width: 22,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: adjustedMax,
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
// 3. GRÁFICO DE LÍNEAS: Actividad del Sistema / Peticiones (TI)
// ─────────────────────────────────────────────────────────────────────────────

class GraficoActividadSemanal extends StatefulWidget {
  const GraficoActividadSemanal({super.key});

  @override
  State<GraficoActividadSemanal> createState() => _GraficoActividadSemanalState();
}

class _GraficoActividadSemanalState extends State<GraficoActividadSemanal> {
  // Puntos representativos de actividad del servidor (API hits / auditoría)
  final List<FlSpot> _spots = const [
    FlSpot(0, 12),
    FlSpot(1, 28),
    FlSpot(2, 45),
    FlSpot(3, 38),
    FlSpot(4, 52),
    FlSpot(5, 64),
    FlSpot(6, 40),
  ];

  final List<String> _dias = const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

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
                        'Tráfico y Auditoría del Sistema',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6433),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peticiones a la API registradas esta semana',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: Color(0xFF2E7D32), size: 16),
                      SizedBox(width: 4),
                      Text(
                        '+18% normal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 80,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.18),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= 0 && i < _dias.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _dias[i],
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1A6433),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dia = _dias[spot.x.toInt()];
                          return LineTooltipItem(
                            '$dia: ${spot.y.toInt()} peticiones',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF1A6433),
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: const Color(0xFF1A6433),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A6433).withValues(alpha: 0.3),
                            const Color(0xFF1A6433).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
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
