import 'package:flutter/material.dart';
import 'package:mcs/backend/resultados_api/usuarios_list.dart';
import 'package:mcs/frontend/TI-Rol/funciones/registros.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';

class PanelTI extends StatelessWidget {
  const PanelTI({super.key});

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
          LateralTi(),

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
                  Row(
                    children: [
                      _buildCard(
                        'Sistema',
                        'En desarrollo',
                        Colors.yellow[700]!,
                        Icons.check_circle,
                      ),
                      _buildCard(
                        'Usuarios registrados',
                        'Sin datos',
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

                      _actionButton('Graficos', Icons.bar_chart),
                      _actionButton('Logs', Icons.list),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 GRAFICAS SIMULADAS
                  Row(
                    children: [
                      _chartBox('Grafica 1'),
                      _chartBox('Grafica 2'),
                      _chartBox('Grafica 3 '),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔹 LOGS
                  const Text(
                    'Actividad reciente',
                    style: TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 10),

                  _logItem('spAdmin creó usuario         24/05/2026 -- 08:30', Icons.check, Colors.green),
                  _logItem('pPerez cambio contraseña         20/05/2026 -- 17:35', Icons.password, Colors.red),
                  _logItem('Usuario eliminado         15/04/2026 -- 10:15', Icons.delete, Colors.orange),
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
          color: color.withOpacity(0.1),
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
  Widget _actionButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[900],
      ),
    );
  }

  // 🔹 GRAFICAS (simples)
  Widget _chartBox(String title) {
    return Expanded(
      child: Container(
        height: 150,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(title)),
      ),
    );
  }

  // 🔹 LOG ITEM
  Widget _logItem(String text, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text),
    );
  }
}