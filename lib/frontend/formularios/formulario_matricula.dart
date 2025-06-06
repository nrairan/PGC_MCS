import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatriculaForm extends StatefulWidget {
  const MatriculaForm({super.key});

  @override
  State<MatriculaForm> createState() => _MatriculaFormState();
}

class _MatriculaFormState extends State<MatriculaForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRol = 'ES'; // Por defecto estudiante

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> usuarioData = {
        'username': _usernameController.text,
        'first_name': _nombreController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'rol': _selectedRol,
      };

      const url = 'http://<TU_IP>:8000/api/usuarios/'; // Reemplaza <TU_IP>

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(usuarioData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado exitosamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Usuario')),
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
                        value == null || value.isEmpty
                            ? 'Ingrese un usuario'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Ingrese el nombre'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Ingrese el correo';
                  if (!value.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator:
                    (value) =>
                        value != null && value.length >= 6
                            ? null
                            : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'CO', child: Text('Coordinador')),
                  DropdownMenuItem(
                    value: 'GC',
                    child: Text('Gestor de calidad'),
                  ),
                  DropdownMenuItem(value: 'ES', child: Text('Estudiante')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRol = value!;
                  });
                },
                validator:
                    (value) => value == null ? 'Seleccione un rol' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
