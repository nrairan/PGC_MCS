import 'package:flutter/material.dart';
import 'package:mcs/frontend/TI-Rol/ti.dart';
import 'package:mcs/frontend/pantallas_historial/historial_ti_screen.dart';
import 'package:mcs/frontend/TI-Rol/usuarios/usuarios_admin_screen.dart';
import 'package:mcs/frontend/TI-Rol/academico/nucleos_admin_screen.dart';
import 'package:mcs/frontend/TI-Rol/academico/programas_admin_screen.dart';
import 'package:mcs/frontend/TI-Rol/academico/salones_admin_screen.dart';
import 'package:mcs/frontend/login/login.dart';

class LateralTi extends StatelessWidget {
  const LateralTi({super.key});

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

          const Text(
            'CRUD:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),

          _buildButton(context, Icons.home, 'General', const PanelTI()),
          _buildButton(
            context,
            Icons.person_add,
            'Usuarios',
            const UsuariosAdminScreen(),
          ),
          _buildButton(
            context,
            Icons.meeting_room,
            'Salones',
            const SalonesAdminScreen(),
          ),
          _buildButton(
            context,
            Icons.school,
            'Programas',
            const ProgramasAdminScreen(),
          ),
          _buildButton(
            context,
            Icons.book,
            'Núcleos temáticos',
            const NucleosAdminScreen(),
          ),
          _buildButton(
            context,
            Icons.history,
            'Registros / Logs',
            const HistorialTiScreen(),
          ),

          const Spacer(),

          _buildButton(
            context,
            Icons.logout,
            'Cerrar Sesión',
            Login(onToggleTheme: () {}),
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
