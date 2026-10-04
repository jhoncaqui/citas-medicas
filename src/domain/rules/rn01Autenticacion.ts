import { OperacionProtegida, Paciente, ResultadoRegla } from '../../types';
import { Resultado } from './resultadoRegla';

export const CODIGO_RN01 = 'RN-01';

const DESCRIPCIONES_OPERACION: Record<OperacionProtegida, { descripcion: string; soloAdministracion: boolean }> = {
  reservar: { descripcion: 'reservar una cita', soloAdministracion: false },
  reprogramar: { descripcion: 'reprogramar una cita', soloAdministracion: false },
  cancelar: { descripcion: 'cancelar una cita', soloAdministracion: false },
  consultarHistorial: { descripcion: 'consultar tu historial', soloAdministracion: false },
  verIndicadores: { descripcion: 'ver los indicadores', soloAdministracion: true },
};

export class Rn01Autenticacion {
  static validar(pacienteAutenticado: Paciente | null, operacion: OperacionProtegida): ResultadoRegla {
    const config = DESCRIPCIONES_OPERACION[operacion];

    if (!pacienteAutenticado) {
      return Resultado.infringe(
        CODIGO_RN01,
        `Inicia sesión para ${config.descripcion}.`
      );
    }

    // Los administradores tienen control total sobre todas las operaciones del sistema
    if (pacienteAutenticado.rol === 'administrador') {
      return Resultado.valida(CODIGO_RN01);
    }

    if (config.soloAdministracion) {
      return Resultado.infringe(
        CODIGO_RN01,
        'Esta sección es solo para el personal de administración.'
      );
    }

    return Resultado.valida(CODIGO_RN01);
  }

  static validarTitularidad(
    pacienteAutenticado: Paciente | null,
    pacienteIdDelRecurso: string,
    operacion: OperacionProtegida
  ): ResultadoRegla {
    const base = this.validar(pacienteAutenticado, operacion);
    if (base.infringida) return base;

    // Los administradores tienen control total para gestionar citas de cualquier paciente
    if (pacienteAutenticado?.rol === 'administrador') {
      return Resultado.valida(CODIGO_RN01);
    }

    if (pacienteAutenticado?.id !== pacienteIdDelRecurso) {
      return Resultado.infringe(
        CODIGO_RN01,
        'No puedes gestionar una cita que no te pertenece.'
      );
    }

    return Resultado.valida(CODIGO_RN01);
  }
}
