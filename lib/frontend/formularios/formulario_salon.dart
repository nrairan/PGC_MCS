import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalonForm extends StatefulWidget {
  const SalonForm({super.key});

  @override
  State<SalonForm> createState() => _SalonFormState();
}

class _SalonFormState extends State<SalonForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _rol = 'CO'; // Valor por defecto

  final String apiUrl =
      'http://127.0.0.1:8000/api/usuarios/'; // Asegúrate de que la URL coincida con tu endpoint real

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'rol': _rol,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado exitosamente')),
        );
        _formKey.currentState!.reset();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear usuario: ${response.body}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              DropdownButtonFormField<String>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'CO', child: Text('Coordinador')),
                  DropdownMenuItem(
                    value: 'GC',
                    child: Text('Gestor del Conocimiento'),
                  ),
                  DropdownMenuItem(value: 'ES', child: Text('Estudiante')),
                ],
                onChanged: (value) {
                  setState(() {
                    _rol = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar Usuario'),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
