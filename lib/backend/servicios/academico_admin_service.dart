import 'package:mcs/backend/api_horario.dart';
import 'package:mcs/backend/modelos/academico_admin.dart';
import 'package:mcs/backend/modelos/usuario_admin.dart';

/// Acceso a los recursos administrativos académicos. Usa el mismo
/// [HorarioHttpClient] que el resto de la app: aquí solo se combinan
/// consultas para resolver relaciones (coordinador, programa, gestores).
class AcademicoAdminService {
  static const String recursoProgramas = 'programa';
  static const String recursoSalones = 'salones';
  static const String recursoNucleos = 'asignaturas';
  static const String recursoMatriculas = 'matricula';
  static const String recursoUsuarios = 'usuarios';

  final HorarioHttpClient api;

  const AcademicoAdminService([this.api = const HorarioHttpClient()]);

  Future<List<UsuarioAdmin>> _usuariosPorRol(String rol) async {
    final datos = await api.listar(recursoUsuarios, filtros: {'rol': rol});
    final lista = datos.map(UsuarioAdmin.fromJson).toList()
      ..sort(_porTitulo);
    return lista;
  }

  static int _porTitulo(UsuarioAdmin a, UsuarioAdmin b) =>
      a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());

  /// Usuarios con rol Coordinador (los únicos que acepta `Programa.coordinador`).
  Future<List<UsuarioAdmin>> coordinadores() => _usuariosPorRol('CO');

  /// Usuarios con rol Gestor del Conocimiento (los únicos que acepta `gestores`).
  Future<List<UsuarioAdmin>> gestores() => _usuariosPorRol('GC');

  /// Usuarios con rol Estudiante (los únicos que acepta `Matricula.estudiante`).
  Future<List<UsuarioAdmin>> estudiantes() => _usuariosPorRol('ES');

  /// Programas con el nombre de su coordinador resuelto.
  Future<List<ProgramaAdmin>> programas() async {
    final r = await Future.wait<Object>([
      api.listar(recursoProgramas),
      coordinadores(),
    ]);
    final datos = r[0] as List<Map<String, dynamic>>;
    final coords = {
      for (final u in r[1] as List<UsuarioAdmin>) u.id: u.titulo,
    };
    final lista = [
      for (final j in datos) ProgramaAdmin.fromJson(j, coordinadores: coords),
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  /// Programas sin resolver coordinadores (para selectores).
  Future<List<ProgramaAdmin>> programasOpciones() async {
    final datos = await api.listar(recursoProgramas);
    return [for (final j in datos) ProgramaAdmin.fromJson(j)]
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  Future<List<SalonAdmin>> salones() async {
    final datos = await api.listar(recursoSalones);
    return [for (final j in datos) SalonAdmin.fromJson(j)]
      ..sort((a, b) => a.codigo.toLowerCase().compareTo(b.codigo.toLowerCase()));
  }

  /// Núcleos temáticos (asignaturas) con programa y gestores resueltos.
  Future<List<NucleoAdmin>> nucleos() async {
    final r = await Future.wait<Object>([
      api.listar(recursoNucleos),
      programasOpciones(),
      gestores(),
    ]);
    final datos = r[0] as List<Map<String, dynamic>>;
    final programas = {
      for (final p in r[1] as List<ProgramaAdmin>) p.id: p.nombre,
    };
    final gestoresPorId = {
      for (final u in r[2] as List<UsuarioAdmin>) u.id: u.titulo,
    };
    return [
      for (final j in datos)
        NucleoAdmin.fromJson(j, programas: programas, gestores: gestoresPorId),
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  /// Matrículas con estudiante, asignatura y programa resueltos.
  Future<List<MatriculaAdmin>> matriculas() async {
    final r = await Future.wait<Object>([
      api.listar(recursoMatriculas),
      estudiantes(),
      nucleos(),
    ]);
    final datos = r[0] as List<Map<String, dynamic>>;
    final porEstudiante = {
      for (final u in r[1] as List<UsuarioAdmin>) u.id: u,
    };
    final porNucleo = {
      for (final n in r[2] as List<NucleoAdmin>) n.id: n,
    };
    return [
      for (final j in datos)
        MatriculaAdmin.fromJson(j,
            estudiantes: porEstudiante, nucleos: porNucleo),
    ]..sort((a, b) {
        final c = (a.estudianteNombre ?? '')
            .toLowerCase()
            .compareTo((b.estudianteNombre ?? '').toLowerCase());
        return c != 0 ? c : a.id.compareTo(b.id);
      });
  }
}
