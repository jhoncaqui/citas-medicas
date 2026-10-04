import { Cadenas } from '../constants/cadenas';
import { ESPECIALIDADES, PROFESIONALES } from '../constants/fixtures';
import { Rn09GuardarrailClinico } from '../domain/rules/rn09GuardarrailClinico';
import { Especialidad, IntencionAsistente, Profesional } from '../types';
import { FechasNaturales } from '../utils/fechasNaturales';
import { ConfigService, OPCIONES_POR_DEFECTO } from './configService';

export interface AnalisisMensajeResult {
  intencion: IntencionAsistente;
  confianza: number;
  respuesta: string;
  derivadoACanalAtencion: boolean;
  entidades: Record<string, string>;
}

const PATRONES: Record<Exclude<IntencionAsistente, 'no_reconocida'>, string[]> = {
  saludo: [
    'hola',
    'buen dia',
    'buenos dias',
    'buenas tardes',
    'buenas noches',
    'que tal',
    'buenas',
    'saludos',
    'hola asistente',
    'hola bot',
    'hola doctor',
    'hola doc',
    'alo',
    'hey',
  ],
  confirmacion: [
    'si',
    'correcto',
    'de acuerdo',
    'afirmativo',
    'exacto',
    'claro',
    'por favor',
    'ok',
    'vale',
    'dale',
    'asi es',
    'confirmo',
    'confirma',
    'proceder',
    'adelante',
    'perfecto',
    'esta bien',
    'bien',
    'seguro',
    'dale si',
  ],
  reservar: [
    'reservar',
    'reserva',
    'reservacion',
    'reservame',
    'sacar cita',
    'sacar una cita',
    'sacar',
    'agendar',
    'agenda',
    'agendame',
    'agendamiento',
    'pedir cita',
    'pedir una cita',
    'pido cita',
    'separar',
    'separar cita',
    'separar turno',
    'programar',
    'programar cita',
    'apartar',
    'quiero una cita',
    'quiero cita',
    'quisiera una cita',
    'quisiera cita',
    'necesito una cita',
    'necesito cita',
    'deseo una cita',
    'deseo cita',
    'busco una cita',
    'busco cita',
    'atenderme',
    'atencion medica',
    'atencion',
    'quiero atenderme',
    'consulta medica',
    'consulta',
    'consultas',
    'quiero una consulta',
    'necesito consulta',
    'cita',
    'citas',
    'cita medica',
    'citas medicas',
    'turno',
    'turnos',
    'cupo',
    'cupos',
    'horario',
    'horarios',
    'ver al doctor',
    'ver a la doctora',
    'ver un medico',
    'ver especialista',
    'medico',
    'medica',
    'doctor',
    'doctora',
    'especialista',
    'especialidad',
    'chequeo',
    'revision',
    'consulta con',
    'atenderme con',
    'quiero',
    'quisiera',
    'necesito',
    'deseo',
    'busco',
  ],
  consultar: [
    'consultar mis citas',
    'ver mis citas',
    'mis citas',
    'que citas tengo',
    'cuando es mi cita',
    'cuando tengo',
    'revisar mi cita',
    'tengo alguna cita',
    'mi proxima cita',
    'historial',
  ],
  reprogramar: [
    'reprogramar',
    'reprograma',
    'cambiar mi cita',
    'cambiar la cita',
    'cambiar de fecha',
    'mover mi cita',
    'mover la cita',
    'posponer',
    'otro dia',
    'otra fecha',
  ],
  cancelar: [
    'cancelar',
    'cancela',
    'anular',
    'ya no quiero',
    'ya no podre',
    'dar de baja mi cita',
    'eliminar mi cita',
    'no podre ir',
  ],
};

const SINONIMOS_ESPECIALIDADES: Record<string, string[]> = {
  'esp-demo-01': [
    'medicina general',
    'medicina',
    'medico general',
    'doctor general',
    'general',
    'medica general',
    'clinico',
    'medicina familiar',
    'familiar',
    'chequeo general',
    'gripe',
    'resfriado',
    'malestar general',
    'fiebre',
    'tos',
  ],
  'esp-demo-02': [
    'pediatria',
    'pediatra',
    'pediatrico',
    'pediatrica',
    'nino',
    'ninos',
    'bebe',
    'bebes',
    'infantil',
    'hijo',
    'hija',
    'mi nene',
    'mi nino',
  ],
  'esp-demo-03': [
    'cardiologia',
    'cardiologo',
    'cardiologa',
    'corazon',
    'cardiovascular',
    'presion alta',
    'presion',
    'hipertension',
    'palpitaciones',
  ],
  'esp-demo-04': [
    'dermatologia',
    'dermatologo',
    'dermatologa',
    'piel',
    'cutaneo',
    'alergia piel',
    'manchas',
    'acne',
    'granos',
  ],
};

