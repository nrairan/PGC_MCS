import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// MODELOS DE DATOS
// ─────────────────────────────────────────────

class Asignatura {
  final int id;
  final String codigo;
  final String nombre;
  final int creditos;

  const Asignatura({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.creditos,
  });

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    return Asignatura(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      creditos: json['creditos'] as int,
    );
  }
}

class GestorConocimiento {
  final int id;
  final String nombre;
  final String email;

  const GestorConocimiento({
    required this.id,
    required this.nombre,
    required this.email,
  });

  factory GestorConocimiento.fromJson(Map<String, dynamic> json) {
    // El modelo Usuario de Django tiene first_name, last_name y email.
    // get_full_name() = "first_name last_name". Si viene vacío, usa username.
    final firstName = (json['first_name'] as String? ?? '').trim();
    final lastName = (json['last_name'] as String? ?? '').trim();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    return GestorConocimiento(
      id: json['id'] as int,
      nombre: fullName.isNotEmpty ? fullName : (json['username'] as String? ?? 'Sin nombre'),
      email: json['email'] as String? ?? '',
    );
  }
}

class AsignacionGestor {
  final Asignatura asignatura;
  final GestorConocimiento gestor;

  const AsignacionGestor({required this.asignatura, required this.gestor});
}

class HorarioDescanso {
  final TimeOfDay inicio;
  final TimeOfDay fin;

  const HorarioDescanso({required this.inicio, required this.fin});

