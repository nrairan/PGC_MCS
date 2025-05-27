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
            ListTile(
              title: const Text('WhatsApp:'),
              leading: const Icon(Icons.textsms_outlined),
            ),

            ListTile(
              title: const Text('Telefono:'),
              leading: const Icon(Icons.contact_phone_outlined),
            ),

            ListTile(
              title: const Text('Facebook'),
              leading: Icon(Icons.facebook),
            ),

            ListTile(
              title: const Text('Correo'),
              leading: const Icon(Icons.mail),
            )
          ],
      ),
    ),
    );
  }
}