import 'package:flutter_test/flutter_test.dart';
import 'package:mcs/backend/api_horario.dart';

void main() {
  group('Pruebas de Núcleos CAI (CaiHelper)', () {
    test('Identifica asignaturas CAI por código o nombre', () {
      expect(CaiHelper.esCai('CAI1002020202', 'COMUNICACIÓN Y LECTURA CRÍTICA I'), isTrue);
      expect(CaiHelper.esCai('DN-CAI1002020201', 'RAZONAMIENTO LÓGICO Y CUANTITATIVO'), isTrue);
      expect(CaiHelper.esCai('CAI1002020304', 'LENGUA EXTRANJERA I'), isTrue);
      expect(CaiHelper.esCai('SIS301', 'ESTRUCTURA DE DATOS'), isFalse);
      expect(CaiHelper.esCai('MAT101', 'CÁLCULO DIFERENCIAL'), isFalse);
    });

    test('Retorna horario predefinido e inalterable para CAI', () {
      final horarioLectura = CaiHelper.horarioPredefinido('CAI1002020202', 'COMUNICACIÓN Y LECTURA CRÍTICA I');
      expect(horarioLectura['dia'], equals('VIE'));
      expect(horarioLectura['hora_inicio'], equals('07:00:00'));
      expect(horarioLectura['hora_fin'], equals('09:00:00'));

      final horarioRazonamiento = CaiHelper.horarioPredefinido('CAI1002020201', 'RAZONAMIENTO LÓGICO Y CUANTITATIVO');
      expect(horarioRazonamiento['dia'], equals('VIE'));
      expect(horarioRazonamiento['hora_inicio'], equals('09:00:00'));
      expect(horarioRazonamiento['hora_fin'], equals('11:00:00'));

      final horarioLengua = CaiHelper.horarioPredefinido('CAI1002020304', 'LENGUA EXTRANJERA I');
      expect(horarioLengua['dia'], equals('SAB'));
      expect(horarioLengua['hora_inicio'], equals('08:00:00'));
      expect(horarioLengua['hora_fin'], equals('12:00:00'));
    });
  });

  group('Pruebas de Salones (SalonItem)', () {
    test('SalonItem parsea JSON y formatea descripción completa', () {
      final salon = SalonItem.fromJson({
        'id': 10,
        'codigo': 'S-204',
        'capacidad': 35,
        'edificio': 'Bloque B',
      });

      expect(salon.id, equals(10));
      expect(salon.codigo, equals('S-204'));
      expect(salon.capacidad, equals(35));
      expect(salon.edificio, equals('Bloque B'));
      expect(salon.descripcionCompleta, contains('S-204'));
      expect(salon.descripcionCompleta, contains('Bloque B'));
      expect(salon.descripcionCompleta, contains('35'));
    });

    test('SalonItem igualdad basada en ID', () {
      const s1 = SalonItem(id: 5, codigo: 'Aula 1');
      const s2 = SalonItem(id: 5, codigo: 'Aula 1 Renombrada');
      const s3 = SalonItem(id: 8, codigo: 'Aula 1');

      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
    });
  });

  group('Pruebas de Conflictos y Errores (ConflictoHorario)', () {
    test('Parsea y traduce mensaje de salón ocupado', () {
      final c1 = ConflictoHorario.fromJson('Classroom S-101 is already occupied in that time slot');
      expect(c1.mensaje, contains('salón'));
      expect(c1.mensaje, contains('ocupado'));

      final c2 = ConflictoHorario.fromJson({'error': 'El salón ya se encuentra ocupado'});
      expect(c2.mensaje, contains('salón'));
      expect(c2.mensaje, contains('ocupado'));
    });

    test('Parsea y traduce cruce de gestor', () {
      final c = ConflictoHorario.fromJson({'detail': 'Gestor already has another class assigned'});
      expect(c.mensaje, contains('gestor'));
      expect(c.mensaje, contains('asignada'));
    });

    test('Mantiene identificador de horario en conflicto si la API lo envía', () {
      final c = ConflictoHorario.fromJson({
        'mensaje': 'Conflicto de salón',
        'horario_id': 42,
        'detalle': {'asignatura': 'Física I'},
      });

      expect(c.horarioConflictoId, equals(42));
      expect(c.detalleConflicto?['asignatura'], equals('Física I'));
    });

    test('DRF devuelve horario_id como texto ("15" o "None"): no debe romper el parseo', () {
      final c = ConflictoHorario.fromJson({
        'tipo': 'GRUPO_OCUPADO',
        'mensaje': 'El semestre 3 ya tiene "Cálculo" en esa franja.',
        'horario_id': '15',
      });
      expect(c.horarioConflictoId, equals(15));
      expect(c.tipo, equals('GRUPO_OCUPADO'));
      // El mensaje redactado por la API no se altera.
      expect(c.mensaje, contains('Cálculo'));

      final sinId = ConflictoHorario.fromJson({
        'tipo': 'LIMITE_HORAS_SEMANA',
        'mensaje': 'El gestor superaría el máximo de 40 h semanales.',
        'horario_id': 'None',
      });
      expect(sinId.horarioConflictoId, isNull);
    });
  });

  group('Tipo de salón', () {
    test('SalonItem lee el tipo y distingue sala de cómputo', () {
      final comp = SalonItem.fromJson({'id': 1, 'codigo': 'SC1', 'tipo': 'COMP'});
      final aula = SalonItem.fromJson({'id': 2, 'codigo': 'A1'});
      expect(comp.esComputo, isTrue);
      expect(aula.esComputo, isFalse); // por defecto, aula convencional
    });
  });
}
