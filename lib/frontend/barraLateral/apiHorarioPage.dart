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
    _loadHorarios();
  }

  Future<void> _loadHorarios() async {
    setState(() {
      _horariosFuture = widget.service.getHorarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios API'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHorarios),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _horariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error!);
          }

          final horarios = snapshot.data ?? [];
          if (horarios.isEmpty) {
            return _buildEmptyState();
          }

          return _buildHorariosList(horarios);
        },
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar horarios',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHorarios,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No hay horarios disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron horarios para mostrar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHorariosList(List<dynamic> horarios) {
    return ListView.separated(
      itemCount: horarios.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = horarios[index];

        // Validación de tipo para el elemento del horario
        if (item is! Map<String, dynamic>) {
          return ListTile(
            title: const Text('Formato de horario inválido'),
            leading: const Icon(Icons.warning, color: Colors.orange),
          );
        }

        return ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(
            item['materia']?.toString() ?? 'Materia no especificada',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            item['hora']?.toString() ?? 'Horario no especificado',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Aquí puedes añadir navegación a detalles si es necesario
          },
        );
      },
    );
  }
}
