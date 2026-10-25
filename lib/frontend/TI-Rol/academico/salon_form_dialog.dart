import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart' show ApiException;
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/servicios/academico_admin_service.dart';
import 'package:mcs/frontend/widgets/admin/admin_widgets.dart';

/// Crear o editar un salón (edición si `salon != null`).
class SalonFormDialog extends StatefulWidget {
  final SalonAdmin? salon;

  const SalonFormDialog({super.key, this.salon});

  @override
  State<SalonFormDialog> createState() => _SalonFormDialogState();
}

class _SalonFormDialogState extends State<SalonFormDialog> {
  static const Map<String, String> _etiquetas = {
    'codigo': 'Código',
    'capacidad': 'Capacidad',
    'edificio': 'Edificio',
    'tipo': 'Tipo',
    'salon': 'Salón',
  };

  final _service = const AcademicoAdminService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _capacidad;
  late final TextEditingController _edificio;
  late String? _tipo;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.salon != null;

  @override
  void initState() {
    super.initState();
    final s = widget.salon;
    _codigo = TextEditingController(text: s?.codigo ?? '');
    _capacidad = TextEditingController(text: s?.capacidad?.toString() ?? '');
    _edificio = TextEditingController(text: s?.edificio ?? '');
    _tipo = (s != null && SalonAdmin.tipos.containsKey(s.tipo))
        ? s.tipo
        : (_esEdicion ? null : 'AULA');
  }

  @override
  void dispose() {
    _codigo.dispose();
    _capacidad.dispose();
    _edificio.dispose();
    super.dispose();
  }

  String? _validarCapacidad(String v) {
    final n = int.tryParse(v);
    if (n == null) return 'Debe ser un número entero';
    if (n < 10) return 'La capacidad mínima es 10';
    if (n > 32767) return 'Valor demasiado grande';
    return null;
  }

  Map<String, dynamic> _datos() {
    final s = widget.salon;
    final d = <String, dynamic>{};
    final codigo = _codigo.text.trim();
    final edificio = _edificio.text.trim();
    final capacidad = int.parse(_capacidad.text.trim());
    if (!_esEdicion || codigo != s!.codigo) d['codigo'] = codigo;
    if (!_esEdicion || capacidad != s!.capacidad) d['capacidad'] = capacidad;
    if (!_esEdicion || edificio != s!.edificio) d['edificio'] = edificio;
    if (!_esEdicion || _tipo != s!.tipo) d['tipo'] = _tipo;
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
            AcademicoAdminService.recursoSalones, widget.salon!.id, datos);
      } else {
        await _service.api.crear(AcademicoAdminService.recursoSalones, datos);
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
        _error = 'No se pudo guardar el salón. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libre = !_guardando;
    return AdminFormulario(
      titulo: _esEdicion ? 'Editar salón' : 'Nuevo salón',
      descripcion: _esEdicion
          ? 'Modifica los datos del salón.'
          : 'Registra un salón con su capacidad y tipo.',
      icono: Icons.meeting_room_outlined,
      esEdicion: _esEdicion,
      formKey: _formKey,
      errorGeneral: _error,
      guardando: _guardando,
      onGuardar: _guardar,
      textoGuardar: _esEdicion ? 'Guardar cambios' : 'Crear salón',
      campos: [
        AdminCampoTexto(
          controller: _codigo,
          etiqueta: 'Código del salón',
          obligatorio: true,
          hint: 'Ej. G101',
          ayuda: 'Debe ser único.',
          icono: Icons.tag,
          habilitado: libre,
          validador: (v) => v.length > 20 ? 'Máximo 20 caracteres' : null,
        ),
        AdminCampoTexto(
          controller: _capacidad,
          etiqueta: 'Capacidad',
          obligatorio: true,
          ayuda: 'Número de sillas. Mínimo 10.',
          icono: Icons.event_seat_outlined,
          teclado: TextInputType.number,
          habilitado: libre,
          validador: _validarCapacidad,
        ),
        AdminCampoTexto(
          controller: _edificio,
          etiqueta: 'Edificio',
          obligatorio: true,
          hint: 'Ej. Bloque G',
          icono: Icons.apartment,
          habilitado: libre,
          validador: (v) => v.length > 50 ? 'Máximo 50 caracteres' : null,
        ),
        AdminSelector<String>(
          valor: _tipo,
          etiqueta: 'Tipo de salón',
          obligatorio: true,
          icono: Icons.computer_outlined,
          opciones: [
            for (final e in SalonAdmin.tipos.entries)
              AdminOpcion<String>(e.key, e.value),
          ],
          onChanged: libre ? (v) => setState(() => _tipo = v) : null,
        ),
      ],
    );
  }
}
