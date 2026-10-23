import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/frontend/widgets/lateral_ti.dart';

const Color kVerdeOscuro = Color(0xFF1A6433);
const Color kVerdeFondo = Color(0xFFF4F6F4);

/// Pantalla y formulario para creación y edición de horarios individuales.
/// Garantiza la selección obligatoria de salón, el bloqueo de horarios para CAI
/// y la visualización de conflictos de la API.
class HorarioForm extends StatefulWidget {
  final Map<String, dynamic>? horarioParaEditar;
  final String? authToken;
  final List<Map<String, dynamic>>? asignaturasIniciales;
  final List<Map<String, dynamic>>? gestoresIniciales;
  final List<SalonItem>? salonesIniciales;

  const HorarioForm({
    super.key,
    this.horarioParaEditar,
    this.authToken,
    this.asignaturasIniciales,
    this.gestoresIniciales,
    this.salonesIniciales,
  });

  @override
  State<HorarioForm> createState() => _HorarioFormState();
}

/// Alias alternativo para facilitar importaciones y compatibilidad
typedef FormularioHorario = HorarioForm;

class _HorarioFormState extends State<HorarioForm> {
  final _formKey = GlobalKey<FormState>();
  late final HorarioHttpClient _client;

  // Listas cargadas desde la API
  List<Map<String, dynamic>> _asignaturas = [];
  List<Map<String, dynamic>> _gestores = [];
  List<SalonItem> _salones = [];

  bool _cargandoDatos = true;
  bool _enviando = false;
  String? _errorCarga;

