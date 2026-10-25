import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Crear o editar un núcleo temático (asignatura) (edición si `nucleo != null`).
/// El programa y los gestores se eligen entre registros reales de la API.
class NucleoFormDialog extends StatefulWidget {
  final NucleoAdmin? nucleo;

  const NucleoFormDialog({super.key, this.nucleo});

  @override
  State<NucleoFormDialog> createState() => _NucleoFormDialogState();
}

class _NucleoFormDialogState extends State<NucleoFormDialog> {
  static const Map<String, String> _etiquetas = {
    'codigo': 'Código',
    'nombre': 'Nombre',
    'programa': 'Programa',
    'creditos': 'Créditos',
    'horas_semana': 'Horas por semana',
    'semestre': 'Semestre',
    'gestores': 'Gestores',
    'requiere_sala_computo': 'Sala de cómputo',
  };

  /// Semestres del programa (el wizard de horarios usa 1 a 10).
  static final List<AdminOpcion<String>> _semestres = [
    const AdminOpcion<String>('', 'Sin semestre'),
    for (var i = 1; i <= 10; i++) AdminOpcion<String>('$i', 'Semestre $i'),
  ];

  final _service = const AcademicoAdminService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _creditos;
  late final TextEditingController _horas;
  int? _programa;
  late String _semestre;
  late bool _requiere;
  late Set<int> _gestores;
  List<ProgramaAdmin> _programas = const [];
  List<UsuarioAdmin> _listaGestores = const [];
  bool _cargandoOpciones = true;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.nucleo != null;

  @override
  void initState() {
    super.initState();
    final n = widget.nucleo;
    _codigo = TextEditingController(text: n?.codigo ?? '');
    _nombre = TextEditingController(text: n?.nombre ?? '');
    _creditos = TextEditingController(text: n?.creditos?.toString() ?? '');
    _horas = TextEditingController(text: n == null ? '' : '${n.horasSemana}');
    _programa = n?.programaId;
    _semestre = (n != null && _semestres.any((o) => o.valor == n.semestre))
        ? n.semestre
        : '';
    _requiere = n?.requiereSalaComputo ?? false;
    _gestores = {...?n?.gestorIds};
    _cargarOpciones();
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _creditos.dispose();
    _horas.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    try {
      final r = await Future.wait<Object>([
        _service.programasOpciones(),
        _service.gestores(),
      ]);
      if (!mounted) return;
      setState(() {
        _programas = r[0] as List<ProgramaAdmin>;
        _listaGestores = r[1] as List<UsuarioAdmin>;
        _cargandoOpciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoOpciones = false;
        _error = 'No se pudieron cargar los programas y gestores: ${mensajeDeError(e)}';
      });
    }
  }

  // ── Validaciones (reflejan las del serializer de Django) ─────────────────

  String? _validarCreditos(String v) {
    final n = int.tryParse(v);
    if (n == null) return 'Debe ser un número entero';
    if (n < 1 || n > 6) return 'Los créditos deben estar entre 1 y 6';
    return null;
  }

  String? _validarHoras(String v) {
    final n = int.tryParse(v);
    if (n == null) return 'Debe ser un número entero';
    // Al crear el mínimo es 1; al editar se respeta lo que acepta la API.
    if (n < (_esEdicion ? 0 : 1)) return 'Indica al menos 1 hora por semana';
    if (n > 40) return 'Las horas por semana no pueden superar 40';
    return null;
  }

