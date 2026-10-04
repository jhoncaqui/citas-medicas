import React from 'react';
import { CheckCircle2, Home } from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { useClinic } from '../context/ClinicContext';
import { FormatoFecha } from '../utils/fechasNaturales';

interface ComprobanteScreenProps {
  onBackToHome: () => void;
}

export const ComprobanteScreen: React.FC<ComprobanteScreenProps> = ({ onBackToHome }) => {
  const { citaConfirmadaReciente, especialidadDe, profesionalDe, sedeDe, consultorioDe } = useClinic();

  if (!citaConfirmadaReciente) {
    return (
      <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] flex flex-col items-center justify-center p-4">
        <p className="text-sm text-gray-500 mb-4">No hay comprobante reciente.</p>
        <button
          type="button"
          onClick={onBackToHome}
          className="px-4 py-2.5 rounded-xl bg-[#00629E] text-white text-xs font-semibold cursor-pointer"
        >
          {Cadenas.volverAlInicio}
        </button>
      </div>
    );
  }

  const cita = citaConfirmadaReciente;
  const esp = especialidadDe(cita.especialidadId);
  const prof = profesionalDe(cita.profesionalId);
  const sede = sedeDe(cita.sedeId);
  const consultorio = consultorioDe(cita.consultorioId);

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
      <Navbar titulo={Cadenas.tituloComprobante} />

      <main className="max-w-md mx-auto px-4 py-6 space-y-6">
        <div className="flex items-center gap-3 p-4 bg-emerald-50 dark:bg-emerald-950/40 rounded-2xl border border-emerald-200 dark:border-emerald-900">
          <CheckCircle2 className="w-6 h-6 text-emerald-600 dark:text-emerald-400 shrink-0" />
          <h2 className="font-bold text-sm text-emerald-900 dark:text-emerald-200">
            {Cadenas.reservaConfirmada}
          </h2>
        </div>

        {/* Tarjeta del comprobante */}
        <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 border border-gray-200 dark:border-gray-800 shadow-sm space-y-4">
          <div className="space-y-3 text-xs">
            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteEspecialidad}</span>
              <span className="font-semibold text-gray-900 dark:text-white text-right">
                {esp?.nombre || '-'}
              </span>
            </div>

            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteProfesional}</span>
              <span className="font-semibold text-gray-900 dark:text-white text-right">
                {prof ? `Dr(a). ${prof.nombres} ${prof.apellidos}` : '-'}
              </span>
            </div>

            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteFecha}</span>
              <span className="font-semibold text-gray-900 dark:text-white text-right">
                {FormatoFecha.fechaLarga(cita.fechaHoraInicio)}
              </span>
            </div>

            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteHora}</span>
              <span className="font-semibold text-[#00629E] dark:text-[#9CCAFF] text-right">
                {FormatoFecha.hora(cita.fechaHoraInicio)}
              </span>
            </div>

            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteSede}</span>
              <span className="font-semibold text-gray-900 dark:text-white text-right max-w-[200px]">
                {sede?.nombre || '-'}
              </span>
            </div>

            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteConsultorio}</span>
              <span className="font-semibold text-gray-900 dark:text-white text-right">
                {consultorio ? `${consultorio.codigo} (piso ${consultorio.piso})` : '-'}
              </span>
            </div>

            <div className="flex justify-between py-1 border-b border-gray-100 dark:border-gray-800/80">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteEstado}</span>
              <span className="font-semibold text-emerald-600 dark:text-emerald-400 capitalize text-right">
                {cita.estado}
              </span>
            </div>

            <div className="flex justify-between py-1">
              <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteCodigo}</span>
              <span className="font-mono text-gray-700 dark:text-gray-300 text-right">
                {cita.id}
              </span>
            </div>
          </div>
        </div>

        {/* ODS 12: Comprobante digital sin papel */}
        <p className="text-xs text-center text-gray-500 dark:text-gray-400 leading-relaxed px-4">
          {Cadenas.comprobanteSinImpresion}
        </p>

        <button
          type="button"
          onClick={onBackToHome}
          className="w-full py-3.5 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-xs transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-sm"
        >
          <Home className="w-4 h-4" />
          <span>{Cadenas.volverAlInicio}</span>
        </button>
      </main>
    </div>
  );
};
