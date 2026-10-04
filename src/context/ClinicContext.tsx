import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  CanalReserva,
  Cita,
  Consultorio,
  CupoDisponible,
  Especialidad,
  EstadoCita,
  IndicadoresData,
  PeriodoIndicadores,
  Profesional,
  Sede,
} from '../types';
import { CONSULTORIOS, ESPECIALIDADES, generarCupos, PROFESIONALES, SEDES } from '../constants/fixtures';
import { StorageService } from '../services/storageService';
import { ConfigService, OpcionesSistema } from '../services/configService';
import { IndicadoresCalculator } from '../domain/rules/indicadores';
import { Rn08Inasistencia } from '../domain/rules/rn06_rn07_rn08Gestion';

const STORAGE_KEYS = {
  ESPECIALIDADES: 'citas_medicas_especialidades_v1',
  PROFESIONALES: 'citas_medicas_profesionales_v1',
};

interface ClinicContextType {
  citas: Cita[];
  especialidades: Especialidad[];
  todasEspecialidades: Especialidad[];
  profesionales: Profesional[];
  sedes: Sede[];
  consultorios: Consultorio[];
  ultimaSincronizacion: Date | null;
  sinConexion: boolean;
  citaConfirmadaReciente: Cita | null;
  opcionesSistema: OpcionesSistema;
  setCitaConfirmadaReciente: (cita: Cita | null) => void;
  recargarCitas: () => void;
  obtenerCuposDisponibles: (especialidadId: string, profesionalId?: string, fecha?: Date) => CupoDisponible[];
  confirmarReserva: (
    pacienteId: string,
    cupo: CupoDisponible,
    canal: CanalReserva,
    claveIdempotencia: string
  ) => Promise<{ ok: boolean; cita?: Cita; error?: string }>;
  crearCitaAdministrativa: (citaData: Partial<Cita>) => Promise<{ ok: boolean; cita?: Cita; error?: string }>;
  cancelarCita: (citaId: string, esAdmin?: boolean) => Promise<{ ok: boolean; error?: string }>;
  reprogramarCita: (citaId: string, nuevoCupo: CupoDisponible, esAdmin?: boolean) => Promise<{ ok: boolean; cita?: Cita; error?: string }>;
  actualizarEstadoCita: (citaId: string, nuevoEstado: EstadoCita) => Promise<{ ok: boolean }>;
  eliminarCita: (citaId: string) => Promise<{ ok: boolean }>;
  toggleEspecialidadActiva: (especialidadId: string) => void;
  agregarEspecialidad: (nueva: Especialidad) => void;
  actualizarEspecialidad: (esp: Especialidad) => void;
  eliminarEspecialidad: (id: string) => void;
  agregarProfesional: (nuevo: Profesional) => void;
  actualizarProfesional: (prof: Profesional) => void;
  eliminarProfesional: (id: string) => void;
  activarTodasLasOpcionesYEspecialidades: () => void;
  actualizarOpcionSistema: <K extends keyof OpcionesSistema>(clave: K, valor: OpcionesSistema[K]) => void;
  especialidadDe: (id?: string) => Especialidad | undefined;
  profesionalDe: (id?: string) => Profesional | undefined;
  sedeDe: (id?: string) => Sede | undefined;
  consultorioDe: (id?: string) => Consultorio | undefined;
  calcularIndicadores: (periodo: PeriodoIndicadores) => IndicadoresData;
}

const ClinicContext = createContext<ClinicContextType | undefined>(undefined);

