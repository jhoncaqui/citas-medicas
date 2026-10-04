import { TurnoDia } from '../types';

export interface FechaInterpretada {
  fecha: Date;
  expresionOriginal: string;
  turno?: TurnoDia;
  horaMinutos?: number;
}

const MESES: Record<string, number> = {
  enero: 0,
  febrero: 1,
  marzo: 2,
  abril: 3,
  mayo: 4,
  junio: 5,
  julio: 6,
  agosto: 7,
  setiembre: 8,
  septiembre: 8,
  octubre: 9,
  noviembre: 10,
  diciembre: 11,
};

const DIAS_SEMANA: Record<string, number> = {
  domingo: 0,
  lunes: 1,
  martes: 2,
  miercoles: 3,
  jueves: 4,
  viernes: 5,
  sabado: 6,
};

const NOMBRES_DIAS = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
const NOMBRES_MESES = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

export class FormatoFecha {
  static fechaLarga(fechaOrIso: Date | string): string {
    const f = typeof fechaOrIso === 'string' ? new Date(fechaOrIso) : fechaOrIso;
    const diaSemana = NOMBRES_DIAS[f.getDay()];
    const dia = f.getDate();
    const mes = NOMBRES_MESES[f.getMonth()];
    const anio = f.getFullYear();
    return `${diaSemana}, ${dia} de ${mes} de ${anio}`;
  }

  static fechaCorta(fechaOrIso: Date | string): string {
    const f = typeof fechaOrIso === 'string' ? new Date(fechaOrIso) : fechaOrIso;
    const dia = String(f.getDate()).padStart(2, '0');
    const mes = String(f.getMonth() + 1).padStart(2, '0');
    const anio = f.getFullYear();
    return `${dia}/${mes}/${anio}`;
  }

  static hora(fechaOrIso: Date | string): string {
    const f = typeof fechaOrIso === 'string' ? new Date(fechaOrIso) : fechaOrIso;
    let horas = f.getHours();
    const minutos = String(f.getMinutes()).padStart(2, '0');
    const ampm = horas >= 12 ? 'p. m.' : 'a. m.';
    horas = horas % 12;
    horas = horas ? horas : 12;
    const horasStr = String(horas).padStart(2, '0');
    return `${horasStr}:${minutos} ${ampm}`;
  }

  static desde(fechaOrIso: Date | string, ahora: Date = new Date()): string {
    const f = typeof fechaOrIso === 'string' ? new Date(fechaOrIso) : fechaOrIso;
    const diffMs = ahora.getTime() - f.getTime();
    const diffSeg = Math.floor(diffMs / 1000);

    if (diffSeg < 60) return 'hace un momento';
    const diffMin = Math.floor(diffSeg / 60);
    if (diffMin < 60) return `hace ${diffMin} min`;
    const diffHoras = Math.floor(diffMin / 60);
    if (diffHoras < 24) return `hace ${diffHoras} h`;
    return this.fechaCorta(f);
  }
}

