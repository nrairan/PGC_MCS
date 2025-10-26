import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatriculasListPage extends StatefulWidget {
  const MatriculasListPage({super.key});

  @override
  State<MatriculasListPage> createState() => _MatriculasListPageState();
}

class _MatriculasListPageState extends State<MatriculasListPage> {
  List<dynamic> matriculas = [];
  bool loading = true;

  Future<void> fetchMatriculas() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/matriculas/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        matriculas = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener matrículas: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMatriculas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrículas registradas')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: matriculas.length,
                itemBuilder: (context, index) {
                  final matricula = matriculas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.assignment_ind_outlined),
                      title: Text(
                        'Estudiante: ${matricula['estudiante_nombre'] ?? 'Sin nombre'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asignatura: ${matricula['asignatura_nombre'] ?? 'Sin nombre'}',
                          ),
                          Text(
                            'Semestre: ${matricula['semestre'] ?? 'No especificado'}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
