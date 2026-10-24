import 'package:flutter/material.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';
import 'package:mcs/frontend/TI-Rol/funciones/registros.dart';
import 'package:mcs/frontend/TI-Rol/funciones/graficas.dart';
import 'package:mcs/frontend/pantallas_historial/historial_ti_screen.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';
import 'package:mcs/frontend/widgets/graficos/graficos_ti.dart';
import 'package:mcs/frontend/widgets/ultimos_cambios_widget.dart';

class PanelTI extends StatefulWidget {
  const PanelTI({super.key});

  @override
  State<PanelTI> createState() => _PanelTIState();
}

class _PanelTIState extends State<PanelTI> {
  final MetricasService _metricasService = MetricasService();
  late Future<List<RolUsuarioMetrica>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _futureUsuarios = _metricasService.fetchUsuariosPorRol();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text('MCS - Panel TI'),
      ),

      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const LateralTi(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text(
                    'Panel de Administración TI',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Estado del sistema'),

                  const SizedBox(height: 20),

                  // 🔹 CARDS
                  FutureBuilder<List<RolUsuarioMetrica>>(
                    future: _futureUsuarios,
                    builder: (context, snapshot) {
                      final totalUsuarios = snapshot.hasData
                          ? snapshot.data!.fold(0, (sum, item) => sum + item.total).toString()
                          : 'Sin datos';

                      return Row(
                        children: [
                          _buildCard(
                            'Sistema',
                            'En desarrollo',
                            Colors.yellow[700]!,
                            Icons.check_circle,
                          ),
                          _buildCard(
                            'Usuarios registrados',
                            totalUsuarios,
                            Colors.blue,
                            Icons.people,
                          ),
                          _buildCard(
                            'Errores',
                            'Sin datos',
                            Colors.orange,
                            Icons.warning,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🔹 BOTONES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.people),
                        label: const Text('Ver registros'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrosScreen(),
                            ),
                          );
                        },
                      ),

                      _actionButton('Graficos', Icons.bar_chart, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const graficasScreen(),
                          ),
                        );
                      }),
                      _actionButton('Logs', Icons.list, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistorialTiScreen(),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 GRAFICAS
                  const Row(
                    children: [
                      Expanded(child: GraficoUsuariosPorRol()),
                      SizedBox(width: 8),
                      Expanded(child: GraficoSalonesPorEdificio()),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const GraficoActividadSemanal(),

                  const SizedBox(height: 20),

                  // 🔹 LOGS
                  const Text(
                    'Actividad reciente',
                    style: TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 10),

                  UltimosCambiosWidget(
                    rol: 'TI',
                    onVerTodo: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistorialTiScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 CARD
  Widget _buildCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(title),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 BOTONES
  Widget _actionButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[900],
      ),
    );
  }
}