export class AsistenteService {
  private static obtenerEspecialidadesActuales(): Especialidad[] {
    if (typeof localStorage !== 'undefined') {
      const guardadas = localStorage.getItem('citas_medicas_especialidades_v1');
      if (guardadas) {
        try {
          return JSON.parse(guardadas);
        } catch (_) {}
      }
    }
    return ESPECIALIDADES;
  }

  private static obtenerProfesionalesActuales(): Profesional[] {
    if (typeof localStorage !== 'undefined') {
      const guardados = localStorage.getItem('citas_medicas_profesionales_v1');
      if (guardados) {
        try {
          return JSON.parse(guardados);
        } catch (_) {}
      }
    }
    return PROFESIONALES;
  }

  static analizar(texto: string, ahora: Date = new Date()): AnalisisMensajeResult {
    // RN-09: guardarraíl clínico primero (con soporte de configuración)
    const opciones = typeof localStorage !== 'undefined' ? ConfigService.obtenerOpciones() : OPCIONES_POR_DEFECTO;
    if (opciones.guardarailClinicoActivo && Rn09GuardarrailClinico.requiereDerivacion(texto)) {
      return {
        intencion: 'no_reconocida',
        confianza: 1.0,
        respuesta: Cadenas.derivacionCanalAtencion,
        derivadoACanalAtencion: true,
        entidades: {},
      };
    }

    const normalizado = FechasNaturales.normalizar(texto);
    const entidades = this.extraerEntidades(normalizado, texto, ahora);
    const { intencion: intencionDetectada, aciertos } = this.clasificar(normalizado);

    let intencion: IntencionAsistente = intencionDetectada;

    // Regla de inferencia inteligente:
    // Si el usuario menciona una especialidad, un médico, una fecha o intención médica,
    // y no pide expresamente consultar/cancelar/reprogramar, la intención es inequívocamente 'reservar'.
    const tieneElementosReserva =
      Boolean(entidades.especialidad) ||
      Boolean(entidades.profesional) ||
      Boolean(entidades.fecha) ||
      Boolean(entidades.turno) ||
      normalizado.includes('consulta') ||
      normalizado.includes('cita') ||
      normalizado.includes('atenderme') ||
      normalizado.includes('doctor') ||
      normalizado.includes('medico') ||
      normalizado.includes('horario');

    if (tieneElementosReserva && intencion !== 'consultar' && intencion !== 'reprogramar' && intencion !== 'cancelar') {
      intencion = 'reservar';
    }

    // Si es solo saludo sin entidades
    if (intencion === 'saludo' && !tieneElementosReserva) {
      return {
        intencion: 'saludo',
        confianza: 0.98,
        respuesta:
          '¡Hola! Con gusto te ayudo a agendar tu cita médica. ¿Para qué especialidad o con qué doctor deseas atenderte y para qué fecha?',
        derivadoACanalAtencion: false,
        entidades: {},
      };
    }

    // Si es confirmación explícita
    if (intencion === 'confirmacion' && !tieneElementosReserva) {
      return {
        intencion: 'confirmacion',
        confianza: 0.98,
        respuesta: '¡Perfecto!',
        derivadoACanalAtencion: false,
        entidades: {},
      };
    }

    if (intencion === 'no_reconocida') {
      return {
        intencion: 'no_reconocida',
        confianza: 0.0,
        respuesta:
          'Puedo ayudarte a agendar tu cita en Medicina General, Pediatría, Cardiología o Dermatología. Indícame qué especialidad o doctor necesitas y para qué fecha.',
        derivadoACanalAtencion: false,
        entidades: {},
      };
    }

    const confianza = this.calcularConfianza(intencion, aciertos, entidades);

    return {
      intencion,
      confianza,
      respuesta: '',
      derivadoACanalAtencion: false,
      entidades,
    };
  }

  private static clasificar(normalizado: string): { intencion: IntencionAsistente; aciertos: number } {
    let mejor: IntencionAsistente = 'no_reconocida';
    let mejorAciertos = 0;

    // Prioridad a intenciones específicas
    const ordenRevision: (Exclude<IntencionAsistente, 'no_reconocida'>)[] = [
      'cancelar',
      'reprogramar',
      'consultar',
      'confirmacion',
      'reservar',
      'saludo',
    ];

    for (const intencion of ordenRevision) {
      const patrones = PATRONES[intencion];
      const aciertos = patrones.filter((p) => normalizado.includes(p)).length;
      if (aciertos > mejorAciertos) {
        mejorAciertos = aciertos;
        mejor = intencion;
      }
    }

    return { intencion: mejor, aciertos: mejorAciertos };
  }

