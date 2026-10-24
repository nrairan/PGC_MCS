import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';

class RutaAprendizajeScreen extends StatelessWidget {
  const RutaAprendizajeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta de Aprendizaje'),
      ),
      body: Row(
        children: [
          const MenuLateral(),

          Expanded(child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text("Aqui se mostrará la ruta de aprendizaje", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            )))
        ],
      )
    );
  }
}