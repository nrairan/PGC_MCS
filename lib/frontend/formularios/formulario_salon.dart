import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mcs/frontend/widgets/menu_lateral.dart';

class SalonForm extends StatefulWidget {
  const SalonForm({super.key});

  @override
  State<SalonForm> createState() => _SalonFormState();
}

class _SalonFormState extends State<SalonForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _capacidadController = TextEditingController();
  final TextEditingController _edificioController = TextEditingController();

  final String apiUrl = 'http://127.0.0.1:8000/api/salones/';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'codigo': _codigoController.text,
            'capacidad': int.parse(_capacidadController.text),
            'edificio': _edificioController.text,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salón creado exitosamente')),
          );
          _formKey.currentState!.reset();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear el salón: ${response.body}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión o formato inválido')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Salón')),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MenuLateral(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _codigoController,
                      decoration: const InputDecoration(
                        labelText: 'Código del aula',
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                    ),
                    TextFormField(
                      controller: _capacidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Capacidad'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Este campo es obligatorio';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Debe ser un número entero positivo';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _edificioController,
                      decoration: const InputDecoration(labelText: 'Edificio'),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Salón'),
                      onPressed: _submitForm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
