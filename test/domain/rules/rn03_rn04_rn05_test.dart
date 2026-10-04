import 'package:citas_medicas_app/domain/entities/cita.dart';
import 'package:citas_medicas_app/domain/entities/cupo_disponible.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/rules/rn03_rn04_rn05_reserva.dart';
import 'package:flutter_test/flutter_test.dart';

CupoDisponible _cupo({
  String id = 'cupo-1',
  String profesionalId = 'prof-1',
  required DateTime inicio,
  bool disponible = true,
}) =>
    CupoDisponible(
      id: id,
      profesionalId: profesionalId,
      sedeId: 'sede-1',
      consultorioId: 'cons-1',
      fechaHoraInicio: inicio,
      duracionMinutos: 30,
      disponible: disponible,
    );

Cita _cita({
  String id = 'cita-1',
  String cupoId = 'cupo-1',
  EstadoCita estado = EstadoCita.confirmada,
  String? especialidadId = 'esp-1',
  String? profesionalId = 'prof-1',
  DateTime? inicio,
}) =>
    Cita(
      id: id,
      pacienteId: 'pac-1',
      cupoId: cupoId,
      estado: estado,
      fechaCreacion: DateTime(2026, 9, 1),
      canalReserva: CanalReserva.flujoGuiado,
      especialidadId: especialidadId,
      profesionalId: profesionalId,
      fechaHoraInicio: inicio,
    );

void main() {
  final ahora = DateTime(2026, 9, 16, 10, 0);

  group('RN-03 — un cupo, una cita activa', () {
    test('un cupo libre y sin citas se acepta', () {
      final r = Rn03CupoUnico.validar(
        cupo: _cupo(inicio: ahora.add(const Duration(days: 1))),
        citasDelSistema: const <Cita>[],
      );
      expect(r.cumple, isTrue);
    });

    test('un cupo marcado como no disponible se rechaza', () {
      final r = Rn03CupoUnico.validar(
        cupo: _cupo(
          inicio: ahora.add(const Duration(days: 1)),
          disponible: false,
        ),
        citasDelSistema: const <Cita>[],
      );
      expect(r.infringida, isTrue);
      expect(r.regla, 'RN-03');
    });

    test('un cupo con una cita activa encima se rechaza', () {
      final r = Rn03CupoUnico.validar(
        cupo: _cupo(inicio: ahora.add(const Duration(days: 1))),
        citasDelSistema: <Cita>[_cita()],
      );
      expect(r.infringida, isTrue);
    });

    test('una cita cancelada libera el cupo', () {
      final r = Rn03CupoUnico.validar(
        cupo: _cupo(inicio: ahora.add(const Duration(days: 1))),
        citasDelSistema: <Cita>[_cita(estado: EstadoCita.cancelada)],
      );
      expect(
        r.cumple,
        isTrue,
        reason: 'Solo las citas activas bloquean el cupo',
      );
    });
  });

  group('RN-04 — nada en el pasado', () {
    test('un horario futuro se acepta', () {
      expect(
        Rn04NoEnElPasado.validar(
          fechaHoraInicio: ahora.add(const Duration(days: 1)),
          ahora: ahora,
        ).cumple,
        isTrue,
      );
    });

    test('un horario pasado se rechaza', () {
      final r = Rn04NoEnElPasado.validar(
        fechaHoraInicio: ahora.subtract(const Duration(minutes: 1)),
        ahora: ahora,
      );
      expect(r.infringida, isTrue);
      expect(r.regla, 'RN-04');
    });

    test('el momento exacto de ahora se rechaza', () {
      expect(
        Rn04NoEnElPasado.validar(fechaHoraInicio: ahora, ahora: ahora)
            .infringida,
        isTrue,
      );
    });

    test('un horario dentro del margen minimo se rechaza', () {
      expect(
        Rn04NoEnElPasado.validar(
          fechaHoraInicio: ahora.add(const Duration(minutes: 5)),
          ahora: ahora,
        ).infringida,
        isTrue,
      );
    });

    test('justo en el limite del margen se acepta', () {
      expect(
        Rn04NoEnElPasado.validar(
          fechaHoraInicio: ahora.add(Rn04NoEnElPasado.margenMinimo),
          ahora: ahora,
        ).cumple,
        isTrue,
      );
    });

    test('filtrar descarta los cupos no reservables', () {
      final cupos = <CupoDisponible>[
        _cupo(id: 'pasado', inicio: ahora.subtract(const Duration(hours: 2))),
        _cupo(id: 'proximo', inicio: ahora.add(const Duration(minutes: 5))),
        _cupo(id: 'valido', inicio: ahora.add(const Duration(days: 1))),
      ];

      final filtrados = Rn04NoEnElPasado.filtrar(cupos, ahora: ahora);
      expect(filtrados.map((c) => c.id), <String>['valido']);
    });
  });

  group('RN-05 — sin citas duplicadas', () {
    final manana = DateTime(2026, 9, 17, 9, 0);

    test('sin citas previas se acepta', () {
      expect(
        Rn05SinDuplicados.validar(
          especialidadId: 'esp-1',
          profesionalId: 'prof-1',
          fechaHoraInicio: manana,
          citasDelPaciente: const <Cita>[],
        ).cumple,
        isTrue,
      );
    });

    test('misma especialidad, profesional y dia se rechaza aunque cambie la hora',
        () {
      final r = Rn05SinDuplicados.validar(
        especialidadId: 'esp-1',
        profesionalId: 'prof-1',
        fechaHoraInicio: manana,
        citasDelPaciente: <Cita>[
          _cita(inicio: DateTime(2026, 9, 17, 16, 30)),
        ],
      );
      expect(r.infringida, isTrue);
      expect(r.regla, 'RN-05');
    });

    test('otro dia se acepta', () {
      expect(
        Rn05SinDuplicados.validar(
          especialidadId: 'esp-1',
          profesionalId: 'prof-1',
          fechaHoraInicio: manana,
          citasDelPaciente: <Cita>[
            _cita(inicio: DateTime(2026, 9, 18, 9, 0)),
          ],
        ).cumple,
        isTrue,
      );
    });

    test('otro profesional el mismo dia se acepta', () {
      expect(
        Rn05SinDuplicados.validar(
          especialidadId: 'esp-1',
          profesionalId: 'prof-2',
          fechaHoraInicio: manana,
          citasDelPaciente: <Cita>[_cita(inicio: manana)],
        ).cumple,
        isTrue,
      );
    });

    test('otra especialidad el mismo dia se acepta', () {
      expect(
        Rn05SinDuplicados.validar(
          especialidadId: 'esp-2',
          profesionalId: 'prof-1',
          fechaHoraInicio: manana,
          citasDelPaciente: <Cita>[_cita(inicio: manana)],
        ).cumple,
        isTrue,
      );
    });

    test('una cita cancelada no cuenta como duplicado', () {
      expect(
        Rn05SinDuplicados.validar(
          especialidadId: 'esp-1',
          profesionalId: 'prof-1',
          fechaHoraInicio: manana,
          citasDelPaciente: <Cita>[
            _cita(estado: EstadoCita.cancelada, inicio: manana),
          ],
        ).cumple,
        isTrue,
      );
    });
  });
}
