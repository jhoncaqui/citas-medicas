import { Cita, CupoDisponible, ResultadoRegla } from '../../types';
import { Resultado } from './resultadoRegla';

export const CODIGO_RN03 = 'RN-03';
export const CODIGO_RN04 = 'RN-04';
export const CODIGO_RN05 = 'RN-05';

export class Rn03CupoUnico {
  static validar(cupo: CupoDisponible, citasDelSistema: Cita[]): ResultadoRegla {
    if (!cupo.disponible) {
      return Resultado.infringe(
        CODIGO_RN03,
        'Ese horario acaba de ocuparse. Elige otro, por favor.'
      );
    }

    const ocupado = citasDelSistema.some(
      (c) => c.cupoId === cupo.id && (c.estado === 'confirmada' || c.estado === 'reprogramada')
    );

    if (ocupado) {
      return Resultado.infringe(
        CODIGO_RN03,
        'Ese horario acaba de ocuparse. Elige otro, por favor.'
      );
    }

    return Resultado.valida(CODIGO_RN03);
  }
}

export class Rn04NoEnElPasado {
  static readonly margenMinimoMs = 15 * 60 * 1000; // 15 minutos

  static validar(fechaHoraInicio: Date | string, ahora: Date = new Date()): ResultadoRegla {
    const inicio = typeof fechaHoraInicio === 'string' ? new Date(fechaHoraInicio) : fechaHoraInicio;

    if (inicio.getTime() <= ahora.getTime()) {
      return Resultado.infringe(
        CODIGO_RN04,
        'No se pueden reservar horarios que ya pasaron.',
        'fecha'
      );
    }

    if (inicio.getTime() - ahora.getTime() < this.margenMinimoMs) {
      return Resultado.infringe(
        CODIGO_RN04,
        'Ese horario está demasiado próximo. Elige uno con al menos 15 minutos de anticipación.',
        'fecha'
      );
    }

    return Resultado.valida(CODIGO_RN04);
  }

  static filtrar(cupos: CupoDisponible[], ahora: Date = new Date()): CupoDisponible[] {
    return cupos.filter((c) => this.validar(c.fechaHoraInicio, ahora).cumple);
  }
}

export class Rn05SinDuplicados {
  static validar(
    especialidadId: string,
    profesionalId: string,
    fechaHoraInicio: Date | string,
    citasDelPaciente: Cita[]
  ): ResultadoRegla {
    const targetDate = typeof fechaHoraInicio === 'string' ? new Date(fechaHoraInicio) : fechaHoraInicio;
    const targetDay = `${targetDate.getFullYear()}-${targetDate.getMonth()}-${targetDate.getDate()}`;

    const duplicada = citasDelPaciente.some((c) => {
      const esActiva = c.estado === 'confirmada' || c.estado === 'reprogramada';
      if (!esActiva) return false;
      if (c.especialidadId !== especialidadId) return false;
      if (c.profesionalId !== profesionalId) return false;

      const cDate = new Date(c.fechaHoraInicio);
      const cDay = `${cDate.getFullYear()}-${cDate.getMonth()}-${cDate.getDate()}`;
      return cDay === targetDay;
    });

    if (duplicada) {
      return Resultado.infringe(
        CODIGO_RN05,
        'Ya tienes una cita ese día con ese profesional para la misma especialidad.'
      );
    }

    return Resultado.valida(CODIGO_RN05);
  }
}
