import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/entities/rol_usuario.dart';
import 'package:citas_medicas_app/domain/rules/resultado_regla.dart';
import 'package:citas_medicas_app/domain/rules/rn01_autenticacion.dart';
import 'package:citas_medicas_app/domain/rules/rn10_consentimiento.dart';
import 'package:flutter_test/flutter_test.dart';

const _pacienteConConsentimiento = Paciente(
  id: 'pac-1',
  tipoDocumento: TipoDocumento.dni,
  numeroDocumento: '12345678',
  nombres: 'Nombre',
  apellidos: 'Apellido',
  correo: 'correo@ejemplo.test',
  telefono: '999888777',
  consentimientoOtorgado: true,
);

final _administrador = _pacienteConConsentimiento.copyWith(
  id: 'adm-1',
  tipoDocumento: TipoDocumento.usuario,
  numeroDocumento: 'ADMIN',
  rol: RolUsuario.administrador,
);

/// Operaciones de paciente: todas menos las exclusivas de administracion.
final _operacionesDePaciente = OperacionProtegida.values
    .where((o) => !o.soloAdministracion)
    .toList();

void main() {
  group('RN-01 — solo un paciente autenticado opera sobre citas', () {
    test('sin sesion, toda operacion protegida se rechaza', () {
      for (final operacion in OperacionProtegida.values) {
        final r = Rn01Autenticacion.validar(
          pacienteAutenticado: null,
          operacion: operacion,
        );
        expect(r.infringida, isTrue, reason: '$operacion deberia rechazarse');
        expect(r.regla, 'RN-01');
        expect(r.mensaje, contains(operacion.descripcion));
      }
    });

    test('con sesion de paciente, sus operaciones se permiten', () {
      expect(_operacionesDePaciente, isNotEmpty);
      for (final operacion in _operacionesDePaciente) {
        expect(
          Rn01Autenticacion.validar(
            pacienteAutenticado: _pacienteConConsentimiento,
            operacion: operacion,
          ).cumple,
          isTrue,
          reason: '$operacion deberia permitirse a un paciente',
        );
      }
    });

    test('un paciente NO puede ver los indicadores', () {
      final r = Rn01Autenticacion.validar(
        pacienteAutenticado: _pacienteConConsentimiento,
        operacion: OperacionProtegida.verIndicadores,
      );
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('personal de administracion'));
    });

    test('un administrador SI puede ver los indicadores', () {
      expect(
        Rn01Autenticacion.validar(
          pacienteAutenticado: _administrador,
          operacion: OperacionProtegida.verIndicadores,
        ).cumple,
        isTrue,
      );
    });

    test('un administrador NO puede reservar, reprogramar ni cancelar', () {
      for (final operacion in _operacionesDePaciente) {
        final r = Rn01Autenticacion.validar(
          pacienteAutenticado: _administrador,
          operacion: operacion,
        );
        expect(
          r.infringida,
          isTrue,
          reason: 'Una cuenta de administracion no debe poder ${operacion.descripcion}',
        );
        expect(r.mensaje, contains('administracion'));
      }
    });

    test('un administrador tampoco gestiona citas ajenas', () {
      expect(
        Rn01Autenticacion.validarTitularidad(
          pacienteAutenticado: _administrador,
          pacienteIdDelRecurso: 'pac-1',
          operacion: OperacionProtegida.cancelar,
        ).infringida,
        isTrue,
      );
    });

    test('una clave de rol desconocida cae en paciente, nunca en admin', () {
      expect(RolUsuario.desdeClave('superusuario'), RolUsuario.paciente);
      expect(RolUsuario.desdeClave(null), RolUsuario.paciente);
      expect(
        RolUsuario.desdeClave('administrador'),
        RolUsuario.administrador,
      );
    });

    test('un paciente no puede gestionar la cita de otro', () {
      final r = Rn01Autenticacion.validarTitularidad(
        pacienteAutenticado: _pacienteConConsentimiento,
        pacienteIdDelRecurso: 'pac-999',
        operacion: OperacionProtegida.cancelar,
      );
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('no te pertenece'));
    });

    test('un paciente si puede gestionar su propia cita', () {
      expect(
        Rn01Autenticacion.validarTitularidad(
          pacienteAutenticado: _pacienteConConsentimiento,
          pacienteIdDelRecurso: 'pac-1',
          operacion: OperacionProtegida.cancelar,
        ).cumple,
        isTrue,
      );
    });

    test('sin sesion, la titularidad falla por falta de autenticacion', () {
      final r = Rn01Autenticacion.validarTitularidad(
        pacienteAutenticado: null,
        pacienteIdDelRecurso: 'pac-1',
        operacion: OperacionProtegida.reprogramar,
      );
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('Inicia sesion'));
    });
  });

  group('RN-10 — consentimiento informado', () {
    test('sin aceptar, el registro se rechaza', () {
      final r = Rn10Consentimiento.validarParaRegistro(aceptado: false);
      expect(r.infringida, isTrue);
      expect(r.regla, 'RN-10');
      expect(r.campo, 'consentimiento');
    });

    test('aceptado, el registro procede', () {
      expect(
        Rn10Consentimiento.validarParaRegistro(aceptado: true).cumple,
        isTrue,
      );
    });

    test('un paciente sin consentimiento vigente no puede operar', () {
      final sinConsentimiento = _pacienteConConsentimiento.copyWith(
        consentimientoOtorgado: false,
      );
      final r = Rn10Consentimiento.validarVigente(paciente: sinConsentimiento);
      expect(r.infringida, isTrue);
      expect(r.mensaje, contains('Revocaste'));
    });

    test('sin paciente tampoco hay consentimiento vigente', () {
      expect(
        Rn10Consentimiento.validarVigente(paciente: null).infringida,
        isTrue,
      );
    });

    test('otorgar deja constancia del momento', () {
      final ahora = DateTime(2026, 9, 15, 10, 30);
      final base = _pacienteConConsentimiento.copyWith(
        consentimientoOtorgado: false,
      );

      final otorgado = Rn10Consentimiento.otorgar(base, ahora: ahora);
      expect(otorgado.consentimientoOtorgado, isTrue);
      expect(otorgado.fechaConsentimiento, ahora);
    });

    test('revocar borra la marca y la fecha (HU-12)', () {
      final otorgado = Rn10Consentimiento.otorgar(
        _pacienteConConsentimiento,
        ahora: DateTime(2026, 9, 15),
      );

      final revocado = Rn10Consentimiento.revocar(otorgado);
      expect(revocado.consentimientoOtorgado, isFalse);
      expect(revocado.fechaConsentimiento, isNull);
    });

    test('revocar y volver a otorgar es reversible', () {
      final revocado = Rn10Consentimiento.revocar(_pacienteConConsentimiento);
      final reotorgado = Rn10Consentimiento.otorgar(
        revocado,
        ahora: DateTime(2026, 10, 1),
      );
      expect(reotorgado.consentimientoOtorgado, isTrue);
      expect(reotorgado.fechaConsentimiento, DateTime(2026, 10, 1));
    });
  });

  group('primeraInfraccion', () {
    test('devuelve la primera regla infringida', () {
      final veredictos = <ResultadoRegla>[
        const ResultadoRegla.valida('RN-01'),
        const ResultadoRegla.infringe('RN-10', mensaje: 'falta consentimiento'),
        const ResultadoRegla.infringe('RN-02', mensaje: 'documento invalido'),
      ];
      expect(primeraInfraccion(veredictos).regla, 'RN-10');
    });

    test('si todas cumplen, devuelve un veredicto valido', () {
      final veredictos = <ResultadoRegla>[
        const ResultadoRegla.valida('RN-01'),
        const ResultadoRegla.valida('RN-10'),
      ];
      expect(primeraInfraccion(veredictos).cumple, isTrue);
    });
  });
}
