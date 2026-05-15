// lib/frontend/widgets/chat_fab.dart
//
// Botón flotante reutilizable que abre el chatbot desde CUALQUIER pantalla.
// Úsalo agregando `floatingActionButton: const ChatFab()` en un Scaffold.
//
// Ejemplo en HorariosScreen:
//   Scaffold(
//     appBar: AppBar(title: Text('Horarios')),
//     floatingActionButton: const ChatFab(),   // ← añadir esta línea
//     body: ...
//   )

import 'package:flutter/material.dart';
import 'package:mcs/frontend/barraLateral/chat.dart';

class ChatFab extends StatelessWidget {
  const ChatFab({super.key});

  static const Color _green700 = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: _green700,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.smart_toy_rounded),
      label: const Text('AsistUC'),
      tooltip: 'Abrir asistente virtual',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ChatScreen(),
            settings: const RouteSettings(name: 'ChatScreen'),
          ),
        );
      },
    );
  }
}
