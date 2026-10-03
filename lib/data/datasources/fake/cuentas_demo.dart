// =====================================================================
// CUENTAS DE DEMOSTRACION — SOLO PARA EL MODO LOCAL
// =====================================================================
//
// Estas cuentas existen unicamente cuando la aplicacion usa la autenticacion
// local (`usarFirebase` en `false`). En cuanto se conecte Firebase o el
// backend real, este archivo deja de usarse y las cuentas desaparecen con el.
//
// **La clave es una clave de demostracion compartida y conocida.** No debe
// reutilizarse en ningun sistema real ni con ninguna cuenta real. Por eso el
// sembrado esta apagado por defecto en las compilaciones release
// (`FeatureFlags.sembrarCuentasDemo`): un AAB con credenciales conocidas
// incrustadas no debe salir de la sala de pruebas.
//
// Datos de los pacientes: FICTICIOS, con el mismo criterio que `fixtures.dart`.
// Los DNI empiezan por `0000000` a proposito: ningun DNI real tiene ese
// formato, asi que no pueden coincidir con el de una persona de verdad.
//
// Consentimiento: las cuentas nacen con el consentimiento (RN-10) ya
// otorgado. Es un atajo de demostracion: no pasaron por el registro, que es
// donde se otorga de verdad.
// =====================================================================

import '../../models/paciente_dto.dart';
import 'fake_paciente_datasource.dart';

class CuentasDemo {
  const CuentasDemo._();

  /// Clave compartida por todas las cuentas de demostracion.
  static const String clave = 'clave1234';

  static const String _consentimiento = '2026-09-01T00:00:00.000';

  // -------------------------------------------------------------------
  // Administracion — inician sesion con el nombre de usuario
  // -------------------------------------------------------------------

  static const List<PacienteDto> administradores = <PacienteDto>[
    PacienteDto(
      id: 'adm-demo-jcaqui',
      tipoDocumento: 'USR',
      numeroDocumento: 'JCAQUI',
      nombres: 'Jhon Daniel',
      apellidos: 'Caqui Calixto',
      correo: 'jcaqui@ejemplo.test',
      telefono: '',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
      rol: 'administrador',
    ),
    PacienteDto(
      id: 'adm-demo-emamani',
      tipoDocumento: 'USR',
      numeroDocumento: 'EMAMANI',
      nombres: 'Elmer Willie',
      apellidos: 'Mamani Quispe',
      correo: 'emamani@ejemplo.test',
      telefono: '',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
      rol: 'administrador',
    ),
    PacienteDto(
      id: 'adm-demo-ksaavedra',
      tipoDocumento: 'USR',
      numeroDocumento: 'KSAAVEDRA',
      nombres: 'Karen Margarita',
      apellidos: 'Saavedra Bautista',
      correo: 'ksaavedra@ejemplo.test',
      telefono: '',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
      rol: 'administrador',
    ),
  ];

  // -------------------------------------------------------------------
  // Pacientes — inician sesion con el DNI
  // -------------------------------------------------------------------

  static const List<PacienteDto> pacientes = <PacienteDto>[
    PacienteDto(
      id: 'pac-demo-01',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000001',
      nombres: 'Paciente Uno',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente1@ejemplo.test',
      telefono: '900000001',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
    ),
    PacienteDto(
      id: 'pac-demo-02',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000002',
      nombres: 'Paciente Dos',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente2@ejemplo.test',
      telefono: '900000002',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
    ),
    PacienteDto(
      id: 'pac-demo-03',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000003',
      nombres: 'Paciente Tres',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente3@ejemplo.test',
      telefono: '900000003',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
    ),
    PacienteDto(
      id: 'pac-demo-04',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000004',
      nombres: 'Paciente Cuatro',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente4@ejemplo.test',
      telefono: '900000004',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
    ),
    PacienteDto(
      id: 'pac-demo-05',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000005',
      nombres: 'Paciente Cinco',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente5@ejemplo.test',
      telefono: '900000005',
      consentimientoOtorgado: true,
      fechaConsentimiento: _consentimiento,
    ),
  ];

  /// Todas las cuentas, listas para sembrar con la clave compartida.
  static List<CuentaInicial> get todas => <CuentaInicial>[
    for (final perfil in <PacienteDto>[...administradores, ...pacientes])
      CuentaInicial(perfil: perfil, clave: clave),
  ];
}
