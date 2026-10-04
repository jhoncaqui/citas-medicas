import React from 'react';
import { Info } from 'lucide-react';
import { Cadenas } from '../constants/cadenas';

export const AvisoModoDemostracion: React.FC<{ className?: string }> = ({ className = '' }) => {
  return (
    <div
      className={`flex items-start gap-2.5 p-3.5 rounded-xl bg-[#DEE3EB]/40 dark:bg-[#42474E]/30 border border-[#DEE3EB] dark:border-[#42474E] text-[#43474E] dark:text-[#C2C7CF] text-xs ${className}`}
      role="note"
    >
      <Info className="w-4 h-4 text-[#00629E] dark:text-[#9CCAFF] shrink-0 mt-0.5" />
      <span>{Cadenas.avisoDatosFicticios}</span>
    </div>
  );
};
