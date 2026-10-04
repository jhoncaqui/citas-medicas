import React, { useState } from 'react';
import {
  AlertTriangle,
  CheckCircle,
  LogOut,
  ShieldAlert,
  ShieldCheck,
  Trash2,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';
import { FormatoFecha } from '../utils/fechasNaturales';

interface PrivacyScreenProps {
  onBack: () => void;
  onLogoutOrDelete: () => void;
}

export const PrivacyScreen: React.FC<PrivacyScreenProps> = ({ onBack, onLogoutOrDelete }) => {
  const {
    paciente,
    otorgarConsentimiento,
    revocarConsentimiento,
    eliminarMisDatos,
    cerrarSesion,
    loading,
  } = useAuth();

  const [dialogo, setDialogo] = useState<'revocar' | 'eliminar' | null>(null);
  const [mensajeToast, setMensajeToast] = useState<string | null>(null);

  if (!paciente) return null;

  const handleOtorgar = async () => {
    const ok = await otorgarConsentimiento();
    if (ok) {
      setMensajeToast(Cadenas.consentimientoOtorgadoAviso);
      setTimeout(() => setMensajeToast(null), 3000);
    }
  };

  const handleConfirmarRevocacion = async () => {
    setDialogo(null);
    const ok = await revocarConsentimiento();
    if (ok) {
      setMensajeToast(Cadenas.consentimientoRevocadoAviso);
      setTimeout(() => setMensajeToast(null), 3000);
    }
  };

  const handleConfirmarEliminacion = async () => {
    setDialogo(null);
    const ok = await eliminarMisDatos();
    if (ok) {
      onLogoutOrDelete();
    }
  };

  const handleCerrarSesion = () => {
    cerrarSesion();
    onLogoutOrDelete();
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
      <Navbar titulo={Cadenas.tituloPrivacidad} onBack={onBack} />

      <main className="max-w-2xl mx-auto px-4 py-6 space-y-6">
        {mensajeToast && (
          <div className="p-3.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-300 dark:border-emerald-800 text-xs text-emerald-800 dark:text-emerald-200 font-medium">
            {mensajeToast}
          </div>
        )}

        {/* Tarjeta de estado de consentimiento (RN-10) */}
        <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 border border-gray-200 dark:border-gray-800 shadow-sm space-y-4">
          <div className="flex items-start gap-3">
            <div className="p-2.5 rounded-2xl bg-blue-50 dark:bg-blue-950/50 text-[#00629E] dark:text-[#9CCAFF] shrink-0">
              {paciente.consentimientoOtorgado ? (
                <ShieldCheck className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
              ) : (
                <ShieldAlert className="w-6 h-6 text-amber-600 dark:text-amber-400" />
              )}
            </div>
            <div>
              <h3 className="font-bold text-sm text-gray-900 dark:text-white">
                {paciente.consentimientoOtorgado && paciente.fechaConsentimiento
                  ? `${Cadenas.consentimientoVigente} ${FormatoFecha.fechaCorta(
                      paciente.fechaConsentimiento
                    )}`
                  : Cadenas.consentimientoRevocado}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 leading-relaxed">
                {Cadenas.consentimientoDetalle}
              </p>
            </div>
          </div>

          <div className="pt-2">
            {paciente.consentimientoOtorgado ? (
              <button
                type="button"
                disabled={loading}
                onClick={() => setDialogo('revocar')}
                className="w-full py-2.5 px-4 rounded-xl border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 font-semibold text-xs hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer"
              >
                {Cadenas.revocarConsentimiento}
              </button>
            ) : (
              <button
                type="button"
                disabled={loading}
                onClick={handleOtorgar}
                className="w-full py-2.5 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-xs transition-colors cursor-pointer"
              >
                {Cadenas.otorgarConsentimiento}
              </button>
            )}
          </div>
        </div>

        {/* Zona de peligro: Eliminar datos (HU-12) */}
        <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 border border-gray-200 dark:border-gray-800 shadow-sm space-y-3">
          <h4 className="font-bold text-sm text-red-600 dark:text-red-400">
            Eliminación de datos
          </h4>
          <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
            {Cadenas.eliminarMisDatosAviso}
          </p>

          <button
            type="button"
            disabled={loading}
            onClick={() => setDialogo('eliminar')}
            className="w-full py-2.5 px-4 rounded-xl border border-red-300 dark:border-red-800 text-red-600 dark:text-red-400 font-semibold text-xs hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors flex items-center justify-center gap-2 cursor-pointer"
          >
            <Trash2 className="w-4 h-4" />
            <span>{Cadenas.eliminarMisDatos}</span>
          </button>
        </div>

        {/* Cerrar sesión */}
        <div className="pt-2">
          <button
            type="button"
            onClick={handleCerrarSesion}
            className="w-full py-3 px-4 rounded-xl border border-gray-200 dark:border-gray-800 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800 font-semibold text-xs transition-colors flex items-center justify-center gap-2 cursor-pointer"
          >
            <LogOut className="w-4 h-4" />
            <span>{Cadenas.cerrarSesion}</span>
          </button>
        </div>
      </main>

      {/* Modal de diálogo */}
      {dialogo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 max-w-sm w-full border border-gray-200 dark:border-gray-800 shadow-xl space-y-4">
            <div className="flex items-center gap-3 text-red-600 dark:text-red-400">
              <AlertTriangle className="w-6 h-6 shrink-0" />
              <h3 className="font-bold text-base text-gray-900 dark:text-white">
                {dialogo === 'revocar'
                  ? Cadenas.revocarConsentimiento
                  : Cadenas.eliminarMisDatos}
              </h3>
            </div>

            <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
              {dialogo === 'revocar'
                ? Cadenas.revocarConsentimientoAviso
                : Cadenas.eliminarMisDatosAviso}
            </p>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setDialogo(null)}
                className="flex-1 py-2.5 px-3 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
              >
                {Cadenas.cancelar}
              </button>
              <button
                type="button"
                onClick={
                  dialogo === 'revocar'
                    ? handleConfirmarRevocacion
                    : handleConfirmarEliminacion
                }
                className="flex-1 py-2.5 px-3 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-semibold cursor-pointer"
              >
                {Cadenas.confirmar}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
