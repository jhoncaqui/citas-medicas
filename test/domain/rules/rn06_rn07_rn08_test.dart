import 'package:citas_medicas_app/domain/entities/cita.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/rules/rn06_rn07_rn08_gestion.dart';
import 'package:flutter_test/flutter_test.dart';

Cita _cita({
  String id = 'cita-1',
  EstadoCita estado = EstadoCita.confirmada,
  DateTime? inicio,
  DateTime? atencion,
}) =>
    Cita(
      id: id,
      pacienteId: 'pac-1',
      cupoId: 'cupo-1',
      estado: estado,
      fechaCreacion: DateTime(2026, 9, 1),
      canalReserva: CanalReserva.flujoGuiado,
      especialidadId: 'esp-1',
      profesionalId: 'prof-1',
      fechaHoraInicio: inicio,
      fechaAtencion: atencion,
    );

void main() {
  final ahora = DateTime(2026, 9, 16, 10, 0);

  group('RN-06 — plazo de autogestion', () {
    test('con margen de sobra se permite cancelar y reprogramar', () {
      final cita = _cita(inicio: ahora.add(const Duration(days: 3)));

      for (final accion in AccionAutogestion.values) {
        expect(
          Rn06Autogestion.validar(
            cita: cita,
            accion: accion,
            ahora: ahora,
            horasMinimas: 24,
          ).cumple,
          isTrue,
        );
      }
    });

    test('dentro del plazo de N horas se rechaza', () {
      final cita = _cita(inicio: ahora.add(const Duration(hours: 5)));

      final r = Rn06Autogestion.validar(
        cita: cita,
        accion: AccionAutogestion.cancelar,
        ahora: ahora,
        horasMinimas: 24,
      );
      expect(r.infringida, isTrue);
      expect(r.regla, 'RN-06');
      expect(r.mensaje, contains('24 horas'));
    });

    test('justo en el limite de N horas se permite', () {
      final cita = _cita(inicio: ahora.add(const Duration(hours: 24)));
      expect(
        Rn06Autogestion.validar(
          cita: cita,
          accion: AccionAutogestion.cancelar,
          ahora: ahora,
          horasMinimas: 24,
        ).cumple,
        isTrue,
      );
    });

    test('un minuto por debajo del limite se rechaza', () {
      final cita = _cita(
        inicio: ahora.add(const Duration(hours: 23, minutes: 59)),
      );
      expect(
        Rn06Autogestion.validar(
          cita: cita,
          accion: AccionAutogestion.cancelar,
          ahora: ahora,
          horasMinimas: 24,
        ).infringida,
        isTrue,
      );
    });

    test('el plazo es parametrizable: con N=2 lo mismo se permite', () {
      final cita = _cita(inicio: ahora.add(const Duration(hours: 5)));
      expect(
        Rn06Autogestion.validar(
          cita: cita,
          accion: AccionAutogestion.cancelar,
          ahora: ahora,
          horasMinimas: 2,
        ).cumple,
        isTrue,
        reason: 'N sale de la configuracion, no esta fijado en duro',
      );
    });

    test('una cita ya cancelada no se puede volver a gestionar', () {
      final cita = _cita(
        estado: EstadoCita.cancelada,
        inicio: ahora.add(const Duration(days: 3)),
      );
      final r = Rn06Autogestion.validar(
        cita: cita,
        accion: AccionAutogestion.cancelar,
        ahora: ahora,
      );
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('cancelada'));
    });

    test('una cita cuya hora ya paso deriva a la clinica', () {
      final cita = _cita(inicio: ahora.subtract(const Duration(hours: 1)));
      final r = Rn06Autogestion.validar(
        cita: cita,
        accion: AccionAutogestion.reprogramar,
        ahora: ahora,
      );
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('Comunicate con la clinica'));
    });

    test('el mensaje nombra la accion que se intento', () {
      final cita = _cita(inicio: ahora.add(const Duration(hours: 1)));

      final cancelar = Rn06Autogestion.validar(
        cita: cita,
        accion: AccionAutogestion.cancelar,
        ahora: ahora,
        horasMinimas: 24,
      );
      final reprogramar = Rn06Autogestion.validar(
        cita: cita,
        accion: AccionAutogestion.reprogramar,
        ahora: ahora,
        horasMinimas: 24,
      );

      expect(cancelar.mensaje, contains('cancelar'));
      expect(reprogramar.mensaje, contains('reprogramar'));
    });
  });

  group('RN-07 — recordatorio automatico', () {
    test('el aviso se calcula M horas antes del inicio', () {
      final cita = _cita(inicio: DateTime(2026, 9, 18, 9, 0));
      final aviso = Rn07Recordatorio.momentoDeAviso(
        cita: cita,
        ahora: ahora,
        horasAntelacion: 24,
      );
      expect(aviso, DateTime(2026, 9, 17, 9, 0));
    });

    test('M es parametrizable', () {
      final cita = _cita(inicio: DateTime(2026, 9, 18, 9, 0));
      expect(
        Rn07Recordatorio.momentoDeAviso(
          cita: cita,
          ahora: ahora,
          horasAntelacion: 2,
        ),
        DateTime(2026, 9, 18, 7, 0),
      );
    });

    test('si el momento de aviso ya paso, no se programa nada', () {
      // La cita es en 3 horas y el aviso seria 24 h antes: ya paso.
      final cita = _cita(inicio: ahora.add(const Duration(hours: 3)));
      expect(
        Rn07Recordatorio.momentoDeAviso(
          cita: cita,
          ahora: ahora,
          horasAntelacion: 24,
        ),
        isNull,
        reason: 'Un recordatorio que llega tarde es peor que ninguno',
      );
    });

    test('una cita cancelada no genera recordatorio', () {
      final cita = _cita(
        estado: EstadoCita.cancelada,
        inicio: ahora.add(const Duration(days: 5)),
      );
      expect(
        Rn07Recordatorio.momentoDeAviso(cita: cita, ahora: ahora),
        isNull,
      );
    });

    test('una cita sin fecha no genera recordatorio', () {
      expect(
        Rn07Recordatorio.momentoDeAviso(cita: _cita(), ahora: ahora),
        isNull,
      );
    });
  });

  group('RN-08 — inasistencia', () {
    test('una cita confirmada pasada sin atencion se marca', () {
      final cita = _cita(inicio: ahora.subtract(const Duration(hours: 5)));
      expect(
        Rn08Inasistencia.debeMarcarse(
          cita: cita,
          ahora: ahora,
          horasMargen: 2,
        ),
        isTrue,
      );
      expect(
        Rn08Inasistencia.aplicar(cita: cita, ahora: ahora, horasMargen: 2)
            .estado,
        EstadoCita.inasistencia,
      );
    });

    test('dentro del margen todavia no se marca', () {
      final cita = _cita(inicio: ahora.subtract(const Duration(hours: 1)));
      expect(
        Rn08Inasistencia.debeMarcarse(
          cita: cita,
          ahora: ahora,
          horasMargen: 2,
        ),
        isFalse,
      );
    });

    test('con atencion registrada nunca se marca', () {
      final cita = _cita(
        inicio: ahora.subtract(const Duration(days: 1)),
        atencion: ahora.subtract(const Duration(days: 1)),
      );
      expect(
        Rn08Inasistencia.debeMarcarse(
          cita: cita,
          ahora: ahora,
          horasMargen: 2,
        ),
        isFalse,
      );
    });

    test('una cita cancelada no se convierte en inasistencia', () {
      final cita = _cita(
        estado: EstadoCita.cancelada,
        inicio: ahora.subtract(const Duration(days: 1)),
      );
      expect(
        Rn08Inasistencia.aplicar(cita: cita, ahora: ahora).estado,
        EstadoCita.cancelada,
      );
    });

    test('una cita futura no se toca', () {
      final cita = _cita(inicio: ahora.add(const Duration(days: 1)));
      expect(
        Rn08Inasistencia.aplicar(cita: cita, ahora: ahora).estado,
        EstadoCita.confirmada,
      );
    });
  });

  group('RN-08 — proporcion de inasistencias (HU-11)', () {
    test('sin citas pasadas devuelve null, no cero', () {
      expect(
        Rn08Inasistencia.proporcion(<Cita>[
          _cita(inicio: ahora.add(const Duration(days: 1))),
        ]),
        isNull,
        reason: 'Mostrar «0 %» sobre cero citas seria enganoso',
      );
    });

    test('calcula la proporcion sobre las citas ya cerradas', () {
      final citas = <Cita>[
        _cita(id: '1', estado: EstadoCita.atendida),
        _cita(id: '2', estado: EstadoCita.atendida),
        _cita(id: '3', estado: EstadoCita.inasistencia),
        _cita(id: '4', estado: EstadoCita.inasistencia),
        // Las canceladas y las futuras no entran en el denominador.
        _cita(id: '5', estado: EstadoCita.cancelada),
        _cita(id: '6', inicio: ahora.add(const Duration(days: 2))),
      ];
      expect(Rn08Inasistencia.proporcion(citas), 0.5);
    });
  });
}
