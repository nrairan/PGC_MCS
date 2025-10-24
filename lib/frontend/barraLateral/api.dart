import 'package:flutter/material.dart';

import 'package:mcs/frontend/formularios/formulario_asignatura.dart';
import 'package:mcs/frontend/formularios/formulario_matricula.dart';
import 'package:mcs/frontend/formularios/formulario_programa.dart';
import 'package:mcs/frontend/formularios/formulario_salon.dart';
import 'package:mcs/frontend/formularios/formulario_usuario.dart';
import 'package:mcs/frontend/formularios/usuarios_list.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({super.key});

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  String? _selectedOption;
  final List<String> _options = [
    'Usuario',
    'Salon',
    'Asignatura',
    'Matricula',
    'Programa',
  ];

  final TextEditingController _searchController = TextEditingController();

  void _handleSelection(String? value) {
    setState(() {
      _selectedOption = value;
    });
  }

  void _navigateToForm() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una opción')),
      );
      return;
    }

    switch (_selectedOption) {
      case 'Usuario':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UsuarioForm()),
        );
        break;
      case 'Salon':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalonForm()),
        );
        break;
      case 'Asignatura':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AsignaturaForm()),
        );
        break;
      case 'Matricula':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatriculaForm()),
        );
        break;
      case 'Programa':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProgramaForm()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opción no válida')));
    }
  }

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
              width: 600,
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

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(70.0),
              child: Image.asset(
                'assets/images/banner-ubate.png',
                height: 300,
                fit: BoxFit.contain,
              ),
            ),

            DropdownButtonFormField<String>(
              value: _selectedOption,
              hint: const Text('Selecciona para registrar'),
              items:
                  _options
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
              onChanged: _handleSelection,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
              onPressed: _navigateToForm,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Ver contenido de la API'),
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
      ),
    );
  }
}
