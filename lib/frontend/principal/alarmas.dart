import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Alarmas extends StatelessWidget {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController horaController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  void guardarAlarma(BuildContext context) async {
    final nombre = nombreController.text;
    final hora = horaController.text;
    final fecha = fechaController.text;
    final descripcion = descripcionController.text;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/add_alarma'),

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'hora': hora,
        'fecha': fecha,
        'descripcion': descripcion,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Alarma guardada")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: ${response.body}")),
      );
    }
  }

  void mostrarFormulario(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nueva alarma'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre')),
              TextField(controller: horaController, decoration: InputDecoration(labelText: 'Hora (HH:MM:SS)')),
              TextField(controller: fechaController, decoration: InputDecoration(labelText: 'Fecha (YYYY-MM-DD)')),
              TextField(controller: descripcionController, decoration: InputDecoration(labelText: 'Descripción')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              guardarAlarma(context);
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alarmas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarFormulario(context),
        child: Icon(Icons.add),
        tooltip: 'Agregar alarma',
      ),
    );
  }
}
