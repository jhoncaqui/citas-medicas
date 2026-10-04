import { Cita, ResultadoRegla } from '../../types';
import { Resultado } from './resultadoRegla';

export const CODIGO_RN06 = 'RN-06';
export const CODIGO_RN07 = 'RN-07';
export const CODIGO_RN08 = 'RN-08';

export type AccionAutogestion = 'cancelar' | 'reprogramar';

export class Rn06Autogestion {
  static readonly horasMinimasDefault = 24;

  static validar(
    cita: Cita,
    accion: AccionAutogestion,
    ahora: Date = new Date(),
    horasMinimas: number = this.horasMinimasDefault,
    esAdmin: boolean = false
  ): ResultadoRegla {
    // Si es administrador con control total, tiene permiso para gestionar cualquier cita
    if (esAdmin) {
      return Resultado.valida(CODIGO_RN06);
    }

    const esActiva = cita.estado === 'confirmada' || cita.estado === 'reprogramada';
    if (!esActiva) {
      return Resultado.infringe(
        CODIGO_RN06,
        `Esta cita está ${cita.estado} y ya no se puede ${accion}.`
      );
    }

    if (!cita.fechaHoraInicio) {
      return Resultado.infringe(
        CODIGO_RN06,
        'No se pudo determinar la fecha de la cita.'
      );
    }

    const inicio = new Date(cita.fechaHoraInicio);

    if (inicio.getTime() <= ahora.getTime()) {
      return Resultado.infringe(
        CODIGO_RN06,
        'La hora de la cita ya pasó. Comunícate con la clínica.'
      );
    }

    const horasRestantes = (inicio.getTime() - ahora.getTime()) / (1000 * 60 * 60);
    if (horasRestantes < horasMinimas) {
      return Resultado.infringe(
        CODIGO_RN06,
        `Solo puedes ${accion} tu cita hasta ${horasMinimas} horas antes. Comunícate con la clínica para gestionarla.`
      );
    }

    return Resultado.valida(CODIGO_RN06);
  }

  static sePuede(
    cita: Cita,
    accion: AccionAutogestion,
    ahora: Date = new Date(),
    horasMinimas?: number,
    esAdmin: boolean = false
  ): boolean {
    return this.validar(cita, accion, ahora, horasMinimas, esAdmin).cumple;
  }
}

export class Rn07Recordatorio {
  static readonly horasAntelacionDefault = 24;

  static momentoDeAviso(
    cita: Cita,
    ahora: Date = new Date(),
    horasAntelacion: number = this.horasAntelacionDefault
  ): Date | null {
    const esActiva = cita.estado === 'confirmada' || cita.estado === 'reprogramada';
    if (!esActiva || !cita.fechaHoraInicio) return null;

    const inicio = new Date(cita.fechaHoraInicio);
    const aviso = new Date(inicio.getTime() - horasAntelacion * 60 * 60 * 1000);

    if (aviso.getTime() <= ahora.getTime()) return null;
    return aviso;
  }
}

export class Rn08Inasistencia {
  static readonly horasMargenDefault = 2;

  static debeMarcarse(
    cita: Cita,
    ahora: Date = new Date(),
    horasMargen: number = this.horasMargenDefault
  ): boolean {
    if (cita.estado !== 'confirmada' && cita.estado !== 'reprogramada') {
      return false;
    }

    if (cita.fechaAtencion) return false;
    if (!cita.fechaHoraInicio) return false;

    const inicio = new Date(cita.fechaHoraInicio);
    const limite = new Date(inicio.getTime() + horasMargen * 60 * 60 * 1000);

    return ahora.getTime() > limite.getTime();
  }

  static aplicar(
    cita: Cita,
    ahora: Date = new Date(),
    horasMargen: number = this.horasMargenDefault
  ): Cita {
    if (!this.debeMarcarse(cita, ahora, horasMargen)) {
      return cita;
    }
    return { ...cita, estado: 'inasistencia' };
  }

  static proporcion(citas: Cita[]): number | null {
    const pasadas = citas.filter((c) => c.estado === 'atendida' || c.estado === 'inasistencia');
    if (pasadas.length === 0) return null;

    const inasistencias = pasadas.filter((c) => c.estado === 'inasistencia').length;
    return inasistencias / pasadas.length;
  }
}
