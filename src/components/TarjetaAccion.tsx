import React from 'react';
import { ChevronRight } from 'lucide-react';

interface TarjetaAccionProps {
  titulo: string;
  detalle: string;
  icono: React.ReactNode;
  destacada?: boolean;
  onPressed?: () => void;
  impedimento?: string | null;
  className?: string;
}

export const TarjetaAccion: React.FC<TarjetaAccionProps> = ({
  titulo,
  detalle,
  icono,
  destacada = false,
  onPressed,
  impedimento,
  className = '',
}) => {
  const deshabilitada = !!impedimento;

  return (
    <button
      type="button"
      onClick={deshabilitada ? undefined : onPressed}
      disabled={deshabilitada && !onPressed}
      className={`w-full text-left p-4 rounded-2xl transition-all duration-200 border flex items-center gap-4 cursor-pointer focus:outline-none focus:ring-2 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF] ${
        destacada
          ? 'bg-[#CFE5FF] dark:bg-[#004A78] text-[#001D33] dark:text-[#CFE5FF] border-[#9CCAFF] dark:border-[#00629E] shadow-sm hover:shadow-md hover:bg-[#b8d9ff] dark:hover:bg-[#005a92]'
          : 'bg-white dark:bg-[#1E2124] text-[#1A1C1E] dark:text-[#E2E2E5] border-gray-200 dark:border-gray-800 shadow-sm hover:border-[#00629E] dark:hover:border-[#9CCAFF] hover:bg-gray-50 dark:hover:bg-[#25292E]'
      } ${
        deshabilitada
          ? 'opacity-85 border-amber-300 dark:border-amber-700 bg-amber-50/50 dark:bg-amber-950/20'
          : ''
      } ${className}`}
    >
      <div
        className={`p-3 rounded-xl shrink-0 ${
          destacada
            ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258]'
            : 'bg-gray-100 dark:bg-gray-800 text-[#00629E] dark:text-[#9CCAFF]'
        }`}
      >
        {icono}
      </div>

      <div className="flex-1 min-w-0">
        <h3 className="font-semibold text-base leading-tight truncate">{titulo}</h3>
        <p
          className={`text-xs mt-1 line-clamp-2 ${
            impedimento
              ? 'text-amber-700 dark:text-amber-400 font-medium'
              : destacada
              ? 'text-[#001D33]/80 dark:text-[#CFE5FF]/80'
              : 'text-[#43474E] dark:text-[#C2C7CF]'
          }`}
        >
          {impedimento || detalle}
        </p>
      </div>

      <ChevronRight
        className={`w-5 h-5 shrink-0 transition-transform ${
          destacada
            ? 'text-[#001D33] dark:text-[#CFE5FF]'
            : 'text-gray-400 dark:text-gray-500'
        }`}
      />
    </button>
  );
};
