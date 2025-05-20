import 'package:flutter/material.dart';

class EcDiferencial extends StatelessWidget{
  const EcDiferencial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //AppBar
      appBar: AppBar(
        title: Center(child: const Text('Ecuaciones diferenciales')), 
      ),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 10), // Espacio entre icono y texto
            Text(
              'Aun no hay asignaciones',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}