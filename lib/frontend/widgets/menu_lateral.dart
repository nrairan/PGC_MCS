import 'package:flutter/material.dart';
import 'package:mcs/frontend/formularios/formulario_usuario.dart';
import 'package:mcs/frontend/formularios/formulario_salon.dart';
import 'package:mcs/frontend/formularios/formulario_asignatura.dart';
import 'package:mcs/frontend/formularios/formulario_programa.dart';
import 'package:mcs/frontend/formularios/formulario_matricula.dart';
import 'package:mcs/frontend/barraLateral/api.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Navegación:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),

          _buildButton(context, Icons.home, 'General', const ApiPage()),
          _buildButton(
            context,
            Icons.person_add,
            'Nuevo Usuario',
            const UsuarioForm(),
          ),
          _buildButton(
            context,
            Icons.meeting_room,
            'Nuevo Salón',
            const SalonForm(),
          ),
          _buildButton(
            context,
            Icons.book,
            'Nueva Asignatura',
            const AsignaturaForm(),
          ),
          _buildButton(
            context,
            Icons.school,
            'Nuevo Programa',
            const ProgramaForm(),
          ),
          _buildButton(
            context,
            Icons.assignment,
            'Nueva Matrícula',
            const MatriculaForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    IconData icon,
    String text,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: () {
          // Si ya estás en la misma página, no hace nada:
          if (ModalRoute.of(context)?.settings.name !=
              page.runtimeType.toString()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => page,
                settings: RouteSettings(name: page.runtimeType.toString()),
              ),
            );
          }
        },
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}