  private static calcularConfianza(
    intencion: IntencionAsistente,
    aciertos: number,
    entidades: Record<string, string>
  ): number {
    if (intencion === 'reservar') {
      let base = 0.82;
      if (entidades.especialidad) base += 0.1;
      if (entidades.profesional) base += 0.1;
      if (entidades.fecha) base += 0.1;
      if (entidades.turno || entidades.hora) base += 0.05;
      return Math.min(0.99, Math.max(0.8, base));
    }

    if (intencion === 'saludo' || intencion === 'confirmacion') {
      return 0.98;
    }

    let valor = 0.7 + (aciertos - 1) * 0.1;
    if (entidades.especialidad) valor += 0.15;
    if (entidades.fecha) valor += 0.1;
    return Math.min(0.99, Math.max(0.65, valor));
  }

  private static extraerEntidades(
    normalizado: string,
    original: string,
    ahora: Date
  ): Record<string, string> {
    const entidades: Record<string, string> = {};
    const especialidades = this.obtenerEspecialidadesActuales();
    const profesionales = this.obtenerProfesionalesActuales();

    // 1. Profesional (médico) - Buscar primero para poder inferir también la especialidad
    for (const prof of profesionales) {
      const nombresNorm = FechasNaturales.normalizar(prof.nombres);
      const apellidosNorm = FechasNaturales.normalizar(prof.apellidos);
      const nombreCompletoNorm = `${nombresNorm} ${apellidosNorm}`;

      const primerNombre = nombresNorm.split(' ')[0];
      const primerApellido = apellidosNorm.split(' ')[0];
      const segundoApellido = apellidosNorm.split(' ')[1];

      const coincideNombreCompleto = normalizado.includes(nombreCompletoNorm);
      const coincideNombres = normalizado.includes(nombresNorm);
      const coincidePrimerNombre =
        primerNombre.length >= 4 &&
        (normalizado.includes(`dr ${primerNombre}`) ||
          normalizado.includes(`dra ${primerNombre}`) ||
          normalizado.includes(`doctor ${primerNombre}`) ||
          normalizado.includes(`doctora ${primerNombre}`) ||
          normalizado.includes(primerNombre));

      const coincidePrimerApellido =
        primerApellido.length >= 4 &&
        (normalizado.includes(primerApellido) ||
          normalizado.includes(`dr ${primerApellido}`) ||
          normalizado.includes(`doctor ${primerApellido}`));

      const coincideSegundoApellido =
        segundoApellido &&
        segundoApellido.length >= 4 &&
        normalizado.includes(segundoApellido);

      if (
        coincideNombreCompleto ||
        coincideNombres ||
        coincidePrimerNombre ||
        coincidePrimerApellido ||
        coincideSegundoApellido
      ) {
        entidades.profesional = prof.id;
        if (!entidades.especialidad && prof.especialidadId) {
          entidades.especialidad = prof.especialidadId;
        }
        break;
      }
    }

    // 2. Especialidad
    if (!entidades.especialidad) {
      for (const esp of especialidades) {
        if (!esp.activa) continue;
        const nombreNorm = FechasNaturales.normalizar(esp.nombre);

        // Coincidencia directa con el nombre de la especialidad
        if (normalizado.includes(nombreNorm)) {
          entidades.especialidad = esp.id;
          break;
        }

        // Coincidencia por sinónimos comunes
        const sinonimos = SINONIMOS_ESPECIALIDADES[esp.id] || [];
        const coincideSinonimo = sinonimos.some((s) => normalizado.includes(s));
        if (coincideSinonimo) {
          entidades.especialidad = esp.id;
          break;
        }

        // Coincidencia por raíz léxica (ej: "pediatr" cubre "pediatría", "pediatra", "pediátrico")
        const palabras = nombreNorm.split(' ');
        for (const p of palabras) {
          if (p.length >= 5) {
            const raiz = p.substring(0, Math.min(p.length - 2, 7));
            if (normalizado.includes(raiz)) {
              entidades.especialidad = esp.id;
              break;
            }
          }
        }
        if (entidades.especialidad) break;
      }
    }

    // 3. Fecha y Turno
    const fechaResuelta = FechasNaturales.interpretar(original, ahora);
    if (fechaResuelta) {
      entidades.fecha = fechaResuelta.fecha.toISOString();
      entidades.fecha_expresion = fechaResuelta.expresionOriginal;
      if (fechaResuelta.turno) entidades.turno = fechaResuelta.turno;
      if (fechaResuelta.horaMinutos !== undefined) {
        const h = Math.floor(fechaResuelta.horaMinutos / 60);
        const m = fechaResuelta.horaMinutos % 60;
        entidades.hora = `${h}:${String(m).padStart(2, '0')}`;
      }
    } else {
      const turno = FechasNaturales.detectarTurno(normalizado);
      if (turno) entidades.turno = turno;
    }

    return entidades;
  }
}
