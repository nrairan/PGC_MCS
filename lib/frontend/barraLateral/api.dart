import 'package:flutter/material.dart';

class ApiPage extends StatelessWidget {
  const ApiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión API')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar en la API'),
              onPressed: () {
                // Aquí puedes llamar a tu lógica para agregar datos a la API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agregar presionado')),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Ver contenido de la API'),
              onPressed: () {
                // Aquí puedes navegar o mostrar datos de la API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ver contenido presionado')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
