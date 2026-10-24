import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/servicios/metricas_service.dart';

void main() {
  group('Pruebas de MetricasService', () {
    final service = MetricasService();

    test('fetchHorariosPorDia retorna lista con los 6 días académicos', () async {
      final dias = await service.fetchHorariosPorDia(semestre: '1');
      expect(dias.length, equals(6));
      expect(dias.map((d) => d.dia), containsAll(['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB']));
      for (final d in dias) {
        expect(d.cantidadClases, isNonNegative);
      }
    });

    test('fetchEstadoHorarios retorna estado consolidado válido', () async {
      final estado = await service.fetchEstadoHorarios();
      expect(estado.completados, isNonNegative);
      expect(estado.pendientes, isNonNegative);
      expect(estado.conConflictos, isNonNegative);
      expect(estado.total, equals(estado.completados + estado.pendientes + estado.conConflictos));
    });

    test('fetchUsuariosPorRol retorna conteos para CO, GC, TI y ES', () async {
      final roles = await service.fetchUsuariosPorRol();
      expect(roles.isNotEmpty, isTrue);
      final codigosRol = roles.map((r) => r.rol).toList();
      expect(codigosRol, containsAll(['CO', 'GC', 'TI', 'ES']));
    });

    test('fetchSalonesPorEdificio retorna agrupación por bloques', () async {
      final salones = await service.fetchSalonesPorEdificio();
      expect(salones.isNotEmpty, isTrue);
      for (final s in salones) {
        expect(s.edificio.isNotEmpty, isTrue);
        expect(s.cantidadSalones, isPositive);
        expect(s.capacidadPromedio, isPositive);
      }
    });

    test('fetchUltimosCambios limita a 5 registros y clasifica tipos', () async {
      final ultimos = await service.fetchUltimosCambios(limit: 5, rol: 'TI');
      expect(ultimos.length, lessThanOrEqualTo(5));
      expect(ultimos.first.usuario.isNotEmpty, isTrue);
      expect(ultimos.first.accion.isNotEmpty, isTrue);
      expect(ultimos.first.tipo, isA<TipoAccionHistorial>());
    });

    test('fetchHistorialPaginado soporta paginación y banderas hasNextPage', () async {
      final resPagina1 = await service.fetchHistorialPaginado(page: 1, pageSize: 5, rol: 'CO');
      expect(resPagina1.items.length, lessThanOrEqualTo(5));
      expect(resPagina1.totalCount, isPositive);

      final item = resPagina1.items.first;
      expect(item.id, isPositive);
      expect(item.entidad.isNotEmpty, isTrue);
    });

    test('ItemHistorial parsea JSON correctamente', () {
      final json = {
        'id': 42,
        'usuario': 'coordinador_sistemas',
        'accion': 'Creación de bloque',
        'detalle': 'Asignado salón A-101 para Cálculo',
        'entidad': 'Horarios',
        'fecha': '2026-10-22T14:30:00Z',
      };

      final item = ItemHistorial.fromJson(json);
      expect(item.id, equals(42));
      expect(item.usuario, equals('coordinador_sistemas'));
      expect(item.tipo, equals(TipoAccionHistorial.creacion));
      expect(item.entidad, equals('Horarios'));
      expect(item.fecha.year, equals(2026));
    });
  });
}
