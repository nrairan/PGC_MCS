// lib/frontend/widgets/menu_lateral.dart
//
// MenuLateral actualizado con el botón "Asistente IA" (ChatScreen).
// Solo se añade el import y el botón — el resto es idéntico al original.

import 'package:flutter/material.dart';
import 'package:mcs/frontend/TI-Rol/ayudas/historial.dart';
import 'package:mcs/frontend/TI-Rol/horarios.dart';
import 'package:mcs/frontend/formularios/formulario_salon.dart';
import 'package:mcs/frontend/formularios/formulario_programa.dart';
import 'package:mcs/frontend/barraLateral/api.dart';
import 'package:mcs/frontend/login/login.dart';
import 'package:mcs/frontend/TI-Rol/ayudas/crearHorario.dart';
import 'package:mcs/frontend/TI-Rol/ayudas/salonesList.dart';
import 'package:mcs/frontend/TI-Rol/ayudas/ruta_aprendizaje.dart';

// ↓ NUEVO IMPORT — Chatbot AsistUC
import 'package:mcs/frontend/barraLateral/chat.dart';

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
          const Text("Uso rápido"),
          _buildButton(context, Icons.home, 'General', const ApiPage()),
          _buildButton(
            context,
            Icons.edit_calendar_rounded,
            'Crear horario',
            const CrearHorarioScreen(),
          ),
          _buildButton(
            context,
            Icons.calendar_month,
            'Horarios',
            const HorariosScreen(),
          ),

          const Text("Ayudas"),
          _buildButton(
            context,
            Icons.map,
            'Ruta de aprendizaje',
            const RutaAprendizajeScreen(),
          ),
          _buildButton(
            context,
            Icons.room_preferences_rounded,
            'Información de salones',
            const SalonesListPage(),
          ),
          _buildButton(
            context,
            Icons.schedule,
            'Historial',
            const HistorialScreen(),
          ),

          // ↓ NUEVO BOTÓN — Chatbot AsistUC
          const Divider(height: 20),
          const Text(
            "Asistente IA",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          _buildButton(
            context,
            Icons.smart_toy_rounded,
            'AsistUC — Chatbot',
            const ChatScreen(),
            highlight: true,           // botón destacado en verde oscuro
          ),

          const SizedBox(height: 170),
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
    Widget page, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        style: highlight
            ? ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
              )
            : null,
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
