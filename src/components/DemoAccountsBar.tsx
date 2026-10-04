import React from 'react';
import { UserCheck, ShieldAlert } from 'lucide-react';
import { CUENTAS_DEMO } from '../constants/fixtures';

interface DemoAccountsBarProps {
  onSelectAccount: (documento: string, clave: string) => void;
  disabled?: boolean;
}

export const DemoAccountsBar: React.FC<DemoAccountsBarProps> = ({ onSelectAccount, disabled = false }) => {
  return (
    <div className="bg-gray-50 dark:bg-gray-800/60 p-3.5 rounded-2xl border border-gray-200 dark:border-gray-700/60 my-4 text-xs">
      <div className="flex items-center justify-between mb-2">
        <span className="font-semibold text-gray-700 dark:text-gray-300">
          Cuentas demo de prueba rápida (Clave: <code className="text-[#00629E] dark:text-[#9CCAFF]">clave1234</code>):
        </span>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={disabled}
          onClick={() => onSelectAccount('00000001', 'clave1234')}
          className="flex items-center gap-2 p-2 rounded-xl bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 hover:border-[#00629E] dark:hover:border-[#9CCAFF] text-left transition-colors cursor-pointer"
        >
          <UserCheck className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
          <div className="truncate">
            <p className="font-medium text-gray-900 dark:text-white truncate">Paciente Uno</p>
            <p className="text-[10px] text-gray-500 dark:text-gray-400">DNI: 00000001</p>
          </div>
        </button>

        <button
          type="button"
          disabled={disabled}
          onClick={() => onSelectAccount('JCAQUI', 'clave1234')}
          className="flex items-center gap-2 p-2 rounded-xl bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 hover:border-[#00629E] dark:hover:border-[#9CCAFF] text-left transition-colors cursor-pointer"
        >
          <ShieldAlert className="w-4 h-4 text-blue-600 dark:text-blue-400 shrink-0" />
          <div className="truncate">
            <p className="font-medium text-gray-900 dark:text-white truncate">Admin Caqui</p>
            <p className="text-[10px] text-gray-500 dark:text-gray-400">Usuario: JCAQUI</p>
          </div>
        </button>
      </div>
    </div>
  );
};