  /// Campos a enviar. En edición solo viajan los que cambiaron.
  Map<String, dynamic> _datos() {
    final n = widget.nucleo;
    final d = <String, dynamic>{};
    final codigo = _codigo.text.trim();
    final nombre = _nombre.text.trim();
    final creditos = int.parse(_creditos.text.trim());
    final horas = int.parse(_horas.text.trim());

    if (!_esEdicion || codigo != n!.codigo) d['codigo'] = codigo;
    if (!_esEdicion || nombre != n!.nombre) d['nombre'] = nombre;
    if (!_esEdicion || _programa != n!.programaId) d['programa'] = _programa;
    if (!_esEdicion || creditos != n!.creditos) d['creditos'] = creditos;
    if (!_esEdicion || horas != n!.horasSemana) d['horas_semana'] = horas;
    if (!_esEdicion || _requiere != n!.requiereSalaComputo) {
      d['requiere_sala_computo'] = _requiere;
    }
    if (_esEdicion ? _semestre != n!.semestre : _semestre.isNotEmpty) {
      d['semestre'] = _semestre;
    }
    final gestoresCambiaron =
        _esEdicion ? !setEquals(_gestores, n!.gestorIds.toSet()) : _gestores.isNotEmpty;
    if (gestoresCambiaron) d['gestores'] = _gestores.toList()..sort();
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
            AcademicoAdminService.recursoNucleos, widget.nucleo!.id, datos);
      } else {
        await _service.api.crear(AcademicoAdminService.recursoNucleos, datos);
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
        _error = 'No se pudo guardar el núcleo temático. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libre = !_guardando;
    final opcionesListas = libre && !_cargandoOpciones;
    return AdminFormulario(
      titulo: _esEdicion ? 'Editar núcleo temático' : 'Nuevo núcleo temático',
      descripcion: _esEdicion
          ? 'Modifica los datos del núcleo temático.'
          : 'Registra un núcleo temático asociado a un programa.',
      icono: Icons.menu_book_outlined,
      esEdicion: _esEdicion,
      formKey: _formKey,
      errorGeneral: _error,
      guardando: _guardando,
      onGuardar: _guardar,
      textoGuardar: _esEdicion ? 'Guardar cambios' : 'Crear núcleo',
      anchoMaximo: 600,
      campos: [
        AdminCampoTexto(
          controller: _codigo,
          etiqueta: 'Código',
          obligatorio: true,
          ayuda: 'Debe ser único.',
          icono: Icons.tag,
          habilitado: libre,
          validador: (v) => v.length > 20 ? 'Máximo 20 caracteres' : null,
        ),
        AdminCampoTexto(
          controller: _nombre,
          etiqueta: 'Nombre del núcleo temático',
          obligatorio: true,
          icono: Icons.menu_book_outlined,
          habilitado: libre,
          validador: (v) => v.length > 100 ? 'Máximo 100 caracteres' : null,
        ),
        AdminSelector<int>(
          valor: _programa,
          etiqueta: 'Programa',
          obligatorio: true,
          icono: Icons.school_outlined,
          hint: _cargandoOpciones ? 'Cargando programas…' : null,
          ayuda: (!_cargandoOpciones && _programas.isEmpty)
              ? 'No hay programas registrados. Crea uno en Programas.'
              : null,
          opciones: [
            for (final p in _programas)
              AdminOpcion<int>(p.id, '${p.nombre} (${p.codigo})'),
          ],
          onChanged: opcionesListas ? (v) => setState(() => _programa = v) : null,
        ),
        AdminSelector<String>(
          valor: _semestre,
          etiqueta: 'Semestre',
          icono: Icons.calendar_month_outlined,
          opciones: _semestres,
          onChanged: libre ? (v) => setState(() => _semestre = v ?? '') : null,
        ),
        AdminCampoTexto(
          controller: _creditos,
          etiqueta: 'Créditos',
          obligatorio: true,
          ayuda: 'Entre 1 y 6.',
          icono: Icons.numbers,
          teclado: TextInputType.number,
          habilitado: libre,
          validador: _validarCreditos,
        ),
        AdminCampoTexto(
          controller: _horas,
          etiqueta: 'Horas por semana',
          obligatorio: true,
          ayuda: 'Máximo 40.',
          icono: Icons.schedule,
          teclado: TextInputType.number,
          habilitado: libre,
          validador: _validarHoras,
        ),
        AdminInterruptor(
          titulo: 'Requiere sala de cómputo',
          subtitulo: 'Solo se programará en salones de tipo sala de cómputo.',
          valor: _requiere,
          onChanged: libre ? (v) => setState(() => _requiere = v) : null,
        ),
        AdminMultiSelector<int>(
          etiqueta: 'Gestores del conocimiento habilitados',
          mensajeVacio: _cargandoOpciones
              ? 'Cargando gestores…'
              : 'No hay gestores registrados. Crea uno en Usuarios.',
          opciones: [
            for (final u in _listaGestores) AdminOpcion<int>(u.id, u.titulo),
          ],
          seleccion: _gestores,
          onChanged: opcionesListas ? (s) => setState(() => _gestores = s) : null,
        ),
      ],
    );
  }
}
