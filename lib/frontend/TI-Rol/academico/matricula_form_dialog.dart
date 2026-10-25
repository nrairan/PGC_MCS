import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Crear o editar una matrícula (edición si `matricula != null`).
/// El estudiante y la asignatura se eligen entre registros reales de la API.
/// Si la API rechaza la operación (pareja repetida, más de 8 por semestre,
/// etc.), el formulario sigue abierto con los datos escritos.
class MatriculaFormDialog extends StatefulWidget {
  final MatriculaAdmin? matricula;

  const MatriculaFormDialog({super.key, this.matricula});

  @override
  State<MatriculaFormDialog> createState() => _MatriculaFormDialogState();
}

class _MatriculaFormDialogState extends State<MatriculaFormDialog> {
  static const Map<String, String> _etiquetas = {
    'estudiante': 'Estudiante',
    'asignatura': 'Asignatura',
    'semestre': 'Semestre',
    'non_field_errors': 'Matrícula',
  };

  final _service = const AcademicoAdminService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _semestre;
  int? _estudiante;
  int? _asignatura;
  List<UsuarioAdmin> _estudiantes = const [];
  List<NucleoAdmin> _nucleos = const [];
  bool _cargandoOpciones = true;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.matricula != null;

  @override
  void initState() {
    super.initState();
    final m = widget.matricula;
    _semestre = TextEditingController(text: m?.semestre ?? '');
    _estudiante = m?.estudianteId;
    _asignatura = m?.asignaturaId;
    _cargarOpciones();
  }

  @override
  void dispose() {
    _semestre.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    try {
      final r = await Future.wait<Object>([
        _service.estudiantes(),
        _service.nucleos(),
      ]);
      if (!mounted) return;
      setState(() {
        _estudiantes = r[0] as List<UsuarioAdmin>;
        _nucleos = r[1] as List<NucleoAdmin>;
        _cargandoOpciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoOpciones = false;
        _error =
            'No se pudieron cargar los estudiantes y asignaturas: ${mensajeDeError(e)}';
      });
    }
  }

  /// Campos a enviar. En edición solo viajan los que cambiaron.
  Map<String, dynamic> _datos() {
    final m = widget.matricula;
    final d = <String, dynamic>{};
    final semestre = _semestre.text.trim();
    if (!_esEdicion || _estudiante != m!.estudianteId) {
      d['estudiante'] = _estudiante;
    }
    if (!_esEdicion || _asignatura != m!.asignaturaId) {
      d['asignatura'] = _asignatura;
    }
    if (!_esEdicion || semestre != m!.semestre) d['semestre'] = semestre;
    return d;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final datos = _datos();
    if (_esEdicion && datos.isEmpty) {
      setState(() => _error = 'No hay cambios para guardar.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (_esEdicion) {
        await _service.api.actualizar(
            AcademicoAdminService.recursoMatriculas, widget.matricula!.id, datos);
      } else {
        await _service.api.crear(AcademicoAdminService.recursoMatriculas, datos);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = mensajeDeApi(e, _etiquetas);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar la matrícula. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libre = !_guardando;
    final opcionesListas = libre && !_cargandoOpciones;
    return AdminFormulario(
      titulo: _esEdicion ? 'Editar matrícula' : 'Nueva matrícula',
      descripcion: _esEdicion
          ? 'Modifica el estudiante, la asignatura o el semestre.'
          : 'Inscribe a un estudiante en una asignatura.',
      icono: Icons.how_to_reg_outlined,
      esEdicion: _esEdicion,
      formKey: _formKey,
      errorGeneral: _error,
      guardando: _guardando,
      onGuardar: _guardar,
      textoGuardar: _esEdicion ? 'Guardar cambios' : 'Crear matrícula',
      campos: [
        AdminSelector<int>(
          valor: _estudiante,
          etiqueta: 'Estudiante',
          obligatorio: true,
          icono: Icons.person_outline,
          hint: _cargandoOpciones ? 'Cargando estudiantes…' : null,
          ayuda: (!_cargandoOpciones && _estudiantes.isEmpty)
              ? 'No hay estudiantes registrados. Crea uno en Usuarios.'
              : null,
          opciones: [
            for (final u in _estudiantes)
              AdminOpcion<int>(
                u.id,
                u.email.isEmpty ? u.titulo : '${u.titulo} (${u.email})',
              ),
          ],
          onChanged:
              opcionesListas ? (v) => setState(() => _estudiante = v) : null,
        ),
        AdminSelector<int>(
          valor: _asignatura,
          etiqueta: 'Asignatura (núcleo temático)',
          obligatorio: true,
          icono: Icons.menu_book_outlined,
          hint: _cargandoOpciones ? 'Cargando asignaturas…' : null,
          ayuda: (!_cargandoOpciones && _nucleos.isEmpty)
              ? 'No hay núcleos temáticos registrados. Crea uno en Núcleos temáticos.'
              : null,
          opciones: [
            for (final n in _nucleos)
              AdminOpcion<int>(n.id, '${n.nombre} (${n.codigo})'),
          ],
          onChanged:
              opcionesListas ? (v) => setState(() => _asignatura = v) : null,
        ),
        AdminCampoTexto(
          controller: _semestre,
          etiqueta: 'Semestre',
          obligatorio: true,
          hint: 'Ej. 1',
          ayuda: 'Máximo 10 caracteres.',
          icono: Icons.calendar_month_outlined,
          habilitado: libre,
          validador: (v) => v.length > 10 ? 'Máximo 10 caracteres' : null,
        ),
      ],
    );
  }
}
