export interface OpcionesSistema {
  asistenteActivo: boolean;
  reservaGuiadaActiva: boolean;
  omitir24hAdmin: boolean;
  mapasActivos: boolean;
  modoDemoActivo: boolean;
  guardarailClinicoActivo: boolean;
  notificacionesActivas: boolean;
  horarioAtencionInicio: string;
  horarioAtencionFin: string;
}

const STORAGE_KEY = 'citas_medicas_config_v1';

export const OPCIONES_POR_DEFECTO: OpcionesSistema = {
  asistenteActivo: true,
  reservaGuiadaActiva: true,
  omitir24hAdmin: true,
  mapasActivos: true,
  modoDemoActivo: true,
  guardarailClinicoActivo: true,
  notificacionesActivas: true,
  horarioAtencionInicio: '08:00',
  horarioAtencionFin: '19:00',
};

export class ConfigService {
  static obtenerOpciones(): OpcionesSistema {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...OPCIONES_POR_DEFECTO };
    try {
      return { ...OPCIONES_POR_DEFECTO, ...JSON.parse(raw) };
    } catch {
      return { ...OPCIONES_POR_DEFECTO };
    }
  }

  static guardarOpciones(opciones: OpcionesSistema): void {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(opciones));
    window.dispatchEvent(new Event('citas_medicas_config_updated'));
  }

  static actualizarOpcion<K extends keyof OpcionesSistema>(clave: K, valor: OpcionesSistema[K]): void {
    const actuales = this.obtenerOpciones();
    actuales[clave] = valor;
    this.guardarOpciones(actuales);
  }

  static activarTodas(): OpcionesSistema {
    const todasActivas: OpcionesSistema = {
      asistenteActivo: true,
      reservaGuiadaActiva: true,
      omitir24hAdmin: true,
      mapasActivos: true,
      modoDemoActivo: true,
      guardarailClinicoActivo: true,
      notificacionesActivas: true,
      horarioAtencionInicio: '08:00',
      horarioAtencionFin: '19:00',
    };
    this.guardarOpciones(todasActivas);
    return todasActivas;
  }
}
