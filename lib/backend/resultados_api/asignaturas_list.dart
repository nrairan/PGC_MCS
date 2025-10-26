import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AsignaturasListPage extends StatefulWidget {
  const AsignaturasListPage({super.key});

  @override
  State<AsignaturasListPage> createState() => _AsignaturasListPageState();
}

class _AsignaturasListPageState extends State<AsignaturasListPage> {
  List<dynamic> asignaturas = [];
  bool loading = true;

  Future<void> fetchAsignaturas() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/asignaturas/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        asignaturas = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener asignaturas: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAsignaturas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignaturas registradas')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : asignaturas.isEmpty
              ? const Center(
                child: Text(
                  'No hay asignaturas registradas.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: asignaturas.length,
                itemBuilder: (context, index) {
                  final asignatura = asignaturas[index];

                  // Extraer campos esperados
                  final codigo = asignatura['codigo'] ?? 'Sin código';
                  final nombre = asignatura['nombre'] ?? 'Sin nombre';
                  final creditos = asignatura['creditos']?.toString() ?? '0';
                  final programa = asignatura['programa'] ?? 'Desconocido';

                  // Convertir lista de gestores a String
                  final gestores = asignatura['gestores'];
                  String gestoresText = 'Sin gestores';
                  if (gestores != null &&
                      gestores is List &&
                      gestores.isNotEmpty) {
                    gestoresText = gestores.join(', ');
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      title: Text('$codigo - $nombre'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Créditos: $creditos'),
                          Text('Programa ID: $programa'),
                          Text('Gestores: $gestoresText'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