  String get label =>
      '${_fmt(inicio)} – ${_fmt(fin)}';

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class BloquHorario {
  final String dia;
  final TimeOfDay inicio;
  final TimeOfDay fin;
  final Asignatura asignatura;
  final GestorConocimiento gestor;
  final String salon;

  const BloquHorario({
    required this.dia,
    required this.inicio,
    required this.fin,
    required this.asignatura,
    required this.gestor,
    required this.salon,
  });
}

// ─────────────────────────────────────────────
// DATOS PREDEFINIDOS
// ─────────────────────────────────────────────

const List<String> kSemestres = [
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

// Núcleos Temáticos CAI predefinidos
const List<String> kNucleosCai = [
  'DN-CAI1002020202 - DIAGNOSTICO Y NIVELATORIO COMUNICACIÓN Y LECTURA CRÍTICA I',
  'DN-CAI1002020201 - DIAGNOSTICO Y NIVELATORIO RAZONAMIENTO LÓGICO Y CUANTITATIVO',
  'CAI1002020202 - COMUNICACIÓN Y LECTURA CRÍTICA I',
  'DN-CAI1002020303 - DIAGNOSTICO Y NIVELATORIO CIUDADANIA DEL SIGLO 21',
  'DN-CAI1002020304 - DIAGNOSTICO Y NIVELATORIO LENGUA EXTRANJERA I',
  'CAI1002020201 - RAZONAMIENTO LÓGICO Y CUANTITATIVO',
  'CAI1002020303 - CIUDADANIA DEL SIGLO 21',
  'CAI1002020305 - COMUNICACIÓN Y LECTURA CRÍTICA II',
  'CAI1002020304 - LENGUA EXTRANJERA I',
  'CAI1002020406 - LENGUA EXTRANJERA II',
  'DN-CAI1002020613 - DIAGNOSTICO Y NIVELATORIO CIENCIA, TECNOLOGIA E INNOVACION I',
  'DN-CAI1002020612 - DIAGNOSTICO Y NIVELATORIO EMPRENDIMIENTO E INNOVACION I',
  'CAI1002020507 - LENGUA EXTRANJERA III',
];

const List<String> kDias = [
  'LUN',
  'MAR',
  'MIE',
  'JUE',
  'VIE',
];

const Map<String, String> kDiasLabel = {
  'LUN': 'Lunes',
  'MAR': 'Martes',
  'MIE': 'Miércoles',
  'JUE': 'Jueves',
  'VIE': 'Viernes',
};

// ─────────────────────────────────────────────
// SERVICIO DE API
// ─────────────────────────────────────────────

class HorarioApiService {
  // ── CONFIGURACIÓN DE URL ────────────────────────────────────────────────
  // Descomenta la línea que corresponda a tu entorno:
  //
  // ✅ Emulador Android (AVD) → el host es 10.0.2.2
  // static const String _baseUrl = 'http://10.0.2.2:8000/api';
  //
  // ✅ Dispositivo físico Android/iOS en la misma red WiFi
  //    → usa la IP local de tu PC (ej. 192.168.1.X)
  //    Encuéntrala con: ipconfig (Windows) o ifconfig/ip a (Linux/Mac)
  // static const String _baseUrl = 'http://192.168.1.100:8000/api';
  //
  // ✅ Web o iOS Simulator → localhost funciona directo
  // static const String _baseUrl = 'http://localhost:8000/api';
  //
  // ✅ Producción
  // static const String _baseUrl = 'https://tu-dominio.com/api';

  static const String _baseUrl = 'http://127.0.0.1:8000/api'; // ← CAMBIA ESTO

  // Token de autenticación — pásalo al construir el servicio
  // o reemplaza por tu mecanismo (SharedPreferences, etc.)
  final String? authToken;

  const HorarioApiService({this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Token $authToken',
      };

  /// GET /api/asignaturas/
  Future<List<Asignatura>> fetchAsignaturas() async {
    final uri = Uri.parse('$_baseUrl/asignaturas/');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      // Soporte para respuesta lista [] o paginada {results:[]}
      dynamic parsed = jsonDecode(body);
      List<dynamic> data;
      if (parsed is List) {
        data = parsed;
      } else if (parsed is Map && parsed.containsKey('results')) {
        data = parsed['results'] as List<dynamic>;
      } else {
        data = [];
      }
      return data
          .map((j) => Asignatura.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar asignaturas (${response.statusCode}): ${response.body}');
  }

  /// GET /api/usuarios/?rol=GC
  /// Filtra solo los Gestores del Conocimiento
  Future<List<GestorConocimiento>> fetchGestores() async {
    final uri = Uri.parse('$_baseUrl/usuarios/?rol=GC');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      // Soporte para respuesta lista [] o paginada {results:[]}
      dynamic parsed = jsonDecode(body);
      List<dynamic> data;
      if (parsed is List) {
        data = parsed;
      } else if (parsed is Map && parsed.containsKey('results')) {
        data = parsed['results'] as List<dynamic>;
      } else {
        data = [];
      }
      return data
          .map((j) => GestorConocimiento.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar gestores (${response.statusCode}): ${response.body}');
  }

  /// POST /api/horarios/  — guarda cada bloque generado
  /// El servidor asigna el salón automáticamente si no se envía.
  Future<void> guardarHorarios({
    required List<BloquHorario> bloques,
    required String semestre,
  }) async {
    final uri = Uri.parse('$_baseUrl/horarios/');
    final List<String> errores = [];

    for (int i = 0; i < bloques.length; i++) {
      final bloque = bloques[i];
      final String horaInicio =
          '${bloque.inicio.hour.toString().padLeft(2, '0')}:${bloque.inicio.minute.toString().padLeft(2, '0')}:00';
      final String horaFin =
          '${bloque.fin.hour.toString().padLeft(2, '0')}:${bloque.fin.minute.toString().padLeft(2, '0')}:00';

      final body = jsonEncode({
        'asignatura':  bloque.asignatura.id,
        'gestor':      bloque.gestor.id,
        'dia':         bloque.dia,
        'hora_inicio': horaInicio,
        'hora_fin':    horaFin,
        'semestre':    semestre,   // ← necesario para filtrar en horarios.dart
        // 'salon' no se envía → Django asigna el primero disponible
      });

      final response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode != 201) {
        // Recopilar errores en lugar de abortar al primer fallo
        String detalle = response.body;
        try {
          final decoded = jsonDecode(response.body);
          detalle = decoded.toString();
        } catch (_) {}
        errores.add('Bloque ${i + 1} (${bloque.dia} ${horaInicio}): $detalle');
      }
    }

    if (errores.isNotEmpty) {
      throw Exception('Algunos bloques no se guardaron:\n${errores.join('\n')}');
    }
  }

  /// GET /api/horarios/por_semestre/?semestre=X
  /// Devuelve el horario guardado agrupado por día.
  Future<Map<String, List<Map<String, dynamic>>>> fetchHorarioPorSemestre(
      String semestre) async {
    final uri = Uri.parse('$_baseUrl/horarios/por_semestre/?semestre=$semestre');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> raw =
          jsonDecode(utf8.decode(response.bodyBytes));
      return raw.map((dia, bloques) => MapEntry(
            dia,
            (bloques as List)
                .map((b) => Map<String, dynamic>.from(b as Map))
                .toList(),
          ));
    }
    throw Exception('Error al cargar horario (${response.statusCode})');
  }
}

// ─────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────

class CrearHorarioScreen extends StatefulWidget {
  /// Pasa el token de autenticación del usuario logueado.
  /// Si tu app ya maneja auth globalmente, puedes obtenerlo
  /// de un Provider/Bloc en lugar de pasarlo aquí.
  final String? authToken;

  const CrearHorarioScreen({super.key, this.authToken});

  @override
  State<CrearHorarioScreen> createState() => _CrearHorarioScreenState();
}

class _CrearHorarioScreenState extends State<CrearHorarioScreen> {
  int _paso = 0;

  // Datos cargados desde la API
  List<Asignatura> _asignaturas = [];
  List<GestorConocimiento> _gestores = [];
  bool _cargandoDatos = true;
  String? _errorCarga;
  late final HorarioApiService _api;

  // Estado acumulado entre pasos
  String? _semestreSeleccionado;
  final Set<String> _nucleosSeleccionados = {};
  final Map<int, int?> _asignacionGestores = {}; // asignaturaId → gestorId
  bool _mismoHorarioDescanso = true;
  HorarioDescanso _descansoGeneral =
      const HorarioDescanso(inicio: TimeOfDay(hour: 12, minute: 0), fin: TimeOfDay(hour: 13, minute: 0));
  final Map<int, HorarioDescanso> _descansosPorGestor = {};
  TimeOfDay _horaFinClases = const TimeOfDay(hour: 18, minute: 0);
  List<BloquHorario> _horarioGenerado = [];

  static const int kTotalPasos = 6;

  final List<String> _titulos = [
    'Seleccionar semestre',
    'Núcleos temáticos CAI',
    'Gestores y materias',
    'Horarios de descanso',
    'Generar horario',
    'Horario generado',
  ];

  @override
  void initState() {
    super.initState();
    _api = HorarioApiService(authToken: widget.authToken);
    // addPostFrameCallback garantiza que el widget esté montado
    // antes de disparar la petición HTTP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarDatos();
    });
  }

  @override
  void dispose() {
    // Al destruir el widget todas las referencias se liberan;
    // los Futures pendientes ya no podrán llamar setState
    // gracias a las guardas `if (!mounted) return` de abajo.
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return; // guarda de entrada

    setState(() {
      _cargandoDatos = true;
      _errorCarga = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchAsignaturas(),
        _api.fetchGestores(),
      ]);

      if (!mounted) return; // guarda post-await (éxito)

      setState(() {
        _asignaturas = results[0] as List<Asignatura>;
        _gestores = results[1] as List<GestorConocimiento>;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (!mounted) return; // guarda post-await (error)

      setState(() {
        _errorCarga = e.toString();
        _cargandoDatos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        //backgroundColor: const Color(0xFF1A6433),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Crear Horario',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      //  bottom: PreferredSize(
    //      preferredSize: const Size.fromHeight(4),
  //        //child: _BarraProgreso(pasoActual: _paso, totalPasos: kTotalPasos),
//        ),
      ),
      body: _cargandoDatos
          ? const _PantallaCargando(mensaje: 'Cargando asignaturas y gestores...')
          : _errorCarga != null
              ? _PantallaError(
                  mensaje: _errorCarga!,
                  onReintentar: _cargarDatos,
                )
              : Column(
                  children: [
                    _EncabezadoPaso(paso: _paso, titulo: _titulos[_paso]),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _buildPasoActual(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPasoActual() {
    switch (_paso) {
      case 0:
        return _PasoSemestre(
          key: const ValueKey(0),
          semestreSeleccionado: _semestreSeleccionado,
          onSeleccionar: (s) => setState(() => _semestreSeleccionado = s),
          onSiguiente: _semestreSeleccionado != null ? () => setState(() => _paso++) : null,
        );
      case 1:
        return _PasoNucleos(
          key: const ValueKey(1),
          nucleosSeleccionados: _nucleosSeleccionados,
          onToggle: (n) => setState(() {
            if (_nucleosSeleccionados.contains(n)) {
              _nucleosSeleccionados.remove(n);
            } else {
              _nucleosSeleccionados.add(n);
            }
          }),
          onAnterior: () => setState(() => _paso--),
          onSiguiente: _nucleosSeleccionados.isNotEmpty ? () => setState(() => _paso++) : null,
        );
      case 2:
        return _PasoGestoresMaterias(
          key: const ValueKey(2),
          asignaturas: _asignaturas,
          gestores: _gestores,
          asignaciones: _asignacionGestores,
          onAsignar: (asignaturaId, gestorId) =>
              setState(() => _asignacionGestores[asignaturaId] = gestorId),
          onAnterior: () => setState(() => _paso--),
          onSiguiente: _asignacionGestores.isNotEmpty ? () => setState(() => _paso++) : null,
        );
      case 3:
        return _PasoDescanso(
          key: const ValueKey(3),
          gestores: _gestores
              .where((g) => _asignacionGestores.values.contains(g.id))
              .toList(),
          mismoHorario: _mismoHorarioDescanso,
          descansoGeneral: _descansoGeneral,
          descansosPorGestor: _descansosPorGestor,
          horaFin: _horaFinClases,
          onMismoHorarioChange: (v) => setState(() => _mismoHorarioDescanso = v),
          onDescansoGeneralChange: (d) => setState(() => _descansoGeneral = d),
          onDescansoPorGestorChange: (id, d) =>
              setState(() => _descansosPorGestor[id] = d),
          onHoraFinChange: (t) => setState(() => _horaFinClases = t),
          onAnterior: () => setState(() => _paso--),
          onSiguiente: () => setState(() => _paso++),
        );
      case 4:
        return _PasoGenerarHorario(
          key: const ValueKey(4),
          asignaciones: _asignacionGestores,
          asignaturas: _asignaturas,
          gestores: _gestores,
          mismoDescanso: _mismoHorarioDescanso,
          descansoGeneral: _descansoGeneral,
          descansosPorGestor: _descansosPorGestor,
          horaFin: _horaFinClases,
          onAnterior: () => setState(() => _paso--),
          onGenerar: (horario) => setState(() {
            _horarioGenerado = horario;
            _paso++;
          }),
        );
      case 5:
        return _PasoVisualizarHorario(
          key: const ValueKey(5),
          horario: _horarioGenerado,
          semestre: _semestreSeleccionado ?? '',
          onReacomodar: () => setState(() => _paso = 4),
          onGuardar: _guardarHorario,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _guardarHorario() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            //CircularProgressIndicator(color: Color(0xFF1A6433)),
            SizedBox(width: 16),
            Text('Guardando horario...'),
          ],
        ),
      ),
    );

    try {
      await _api.guardarHorarios(
        bloques: _horarioGenerado,
        semestre: _semestreSeleccionado ?? '',
      );
      if (mounted) Navigator.of(context).pop(); // cierra dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario guardado exitosamente'),
            //backgroundColor: Color(0xFF1A6433),
          ),
        );
        Navigator.of(context).pop(); // sale de la pantalla
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // cierra dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// WIDGETS DE ESTADO DE CARGA
// ─────────────────────────────────────────────

class _PantallaCargando extends StatelessWidget {
  final String mensaje;

  const _PantallaCargando({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //const CircularProgressIndicator(color: Color(0xFF1A6433)),
          const SizedBox(height: 20),
          Text(
            mensaje,
            style: const TextStyle(color: Color(0xFF2E7D52), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _PantallaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _PantallaError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFC62828), size: 48),
            const SizedBox(height: 16),
            const Text(
              'No se pudo conectar con la API',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                //color: Color(0xFF1A6433),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                //backgroundColor: const Color(0xFF1A6433),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS DE APOYO
// ─────────────────────────────────────────────


//class _BarraProgreso extends StatelessWidget {
//  final int pasoActual;
//  final int totalPasos;

//  const _BarraProgreso({required this.pasoActual, required this.totalPasos});

//  @override
//  Widget build(BuildContext context) {
//    return LinearProgressIndicator(
//      value: (pasoActual + 1) / totalPasos,
//      backgroundColor: Colors.white24,
//      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
//      minHeight: 4,
//    );
//  }
//}

class _EncabezadoPaso extends StatelessWidget {
  final int paso;
  final String titulo;

  const _EncabezadoPaso({required this.paso, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 33, 100, 72),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              //color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${paso + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonesNavegacion extends StatelessWidget {
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;
  final String labelSiguiente;

  const _BotonesNavegacion({
    this.onAnterior,
    this.onSiguiente,
    this.labelSiguiente = 'Siguiente',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (onAnterior != null)
            OutlinedButton.icon(
              onPressed: onAnterior,
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                //foregroundColor: const Color(0xFF1A6433),
                //side: const BorderSide(color: Color(0xFF1A6433)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: onSiguiente,
            style: ElevatedButton.styleFrom(
              //backgroundColor: const Color(0xFF1A6433),
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labelSiguiente),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PASO 1: SELECCIONAR SEMESTRE
// ─────────────────────────────────────────────

class _PasoSemestre extends StatelessWidget {
  final String? semestreSeleccionado;
  final ValueChanged<String> onSeleccionar;
  final VoidCallback? onSiguiente;

  const _PasoSemestre({
    super.key,
    required this.semestreSeleccionado,
    required this.onSeleccionar,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: kSemestres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = kSemestres[i];
              final seleccionado = s == semestreSeleccionado;
              return _TarjetaSeleccionable(
                titulo: s,
                subtitulo: i == 0 ? 'Próximo' : (i == 1 ? 'Actual' : ''),
                seleccionado: seleccionado,
                icono: Icons.calendar_today_outlined,
                onTap: () => onSeleccionar(s),
              );
            },
          ),
        ),
        _BotonesNavegacion(onSiguiente: onSiguiente),
      ],
    );
  }
}

class _TarjetaSeleccionable extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool seleccionado;
  final IconData icono;
  final VoidCallback onTap;

  const _TarjetaSeleccionable({
    required this.titulo,
    required this.subtitulo,
    required this.seleccionado,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado ? const Color(0xFF1A6433) : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              color: seleccionado ? const Color(0xFF1A6433) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
                  color: seleccionado ? const Color(0xFF1A6433) : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (subtitulo.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D52)),
                ),
              ),
            if (seleccionado) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Color(0xFF1A6433), size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PASO 2: NÚCLEOS TEMÁTICOS CAI
// ─────────────────────────────────────────────

class _PasoNucleos extends StatelessWidget {
  final Set<String> nucleosSeleccionados;
  final ValueChanged<String> onToggle;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  const _PasoNucleos({
    super.key,
    required this.nucleosSeleccionados,
    required this.onToggle,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            '${nucleosSeleccionados.length} núcleo(s) seleccionado(s)',
            style: const TextStyle(color: Color(0xFF2E7D52), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: kNucleosCai.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final nucleo = kNucleosCai[i];
              final sel = nucleosSeleccionados.contains(nucleo);
              return GestureDetector(
                onTap: () => onToggle(nucleo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? const Color(0xFF1A6433) : Colors.grey.shade200,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: sel,
                        onChanged: (_) => onToggle(nucleo),
                        activeColor: const Color(0xFF1A6433),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nucleo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? const Color(0xFF1A6433) : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _BotonesNavegacion(onAnterior: onAnterior, onSiguiente: onSiguiente),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PASO 3: GESTORES Y MATERIAS
// ─────────────────────────────────────────────

class _PasoGestoresMaterias extends StatefulWidget {
  final List<Asignatura> asignaturas;
  final List<GestorConocimiento> gestores;
  final Map<int, int?> asignaciones;
  final Function(int asignaturaId, int gestorId) onAsignar;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  const _PasoGestoresMaterias({
    super.key,
    required this.asignaturas,
    required this.gestores,
    required this.asignaciones,
    required this.onAsignar,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  State<_PasoGestoresMaterias> createState() => _PasoGestoresMateriasState();
}

class _PasoGestoresMateriasState extends State<_PasoGestoresMaterias> {
  Asignatura? _asignaturaSeleccionada;

  @override
  Widget build(BuildContext context) {
    final asignadas = widget.asignaciones.keys.length;
    return Column(
      children: [
        // ── Banner de estado de carga ──────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.gestores.isEmpty
                ? const Color(0xFFFFF8E1)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.gestores.isEmpty
                  ? const Color(0xFFF57F17)
                  : const Color(0xFF66BB6A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.gestores.isEmpty
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                size: 16,
                color: widget.gestores.isEmpty
                    ? const Color(0xFFF57F17)
                    : const Color(0xFF1A6433),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.gestores.isEmpty
                      ? 'API devolvió 0 gestores (rol=GC). Crea usuarios GC en Django Admin.'
                      : '${widget.gestores.length} gestor(es) · ${widget.asignaturas.length} materia(s) · $asignadas asignada(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.gestores.isEmpty
                        ? const Color(0xFFE65100)
                        : const Color(0xFF1A6433),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            children: [
              Text(
                '$asignadas de ${widget.asignaturas.length} materias asignadas',
                style: const TextStyle(color: Color(0xFF2E7D52), fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const Spacer(),
              Text(
                'Toca materia → elige gestor',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lista materias
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EncabezadoColumna(label: 'Materias', icono: Icons.book_outlined),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 6, 12),
                        itemCount: widget.asignaturas.length,
                        itemBuilder: (_, i) {
                          final a = widget.asignaturas[i];
                          final gestorId = widget.asignaciones[a.id];
                          final gestor = gestorId != null
                              ? widget.gestores.firstWhere((g) => g.id == gestorId,
                                  orElse: () => widget.gestores.first)
                              : null;
                          final selec = _asignaturaSeleccionada?.id == a.id;
                          return GestureDetector(
                            onTap: () => setState(() => _asignaturaSeleccionada = a),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selec
                                    ? const Color(0xFF1A6433)
                                    : (gestor != null ? const Color(0xFFE8F5E9) : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selec
                                      ? const Color(0xFF1A6433)
                                      : (gestor != null
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey.shade200),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.nombre,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selec ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    a.codigo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selec
                                          ? Colors.white70
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (gestor != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 10,
                                          color: selec ? Colors.white70 : const Color(0xFF4CAF50),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            gestor.nombre.split(' ').first,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: selec ? Colors.white70 : const Color(0xFF2E7D32),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Separador
              Container(width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 8)),
              // Lista gestores
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EncabezadoColumna(label: 'Gestores', icono: Icons.person_outlined),
                    // ── Diagnóstico: si no hay gestores, mostrar aviso claro ──
                    if (widget.gestores.isEmpty)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFF57F17), size: 36),
                                const SizedBox(height: 10),
                                const Text(
                                  'No hay gestores registrados',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A6433)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Asegúrate de que existan usuarios con rol GC en la API '
                                  '(GET /api/usuarios/?rol=GC debe devolver al menos uno).',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_asignaturaSeleccionada == null)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, color: Colors.grey.shade300, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Selecciona una materia para asignar gestor',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(6, 4, 12, 12),
                          itemCount: widget.gestores.length,
                          itemBuilder: (_, i) {
                            final g = widget.gestores[i];
                            final asignadoActual =
                                widget.asignaciones[_asignaturaSeleccionada!.id] == g.id;
                            // Cuántas materias tiene este gestor
                            final count = widget.asignaciones.values
                                .where((v) => v == g.id)
                                .length;
                            return GestureDetector(
                              onTap: () {
                                widget.onAsignar(_asignaturaSeleccionada!.id, g.id);
                                setState(() => _asignaturaSeleccionada = null);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: asignadoActual
                                      ? const Color(0xFF1A6433)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: asignadoActual
                                        ? const Color(0xFF1A6433)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: asignadoActual
                                              ? Colors.white24
                                              : const Color(0xFFE8F5E9),
                                          child: Text(
                                            g.nombre[0],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: asignadoActual
                                                  ? Colors.white
                                                  : const Color(0xFF1A6433),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            g.nombre,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: asignadoActual ? Colors.white : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$count materia(s)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: asignadoActual ? Colors.white70 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _BotonesNavegacion(onAnterior: widget.onAnterior, onSiguiente: widget.onSiguiente),
      ],
    );
  }
}

class _EncabezadoColumna extends StatelessWidget {
  final String label;
  final IconData icono;

  const _EncabezadoColumna({required this.label, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF5F6FA),
      child: Row(
        children: [
          Icon(icono, size: 14, color: const Color(0xFF2E7D52)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D52),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PASO 4: HORARIOS DE DESCANSO
// ─────────────────────────────────────────────

class _PasoDescanso extends StatelessWidget {
  final List<GestorConocimiento> gestores;
  final bool mismoHorario;
  final HorarioDescanso descansoGeneral;
  final Map<int, HorarioDescanso> descansosPorGestor;
  final TimeOfDay horaFin;
  final ValueChanged<bool> onMismoHorarioChange;
  final ValueChanged<HorarioDescanso> onDescansoGeneralChange;
  final Function(int, HorarioDescanso) onDescansoPorGestorChange;
  final ValueChanged<TimeOfDay> onHoraFinChange;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  const _PasoDescanso({
    super.key,
    required this.gestores,
    required this.mismoHorario,
    required this.descansoGeneral,
    required this.descansosPorGestor,
    required this.horaFin,
    required this.onMismoHorarioChange,
    required this.onDescansoGeneralChange,
    required this.onDescansoPorGestorChange,
    required this.onHoraFinChange,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hora fin de clases
                _SeccionDescanso(
                  titulo: 'Hora de finalización de clases',
                  child: _SelectorHora(
                    label: 'Hora fin',
                    hora: horaFin,
                    onCambiar: (t) => onHoraFinChange(t),
                    context: context,
                  ),
                ),
                const SizedBox(height: 16),

                // Mismo horario para todos
                _SeccionDescanso(
                  titulo: '¿Todos los gestores tienen el mismo horario de almuerzo?',
                  child: Row(
                    children: [
                      Expanded(
                        child: _OpcionSwitch(
                          label: 'Sí, mismo horario',
                          valor: mismoHorario,
                          onChanged: (v) => onMismoHorarioChange(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OpcionSwitch(
                          label: 'No, horarios diferentes',
                          valor: !mismoHorario,
                          onChanged: (v) => onMismoHorarioChange(false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (mismoHorario) ...[
                  _SeccionDescanso(
                    titulo: 'Horario de almuerzo (todos los gestores)',
                    child: Row(
                      children: [
                        Expanded(
                          child: _SelectorHora(
                            label: 'Inicio',
                            hora: descansoGeneral.inicio,
                            onCambiar: (t) => onDescansoGeneralChange(
                                HorarioDescanso(inicio: t, fin: descansoGeneral.fin)),
                            context: context,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectorHora(
                            label: 'Fin',
                            hora: descansoGeneral.fin,
                            onCambiar: (t) => onDescansoGeneralChange(
                                HorarioDescanso(inicio: descansoGeneral.inicio, fin: t)),
                            context: context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...gestores.map((g) {
                    final d = descansosPorGestor[g.id] ??
                        const HorarioDescanso(
                            inicio: TimeOfDay(hour: 12, minute: 0),
                            fin: TimeOfDay(hour: 13, minute: 0));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SeccionDescanso(
                        titulo: g.nombre,
                        child: Row(
                          children: [
                            Expanded(
                              child: _SelectorHora(
                                label: 'Inicio',
                                hora: d.inicio,
                                onCambiar: (t) =>
                                    onDescansoPorGestorChange(g.id, HorarioDescanso(inicio: t, fin: d.fin)),
                                context: context,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SelectorHora(
                                label: 'Fin',
                                hora: d.fin,
                                onCambiar: (t) => onDescansoPorGestorChange(
                                    g.id, HorarioDescanso(inicio: d.inicio, fin: t)),
                                context: context,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        _BotonesNavegacion(onAnterior: onAnterior, onSiguiente: onSiguiente),
      ],
    );
  }
}

class _SeccionDescanso extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _SeccionDescanso({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A6433),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _OpcionSwitch extends StatelessWidget {
  final String label;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _OpcionSwitch({required this.label, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: valor ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: valor ? const Color(0xFF1A6433) : Colors.grey.shade300,
            width: valor ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              valor ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: valor ? const Color(0xFF1A6433) : Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: valor ? const Color(0xFF1A6433) : Colors.grey.shade600,
                  fontWeight: valor ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorHora extends StatelessWidget {
  final String label;
  final TimeOfDay hora;
  final ValueChanged<TimeOfDay> onCambiar;
  final BuildContext context;

  const _SelectorHora({
    required this.label,
    required this.hora,
    required this.onCambiar,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final texto = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: hora);
        if (picked != null) onCambiar(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Color(0xFF2E7D52)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A6433),
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

// ─────────────────────────────────────────────
// PASO 5: GENERACIÓN AUTOMÁTICA
// ─────────────────────────────────────────────

class _PasoGenerarHorario extends StatefulWidget {
  final Map<int, int?> asignaciones;
  final List<Asignatura> asignaturas;
  final List<GestorConocimiento> gestores;
  final bool mismoDescanso;
  final HorarioDescanso descansoGeneral;
  final Map<int, HorarioDescanso> descansosPorGestor;
  final TimeOfDay horaFin;
  final VoidCallback? onAnterior;
  final ValueChanged<List<BloquHorario>> onGenerar;

  const _PasoGenerarHorario({
    super.key,
    required this.asignaciones,
    required this.asignaturas,
    required this.gestores,
    required this.mismoDescanso,
    required this.descansoGeneral,
    required this.descansosPorGestor,
    required this.horaFin,
    required this.onAnterior,
    required this.onGenerar,
  });

  @override
  State<_PasoGenerarHorario> createState() => _PasoGenerarHorarioState();
}

class _PasoGenerarHorarioState extends State<_PasoGenerarHorario> {
  bool _generando = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResumenConfiguracion(
                  asignaciones: widget.asignaciones,
                  asignaturas: widget.asignaturas,
                  gestores: widget.gestores,
                  mismoDescanso: widget.mismoDescanso,
                  descansoGeneral: widget.descansoGeneral,
                  horaFin: widget.horaFin,
                ),
                const SizedBox(height: 20),
                const _ReglaCard(
                  icono: Icons.block,
                  color: Color(0xFFFFEBEE),
                  colorIcono: Color(0xFFC62828),
                  titulo: 'Sin cruces de horarios',
                  desc: 'No se permite que dos asignaturas compartan el mismo salón/gestor al mismo tiempo.',
                ),
                const SizedBox(height: 10),
                const _ReglaCard(
                  icono: Icons.access_time,
                  color: Color(0xFFE3F2FD),
                  colorIcono: Color(0xFF1565C0),
                  titulo: 'Inicio: 7:00 AM',
                  desc: 'Las clases comienzan a las 7:00 a.m. y se distribuyen hasta la hora de finalización definida.',
                ),
                const SizedBox(height: 10),
                const _ReglaCard(
                  icono: Icons.balance,
                  color: Color(0xFFE8F5E9),
                  colorIcono: Color(0xFF2E7D32),
                  titulo: 'Carga equilibrada',
                  desc: 'Las asignaturas se distribuyen equitativamente entre los días de la semana.',
                ),
                const SizedBox(height: 10),
                const _ReglaCard(
                  icono: Icons.restaurant,
                  color: Color(0xFFFFF8E1),
                  colorIcono: Color(0xFFF57F17),
                  titulo: 'Respeto a descansos',
                  desc: 'Los horarios de almuerzo de los gestores son bloques protegidos.',
                ),
              ],
            ),
          ),
        ),
        if (_generando)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                //CircularProgressIndicator(color: Color(0xFF1A6433)),
                SizedBox(height: 12),
                Text('Generando horario óptimo...', style: TextStyle(color: Color(0xFF2E7D52))),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (widget.onAnterior != null)
                  OutlinedButton.icon(
                    onPressed: widget.onAnterior,
                    icon: const Icon(Icons.arrow_back_ios, size: 14),
                    label: const Text('Anterior'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A6433),
                      side: const BorderSide(color: Color(0xFF1A6433)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _generarHorario,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generar Horario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6433),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _generarHorario() async {
    setState(() => _generando = true);

    // Simular tiempo de procesamiento
    await Future.delayed(const Duration(milliseconds: 1500));

    final horario = _algoritmoGenerarHorario();
    setState(() => _generando = false);
    widget.onGenerar(horario);
  }

  // ─── ALGORITMO DE GENERACIÓN ───────────────────────────────────────────────
  // Distribuye asignaturas en bloques de 2 horas entre LUN-VIE,
  // respetando cruces de gestor y bloque de almuerzo.
  List<BloquHorario> _algoritmoGenerarHorario() {
    final List<BloquHorario> resultado = [];

    // Preparar asignaciones con objetos completos
    final List<AsignacionGestor> asignaciones = [];
    for (final entry in widget.asignaciones.entries) {
      if (entry.value == null) continue;
      final asig = widget.asignaturas.firstWhere((a) => a.id == entry.key,
          orElse: () => widget.asignaturas.first);
      final gestor = widget.gestores.firstWhere((g) => g.id == entry.value,
          orElse: () => widget.gestores.first);
      asignaciones.add(AsignacionGestor(asignatura: asig, gestor: gestor));
    }

    // Índice de ocupación: dia → lista de (inicio, fin, gestorId)
    final Map<String, List<Map<String, dynamic>>> ocupacion = {
      for (final d in kDias) d: [],
    };

    // Distribuir equitativamente por días (round-robin)
    int diaIdx = 0;
    const TimeOfDay kInicioClases = TimeOfDay(hour: 7, minute: 0);
    const int kDuracionBloque = 2; // horas por bloque

    // Ordenar para distribuir equitativamente
    final List<String> diasOrden = List.from(kDias);

    for (final asig in asignaciones) {
      bool colocado = false;
      int intentos = 0;

      while (!colocado && intentos < kDias.length * 3) {
        final dia = diasOrden[diaIdx % diasOrden.length];
        diaIdx++;
        intentos++;

        final descanso = widget.mismoDescanso
            ? widget.descansoGeneral
            : (widget.descansosPorGestor[asig.gestor.id] ?? widget.descansoGeneral);

        // Encontrar próximo slot libre en este día para este gestor
        final slot = _encontrarSlot(
          dia: dia,
          ocupacion: ocupacion[dia]!,
          gestorId: asig.gestor.id,
          descanso: descanso,
          horaInicio: kInicioClases,
          horaFin: widget.horaFin,
          duracion: kDuracionBloque,
        );

        if (slot != null) {
          resultado.add(BloquHorario(
            dia: dia,
            inicio: slot['inicio'],
            fin: slot['fin'],
            asignatura: asig.asignatura,
            gestor: asig.gestor,
            salon: 'S-${(resultado.length % 10) + 101}',
          ));
          ocupacion[dia]!.add({
            'inicio': slot['inicio'],
            'fin': slot['fin'],
            'gestorId': asig.gestor.id,
          });
          colocado = true;
        }
      }
    }

    return resultado;
  }

  Map<String, dynamic>? _encontrarSlot({
    required String dia,
    required List<Map<String, dynamic>> ocupacion,
    required int gestorId,
    required HorarioDescanso descanso,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    required int duracion,
  }) {
    int horaActual = horaInicio.hour;
    int minActual = horaInicio.minute;

    while (true) {
      final finBloque = horaActual + duracion;
      if (finBloque > horaFin.hour || (finBloque == horaFin.hour && horaFin.minute == 0)) break;

      final inicioT = TimeOfDay(hour: horaActual, minute: minActual);
      final finT = TimeOfDay(hour: finBloque, minute: minActual);

      // Verificar cruce con descanso
      if (_cruceConDescanso(inicioT, finT, descanso)) {
        // Saltar al fin del descanso
        horaActual = descanso.fin.hour;
        minActual = descanso.fin.minute;
        continue;
      }

      // Verificar cruce con otros bloques del mismo gestor en este día
      bool cruce = false;
      for (final bloque in ocupacion) {
        if (bloque['gestorId'] == gestorId) {
          final bIni = bloque['inicio'] as TimeOfDay;
          final bFin = bloque['fin'] as TimeOfDay;
          if (_timeOverlap(inicioT, finT, bIni, bFin)) {
            cruce = true;
            horaActual = bFin.hour;
            minActual = bFin.minute;
            break;
          }
        }
      }

      if (!cruce) {
        return {'inicio': inicioT, 'fin': finT};
      }
    }
    return null;
  }

  bool _cruceConDescanso(TimeOfDay ini, TimeOfDay fin, HorarioDescanso d) {
    return _toMin(ini) < _toMin(d.fin) && _toMin(fin) > _toMin(d.inicio);
  }

  bool _timeOverlap(TimeOfDay ai, TimeOfDay af, TimeOfDay bi, TimeOfDay bf) {
    return _toMin(ai) < _toMin(bf) && _toMin(af) > _toMin(bi);
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;
}

class _ResumenConfiguracion extends StatelessWidget {
  final Map<int, int?> asignaciones;
  final List<Asignatura> asignaturas;
  final List<GestorConocimiento> gestores;
  final bool mismoDescanso;
  final HorarioDescanso descansoGeneral;
  final TimeOfDay horaFin;

  const _ResumenConfiguracion({
    required this.asignaciones,
    required this.asignaturas,
    required this.gestores,
    required this.mismoDescanso,
    required this.descansoGeneral,
    required this.horaFin,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = (TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de configuración',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A6433)),
          ),
          const SizedBox(height: 8),
          _FilaResumen(
            icono: Icons.book,
            texto: '${asignaciones.length} materia(s) con gestor asignado',
          ),
          _FilaResumen(
            icono: Icons.schedule,
            texto: '7:00 – ${fmt(horaFin)}',
          ),
          _FilaResumen(
            icono: Icons.restaurant,
            texto: mismoDescanso
                ? 'Almuerzo general: ${descansoGeneral.label}'
                : 'Almuerzos personalizados por gestor',
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _FilaResumen({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icono, size: 14, color: const Color(0xFF2E7D52)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E3B))),
          ),
        ],
      ),
    );
  }
}

class _ReglaCard extends StatelessWidget {
  final IconData icono;
  final Color color;
  final Color colorIcono;
  final String titulo;
  final String desc;

  const _ReglaCard({
    required this.icono,
    required this.color,
    required this.colorIcono,
    required this.titulo,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, color: colorIcono, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorIcono)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12, color: colorIcono.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PASO 6: VISUALIZAR HORARIO
// ─────────────────────────────────────────────

class _PasoVisualizarHorario extends StatelessWidget {
  final List<BloquHorario> horario;
  final String semestre;
  final VoidCallback onReacomodar;
  final VoidCallback onGuardar;

  const _PasoVisualizarHorario({
    super.key,
    required this.horario,
    required this.semestre,
    required this.onReacomodar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    // Agrupar por día
    final Map<String, List<BloquHorario>> porDia = {};
    for (final dia in kDias) {
      porDia[dia] = horario.where((b) => b.dia == dia).toList()
        ..sort((a, b) => a.inicio.hour * 60 + a.inicio.minute - (b.inicio.hour * 60 + b.inicio.minute));
    }

    return Column(
      children: [
        // Encabezado semestre
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.calendar_view_week, color: Color(0xFF2E7D52), size: 18),
              const SizedBox(width: 8),
              Text(
                'Semestre $semestre  ·  ${horario.length} bloque(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A6433),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kDias.length,
            itemBuilder: (_, i) {
              final dia = kDias[i];
              final bloques = porDia[dia]!;
              return _TarjetaDia(dia: dia, bloques: bloques);
            },
          ),
        ),
        // Botones guardar / reacomodar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReacomodar,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reacomodar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A6433),
                    side: const BorderSide(color: Color(0xFF1A6433)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGuardar,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6433),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaDia extends StatelessWidget {
  final String dia;
  final List<BloquHorario> bloques;

  const _TarjetaDia({required this.dia, required this.bloques});

  static const List<Color> kColoresAsig = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFFB71C1C),
    Color(0xFF1B5E3B),
    Color(0xFF33691E),
    Color(0xFF4A148C),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6433),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Text(
                  kDiasLabel[dia] ?? dia,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bloques.length} clase(s)',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          if (bloques.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Sin clases este día',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ...bloques.asMap().entries.map((e) {
              final bloque = e.value;
              final color = kColoresAsig[bloque.asignatura.id % kColoresAsig.length];
              final fmt = (TimeOfDay t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              return Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100),
                    left: BorderSide(color: color, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bloque.asignatura.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bloque.gestor.nombre,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            'Salón: ${bloque.salon}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt(bloque.inicio),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A6433),
                          ),
                        ),
                        Text(
                          '↓ ${fmt(bloque.fin)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
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