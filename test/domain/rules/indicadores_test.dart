import 'package:citas_medicas_app/domain/entities/cita.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/rules/indicadores.dart';
import 'package:flutter_test/flutter_test.dart';

Cita _cita({
  required String id,
  EstadoCita estado = EstadoCita.confirmada,
  CanalReserva canal = CanalReserva.flujoGuiado,
  DateTime? creada,
}) =>
    Cita(
      id: id,
      pacienteId: 'pac-1',
      cupoId: 'cupo-$id',
      estado: estado,
      fechaCreacion: creada ?? DateTime(2026, 9, 10),
      canalReserva: canal,
      especialidadId: 'esp-1',
      profesionalId: 'prof-1',
    );

void main() {
  group('Conteos basicos', () {
    test('cuenta reservadas, canceladas, inasistencias y atendidas', () {
      final datos = Indicadores.calcular(<Cita>[
        _cita(id: '1'),
        _cita(id: '2', estado: EstadoCita.cancelada),
        _cita(id: '3', estado: EstadoCita.inasistencia),
        _cita(id: '4', estado: EstadoCita.atendida),
        _cita(id: '5', estado: EstadoCita.atendida),
      ]);

      expect(datos.reservadas, 5);
      expect(datos.canceladas, 1);
      expect(datos.inasistencias, 1);
      expect(datos.atendidas, 2);
    });

    test('sin citas, todo es cero y sinDatos es true', () {
      final datos = Indicadores.calcular(const <Cita>[]);
      expect(datos.reservadas, 0);
      expect(datos.sinDatos, isTrue);
    });
  });

  group('Proporciones', () {
    test('la tasa de inasistencia se calcula sobre las citas ya cerradas', () {
      final datos = Indicadores.calcular(<Cita>[
        _cita(id: '1', estado: EstadoCita.atendida),
        _cita(id: '2', estado: EstadoCita.atendida),
        _cita(id: '3', estado: EstadoCita.atendida),
        _cita(id: '4', estado: EstadoCita.inasistencia),
        // Ni la confirmada ni la cancelada entran en el denominador.
        _cita(id: '5'),
        _cita(id: '6', estado: EstadoCita.cancelada),
      ]);

      expect(datos.cerradas, 4);
      expect(datos.tasaInasistencia, 0.25);
    });

    test('sin citas cerradas la tasa es null, no cero', () {
      final datos = Indicadores.calcular(<Cita>[_cita(id: '1')]);
      expect(
        datos.tasaInasistencia,
        isNull,
        reason: 'Mostrar «0 %» sobre cero casos seria enganoso',
      );
    });

    test('la tasa de cancelacion se calcula sobre el total reservado', () {
      final datos = Indicadores.calcular(<Cita>[
        _cita(id: '1'),
        _cita(id: '2', estado: EstadoCita.cancelada),
        _cita(id: '3', estado: EstadoCita.cancelada),
        _cita(id: '4', estado: EstadoCita.atendida),
      ]);
      expect(datos.tasaCancelacion, 0.5);
    });
  });

  group('HU-11 — proporcion de reservas autogestionadas', () {
    test('cuenta solo los canales de la aplicacion', () {
      final datos = Indicadores.calcular(<Cita>[
        _cita(id: '1', canal: CanalReserva.conversacional),
        _cita(id: '2', canal: CanalReserva.flujoGuiado),
        _cita(id: '3', canal: CanalReserva.presencial),
        _cita(id: '4', canal: CanalReserva.telefonico),
      ]);

      expect(datos.autogestionadas, 2);
      expect(datos.tasaAutogestion, 0.5);
    });

    test('sin reservas la tasa es null', () {
      expect(Indicadores.calcular(const <Cita>[]).tasaAutogestion, isNull);
    });

    test('con todas autogestionadas la tasa es 1', () {
      final datos = Indicadores.calcular(<Cita>[
        _cita(id: '1', canal: CanalReserva.conversacional),
        _cita(id: '2', canal: CanalReserva.flujoGuiado),
      ]);
      expect(datos.tasaAutogestion, 1.0);
    });
  });

  group('Acotado por periodo', () {
    test('solo entran las citas creadas dentro del rango', () {
      final citas = <Cita>[
        _cita(id: 'vieja', creada: DateTime(2026, 8, 1)),
        _cita(id: 'dentro', creada: DateTime(2026, 9, 10)),
        _cita(id: 'futura', creada: DateTime(2026, 10, 1)),
      ];

      final datos = Indicadores.calcular(
        citas,
        desde: DateTime(2026, 9, 1),
        hasta: DateTime(2026, 9, 30),
      );

      expect(datos.reservadas, 1);
    });

    test('sin rango entran todas', () {
      final citas = <Cita>[
        _cita(id: '1', creada: DateTime(2026, 8, 1)),
        _cita(id: '2', creada: DateTime(2026, 10, 1)),
      ];
      expect(Indicadores.calcular(citas).reservadas, 2);
    });
  });

  group('Reparto por canal', () {
    test('cuenta cada canal y deja en cero los que no aparecen', () {
      final conteo = Indicadores.porCanal(<Cita>[
        _cita(id: '1', canal: CanalReserva.conversacional),
        _cita(id: '2', canal: CanalReserva.conversacional),
        _cita(id: '3', canal: CanalReserva.presencial),
      ]);

      expect(conteo[CanalReserva.conversacional], 2);
      expect(conteo[CanalReserva.presencial], 1);
      expect(conteo[CanalReserva.flujoGuiado], 0);
      expect(conteo[CanalReserva.telefonico], 0);
    });

    test('todos los canales aparecen en el mapa, aunque valgan cero', () {
      final conteo = Indicadores.porCanal(const <Cita>[]);
      expect(conteo.keys.toSet(), CanalReserva.values.toSet());
    });
  });
}
