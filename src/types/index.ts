export type TipoDocumento = 'DNI' | 'CE' | 'USR';

export type RolUsuario = 'paciente' | 'administrador';

export interface Paciente {
  id: string;
  tipoDocumento: TipoDocumento;
  numeroDocumento: string;
  nombres: string;
  apellidos: string;
  correo: string;
  telefono: string;
  consentimientoOtorgado: boolean;
  fechaConsentimiento?: string | null;
  rol: RolUsuario;
}

export interface Especialidad {
  id: string;
  nombre: string;
  descripcion: string;
  activa: boolean;
}

export interface Profesional {
  id: string;
  nombres: string;
  apellidos: string;
  especialidadId: string;
  colegiatura: string;
}

export interface Sede {
  id: string;
  nombre: string;
  direccion: string;
  latitud: number;
  longitud: number;
  referencia?: string;
}

export interface Consultorio {
  id: string;
  sedeId: string;
  codigo: string;
  piso: number;
}

export interface CupoDisponible {
  id: string;
  profesionalId: string;
  sedeId: string;
  consultorioId: string;
  fechaHoraInicio: string; // ISO string
  duracionMinutos: number;
  disponible: boolean;
}

export type EstadoCita = 'confirmada' | 'reprogramada' | 'cancelada' | 'atendida' | 'inasistencia';

export type CanalReserva = 'conversacional' | 'flujo_guiado' | 'telefonico' | 'presencial';

export interface Cita {
  id: string;
  pacienteId: string;
  cupoId: string;
  estado: EstadoCita;
  fechaCreacion: string; // ISO string
  canalReserva: CanalReserva;
  claveIdempotencia?: string;
  especialidadId: string;
  profesionalId: string;
  sedeId: string;
  consultorioId: string;
  fechaHoraInicio: string; // ISO string
  fechaAtencion?: string | null;
}

export type RolMensaje = 'paciente' | 'asistente';

export type IntencionAsistente =
  | 'reservar'
  | 'consultar'
  | 'reprogramar'
  | 'cancelar'
  | 'saludo'
  | 'confirmacion'
  | 'no_reconocida';

export interface MensajeConversacion {
  id: string;
  rol: RolMensaje;
  texto: string;
  marcaTiempo: string;
  intencionDetectada?: IntencionAsistente;
  confianza?: number;
}

export type TurnoDia = 'manana' | 'tarde';

export type PasoReserva = 'especialidad' | 'profesional' | 'fecha' | 'horario' | 'confirmacion';

export type PeriodoIndicadores = 'ultimos7' | 'ultimos30' | 'todo';

export interface IndicadoresData {
  reservadas: number;
  canceladas: number;
  inasistencias: number;
  atendidas: number;
  autogestionadas: number;
  cerradas: number;
  tasaInasistencia: number | null;
  tasaCancelacion: number | null;
  tasaAutogestion: number | null;
  sinDatos: boolean;
  porCanal: Record<CanalReserva, number>;
}

export type OperacionProtegida =
  | 'reservar'
  | 'reprogramar'
  | 'cancelar'
  | 'consultarHistorial'
  | 'verIndicadores';

export interface ResultadoRegla {
  cumple: boolean;
  infringida: boolean;
  regla: string;
  mensaje?: string;
  campo?: string;
}
