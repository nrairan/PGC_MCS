import 'package:flutter/material.dart';
import '../widgets/admin_card.dart';

class AdminCrudScreen extends StatefulWidget {
  final String titulo;
  final Future<List<dynamic>> Function() fetchRecords;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function(String id) onDelete;
  final Widget Function(Map<String, dynamic>? record, Function(Map<String, dynamic>) onSaveForm) formBuilder;

  const AdminCrudScreen({
    Key? key, required this.titulo, required this.fetchRecords, required this.onSave, required this.onDelete, required this.formBuilder,
  }) : super(key: key);

  @override
  _AdminCrudScreenState createState() => _AdminCrudScreenState();
}

class _AdminCrudScreenState extends State<AdminCrudScreen> {
  List<dynamic> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      records = await widget.fetchRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openForm([Map<String, dynamic>? record]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: widget.formBuilder(record, (formData) async {
          Navigator.pop(ctx);
          setState(() => isLoading = true);
          await widget.onSave(formData);
          _loadData();
        }),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Está seguro de que desea eliminar este registro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoading = true);
              try {
                await widget.onDelete(id);
                _loadData();
              } catch (e) {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restricción: $e')));
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: const Color(0xFF2D6A4F), // Verde institucional
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _openForm()),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? const Center(child: Text("No existen registros."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final item = records[i];
                    return AdminCard(
                      title: item['nombre'] ?? item['nombres'] ?? 'Sin nombre',
                      subtitle1: item['correo'] ?? item['codigo'] ?? item['rol'] ?? 'N/A',
                      subtitle2: item['capacidad'] != null ? 'Capacidad: ${item['capacidad']}' : (item['edificio'] ?? '---'),
                      onEdit: () => _openForm(item),
                      onDelete: () => _confirmDelete(item['id'].toString()),
                    );
                  },
                ),
    );
  }
}