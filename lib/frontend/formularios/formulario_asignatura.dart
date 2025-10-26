import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mcs/frontend/widgets/menu_lateral.dart';

class AsignaturaForm extends StatefulWidget {
  const AsignaturaForm({super.key});

  @override
  State<AsignaturaForm> createState() => _AsignaturaFormState();
}

class _AsignaturaFormState extends State<AsignaturaForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _creditosController = TextEditingController();

  int? _programaSeleccionado;
  List<int> _gestoresSeleccionados = [];

  List<dynamic> _programas = [];
  List<dynamic> _gestores = [];

  final String apiUrl = 'http://127.0.0.1:8000/api/asignaturas/';
  final String programasUrl = 'http://127.0.0.1:8000/api/programa/';
  final String gestoresUrl = 'http://127.0.0.1:8000/api/usuarios/?rol=GC';

  @override
  void initState() {
    super.initState();
    _cargarProgramas();
    _cargarGestores();
  }

  Future<void> _cargarProgramas() async {
    final response = await http.get(Uri.parse(programasUrl));
    if (response.statusCode == 200) {
      setState(() {
        _programas = json.decode(response.body);
      });
    }
  }

  Future<void> _cargarGestores() async {
    final response = await http.get(Uri.parse(gestoresUrl));
    if (response.statusCode == 200) {
      setState(() {
        _gestores = json.decode(response.body);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo': _codigoController.text,
          'nombre': _nombreController.text,
          'programa': _programaSeleccionado,
          'gestores': _gestoresSeleccionados,
          'creditos': int.parse(_creditosController.text),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asignatura creada exitosamente')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _programaSeleccionado = null;
          _gestoresSeleccionados = [];
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    }
  }

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Crear Asinatura',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),

            const Spacer(),
            // --- Campo de búsqueda ---
            SizedBox(
              width: 450,
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar clases, profesores o salones',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Cuenta',
            onPressed: () {
              // Aquí luego puedes abrir una página de perfil o configuración
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión no iniciada. Intenta mas tarde.'),
                ),
              );
            },
          ),
        ],
      ),

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
                      decoration: const InputDecoration(labelText: 'Código'),
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                    ),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                    ),
                    TextFormField(
                      controller: _creditosController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Créditos'),
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Programa'),
                      value: _programaSeleccionado,
                      items:
                          _programas.map<DropdownMenuItem<int>>((programa) {
                            return DropdownMenuItem<int>(
                              value: programa['id'],
                              child: Text(programa['nombre']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _programaSeleccionado = value;
                        });
                      },
                      validator:
                          (value) =>
                              value == null ? 'Selecciona un programa' : null,
                    ),
                    const SizedBox(height: 10),
                    const Text('Gestores (puedes seleccionar varios)'),
                    ..._gestores.map((gestor) {
                      return CheckboxListTile(
                        value: _gestoresSeleccionados.contains(gestor['id']),
                        title: Text(gestor['username']),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _gestoresSeleccionados.add(gestor['id']);
                            } else {
                              _gestoresSeleccionados.remove(gestor['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Asignatura'),
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
