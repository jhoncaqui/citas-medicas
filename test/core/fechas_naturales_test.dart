import 'package:citas_medicas_app/core/utils/fechas_naturales.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Miercoles 16 de setiembre de 2026, 10:00.
  final ahora = DateTime(2026, 9, 16, 10, 0);

  DateTime? fechaDe(String texto) =>
      FechasNaturales.interpretar(texto, ahora: ahora)?.fecha;

  group('Expresiones relativas', () {
    test('"hoy"', () => expect(fechaDe('quiero cita hoy'), DateTime(2026, 9, 16)));

    test('"manana"', () {
      expect(fechaDe('una cita para manana'), DateTime(2026, 9, 17));
    });

    test('"mañana" con tilde', () {
      expect(fechaDe('una cita para mañana'), DateTime(2026, 9, 17));
    });

    test('"pasado manana"', () {
      expect(fechaDe('cita pasado manana'), DateTime(2026, 9, 18));
    });

    test('"pasado manana" gana sobre "manana"', () {
      // Si se evaluara «manana» primero, esto daria el 17 en lugar del 18.
      expect(fechaDe('pasado manana por favor'), DateTime(2026, 9, 18));
    });

    test('"en 3 dias"', () {
      expect(fechaDe('en 3 dias'), DateTime(2026, 9, 19));
    });
  });

  group('Dias de la semana', () {
    test('"el lunes" desde un miercoles es el lunes siguiente', () {
      expect(fechaDe('el lunes'), DateTime(2026, 9, 21));
    });

    test('"el viernes" desde un miercoles es el viernes de esta semana', () {
      expect(fechaDe('el viernes'), DateTime(2026, 9, 18));
    });

    test('el mismo dia de la semana salta al siguiente', () {
      // Hoy es miercoles: «el miercoles» es el de la semana que viene.
      expect(fechaDe('el miercoles'), DateTime(2026, 9, 23));
    });

    test('"el lunes de la proxima semana" salta una semana mas', () {
      expect(fechaDe('el lunes de la proxima semana'), DateTime(2026, 9, 28));
    });

    test('"la proxima semana" sin dia concreto cae en lunes', () {
      expect(fechaDe('la proxima semana'), DateTime(2026, 9, 21));
    });
  });

  group('Fechas explicitas', () {
    test('"20 de octubre"', () {
      expect(fechaDe('el 20 de octubre'), DateTime(2026, 10, 20));
    });

    test('"setiembre" (grafia peruana) tambien se entiende', () {
      expect(fechaDe('el 30 de setiembre'), DateTime(2026, 9, 30));
    });

    test('una fecha ya pasada se entiende del ano siguiente', () {
      expect(fechaDe('el 3 de enero'), DateTime(2027, 1, 3));
    });

    test('formato numerico "20/10"', () {
      expect(fechaDe('el 20/10'), DateTime(2026, 10, 20));
    });

    test('formato numerico con ano "20/10/2027"', () {
      expect(fechaDe('20/10/2027'), DateTime(2027, 10, 20));
    });
  });

  group('Turnos', () {
    test('"por la manana" es turno, no dia', () {
      final r = FechasNaturales.interpretar(
        'el viernes por la manana',
        ahora: ahora,
      );
      expect(r!.turno, TurnoDia.manana);
      expect(r.fecha, DateTime(2026, 9, 18));
    });

    test('"por la tarde"', () {
      final r = FechasNaturales.interpretar('manana por la tarde', ahora: ahora);
      expect(r!.turno, TurnoDia.tarde);
      expect(
        r.fecha,
        DateTime(2026, 9, 17),
        reason: '«manana por la tarde» es el dia siguiente, no hoy',
      );
    });

    test('sin turno indicado, turno es null', () {
      expect(
        FechasNaturales.interpretar('el viernes', ahora: ahora)!.turno,
        isNull,
      );
    });
  });

  group('Horas', () {
    test('"a las 10"', () {
      final r = FechasNaturales.interpretar('manana a las 10', ahora: ahora);
      expect(r!.hora, const Duration(hours: 10));
    });

    test('"10:30"', () {
      final r = FechasNaturales.interpretar('manana 10:30', ahora: ahora);
      expect(r!.hora, const Duration(hours: 10, minutes: 30));
    });

    test('"a las 3 de la tarde" pasa a 24 horas', () {
      final r = FechasNaturales.interpretar(
        'manana a las 3 de la tarde',
        ahora: ahora,
      );
      expect(r!.hora, const Duration(hours: 15));
    });

    test('fechaHora combina dia y hora', () {
      final r = FechasNaturales.interpretar('manana a las 9', ahora: ahora);
      expect(r!.fechaHora, DateTime(2026, 9, 17, 9));
    });

    test('sin hora, el turno manana empieza a las 8', () {
      final r = FechasNaturales.interpretar(
        'manana en la manana',
        ahora: ahora,
      );
      expect(r!.fechaHora, DateTime(2026, 9, 17, 8));
    });
  });

  group('Sin fecha reconocible', () {
    test('devuelve null en lugar de inventarse un dia', () {
      expect(
        FechasNaturales.interpretar('quiero una cita', ahora: ahora),
        isNull,
      );
      expect(FechasNaturales.interpretar('', ahora: ahora), isNull);
    });
  });
}
