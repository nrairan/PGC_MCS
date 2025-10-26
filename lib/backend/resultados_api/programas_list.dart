import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProgramasListPage extends StatefulWidget {
  const ProgramasListPage({super.key});

  @override
  State<ProgramasListPage> createState() => _ProgramasListPageState();
}

class _ProgramasListPageState extends State<ProgramasListPage> {
  List<dynamic> programas = [];
  bool loading = true;

  Future<void> fetchProgramas() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/programa/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        programas = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener programas: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProgramas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programas registrados')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : programas.isEmpty
              ? const Center(
                child: Text(
                  'No hay programas registrados.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: programas.length,
                itemBuilder: (context, index) {
                  final programa = programas[index];

                  // Extraer datos del programa
                  final nombre = programa['nombre'] ?? 'Sin nombre';
                  final codigo = programa['codigo'] ?? 'Sin código';
                  final coordinador =
                      programa['coordinador'] ?? 'Sin coordinador';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(
                        Icons.school,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Código: $codigo'),
                          Text('Coordinador ID: $coordinador'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
