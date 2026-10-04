import React, { useState } from 'react';
import {
  AlertTriangle,
  Calendar,
  Check,
  CheckCircle,
  Clock,
  Download,
  Filter,
  Layers,
  MapPin,
  Pencil,
  Plus,
  Power,
  RefreshCw,
  Search,
  Settings,
  Shield,
  ShieldAlert,
  ShieldCheck,
  Stethoscope,
  Trash2,
  User,
  UserCheck,
  UserPlus,
  Users,
  X,
  XCircle,
  Zap,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { useAuth } from '../context/AuthContext';
import { useClinic } from '../context/ClinicContext';
import { Cita, Especialidad, EstadoCita, Paciente, Profesional } from '../types';
import { FormatoFecha } from '../utils/fechasNaturales';
import { StorageService } from '../services/storageService';
import { OpcionesSistema } from '../services/configService';

interface AdminControlScreenProps {
  onBack: () => void;
  onReprogramarCita: (cita: Cita) => void;
}

type TabAdmin = 'citas' | 'especialidades' | 'profesionales' | 'usuarios' | 'opciones';

export const AdminControlScreen: React.FC<AdminControlScreenProps> = ({ onBack, onReprogramarCita }) => {
  const { paciente } = useAuth();
  const {
    citas,
    todasEspecialidades,
    profesionales,
    sedes,
    consultorios,
    actualizarEstadoCita,
    eliminarCita,
    crearCitaAdministrativa,
    toggleEspecialidadActiva,
    agregarEspecialidad,
    actualizarEspecialidad,
    eliminarEspecialidad,
    agregarProfesional,
    actualizarProfesional,
    eliminarProfesional,
    activarTodasLasOpcionesYEspecialidades,
    opcionesSistema,
    actualizarOpcionSistema,
    especialidadDe,
    profesionalDe,
    sedeDe,
    recargarCitas,
  } = useClinic();

  const [tab, setTab] = useState<TabAdmin>('citas');
  const [filtroEstado, setFiltroEstado] = useState<string>('todas');
  const [filtroEspecialidad, setFiltroEspecialidad] = useState<string>('todas');
  const [busqueda, setBusqueda] = useState<string>('');
  const [mensajeToast, setMensajeToast] = useState<{ tipo: 'ok' | 'err'; texto: string } | null>(null);

  // Modales Cita Administrativa
  const [modalNuevaCita, setModalNuevaCita] = useState(false);
  const [adminCitaPacienteId, setAdminCitaPacienteId] = useState('');
  const [adminCitaEspId, setAdminCitaEspId] = useState('');
  const [adminCitaProfId, setAdminCitaProfId] = useState('');
  const [adminCitaSedeId, setAdminCitaSedeId] = useState(sedes[0]?.id || '');
  const [adminCitaFecha, setAdminCitaFecha] = useState('');
  const [adminCitaHora, setAdminCitaHora] = useState('09:00');
  const [adminCitaEstado, setAdminCitaEstado] = useState<EstadoCita>('confirmada');

  // Modales Especialidad
  const [modalNuevaEsp, setModalNuevaEsp] = useState(false);
  const [nuevaEspNombre, setNuevaEspNombre] = useState('');
  const [nuevaEspDesc, setNuevaEspDesc] = useState('');
  const [espAEditar, setEspAEditar] = useState<Especialidad | null>(null);

  // Modales Profesional
  const [modalNuevoProf, setModalNuevoProf] = useState(false);
  const [nuevoProfNombres, setNuevoProfNombres] = useState('');
  const [nuevoProfApellidos, setNuevoProfApellidos] = useState('');
  const [nuevoProfEspId, setNuevoProfEspId] = useState(todasEspecialidades[0]?.id || '');
  const [nuevoProfColegiatura, setNuevoProfColegiatura] = useState('');
  const [profAEditar, setProfAEditar] = useState<Profesional | null>(null);

  // Modales Usuarios
  const [usuarios, setUsuarios] = useState<Paciente[]>([]);
  const [modalNuevoUsuario, setModalNuevoUsuario] = useState(false);
  const [nuevoUserTipoDoc, setNuevoUserTipoDoc] = useState<'DNI' | 'CE'>('DNI');
  const [nuevoUserNumDoc, setNuevoUserNumDoc] = useState('');
  const [nuevoUserNombres, setNuevoUserNombres] = useState('');
  const [nuevoUserApellidos, setNuevoUserApellidos] = useState('');
  const [nuevoUserCorreo, setNuevoUserCorreo] = useState('');
  const [nuevoUserTelefono, setNuevoUserTelefono] = useState('');
  const [nuevoUserClave, setNuevoUserClave] = useState('');
  const [nuevoUserRol, setNuevoUserRol] = useState<'paciente' | 'administrador'>('paciente');

  const [usuarioClaveARestablecer, setUsuarioClaveARestablecer] = useState<Paciente | null>(null);
  const [nuevaClaveInput, setNuevaClaveInput] = useState('');

  const cargarUsuarios = async () => {
    const cuentasObj = await StorageService.obtenerCuentas();
    const lista = Object.values(cuentasObj).map((c: any) => c.paciente);
    setUsuarios(lista);
    if (!adminCitaPacienteId && lista.length > 0) {
      setAdminCitaPacienteId(lista[0].id);
    }
  };

  React.useEffect(() => {
    cargarUsuarios();
  }, []);

  const showToast = (texto: string, tipo: 'ok' | 'err' = 'ok') => {
    setMensajeToast({ tipo, texto });
    setTimeout(() => setMensajeToast(null), 3500);
  };

  const handleCambiarEstado = async (citaId: string, nuevoEstado: EstadoCita) => {
    const res = await actualizarEstadoCita(citaId, nuevoEstado);
    if (res.ok) {
      showToast(`Estado de cita actualizado a: ${nuevoEstado.toUpperCase()}`);
    }
  };

  const handleEliminarCita = async (citaId: string) => {
    if (confirm('¿Estás seguro de eliminar permanentemente esta cita del sistema?')) {
      const res = await eliminarCita(citaId);
      if (res.ok) {
        showToast('Cita eliminada permanentemente del sistema.');
      }
    }
  };

  // Crear Cita Administrativa Directa
  const handleCrearCitaAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminCitaPacienteId || !adminCitaProfId || !adminCitaFecha || !adminCitaHora) {
      showToast('Por favor completa los campos requeridos.', 'err');
      return;
    }

    const fechaHora = `${adminCitaFecha}T${adminCitaHora}:00.000Z`;

    const res = await crearCitaAdministrativa({
      pacienteId: adminCitaPacienteId,
      especialidadId: adminCitaEspId || undefined,
      profesionalId: adminCitaProfId,
      sedeId: adminCitaSedeId,
      fechaHoraInicio: fechaHora,
      estado: adminCitaEstado,
      canalReserva: 'presencial',
    });

    if (res.ok) {
      setModalNuevaCita(false);
      showToast('Cita creada exitosamente por el administrador.');
    } else {
      showToast(res.error || 'Error al crear la cita.', 'err');
    }
  };

  // Exportar Citas a CSV
  const handleExportarCitas = () => {
    if (citas.length === 0) {
      showToast('No hay citas registradas para exportar.', 'err');
      return;
    }

    const headers = ['ID Cita', 'Paciente ID', 'Especialidad', 'Médico', 'Sede', 'Fecha Inicio', 'Estado', 'Canal'];
    const rows = citas.map((c) => {
      const esp = especialidadDe(c.especialidadId)?.nombre || 'General';
      const prof = profesionalDe(c.profesionalId);
      const profNom = prof ? `Dr. ${prof.nombres} ${prof.apellidos}` : 'No asignado';
      const sede = sedeDe(c.sedeId)?.nombre || 'Sede Central';
      return [
        c.id,
        c.pacienteId,
        `"${esp}"`,
        `"${profNom}"`,
        `"${sede}"`,
        c.fechaHoraInicio,
        c.estado,
        c.canalReserva,
      ].join(',');
    });

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `reporte_citas_clinica_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast('Reporte de citas descargado en CSV.');
  };

  // Crear o Editar Especialidad
  const handleGuardarEspecialidad = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nuevaEspNombre.trim()) return;

    if (espAEditar) {
      actualizarEspecialidad({
        ...espAEditar,
        nombre: nuevaEspNombre.trim(),
        descripcion: nuevaEspDesc.trim() || 'Consulta médica especializada.',
      });
      showToast(`Especialidad "${nuevaEspNombre}" actualizada.`);
      setEspAEditar(null);
    } else {
      const nueva: Especialidad = {
        id: `esp-custom-${Date.now()}`,
        nombre: nuevaEspNombre.trim(),
        descripcion: nuevaEspDesc.trim() || 'Consulta médica especializada.',
        activa: true,
      };
      agregarEspecialidad(nueva);
      showToast(`Especialidad "${nueva.nombre}" creada y activada.`);
    }

    setNuevaEspNombre('');
    setNuevaEspDesc('');
    setModalNuevaEsp(false);
  };

  const handleEliminarEspecialidad = (id: string, nombre: string) => {
    if (confirm(`¿Eliminar permanentemente la especialidad "${nombre}"?`)) {
      eliminarEspecialidad(id);
      showToast(`Especialidad "${nombre}" eliminada.`);
    }
  };

  // Crear o Editar Profesional
  const handleGuardarProfesional = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nuevoProfNombres.trim() || !nuevoProfApellidos.trim()) return;

    if (profAEditar) {
      actualizarProfesional({
        ...profAEditar,
        nombres: nuevoProfNombres.trim(),
        apellidos: nuevoProfApellidos.trim(),
        especialidadId: nuevoProfEspId,
        colegiatura: nuevoProfColegiatura.trim() || profAEditar.colegiatura,
      });
      showToast(`Datos del Dr(a). ${nuevoProfNombres} actualizados.`);
      setProfAEditar(null);
    } else {
      const nuevo: Profesional = {
        id: `prof-custom-${Date.now()}`,
        nombres: nuevoProfNombres.trim(),
        apellidos: nuevoProfApellidos.trim(),
        especialidadId: nuevoProfEspId,
        colegiatura: nuevoProfColegiatura.trim() || `CMP-${Math.floor(100000 + Math.random() * 900000)}`,
      };
      agregarProfesional(nuevo);
      showToast(`Médico Dr(a). ${nuevo.nombres} ${nuevo.apellidos} registrado.`);
    }

    setNuevoProfNombres('');
    setNuevoProfApellidos('');
    setNuevoProfColegiatura('');
    setModalNuevoProf(false);
  };

  const handleEliminarProfesional = (id: string, nombreCompleto: string) => {
    if (confirm(`¿Eliminar permanentemente al médico Dr(a). ${nombreCompleto}?`)) {
      eliminarProfesional(id);
      showToast(`Médico Dr(a). ${nombreCompleto} eliminado.`);
    }
  };

  // Control de Usuarios
  const handleToggleRolUsuario = async (u: Paciente) => {
    const nuevoRol = u.rol === 'administrador' ? 'paciente' : 'administrador';
    try {
      await StorageService.actualizarRolUsuario(u.id, nuevoRol);
      await cargarUsuarios();
      showToast(`Rol de ${u.nombres} actualizado a ${nuevoRol.toUpperCase()}`);
    } catch (err: any) {
      showToast(err.message || 'Error al cambiar rol', 'err');
    }
  };

  const handleRestablecerClave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!usuarioClaveARestablecer || !nuevaClaveInput.trim()) return;
    if (nuevaClaveInput.length < 8) {
      showToast('La nueva contraseña debe tener al menos 8 caracteres.', 'err');
      return;
    }

    try {
      await StorageService.restablecerClaveUsuario(usuarioClaveARestablecer.id, nuevaClaveInput.trim());
      showToast(`Contraseña de ${usuarioClaveARestablecer.nombres} restablecida.`);
      setUsuarioClaveARestablecer(null);
      setNuevaClaveInput('');
    } catch (err: any) {
      showToast(err.message || 'Error al restablecer contraseña', 'err');
    }
  };

  const handleRestaurarConsentimiento = async (u: Paciente) => {
    try {
      await StorageService.restaurarConsentimiento(u.id);
      await cargarUsuarios();
      showToast(`Consentimiento de ${u.nombres} reactivado exitosamente.`);
    } catch (err: any) {
      showToast(err.message || 'Error al restaurar consentimiento', 'err');
    }
  };

  const handleEliminarUsuario = async (u: Paciente) => {
    if (u.id === paciente?.id) {
      showToast('No puedes eliminar tu propia cuenta en sesión.', 'err');
      return;
    }
    if (confirm(`¿Eliminar permanentemente la cuenta de ${u.nombres} ${u.apellidos}?`)) {
      await StorageService.eliminarUsuarioPorAdmin(u.id);
      await cargarUsuarios();
      showToast(`Usuario ${u.nombres} eliminado del sistema.`);
    }
  };

  const handleCrearUsuarioAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nuevoUserNumDoc || !nuevoUserNombres || !nuevoUserApellidos || !nuevoUserCorreo || !nuevoUserClave) {
      showToast('Por favor completa todos los campos del usuario.', 'err');
      return;
    }

    const nuevo: Paciente = {
      id: `pac-${Date.now()}`,
      tipoDocumento: nuevoUserTipoDoc,
      numeroDocumento: nuevoUserNumDoc.trim(),
      nombres: nuevoUserNombres.trim(),
      apellidos: nuevoUserApellidos.trim(),
      correo: nuevoUserCorreo.trim(),
      telefono: nuevoUserTelefono.trim() || '999999999',
      consentimientoOtorgado: true,
      fechaConsentimiento: new Date().toISOString(),
      rol: nuevoUserRol,
    };

    try {
      await StorageService.registrarPaciente(nuevo, nuevoUserClave);
      await cargarUsuarios();
      setModalNuevoUsuario(false);
      setNuevoUserNumDoc('');
      setNuevoUserNombres('');
      setNuevoUserApellidos('');
      setNuevoUserCorreo('');
      setNuevoUserTelefono('');
      setNuevoUserClave('');
      showToast(`Usuario ${nuevo.nombres} creado con rol ${nuevo.rol.toUpperCase()}.`);
    } catch (err: any) {
      showToast(err.message || 'Error al registrar usuario', 'err');
    }
  };

  // Filtrado de citas
  const citasFiltradas = citas.filter((c) => {
    if (filtroEstado !== 'todas' && c.estado !== filtroEstado) return false;
    if (filtroEspecialidad !== 'todas' && c.especialidadId !== filtroEspecialidad) return false;

    if (busqueda.trim()) {
      const q = busqueda.toLowerCase().trim();
      const prof = profesionalDe(c.profesionalId);
      const esp = especialidadDe(c.especialidadId);
      const coincide =
        c.id.toLowerCase().includes(q) ||
        c.pacienteId.toLowerCase().includes(q) ||
        (prof && `${prof.nombres} ${prof.apellidos}`.toLowerCase().includes(q)) ||
        (esp && esp.nombre.toLowerCase().includes(q));
      if (!coincide) return false;
    }

    return true;
  });

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
      <Navbar titulo="Panel de Control Total (Admin)" onBack={onBack} />

      <main className="max-w-5xl mx-auto px-4 py-6 space-y-6">
        {/* Toast Notificación */}
        {mensajeToast && (
          <div
            className={`p-3.5 rounded-2xl border text-xs font-semibold shadow-sm animate-in fade-in flex items-center justify-between ${
              mensajeToast.tipo === 'ok'
                ? 'bg-emerald-50 dark:bg-emerald-950/60 border-emerald-300 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200'
                : 'bg-red-50 dark:bg-red-950/60 border-red-300 dark:border-red-800 text-red-800 dark:text-red-200'
            }`}
          >
            <span>{mensajeToast.texto}</span>
            <button type="button" onClick={() => setMensajeToast(null)} className="p-1 opacity-70 hover:opacity-100">
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* Banner de Control Total */}
        <div className="p-6 rounded-3xl bg-gradient-to-r from-[#00629E] via-[#004e7e] to-[#003258] text-white shadow-lg flex flex-col md:flex-row md:items-center justify-between gap-5">
          <div>
            <div className="flex items-center gap-2.5">
              <div className="p-2 rounded-xl bg-white/15 backdrop-blur-xs">
                <ShieldCheck className="w-6 h-6 text-amber-300" />
              </div>
              <div>
                <h2 className="font-extrabold text-xl tracking-tight">
                  Control Total de la Clínica
                </h2>
                <p className="text-xs text-blue-100 mt-0.5">
                  Sesión: <span className="font-semibold">{paciente?.nombres} {paciente?.apellidos}</span> (Permisos Globales de Administrador)
                </p>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={() => {
                activarTodasLasOpcionesYEspecialidades();
                showToast('⚡ ¡Todas las opciones del sistema y especialidades han sido activadas con éxito!');
              }}
              className="px-3.5 py-2 rounded-xl bg-amber-400 hover:bg-amber-300 text-amber-950 text-xs font-bold transition-all shadow-sm flex items-center gap-1.5 cursor-pointer"
              title="Activa todas las especialidades y desbloquea todas las opciones del sistema al instante"
            >
              <Zap className="w-4 h-4 fill-amber-950" />
              <span>Activar Todas las Opciones</span>
            </button>

            <button
              type="button"
              onClick={handleExportarCitas}
              className="px-3 py-2 rounded-xl bg-white/20 hover:bg-white/30 text-white text-xs font-semibold backdrop-blur-xs transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Exportar Citas (CSV)</span>
            </button>
          </div>
        </div>

        {/* Pestañas de Navegación de Administración */}
        <div className="flex gap-2 overflow-x-auto pb-1 border-b border-gray-200 dark:border-gray-800">
          <button
            type="button"
            onClick={() => setTab('citas')}
            className={`px-4 py-2.5 rounded-2xl text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer flex items-center gap-2 ${
              tab === 'citas'
                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258]'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <Calendar className="w-4 h-4" />
            <span>Gestión de Citas ({citas.length})</span>
          </button>

          <button
            type="button"
            onClick={() => setTab('especialidades')}
            className={`px-4 py-2.5 rounded-2xl text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer flex items-center gap-2 ${
              tab === 'especialidades'
                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258]'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <Layers className="w-4 h-4" />
            <span>Especialidades ({todasEspecialidades.length})</span>
          </button>

          <button
            type="button"
            onClick={() => setTab('profesionales')}
            className={`px-4 py-2.5 rounded-2xl text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer flex items-center gap-2 ${
              tab === 'profesionales'
                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258]'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <Stethoscope className="w-4 h-4" />
            <span>Médicos ({profesionales.length})</span>
          </button>

          <button
            type="button"
            onClick={() => setTab('usuarios')}
            className={`px-4 py-2.5 rounded-2xl text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer flex items-center gap-2 ${
              tab === 'usuarios'
                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258]'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <Users className="w-4 h-4" />
            <span>Usuarios y Roles ({usuarios.length})</span>
          </button>

          <button
            type="button"
            onClick={() => setTab('opciones')}
            className={`px-4 py-2.5 rounded-2xl text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer flex items-center gap-2 ${
              tab === 'opciones'
                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258]'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <Settings className="w-4 h-4" />
            <span>Opciones del Sistema</span>
          </button>
        </div>

        {/* TAB 1: GESTIÓN DE CITAS */}
        {tab === 'citas' && (
          <div className="space-y-4">
            {/* Barra de Búsqueda, Filtros y Botón de Nueva Cita */}
            <div className="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
              <div className="flex-1 relative">
                <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={busqueda}
                  onChange={(e) => setBusqueda(e.target.value)}
                  placeholder="Buscar por código, paciente, médico o especialidad..."
                  className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#00629E]"
                />
              </div>

              <div className="flex flex-wrap gap-2">
                <select
                  value={filtroEstado}
                  onChange={(e) => setFiltroEstado(e.target.value)}
                  className="px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs text-gray-800 dark:text-gray-200 font-medium cursor-pointer"
                >
                  <option value="todas">Todos los estados ({citas.length})</option>
                  <option value="confirmada">Confirmadas</option>
                  <option value="reprogramada">Reprogramadas</option>
                  <option value="atendida">Atendidas</option>
                  <option value="inasistencia">Inasistencias</option>
                  <option value="cancelada">Canceladas</option>
                </select>

                <select
                  value={filtroEspecialidad}
                  onChange={(e) => setFiltroEspecialidad(e.target.value)}
                  className="px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs text-gray-800 dark:text-gray-200 font-medium cursor-pointer"
                >
                  <option value="todas">Todas las especialidades</option>
                  {todasEspecialidades.map((esp) => (
                    <option key={esp.id} value={esp.id}>
                      {esp.nombre}
                    </option>
                  ))}
                </select>

                <button
                  type="button"
                  onClick={() => {
                    if (profesionales.length > 0) setAdminCitaProfId(profesionales[0].id);
                    if (todasEspecialidades.length > 0) setAdminCitaEspId(todasEspecialidades[0].id);
                    setModalNuevaCita(true);
                  }}
                  className="px-3 py-2 rounded-xl bg-[#00629E] hover:bg-[#004e7e] text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer whitespace-nowrap shadow-xs"
                >
                  <Plus className="w-4 h-4" />
                  <span>Nueva Cita Directa</span>
                </button>
              </div>
            </div>

            {/* Listado de citas */}
            {citasFiltradas.length === 0 ? (
              <div className="p-10 text-center bg-white dark:bg-[#1E2124] rounded-2xl border border-gray-200 dark:border-gray-800 text-xs text-gray-500">
                No se encontraron citas con los filtros o búsqueda aplicados.
              </div>
            ) : (
              <div className="space-y-3">
                {citasFiltradas.map((cita) => {
                  const esp = especialidadDe(cita.especialidadId);
                  const prof = profesionalDe(cita.profesionalId);
                  const sede = sedeDe(cita.sedeId);

                  return (
                    <div
                      key={cita.id}
                      className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs space-y-3"
                    >
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs font-bold text-[#00629E] dark:text-[#9CCAFF]">
                            {cita.id}
                          </span>
                          <span className="text-xs text-gray-400">·</span>
                          <span className="font-semibold text-xs text-gray-900 dark:text-white">
                            {esp?.nombre || 'Especialidad'}
                          </span>
                        </div>

                        <div className="flex items-center gap-2">
                          <span className="text-[10px] text-gray-400 capitalize">
                            Canal: {cita.canalReserva.replace('_', ' ')}
                          </span>
                          <span
                            className={`text-[10px] font-bold px-2 py-0.5 rounded-full border capitalize ${
                              cita.estado === 'confirmada' || cita.estado === 'reprogramada'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-300 dark:bg-emerald-950/40 dark:text-emerald-400'
                                : cita.estado === 'atendida'
                                ? 'bg-blue-50 text-blue-700 border-blue-300 dark:bg-blue-950/40 dark:text-blue-400'
                                : 'bg-red-50 text-red-700 border-red-300 dark:bg-red-950/40 dark:text-red-400'
                            }`}
                          >
                            {cita.estado}
                          </span>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs text-gray-600 dark:text-gray-300">
                        <div className="flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5 text-[#00629E] dark:text-[#9CCAFF]" />
                          <span>
                            {FormatoFecha.fechaLarga(cita.fechaHoraInicio)} ·{' '}
                            {FormatoFecha.hora(cita.fechaHoraInicio)}
                          </span>
                        </div>

                        <div className="flex items-center gap-1.5 truncate">
                          <User className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                          <span className="truncate">
                            Dr(a). {prof ? `${prof.nombres} ${prof.apellidos}` : 'No asignado'}
                          </span>
                        </div>

                        <div className="flex items-center gap-1.5 truncate">
                          <MapPin className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                          <span className="truncate">{sede?.nombre || 'Sede Central'}</span>
                        </div>
                      </div>

                      {/* Botones de acción rápida de administrador */}
                      <div className="pt-2 border-t border-gray-100 dark:border-gray-800 flex flex-wrap items-center justify-between gap-2">
                        <span className="text-[11px] font-semibold text-gray-500">
                          Control de administrador:
                        </span>

                        <div className="flex flex-wrap gap-1.5">
                          {cita.estado !== 'atendida' && (
                            <button
                              type="button"
                              onClick={() => handleCambiarEstado(cita.id, 'atendida')}
                              className="px-2.5 py-1 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 dark:bg-blue-950/50 dark:text-blue-300 text-[11px] font-semibold cursor-pointer flex items-center gap-1"
                            >
                              <CheckCircle className="w-3 h-3" />
                              <span>Marcar Atendida</span>
                            </button>
                          )}

                          {cita.estado !== 'inasistencia' && (
                            <button
                              type="button"
                              onClick={() => handleCambiarEstado(cita.id, 'inasistencia')}
                              className="px-2.5 py-1 rounded-lg bg-amber-50 hover:bg-amber-100 text-amber-700 dark:bg-amber-950/50 dark:text-amber-300 text-[11px] font-semibold cursor-pointer"
                            >
                              Inasistencia
                            </button>
                          )}

                          {cita.estado !== 'confirmada' && (
                            <button
                              type="button"
                              onClick={() => handleCambiarEstado(cita.id, 'confirmada')}
                              className="px-2.5 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300 text-[11px] font-semibold cursor-pointer"
                            >
                              Confirmar
                            </button>
                          )}

                          <button
                            type="button"
                            onClick={() => onReprogramarCita(cita)}
                            className="px-2.5 py-1 rounded-lg border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 text-[11px] font-semibold cursor-pointer"
                            title="Reprogramar cita (sin restricción de 24h para admin)"
                          >
                            Reprogramar
                          </button>

                          {cita.estado !== 'cancelada' && (
                            <button
                              type="button"
                              onClick={() => handleCambiarEstado(cita.id, 'cancelada')}
                              className="px-2.5 py-1 rounded-lg border border-red-200 dark:border-red-900 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40 text-[11px] font-semibold cursor-pointer"
                            >
                              Cancelar
                            </button>
                          )}

                          <button
                            type="button"
                            onClick={() => handleEliminarCita(cita.id)}
                            className="p-1 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/40 cursor-pointer"
                            title="Eliminar registro permanentemente"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* TAB 2: ESPECIALIDADES MÉDICAS */}
        {tab === 'especialidades' && (
          <div className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                  Catálogo de Especialidades Médicas
                </h3>
                <p className="text-xs text-gray-500">
                  Activa o desactiva opciones de especialidad en tiempo real para pacientes y asistentes.
                </p>
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => {
                    activarTodasLasOpcionesYEspecialidades();
                    showToast('Todas las especialidades han sido activadas.');
                  }}
                  className="px-3 py-1.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer shadow-xs"
                >
                  <Zap className="w-3.5 h-3.5" />
                  <span>Activar Todas</span>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setEspAEditar(null);
                    setNuevaEspNombre('');
                    setNuevaEspDesc('');
                    setModalNuevaEsp(true);
                  }}
                  className="px-3 py-1.5 rounded-xl bg-[#00629E] hover:bg-[#004e7e] text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer shadow-xs"
                >
                  <Plus className="w-4 h-4" />
                  <span>Nueva Especialidad</span>
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-3">
              {todasEspecialidades.map((esp) => (
                <div
                  key={esp.id}
                  className={`p-4 rounded-2xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
                    esp.activa
                      ? 'bg-white dark:bg-[#1E2124] border-gray-200 dark:border-gray-800'
                      : 'bg-gray-50 dark:bg-gray-800/40 border-gray-200 dark:border-gray-700/60 opacity-80'
                  }`}
                >
                  <div className="flex items-start gap-3 flex-1 min-w-0">
                    <div
                      className={`p-2.5 rounded-xl shrink-0 ${
                        esp.activa
                          ? 'bg-blue-50 text-[#00629E] dark:bg-blue-950 dark:text-[#9CCAFF]'
                          : 'bg-gray-100 text-gray-400 dark:bg-gray-800'
                      }`}
                    >
                      <Stethoscope className="w-5 h-5" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <h4 className="font-semibold text-sm text-gray-900 dark:text-white">
                          {esp.nombre}
                        </h4>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            esp.activa
                              ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-400'
                              : 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                          }`}
                        >
                          {esp.activa ? 'Activa y Disponible' : 'Desactivada'}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                        {esp.descripcion}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0 self-end sm:self-center">
                    <button
                      type="button"
                      onClick={() => toggleEspecialidadActiva(esp.id)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                        esp.activa
                          ? 'bg-amber-100 text-amber-800 hover:bg-amber-200 dark:bg-amber-950 dark:text-amber-300'
                          : 'bg-emerald-600 text-white hover:bg-emerald-700'
                      }`}
                    >
                      {esp.activa ? 'Desactivar' : 'Activar Opción'}
                    </button>

                    <button
                      type="button"
                      onClick={() => {
                        setEspAEditar(esp);
                        setNuevaEspNombre(esp.nombre);
                        setNuevaEspDesc(esp.descripcion);
                        setModalNuevaEsp(true);
                      }}
                      className="p-1.5 rounded-xl border border-gray-300 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
                      title="Editar especialidad"
                    >
                      <Pencil className="w-3.5 h-3.5" />
                    </button>

                    <button
                      type="button"
                      onClick={() => handleEliminarEspecialidad(esp.id, esp.nombre)}
                      className="p-1.5 rounded-xl border border-red-200 dark:border-red-900 text-red-600 hover:bg-red-50 dark:hover:bg-red-950/40 cursor-pointer"
                      title="Eliminar especialidad"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 3: PROFESIONALES MÉDICOS */}
        {tab === 'profesionales' && (
          <div className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                  Equipo de Médicos Colegiados
                </h3>
                <p className="text-xs text-gray-500">
                  Control total sobre médicos, asignación de especialidades y colegiaturas.
                </p>
              </div>

              <button
                type="button"
                onClick={() => {
                  setProfAEditar(null);
                  setNuevoProfNombres('');
                  setNuevoProfApellidos('');
                  setNuevoProfColegiatura('');
                  setModalNuevoProf(true);
                }}
                className="px-3 py-1.5 rounded-xl bg-[#00629E] hover:bg-[#004e7e] text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer shadow-xs self-start sm:self-auto"
              >
                <Plus className="w-4 h-4" />
                <span>Nuevo Médico</span>
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {profesionales.map((prof) => {
                const esp = especialidadDe(prof.especialidadId);
                const citasProf = citas.filter((c) => c.profesionalId === prof.id).length;

                return (
                  <div
                    key={prof.id}
                    className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs space-y-3"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-950/60 text-[#00629E] dark:text-[#9CCAFF] font-bold text-xs flex items-center justify-center">
                          {prof.nombres[0]}
                          {prof.apellidos[0]}
                        </div>
                        <div>
                          <h4 className="font-bold text-xs text-gray-900 dark:text-white">
                            Dr(a). {prof.nombres} {prof.apellidos}
                          </h4>
                          <span className="text-[11px] text-gray-400">
                            Colegiatura: {prof.colegiatura}
                          </span>
                        </div>
                      </div>

                      <div className="flex items-center gap-1">
                        <button
                          type="button"
                          onClick={() => {
                            setProfAEditar(prof);
                            setNuevoProfNombres(prof.nombres);
                            setNuevoProfApellidos(prof.apellidos);
                            setNuevoProfEspId(prof.especialidadId);
                            setNuevoProfColegiatura(prof.colegiatura);
                            setModalNuevoProf(true);
                          }}
                          className="p-1 text-gray-400 hover:text-gray-700 dark:hover:text-white"
                          title="Editar médico"
                        >
                          <Pencil className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleEliminarProfesional(prof.id, `${prof.nombres} ${prof.apellidos}`)}
                          className="p-1 text-gray-400 hover:text-red-600"
                          title="Eliminar médico"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-xs">
                      <div>
                        <span className="text-gray-500">Especialidad: </span>
                        <span className="font-semibold text-[#00629E] dark:text-[#9CCAFF]">
                          {esp?.nombre || 'General'}
                        </span>
                      </div>
                      <span className="text-[11px] px-2 py-0.5 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                        {citasProf} citas
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* TAB 4: USUARIOS Y ROLES */}
        {tab === 'usuarios' && (
          <div className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                  Directorio de Cuentas y Control de Acceso
                </h3>
                <p className="text-xs text-gray-500">
                  Cambia roles a Administrador o Paciente, restablece claves y gestiona consentimientos.
                </p>
              </div>

              <button
                type="button"
                onClick={() => setModalNuevoUsuario(true)}
                className="px-3 py-1.5 rounded-xl bg-[#00629E] hover:bg-[#004e7e] text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer shadow-xs self-start sm:self-auto"
              >
                <UserPlus className="w-4 h-4" />
                <span>Registrar Usuario</span>
              </button>
            </div>

            <div className="grid grid-cols-1 gap-3">
              {usuarios.map((u) => {
                const esAdmin = u.rol === 'administrador';
                const tieneConsentimiento = u.consentimientoOtorgado;

                return (
                  <div
                    key={u.id}
                    className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="font-semibold text-xs text-gray-900 dark:text-white">
                          {u.nombres} {u.apellidos}
                        </h4>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            esAdmin
                              ? 'bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300'
                              : 'bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-300'
                          }`}
                        >
                          {u.rol.toUpperCase()}
                        </span>
                        {!tieneConsentimiento && (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300">
                            Consentimiento Revocado
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-gray-500 mt-0.5">
                        Doc: {u.numeroDocumento} ({u.tipoDocumento}) · Correo: {u.correo} · Tel: {u.telefono}
                      </p>
                    </div>

                    <div className="flex flex-wrap items-center gap-2 shrink-0">
                      {!tieneConsentimiento && (
                        <button
                          type="button"
                          onClick={() => handleRestaurarConsentimiento(u)}
                          className="px-2.5 py-1.5 rounded-xl bg-emerald-50 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300 text-xs font-semibold cursor-pointer"
                          title="Restaurar consentimiento para que el usuario pueda reservar citas"
                        >
                          Restaurar Consentimiento
                        </button>
                      )}

                      <button
                        type="button"
                        onClick={() => {
                          setUsuarioClaveARestablecer(u);
                          setNuevaClaveInput('');
                        }}
                        className="px-2.5 py-1.5 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
                        title="Cambiar contraseña de este usuario"
                      >
                        Restablecer Clave
                      </button>

                      <button
                        type="button"
                        onClick={() => handleToggleRolUsuario(u)}
                        className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                          esAdmin
                            ? 'bg-gray-200 text-gray-800 dark:bg-gray-700 dark:text-gray-200 hover:bg-gray-300'
                            : 'bg-purple-600 text-white hover:bg-purple-700'
                        }`}
                      >
                        {esAdmin ? 'Hacer Paciente' : 'Ascender a Admin'}
                      </button>

                      {u.id !== paciente?.id && (
                        <button
                          type="button"
                          onClick={() => handleEliminarUsuario(u)}
                          className="p-1.5 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/40 cursor-pointer"
                          title="Eliminar usuario"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* TAB 5: OPCIONES DEL SISTEMA Y FEATURE FLAGS */}
        {tab === 'opciones' && (
          <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                  Opciones Globales y Configuración del Sistema
                </h3>
                <p className="text-xs text-gray-500">
                  Controla las funciones activas de la aplicación clínica en tiempo real.
                </p>
              </div>

              <button
                type="button"
                onClick={() => {
                  activarTodasLasOpcionesYEspecialidades();
                  showToast('⚡ Todas las opciones y especialidades han sido activadas.');
                }}
                className="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold flex items-center gap-1.5 cursor-pointer shadow-xs self-start sm:self-auto"
              >
                <Zap className="w-4 h-4 fill-white" />
                <span>Activar Todas las Opciones</span>
              </button>
            </div>

            {/* Grid de switches de opciones */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Opción 1: Asistente conversacional */}
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex items-start justify-between gap-3">
                <div>
                  <h4 className="font-semibold text-xs text-gray-900 dark:text-white">
                    Reserva con Asistente Conversacional
                  </h4>
                  <p className="text-[11px] text-gray-500 mt-1">
                    Permite a los pacientes agendar citas conversando en lenguaje natural.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    actualizarOpcionSistema('asistenteActivo', !opcionesSistema.asistenteActivo)
                  }
                  className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    opcionesSistema.asistenteActivo ? 'bg-[#00629E]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                      opcionesSistema.asistenteActivo ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Opción 2: Flujo guiado */}
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex items-start justify-between gap-3">
                <div>
                  <h4 className="font-semibold text-xs text-gray-900 dark:text-white">
                    Reserva Paso a Paso Guiada
                  </h4>
                  <p className="text-[11px] text-gray-500 mt-1">
                    Habilita el formulario secuencial de especialidad, médico, fecha y horario.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    actualizarOpcionSistema('reservaGuiadaActiva', !opcionesSistema.reservaGuiadaActiva)
                  }
                  className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    opcionesSistema.reservaGuiadaActiva ? 'bg-[#00629E]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                      opcionesSistema.reservaGuiadaActiva ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Opción 3: Control total admin sin límite 24h */}
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex items-start justify-between gap-3">
                <div>
                  <h4 className="font-semibold text-xs text-gray-900 dark:text-white flex items-center gap-1">
                    <span>Control Total Admin (Omitir regla 24h)</span>
                    <Shield className="w-3.5 h-3.5 text-amber-500" />
                  </h4>
                  <p className="text-[11px] text-gray-500 mt-1">
                    Los administradores pueden cancelar o reprogramar citas en cualquier momento sin bloqueo de 24 horas.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    actualizarOpcionSistema('omitir24hAdmin', !opcionesSistema.omitir24hAdmin)
                  }
                  className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    opcionesSistema.omitir24hAdmin ? 'bg-[#00629E]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                      opcionesSistema.omitir24hAdmin ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Opción 4: Modo Demostración */}
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex items-start justify-between gap-3">
                <div>
                  <h4 className="font-semibold text-xs text-gray-900 dark:text-white">
                    Modo Demostración y Cuentas Rápidas
                  </h4>
                  <p className="text-[11px] text-gray-500 mt-1">
                    Muestra la barra superior para cambiar entre cuentas de prueba (Admin, Paciente, etc.).
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    actualizarOpcionSistema('modoDemoActivo', !opcionesSistema.modoDemoActivo)
                  }
                  className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    opcionesSistema.modoDemoActivo ? 'bg-[#00629E]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                      opcionesSistema.modoDemoActivo ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Opción 5: Guardarraíl Clínico */}
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex items-start justify-between gap-3">
                <div>
                  <h4 className="font-semibold text-xs text-gray-900 dark:text-white">
                    Guardarraíl Clínico Ético (RN-09)
                  </h4>
                  <p className="text-[11px] text-gray-500 mt-1">
                    Redirige inmediatamente a canales de urgencia si se detectan síntomas graves en el asistente.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    actualizarOpcionSistema('guardarailClinicoActivo', !opcionesSistema.guardarailClinicoActivo)
                  }
                  className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    opcionesSistema.guardarailClinicoActivo ? 'bg-[#00629E]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                      opcionesSistema.guardarailClinicoActivo ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Opción 6: Mapas y Localización de Sedes */}
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 flex items-start justify-between gap-3">
                <div>
                  <h4 className="font-semibold text-xs text-gray-900 dark:text-white">
                    Mapas Interactivos de Sedes Clínicas
                  </h4>
                  <p className="text-[11px] text-gray-500 mt-1">
                    Habilita la visualización de mapas y geolocalización de las sedes de la clínica.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    actualizarOpcionSistema('mapasActivos', !opcionesSistema.mapasActivos)
                  }
                  className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    opcionesSistema.mapasActivos ? 'bg-[#00629E]' : 'bg-gray-300 dark:bg-gray-700'
                  }`}
                >
                  <div
                    className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                      opcionesSistema.mapasActivos ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>

            {/* Zona de Mantenimiento y Reinicio */}
            <div className="p-5 rounded-2xl border border-red-200 dark:border-red-900/60 bg-red-50/50 dark:bg-red-950/20 space-y-3">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400" />
                <h4 className="font-bold text-xs text-red-900 dark:text-red-200">
                  Zona de Mantenimiento y Restablecimiento
                </h4>
              </div>
              <p className="text-xs text-red-700 dark:text-red-300">
                Puedes restablecer la base de datos a sus valores iniciales si deseas reiniciar todas las citas, especialidades y cuentas demo.
              </p>
              <button
                type="button"
                onClick={() => {
                  if (confirm('¿Restablecer toda la base de datos a valores de fábrica? Se reiniciarán citas y cuentas demo.')) {
                    StorageService.restablecerDatosFabrica();
                    window.location.reload();
                  }
                }}
                className="px-4 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-semibold cursor-pointer shadow-xs"
              >
                Restablecer Todo a Valores de Fábrica
              </button>
            </div>
          </div>
        )}
      </main>

      {/* MODAL NUEVA CITA ADMINISTRATIVA */}
      {modalNuevaCita && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-md w-full border border-gray-200 dark:border-gray-800 shadow-2xl space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-[#00629E]" />
                <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                  Crear Cita Administrativa Directa
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setModalNuevaCita(false)}
                className="p-1 text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCrearCitaAdmin} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Paciente Asignado
                </label>
                <select
                  value={adminCitaPacienteId}
                  onChange={(e) => setAdminCitaPacienteId(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs text-gray-800 dark:text-gray-200 font-medium"
                >
                  {usuarios.map((u) => (
                    <option key={u.id} value={u.id}>
                      {u.nombres} {u.apellidos} ({u.numeroDocumento})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Especialidad
                </label>
                <select
                  value={adminCitaEspId}
                  onChange={(e) => {
                    setAdminCitaEspId(e.target.value);
                    const profsDeEsp = profesionales.filter((p) => p.especialidadId === e.target.value);
                    if (profsDeEsp.length > 0) setAdminCitaProfId(profsDeEsp[0].id);
                  }}
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs text-gray-800 dark:text-gray-200 font-medium"
                >
                  {todasEspecialidades.map((esp) => (
                    <option key={esp.id} value={esp.id}>
                      {esp.nombre} {!esp.activa ? '(Inactiva)' : ''}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Médico Responsable
                </label>
                <select
                  value={adminCitaProfId}
                  onChange={(e) => setAdminCitaProfId(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs text-gray-800 dark:text-gray-200 font-medium"
                >
                  {profesionales
                    .filter((p) => !adminCitaEspId || p.especialidadId === adminCitaEspId)
                    .map((prof) => (
                      <option key={prof.id} value={prof.id}>
                        Dr(a). {prof.nombres} {prof.apellidos} ({prof.colegiatura})
                      </option>
                    ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Fecha
                  </label>
                  <input
                    type="date"
                    required
                    value={adminCitaFecha}
                    onChange={(e) => setAdminCitaFecha(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs text-gray-800 dark:text-gray-200"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Hora
                  </label>
                  <input
                    type="time"
                    required
                    value={adminCitaHora}
                    onChange={(e) => setAdminCitaHora(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs text-gray-800 dark:text-gray-200"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Sede
                  </label>
                  <select
                    value={adminCitaSedeId}
                    onChange={(e) => setAdminCitaSedeId(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs"
                  >
                    {sedes.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.nombre}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Estado Inicial
                  </label>
                  <select
                    value={adminCitaEstado}
                    onChange={(e) => setAdminCitaEstado(e.target.value as EstadoCita)}
                    className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs"
                  >
                    <option value="confirmada">Confirmada</option>
                    <option value="reprogramada">Reprogramada</option>
                    <option value="atendida">Atendida</option>
                    <option value="inasistencia">Inasistencia</option>
                    <option value="cancelada">Cancelada</option>
                  </select>
                </div>
              </div>

              <div className="flex gap-2 pt-3">
                <button
                  type="button"
                  onClick={() => setModalNuevaCita(false)}
                  className="flex-1 py-2.5 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-[#00629E] text-white text-xs font-semibold cursor-pointer shadow-xs"
                >
                  Crear Cita
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL NUEVA/EDITAR ESPECIALIDAD */}
      {modalNuevaEsp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-sm w-full border border-gray-200 dark:border-gray-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                {espAEditar ? 'Editar Especialidad' : 'Agregar Nueva Especialidad'}
              </h3>
              <button
                type="button"
                onClick={() => setModalNuevaEsp(false)}
                className="p-1 text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleGuardarEspecialidad} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Nombre de la Especialidad
                </label>
                <input
                  type="text"
                  required
                  value={nuevaEspNombre}
                  onChange={(e) => setNuevaEspNombre(e.target.value)}
                  placeholder="Ej: Odontología, Oftalmología, Cardiología"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Descripción
                </label>
                <textarea
                  value={nuevaEspDesc}
                  onChange={(e) => setNuevaEspDesc(e.target.value)}
                  placeholder="Descripción clínica del servicio..."
                  rows={3}
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setModalNuevaEsp(false)}
                  className="flex-1 py-2 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 rounded-xl bg-[#00629E] text-white text-xs font-semibold cursor-pointer shadow-xs"
                >
                  Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL NUEVO/EDITAR MÉDICO */}
      {modalNuevoProf && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-sm w-full border border-gray-200 dark:border-gray-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                {profAEditar ? 'Editar Datos del Médico' : 'Registrar Nuevo Médico'}
              </h3>
              <button
                type="button"
                onClick={() => setModalNuevoProf(false)}
                className="p-1 text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleGuardarProfesional} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Nombres
                </label>
                <input
                  type="text"
                  required
                  value={nuevoProfNombres}
                  onChange={(e) => setNuevoProfNombres(e.target.value)}
                  placeholder="Ej: Daniel Alejandro"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Apellidos
                </label>
                <input
                  type="text"
                  required
                  value={nuevoProfApellidos}
                  onChange={(e) => setNuevoProfApellidos(e.target.value)}
                  placeholder="Ej: Soto Medina"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Especialidad Asignada
                </label>
                <select
                  value={nuevoProfEspId}
                  onChange={(e) => setNuevoProfEspId(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs"
                >
                  {todasEspecialidades.map((esp) => (
                    <option key={esp.id} value={esp.id}>
                      {esp.nombre} {esp.activa ? '' : '(Inactiva)'}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Colegiatura (CMP)
                </label>
                <input
                  type="text"
                  value={nuevoProfColegiatura}
                  onChange={(e) => setNuevoProfColegiatura(e.target.value)}
                  placeholder="CMP-00000X"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setModalNuevoProf(false)}
                  className="flex-1 py-2 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 rounded-xl bg-[#00629E] text-white text-xs font-semibold cursor-pointer shadow-xs"
                >
                  Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL REGISTRAR NUEVO USUARIO */}
      {modalNuevoUsuario && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-sm w-full border border-gray-200 dark:border-gray-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                Registrar Nuevo Usuario (Admin)
              </h3>
              <button
                type="button"
                onClick={() => setModalNuevoUsuario(false)}
                className="p-1 text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCrearUsuarioAdmin} className="space-y-3">
              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Tipo
                  </label>
                  <select
                    value={nuevoUserTipoDoc}
                    onChange={(e) => setNuevoUserTipoDoc(e.target.value as any)}
                    className="w-full px-2 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs"
                  >
                    <option value="DNI">DNI</option>
                    <option value="CE">CE</option>
                  </select>
                </div>
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Número Doc.
                  </label>
                  <input
                    type="text"
                    required
                    value={nuevoUserNumDoc}
                    onChange={(e) => setNuevoUserNumDoc(e.target.value)}
                    placeholder="8 dígitos para DNI"
                    className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Nombres
                </label>
                <input
                  type="text"
                  required
                  value={nuevoUserNombres}
                  onChange={(e) => setNuevoUserNombres(e.target.value)}
                  placeholder="Ej: Rosa María"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Apellidos
                </label>
                <input
                  type="text"
                  required
                  value={nuevoUserApellidos}
                  onChange={(e) => setNuevoUserApellidos(e.target.value)}
                  placeholder="Ej: Morales Castro"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Correo Electrónico
                </label>
                <input
                  type="email"
                  required
                  value={nuevoUserCorreo}
                  onChange={(e) => setNuevoUserCorreo(e.target.value)}
                  placeholder="usuario@correo.com"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Rol
                  </label>
                  <select
                    value={nuevoUserRol}
                    onChange={(e) => setNuevoUserRol(e.target.value as any)}
                    className="w-full px-2 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-xs font-semibold"
                  >
                    <option value="paciente">Paciente</option>
                    <option value="administrador">Administrador</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                    Contraseña
                  </label>
                  <input
                    type="password"
                    required
                    value={nuevoUserClave}
                    onChange={(e) => setNuevoUserClave(e.target.value)}
                    placeholder="Mínimo 8 caracteres"
                    className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                  />
                </div>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setModalNuevoUsuario(false)}
                  className="flex-1 py-2 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 rounded-xl bg-[#00629E] text-white text-xs font-semibold cursor-pointer shadow-xs"
                >
                  Registrar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL RESTABLECER CONTRASEÑA */}
      {usuarioClaveARestablecer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-sm w-full border border-gray-200 dark:border-gray-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                Restablecer Contraseña
              </h3>
              <button
                type="button"
                onClick={() => setUsuarioClaveARestablecer(null)}
                className="p-1 text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-gray-600 dark:text-gray-300">
              Asigna una nueva clave para{' '}
              <span className="font-semibold text-gray-900 dark:text-white">
                {usuarioClaveARestablecer.nombres} {usuarioClaveARestablecer.apellidos}
              </span>{' '}
              (Doc: {usuarioClaveARestablecer.numeroDocumento}).
            </p>

            <form onSubmit={handleRestablecerClave} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                  Nueva Contraseña
                </label>
                <input
                  type="password"
                  required
                  value={nuevaClaveInput}
                  onChange={(e) => setNuevaClaveInput(e.target.value)}
                  placeholder="Mínimo 8 caracteres"
                  className="w-full px-3 py-2 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-xs"
                />
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setUsuarioClaveARestablecer(null)}
                  className="flex-1 py-2 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 rounded-xl bg-[#00629E] text-white text-xs font-semibold cursor-pointer shadow-xs"
                >
                  Actualizar Clave
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
