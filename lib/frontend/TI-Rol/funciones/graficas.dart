import 'package:flutter/material.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';

class graficasScreen extends StatelessWidget {
  const graficasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficas'),
      ),
      body: Row(
        children: [
          const MenuLateral(),

          Expanded(child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text("Aqui se mostrará los registros", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            )))
        ],
      ),
    );
  }
}