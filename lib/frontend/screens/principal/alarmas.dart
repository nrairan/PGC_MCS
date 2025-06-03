import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Alarmas extends StatelessWidget {
  Future<void> guardarAlarma() async {
    final url = Uri.parse('http://192.168.101.9/add_alarma');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': 'Despertar',
        'hora': '07:00:00',
        'descripcion': 'Clase de matemáticas',
        'fecha': '2025-06-03',
      }),
    );

    if (response.statusCode == 201) {
      print('✅ Alarma guardada con éxito');
    } else {
      print('❌ Error al guardar alarma: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          guardarAlarma(); // Llama la función
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Guardando alarma...')),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Agregar alarma',
      ),
    );
  }
}
