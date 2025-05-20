import 'package:flutter/material.dart';

class Notificaciones extends StatelessWidget{
  const Notificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //AppBar
      appBar: AppBar(
        title: Center(child: const Text('Notificaciones')),
      ),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 10), // Espacio entre icono y texto
            Text(
              'Sin notificaciones',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}