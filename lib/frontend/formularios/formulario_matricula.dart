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

  String? _semestre;
  int? _estudianteSeleccionado;
  int? _asignaturaSeleccionada;

  List<dynamic> _estudiantes = [];
  List<dynamic> _asignaturas = [];

  final String apiUrl = 'http://127.0.0.1:8000/api/matricula/';
  final String estudiantesUrl = 'http://127.0.0.1:8000/api/usuarios/?rol=ES';
  final String asignaturasUrl = 'http://127.0.0.1:8000/api/asignaturas/';

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
    _cargarAsignaturas();
  }

  Future<void> _cargarEstudiantes() async {
    final response = await http.get(Uri.parse(estudiantesUrl));
    if (response.statusCode == 200) {
      setState(() {
        _estudiantes = json.decode(response.body);
      });
    }
  }

  Future<void> _cargarAsignaturas() async {
    final response = await http.get(Uri.parse(asignaturasUrl));
    if (response.statusCode == 200) {
      setState(() {
        _asignaturas = json.decode(response.body);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estudiante': _estudianteSeleccionado,
          'asignatura': _asignaturaSeleccionada,
          'semestre': _semestre,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matrícula registrada exitosamente')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _estudianteSeleccionado = null;
          _asignaturaSeleccionada = null;
          _semestre = null;
        });
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
      appBar: AppBar(title: const Text('Registrar Matrícula')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Estudiante'),
                value: _estudianteSeleccionado,
                items:
                    _estudiantes.map<DropdownMenuItem<int>>((user) {
                      return DropdownMenuItem<int>(
                        value: user['id'],
                        child: Text(user['username']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _estudianteSeleccionado = value;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Selecciona un estudiante' : null,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Asignatura'),
                value: _asignaturaSeleccionada,
                items:
                    _asignaturas.map<DropdownMenuItem<int>>((asignatura) {
                      return DropdownMenuItem<int>(
                        value: asignatura['id'],
                        child: Text(
                          "${asignatura['codigo']} - ${asignatura['nombre']}",
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _asignaturaSeleccionada = value;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Selecciona una asignatura' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Semestre'),
                onChanged: (value) {
                  _semestre = value;
                },
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Registrar Matrícula'),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
