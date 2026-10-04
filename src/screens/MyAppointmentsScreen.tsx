import React, { useState } from 'react';
import {
  AlertTriangle,
  Calendar,
  Clock,
  Cloud,
  CloudOff,
  MapPin,
  RefreshCw,
  Shield,
  User,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';
import { useClinic } from '../context/ClinicContext';
import { Cita } from '../types';
import { FormatoFecha } from '../utils/fechasNaturales';
import { Rn06Autogestion } from '../domain/rules/rn06_rn07_rn08Gestion';

interface MyAppointmentsScreenProps {
  onBack: () => void;
  onGoToBooking: () => void;
  onReprogramar: (cita: Cita) => void;
}

export const MyAppointmentsScreen: React.FC<MyAppointmentsScreenProps> = ({
  onBack,
  onGoToBooking,
  onReprogramar,
}) => {
  const { paciente } = useAuth();
  const {
    citas,
    cancelarCita,
    recargarCitas,
    ultimaSincronizacion,
    sinConexion,
    especialidadDe,
    profesionalDe,
    sedeDe,
  } = useClinic();

  const [citaACancelar, setCitaACancelar] = useState<Cita | null>(null);
  const [cancelando, setCancelando] = useState(false);
  const [mensajeExito, setMensajeExito] = useState<string | null>(null);
  const [verTodasClinica, setVerTodasClinica] = useState(false);

  const esAdministrador = paciente?.rol === 'administrador';

  const citasVisibles = esAdministrador && verTodasClinica
    ? citas
    : citas.filter((c) => c.pacienteId === paciente?.id);

  const proximas = citasVisibles
    .filter((c) => c.estado === 'confirmada' || c.estado === 'reprogramada')
    .sort((a, b) => new Date(a.fechaHoraInicio).getTime() - new Date(b.fechaHoraInicio).getTime());

  const pasadas = citasVisibles
    .filter((c) => c.estado !== 'confirmada' && c.estado !== 'reprogramada')
    .sort((a, b) => new Date(b.fechaHoraInicio).getTime() - new Date(a.fechaHoraInicio).getTime());

  const ahora = new Date();

  const handleConfirmarCancelacion = async () => {
    if (!citaACancelar) return;
    setCancelando(true);
    const res = await cancelarCita(citaACancelar.id);
    setCancelando(false);
    setCitaACancelar(null);
    if (res.ok) {
      setMensajeExito(Cadenas.citaCancelada);
      setTimeout(() => setMensajeExito(null), 4000);
    }
  };

  const getBadgeStyle = (estado: string) => {
    switch (estado) {
      case 'confirmada':
      case 'reprogramada':
        return 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400 border-emerald-300 dark:border-emerald-800';
      case 'atendida':
        return 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-400 border-blue-300 dark:border-blue-800';
      case 'cancelada':
      case 'inasistencia':
        return 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-400 border-red-300 dark:border-red-800';
      default:
        return 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300 border-gray-300 dark:border-gray-700';
    }
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
      <Navbar titulo={Cadenas.misCitas} onBack={onBack} />

      {/* Barra de sincronización (HU-09) */}
      <div className="bg-[#DEE3EB]/40 dark:bg-[#42474E]/30 border-b border-gray-200 dark:border-gray-800 px-4 py-2 text-xs text-gray-600 dark:text-gray-300 flex items-center justify-between">
        <div className="flex items-center gap-2">
          {sinConexion ? (
            <CloudOff className="w-4 h-4 text-amber-500" />
          ) : (
            <Cloud className="w-4 h-4 text-emerald-600" />
          )}
          <span>
            {sinConexion ? `${Cadenas.sinConexionAviso}. ` : ''}
            {ultimaSincronizacion
              ? `${Cadenas.ultimaSincronizacion} ${FormatoFecha.desde(ultimaSincronizacion, ahora)}`
              : Cadenas.nuncaSincronizado}
          </span>
        </div>
        <button
          type="button"
          onClick={() => recargarCitas()}
          className="p-1 hover:text-gray-900 dark:hover:text-white cursor-pointer"
          title={Cadenas.actualizar}
        >
          <RefreshCw className="w-3.5 h-3.5" />
        </button>
      </div>

      <main className="max-w-2xl mx-auto px-4 py-6 space-y-6">
        {mensajeExito && (
          <div className="p-3.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-300 dark:border-emerald-800 text-xs text-emerald-800 dark:text-emerald-200 font-medium">
            {mensajeExito}
          </div>
        )}

        {/* Selector de modo para Administrador */}
        {esAdministrador && (
          <div className="flex items-center justify-between p-1 rounded-2xl bg-gray-100 dark:bg-gray-800/80 border border-gray-200 dark:border-gray-700">
            <button
              type="button"
              onClick={() => setVerTodasClinica(false)}
              className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                !verTodasClinica
                  ? 'bg-white dark:bg-[#1E2124] text-gray-900 dark:text-white shadow-xs'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              Mis Citas ({citas.filter((c) => c.pacienteId === paciente?.id).length})
            </button>
            <button
              type="button"
              onClick={() => setVerTodasClinica(true)}
              className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                verTodasClinica
                  ? 'bg-[#00629E] text-white shadow-xs'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              Todas de la Clínica (Admin: {citas.length})
            </button>
          </div>
        )}

        {citasVisibles.length === 0 ? (
          <div className="text-center py-16 px-4 space-y-4">
            <p className="text-base text-gray-600 dark:text-gray-400">
              {Cadenas.sinCitas}
            </p>
            <button
              type="button"
              onClick={onGoToBooking}
              className="px-5 py-2.5 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-xs transition-colors cursor-pointer"
            >
              {Cadenas.reservarAhora}
            </button>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Próximas Citas */}
            <div>
              <h3 className="text-base font-bold text-gray-900 dark:text-white mb-3">
                {Cadenas.proximasCitas}
              </h3>

              {proximas.length === 0 ? (
                <div className="p-6 text-center rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 text-xs text-gray-500 dark:text-gray-400">
                  {Cadenas.sinCitasProximas}
                </div>
              ) : (
                <div className="space-y-3">
                  {proximas.map((cita) => {
                    const esp = especialidadDe(cita.especialidadId);
                    const prof = profesionalDe(cita.profesionalId);
                    const sede = sedeDe(cita.sedeId);

                    const puedeCancelar = Rn06Autogestion.sePuede(cita, 'cancelar', ahora, undefined, esAdministrador);
                    const puedeReprogramar = Rn06Autogestion.sePuede(cita, 'reprogramar', ahora, undefined, esAdministrador);
                    const motivoCancelacion = Rn06Autogestion.validar(cita, 'cancelar', ahora, undefined, esAdministrador).mensaje;

                    return (
                      <div
                        key={cita.id}
                        className="p-5 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs space-y-3"
                      >
                        <div className="flex items-start justify-between gap-2">
                          <h4 className="font-bold text-sm text-gray-900 dark:text-white">
                            {esp?.nombre || Cadenas.cargando}
                          </h4>
                          <span
                            className={`text-[11px] font-semibold px-2.5 py-0.5 rounded-full border capitalize ${getBadgeStyle(
                              cita.estado
                            )}`}
                          >
                            {cita.estado}
                          </span>
                        </div>

                        <div className="space-y-1.5 text-xs text-gray-600 dark:text-gray-300">
                          <div className="flex items-center gap-2">
                            <Clock className="w-3.5 h-3.5 text-[#00629E] dark:text-[#9CCAFF]" />
                            <span className="font-medium">
                              {FormatoFecha.fechaLarga(cita.fechaHoraInicio)} ·{' '}
                              {FormatoFecha.hora(cita.fechaHoraInicio)}
                            </span>
                          </div>

                          {prof && (
                            <div className="flex items-center gap-2">
                              <User className="w-3.5 h-3.5 text-gray-400" />
                              <span>
                                Dr(a). {prof.nombres} {prof.apellidos}
                              </span>
                            </div>
                          )}

                          {sede && (
                            <div className="flex items-center gap-2">
                              <MapPin className="w-3.5 h-3.5 text-gray-400" />
                              <span>{sede.nombre}</span>
                            </div>
                          )}
                        </div>

                        {/* Botones de Autogestión (RN-06) */}
                        <div className="pt-2 border-t border-gray-100 dark:border-gray-800">
                          {esAdministrador && (
                            <div className="flex items-center gap-1.5 mb-2 text-[11px] text-purple-700 dark:text-purple-300 font-semibold">
                              <Shield className="w-3.5 h-3.5" />
                              <span>Permiso Administrador: Control total activo</span>
                            </div>
                          )}

                          {!puedeCancelar && !puedeReprogramar && motivoCancelacion ? (
                            <p className="text-[11px] text-gray-500 dark:text-gray-400 italic">
                              {motivoCancelacion}
                            </p>
                          ) : (
                            <div className="flex gap-2">
                              <button
                                type="button"
                                disabled={!puedeReprogramar}
                                onClick={() => onReprogramar(cita)}
                                className="flex-1 py-2 px-3 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer disabled:opacity-40"
                              >
                                {Cadenas.reprogramar}
                              </button>
                              <button
                                type="button"
                                disabled={!puedeCancelar}
                                onClick={() => setCitaACancelar(cita)}
                                className="flex-1 py-2 px-3 rounded-xl border border-red-300 dark:border-red-800 text-xs font-semibold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors cursor-pointer disabled:opacity-40"
                              >
                                {Cadenas.cancelarCita}
                              </button>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Citas Anteriores */}
            {pasadas.length > 0 && (
              <div>
                <h3 className="text-base font-bold text-gray-900 dark:text-white mb-3">
                  {Cadenas.citasAnteriores}
                </h3>
                <div className="space-y-3">
                  {pasadas.map((cita) => {
                    const esp = especialidadDe(cita.especialidadId);
                    const prof = profesionalDe(cita.profesionalId);
                    const sede = sedeDe(cita.sedeId);

                    return (
                      <div
                        key={cita.id}
                        className="p-4 rounded-2xl bg-gray-50 dark:bg-gray-800/40 border border-gray-200 dark:border-gray-800 space-y-2 opacity-80"
                      >
                        <div className="flex items-start justify-between gap-2">
                          <h4 className="font-semibold text-sm text-gray-800 dark:text-gray-200">
                            {esp?.nombre || Cadenas.cargando}
                          </h4>
                          <span
                            className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border capitalize ${getBadgeStyle(
                              cita.estado
                            )}`}
                          >
                            {cita.estado}
                          </span>
                        </div>

                        <div className="text-xs text-gray-500 dark:text-gray-400 space-y-1">
                          <p>
                            {FormatoFecha.fechaLarga(cita.fechaHoraInicio)} ·{' '}
                            {FormatoFecha.hora(cita.fechaHoraInicio)}
                          </p>
                          {prof && <p>Dr(a). {prof.nombres} {prof.apellidos}</p>}
                          {sede && <p>{sede.nombre}</p>}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        )}
      </main>

      {/* Modal de confirmación para cancelar cita */}
      {citaACancelar && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-sm w-full border border-gray-200 dark:border-gray-800 shadow-xl space-y-4">
            <div className="flex items-center gap-3 text-red-600 dark:text-red-400">
              <AlertTriangle className="w-6 h-6 shrink-0" />
              <h3 className="font-bold text-base text-gray-900 dark:text-white">
                {Cadenas.cancelarCita}
              </h3>
            </div>

            <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
              {Cadenas.cancelarCitaAviso}
            </p>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setCitaACancelar(null)}
                disabled={cancelando}
                className="flex-1 py-2.5 px-3 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
              >
                {Cadenas.cancelar}
              </button>
              <button
                type="button"
                onClick={handleConfirmarCancelacion}
                disabled={cancelando}
                className="flex-1 py-2.5 px-3 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-semibold cursor-pointer"
              >
                {cancelando ? 'Cancelando...' : Cadenas.confirmar}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
