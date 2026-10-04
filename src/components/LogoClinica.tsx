import React, { useState } from 'react';

interface LogoClinicaProps {
  alto?: number;
}

export const LogoClinica: React.FC<LogoClinicaProps> = ({ alto = 84 }) => {
  const [errorCarga, setErrorCarga] = useState(false);

  if (errorCarga) {
    return (
      <div
        style={{ height: alto, width: alto }}
        className="rounded-2xl border border-gray-300 dark:border-gray-700 bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-[#00629E] dark:text-[#9CCAFF]"
        aria-hidden="true"
      >
        <svg className="w-1/2 h-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1.5}
            d="M19 14l-7 7m0 0l-7-7m7 7V3"
          />
        </svg>
      </div>
    );
  }

  return (
    <div style={{ height: alto }} className="flex items-center justify-center">
      <img
        src="/assets/images/logo.png"
        alt="Logo de la clínica"
        style={{ maxHeight: alto }}
        className="object-contain"
        onError={() => setErrorCarga(true)}
      />
    </div>
  );
};

interface CabeceraConLogoProps {
  titulo: string;
  subtitulo: string;
  altoLogo?: number;
}

export const CabeceraConLogo: React.FC<CabeceraConLogoProps> = ({ titulo, subtitulo, altoLogo = 80 }) => {
  return (
    <div className="flex flex-col items-center text-center mb-6">
      <LogoClinica alto={altoLogo} />
      <h1 className="text-2xl font-bold mt-4 text-[#1A1C1E] dark:text-[#E2E2E5] tracking-tight">
        {titulo}
      </h1>
      <p className="text-sm text-[#43474E] dark:text-[#C2C7CF] mt-1 max-w-sm">
        {subtitulo}
      </p>
    </div>
  );
};
