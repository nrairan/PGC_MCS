import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Crear o editar un programa (edición si `programa != null`).
/// El coordinador se elige entre los usuarios con rol Coordinador.
class ProgramaFormDialog extends StatefulWidget {
  final ProgramaAdmin? programa;

  const ProgramaFormDialog({super.key, this.programa});

  @override
  State<ProgramaFormDialog> createState() => _ProgramaFormDialogState();
}

class _ProgramaFormDialogState extends State<ProgramaFormDialog> {
  static const Map<String, String> _etiquetas = {
    'nombre': 'Nombre',
    'codigo': 'Código',
    'coordinador': 'Coordinador',
  };

  final _service = const AcademicoAdminService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  int? _coordinador;
  List<UsuarioAdmin> _coordinadores = const [];
  bool _cargandoOpciones = true;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.programa != null;

  @override
  void initState() {
    super.initState();
    final p = widget.programa;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _codigo = TextEditingController(text: p?.codigo ?? '');
    _coordinador = p?.coordinadorId;
    _cargarOpciones();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    try {
      final lista = await _service.coordinadores();
      if (!mounted) return;
      setState(() {
        _coordinadores = lista;
        _cargandoOpciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoOpciones = false;
        _error = 'No se pudieron cargar los coordinadores: ${mensajeDeError(e)}';
      });
    }
  }

  String? _validarCodigo(String v) {
    if (v.length > 20) return 'Máximo 20 caracteres';
    if (!RegExp(r'^[\p{L}\p{N}]+$', unicode: true).hasMatch(v)) {
      return 'El código debe ser alfanumérico (sin espacios ni símbolos)';
    }
    return null;
  }

  Map<String, dynamic> _datos() {
    final p = widget.programa;
    final d = <String, dynamic>{};
    final nombre = _nombre.text.trim();
    final codigo = _codigo.text.trim();
    if (!_esEdicion || nombre != p!.nombre) d['nombre'] = nombre;
    if (!_esEdicion || codigo != p!.codigo) d['codigo'] = codigo;
    if (!_esEdicion || _coordinador != p!.coordinadorId) {
      d['coordinador'] = _coordinador;
    }
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
            AcademicoAdminService.recursoProgramas, widget.programa!.id, datos);
      } else {
        await _service.api.crear(AcademicoAdminService.recursoProgramas, datos);
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
        _error = 'No se pudo guardar el programa. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libre = !_guardando;
    return AdminFormulario(
      titulo: _esEdicion ? 'Editar programa' : 'Nuevo programa',
      descripcion: _esEdicion
          ? 'Modifica los datos del programa académico.'
          : 'Registra un programa y asígnale su coordinador.',
      icono: Icons.school_outlined,
      esEdicion: _esEdicion,
      formKey: _formKey,
      errorGeneral: _error,
      guardando: _guardando,
      onGuardar: _guardar,
      textoGuardar: _esEdicion ? 'Guardar cambios' : 'Crear programa',
      campos: [
        AdminCampoTexto(
          controller: _nombre,
          etiqueta: 'Nombre del programa',
          obligatorio: true,
          icono: Icons.school_outlined,
          habilitado: libre,
          validador: (v) => v.length > 100 ? 'Máximo 100 caracteres' : null,
        ),
        AdminCampoTexto(
          controller: _codigo,
          etiqueta: 'Código',
          obligatorio: true,
          hint: 'Ej. ISC',
          ayuda: 'Solo letras y números. Debe ser único.',
          icono: Icons.tag,
          habilitado: libre,
          validador: _validarCodigo,
        ),
        AdminSelector<int>(
          valor: _coordinador,
          etiqueta: 'Coordinador',
          obligatorio: true,
          icono: Icons.person_outline,
          hint: _cargandoOpciones ? 'Cargando coordinadores…' : null,
          ayuda: (!_cargandoOpciones && _coordinadores.isEmpty)
              ? 'No hay coordinadores registrados. Crea uno en Usuarios.'
              : null,
          opciones: [
            for (final u in _coordinadores)
              AdminOpcion<int>(
                u.id,
                u.email.isEmpty ? u.titulo : '${u.titulo} (${u.email})',
              ),
          ],
          onChanged: (libre && !_cargandoOpciones)
              ? (v) => setState(() => _coordinador = v)
              : null,
        ),
      ],
    );
  }
}
