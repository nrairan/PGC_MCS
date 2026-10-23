import 'package:flutter/material.dart';
import 'package:mcs/backend/api_horario.dart';

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

  // Conflictos (restricciones duras) y advertencias (blandas) detectados
  List<ConflictoHorario> _conflictos = [];
  List<ConflictoHorario> _advertencias = [];
  Map<String, dynamic>? _resumen;

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
      Map<String, dynamic>? encontrada;
      for (final a in _asignaturas) {
        if (a['id'].toString() == asigId.toString()) {
          encontrada = a;
          break;
        }
      }
      encontrada ??= _asignaturas.first;
      _aplicarAsignatura(encontrada);
    }

    // Gestor
    final gestorId = editar['gestor_id'] ?? editar['gestor'];
    if (gestorId != null && _gestores.isNotEmpty) {
      Map<String, dynamic>? gestorEnc;
      for (final g in _gestores) {
        if (g['id'].toString() == gestorId.toString()) {
          gestorEnc = g;
          break;
        }
      }
      _gestorSeleccionado = gestorEnc ?? _gestores.first;
    }

    // Salón
    final salonData = editar['salon'];
    if (salonData != null && _salones.isNotEmpty) {
      SalonItem? salonEnc;
      for (final s in _salones) {
        if (s.id.toString() == salonData.toString() || s.codigo == salonData.toString()) {
          salonEnc = s;
          break;
        }
      }
      _salonSeleccionado = salonEnc ?? _salones.first;
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

  void _aplicarAsignatura(Map<String, dynamic>? asig) {
    if (asig == null) {
      _asignaturaSeleccionada = null;
      _esCai = false;
      _infoCai = null;
      return;
    }

    final codigo = asig['codigo']?.toString() ?? '';
    final nombre = asig['nombre']?.toString() ?? '';
    final esCai = CaiHelper.esCai(codigo, nombre);

    _asignaturaSeleccionada = asig;
    _esCai = esCai;

    // El bloque pertenece al semestre del núcleo (la API rechaza si no coincide).
    final semAsig = (asig['semestre'] ?? '').toString();
    if (semAsig.isNotEmpty) _semestreSeleccionado = semAsig;

    // Si el gestor/salón ya elegidos dejan de ser válidos para este núcleo, se limpian.
    if (_gestorSeleccionado != null &&
        !_gestoresPermitidos.any((g) => g['id'].toString() == _gestorSeleccionado!['id'].toString())) {
      _gestorSeleccionado = null;
    }
    if (_salonSeleccionado != null &&
        !_salonesPermitidos.any((s) => s == _salonSeleccionado)) {
      _salonSeleccionado = null;
    }
    _conflictos = [];
    _advertencias = [];
    _resumen = null;

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
  }

  /// Gestores habilitados para el núcleo (si el núcleo no tiene gestores, todos).
  List<Map<String, dynamic>> get _gestoresPermitidos {
    final ids = ((_asignaturaSeleccionada?['gestores'] as List?) ?? [])
        .map((e) => e.toString())
        .toSet();
    if (ids.isEmpty) return _gestores;
    return _gestores.where((g) => ids.contains(g['id'].toString())).toList();
  }

  bool get _requiereComputo =>
      _asignaturaSeleccionada?['requiere_sala_computo'] == true;

  /// Un núcleo que requiere sala de cómputo solo ofrece salas de cómputo.
  List<SalonItem> get _salonesPermitidos =>
      _requiereComputo ? _salones.where((s) => s.esComputo).toList() : _salones;

  bool get _semestreBloqueado =>
      (_asignaturaSeleccionada?['semestre'] ?? '').toString().isNotEmpty;

  num _num(dynamic v) => v is num ? v : (num.tryParse('$v') ?? 0);

  String _fmtH(num h) =>
      h == h.roundToDouble() ? '${h.toInt()} h' : '${h.toStringAsFixed(1)} h';

  void _onSeleccionarAsignatura(Map<String, dynamic>? asig) {
    setState(() {
      _aplicarAsignatura(asig);
    });
  }

  Future<void> _validarDisponibilidad() async {
    if (!_validarCamposPrevios()) return;

    setState(() {
      _enviando = true;
      _conflictos = [];
      _advertencias = [];
      _resumen = null;
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
      _advertencias = res.advertencias;
      _resumen = res.resumen;
    });

    if (res.valido) {
      final nAv = res.advertencias.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(nAv == 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(nAv == 0
                    ? 'Horario disponible. No se detectaron conflictos.'
                    : 'Se puede guardar, pero hay $nAv advertencia(s). Revisa el panel.'),
              ),
            ],
          ),
          backgroundColor: nAv == 0 ? kVerdeOscuro : Colors.orange.shade800,
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

  Future<bool> _confirmarAdvertencias(List<ConflictoHorario> avisos) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Expanded(child: Text('El horario cumple las reglas, pero…')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: avisos
                .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${a.mensaje}'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Revisar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar de todos modos'),
          ),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _submitForm() async {
    if (!_validarCamposPrevios()) return;

    setState(() {
      _enviando = true;
      _conflictos = [];
      _advertencias = [];
      _resumen = null;
    });

    // 1) Consulta previa: restricciones duras bloquean; las blandas piden confirmación.
    final previa = await _client.validarBloque(
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
      _conflictos = previa.conflictos;
      _advertencias = previa.advertencias;
      _resumen = previa.resumen;
    });
    if (!previa.valido) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No se puede guardar: ${previa.conflictos.length} restricción(es) incumplida(s).'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (previa.advertencias.isNotEmpty) {
      final seguir = await _confirmarAdvertencias(previa.advertencias);
      if (!mounted) return;
      if (!seguir) {
        setState(() => _enviando = false);
        return;
      }
    }

    // 2) Guardado definitivo (la API vuelve a validar todo).
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

                                  // Advertencias (restricciones blandas)
                                  if (_advertencias.isNotEmpty) ...[
                                    _PanelAdvertencias(avisos: _advertencias),
                                    const SizedBox(height: 16),
                                  ],

                                  // Resumen de cargas (tras validar)
                                  if (_resumen != null) ...[
                                    _PanelResumen(
                                      resumen: _resumen!,
                                      fmt: _fmtH,
                                      toNum: _num,
                                    ),
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
                                      final sem = (a['semestre'] ?? '').toString();
                                      return DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                          '$cod - $nom${sem.isNotEmpty ? "  (Sem. $sem)" : ""}${esC ? " [CAI]" : ""}',
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
                                  if (_asignaturaSeleccionada != null) ...[
                                    const SizedBox(height: 8),
                                    _InfoAsignatura(
                                      horasSemana: _num(_asignaturaSeleccionada!['horas_semana']),
                                      horasAsignadas: _num(_asignaturaSeleccionada!['horas_asignadas']),
                                      requiereComputo: _requiereComputo,
                                      fmt: _fmtH,
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // Selector Obligatorio de Salón
                                  DropdownButtonFormField<SalonItem>(
                                    key: ValueKey('salon-${_asignaturaSeleccionada?['id']}'),
                                    initialValue: _salonSeleccionado,
                                    decoration: InputDecoration(
                                      labelText: 'Salón de clases (Obligatorio) *',
                                      prefixIcon: const Icon(Icons.meeting_room),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      helperText: _requiereComputo
                                          ? 'Este núcleo requiere sala de cómputo: solo se listan salas de cómputo.'
                                          : 'La API verifica disponibilidad, capacidad y tipo de aula.',
                                    ),
                                    isExpanded: true,
                                    items: _salonesPermitidos.map((s) {
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
                                    key: ValueKey('gestor-${_asignaturaSeleccionada?['id']}'),
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
                                    items: _gestoresPermitidos.map((g) {
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
                                        child: IgnorePointer(
                                          ignoring: _semestreBloqueado,
                                          child: DropdownButtonFormField<String>(
                                          key: ValueKey('sem-$_semestreSeleccionado'),
                                          initialValue: _semestreSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: _semestreBloqueado
                                                ? 'Semestre (definido por el núcleo)'
                                                : 'Semestre *',
                                            filled: true,
                                            fillColor: _semestreBloqueado
                                                ? Colors.grey.shade100
                                                : Colors.white,
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
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: IgnorePointer(
                                          ignoring: _esCai,
                                          child: Opacity(
                                            opacity: _esCai ? 0.6 : 1.0,
                                            child: DropdownButtonFormField<String>(
                                              key: ValueKey('dia-$_diaSeleccionado-$_esCai'),
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
                                                  .where((d) => _esCai || d != 'SAB')
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

class _InfoAsignatura extends StatelessWidget {
  final num horasSemana;
  final num horasAsignadas;
  final bool requiereComputo;
  final String Function(num) fmt;

  const _InfoAsignatura({
    required this.horasSemana,
    required this.horasAsignadas,
    required this.requiereComputo,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final definido = horasSemana > 0;
    final pendientes = horasSemana - horasAsignadas;
    final completo = definido && pendientes <= 0;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Chip(
          avatar: const Icon(Icons.schedule, size: 16),
          label: Text(definido
              ? 'Horas/semana: ${fmt(horasSemana)} · asignadas ${fmt(horasAsignadas)}'
                  '${completo ? " (completo)" : " · faltan ${fmt(pendientes)}"}'
              : 'Horas/semana sin definir (edita el núcleo)'),
          backgroundColor:
              completo ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        ),
        if (requiereComputo)
          const Chip(
            avatar: Icon(Icons.computer, size: 16),
            label: Text('Requiere sala de cómputo'),
            backgroundColor: Color(0xFFE3F2FD),
          ),
      ],
    );
  }
}

class _PanelAdvertencias extends StatelessWidget {
  final List<ConflictoHorario> avisos;

  const _PanelAdvertencias({required this.avisos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 22),
              SizedBox(width: 10),
              Text(
                'Advertencias (no impiden guardar):',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFE65100)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...avisos.map((a) => Padding(
                padding: const EdgeInsets.only(top: 3, left: 32),
                child: Text('• ${a.mensaje}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6D4C41))),
              )),
        ],
      ),
    );
  }
}

class _PanelResumen extends StatelessWidget {
  final Map<String, dynamic> resumen;
  final String Function(num) fmt;
  final num Function(dynamic) toNum;

  const _PanelResumen({
    required this.resumen,
    required this.fmt,
      required this.toNum,
  });

  @override
  Widget build(BuildContext context) {
    final hSemAsig = toNum(resumen['horas_semana_asignatura']);
    final hAsig = toNum(resumen['horas_asignadas_asignatura']);
    final gestor = resumen['horas_semana_gestor'];
    final maxG = toNum(resumen['max_horas_semana_gestor']);
    final lineas = <String>[
      if (hSemAsig > 0)
        'Núcleo: ${fmt(hAsig)} de ${fmt(hSemAsig)} por semana (con este bloque).',
      if (gestor != null)
        'Gestor: ${fmt(toNum(gestor))} de ${fmt(maxG)} semanales (con este bloque).',
      'Matriculados en el núcleo: ${resumen['inscritos'] ?? 0}.',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kVerdeOscuro.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lineas
            .map((l) => Text(l, style: const TextStyle(fontSize: 13)))
            .toList(),
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
