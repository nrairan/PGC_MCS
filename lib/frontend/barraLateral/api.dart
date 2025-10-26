import 'package:flutter/material.dart';

import 'package:mcs/backend/resultados_api/usuarios_list.dart';
import 'package:mcs/backend/resultados_api/asignaturas_list.dart';
import 'package:mcs/backend/resultados_api/programas_list.dart';
import 'package:mcs/backend/resultados_api/salones_list.dart';
import 'package:mcs/backend/resultados_api/matriculas_list.dart';
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
                  hintText: 'Buscar clases, profesores o salones',
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
                  content: Text('Sesión no iniciada. Intenta mas tarde.'),
                ),
              );
            },
          ),
        ],
      ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MenuLateral(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Image.asset(
                      'assets/images/banner-ubate.png',
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list),
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

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AsignaturasListPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Asignaturas'),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgramasListPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Programas'),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SalonesListPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Salones'),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MatriculasListPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Matriculas'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
