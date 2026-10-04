import React, { useState } from 'react';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import { CabeceraConLogo } from '../components/LogoClinica';
import { DemoAccountsBar } from '../components/DemoAccountsBar';
import { AvisoModoDemostracion } from '../components/AvisoModoDemostracion';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';

interface LoginScreenProps {
  onGoToRegister: () => void;
  onLoginSuccess: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({ onGoToRegister, onLoginSuccess }) => {
  const { iniciarSesion, error, limpiarError, loading } = useAuth();

  const [documento, setDocumento] = useState('');
  const [clave, setClave] = useState('');
  const [mostrarClave, setMostrarClave] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    limpiarError();

    if (!documento.trim()) {
      setFormError(Cadenas.ingresaDocumentoOUsuario);
      return;
    }
    if (!clave) {
      setFormError('Ingresa tu contraseña.');
      return;
    }

    const exito = await iniciarSesion(documento.trim(), clave);
    if (exito) {
      onLoginSuccess();
    }
  };

  const handleSelectDemo = (doc: string, pass: string) => {
    setDocumento(doc);
    setClave(pass);
    setFormError(null);
    limpiarError();
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white dark:bg-[#1E2124] rounded-3xl p-6 sm:p-8 shadow-sm border border-gray-200 dark:border-gray-800 transition-colors">
        <CabeceraConLogo
          titulo={Cadenas.tituloInicioSesion}
          subtitulo={Cadenas.subtituloInicioSesion}
          altoLogo={72}
        />

        <DemoAccountsBar onSelectAccount={handleSelectDemo} disabled={loading} />

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              {Cadenas.documentoOUsuario}
            </label>
            <input
              type="text"
              value={documento}
              onChange={(e) => {
                setDocumento(e.target.value);
                setFormError(null);
              }}
              disabled={loading}
              placeholder="Ej: 00000001 o JCAQUI"
              className="w-full px-4 py-3 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-[#1A1C1E] dark:text-[#E2E2E5] focus:outline-none focus:ring-2 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF] text-sm"
              autoComplete="username"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              {Cadenas.clave}
            </label>
            <div className="relative">
              <input
                type={mostrarClave ? 'text' : 'password'}
                value={clave}
                onChange={(e) => {
                  setClave(e.target.value);
                  setFormError(null);
                }}
                disabled={loading}
                placeholder="Contraseña"
                className="w-full px-4 py-3 rounded-xl border border-gray-300 dark:border-gray-700 bg-transparent text-[#1A1C1E] dark:text-[#E2E2E5] focus:outline-none focus:ring-2 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF] text-sm pr-11"
                autoComplete="current-password"
              />
              <button
                type="button"
                onClick={() => setMostrarClave(!mostrarClave)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 cursor-pointer p-1"
                aria-label={mostrarClave ? Cadenas.semanticaOcultarClave : Cadenas.semanticaMostrarClave}
              >
                {mostrarClave ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {(formError || error) && (
            <div
              className="p-3 rounded-xl bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900 text-xs text-red-600 dark:text-red-400 font-medium"
              role="alert"
            >
              {formError || error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-sm transition-colors shadow-sm flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-6 min-h-[48px]"
          >
            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : Cadenas.entrar}
          </button>
        </form>

        <div className="mt-5 text-center">
          <button
            type="button"
            onClick={onGoToRegister}
            disabled={loading}
            className="text-xs text-[#00629E] dark:text-[#9CCAFF] hover:underline font-medium cursor-pointer"
          >
            {Cadenas.noTengoCuenta}
          </button>
        </div>

        <div className="mt-8 pt-4 border-t border-gray-100 dark:border-gray-800">
          <AvisoModoDemostracion />
        </div>
      </div>
    </div>
  );
};
