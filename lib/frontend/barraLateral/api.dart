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
      appBar: AppBar(title: const Text('Gestión API')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
