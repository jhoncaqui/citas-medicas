import { Cita, Paciente } from '../types';
import { CUENTAS_DEMO, CuentaInicial } from '../constants/fixtures';
import { Rn02DocumentoIdentidad } from '../domain/rules/rn02DocumentoIdentidad';

const STORAGE_KEYS = {
  CUENTAS: 'citas_medicas_cuentas_v1',
  SEMBRADAS: 'citas_medicas_sembradas_v1',
  CITAS: 'citas_medicas_citas_v1',
  SESION: 'citas_medicas_sesion_v1',
  TEMA: 'citas_medicas_tema_v1',
  SYNC: 'citas_medicas_sync_v1',
};

export interface CuentaGuardada {
  paciente: Paciente;
  sal: string;
  hash: string;
}

export class StorageService {
  private static async sha256(mensaje: string): Promise<string> {
    const encoder = new TextEncoder();
    const data = encoder.encode(mensaje);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
  }

  static async sembrarCuentasIniciales(): Promise<void> {
    const sembradasStr = localStorage.getItem(STORAGE_KEYS.SEMBRADAS);
    const sembradas = new Set<string>(sembradasStr ? JSON.parse(sembradasStr) : []);

    const cuentasStr = localStorage.getItem(STORAGE_KEYS.CUENTAS);
    const cuentas: Record<string, CuentaGuardada> = cuentasStr ? JSON.parse(cuentasStr) : {};

    let huboCambio = false;

    for (const item of CUENTAS_DEMO) {
      const doc = Rn02DocumentoIdentidad.normalizar(item.perfil.numeroDocumento);
      if (sembradas.has(doc)) continue;

      if (!cuentas[doc]) {
        const sal = Math.random().toString(36).substring(2, 10);
        const hash = await this.sha256(`${sal}:${item.clave}`);
        cuentas[doc] = {
          paciente: item.perfil,
          sal,
          hash,
        };
        huboCambio = true;
      }
      sembradas.add(doc);
    }

    if (huboCambio) {
      localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));
      localStorage.setItem(STORAGE_KEYS.SEMBRADAS, JSON.stringify(Array.from(sembradas)));
    }

    // Sembrar algunas citas iniciales para indicadores si está vacío
    this.sembrarCitasInicialesSiVacio();
  }

  private static sembrarCitasInicialesSiVacio(): void {
    const citasStr = localStorage.getItem(STORAGE_KEYS.CITAS);
    if (!citasStr || JSON.parse(citasStr).length === 0) {
      const ahora = new Date();
      const hace5Dias = new Date(ahora.getTime() - 5 * 86400000);
      const hace3Dias = new Date(ahora.getTime() - 3 * 86400000);
      const hace1Dia = new Date(ahora.getTime() - 1 * 86400000);
      const manana = new Date(ahora.getTime() + 1 * 86400000);
      manana.setHours(10, 0, 0, 0);
      const pasadoManana = new Date(ahora.getTime() + 2 * 86400000);
      pasadoManana.setHours(15, 30, 0, 0);

      const citasIniciales: Cita[] = [
        {
          id: 'cita-demo-101',
          pacienteId: 'pac-demo-01',
          cupoId: 'cupo-demo-101',
          estado: 'atendida',
          fechaCreacion: hace5Dias.toISOString(),
          canalReserva: 'conversacional',
          especialidadId: 'esp-demo-01',
          profesionalId: 'prof-demo-01',
          sedeId: 'sede-demo-01',
          consultorioId: 'cons-demo-01',
          fechaHoraInicio: new Date(hace5Dias.getTime() + 2 * 3600000).toISOString(),
          fechaAtencion: new Date(hace5Dias.getTime() + 2 * 3600000).toISOString(),
        },
        {
          id: 'cita-demo-102',
          pacienteId: 'pac-demo-02',
          cupoId: 'cupo-demo-102',
          estado: 'inasistencia',
          fechaCreacion: hace3Dias.toISOString(),
          canalReserva: 'flujo_guiado',
          especialidadId: 'esp-demo-02',
          profesionalId: 'prof-demo-03',
          sedeId: 'sede-demo-02',
          consultorioId: 'cons-demo-03',
          fechaHoraInicio: new Date(hace3Dias.getTime() + 3 * 3600000).toISOString(),
        },
        {
          id: 'cita-demo-103',
          pacienteId: 'pac-demo-01',
          cupoId: 'cupo-demo-103',
          estado: 'cancelada',
          fechaCreacion: hace1Dia.toISOString(),
          canalReserva: 'flujo_guiado',
          especialidadId: 'esp-demo-01',
          profesionalId: 'prof-demo-02',
          sedeId: 'sede-demo-01',
          consultorioId: 'cons-demo-02',
          fechaHoraInicio: new Date(hace1Dia.getTime() + 5 * 3600000).toISOString(),
        },
        {
          id: 'cita-demo-104',
          pacienteId: 'pac-demo-01',
          cupoId: 'cupo-demo-104',
          estado: 'confirmada',
          fechaCreacion: ahora.toISOString(),
          canalReserva: 'conversacional',
          especialidadId: 'esp-demo-01',
          profesionalId: 'prof-demo-01',
          sedeId: 'sede-demo-01',
          consultorioId: 'cons-demo-01',
          fechaHoraInicio: manana.toISOString(),
        },
        {
          id: 'cita-demo-105',
          pacienteId: 'pac-demo-03',
          cupoId: 'cupo-demo-105',
          estado: 'confirmada',
          fechaCreacion: ahora.toISOString(),
          canalReserva: 'telefonico',
          especialidadId: 'esp-demo-03',
          profesionalId: 'prof-demo-04',
          sedeId: 'sede-demo-01',
          consultorioId: 'cons-demo-02',
          fechaHoraInicio: pasadoManana.toISOString(),
        },
      ];

      localStorage.setItem(STORAGE_KEYS.CITAS, JSON.stringify(citasIniciales));
      localStorage.setItem(STORAGE_KEYS.SYNC, new Date().toISOString());
    }
  }

  // Cuentas y Auth
  static async obtenerCuentas(): Promise<Record<string, CuentaGuardada>> {
    await this.sembrarCuentasIniciales();
    const cuentasStr = localStorage.getItem(STORAGE_KEYS.CUENTAS);
    return cuentasStr ? JSON.parse(cuentasStr) : {};
  }

  static async registrarPaciente(paciente: Paciente, clave: string): Promise<Paciente> {
    const cuentas = await this.obtenerCuentas();
    const doc = Rn02DocumentoIdentidad.normalizar(paciente.numeroDocumento);

    if (cuentas[doc]) {
      throw new Error('Ya existe una cuenta registrada con este documento.');
    }

    const sal = Math.random().toString(36).substring(2, 10);
    const hash = await this.sha256(`${sal}:${clave}`);

    cuentas[doc] = {
      paciente,
      sal,
      hash,
    };

    localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));
    this.guardarSesion(paciente);
    return paciente;
  }

  static async iniciarSesion(numeroDocumento: string, clave: string): Promise<Paciente> {
    const cuentas = await this.obtenerCuentas();
    const doc = Rn02DocumentoIdentidad.normalizar(numeroDocumento);
    const cuenta = cuentas[doc];

    if (!cuenta) {
      throw new Error('Credenciales inválidas. Verifica tu documento y contraseña.');
    }

    const hashCalculado = await this.sha256(`${cuenta.sal}:${clave}`);
    if (hashCalculado !== cuenta.hash) {
      throw new Error('Credenciales inválidas. Verifica tu documento y contraseña.');
    }

    this.guardarSesion(cuenta.paciente);
    return cuenta.paciente;
  }

  static guardarSesion(paciente: Paciente): void {
    localStorage.setItem(STORAGE_KEYS.SESION, JSON.stringify(paciente));
  }

  static obtenerSesion(): Paciente | null {
    const sesionStr = localStorage.getItem(STORAGE_KEYS.SESION);
    return sesionStr ? JSON.parse(sesionStr) : null;
  }

  static cerrarSesion(): void {
    localStorage.removeItem(STORAGE_KEYS.SESION);
  }

  static async actualizarConsentimiento(pacienteId: string, otorgado: boolean): Promise<Paciente> {
    const cuentas = await this.obtenerCuentas();
    let pacienteActualizado: Paciente | null = null;

    for (const [doc, c] of Object.entries(cuentas)) {
      if (c.paciente.id === pacienteId) {
        c.paciente.consentimientoOtorgado = otorgado;
        c.paciente.fechaConsentimiento = otorgado ? new Date().toISOString() : null;
        pacienteActualizado = c.paciente;
        cuentas[doc] = c;
        break;
      }
    }

    if (!pacienteActualizado) {
      throw new Error('No se encontró el paciente.');
    }

    localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));
    this.guardarSesion(pacienteActualizado);
    return pacienteActualizado;
  }

  static async eliminarDatosPaciente(pacienteId: string): Promise<void> {
    const cuentas = await this.obtenerCuentas();
    let docAEliminar: string | null = null;

    for (const [doc, c] of Object.entries(cuentas)) {
      if (c.paciente.id === pacienteId) {
        docAEliminar = doc;
        break;
      }
    }

    if (docAEliminar) {
      delete cuentas[docAEliminar];
      localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));
    }

    // Eliminar sesión
    this.cerrarSesion();
  }

  static async actualizarRolUsuario(pacienteId: string, nuevoRol: 'paciente' | 'administrador'): Promise<Paciente> {
    const cuentas = await this.obtenerCuentas();
    let actualizado: Paciente | null = null;

    for (const [doc, c] of Object.entries(cuentas)) {
      if (c.paciente.id === pacienteId) {
        c.paciente.rol = nuevoRol;
        actualizado = c.paciente;
        cuentas[doc] = c;
        break;
      }
    }

    if (!actualizado) {
      throw new Error('No se encontró el usuario.');
    }

    localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));

    // Si el usuario actualizado es el de la sesión actual, actualizar sesión
    const sesion = this.obtenerSesion();
    if (sesion && sesion.id === pacienteId) {
      this.guardarSesion(actualizado);
    }

    return actualizado;
  }

  static async restablecerClaveUsuario(pacienteId: string, nuevaClave: string): Promise<void> {
    const cuentas = await this.obtenerCuentas();
    let encontrado = false;

    for (const [doc, c] of Object.entries(cuentas)) {
      if (c.paciente.id === pacienteId) {
        const sal = Math.random().toString(36).substring(2, 10);
        const hash = await this.sha256(`${sal}:${nuevaClave}`);
        c.sal = sal;
        c.hash = hash;
        cuentas[doc] = c;
        encontrado = true;
        break;
      }
    }

    if (!encontrado) {
      throw new Error('No se encontró el usuario para restablecer la contraseña.');
    }

    localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));
  }

  static async eliminarUsuarioPorAdmin(pacienteId: string): Promise<void> {
    const cuentas = await this.obtenerCuentas();
    let docAEliminar: string | null = null;

    for (const [doc, c] of Object.entries(cuentas)) {
      if (c.paciente.id === pacienteId) {
        docAEliminar = doc;
        break;
      }
    }

    if (docAEliminar) {
      delete cuentas[docAEliminar];
      localStorage.setItem(STORAGE_KEYS.CUENTAS, JSON.stringify(cuentas));
    }
  }

  static async restaurarConsentimiento(pacienteId: string): Promise<Paciente> {
    return this.actualizarConsentimiento(pacienteId, true);
  }

  static restablecerDatosFabrica(): void {
    localStorage.removeItem(STORAGE_KEYS.CUENTAS);
    localStorage.removeItem(STORAGE_KEYS.SEMBRADAS);
    localStorage.removeItem(STORAGE_KEYS.CITAS);
    localStorage.removeItem(STORAGE_KEYS.SYNC);
    localStorage.removeItem('citas_medicas_especialidades_v1');
    localStorage.removeItem('citas_medicas_profesionales_v1');
    localStorage.removeItem('citas_medicas_config_v1');
  }

  // Citas
  static obtenerCitas(): Cita[] {
    const citasStr = localStorage.getItem(STORAGE_KEYS.CITAS);
    return citasStr ? JSON.parse(citasStr) : [];
  }

  static guardarCita(cita: Cita): void {
    const citas = this.obtenerCitas();
    const index = citas.findIndex((c) => c.id === cita.id);
    if (index >= 0) {
      citas[index] = cita;
    } else {
      citas.push(cita);
    }
    localStorage.setItem(STORAGE_KEYS.CITAS, JSON.stringify(citas));
    localStorage.setItem(STORAGE_KEYS.SYNC, new Date().toISOString());
  }

  static obtenerUltimaSincronizacion(): Date | null {
    const s = localStorage.getItem(STORAGE_KEYS.SYNC);
    return s ? new Date(s) : null;
  }

  // Tema
  static obtenerTema(): 'system' | 'light' | 'dark' {
    const t = localStorage.getItem(STORAGE_KEYS.TEMA);
    if (t === 'light' || t === 'dark' || t === 'system') return t;
    return 'system';
  }

  static guardarTema(tema: 'system' | 'light' | 'dark'): void {
    localStorage.setItem(STORAGE_KEYS.TEMA, tema);
  }
}
