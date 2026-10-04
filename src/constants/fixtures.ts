import { Consultorio, CupoDisponible, Especialidad, Paciente, Profesional, Sede } from '../types';

export const ESPECIALIDADES: Especialidad[] = [
  {
    id: 'esp-demo-01',
    nombre: 'Medicina General',
    descripcion: 'Consulta y atención médica general para pacientes de todas las edades.',
    activa: true,
  },
  {
    id: 'esp-demo-02',
    nombre: 'Pediatría',
    descripcion: 'Atención médica especializada para bebés, niños y adolescentes.',
    activa: true,
  },
  {
    id: 'esp-demo-03',
    nombre: 'Cardiología',
    descripcion: 'Diagnóstico y tratamiento de enfermedades del corazón y del sistema circulatorio.',
    activa: true,
  },
  {
    id: 'esp-demo-04',
    nombre: 'Dermatología',
    descripcion: 'Diagnóstico y tratamiento integral de enfermedades de la piel, cabello y uñas.',
    activa: true,
  },
];

export const PROFESIONALES: Profesional[] = [
  {
    id: 'prof-demo-01',
    nombres: 'Carlos Alberto',
    apellidos: 'Ramírez Soto',
    especialidadId: 'esp-demo-01',
    colegiatura: 'CMP-000001',
  },
  {
    id: 'prof-demo-02',
    nombres: 'María Fernanda',
    apellidos: 'Torres Vega',
    especialidadId: 'esp-demo-01',
    colegiatura: 'CMP-000002',
  },
  {
    id: 'prof-demo-03',
    nombres: 'Luis Miguel',
    apellidos: 'Huamán Rojas',
    especialidadId: 'esp-demo-02',
    colegiatura: 'CMP-000003',
  },
  {
    id: 'prof-demo-04',
    nombres: 'Patricia Elena',
    apellidos: 'Salazar Ponce',
    especialidadId: 'esp-demo-03',
    colegiatura: 'CMP-000004',
  },
  {
    id: 'prof-demo-05',
    nombres: 'Andrea Sofía',
    apellidos: 'Vargas Mendoza',
    especialidadId: 'esp-demo-04',
    colegiatura: 'CMP-000005',
  },
];

export const SEDES: Sede[] = [
  {
    id: 'sede-demo-01',
    nombre: 'Sede Defensores del Morro',
    direccion: 'Av. Defensores del Morro 1221, Chorrillos 15064, Lima',
    latitud: -12.181000,
    longitud: -77.008000,
    referencia: 'Sobre la avenida costanera de Chorrillos, cerca del cruce con Prolongación Huaylas.',
  },
  {
    id: 'sede-demo-02',
    nombre: 'Sede Prolongación Huaylas',
    direccion: 'Av. Prol. Huaylas 365, Chorrillos, Lima',
    latitud: -12.178000,
    longitud: -77.000000,
    referencia: 'Sobre la prolongación de la avenida Defensores del Morro, en Chorrillos.',
  },
];

export const CONSULTORIOS: Consultorio[] = [
  {
    id: 'cons-demo-01',
    sedeId: 'sede-demo-01',
    codigo: 'C-101',
    piso: 1,
  },
  {
    id: 'cons-demo-02',
    sedeId: 'sede-demo-01',
    codigo: 'C-204',
    piso: 2,
  },
  {
    id: 'cons-demo-03',
    sedeId: 'sede-demo-02',
    codigo: 'N-301',
    piso: 3,
  },
];

export interface CuentaInicial {
  perfil: Paciente;
  clave: string;
}

const FECHA_CONSENTIMIENTO = '2026-09-01T00:00:00.000Z';

