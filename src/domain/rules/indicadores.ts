import { CanalReserva, Cita, IndicadoresData, PeriodoIndicadores } from '../../types';

export class IndicadoresCalculator {
  static calcular(citas: Cita[], periodo: PeriodoIndicadores = 'ultimos30', ahora: Date = new Date()): IndicadoresData {
    let desde: Date | null = null;
    if (periodo === 'ultimos7') {
      desde = new Date(ahora.getTime() - 7 * 86400000);
    } else if (periodo === 'ultimos30') {
      desde = new Date(ahora.getTime() - 30 * 86400000);
    }

    const enPeriodo = citas.filter((c) => {
      if (!desde) return true;
      const fCreacion = new Date(c.fechaCreacion);
      return fCreacion.getTime() >= desde.getTime();
    });

    const reservadas = enPeriodo.length;
    const canceladas = enPeriodo.filter((c) => c.estado === 'cancelada').length;
    const inasistencias = enPeriodo.filter((c) => c.estado === 'inasistencia').length;
    const atendidas = enPeriodo.filter((c) => c.estado === 'atendida').length;
    const autogestionadas = enPeriodo.filter(
      (c) => c.canalReserva === 'conversacional' || c.canalReserva === 'flujo_guiado'
    ).length;

    const cerradas = atendidas + inasistencias;
    const tasaInasistencia = cerradas === 0 ? null : inasistencias / cerradas;
    const tasaCancelacion = reservadas === 0 ? null : canceladas / reservadas;
    const tasaAutogestion = reservadas === 0 ? null : autogestionadas / reservadas;

    const porCanal: Record<CanalReserva, number> = {
      conversacional: 0,
      flujo_guiado: 0,
      telefonico: 0,
      presencial: 0,
    };

    for (const cita of enPeriodo) {
      if (porCanal[cita.canalReserva] !== undefined) {
        porCanal[cita.canalReserva]++;
      }
    }

    return {
      reservadas,
      canceladas,
      inasistencias,
      atendidas,
      autogestionadas,
      cerradas,
      tasaInasistencia,
      tasaCancelacion,
      tasaAutogestion,
      sinDatos: reservadas === 0,
      porCanal,
    };
  }
}