export class FechasNaturales {
  static normalizar(texto: string): string {
    const conTilde = 'áéíóúàèìòùäëïöüâêîôûñ';
    const sinTilde = 'aeiouaeiouaeiouaeioun';
    let resultado = texto.toLowerCase().trim();
    for (let i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  static detectarTurno(textoNormalizado: string): TurnoDia | undefined {
    const t = textoNormalizado;
    if (
      t.includes('por la manana') ||
      t.includes('en la manana') ||
      t.includes('de la manana') ||
      t.includes('temprano')
    ) {
      return 'manana';
    }
    if (t.includes('tarde') || t.includes('mediodia') || t.includes('por la tarde') || t.includes('en la tarde')) {
      return 'tarde';
    }
    return undefined;
  }

  static detectarHora(textoNormalizado: string): number | undefined {
    const t = textoNormalizado;

    const conMinutos = /(\d{1,2})[:.](\d{2})/.exec(t);
    if (conMinutos) {
      let h = parseInt(conMinutos[1], 10);
      const m = parseInt(conMinutos[2], 10);
      if (h < 24 && m < 60) {
        h = this.ajustarPorSufijo(h, t);
        return h * 60 + m;
      }
    }

    const aLas = /a la?s? (\d{1,2})(?![:.\d])/.exec(t);
    if (aLas) {
      let h = parseInt(aLas[1], 10);
      if (h < 24) {
        h = this.ajustarPorSufijo(h, t);
        return h * 60;
      }
    }

    return undefined;
  }

  private static ajustarPorSufijo(hora: number, texto: string): number {
    const esTarde =
      texto.includes('pm') ||
      texto.includes('de la tarde') ||
      texto.includes('por la tarde') ||
      texto.includes('de la noche');
    if (esTarde && hora < 12) return hora + 12;
    return hora;
  }

  static interpretar(texto: string, ahora: Date = new Date()): FechaInterpretada | null {
    const t = this.normalizar(texto);
    const hoy = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());

    const turno = this.detectarTurno(t);
    const horaMinutos = this.detectarHora(t);

    let fecha: Date | null = null;
    let expresion = texto.trim();

    // Eliminar referencias a 'la mañana' como turno para evitar falso positivo con 'mañana'
    const sinTurno = t
      .replace(/(por|en|de|a)\s+la\s+manana/g, ' ')
      .replace(/\sla\s+manana\s/g, ' ');

    // Expresiones relativas
    if (t.includes('pasado manana')) {
      fecha = new Date(hoy.getTime() + 2 * 86400000);
      expresion = 'pasado mañana';
    } else if (sinTurno.includes('manana') || t.includes('el dia de manana') || t.includes('dia de manana') || t.includes('para manana')) {
      fecha = new Date(hoy.getTime() + 1 * 86400000);
      expresion = 'mañana';
    } else if (t.includes('hoy') || t.includes('el dia de hoy') || t.includes('hoy mismo')) {
      fecha = hoy;
      expresion = 'hoy';
    } else if (t.includes('fin de semana')) {
      const diffSabado = (6 - hoy.getDay() + 7) % 7 || 7;
      fecha = new Date(hoy.getTime() + diffSabado * 86400000);
      expresion = 'este fin de semana';
    }

    // Días de la semana
    if (!fecha) {
      for (const [diaNombre, diaNum] of Object.entries(DIAS_SEMANA)) {
        if (!t.includes(diaNombre)) continue;

        const saltarSemana =
          t.includes('proxima semana') ||
          t.includes('siguiente semana') ||
          t.includes('que viene');

        let diff = (diaNum - hoy.getDay() + 7) % 7;
        if (diff === 0) diff = 7;
        if (saltarSemana) diff += 7;

        fecha = new Date(hoy.getTime() + diff * 86400000);
        expresion = diaNombre;
        break;
      }
    }

    // Próxima semana sin día: próximo lunes
    if (!fecha && (t.includes('proxima semana') || t.includes('siguiente semana') || t.includes('semana que viene'))) {
      let diff = (1 - hoy.getDay() + 7) % 7;
      if (diff === 0) diff = 7;
      fecha = new Date(hoy.getTime() + diff * 86400000);
      expresion = 'la próxima semana';
    }

    // "en N días" o "dentro de N días"
    if (!fecha) {
      const enDias = /(?:en|dentro de)\s+(\d{1,2})\s+dias?/.exec(t);
      if (enDias) {
        const dias = parseInt(enDias[1], 10);
        fecha = new Date(hoy.getTime() + dias * 86400000);
        expresion = enDias[0];
      }
    }

    // Fecha explícita con mes: "20 de octubre", "el 5 de noviembre"
    if (!fecha) {
      const conMes = /(?:el\s+)?(?:dia\s+)?(\d{1,2})\s+de\s+([a-z]+)/.exec(t);
      if (conMes) {
        const dia = parseInt(conMes[1], 10);
        const mes = MESES[conMes[2]];
        if (mes !== undefined && dia >= 1 && dia <= 31) {
          const candidata = new Date(hoy.getFullYear(), mes, dia);
          fecha = candidata.getTime() < hoy.getTime()
            ? new Date(hoy.getFullYear() + 1, mes, dia)
            : candidata;
          expresion = conMes[0];
        }
      }
    }

    // Fecha numérica: 20/10 o 20-10 o 20/10/2026
    if (!fecha) {
      const numerica = /(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?/.exec(t);
      if (numerica) {
        const dia = parseInt(numerica[1], 10);
        const mes = parseInt(numerica[2], 10) - 1;
        if (dia >= 1 && dia <= 31 && mes >= 0 && mes <= 11) {
          const anioStr = numerica[3];
          let anio = anioStr ? parseInt(anioStr, 10) : hoy.getFullYear();
          if (anio < 100) anio += 2000;
          const candidata = new Date(anio, mes, dia);
          fecha = !anioStr && candidata.getTime() < hoy.getTime()
            ? new Date(hoy.getFullYear() + 1, mes, dia)
            : candidata;
          expresion = numerica[0];
        }
      }
    }

    // Solo día del mes: "para el 15", "el día 20", "el 8"
    if (!fecha) {
      const soloDia = /(?:el\s+dia\s+|para\s+el\s+|el\s+)(\d{1,2})(?!\s*[a-z0-9/:-])/.exec(t);
      if (soloDia) {
        const dia = parseInt(soloDia[1], 10);
        if (dia >= 1 && dia <= 31) {
          let mes = hoy.getMonth();
          let anio = hoy.getFullYear();
          const candidata = new Date(anio, mes, dia);
          if (candidata.getTime() < hoy.getTime()) {
            mes = (mes + 1) % 12;
            if (mes === 0) anio++;
          }
          fecha = new Date(anio, mes, dia);
          expresion = `el ${dia}`;
        }
      }
    }

    if (!fecha) return null;

    return {
      fecha,
      expresionOriginal: expresion,
      turno,
      horaMinutos,
    };
  }
}