export const ClinicProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [citas, setCitas] = useState<Cita[]>([]);
  const [ultimaSincronizacion, setUltimaSincronizacion] = useState<Date | null>(null);
  const [sinConexion, setSinConexion] = useState(!navigator.onLine);
  const [citaConfirmadaReciente, setCitaConfirmadaReciente] = useState<Cita | null>(null);
  const [opcionesSistema, setOpcionesSistema] = useState<OpcionesSistema>(() => ConfigService.obtenerOpciones());

  useEffect(() => {
    const handleConfigUpdate = () => {
      setOpcionesSistema(ConfigService.obtenerOpciones());
    };
    window.addEventListener('citas_medicas_config_updated', handleConfigUpdate);
    return () => window.removeEventListener('citas_medicas_config_updated', handleConfigUpdate);
  }, []);

  const actualizarOpcionSistema = <K extends keyof OpcionesSistema>(clave: K, valor: OpcionesSistema[K]) => {
    ConfigService.actualizarOpcion(clave, valor);
    setOpcionesSistema(ConfigService.obtenerOpciones());
  };

  // Especialidades con persistencia para control total de administradores
  const [todasEspecialidades, setTodasEspecialidades] = useState<Especialidad[]>(() => {
    const guardadas = localStorage.getItem(STORAGE_KEYS.ESPECIALIDADES);
    if (guardadas) {
      try {
        return JSON.parse(guardadas);
      } catch (_) {}
    }
    return ESPECIALIDADES;
  });

  // Profesionales con persistencia
  const [profesionales, setProfesionales] = useState<Profesional[]>(() => {
    const guardados = localStorage.getItem(STORAGE_KEYS.PROFESIONALES);
    if (guardados) {
      try {
        return JSON.parse(guardados);
      } catch (_) {}
    }
    return PROFESIONALES;
  });

  const guardarEspecialidades = (lista: Especialidad[]) => {
    setTodasEspecialidades(lista);
    localStorage.setItem(STORAGE_KEYS.ESPECIALIDADES, JSON.stringify(lista));
  };

  const guardarProfesionales = (lista: Profesional[]) => {
    setProfesionales(lista);
    localStorage.setItem(STORAGE_KEYS.PROFESIONALES, JSON.stringify(lista));
  };

  const toggleEspecialidadActiva = (id: string) => {
    const actualizadas = todasEspecialidades.map((e) =>
      e.id === id ? { ...e, activa: !e.activa } : e
    );
    guardarEspecialidades(actualizadas);
  };

  const agregarEspecialidad = (nueva: Especialidad) => {
    const actualizadas = [...todasEspecialidades, nueva];
    guardarEspecialidades(actualizadas);
  };

  const actualizarEspecialidad = (esp: Especialidad) => {
    const actualizadas = todasEspecialidades.map((e) => (e.id === esp.id ? esp : e));
    guardarEspecialidades(actualizadas);
  };

  const eliminarEspecialidad = (id: string) => {
    const actualizadas = todasEspecialidades.filter((e) => e.id !== id);
    guardarEspecialidades(actualizadas);
  };

  const agregarProfesional = (nuevo: Profesional) => {
    const actualizados = [...profesionales, nuevo];
    guardarProfesionales(actualizados);
  };

  const actualizarProfesional = (prof: Profesional) => {
    const actualizados = profesionales.map((p) => (p.id === prof.id ? prof : p));
    guardarProfesionales(actualizados);
  };

  const eliminarProfesional = (id: string) => {
    const actualizados = profesionales.filter((p) => p.id !== id);
    guardarProfesionales(actualizados);
  };

  const activarTodasLasOpcionesYEspecialidades = () => {
    // Activa todas las especialidades disponibles
    const todasActivas = todasEspecialidades.map((e) => ({ ...e, activa: true }));
    guardarEspecialidades(todasActivas);
    // Activa todas las opciones del sistema
    const configActiva = ConfigService.activarTodas();
    setOpcionesSistema(configActiva);
  };

  const cargarCitasDeAlmacen = () => {
    let almacenadas = StorageService.obtenerCitas();
    const ahora = new Date();

    // Aplicar RN-08 a citas que ya pasaron
    let huboCambio = false;
    almacenadas = almacenadas.map((c) => {
      if (Rn08Inasistencia.debeMarcarse(c, ahora)) {
        huboCambio = true;
        return { ...c, estado: 'inasistencia' };
      }
      return c;
    });

    if (huboCambio) {
      almacenadas.forEach((c) => StorageService.guardarCita(c));
    }

    setCitas(almacenadas);
    setUltimaSincronizacion(StorageService.obtenerUltimaSincronizacion() || new Date());
  };

  useEffect(() => {
    cargarCitasDeAlmacen();

    const handleOnline = () => setSinConexion(false);
    const handleOffline = () => setSinConexion(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const obtenerCuposDisponibles = (
    especialidadId: string,
    profesionalId?: string,
    fecha?: Date
  ): CupoDisponible[] => {
    const ahora = new Date();
    const todosCupos = generarCupos(ahora);

    // Obtener IDs de cupos ocupados en citas activas
    const cuposOcupados = new Set(
      citas
        .filter((c) => c.estado === 'confirmada' || c.estado === 'reprogramada')
        .map((c) => c.cupoId)
    );

    const profesionalesDeEspecialidad = new Set(
      profesionales.filter((p) => p.especialidadId === especialidadId).map((p) => p.id)
    );

    const ahoraMs = ahora.getTime();

    return todosCupos
      .filter((c) => {
        // 1. Debe pertenecer a un profesional de la especialidad
        if (!profesionalesDeEspecialidad.has(c.profesionalId)) {
          return false;
        }
        // 2. Si se especificó un profesional particular, debe coincidir
        if (profesionalId && c.profesionalId !== profesionalId) {
          return false;
        }
        // 3. Si se especificó fecha, debe ser estrictamente el mismo día (año, mes, día)
        if (fecha) {
          const cDate = new Date(c.fechaHoraInicio);
          const mismoDia =
            cDate.getFullYear() === fecha.getFullYear() &&
            cDate.getMonth() === fecha.getMonth() &&
            cDate.getDate() === fecha.getDate();
          if (!mismoDia) {
            return false;
          }
        }
        return true;
      })
      .map((c) => {
        const cInicioMs = new Date(c.fechaHoraInicio).getTime();
        const estaEnFuturo = cInicioMs > ahoraMs;
        const noOcupado = !cuposOcupados.has(c.id);

        return {
          ...c,
          disponible: estaEnFuturo && noOcupado,
        };
      });
  };

  const confirmarReserva = async (
    pacienteId: string,
    cupo: CupoDisponible,
    canal: CanalReserva,
    claveIdempotencia: string
  ): Promise<{ ok: boolean; cita?: Cita; error?: string }> => {
    const existentePorClave = citas.find((c) => c.claveIdempotencia === claveIdempotencia);
    if (existentePorClave) {
      setCitaConfirmadaReciente(existentePorClave);
      return { ok: true, cita: existentePorClave };
    }

    const ocupado = citas.some(
      (c) => c.cupoId === cupo.id && (c.estado === 'confirmada' || c.estado === 'reprogramada')
    );
    if (ocupado) {
      return { ok: false, error: 'Ese horario acaba de ocuparse. Elige otro, por favor.' };
    }

    const profesional = profesionales.find((p) => p.id === cupo.profesionalId);
    const ahora = new Date();
    const id = `cita-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`;

    const nuevaCita: Cita = {
      id,
      pacienteId,
      cupoId: cupo.id,
      estado: 'confirmada',
      fechaCreacion: ahora.toISOString(),
      canalReserva: canal,
      claveIdempotencia,
      especialidadId: profesional ? profesional.especialidadId : '',
      profesionalId: cupo.profesionalId,
      sedeId: cupo.sedeId,
      consultorioId: cupo.consultorioId,
      fechaHoraInicio: cupo.fechaHoraInicio,
    };

    StorageService.guardarCita(nuevaCita);
    cargarCitasDeAlmacen();
    setCitaConfirmadaReciente(nuevaCita);
    return { ok: true, cita: nuevaCita };
  };

  const crearCitaAdministrativa = async (
    citaData: Partial<Cita>
  ): Promise<{ ok: boolean; cita?: Cita; error?: string }> => {
    if (!citaData.pacienteId || !citaData.profesionalId || !citaData.fechaHoraInicio) {
      return { ok: false, error: 'Faltan datos obligatorios para crear la cita.' };
    }

    const profesional = profesionales.find((p) => p.id === citaData.profesionalId);
    const ahora = new Date();
    const id = `cita-adm-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`;
    const cupoId = citaData.cupoId || `cupo-custom-${Date.now()}`;

    const nuevaCita: Cita = {
      id,
      pacienteId: citaData.pacienteId,
      cupoId,
      estado: citaData.estado || 'confirmada',
      fechaCreacion: ahora.toISOString(),
      canalReserva: citaData.canalReserva || 'presencial',
      especialidadId: citaData.especialidadId || (profesional ? profesional.especialidadId : 'esp-demo-01'),
      profesionalId: citaData.profesionalId,
      sedeId: citaData.sedeId || 'sede-demo-01',
      consultorioId: citaData.consultorioId || 'cons-demo-01',
      fechaHoraInicio: citaData.fechaHoraInicio,
      fechaAtencion: citaData.estado === 'atendida' ? ahora.toISOString() : null,
    };

    StorageService.guardarCita(nuevaCita);
    cargarCitasDeAlmacen();
    return { ok: true, cita: nuevaCita };
  };

  const cancelarCita = async (citaId: string, _esAdmin?: boolean): Promise<{ ok: boolean; error?: string }> => {
    const cita = citas.find((c) => c.id === citaId);
    if (!cita) return { ok: false, error: 'No se encontró la cita.' };

    const actualizada: Cita = {
      ...cita,
      estado: 'cancelada',
    };

    StorageService.guardarCita(actualizada);
    cargarCitasDeAlmacen();
    return { ok: true };
  };

  const reprogramarCita = async (
    citaId: string,
    nuevoCupo: CupoDisponible,
    _esAdmin?: boolean
  ): Promise<{ ok: boolean; cita?: Cita; error?: string }> => {
    const cita = citas.find((c) => c.id === citaId);
    if (!cita) return { ok: false, error: 'No se encontró la cita.' };

    const ocupado = citas.some(
      (c) => c.id !== citaId && c.cupoId === nuevoCupo.id && (c.estado === 'confirmada' || c.estado === 'reprogramada')
    );
    if (ocupado) {
      return { ok: false, error: 'Ese horario ya está reservado por otra cita.' };
    }

    const profesional = profesionales.find((p) => p.id === nuevoCupo.profesionalId);

    const actualizada: Cita = {
      ...cita,
      cupoId: nuevoCupo.id,
      estado: 'reprogramada',
      profesionalId: nuevoCupo.profesionalId,
      sedeId: nuevoCupo.sedeId,
      consultorioId: nuevoCupo.consultorioId,
      fechaHoraInicio: nuevoCupo.fechaHoraInicio,
      especialidadId: profesional ? profesional.especialidadId : cita.especialidadId,
    };

    StorageService.guardarCita(actualizada);
    cargarCitasDeAlmacen();
    setCitaConfirmadaReciente(actualizada);
    return { ok: true, cita: actualizada };
  };

  // Acciones de control total de administrador
  const actualizarEstadoCita = async (citaId: string, nuevoEstado: EstadoCita): Promise<{ ok: boolean }> => {
    const cita = citas.find((c) => c.id === citaId);
    if (!cita) return { ok: false };

    const actualizada: Cita = {
      ...cita,
      estado: nuevoEstado,
      fechaAtencion: nuevoEstado === 'atendida' ? new Date().toISOString() : cita.fechaAtencion,
    };

    StorageService.guardarCita(actualizada);
    cargarCitasDeAlmacen();
    return { ok: true };
  };

  const eliminarCita = async (citaId: string): Promise<{ ok: boolean }> => {
    const filtradas = citas.filter((c) => c.id !== citaId);
    setCitas(filtradas);
    localStorage.setItem('citas_medicas_citas_v1', JSON.stringify(filtradas));
    return { ok: true };
  };

  const especialidadDe = (id?: string) => (id ? todasEspecialidades.find((e) => e.id === id) : undefined);
  const profesionalDe = (id?: string) => (id ? profesionales.find((p) => p.id === id) : undefined);
  const sedeDe = (id?: string) => (id ? SEDES.find((s) => s.id === id) : undefined);
  const consultorioDe = (id?: string) => (id ? CONSULTORIOS.find((c) => c.id === id) : undefined);

  const calcularIndicadores = (periodo: PeriodoIndicadores) => {
    return IndicadoresCalculator.calcular(citas, periodo);
  };

  return (
    <ClinicContext.Provider
      value={{
        citas,
        especialidades: todasEspecialidades.filter((e) => e.activa),
        todasEspecialidades,
        profesionales,
        sedes: SEDES,
        consultorios: CONSULTORIOS,
        ultimaSincronizacion,
        sinConexion,
        citaConfirmadaReciente,
        opcionesSistema,
        setCitaConfirmadaReciente,
        recargarCitas: cargarCitasDeAlmacen,
        obtenerCuposDisponibles,
        confirmarReserva,
        crearCitaAdministrativa,
        cancelarCita,
        reprogramarCita,
        actualizarEstadoCita,
        eliminarCita,
        toggleEspecialidadActiva,
        agregarEspecialidad,
        actualizarEspecialidad,
        eliminarEspecialidad,
        agregarProfesional,
        actualizarProfesional,
        eliminarProfesional,
        activarTodasLasOpcionesYEspecialidades,
        actualizarOpcionSistema,
        especialidadDe,
        profesionalDe,
        sedeDe,
        consultorioDe,
        calcularIndicadores,
      }}
    >
      {children}
    </ClinicContext.Provider>
  );
};

export const useClinic = (): ClinicContextType => {
  const context = useContext(ClinicContext);
  if (!context) throw new Error('useClinic must be used within ClinicProvider');
  return context;
};
