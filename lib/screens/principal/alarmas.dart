import 'package:flutter/material.dart';

class alarmas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción al presionar el botón
        },
        child: Icon(Icons.add),
        tooltip: 'Agregar alarma',
      ),
    );
  }
}