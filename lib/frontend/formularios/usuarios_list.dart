import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsuariosListPage extends StatefulWidget {
  const UsuariosListPage({super.key});

  @override
  State<UsuariosListPage> createState() => _UsuariosListPageState();
}

class _UsuariosListPageState extends State<UsuariosListPage> {
  List<dynamic> usuarios = [];
  bool loading = true;

  Future<void> fetchUsuarios() async {
    final response = await http.get(
      Uri.parse('http://10.157.17.53:8000/api/usuarios/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        usuarios = json.decode(response.body);
        loading = false;
      });
    } else {
      // Manejo de error
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener usuarios: ${response.statusCode}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios registrados')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  return ListTile(
                    title: Text(usuario['nombre'] ?? 'Sin nombre'),
                    subtitle: Text('Email: ${usuario['email'] ?? 'Sin email'}'),
                  );
                },
              ),
    );
  }
}
