import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';
import 'package:mcs/frontend/widgets/menu_lateral.dart';
import 'package:mcs/frontend/widgets/programa_coordinador_banner.dart';

/// Núcleos temáticos (asignaturas) del programa del coordinador (solo lectura).
///
/// La API devuelve únicamente las asignaturas del programa asignado al usuario
/// autenticado; la pantalla no filtra ni permite cambiar de programa.
class NucleosCoordinadorScreen extends StatefulWidget {
  final AcademicoAdminService servicio;

  const NucleosCoordinadorScreen({
    super.key,
    this.servicio = const AcademicoAdminService(),
  });

  @override
  State<NucleosCoordinadorScreen> createState() =>
      _NucleosCoordinadorScreenState();
}

class _NucleosCoordinadorScreenState extends State<NucleosCoordinadorScreen> {
  final _busqueda = TextEditingController();
  List<NucleoAdmin> _nucleos = const [];
  bool _cargando = true;
  bool? _sinPrograma; // null mientras no se conoce
  Object? _error;
  String _consulta = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final nucleos = await widget.servicio.nucleos();
      if (!mounted) return;
      setState(() {
        _nucleos = nucleos;
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
    final filtrados = _nucleos.where((n) => n.coincide(_consulta)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCS - Núcleos temáticos'),
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
                      AdminEncabezado(
                        titulo: 'Núcleos temáticos',
                        descripcion:
                            'Asignaturas de tu programa, con su carga semanal y gestores.',
                        icono: Icons.book_outlined,
                        controladorBusqueda: _busqueda,
                        hintBusqueda: 'Buscar por nombre, código o gestor',
                        onBuscar: (v) => setState(() => _consulta = v),
                      ),
                      const SizedBox(height: 8),
                      ProgramaCoordinadorBanner(
                        servicio: widget.servicio,
                        onCargado: (p) => setState(() => _sinPrograma = p.isEmpty),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _cuerpo(filtrados)),
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

  Widget _cuerpo(List<NucleoAdmin> filtrados) {
    if (_cargando) {
      return const AdminCargando(mensaje: 'Cargando núcleos temáticos…');
    }
    if (_error != null) {
      return AdminError(error: _error!, onReintentar: _cargar);
    }
    if (_sinPrograma == true) {
      return const AdminVacio(
        icono: Icons.warning_amber_rounded,
        titulo: 'Sin programa asignado',
        mensaje: 'No hay núcleos temáticos para mostrar porque tu usuario '
            'no tiene un programa asignado.',
      );
    }
    if (_nucleos.isEmpty) {
      return const AdminVacio(
        icono: Icons.book_outlined,
        titulo: 'Tu programa aún no tiene núcleos temáticos',
        mensaje: 'Cuando TI registre asignaturas para tu programa aparecerán aquí.',
      );
    }
    if (filtrados.isEmpty) {
      return AdminSinResultados(
        consulta: _consulta.trim(),
        onLimpiar: () {
          _busqueda.clear();
          setState(() => _consulta = '');
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtrados.length,
      itemBuilder: (context, i) {
        final n = filtrados[i];
        return AdminTarjeta(
          titulo: n.nombre.isEmpty ? n.codigo : n.nombre,
          subtitulo: n.codigo.isEmpty ? null : 'Código: ${n.codigo}',
          icono: Icons.book_outlined,
          datos: [
            AdminDato(
              n.horasSemana > 0
                  ? '${n.creditos ?? '-'} créditos · ${n.horasSemana} h por semana'
                  : '${n.creditos ?? '-'} créditos · horas por semana sin definir',
              icono: Icons.schedule_outlined,
            ),
            if (n.gestoresNombres.isNotEmpty)
              AdminDato('Gestores: ${n.gestoresNombres.join(', ')}',
                  icono: Icons.person_outline),
          ],
          etiquetas: [
            if (n.semestre.isNotEmpty) 'Semestre ${n.semestre}',
            if (n.requiereSalaComputo) 'Sala de cómputo',
          ],
        );
      },
    );
  }
}
