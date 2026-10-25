import 'package:flutter/material.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Franja que indica a qué programa pertenece el coordinador autenticado.
///
/// El programa NO se elige ni se guarda en el cliente: se consulta
/// `GET /api/programa/`, que para un coordinador devuelve solo el programa que
/// tiene asignado. Si no tiene ninguno, muestra un aviso claro.
class ProgramaCoordinadorBanner extends StatefulWidget {
  final AcademicoAdminService servicio;

  /// Se invoca cuando termina la consulta con los programas asignados
  /// (lista vacía = sin programa asignado).
  final ValueChanged<List<ProgramaAdmin>>? onCargado;

  const ProgramaCoordinadorBanner({
    super.key,
    this.servicio = const AcademicoAdminService(),
    this.onCargado,
  });

  @override
  State<ProgramaCoordinadorBanner> createState() =>
      _ProgramaCoordinadorBannerState();
}

class _ProgramaCoordinadorBannerState extends State<ProgramaCoordinadorBanner> {
  List<ProgramaAdmin>? _programas;
  Object? _error;
  bool _cargando = true;

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
      final programas = await widget.servicio.programasOpciones();
      if (!mounted) return;
      setState(() {
        _programas = programas;
        _cargando = false;
      });
      widget.onCargado?.call(programas);
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
    if (_cargando) {
      return const _FranjaPrograma(
        icono: Icons.school_outlined,
        texto: 'Consultando tu programa…',
      );
    }
    if (_error != null) {
      return _FranjaPrograma(
        icono: Icons.error_outline,
        color: AdminEstilos.peligro,
        texto: 'No se pudo consultar tu programa: ${mensajeDeError(_error!)}',
        accion: TextButton(onPressed: _cargar, child: const Text('Reintentar')),
      );
    }
    final programas = _programas ?? const <ProgramaAdmin>[];
    if (programas.isEmpty) {
      return const _FranjaPrograma(
        icono: Icons.warning_amber_rounded,
        color: Color(0xFFE65100),
        texto: 'Tu usuario no tiene un programa asignado. No se mostrará '
            'información académica hasta que un administrador (TI) te asigne uno.',
      );
    }
    final etiqueta = programas.length == 1 ? 'Programa' : 'Programas';
    final nombres = programas
        .map((p) => p.codigo.isEmpty ? p.nombre : '${p.nombre} (${p.codigo})')
        .join(' · ');
    return _FranjaPrograma(
      icono: Icons.school_outlined,
      texto: '$etiqueta: $nombres',
      resaltar: true,
    );
  }
}

class _FranjaPrograma extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;
  final bool resaltar;
  final Widget? accion;

  const _FranjaPrograma({
    required this.icono,
    required this.texto,
    this.color,
    this.resaltar = false,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminEstilos.verde;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: c.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Icon(icono, color: c, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: resaltar ? FontWeight.w600 : FontWeight.normal,
                color: c,
              ),
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}
