import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────

const List<String> kDiasOrden = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE'];
const Map<String, String> kDiasLabel = {
  'LUN': 'Lunes',
  'MAR': 'Martes',
  'MIE': 'Miércoles',
  'JUE': 'Jueves',
  'VIE': 'Viernes',
};
const List<String> kSemestres = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

// ─────────────────────────────────────────────
// MODELO
// ─────────────────────────────────────────────

class BloqueHorarioApi {
  final int id;
  final String asignatura;
  final int asignaturaId;
  final String gestor;
  final int gestorId;
  final String? salon;
  final String horaInicio;
  final String horaFin;

  const BloqueHorarioApi({
    required this.id,
    required this.asignatura,
    required this.asignaturaId,
    required this.gestor,
    required this.gestorId,
    this.salon,
    required this.horaInicio,
    required this.horaFin,
  });

  factory BloqueHorarioApi.fromJson(Map<String, dynamic> json) {
    return BloqueHorarioApi(
      id:           json['id'] as int,
      asignatura:   json['asignatura'] as String,
      asignaturaId: json['asignatura_id'] as int,
      gestor:       json['gestor'] as String,
      gestorId:     json['gestor_id'] as int,
      salon:        json['salon'] as String?,
      horaInicio:   json['hora_inicio'] as String,
      horaFin:      json['hora_fin'] as String,
    );
  }

  String get horaInicioCorta => horaInicio.length >= 5 ? horaInicio.substring(0, 5) : horaInicio;
  String get horaFinCorta    => horaFin.length >= 5    ? horaFin.substring(0, 5)    : horaFin;
}

// ─────────────────────────────────────────────
// SERVICIO API
// ─────────────────────────────────────────────

class HorarioVistaService {
  // ── Ajusta igual que en crearHorario.dart ──
  // Emulador Android:  'http://10.0.2.2:8000/api'
  // Dispositivo físico: 'http://192.168.X.X:8000/api'
  // Web / iOS Sim:     'http://localhost:8000/api'
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  final String? authToken;
  const HorarioVistaService({this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Token $authToken',
      };

  Future<Map<String, List<BloqueHorarioApi>>> fetchHorario(
      String semestre) async {
    final uri =
        Uri.parse('$_baseUrl/horarios/por_semestre/?semestre=$semestre');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> raw =
          jsonDecode(utf8.decode(response.bodyBytes));

      return raw.map((dia, bloques) => MapEntry(
            dia,
            (bloques as List)
                .map((b) =>
                    BloqueHorarioApi.fromJson(b as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio)),
          ));
    }
    throw Exception(
        'Error al cargar horario (${response.statusCode}): ${response.body}');
  }
}

// ─────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────

class HorariosScreen extends StatefulWidget {
  final String? authToken;

  const HorariosScreen({super.key, this.authToken});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen>
    with SingleTickerProviderStateMixin {
  late final HorarioVistaService _api;
  late final TabController _tabController;

  String _semestreSeleccionado = kSemestres.first;
  Map<String, List<BloqueHorarioApi>> _horario = {};
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = HorarioVistaService(authToken: widget.authToken);
    _tabController =
        TabController(length: kDiasOrden.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _api.fetchHorario(_semestreSeleccionado);
      if (!mounted) return;
      setState(() {
        _horario = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  int get _totalBloques =>
      _horario.values.fold(0, (s, l) => s + l.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        //backgroundColor: const Color(0xFF1A6433),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Horarios',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // ── Selector de semestre ─────────────────────────────
              Container(
                height: 44,
                color: const Color(0xFF155227),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  itemCount: kSemestres.length,
                  itemBuilder: (_, i) {
                    final s = kSemestres[i];
                    final sel = s == _semestreSeleccionado;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _semestreSeleccionado = s);
                        _cargar();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Semestre: $s',
                          style: TextStyle(
                            color: sel
                                ? const Color(0xFF1A6433)
                                : Colors.white,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ── Pestañas por día ─────────────────────────────────
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 12),
                tabs: kDiasOrden.map((d) {
                  final count = _horario[d]?.length ?? 0;
                  return Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(kDiasLabel[d]!.substring(0, 3)),
                        if (count > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$count',
                                style: const TextStyle(fontSize: 9)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //CircularProgressIndicator(color: Color(0xFF1A6433)),
            SizedBox(height: 16),
            Text('Cargando horario...',
                style: TextStyle(color: Color(0xFF2E7D52))),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFC62828), size: 48),
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el horario',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    //color: Color(0xFF1A6433),
                    fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  //backgroundColor: const Color(0xFF1A6433),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_totalBloques == 0) {
      return _PantallaSinHorario(semestre: _semestreSeleccionado);
    }

    return Column(
      children: [
        // Banner resumen
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.calendar_view_week,
                  color: Color(0xFF2E7D52), size: 16),
              const SizedBox(width: 8),
              Text(
                'Semestre $_semestreSeleccionado  ·  $_totalBloques clase(s)',
                style: const TextStyle(
                    //color: Color(0xFF1A6433),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: kDiasOrden.map((dia) {
              final bloques = _horario[dia] ?? [];
              return _VistaDia(dia: dia, bloques: bloques);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// VISTA DE UN DÍA
// ─────────────────────────────────────────────

class _VistaDia extends StatelessWidget {
  final String dia;
  final List<BloqueHorarioApi> bloques;

  const _VistaDia({required this.dia, required this.bloques});

  static const List<Color> kColores = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFFB71C1C),
    Color(0xFF1A6433),
    Color(0xFF33691E),
    Color(0xFF4A148C),
  ];

  @override
  Widget build(BuildContext context) {
    if (bloques.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available,
                color: Colors.grey.shade300, size: 52),
            const SizedBox(height: 12),
            Text(
              'Sin clases el ${kDiasLabel[dia]}',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bloques.length,
      itemBuilder: (_, i) {
        final b = bloques[i];
        final color = kColores[b.asignaturaId % kColores.length];
        return _TarjetaBloque(bloque: b, color: color);
      },
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE BLOQUE
// ─────────────────────────────────────────────

class _TarjetaBloque extends StatelessWidget {
  final BloqueHorarioApi bloque;
  final Color color;

  const _TarjetaBloque({required this.bloque, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Franja de color izquierda
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10)),
              ),
            ),
            // Columna de hora
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                border: Border(
                    right: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bloque.horaInicioCorta,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color),
                  ),
                  const SizedBox(height: 2),
                  Icon(Icons.arrow_downward,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(height: 2),
                  Text(
                    bloque.horaFinCorta,
                    style: TextStyle(
                        fontSize: 13,
                        color: color.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bloque.asignatura,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _FilaInfo(
                      icono: Icons.person_outline,
                      texto: bloque.gestor,
                    ),
                    if (bloque.salon != null) ...[
                      const SizedBox(height: 3),
                      _FilaInfo(
                        icono: Icons.room_outlined,
                        texto: 'Salón ${bloque.salon}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _FilaInfo({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            texto,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA SIN HORARIO
// ─────────────────────────────────────────────

class _PantallaSinHorario extends StatelessWidget {
  final String semestre;

  const _PantallaSinHorario({required this.semestre});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF1A6433), size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin horario para el semestre $semestre',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A6433)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Crea el horario desde "Crear Horario" y guárdalo para verlo aquí.',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}