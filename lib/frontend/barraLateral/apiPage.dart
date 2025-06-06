import 'package:flutter/material.dart';
// import 'formulario_docente.dart'; // Importa tus formularios
// import 'formulario_estudiante.dart';
// import 'formulario_asignatura.dart';

class ApiPage extends StatelessWidget {
  const ApiPage({super.key});

  void _mostrarDialogoDeModelos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Agregar Docente'),
              onTap: () {
                // Navigator.pop(context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => FormularioDocente()),
                // );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Agregar Estudiante'),
              onTap: () {
                // Navigator.pop(context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => FormularioEstudiante()),
                // );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Agregar Asignatura'),
              onTap: () {
                // Navigator.pop(context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => FormularioAsignatura()),
                // );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión API')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar en la API'),
              onPressed: () => _mostrarDialogoDeModelos(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Ver contenido de la API'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ver contenido presionado')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
