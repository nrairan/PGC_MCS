import 'package:mcs/backend/modelos/usuario_admin.dart';

int? _entero(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

String _texto(dynamic v) => v?.toString().trim() ?? '';

/// Programa académico (`/api/programa/`).
class ProgramaAdmin {
  final int id;
  final String nombre;
  final String codigo;

  /// Id del coordinador (puede ser null: el modelo lo permite).
  final int? coordinadorId;

  /// Nombre del coordinador, resuelto con la lista de usuarios CO.
  final String? coordinadorNombre;

  const ProgramaAdmin({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.coordinadorId,
    this.coordinadorNombre,
  });

  factory ProgramaAdmin.fromJson(Map<String, dynamic> json,
      {Map<int, String> coordinadores = const {}}) {
    final coord = _entero(json['coordinador']);
    return ProgramaAdmin(
      id: _entero(json['id'])!,
      nombre: _texto(json['nombre']),
      codigo: _texto(json['codigo']),
      coordinadorId: coord,
      coordinadorNombre: coord == null ? null : coordinadores[coord],
    );
  }

  bool coincide(String consulta) {
    final q = UsuarioAdmin.normalizar(consulta.trim());
    if (q.isEmpty) return true;
    return UsuarioAdmin.normalizar('$nombre $codigo ${coordinadorNombre ?? ''}')
        .contains(q);
  }
}

/// Salón (`/api/salones/`).
class SalonAdmin {
  final int id;
  final String codigo;
  final int? capacidad;
  final String edificio;

  /// Código de tipo de la API: AULA o COMP.
  final String tipo;

  const SalonAdmin({
    required this.id,
    required this.codigo,
    required this.capacidad,
    required this.edificio,
    required this.tipo,
  });

  /// Tipos que acepta la API (`Salon.TIPOS`).
  static const Map<String, String> tipos = {
    'AULA': 'Aula convencional',
    'COMP': 'Sala de cómputo',
  };

  factory SalonAdmin.fromJson(Map<String, dynamic> json) => SalonAdmin(
        id: _entero(json['id'])!,
        codigo: _texto(json['codigo']),
        capacidad: _entero(json['capacidad']),
        edificio: _texto(json['edificio']),
        tipo: _texto(json['tipo']),
      );

  String get tipoEtiqueta => tipos[tipo] ?? tipo;

  bool coincide(String consulta) {
    final q = UsuarioAdmin.normalizar(consulta.trim());
    if (q.isEmpty) return true;
    return UsuarioAdmin.normalizar('$codigo $edificio $tipoEtiqueta')
        .contains(q);
  }
}

/// Núcleo temático = `Asignatura` en la API (`/api/asignaturas/`).
class NucleoAdmin {
  final int id;
  final String codigo;
  final String nombre;
  final int? programaId;
  final String? programaNombre;
  final int? creditos;
  final int horasSemana;
  final bool requiereSalaComputo;

  /// Semestre como lo guarda la API (texto; vacío si no tiene).
  final String semestre;
  final List<int> gestorIds;
  final List<String> gestoresNombres;

  const NucleoAdmin({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.programaId,
    required this.programaNombre,
    required this.creditos,
    required this.horasSemana,
    required this.requiereSalaComputo,
    required this.semestre,
    required this.gestorIds,
    required this.gestoresNombres,
  });

  factory NucleoAdmin.fromJson(
    Map<String, dynamic> json, {
    Map<int, String> programas = const {},
    Map<int, String> gestores = const {},
  }) {
    final prog = _entero(json['programa']);
    final ids = (json['gestores'] is List)
        ? (json['gestores'] as List)
            .map(_entero)
            .whereType<int>()
            .toList()
        : <int>[];
    return NucleoAdmin(
      id: _entero(json['id'])!,
      codigo: _texto(json['codigo']),
      nombre: _texto(json['nombre']),
      programaId: prog,
      programaNombre: prog == null ? null : programas[prog],
      creditos: _entero(json['creditos']),
      horasSemana: _entero(json['horas_semana']) ?? 0,
      requiereSalaComputo: json['requiere_sala_computo'] == true,
      semestre: _texto(json['semestre']),
      gestorIds: ids,
      gestoresNombres: [
        for (final id in ids)
          if (gestores[id] != null) gestores[id]!,
      ],
    );
  }

  bool coincide(String consulta) {
    final q = UsuarioAdmin.normalizar(consulta.trim());
    if (q.isEmpty) return true;
    return UsuarioAdmin.normalizar(
      '$nombre $codigo ${programaNombre ?? ''} ${gestoresNombres.join(' ')}',
    ).contains(q);
  }
}

/// Matrícula (`/api/matricula/`): un estudiante inscrito en una asignatura
/// (núcleo temático) para un semestre. La API no admite repetir la pareja
/// estudiante + asignatura ni más de 8 asignaturas por estudiante y semestre.
class MatriculaAdmin {
  final int id;
  final int estudianteId;
  final int asignaturaId;

  /// Texto libre de hasta 10 caracteres, tal como lo guarda la API.
  final String semestre;

  /// Datos resueltos con las listas de estudiantes y núcleos (pueden faltar).
  final String? estudianteNombre;
  final String? estudianteCorreo;
  final String? asignaturaNombre;
  final String? asignaturaCodigo;
  final String? programaNombre;

  const MatriculaAdmin({
    required this.id,
    required this.estudianteId,
    required this.asignaturaId,
    required this.semestre,
    this.estudianteNombre,
    this.estudianteCorreo,
    this.asignaturaNombre,
    this.asignaturaCodigo,
    this.programaNombre,
  });

  factory MatriculaAdmin.fromJson(
    Map<String, dynamic> json, {
    Map<int, UsuarioAdmin> estudiantes = const {},
    Map<int, NucleoAdmin> nucleos = const {},
  }) {
    final est = _entero(json['estudiante'])!;
    final asig = _entero(json['asignatura'])!;
    final u = estudiantes[est];
    final n = nucleos[asig];
    return MatriculaAdmin(
      id: _entero(json['id'])!,
      estudianteId: est,
      asignaturaId: asig,
      semestre: _texto(json['semestre']),
      estudianteNombre: u?.titulo,
      estudianteCorreo: (u == null || u.email.isEmpty) ? null : u.email,
      asignaturaNombre: n?.nombre,
      asignaturaCodigo: n?.codigo,
      programaNombre: n?.programaNombre,
    );
  }

  bool coincide(String consulta) {
    final q = UsuarioAdmin.normalizar(consulta.trim());
    if (q.isEmpty) return true;
    return UsuarioAdmin.normalizar(
      '${estudianteNombre ?? ''} ${estudianteCorreo ?? ''} '
      '${asignaturaNombre ?? ''} ${asignaturaCodigo ?? ''} '
      '${programaNombre ?? ''} $semestre',
    ).contains(q);
  }
}
