import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE DATOS
// ─────────────────────────────────────────────────────────────────────────────

/// Representa la información de un salón de clases disponible en la API.
class SalonItem {
  final dynamic id;
  final String codigo;
  final int? capacidad;
  final String? edificio;

  /// 'AULA' (aula convencional) o 'COMP' (sala de cómputo).
  final String tipo;

  const SalonItem({
    required this.id,
    required this.codigo,
    this.capacidad,
    this.edificio,
    this.tipo = 'AULA',
  });

  bool get esComputo => tipo == 'COMP';

  factory SalonItem.fromJson(Map<String, dynamic> json) {
    return SalonItem(
      id: json['id'] ?? json['codigo'],
      codigo: json['codigo']?.toString() ?? 'Sin código',
      capacidad: json['capacidad'] is int
          ? json['capacidad'] as int
          : int.tryParse(json['capacidad']?.toString() ?? ''),
      edificio: json['edificio']?.toString(),
      tipo: json['tipo']?.toString() ?? 'AULA',
    );
  }

  String get descripcionCompleta {
    final partes = <String>[codigo];
    if (edificio != null && edificio!.isNotEmpty) partes.add('Edif: $edificio');
    if (capacidad != null && capacidad! > 0) partes.add('Cap: $capacidad');
    partes.add(esComputo ? 'Sala de cómputo' : 'Aula');
    return partes.join(' - ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalonItem &&
          runtimeType == other.runtimeType &&
          id.toString() == other.id.toString();

  @override
  int get hashCode => id.toString().hashCode;
}

/// Helper para identificación y horarios predefinidos de Núcleos Temáticos CAI.
class CaiHelper {
  static const List<String> kCodigosCaiConocidos = [
    'DN-CAI1002020202',
    'DN-CAI1002020201',
    'CAI1002020202',
    'DN-CAI1002020303',
    'DN-CAI1002020304',
    'CAI1002020201',
    'CAI1002020303',
    'CAI1002020305',
    'CAI1002020304',
    'CAI1002020406',
    'DN-CAI1002020613',
    'DN-CAI1002020612',
    'CAI1002020507',
  ];

  /// Determina si una asignatura corresponde a un Núcleo CAI.
  static bool esCai(String codigo, [String? nombre]) {
    final cod = codigo.toUpperCase();
    final nom = (nombre ?? '').toUpperCase();
    if (cod.contains('CAI') || nom.contains('CAI')) return true;
    for (final c in kCodigosCaiConocidos) {
      if (cod.contains(c.toUpperCase())) return true;
    }
    return false;
  }

  /// Retorna el horario predefinido bloqueado e inalterable para un Núcleo CAI.
  static Map<String, String> horarioPredefinido(String codigo, [String? nombre]) {
    final cod = codigo.toUpperCase();
    final nom = (nombre ?? '').toUpperCase();

    if (cod.contains('1002020202') || nom.contains('LECTURA CRÍTICA') || nom.contains('COMUNICACIÓN')) {
      return {'dia': 'VIE', 'hora_inicio': '07:00:00', 'hora_fin': '09:00:00'};
    }
    if (cod.contains('1002020201') || nom.contains('RAZONAMIENTO')) {
      return {'dia': 'VIE', 'hora_inicio': '09:00:00', 'hora_fin': '11:00:00'};
    }
    if (cod.contains('1002020303') || nom.contains('CIUDADANIA') || nom.contains('CIUDADANÍA')) {
      return {'dia': 'VIE', 'hora_inicio': '11:00:00', 'hora_fin': '13:00:00'};
    }
    if (cod.contains('1002020304') || nom.contains('LENGUA EXTRANJERA')) {
      return {'dia': 'SAB', 'hora_inicio': '08:00:00', 'hora_fin': '12:00:00'};
    }
    if (cod.contains('1002020612') || nom.contains('EMPRENDIMIENTO')) {
      return {'dia': 'VIE', 'hora_inicio': '14:00:00', 'hora_fin': '16:00:00'};
    }
    if (cod.contains('1002020613') || nom.contains('TECNOLOGIA') || nom.contains('INNOVACION') || nom.contains('INNOVACIÓN')) {
      return {'dia': 'VIE', 'hora_inicio': '16:00:00', 'hora_fin': '18:00:00'};
    }
    // Horario por defecto protegido para CAI
    return {'dia': 'VIE', 'hora_inicio': '08:00:00', 'hora_fin': '10:00:00'};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE CONFLICTO
// ─────────────────────────────────────────────────────────────────────────────

/// Representa un único conflicto de horario devuelto por la API.
class ConflictoHorario {
  /// Descripción legible del conflicto (proveniente de la API o traducida).
  final String mensaje;

  /// Código de la regla incumplida (SALON_OCUPADO, GRUPO_OCUPADO, ...), si la API lo envía.
  final String? tipo;

  /// Identificador del horario existente que causa el conflicto, si la API lo incluye.
  final int? horarioConflictoId;

  /// Datos adicionales del horario en conflicto.
  final Map<String, dynamic>? detalleConflicto;

  const ConflictoHorario({
    required this.mensaje,
    this.tipo,
    this.horarioConflictoId,
    this.detalleConflicto,
  });

  factory ConflictoHorario.fromJson(dynamic json) {
    if (json is String) {
      return ConflictoHorario(mensaje: _traducirMensaje(json));
    }
    if (json is Map) {
      final msg = (json['mensaje'] ?? json['detail'] ?? json['error'] ?? json.toString()).toString();
      final tipo = json['tipo']?.toString();
      return ConflictoHorario(
        // Los mensajes con `tipo` ya vienen redactados en español por la API.
        mensaje: tipo != null ? msg : _traducirMensaje(msg),
        tipo: tipo,
        // DRF serializa los valores de un ValidationError como texto ("15" / "None"),
        // por eso NO se puede hacer `as int?`: se convierte de forma segura.
        horarioConflictoId: int.tryParse('${json['horario_id'] ?? ''}'),
        detalleConflicto: json['detalle'] is Map
            ? Map<String, dynamic>.from(json['detalle'] as Map)
            : null,
      );
    }
    return ConflictoHorario(mensaje: _traducirMensaje(json.toString()));
  }

  static String _traducirMensaje(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('classroom') || lower.contains('salon') || lower.contains('room')) {
      if (lower.contains('already occupied') || lower.contains('ocupado') || lower.contains('conflict')) {
        return 'El salón seleccionado ya está ocupado en ese horario.';
      }
    }
    if (lower.contains('teacher') || lower.contains('gestor') || lower.contains('professor')) {
      if (lower.contains('already') || lower.contains('ocupado') || lower.contains('overlap')) {
        return 'El gestor ya tiene una clase asignada durante ese intervalo.';
      }
    }
    if (lower.contains('max') && (lower.contains('hour') || lower.contains('hora'))) {
      return 'Se supera el máximo de horas diarias permitido.';
    }
    if (lower.contains('start') && lower.contains('end') || lower.contains('hora de fin')) {
      return 'La hora de fin debe ser posterior a la hora de inicio.';
    }
    return raw;
  }
}

/// Resultado completo de la validación de un bloque propuesto.
class ResultadoValidacion {
  final bool valido;

  /// Restricciones DURAS incumplidas: impiden guardar.
  final List<ConflictoHorario> conflictos;

  /// Restricciones BLANDAS (almuerzo, ventanas, carga desequilibrada, tamaño de grupo).
  final List<ConflictoHorario> advertencias;

  /// Horas asignadas del núcleo, carga semanal del gestor, inscritos, etc.
  final Map<String, dynamic>? resumen;

  const ResultadoValidacion({
    required this.valido,
    required this.conflictos,
    this.advertencias = const [],
    this.resumen,
  });

  factory ResultadoValidacion.exitoso() =>
      const ResultadoValidacion(valido: true, conflictos: []);
}

/// Resultado del intento de guardar un bloque individual.
class ResultadoGuardado {
  final Map<String, dynamic>? bloqueGuardado;
  final List<ConflictoHorario> conflictos;
  final int statusCode;

  bool get exitoso => (statusCode == 200 || statusCode == 201) && conflictos.isEmpty;

  const ResultadoGuardado({
    this.bloqueGuardado,
    required this.conflictos,
    required this.statusCode,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ERRORES DE LA API
// ─────────────────────────────────────────────────────────────────────────────

/// Error de una operación genérica del cliente HTTP.
class ApiException implements Exception {
  /// Mensaje legible para mostrar al usuario.
  final String mensaje;

  /// Código HTTP, o null si no se llegó a obtener respuesta.
  final int? statusCode;

  /// true si el fallo fue de conexión (servidor caído, sin red, tiempo agotado).
  final bool esConexion;

  /// Errores por campo devueltos por la API (400), p. ej. {'email': 'Ya existe…'}.
  final Map<String, String> errores;

  /// Registros asociados que bloquean una eliminación (409), si la API los envía.
  final Map<String, dynamic>? dependencias;

  const ApiException(
    this.mensaje, {
    this.statusCode,
    this.esConexion = false,
    this.errores = const {},
    this.dependencias,
  });

  factory ApiException.conexion(String mensaje) =>
      ApiException(mensaje, esConexion: true);

  factory ApiException.desdeRespuesta(
      int statusCode, String body, String mensajePorDefecto) {
    String mensaje = mensajePorDefecto;
    final errores = <String, String>{};
    Map<String, dynamic>? dependencias;
    try {
      final d = jsonDecode(body);
      if (d is Map) {
        if (d['dependencias'] is Map) {
          dependencias = Map<String, dynamic>.from(d['dependencias'] as Map);
        }
        final general = d['error'] ?? d['detail'];
        if (general != null) {
          mensaje = general.toString();
        } else {
          for (final e in d.entries) {
            final v = e.value;
            errores[e.key.toString()] =
                v is List ? v.map((x) => x.toString()).join(' ') : v.toString();
          }
          if (errores.isNotEmpty) {
            mensaje = errores.values.join('\n');
          }
        }
      }
    } catch (_) {}
    if (statusCode == 401) {
      mensaje = 'Tu sesión no está iniciada o expiró. Inicia sesión de nuevo.';
    }
    return ApiException(mensaje,
        statusCode: statusCode, errores: errores, dependencias: dependencias);
  }

  @override
  String toString() => mensaje;
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENTE HTTP PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

/// Renueva el token de acceso de la sesión con `POST /api/token/refresh/`.
///
/// Devuelve true si obtuvo un token nuevo. Si el refresh es inválido o venció,
/// cierra la sesión local; sin conexión conserva la sesión.
Future<bool> renovarSesionApi() async {
  final refresh = SesionApi.refresh;
  if (refresh == null) return false;
  try {
    final r = await http
        .post(
          Uri.parse('$kBaseUrl/token/refresh/'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refresh}),
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode == 200) {
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      if (d is Map && d['access'] != null) {
        SesionApi.token = d['access'].toString();
        if (d['refresh'] != null) SesionApi.refresh = d['refresh'].toString();
        return true;
      }
    }
    SesionApi.limpiar();
  } catch (_) {
    // Sin conexión: se conserva la sesión y se informa el 401 original.
  }
  return false;
}

/// Cliente HTTP para todos los endpoints de horarios.
class HorarioHttpClient {
  final String? authToken;

  const HorarioHttpClient({this.authToken});

  Map<String, String> get _headers {
    // Token explícito o, si no hay, el de la sesión iniciada.
    final token = authToken ?? SesionApi.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ejecuta la petición y, si el token de acceso venció (401), lo renueva una vez
  /// y repite la solicitud (la cabecera se reconstruye dentro de `peticion`).
  Future<http.Response> _conRenovacion(
      Future<http.Response> Function() peticion) async {
    var r = await peticion();
    if (r.statusCode == 401 && authToken == null && await renovarSesionApi()) {
      r = await peticion();
    }
    return r;
  }

  /// Cabeceras de las operaciones genéricas: usa `authToken` o, si no hay,
  /// el token de la sesión (`SesionApi`). Los métodos anteriores no cambian.
  Map<String, String> get _headersSesion {
    final token = authToken ?? SesionApi.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<ConflictoHorario> _parsearConflictos(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('conflictos')) {
          final lista = decoded['conflictos'];
          if (lista is List) {
            return lista.map((e) => ConflictoHorario.fromJson(e)).toList();
          }
        }
        if (decoded.containsKey('error')) {
          return [ConflictoHorario.fromJson(decoded['error'])];
        }
        if (decoded.containsKey('detail')) {
          return [ConflictoHorario.fromJson(decoded['detail'])];
        }
        final List<ConflictoHorario> erroresCampo = [];
        for (final entry in decoded.entries) {
          final valor = entry.value;
          if (valor is List) {
            for (final msg in valor) {
              erroresCampo.add(ConflictoHorario(
                  mensaje: '${entry.key}: ${msg.toString()}'));
            }
          } else {
            erroresCampo.add(
                ConflictoHorario(mensaje: '${entry.key}: ${valor.toString()}'));
          }
        }
        if (erroresCampo.isNotEmpty) return erroresCampo;
      }
      if (decoded is List) {
        return decoded.map((e) => ConflictoHorario.fromJson(e)).toList();
      }
      if (decoded is String) {
        return [ConflictoHorario.fromJson(decoded)];
      }
    } catch (_) {}
    return [ConflictoHorario(mensaje: body.isNotEmpty ? body : 'Error desconocido al validar horario')];
  }

  /// Conflictos a mostrar cuando la API responde con un estado no previsto.
  /// En 403 se muestra el motivo que envía el servidor (p. ej. "tu usuario no
  /// tiene un programa asignado" o "la asignatura no pertenece a tu programa").
  List<ConflictoHorario> _conflictosDeEstado(http.Response r) {
    if (r.statusCode == 403) {
      final c = _parsearConflictos(utf8.decode(r.bodyBytes));
      if (c.isNotEmpty) return c;
    }
    return [ConflictoHorario(mensaje: _mensajeDeEstado(r.statusCode))];
  }

  String _mensajeDeEstado(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'La solicitud contiene datos inválidos o presenta conflictos.';
      case 401:
        return 'No autorizado. Inicia sesión nuevamente.';
      case 403:
        return 'No tienes permiso para realizar esta operación.';
      case 404:
        return 'Recurso no encontrado. Verifica la configuración de la API.';
      case 500:
        return 'Error interno del servidor. Intenta más tarde.';
      default:
        return 'Error inesperado de la API ($statusCode).';
    }
  }

  // ── Métodos públicos ──────────────────────────────────────────────────────

  /// GET /api/horarios/por_semestre/?semestre=X
  Future<Map<String, List<Map<String, dynamic>>>> fetchHorarioPorSemestre(
      String semestre) async {
    try {
      final uri =
          Uri.parse('$kBaseUrl/horarios/por_semestre/?semestre=$semestre');
      final response = await _conRenovacion(() =>
          http.get(uri, headers: _headers).timeout(const Duration(seconds: 15)));

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
      // ApiException conserva el código HTTP (401, 403...) para que la pantalla
      // distinga sesión vencida, falta de permiso y errores del servidor.
      throw ApiException.desdeRespuesta(response.statusCode,
          utf8.decode(response.bodyBytes), _mensajeDeEstado(response.statusCode));
    } on Exception {
      rethrow;
    } catch (e, st) {
      developer.log('fetchHorarioPorSemestre error', name: 'HorarioHttpClient', error: e, stackTrace: st);
      throw ApiException.conexion(_mensajeDeErrorConexion(e));
    }
  }

  /// GET /api/asignaturas/
  Future<List<Map<String, dynamic>>> fetchAsignaturas() async {
    return _getList('$kBaseUrl/asignaturas/');
  }

  /// GET /api/usuarios/?rol=GC
  Future<List<Map<String, dynamic>>> fetchGestores() async {
    return _getList('$kBaseUrl/usuarios/?rol=GC');
  }

  /// GET /api/salones/
  Future<List<SalonItem>> fetchSalones() async {
    final list = await _getList('$kBaseUrl/salones/');
    return list.map((j) => SalonItem.fromJson(j)).toList();
  }

  Future<List<Map<String, dynamic>>> _getList(String url) async {
    try {
      final response = await _conRenovacion(() => http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15)));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        dynamic parsed = jsonDecode(body);
        List<dynamic> data;
        if (parsed is List) {
          data = parsed;
        } else if (parsed is Map && parsed.containsKey('results')) {
          data = parsed['results'] as List<dynamic>;
        } else {
          data = [];
        }
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw ApiException.desdeRespuesta(response.statusCode,
          utf8.decode(response.bodyBytes), _mensajeDeEstado(response.statusCode));
    } on Exception {
      rethrow;
    } catch (e) {
      throw ApiException.conexion(_mensajeDeErrorConexion(e));
    }
  }

  /// POST /api/horarios/validar/
  ///
  /// Valida el bloque antes de guardar. Envía salón obligatorio y campos del contrato.
  Future<ResultadoValidacion> validarBloque({
    required int asignaturaId,
    required dynamic salon,
    required int gestorId,
    required String dia,
    required String horaInicio,
    required String horaFin,
    required String semestre,
    int? horarioExcluidoId,
  }) async {
    try {
      final uri = Uri.parse('$kBaseUrl/horarios/validar/');
      final body = jsonEncode({
        'asignatura': asignaturaId,
        'salon': salon,
        'gestor': gestorId,
        'dia': dia,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'semestre': semestre,
        if (horarioExcluidoId != null) 'horario_id': horarioExcluidoId,
      });

      final response = await _conRenovacion(() => http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15)));

      developer.log(
        'validarBloque → ${response.statusCode}: ${response.body}',
        name: 'HorarioHttpClient',
      );

      if (response.statusCode == 200) {
        // La API responde 200 incluso cuando hay conflictos: hay que leer `valido`.
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          List<ConflictoHorario> leer(dynamic l) => l is List
              ? l.map((e) => ConflictoHorario.fromJson(e)).toList()
              : <ConflictoHorario>[];
          final conflictos = leer(decoded['conflictos']);
          return ResultadoValidacion(
            valido: decoded['valido'] == true && conflictos.isEmpty,
            conflictos: conflictos,
            advertencias: leer(decoded['advertencias']),
            resumen: decoded['resumen'] is Map
                ? Map<String, dynamic>.from(decoded['resumen'] as Map)
                : null,
          );
        }
        return ResultadoValidacion.exitoso();
      }
      if (response.statusCode == 204) {
        return ResultadoValidacion.exitoso();
      }
      if (response.statusCode == 400) {
        final conflictos = _parsearConflictos(response.body);
        return ResultadoValidacion(valido: false, conflictos: conflictos);
      }
      if (response.statusCode == 404) {
        developer.log(
          'POST /api/horarios/validar/ no disponible (404). Validación delegada a POST definitivo.',
          name: 'HorarioHttpClient',
        );
        return ResultadoValidacion.exitoso();
      }
      return ResultadoValidacion(
        valido: false,
        conflictos: _conflictosDeEstado(response),
      );
    } on Exception catch (e) {
      developer.log('validarBloque: error de conexión', name: 'HorarioHttpClient', error: e);
      return ResultadoValidacion(
        valido: false,
        conflictos: [ConflictoHorario(mensaje: _mensajeDeErrorConexion(e))],
      );
    }
  }

  /// POST /api/horarios/
  ///
  /// Guarda un nuevo horario asegurando el envío del campo `salon` obligatorio.
  Future<ResultadoGuardado> guardarBloque({
    required int asignaturaId,
    required dynamic salon,
    required int gestorId,
    required String dia,
    required String horaInicio,
    required String horaFin,
    required String semestre,
  }) async {
    try {
      final uri = Uri.parse('$kBaseUrl/horarios/');
      final bodyMap = {
        'asignatura': asignaturaId,
        'salon': salon,
        'gestor': gestorId,
        'dia': dia,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'semestre': semestre,
      };

      developer.log(
        'guardarBloque → POST $uri: ${jsonEncode(bodyMap)}',
        name: 'HorarioHttpClient',
      );

      final response = await _conRenovacion(() => http
          .post(uri, headers: _headers, body: jsonEncode(bodyMap))
          .timeout(const Duration(seconds: 15)));

      developer.log(
        'guardarBloque ← ${response.statusCode}: ${response.body}',
        name: 'HorarioHttpClient',
      );

      if (response.statusCode == 201) {
        final bloqueGuardado =
            Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)) as Map);
        return ResultadoGuardado(
          bloqueGuardado: bloqueGuardado,
          conflictos: [],
          statusCode: 201,
        );
      }

      if (response.statusCode == 400) {
        return ResultadoGuardado(
          conflictos: _parsearConflictos(response.body),
          statusCode: 400,
        );
      }

      return ResultadoGuardado(
        conflictos: _conflictosDeEstado(response),
        statusCode: response.statusCode,
      );
    } on Exception catch (e) {
      return ResultadoGuardado(
        conflictos: [ConflictoHorario(mensaje: _mensajeDeErrorConexion(e))],
        statusCode: -1,
      );
    }
  }

  /// PUT /api/horarios/{id}/
  Future<ResultadoGuardado> actualizarBloque({
    required int horarioId,
    required int asignaturaId,
    required dynamic salon,
    required int gestorId,
    required String dia,
    required String horaInicio,
    required String horaFin,
    required String semestre,
  }) async {
    try {
      final uri = Uri.parse('$kBaseUrl/horarios/$horarioId/');
      final bodyMap = {
        'asignatura': asignaturaId,
        'salon': salon,
        'gestor': gestorId,
        'dia': dia,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'semestre': semestre,
      };

      final response = await _conRenovacion(() => http
          .put(uri, headers: _headers, body: jsonEncode(bodyMap))
          .timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200) {
        return ResultadoGuardado(
          bloqueGuardado:
              Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)) as Map),
          conflictos: [],
          statusCode: 200,
        );
      }
      if (response.statusCode == 400) {
        return ResultadoGuardado(
          conflictos: _parsearConflictos(response.body),
          statusCode: 400,
        );
      }
      return ResultadoGuardado(
        conflictos: _conflictosDeEstado(response),
        statusCode: response.statusCode,
      );
    } on Exception catch (e) {
      return ResultadoGuardado(
        conflictos: [ConflictoHorario(mensaje: _mensajeDeErrorConexion(e))],
        statusCode: -1,
      );
    }
  }

  // ── Operaciones genéricas (recursos administrativos) ─────────────────────
  //
  // `ruta` es el recurso relativo a la URL base, sin barras (ej. 'salones').
  // Todos los errores se lanzan como [ApiException].

  Uri _uriRecurso(String ruta, [Object? id, Map<String, String>? filtros]) {
    final base = '$kBaseUrl/$ruta/${id != null ? '$id/' : ''}';
    final uri = Uri.parse(base);
    return (filtros == null || filtros.isEmpty)
        ? uri
        : uri.replace(queryParameters: filtros);
  }

  Future<http.Response> _ejecutar(
      Future<http.Response> Function() peticion) async {
    try {
      return await peticion().timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException.conexion(_mensajeDeErrorConexion(e));
    }
  }

  /// Renueva el token de acceso con `POST /api/token/refresh/`.
  Future<bool> _renovarToken() => renovarSesionApi();

  Future<http.Response> _enviar(
      Future<http.Response> Function() peticion) async {
    var r = await _ejecutar(peticion);
    // Token vencido: se renueva una vez y se repite la solicitud
    // (la cabecera se vuelve a construir dentro de `peticion`).
    if (r.statusCode == 401 && authToken == null && await _renovarToken()) {
      r = await _ejecutar(peticion);
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    throw ApiException.desdeRespuesta(
      r.statusCode,
      utf8.decode(r.bodyBytes),
      _mensajeDeEstado(r.statusCode),
    );
  }

  /// GET /api/{ruta}/  (acepta respuesta como lista o paginada con `results`).
  Future<List<Map<String, dynamic>>> listar(String ruta,
      {Map<String, String>? filtros}) async {
    final r = await _enviar(
        () => http.get(_uriRecurso(ruta, null, filtros), headers: _headersSesion));
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    final data = decoded is List
        ? decoded
        : (decoded is Map && decoded['results'] is List
            ? decoded['results'] as List
            : const []);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// POST /api/{ruta}/
  Future<Map<String, dynamic>> crear(
      String ruta, Map<String, dynamic> datos) async {
    final r = await _enviar(() => http.post(_uriRecurso(ruta),
        headers: _headersSesion, body: jsonEncode(datos)));
    return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map);
  }

  /// PATCH /api/{ruta}/{id}/  (solo se envían los campos indicados).
  Future<Map<String, dynamic>> actualizar(
      String ruta, Object id, Map<String, dynamic> datos) async {
    final r = await _enviar(() => http.patch(_uriRecurso(ruta, id),
        headers: _headersSesion, body: jsonEncode(datos)));
    return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map);
  }

  /// DELETE /api/{ruta}/{id}/
  ///
  /// Si el servidor bloquea la eliminación (409) la [ApiException] trae
  /// `dependencias` con los registros asociados.
  Future<void> eliminar(String ruta, Object id) async {
    await _enviar(() => http.delete(_uriRecurso(ruta, id), headers: _headersSesion));
  }

  String _mensajeDeErrorConexion(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network')) {
      return 'No se pudo conectar con la API. Verifica que el servidor Django esté activo '
          'y que la URL base en lib/backend/api_config.dart sea la indicada para tu dispositivo.';
    }
    if (msg.contains('timeoutexception') || msg.contains('timed out')) {
      return 'La solicitud tardó demasiado. Intenta nuevamente.';
    }
    developer.log('Error de conexión', name: 'HorarioHttpClient', error: e);
    return 'Error de conexión inesperado.';
  }
}

/// Cliente legado mantenido por compatibilidad
class HorarioService {
  final String baseUrl;

  HorarioService([this.baseUrl = '$kBaseUrl/']);

  Future<List<dynamic>> getHorarios() async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.get(uri);
      return _parseResponse(response);
    } catch (e, stackTrace) {
      developer.log('Error fetching horarios', name: 'HorarioService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  List<dynamic> _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw _handleError(response.statusCode, response.body);
    }
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (!decoded.containsKey('horarios')) {
        throw const FormatException('Campo "horarios" no encontrado');
      }
      final horarios = decoded['horarios'];
      if (horarios is List) return horarios;
      if (horarios is String) {
        try {
          return jsonDecode(horarios) as List;
        } catch (_) {
          return [horarios];
        }
      }
      throw const FormatException('Formato inválido para "horarios"');
    } on FormatException catch (e) {
      developer.log('Parse error', name: 'HorarioService', error: e);
      throw FormatException('Error parsing response: ${e.message}');
    }
  }

  Exception _handleError(int statusCode, String body) {
    try {
      final error = jsonDecode(body)?['error'] ?? body;
      return Exception('Error $statusCode: $error');
    } catch (_) {
      return Exception('Error $statusCode: Invalid response format');
    }
  }
}
