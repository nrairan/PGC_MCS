import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';

/// Programa del coordinador (solo lectura).
///
/// Muestra únicamente el programa que la API asigna al usuario autenticado:
/// no hay lista de programas ni selector para cambiar de programa.
class ProgramaCoordinadorScreen extends StatefulWidget {
  final AcademicoAdminService servicio;

  const ProgramaCoordinadorScreen({
    super.key,
    this.servicio = const AcademicoAdminService(),
  });

  @override
  State<ProgramaCoordinadorScreen> createState() =>
      _ProgramaCoordinadorScreenState();
}

class _ProgramaCoordinadorScreenState extends State<ProgramaCoordinadorScreen> {
  List<ProgramaAdmin> _programas = const [];
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final programas = await widget.servicio.programas();
      if (!mounted) return;
      setState(() {
        _programas = programas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCS - Mi programa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MenuLateral(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AdminEncabezado(
                        titulo: 'Mi programa',
                        descripcion:
                            'Programa académico que tienes asignado como coordinador.',
                        icono: Icons.school_outlined,
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _cuerpo()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const AdminCargando(mensaje: 'Consultando tu programa…');
    }
    if (_error != null) {
      return AdminError(error: _error!, onReintentar: _cargar);
    }
    if (_programas.isEmpty) {
      return const AdminVacio(
        icono: Icons.school_outlined,
        titulo: 'No tienes un programa asignado',
        mensaje: 'Tu usuario aún no es coordinador de ningún programa. '
            'Solicita a TI que te lo asigne para ver sus núcleos y horarios.',
      );
    }
    return ListView(
      children: [
        for (final p in _programas)
          AdminTarjeta(
            titulo: p.nombre,
            subtitulo: p.codigo.isEmpty ? null : 'Código: ${p.codigo}',
            icono: Icons.school_outlined,
            datos: [
              if ((p.coordinadorNombre ?? '').isNotEmpty)
                AdminDato('Coordinador: ${p.coordinadorNombre}',
                    icono: Icons.supervisor_account_outlined),
            ],
          ),
      ],
    );
  }
}