export const CUENTAS_DEMO: CuentaInicial[] = [
  // Administradores
  {
    clave: 'clave1234',
    perfil: {
      id: 'adm-demo-jcaqui',
      tipoDocumento: 'USR',
      numeroDocumento: 'JCAQUI',
      nombres: 'Jhon Daniel',
      apellidos: 'Caqui Calixto',
      correo: 'jcaqui@ejemplo.test',
      telefono: '999888777',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'administrador',
    },
  },
  {
    clave: 'clave1234',
    perfil: {
      id: 'adm-demo-emamani',
      tipoDocumento: 'USR',
      numeroDocumento: 'EMAMANI',
      nombres: 'Elmer Willie',
      apellidos: 'Mamani Quispe',
      correo: 'emamani@ejemplo.test',
      telefono: '999888776',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'administrador',
    },
  },
  {
    clave: 'clave1234',
    perfil: {
      id: 'adm-demo-ksaavedra',
      tipoDocumento: 'USR',
      numeroDocumento: 'KSAAVEDRA',
      nombres: 'Karen Margarita',
      apellidos: 'Saavedra Bautista',
      correo: 'ksaavedra@ejemplo.test',
      telefono: '999888775',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'administrador',
    },
  },

  // Pacientes
  {
    clave: 'clave1234',
    perfil: {
      id: 'pac-demo-01',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000001',
      nombres: 'Paciente Uno',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente1@ejemplo.test',
      telefono: '900000001',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'paciente',
    },
  },
  {
    clave: 'clave1234',
    perfil: {
      id: 'pac-demo-02',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000002',
      nombres: 'Paciente Dos',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente2@ejemplo.test',
      telefono: '900000002',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'paciente',
    },
  },
  {
    clave: 'clave1234',
    perfil: {
      id: 'pac-demo-03',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000003',
      nombres: 'Paciente Tres',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente3@ejemplo.test',
      telefono: '900000003',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'paciente',
    },
  },
  {
    clave: 'clave1234',
    perfil: {
      id: 'pac-demo-04',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000004',
      nombres: 'Paciente Cuatro',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente4@ejemplo.test',
      telefono: '900000004',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'paciente',
    },
  },
  {
    clave: 'clave1234',
    perfil: {
      id: 'pac-demo-05',
      tipoDocumento: 'DNI',
      numeroDocumento: '00000005',
      nombres: 'Paciente Cinco',
      apellidos: 'Ficticio Ejemplo',
      correo: 'paciente5@ejemplo.test',
      telefono: '900000005',
      consentimientoOtorgado: true,
      fechaConsentimiento: FECHA_CONSENTIMIENTO,
      rol: 'paciente',
    },
  },
];

export function generarCupos(desde: Date = new Date(), dias: number = 14, duracionMinutos: number = 30): CupoDisponible[] {
  const cupos: CupoDisponible[] = [];
  const base = new Date(desde.getFullYear(), desde.getMonth(), desde.getDate());

  for (let dia = 0; dia < dias; dia++) {
    const fecha = new Date(base.getTime() + dia * 86400000);

    // La clínica no atiende domingos (0 = Domingo)
    if (fecha.getDay() === 0) continue;

    for (let i = 0; i < PROFESIONALES.length; i++) {
      const profesional = PROFESIONALES[i];
      const consultorio = CONSULTORIOS[i % CONSULTORIOS.length];

      for (const horaInicio of [8, 9, 10, 11, 14, 15, 16, 17]) {
        for (const minuto of [0, duracionMinutos]) {
          if (minuto >= 60) continue;
          const inicio = new Date(
            fecha.getFullYear(),
            fecha.getMonth(),
            fecha.getDate(),
            horaInicio,
            minuto,
            0,
            0
          );

          // RN-04: no se ofrecen cupos anteriores al momento actual
          if (inicio.getTime() <= desde.getTime()) continue;

          cupos.push({
            id: `cupo-${profesional.id}-${inicio.toISOString()}`,
            profesionalId: profesional.id,
            sedeId: consultorio.sedeId,
            consultorioId: consultorio.id,
            fechaHoraInicio: inicio.toISOString(),
            duracionMinutos,
            disponible: true,
          });
        }
      }
    }
  }

  return cupos;
}