  // Campos seleccionados
  Map<String, dynamic>? _asignaturaSeleccionada;
  Map<String, dynamic>? _gestorSeleccionado;
  SalonItem? _salonSeleccionado;
  String _semestreSeleccionado = '1';
  String _diaSeleccionado = 'LUN';
  TimeOfDay _horaInicio = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 9, minute: 0);

  // Estado CAI
  bool _esCai = false;
  String? _infoCai;

  // Conflictos detectados
  List<ConflictoHorario> _conflictos = [];

  static const List<String> kDiasSemana = [
    'LUN',
    'MAR',
    'MIE',
    'JUE',
    'VIE',
    'SAB',
  ];

  static const Map<String, String> kDiasNombres = {
    'LUN': 'Lunes',
    'MAR': 'Martes',
    'MIE': 'Miércoles',
    'JUE': 'Jueves',
    'VIE': 'Viernes',
    'SAB': 'Sábado',
  };

  static const List<String> kSemestresDisponibles = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'
  ];

  @override
  void initState() {
    super.initState();
    _client = HorarioHttpClient(authToken: widget.authToken);
    if (widget.asignaturasIniciales != null &&
        widget.gestoresIniciales != null &&
        widget.salonesIniciales != null) {
      _asignaturas = widget.asignaturasIniciales!;
      _gestores = widget.gestoresIniciales!;
      _salones = widget.salonesIniciales!;
      _cargandoDatos = false;
      _inicializarDatosEdicion();
    } else {
      _cargarCatalogos();
    }
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoDatos = true;
      _errorCarga = null;
    });

    try {
      final resultados = await Future.wait([
        _client.fetchAsignaturas(),
        _client.fetchGestores(),
        _client.fetchSalones(),
      ]);

      if (!mounted) return;

      setState(() {
        _asignaturas = resultados[0] as List<Map<String, dynamic>>;
        _gestores = resultados[1] as List<Map<String, dynamic>>;
        _salones = resultados[2] as List<SalonItem>;
        _cargandoDatos = false;
      });

      _inicializarDatosEdicion();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = e.toString();
        _cargandoDatos = false;
      });
    }
  }

  void _inicializarDatosEdicion() {
    final editar = widget.horarioParaEditar;
    if (editar == null) return;

    // Asignatura
    final asigId = editar['asignatura_id'] ?? editar['asignatura'];
    if (asigId != null && _asignaturas.isNotEmpty) {
      try {
        final encontrada = _asignaturas.firstWhere(
          (a) => a['id'] == asigId,
          orElse: () => _asignaturas.first,
        );
        _onSeleccionarAsignatura(encontrada);
      } catch (_) {}
    }

    // Gestor
    final gestorId = editar['gestor_id'] ?? editar['gestor'];
    if (gestorId != null && _gestores.isNotEmpty) {
      try {
        _gestorSeleccionado = _gestores.firstWhere(
          (g) => g['id'] == gestorId,
          orElse: () => _gestores.first,
        );
      } catch (_) {}
    }

    // Salón
    final salonData = editar['salon'];
    if (salonData != null && _salones.isNotEmpty) {
      try {
        _salonSeleccionado = _salones.firstWhere(
          (s) => s.id.toString() == salonData.toString() || s.codigo == salonData.toString(),
          orElse: () => _salones.first,
        );
      } catch (_) {}
    }

    // Semestre
    if (editar['semestre'] != null) {
      _semestreSeleccionado = editar['semestre'].toString();
    }

    // Día y Horas (solo si no es CAI)
    if (!_esCai) {
      if (editar['dia'] != null && kDiasSemana.contains(editar['dia'])) {
        _diaSeleccionado = editar['dia'].toString();
      }
      if (editar['hora_inicio'] != null) {
        _horaInicio = _parseTimeOfDay(editar['hora_inicio'].toString()) ?? _horaInicio;
      }
      if (editar['hora_fin'] != null) {
        _horaFin = _parseTimeOfDay(editar['hora_fin'].toString()) ?? _horaFin;
      }
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final partes = timeStr.split(':');
      if (partes.length >= 2) {
        return TimeOfDay(
          hour: int.parse(partes[0]),
          minute: int.parse(partes[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  void _onSeleccionarAsignatura(Map<String, dynamic>? asig) {
    if (asig == null) {
      setState(() {
        _asignaturaSeleccionada = null;
        _esCai = false;
        _infoCai = null;
      });
      return;
    }

    final codigo = asig['codigo']?.toString() ?? '';
    final nombre = asig['nombre']?.toString() ?? '';
    final esCai = CaiHelper.esCai(codigo, nombre);

    setState(() {
      _asignaturaSeleccionada = asig;
      _esCai = esCai;

      if (esCai) {
        final predefinido = CaiHelper.horarioPredefinido(codigo, nombre);
        _diaSeleccionado = predefinido['dia']!;
        _horaInicio = _parseTimeOfDay(predefinido['hora_inicio']!) ?? _horaInicio;
        _horaFin = _parseTimeOfDay(predefinido['hora_fin']!) ?? _horaFin;
        _infoCai =
            'Núcleo CAI detectado: El horario (${kDiasNombres[_diaSeleccionado]} ${predefinido['hora_inicio']!.substring(0, 5)} - ${predefinido['hora_fin']!.substring(0, 5)}) está predefinido institucionalmente y no permite alteraciones.';
      } else {
        _infoCai = null;
      }
    });
  }

  Future<void> _validarDisponibilidad() async {
    if (!_validarCamposPrevios()) return;

    setState(() {
      _enviando = true;
      _conflictos = [];
    });

    final res = await _client.validarBloque(
      asignaturaId: _asignaturaSeleccionada!['id'] as int,
      salon: _salonSeleccionado!.id,
      gestorId: _gestorSeleccionado!['id'] as int,
      dia: _diaSeleccionado,
      horaInicio: _formatTimeOfDay(_horaInicio),
      horaFin: _formatTimeOfDay(_horaFin),
      semestre: _semestreSeleccionado,
      horarioExcluidoId: widget.horarioParaEditar?['id'] as int?,
    );

    if (!mounted) return;

    setState(() {
      _enviando = false;
      _conflictos = res.conflictos;
    });

    if (res.valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Horario disponible. No se detectaron conflictos.'),
            ],
          ),
          backgroundColor: kVerdeOscuro,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se encontraron ${_conflictos.length} conflicto(s). Revisa el panel inferior.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  bool _validarCamposPrevios() {
    if (_salonSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Advertencia: El salón de clases es obligatorio.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      _formKey.currentState?.validate();
      return false;
    }

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final inicioMin = _horaInicio.hour * 60 + _horaInicio.minute;
    final finMin = _horaFin.hour * 60 + _horaFin.minute;
    if (finMin <= inicioMin) {
      setState(() {
        _conflictos = [
          const ConflictoHorario(
            mensaje: 'La hora de fin debe ser posterior a la hora de inicio.',
          )
        ];
      });
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validarCamposPrevios()) return;

    setState(() {
      _enviando = true;
      _conflictos = [];
    });

    try {
      final esEdicion = widget.horarioParaEditar != null;
      final ResultadoGuardado res;

      if (esEdicion) {
        final id = widget.horarioParaEditar!['id'] as int;
        res = await _client.actualizarBloque(
          horarioId: id,
          asignaturaId: _asignaturaSeleccionada!['id'] as int,
          salon: _salonSeleccionado!.id,
          gestorId: _gestorSeleccionado!['id'] as int,
          dia: _diaSeleccionado,
          horaInicio: _formatTimeOfDay(_horaInicio),
          horaFin: _formatTimeOfDay(_horaFin),
          semestre: _semestreSeleccionado,
        );
      } else {
        res = await _client.guardarBloque(
          asignaturaId: _asignaturaSeleccionada!['id'] as int,
          salon: _salonSeleccionado!.id,
          gestorId: _gestorSeleccionado!['id'] as int,
          dia: _diaSeleccionado,
          horaInicio: _formatTimeOfDay(_horaInicio),
          horaFin: _formatTimeOfDay(_horaFin),
          semestre: _semestreSeleccionado,
        );
      }

      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      if (res.exitoso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(esEdicion
                    ? 'Horario actualizado exitosamente'
                    : 'Horario creado exitosamente'),
              ],
            ),
            backgroundColor: kVerdeOscuro,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _conflictos = res.conflictos;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo guardar el horario. La API reportó ${res.conflictos.length} conflicto(s).',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _conflictos = [ConflictoHorario(mensaje: 'Error inesperado: $e')];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.horarioParaEditar != null;

    return Scaffold(
      backgroundColor: kVerdeFondo,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          esEdicion ? 'Editar Horario' : 'Crear Horario',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LateralTi(),
          Expanded(
            child: _cargandoDatos
                ? const Center(
                    child: CircularProgressIndicator(color: kVerdeOscuro),
                  )
                : _errorCarga != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(_errorCarga!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargarCatalogos,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 780),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado
                                  Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                kVerdeOscuro.withValues(alpha: 0.1),
                                            child: const Icon(
                                              Icons.calendar_month,
                                              color: kVerdeOscuro,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  esEdicion
                                                      ? 'Modificar horario académico'
                                                      : 'Registrar nuevo bloque de horario',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'El salón es obligatorio. Las asignaturas CAI aplican su horario institucional fijo.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Aviso CAI si aplica
                                  if (_esCai && _infoCai != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF1976D2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.lock_clock,
                                            color: Color(0xFF1976D2),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _infoCai!,
                                              style: const TextStyle(
                                                color: Color(0xFF0D47A1),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Lista de Conflictos Detectados
                                  if (_conflictos.isNotEmpty) ...[
                                    _PanelConflictos(conflictos: _conflictos),
                                    const SizedBox(height: 16),
                                  ],

                                  // Selector de Asignatura
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    initialValue: _asignaturaSeleccionada,
                                    decoration: InputDecoration(
                                      labelText: 'Asignatura / Núcleo Temático *',
                                      prefixIcon: const Icon(Icons.book_outlined),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    isExpanded: true,
                                    items: _asignaturas.map((a) {
                                      final cod = a['codigo'] ?? '';
                                      final nom = a['nombre'] ?? '';
                                      final esC = CaiHelper.esCai(cod, nom);
                                      return DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                          '$cod - $nom ${esC ? " [CAI]" : ""}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: esC
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: esC
                                                ? const Color(0xFF0D47A1)
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _onSeleccionarAsignatura,
                                    validator: (val) => val == null
                                        ? 'Selecciona una asignatura'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Selector Obligatorio de Salón
                                  DropdownButtonFormField<SalonItem>(
                                    initialValue: _salonSeleccionado,
                                    decoration: InputDecoration(
                                      labelText: 'Salón de clases (Obligatorio) *',
                                      prefixIcon: const Icon(Icons.meeting_room),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      helperText:
                                          'La API requiere asignar un salón para verificar disponibilidad.',
                                    ),
                                    isExpanded: true,
                                    items: _salones.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s.descripcionCompleta,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (s) {
                                      setState(() {
                                        _salonSeleccionado = s;
                                      });
                                    },
                                    validator: (val) {
                                      if (val == null) {
                                        return 'El salón de clases es obligatorio. Selecciona un salón.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Selector de Gestor
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    initialValue: _gestorSeleccionado,
                                    decoration: InputDecoration(
                                      labelText: 'Gestor del Conocimiento *',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    isExpanded: true,
                                    items: _gestores.map((g) {
                                      final nombre = [
                                        g['first_name'] ?? '',
                                        g['last_name'] ?? ''
                                      ].where((s) => s.isNotEmpty).join(' ');
                                      final display = nombre.isNotEmpty
                                          ? nombre
                                          : (g['username'] ?? 'Sin nombre');
                                      return DropdownMenuItem(
                                        value: g,
                                        child: Text(display),
                                      );
                                    }).toList(),
                                    onChanged: (g) =>
                                        setState(() => _gestorSeleccionado = g),
                                    validator: (val) => val == null
                                        ? 'Selecciona un gestor del conocimiento'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Fila: Semestre y Día
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _semestreSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: 'Semestre *',
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          items: kSemestresDisponibles
                                              .map((s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text('Semestre $s'),
                                                  ))
                                              .toList(),
                                          onChanged: (s) {
                                            if (s != null) {
                                              setState(() =>
                                                  _semestreSeleccionado = s);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: IgnorePointer(
                                          ignoring: _esCai,
                                          child: Opacity(
                                            opacity: _esCai ? 0.6 : 1.0,
                                            child: DropdownButtonFormField<String>(
                                              initialValue: _diaSeleccionado,
                                              decoration: InputDecoration(
                                                labelText: _esCai
                                                    ? 'Día (Fijo CAI)'
                                                    : 'Día de la semana *',
                                                filled: true,
                                                fillColor: _esCai
                                                    ? Colors.grey.shade100
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                suffixIcon: _esCai
                                                    ? const Icon(Icons.lock,
                                                        size: 18)
                                                    : null,
                                              ),
                                              items: kDiasSemana
                                                  .map((d) => DropdownMenuItem(
                                                        value: d,
                                                        child: Text(
                                                            kDiasNombres[d] ?? d),
                                                      ))
                                                  .toList(),
                                              onChanged: (d) {
                                                if (d != null) {
                                                  setState(() =>
                                                      _diaSeleccionado = d);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Fila: Horas Inicio y Fin
                                  IgnorePointer(
                                    ignoring: _esCai,
                                    child: Opacity(
                                      opacity: _esCai ? 0.6 : 1.0,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _CampoHoraSelector(
                                              label: _esCai
                                                  ? 'Hora Inicio (Fija CAI)'
                                                  : 'Hora Inicio *',
                                              hora: _horaInicio,
                                              bloqueado: _esCai,
                                              onCambiar: (h) => setState(
                                                  () => _horaInicio = h),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: _CampoHoraSelector(
                                              label: _esCai
                                                  ? 'Hora Fin (Fija CAI)'
                                                  : 'Hora Fin *',
                                              hora: _horaFin,
                                              bloqueado: _esCai,
                                              onCambiar: (h) => setState(
                                                  () => _horaFin = h),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Botones de Acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _enviando
                                              ? null
                                              : _validarDisponibilidad,
                                          icon: const Icon(
                                              Icons.fact_check_outlined),
                                          label: const Text('Validar Disponibilidad'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: kVerdeOscuro,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            side: const BorderSide(
                                                color: kVerdeOscuro),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _enviando ? null : _submitForm,
                                          icon: _enviando
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.save),
                                          label: Text(_enviando
                                              ? 'Guardando...'
                                              : (esEdicion
                                                  ? 'Actualizar Horario'
                                                  : 'Guardar Horario')),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COMPONENTES AUXILIARES
// ─────────────────────────────────────────────

class _CampoHoraSelector extends StatelessWidget {
  final String label;
  final TimeOfDay hora;
  final bool bloqueado;
  final ValueChanged<TimeOfDay> onCambiar;

  const _CampoHoraSelector({
    required this.label,
    required this.hora,
    required this.bloqueado,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final texto =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: bloqueado
          ? null
          : () async {
              final seleccion = await showTimePicker(
                context: context,
                initialTime: hora,
              );
              if (seleccion != null) {
                onCambiar(seleccion);
              }
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bloqueado ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Icon(
              bloqueado ? Icons.lock_outline : Icons.access_time,
              size: 20,
              color: bloqueado ? Colors.grey : kVerdeOscuro,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: bloqueado ? Colors.grey.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelConflictos extends StatelessWidget {
  final List<ConflictoHorario> conflictos;

  const _PanelConflictos({required this.conflictos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFC62828), size: 22),
              SizedBox(width: 10),
              Text(
                'Conflictos reportados por la API:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...conflictos.map((c) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, left: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      c.mensaje,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
