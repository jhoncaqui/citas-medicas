import React, { useState } from 'react';
import {
  AlertCircle,
  BarChart3,
  Calendar,
  CheckCircle2,
  Info,
  ShieldAlert,
  UserX,
  XCircle,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';
import { useClinic } from '../context/ClinicContext';
import { CanalReserva, PeriodoIndicadores } from '../types';

interface IndicatorsScreenProps {
  onBack: () => void;
}

const NOMBRES_CANALES: Record<CanalReserva, string> = {
  conversacional: 'Asistente conversacional',
  flujo_guiado: 'Flujo guiado paso a paso',
  telefonico: 'Atención telefónica',
  presencial: 'Admisión presencial',
};

export const IndicatorsScreen: React.FC<IndicatorsScreenProps> = ({ onBack }) => {
  const { paciente } = useAuth();
  const { calcularIndicadores } = useClinic();

  const [periodo, setPeriodo] = useState<PeriodoIndicadores>('ultimos30');

  // RN-01: Verificación de acceso
  if (paciente?.rol !== 'administrador') {
    return (
      <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
        <Navbar titulo={Cadenas.tituloIndicadores} onBack={onBack} />
        <main className="max-w-md mx-auto px-4 py-16 text-center space-y-4">
          <div className="w-12 h-12 rounded-full bg-red-100 dark:bg-red-950/40 text-red-600 dark:text-red-400 mx-auto flex items-center justify-center">
            <ShieldAlert className="w-6 h-6" />
          </div>
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">
            Acceso restringido
          </h2>
          <p className="text-xs text-gray-600 dark:text-gray-400">
            Esta sección es exclusiva para el personal de administración (RN-01).
          </p>
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 rounded-xl bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] text-xs font-semibold cursor-pointer"
          >
            Volver
          </button>
        </main>
      </div>
    );
  }

  const datos = calcularIndicadores(periodo);

  const formatPorcentaje = (val: number | null): string => {
    if (val === null) return Cadenas.indicadorSinDenominador;
    return `${Math.round(val * 100)} %`;
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
      <Navbar titulo={Cadenas.tituloIndicadores} onBack={onBack} />

      <main className="max-w-2xl mx-auto px-4 py-6 space-y-6">
        {/* Aviso de alcance */}
        <div className="p-3.5 rounded-2xl bg-[#DEE3EB]/40 dark:bg-[#42474E]/30 border border-[#DEE3EB] dark:border-[#42474E] text-xs text-[#43474E] dark:text-[#C2C7CF] flex items-start gap-2.5">
          <Info className="w-4 h-4 text-[#00629E] dark:text-[#9CCAFF] shrink-0 mt-0.5" />
          <p>{Cadenas.indicadorAvisoAlcance}</p>
        </div>

        {/* Selector de Periodo */}
        <div>
          <label className="block text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
            {Cadenas.indicadorPeriodo}
          </label>
          <div className="grid grid-cols-3 gap-2">
            <button
              type="button"
              onClick={() => setPeriodo('ultimos7')}
              className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                periodo === 'ultimos7'
                  ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] border-transparent shadow-xs'
                  : 'bg-white dark:bg-[#1E2124] text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-800'
              }`}
            >
              Últimos 7 días
            </button>
            <button
              type="button"
              onClick={() => setPeriodo('ultimos30')}
              className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                periodo === 'ultimos30'
                  ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] border-transparent shadow-xs'
                  : 'bg-white dark:bg-[#1E2124] text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-800'
              }`}
            >
              Últimos 30 días
            </button>
            <button
              type="button"
              onClick={() => setPeriodo('todo')}
              className={`py-2 px-3 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
                periodo === 'todo'
                  ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] border-transparent shadow-xs'
                  : 'bg-white dark:bg-[#1E2124] text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-800'
              }`}
            >
              Todo el historial
            </button>
          </div>
        </div>

        {datos.sinDatos ? (
          <div className="p-8 text-center bg-white dark:bg-[#1E2124] rounded-2xl border border-gray-200 dark:border-gray-800 text-xs text-gray-500">
            {Cadenas.indicadorSinDatos}
          </div>
        ) : (
          <div className="space-y-4">
            {/* Cifra destacada: Reservadas */}
            <div className="p-5 rounded-2xl bg-[#CFE5FF] dark:bg-[#004A78] text-[#001D33] dark:text-[#CFE5FF] border border-[#9CCAFF] dark:border-[#00629E] shadow-xs">
              <span className="text-xs font-medium opacity-90 block">
                {Cadenas.indicadorReservadas}
              </span>
              <span className="text-3xl font-extrabold mt-1 block tracking-tight">
                {datos.reservadas}
              </span>
            </div>

            {/* Grid 2x2 métricas */}
            <div className="grid grid-cols-2 gap-3">
              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs">
                <div className="flex items-center gap-1.5 text-gray-500 dark:text-gray-400 text-xs mb-1">
                  <XCircle className="w-3.5 h-3.5 text-red-500" />
                  <span>{Cadenas.indicadorCanceladas}</span>
                </div>
                <span className="text-2xl font-bold text-gray-900 dark:text-white">
                  {datos.canceladas}
                </span>
                {datos.tasaCancelacion !== null && (
                  <span className="text-[10px] text-gray-400 block mt-0.5">
                    {formatPorcentaje(datos.tasaCancelacion)} del total
                  </span>
                )}
              </div>

              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs">
                <div className="flex items-center gap-1.5 text-gray-500 dark:text-gray-400 text-xs mb-1">
                  <UserX className="w-3.5 h-3.5 text-amber-500" />
                  <span>{Cadenas.indicadorInasistencias}</span>
                </div>
                <span className="text-2xl font-bold text-gray-900 dark:text-white">
                  {datos.inasistencias}
                </span>
                <span className="text-[10px] text-gray-400 block mt-0.5">
                  Tasa: {formatPorcentaje(datos.tasaInasistencia)}
                </span>
              </div>

              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs">
                <div className="flex items-center gap-1.5 text-gray-500 dark:text-gray-400 text-xs mb-1">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>{Cadenas.indicadorAtendidas}</span>
                </div>
                <span className="text-2xl font-bold text-gray-900 dark:text-white">
                  {datos.atendidas}
                </span>
              </div>

              <div className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs">
                <div className="flex items-center gap-1.5 text-gray-500 dark:text-gray-400 text-xs mb-1">
                  <AlertCircle className="w-3.5 h-3.5 text-blue-500" />
                  <span>{Cadenas.indicadorTasaInasistencia}</span>
                </div>
                <span className="text-2xl font-bold text-gray-900 dark:text-white">
                  {formatPorcentaje(datos.tasaInasistencia)}
                </span>
                <span className="text-[10px] text-gray-400 block mt-0.5">
                  Sobre citas cerradas ({datos.cerradas})
                </span>
              </div>
            </div>

            {/* Indicador de Autogestión (clave de éxito de la app) */}
            <div className="p-5 rounded-2xl bg-[#CFE5FF] dark:bg-[#004A78] text-[#001D33] dark:text-[#CFE5FF] border border-[#9CCAFF] dark:border-[#00629E] shadow-xs">
              <span className="text-xs font-medium opacity-90 block">
                {Cadenas.indicadorAutogestion}
              </span>
              <span className="text-3xl font-extrabold mt-1 block tracking-tight">
                {formatPorcentaje(datos.tasaAutogestion)}
              </span>
              <span className="text-xs opacity-85 block mt-1">
                {datos.autogestionadas} de {datos.reservadas} citas fueron agendadas por los pacientes
              </span>
            </div>

            {/* Desglose por Canal */}
            <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 border border-gray-200 dark:border-gray-800 shadow-sm space-y-4">
              <div className="flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-[#00629E] dark:text-[#9CCAFF]" />
                <h4 className="font-bold text-sm text-gray-900 dark:text-white">
                  {Cadenas.indicadorPorCanal}
                </h4>
              </div>

              <div className="space-y-3">
                {(Object.entries(datos.porCanal) as [CanalReserva, number][]).map(([canal, cant]) => {
                  const pct = datos.reservadas === 0 ? 0 : Math.round((cant / datos.reservadas) * 100);
                  return (
                    <div key={canal} className="space-y-1.5">
                      <div className="flex justify-between text-xs">
                        <span className="text-gray-700 dark:text-gray-300 font-medium">
                          {NOMBRES_CANALES[canal]}
                        </span>
                        <span className="text-gray-500 dark:text-gray-400 font-semibold">
                          {cant} ({pct}%)
                        </span>
                      </div>
                      <div className="w-full bg-gray-100 dark:bg-gray-800 rounded-full h-2 overflow-hidden">
                        <div
                          className="bg-[#00629E] dark:bg-[#9CCAFF] h-2 rounded-full transition-all duration-300"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
};
