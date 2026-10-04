import { Paciente, ResultadoRegla } from '../../types';
import { Resultado } from './resultadoRegla';

export const CODIGO_RN10 = 'RN-10';

export class Rn10Consentimiento {
  static validarParaRegistro(aceptado: boolean): ResultadoRegla {
    if (!aceptado) {
      return Resultado.infringe(
        CODIGO_RN10,
        'Debes aceptar el tratamiento de tus datos para registrarte.',
        'consentimiento'
      );
    }
    return Resultado.valida(CODIGO_RN10);
  }

  static validarVigente(paciente: Paciente | null): ResultadoRegla {
    if (!paciente) {
      return Resultado.infringe(CODIGO_RN10, 'No hay una sesión activa.');
    }
    if (!paciente.consentimientoOtorgado) {
      return Resultado.infringe(
        CODIGO_RN10,
        'Revocaste el consentimiento para el tratamiento de tus datos. Para volver a reservar necesitas otorgarlo de nuevo.'
      );
    }
    return Resultado.valida(CODIGO_RN10);
  }

  static otorgar(paciente: Paciente, ahora: Date = new Date()): Paciente {
    return {
      ...paciente,
      consentimientoOtorgado: true,
      fechaConsentimiento: ahora.toISOString(),
    };
  }

  static revocar(paciente: Paciente): Paciente {
    return {
      ...paciente,
      consentimientoOtorgado: false,
      fechaConsentimiento: null,
    };
  }
}
