import React from 'react';
import { ArrowLeft, LogOut, Moon, Shield, Sun } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { Cadenas } from '../constants/cadenas';

interface NavbarProps {
  titulo?: string;
  onBack?: () => void;
  onOpenPrivacy?: () => void;
  onOpenAdmin?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ titulo, onBack, onOpenPrivacy, onOpenAdmin }) => {
  const { paciente, cerrarSesion } = useAuth();
  const { effectiveTheme, toggleTheme } = useTheme();

  return (
    <header className="sticky top-0 z-30 bg-white/90 dark:bg-[#121417]/90 backdrop-blur-md border-b border-gray-200 dark:border-gray-800 transition-colors">
      <div className="max-w-2xl mx-auto px-4 h-16 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2 min-w-0">
          {onBack && (
            <button
              type="button"
              onClick={onBack}
              className="p-2 -ml-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-colors cursor-pointer"
              aria-label="Volver atrás"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
          )}

          <div className="flex items-center gap-2 min-w-0">
            {!onBack && (
              <img
                src="/assets/images/logo.png"
                alt="Logo"
                className="w-8 h-8 object-contain shrink-0"
                onError={(e) => {
                  (e.currentTarget as HTMLElement).style.display = 'none';
                }}
              />
            )}
            <h1 className="font-bold text-lg text-[#1A1C1E] dark:text-[#E2E2E5] truncate">
              {titulo || Cadenas.nombreApp}
            </h1>
          </div>
        </div>

        <div className="flex items-center gap-1 shrink-0">
          {paciente && (
            paciente.rol === 'administrador' && onOpenAdmin ? (
              <button
                type="button"
                onClick={onOpenAdmin}
                className="hidden sm:inline-flex items-center text-xs font-bold px-2.5 py-0.5 rounded-full bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300 border border-purple-200 dark:border-purple-800 mr-1 hover:bg-purple-200 cursor-pointer"
                title="Abrir Panel de Control Total"
              >
                Panel Admin
              </button>
            ) : (
              <span className="hidden sm:inline-flex items-center text-xs font-medium px-2 py-0.5 rounded-full bg-blue-50 text-[#00629E] dark:bg-blue-950/40 dark:text-[#9CCAFF] border border-blue-200 dark:border-blue-900 mr-1">
                {paciente.rol === 'administrador' ? 'Admin' : 'Paciente'}
              </span>
            )
          )}

          <button
            type="button"
            onClick={toggleTheme}
            className="p-2.5 rounded-full text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer"
            title={Cadenas.semanticaCambiarTema}
            aria-label={Cadenas.semanticaCambiarTema}
          >
            {effectiveTheme === 'dark' ? (
              <Sun className="w-5 h-5 text-amber-400" />
            ) : (
              <Moon className="w-5 h-5 text-gray-700" />
            )}
          </button>

          {onOpenPrivacy && (
            <button
              type="button"
              onClick={onOpenPrivacy}
              className="p-2.5 rounded-full text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer"
              title={Cadenas.tituloPrivacidad}
              aria-label={Cadenas.tituloPrivacidad}
            >
              <Shield className="w-5 h-5 text-[#00629E] dark:text-[#9CCAFF]" />
            </button>
          )}

          {paciente && (
            <button
              type="button"
              onClick={cerrarSesion}
              className="p-2.5 rounded-full text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors cursor-pointer"
              title={Cadenas.cerrarSesion}
              aria-label={Cadenas.cerrarSesion}
            >
              <LogOut className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>
    </header>
  );
};
