import React, { useState } from 'react';
import {
  CalendarCheck,
  CheckCircle2,
  FileText,
  MapPin,
  MessageSquare,
  ShieldAlert,
  ShieldCheck,
  Stethoscope,
  TrendingUp,
  Zap,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { TarjetaAccion } from '../components/TarjetaAccion';
import { AvisoModoDemostracion } from '../components/AvisoModoDemostracion';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';
import { useClinic } from '../context/ClinicContext';

interface HomeScreenProps {
  onNavigate: (route: string) => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigate }) => {
  const { paciente, impedimentoPara } = useAuth();
  const {
    especialidades,
    todasEspecialidades,
    activarTodasLasOpcionesYEspecialidades,
    opcionesSistema,
  } = useClinic();

  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const primerNombre = paciente?.nombres.trim().split(' ')[0] || '';
  const consentimientoRevocado = paciente && !paciente.consentimientoOtorgado;
  const esAdministrador = paciente?.rol === 'administrador';

  // Si es administrador, no tiene impedimentos para reservar o consultar
  const impedimentoReservar = esAdministrador ? undefined : impedimentoPara('reservar');
  const impedimentoHistorial = esAdministrador ? undefined : impedimentoPara('consultarHistorial');

  const handleActivarTodas = () => {
    activarTodasLasOpcionesYEspecialidades();
    setToastMsg('⚡ ¡Todas las opciones del sistema y especialidades han sido activadas!');
    setTimeout(() => setToastMsg(null), 3500);
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] pb-12 transition-colors">
      <Navbar
        onOpenPrivacy={() => onNavigate('privacidad')}
        onOpenAdmin={esAdministrador ? () => onNavigate('adminControl') : undefined}
      />

      <main className="max-w-2xl mx-auto px-4 pt-6 space-y-6">
        {/* Toast Notificación */}
        {toastMsg && (
          <div className="p-3.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-300 dark:border-emerald-800 text-xs font-semibold text-emerald-800 dark:text-emerald-200 shadow-sm animate-in fade-in">
            {toastMsg}
          </div>
        )}

        {/* Saludo y bienvenida */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              {primerNombre && (
                <h2 className="text-2xl font-bold text-[#1A1C1E] dark:text-[#E2E2E5] tracking-tight">
                  {Cadenas.saludo}, {primerNombre}
                </h2>
              )}
              {esAdministrador && (
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300 border border-purple-200 dark:border-purple-800">
                  Admin · Control Total
                </span>
              )}
            </div>
            <p className="text-sm text-[#43474E] dark:text-[#C2C7CF] mt-1">
              {Cadenas.descripcionApp}
            </p>
          </div>

          {esAdministrador && (
            <button
              type="button"
              onClick={handleActivarTodas}
              className="px-3.5 py-2 rounded-xl bg-amber-400 hover:bg-amber-300 text-amber-950 text-xs font-bold transition-all shadow-xs flex items-center gap-1.5 cursor-pointer self-start sm:self-auto shrink-0"
              title="Activar todas las opciones y especialidades de la clínica"
            >
              <Zap className="w-4 h-4 fill-amber-950" />
              <span>Activar Opciones</span>
            </button>
          )}
        </div>

        {/* Aviso de modo demostración */}
        {opcionesSistema.modoDemoActivo && <AvisoModoDemostracion />}

        {/* Banner de Control Total para Administradores */}
        {esAdministrador && (
          <div className="p-4 rounded-2xl bg-gradient-to-r from-purple-900 to-indigo-900 text-white shadow-md flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-xl bg-white/10">
                <ShieldCheck className="w-5 h-5 text-amber-300" />
              </div>
              <div>
                <h3 className="font-bold text-xs tracking-wide uppercase text-amber-300">
                  Modo Administrador Habilitado
                </h3>
                <p className="text-xs text-purple-100 mt-0.5">
                  Tienes acceso total a citas, especialidades, médicos, cuentas y opciones.
                </p>
              </div>
            </div>
            <button
              type="button"
              onClick={() => onNavigate('adminControl')}
              className="px-3 py-1.5 rounded-xl bg-white text-purple-950 text-xs font-bold hover:bg-purple-50 transition-colors cursor-pointer shrink-0 shadow-xs"
            >
              Abrir Panel Admin
            </button>
          </div>
        )}

        {/* RN-10: Aviso si revocó consentimiento */}
        {consentimientoRevocado && (
          <div className="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-300 dark:border-amber-800 text-xs">
            <div className="flex items-start gap-2.5">
              <ShieldAlert className="w-5 h-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-amber-900 dark:text-amber-200">
                  {Cadenas.consentimientoRevocado}
                </p>
                <p className="text-amber-700 dark:text-amber-300 mt-1">
                  Para poder reservar o gestionar citas necesitas autorizar el tratamiento de datos.
                </p>
                <button
                  type="button"
                  onClick={() => onNavigate('privacidad')}
                  className="mt-2.5 inline-flex items-center px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-700 text-white font-medium text-xs transition-colors cursor-pointer"
                >
                  {Cadenas.tituloPrivacidad}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tarjetas de Acción principales */}
        <div className="space-y-3 pt-2">
          {/* Panel de Control Total (Solo Administradores) */}
          {esAdministrador && (
            <TarjetaAccion
              titulo="Panel de Control Total (Admin)"
              detalle="Gestiona todas las citas, catálogo de especialidades, equipo médico, cuentas y opciones del sistema."
              icono={<ShieldCheck className="w-6 h-6" />}
              destacada={true}
              onPressed={() => onNavigate('adminControl')}
            />
          )}

          {/* Reservar conversando */}
          <TarjetaAccion
            titulo="Reservar conversando (Voz y Texto)"
            detalle="Habla por micrófono o escribe en lenguaje natural para agendar tu cita médica."
            icono={<MessageSquare className="w-6 h-6" />}
            destacada={!esAdministrador && !impedimentoReservar}
            impedimento={impedimentoReservar}
            onPressed={() => onNavigate('conversacion')}
          />

          {/* Reservar paso a paso */}
          <TarjetaAccion
            titulo={Cadenas.reservarPasoAPaso}
            detalle={Cadenas.reservarPasoAPasoDetalle}
            icono={<FileText className="w-6 h-6" />}
            impedimento={impedimentoReservar}
            onPressed={() => onNavigate('flujoGuiado')}
          />

          {/* Mis citas */}
          <TarjetaAccion
            titulo={esAdministrador ? 'Mis Citas / Citas de la Clínica' : Cadenas.misCitas}
            detalle={
              esAdministrador
                ? 'Revisa y gestiona tus citas o consulta todas las de la clínica'
                : Cadenas.misCitasDetalle
            }
            icono={<CalendarCheck className="w-6 h-6" />}
            impedimento={impedimentoHistorial}
            onPressed={() => onNavigate('misCitas')}
          />

          {/* Panel de Indicadores (Solo Administradores - HU-11) */}
          {esAdministrador && (
            <TarjetaAccion
              titulo={Cadenas.tituloIndicadores}
              detalle={Cadenas.indicadorAutogestion}
              icono={<TrendingUp className="w-6 h-6" />}
              onPressed={() => onNavigate('indicadores')}
            />
          )}

          {/* Ubicación de sedes */}
          <TarjetaAccion
            titulo={Cadenas.ubicacionSedes}
            detalle={Cadenas.ubicacionSedesDetalle}
            icono={<MapPin className="w-6 h-6" />}
            onPressed={() => onNavigate('ubicacion')}
          />
        </div>

        {/* Catálogo de especialidades disponibles */}
        <div className="pt-6">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Stethoscope className="w-5 h-5 text-[#00629E] dark:text-[#9CCAFF]" />
              <h3 className="font-bold text-base text-[#1A1C1E] dark:text-[#E2E2E5]">
                {Cadenas.especialidadesDisponibles} ({especialidades.length})
              </h3>
            </div>
            {esAdministrador && todasEspecialidades.length > especialidades.length && (
              <button
                type="button"
                onClick={handleActivarTodas}
                className="text-xs font-semibold text-[#00629E] dark:text-[#9CCAFF] hover:underline cursor-pointer"
              >
                Activar todas ({todasEspecialidades.length})
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 gap-2.5">
            {especialidades.map((esp) => (
              <div
                key={esp.id}
                className="p-4 rounded-2xl bg-white dark:bg-[#1E2124] border border-gray-200 dark:border-gray-800 shadow-xs flex items-start gap-3.5"
              >
                <div className="p-2.5 rounded-xl bg-blue-50 dark:bg-blue-950/50 text-[#00629E] dark:text-[#9CCAFF] shrink-0">
                  <CheckCircle2 className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-semibold text-sm text-[#1A1C1E] dark:text-[#E2E2E5]">
                    {esp.nombre}
                  </h4>
                  <p className="text-xs text-[#43474E] dark:text-[#C2C7CF] mt-0.5 leading-relaxed">
                    {esp.descripcion}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
};

