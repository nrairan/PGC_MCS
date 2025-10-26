import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalonesListPage extends StatefulWidget {
  const SalonesListPage({super.key});

  @override
  State<SalonesListPage> createState() => _SalonesListPageState();
}

class _SalonesListPageState extends State<SalonesListPage> {
  List<dynamic> salones = [];
  bool loading = true;

  Future<void> fetchSalones() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/salones/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        salones = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener salones: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSalones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salones registrados')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: salones.length,
                itemBuilder: (context, index) {
                  final salon = salones[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.meeting_room_outlined),
                      title: Text(salon['codigo'] ?? 'Sin código'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capacidad: ${salon['capacidad'] ?? 'No especificada'}',
                          ),
                          Text(
                            'Edificio: ${salon['edificio'] ?? 'No registrado'}',
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
