import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Importa tus pantallas
import 'package:mcs/frontend/barraLateral/api.dart'; // GC
import 'package:mcs/frontend/TI-Rol/ti.dart';  // TI

class Login extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const Login({super.key, required this.onToggleTheme});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    setState(() => loading = false);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': emailController.text,
        'password': passwordController.text,
      }),
    );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['access'];

        // 🔥 SEGUNDA PETICIÓN
        final userResponse = await http.get(
          Uri.parse('http://127.0.0.1:8000/api/usuarios/'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        final users = jsonDecode(userResponse.body);

        // ⚠️ Buscar usuario (ejemplo básico)
        final user = users.firstWhere(
          (u) => u['username'] == emailController.text,
        );

        String rol = user['rol'];

      if (rol == 'CO') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ApiPage()),
        );
      } else if (rol == 'TI') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PanelTI()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol no autorizado')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('MCS'))),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // EMAIL
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              // BOTÓN LOGIN
              ElevatedButton(
                onPressed: loading ? null : login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 20),
              const Text("¿Problemas para iniciar sesión? Describe tu problema a ejemplo@ucundinamarca.edu.co."),
            ],
          ),
        ),
      ),
    );
  }
}