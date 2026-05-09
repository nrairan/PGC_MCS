import 'package:flutter/material.dart';

import 'package:mcs/backend/resultados_api/usuarios_list.dart';
import 'package:mcs/backend/resultados_api/asignaturas_list.dart';
import 'package:mcs/backend/resultados_api/programas_list.dart';
import 'package:mcs/frontend/TI-Rol/ayudas/salonesList.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({super.key});

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'MCS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),

            const Spacer(),
            // --- Campo de búsqueda ---
            SizedBox(
              width: 450,
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar nucleos tematicos, gestores o salones',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Cuenta',
            onPressed: () {
              // Aquí luego puedes abrir una página de perfil o configuración
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opcion no disponible. Intenta mas tarde.'),
                ),
              );
            },
          ),
        ],
      ),

      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const MenuLateral(),

          Expanded(
            child: Padding(padding: const EdgeInsetsGeometry.all( 16.0 ),
              child: ListView(
                children: [
                    const Text(
                      'Panel de Coordinación',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                  const SizedBox(height: 20),
                  const Text('Resumen'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Tarjetas
                      _buildCard(
                        'Horarios completados',
                        'Sin datos',
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildCard(
                        'Horarios por completar',
                        'Sin datos',
                        Colors.blue,
                        Icons.schedule,
                      ),
                      _buildCard(
                        'Cruces de horarios',
                        'Sin datos',
                        Colors.red,
                        Icons.warning,
                      ),
                    ],
                  ),
                
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.people),
                          label: const Text('Ver Usuarios'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UsuariosListPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.book),
                          label: const Text('Ver Nucleos tematicos'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AsignaturasListPage(),
                              ),
                            );
                          },
                        ),

                      ],
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.meeting_room),
                          label: const Text('Ver Salones'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SalonesListPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.school),
                          label: const Text('Ver Programas'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProgramasListPage(),
                              ),
                            );
                          },
                        ),
                      ],

                      
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Grafica_Bloque1.png',
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 180),
                    Image.asset(
                      'assets/images/Grafica_Bloque2.png',
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
