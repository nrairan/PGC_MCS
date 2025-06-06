import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart';

class ApiHorarioPage extends StatefulWidget {
  final HorarioService service;

  const ApiHorarioPage({super.key, required this.service});

  @override
  State<ApiHorarioPage> createState() => _ApiHorarioPageState();
}

class _ApiHorarioPageState extends State<ApiHorarioPage> {
  late Future<List<dynamic>> _horariosFuture;

  @override
  void initState() {
    super.initState();
    _horariosFuture = widget.service.getHorarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horarios API')),
      body: FutureBuilder(
        future: _horariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final horarios = snapshot.data ?? [];
          return _buildHorariosList(horarios);
        },
      ),
    );
  }

  Widget _buildHorariosList(List<dynamic> horarios) {
    return ListView.builder(
      itemCount: horarios.length,
      itemBuilder: (context, index) {
        final horario = horarios[index];
        return ListTile(
          title: Text(horario['materia']?.toString() ?? 'Sin nombre'),
          subtitle: Text(horario['hora']?.toString() ?? 'Sin hora definida'),
        );
      },
    );
  }
}
