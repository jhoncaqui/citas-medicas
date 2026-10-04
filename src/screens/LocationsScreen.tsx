import React, { useState } from 'react';
import { ExternalLink, Info, MapPin, Navigation } from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { useClinic } from '../context/ClinicContext';
import { Sede } from '../types';

interface LocationsScreenProps {
  onBack: () => void;
}

export const LocationsScreen: React.FC<LocationsScreenProps> = ({ onBack }) => {
  const { sedes, consultorios } = useClinic();
  const [sedeSeleccionada, setSedeSeleccionada] = useState<Sede>(sedes[0] || null);

  const consultoriosDeSede = consultorios.filter((c) => c.sedeId === sedeSeleccionada?.id);

  const handleAbrirMapas = () => {
    if (!sedeSeleccionada) return;
    const url = `https://www.google.com/maps/search/?api=1&query=${sedeSeleccionada.latitud},${sedeSeleccionada.longitud}`;
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-16 transition-colors">
      <Navbar titulo={Cadenas.ubicacionSedes} onBack={onBack} />

      <main className="max-w-2xl mx-auto px-4 py-6 space-y-6">
        {/* Selector de Sedes (Chips) */}
        {sedes.length > 1 && (
          <div className="flex gap-2 overflow-x-auto pb-1">
            {sedes.map((s) => {
              const activa = s.id === sedeSeleccionada?.id;
              return (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => setSedeSeleccionada(s)}
                  className={`px-4 py-2.5 rounded-2xl text-xs font-semibold whitespace-nowrap transition-colors border cursor-pointer ${
                    activa
                      ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] border-transparent shadow-xs'
                      : 'bg-white dark:bg-[#1E2124] text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-800 hover:border-gray-400'
                  }`}
                >
                  {s.nombre}
                </button>
              );
            })}
          </div>
        )}

        {sedeSeleccionada && (
          <div className="space-y-6">
            {/* Mapa Interactivo / Canvas */}
            <div className="rounded-3xl overflow-hidden border border-gray-200 dark:border-gray-800 bg-slate-100 dark:bg-slate-900 shadow-sm relative h-64 flex flex-col items-center justify-center p-6 text-center">
              {/* Mapa estilizado */}
              <div
                className="absolute inset-0 opacity-40 dark:opacity-25 bg-[radial-gradient(#00629e_1px,transparent_1px)] [background-size:16px_16px]"
                aria-hidden="true"
              />

              <div className="relative z-10 flex flex-col items-center">
                <div className="p-3.5 rounded-full bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] shadow-lg animate-bounce">
                  <MapPin className="w-6 h-6" />
                </div>
                <h4 className="font-bold text-sm text-gray-900 dark:text-white mt-2">
                  {sedeSeleccionada.nombre}
                </h4>
                <p className="text-xs text-gray-600 dark:text-gray-400 max-w-xs mt-1">
                  Lat: {sedeSeleccionada.latitud.toFixed(4)}, Lng: {sedeSeleccionada.longitud.toFixed(4)}
                </p>
                <button
                  type="button"
                  onClick={handleAbrirMapas}
                  className="mt-3 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/90 dark:bg-gray-800/90 text-[#00629E] dark:text-[#9CCAFF] font-semibold text-xs border border-gray-200 dark:border-gray-700 shadow-xs hover:bg-white cursor-pointer"
                >
                  <Navigation className="w-3.5 h-3.5" />
                  <span>Ver en Google Maps</span>
                </button>
              </div>
            </div>

            {/* Datos detallados de la sede */}
            <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 border border-gray-200 dark:border-gray-800 shadow-sm space-y-4">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                {sedeSeleccionada.nombre}
              </h3>

              <div className="space-y-3 text-xs">
                <div>
                  <span className="font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider block mb-1">
                    {Cadenas.direccion}
                  </span>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">
                    {sedeSeleccionada.direccion}
                  </p>
                </div>

                {sedeSeleccionada.referencia && (
                  <div>
                    <span className="font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider block mb-1">
                      {Cadenas.referencia}
                    </span>
                    <p className="text-xs text-gray-700 dark:text-gray-300 leading-relaxed">
                      {sedeSeleccionada.referencia}
                    </p>
                  </div>
                )}

                {consultoriosDeSede.length > 0 && (
                  <div>
                    <span className="font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider block mb-1.5">
                      {Cadenas.comprobanteConsultorio}s en esta sede
                    </span>
                    <div className="grid grid-cols-2 gap-2 pt-1">
                      {consultoriosDeSede.map((c) => (
                        <div
                          key={c.id}
                          className="p-2.5 rounded-xl bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700/60"
                        >
                          <span className="font-semibold text-sm text-gray-900 dark:text-white block">
                            {c.codigo}
                          </span>
                          <span className="text-[11px] text-gray-500 dark:text-gray-400">
                            Piso {c.piso}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={handleAbrirMapas}
                  className="w-full py-3 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-xs transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-sm"
                >
                  <ExternalLink className="w-4 h-4" />
                  <span>{Cadenas.abrirEnMapas}</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
};
