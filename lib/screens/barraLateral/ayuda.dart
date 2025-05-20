import 'package:flutter/material.dart';

class Ayuda extends StatelessWidget {
  const Ayuda({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //AppBar
      appBar: AppBar(
        title: Center(child: const Text('Ayuda')),
      ),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 10), // Espacio entre icono y texto
            Text(
              'Lo sentimos, no pudimos ayudarte.\nEsta opcion no se encuentra actualmente',
              style: TextStyle(fontSize: 18)
            ),
          ],
      ),
    ),
    );
  }
}