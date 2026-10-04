import 'package:citas_medicas_app/domain/entities/cita.dart';
import 'package:citas_medicas_app/domain/entities/cupo_disponible.dart';
import 'package:citas_medicas_app/domain/entities/especialidad.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Paciente', () {
    const base = Paciente(
      id: 'pac-1',
      tipoDocumento: TipoDocumento.dni,
      numeroDocumento: '12345678',
      nombres: 'Nombre',
      apellidos: 'Apellido',
      correo: 'correo@ejemplo.test',
      telefono: '999888777',
    );

    test('dos instancias con los mismos datos son iguales', () {
      const otra = Paciente(
        id: 'pac-1',
        tipoDocumento: TipoDocumento.dni,
        numeroDocumento: '12345678',
        nombres: 'Nombre',
        apellidos: 'Apellido',
        correo: 'correo@ejemplo.test',
        telefono: '999888777',
      );
      expect(base, equals(otra));
      expect(base.hashCode, equals(otra.hashCode));
    });

    test('copyWith solo cambia el campo indicado', () {
      final copia = base.copyWith(telefono: '111222333');
      expect(copia.telefono, '111222333');
      expect(copia.id, base.id);
      expect(copia.numeroDocumento, base.numeroDocumento);
      expect(copia, isNot(equals(base)));
    });

    test('copyWith puede limpiar la fecha de consentimiento (HU-12)', () {
      final otorgado = base.copyWith(
        consentimientoOtorgado: true,
        fechaConsentimiento: DateTime(2026, 9, 15),
      );
      expect(otorgado.fechaConsentimiento, isNotNull);

      final revocado = otorgado.copyWith(
        consentimientoOtorgado: false,
        limpiarFechaConsentimiento: true,
      );
      expect(revocado.consentimientoOtorgado, isFalse);
      expect(revocado.fechaConsentimiento, isNull);
    });

    test('iniciales toma la primera letra de nombres y apellidos', () {
      expect(base.iniciales, 'NA');
    });
  });

  group('EstadoCita', () {
    test('pendiente, confirmada y reprogramada son estados activos', () {
      expect(EstadoCita.pendiente.esActiva, isTrue);
      expect(EstadoCita.confirmada.esActiva, isTrue);
      expect(EstadoCita.reprogramada.esActiva, isTrue);
    });

    test('cancelada, atendida e inasistencia son terminales', () {
      expect(EstadoCita.cancelada.esTerminal, isTrue);
      expect(EstadoCita.atendida.esTerminal, isTrue);
      expect(EstadoCita.inasistencia.esTerminal, isTrue);
    });

    test('desdeClave resuelve el valor de transporte', () {
      expect(EstadoCita.desdeClave('confirmada'), EstadoCita.confirmada);
      expect(() => EstadoCita.desdeClave('inventado'), throwsArgumentError);
    });
  });

  group('IntencionAsistente', () {
    test('una clave desconocida cae en noReconocida, sin lanzar', () {
      expect(
        IntencionAsistente.desdeClave('saludar'),
        IntencionAsistente.noReconocida,
      );
      expect(IntencionAsistente.desdeClave(null),
          IntencionAsistente.noReconocida);
    });

    test('noReconocida no es accionable', () {
      expect(IntencionAsistente.noReconocida.esAccionable, isFalse);
      expect(IntencionAsistente.reservar.esAccionable, isTrue);
    });
  });

  group('CanalReserva', () {
    test('solo los canales de la app cuentan como autogestionados (HU-11)', () {
      expect(CanalReserva.conversacional.esAutogestionada, isTrue);
      expect(CanalReserva.flujoGuiado.esAutogestionada, isTrue);
      expect(CanalReserva.presencial.esAutogestionada, isFalse);
      expect(CanalReserva.telefonico.esAutogestionada, isFalse);
    });
  });

  group('CupoDisponible', () {
    final cupo = CupoDisponible(
      id: 'cupo-1',
      profesionalId: 'prof-1',
      sedeId: 'sede-1',
      consultorioId: 'cons-1',
      fechaHoraInicio: DateTime(2026, 9, 20, 8, 30),
      duracionMinutos: 30,
    );

    test('fechaHoraFin suma la duracion', () {
      expect(cupo.fechaHoraFin, DateTime(2026, 9, 20, 9, 0));
    });

    test('soloFecha descarta la hora', () {
      expect(cupo.soloFecha, DateTime(2026, 9, 20));
    });
  });

  group('Cita', () {
    final cita = Cita(
      id: 'cita-1',
      pacienteId: 'pac-1',
      cupoId: 'cupo-1',
      estado: EstadoCita.confirmada,
      fechaCreacion: DateTime(2026, 9, 15),
      canalReserva: CanalReserva.conversacional,
    );

    test('esActiva delega en el estado', () {
      expect(cita.esActiva, isTrue);
      expect(cita.copyWith(estado: EstadoCita.cancelada).esActiva, isFalse);
    });

    test('la igualdad distingue el estado', () {
      expect(cita.copyWith(estado: EstadoCita.cancelada), isNot(equals(cita)));
    });
  });

  group('Especialidad', () {
    test('copyWith conserva los campos no indicados', () {
      const e = Especialidad(
        id: 'esp-1',
        nombre: 'Demo',
        descripcion: 'Descripcion demo',
      );
      final inactiva = e.copyWith(activa: false);
      expect(inactiva.activa, isFalse);
      expect(inactiva.nombre, 'Demo');
    });
  });
}
