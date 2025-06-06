import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProgramaForm extends StatefulWidget {
  const ProgramaForm({super.key});

  @override
  State<ProgramaForm> createState() => _ProgramaFormState();
}

class _ProgramaFormState extends State<ProgramaForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  int? _selectedCoordinadorId;
  List<Map<String, dynamic>> _coordinadores = [];

  final String apiUrl = 'http://127.0.0.1:8000/api/programa/';
  final String coordinadoresUrl = 'http://127.0.0.1:8000/api/usuarios/?rol=CO';

  @override
  void initState() {
    super.initState();
    _fetchCoordinadores();
  }

  Future<void> _fetchCoordinadores() async {
    try {
      final response = await http.get(Uri.parse(coordinadoresUrl));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _coordinadores = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showMessage('Error cargando coordinadores');
      }
    } catch (e) {
      _showMessage('Error de conexión');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreController.text,
          'codigo': _codigoController.text,
          'coordinador': _selectedCoordinadorId,
        }),
      );

      if (response.statusCode == 201) {
        _showMessage('Programa registrado exitosamente');
        _formKey.currentState!.reset();
        setState(() {
          _selectedCoordinadorId = null;
        });
        Navigator.pop(context);
      } else {
        _showMessage('Error: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Programa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del programa',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código del programa',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Campo obligatorio'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCoordinadorId,
                items:
                    _coordinadores.map((user) {
                      return DropdownMenuItem<int>(
                        value: user['id'],
                        child: Text(
                          '${user['first_name']} ${user['last_name']}',
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCoordinadorId = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Coordinador'),
                validator:
                    (value) =>
                        value == null ? 'Seleccione un coordinador' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
