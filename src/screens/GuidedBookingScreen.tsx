import React, { useEffect, useState } from 'react';
import {
  Calendar,
  CheckCircle2,
  Clock,
  FileCheck2,
  Loader2,
  MapPin,
  Stethoscope,
  User,
  Users,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';
import { useClinic } from '../context/ClinicContext';
import { Cita, CupoDisponible, Especialidad, PasoReserva, Profesional } from '../types';
import { FormatoFecha } from '../utils/fechasNaturales';
import { Rn04NoEnElPasado, Rn05SinDuplicados } from '../domain/rules/rn03_rn04_rn05Reserva';
import { Rn06Autogestion } from '../domain/rules/rn06_rn07_rn08Gestion';

interface GuidedBookingScreenProps {
  onBack: () => void;
  onBookingSuccess: () => void;
  initialData?: {
    especialidadId?: string;
    fecha?: Date;
    turno?: 'manana' | 'tarde';
    profesionalId?: string;
    cupo?: CupoDisponible;
    cupoId?: string;
    irAConfirmacion?: boolean;
  };
  citaAReprogramar?: Cita | null;
}

export const GuidedBookingScreen: React.FC<GuidedBookingScreenProps> = ({
  onBack,
  onBookingSuccess,
  initialData,
  citaAReprogramar,
}) => {
  const { paciente, impedimentoPara } = useAuth();
  const {
    especialidades,
    profesionales,
    sedes,
    consultorios,
    citas,
    obtenerCuposDisponibles,
    confirmarReserva,
    reprogramarCita,
    especialidadDe,
    profesionalDe,
    sedeDe,
    consultorioDe,
  } = useClinic();

  const [paso, setPaso] = useState<PasoReserva>('especialidad');
  const [especialidad, setEspecialidad] = useState<Especialidad | null>(null);
  const [profesional, setProfesional] = useState<Profesional | null>(null);
  const [fecha, setFecha] = useState<Date | null>(null);
  const [cupoSeleccionado, setCupoSeleccionado] = useState<CupoDisponible | null>(null);
  const [errorRegla, setErrorRegla] = useState<string | null>(null);
  const [confirmando, setConfirmando] = useState(false);
  const [claveIdempotencia, setClaveIdempotencia] = useState<string>('');

  // Inicialización o prefill desde Asistente o Reprogramación
  useEffect(() => {
    if (citaAReprogramar) {
      const esp = especialidadDe(citaAReprogramar.especialidadId);
      if (esp) {
        setEspecialidad(esp);
        setPaso('fecha');
      }
      return;
    }

    if (initialData?.especialidadId) {
      const esp = especialidadDe(initialData.especialidadId);
      if (esp) setEspecialidad(esp);

      if (initialData.profesionalId) {
        const prof = profesionalDe(initialData.profesionalId);
        if (prof) setProfesional(prof);
      }

      if (initialData.fecha) {
        setFecha(initialData.fecha);
      }

      // Si el usuario ya seleccionó un horario específico (ej: desde la conversación),
      // ir DIRECTAMENTE a la confirmación de la cita sin pedir que vuelva a elegirlo.
      if (initialData.cupo || initialData.cupoId || initialData.irAConfirmacion) {
        const cupoElegido =
          initialData.cupo ||
          (initialData.fecha && initialData.especialidadId
            ? obtenerCuposDisponibles(initialData.especialidadId, initialData.profesionalId, initialData.fecha).find(
                (c) => c.id === initialData.cupoId
              )
            : null);

        if (cupoElegido) {
          setCupoSeleccionado(cupoElegido);
          setPaso('confirmacion');
          return;
        }
      }

      if (initialData.fecha) {
        setPaso('horario');
      } else {
        setPaso('fecha');
      }
    }
  }, [initialData, citaAReprogramar]);

  const pasoNumero =
    paso === 'especialidad'
      ? 1
      : paso === 'profesional'
      ? 2
      : paso === 'fecha'
      ? 3
      : paso === 'horario'
      ? 4
      : 5;

  const handleRetroceder = () => {
    setErrorRegla(null);
    if (paso === 'confirmacion') setPaso('horario');
    else if (paso === 'horario') setPaso('fecha');
    else if (paso === 'fecha') {
      if (citaAReprogramar) onBack();
      else setPaso('profesional');
    } else if (paso === 'profesional') setPaso('especialidad');
    else onBack();
  };

  // Obtener fechas válidas de los próximos 14 días (sin domingos, RN-04)
  const ahora = new Date();
  const diasDisponibles: Date[] = [];
  for (let i = 1; i <= 14; i++) {
    const d = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate() + i);
    if (d.getDay() !== 0) {
      diasDisponibles.push(d);
    }
  }

  // Lista de cupos para la especialidad, profesional y fecha seleccionados
  // Filtramos estrictamente SOLO los horarios disponibles (disponible === true)
  const cupos = (
    especialidad && fecha
      ? obtenerCuposDisponibles(especialidad.id, profesional?.id, fecha)
      : []
  ).filter((c) => c.disponible);

  const cuposManana = cupos.filter((c) => new Date(c.fechaHoraInicio).getHours() < 12);
  const cuposTarde = cupos.filter((c) => new Date(c.fechaHoraInicio).getHours() >= 12);

  const handleElegirCupo = (c: CupoDisponible) => {
    const valRn04 = Rn04NoEnElPasado.validar(c.fechaHoraInicio, ahora);
    if (valRn04.infringida) {
      setErrorRegla(valRn04.mensaje || 'Horario no válido.');
      return;
    }
    setErrorRegla(null);
    setCupoSeleccionado(c);
  };

  const handleAvanzarAConfirmacion = () => {
    if (!cupoSeleccionado) return;
    setErrorRegla(null);
    if (!claveIdempotencia) {
      setClaveIdempotencia(`idemp-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`);
    }
    setPaso('confirmacion');
  };

  const handleConfirmarCita = async () => {
    if (!paciente || !cupoSeleccionado || !especialidad) return;

    // Validación RN-01
    const impedimento = impedimentoPara('reservar');
    if (impedimento) {
      setErrorRegla(impedimento);
      return;
    }

    // Validación RN-04
    const valRn04 = Rn04NoEnElPasado.validar(cupoSeleccionado.fechaHoraInicio, new Date());
    if (valRn04.infringida) {
      setErrorRegla(valRn04.mensaje || 'El horario seleccionado ya no está disponible.');
      return;
    }

    // Validación RN-06 si es reprogramación
    if (citaAReprogramar) {
      const valRn06 = Rn06Autogestion.validar(citaAReprogramar, 'reprogramar', new Date());
      if (valRn06.infringida) {
        setErrorRegla(valRn06.mensaje || 'Plazo de reprogramación vencido.');
        return;
      }
    }

    // Validación RN-05 (sin duplicados con mismo doctor/esp el mismo día)
    const citasPaciente = citas.filter((c) => c.pacienteId === paciente.id && c.id !== citaAReprogramar?.id);
    const valRn05 = Rn05SinDuplicados.validar(
      especialidad.id,
      cupoSeleccionado.profesionalId,
      cupoSeleccionado.fechaHoraInicio,
      citasPaciente
    );
    if (valRn05.infringida) {
      setErrorRegla(valRn05.mensaje || 'Ya tienes una cita ese día con ese profesional.');
      return;
    }

    setConfirmando(true);
    setErrorRegla(null);

    const canal = initialData ? 'conversacional' : 'flujo_guiado';

    try {
      if (citaAReprogramar) {
        const res = await reprogramarCita(citaAReprogramar.id, cupoSeleccionado);
        if (res.ok) {
          onBookingSuccess();
        } else {
          setErrorRegla(res.error || 'Error al reprogramar la cita.');
        }
      } else {
        const res = await confirmarReserva(paciente.id, cupoSeleccionado, canal, claveIdempotencia);
        if (res.ok) {
          onBookingSuccess();
        } else {
          setErrorRegla(res.error || 'Error al confirmar la reserva.');
        }
      }
    } finally {
      setConfirmando(false);
    }
  };

  const tituloPaso =
    paso === 'especialidad'
      ? Cadenas.pasoEspecialidad
      : paso === 'profesional'
      ? Cadenas.pasoProfesional
      : paso === 'fecha'
      ? Cadenas.pasoFecha
      : paso === 'horario'
      ? Cadenas.pasoHorario
      : Cadenas.pasoConfirmacion;

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] flex flex-col transition-colors pb-16">
      <Navbar titulo={tituloPaso} onBack={handleRetroceder} />

      {/* Barra de progreso */}
      <div className="w-full bg-gray-200 dark:bg-gray-800 h-1.5">
        <div
          className="bg-[#00629E] dark:bg-[#9CCAFF] h-1.5 transition-all duration-300"
          style={{ width: `${(pasoNumero / 5) * 100}%` }}
        />
      </div>

      <main className="max-w-2xl w-full mx-auto px-4 py-6 flex-1 flex flex-col">
        {errorRegla && (
          <div
            className="mb-4 p-3.5 rounded-2xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 text-xs text-red-700 dark:text-red-300 font-medium"
            role="alert"
          >
            {errorRegla}
          </div>
        )}

        {/* Paso 1: Especialidad */}
        {paso === 'especialidad' && (
          <div className="space-y-3">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
              Selecciona la especialidad médica para tu consulta:
            </p>
            {especialidades.map((esp) => (
              <button
                key={esp.id}
                type="button"
                onClick={() => {
                  setEspecialidad(esp);
                  setProfesional(null);
                  setCupoSeleccionado(null);
                  setPaso('profesional');
                }}
                className={`w-full p-4 rounded-2xl border text-left flex items-start gap-4 transition-all cursor-pointer ${
                  especialidad?.id === esp.id
                    ? 'border-[#00629E] bg-blue-50/50 dark:bg-blue-950/30 dark:border-[#9CCAFF]'
                    : 'bg-white dark:bg-[#1E2124] border-gray-200 dark:border-gray-800 hover:border-gray-400'
                }`}
              >
                <div className="p-3 rounded-xl bg-blue-50 dark:bg-blue-950 text-[#00629E] dark:text-[#9CCAFF] shrink-0">
                  <Stethoscope className="w-5 h-5" />
                </div>
                <div className="flex-1">
                  <h4 className="font-semibold text-sm text-gray-900 dark:text-white">
                    {esp.nombre}
                  </h4>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 leading-relaxed">
                    {esp.descripcion}
                  </p>
                </div>
              </button>
            ))}
          </div>
        )}

        {/* Paso 2: Profesional */}
        {paso === 'profesional' && (
          <div className="space-y-3">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
              Puedes elegir un médico en particular o cualquier profesional disponible:
            </p>

            <button
              type="button"
              onClick={() => {
                setProfesional(null);
                setCupoSeleccionado(null);
                setPaso('fecha');
              }}
              className={`w-full p-4 rounded-2xl border text-left flex items-center gap-4 transition-all cursor-pointer ${
                profesional === null
                  ? 'border-[#00629E] bg-blue-50/50 dark:bg-blue-950/30 dark:border-[#9CCAFF]'
                  : 'bg-white dark:bg-[#1E2124] border-gray-200 dark:border-gray-800 hover:border-gray-400'
              }`}
            >
              <div className="p-3 rounded-xl bg-blue-50 dark:bg-blue-950 text-[#00629E] dark:text-[#9CCAFF] shrink-0">
                <Users className="w-5 h-5" />
              </div>
              <div className="flex-1">
                <h4 className="font-semibold text-sm text-gray-900 dark:text-white">
                  {Cadenas.cualquierProfesional}
                </h4>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  Te mostramos todos los horarios de la especialidad.
                </p>
              </div>
            </button>

            {profesionales
              .filter((p) => p.especialidadId === especialidad?.id)
              .map((prof) => (
                <button
                  key={prof.id}
                  type="button"
                  onClick={() => {
                    setProfesional(prof);
                    setCupoSeleccionado(null);
                    setPaso('fecha');
                  }}
                  className={`w-full p-4 rounded-2xl border text-left flex items-center gap-4 transition-all cursor-pointer ${
                    profesional?.id === prof.id
                      ? 'border-[#00629E] bg-blue-50/50 dark:bg-blue-950/30 dark:border-[#9CCAFF]'
                      : 'bg-white dark:bg-[#1E2124] border-gray-200 dark:border-gray-800 hover:border-gray-400'
                  }`}
                >
                  <div className="p-3 rounded-xl bg-gray-100 dark:bg-gray-800 text-[#00629E] dark:text-[#9CCAFF] shrink-0">
                    <User className="w-5 h-5" />
                  </div>
                  <div className="flex-1">
                    <h4 className="font-semibold text-sm text-gray-900 dark:text-white">
                      Dr(a). {prof.nombres} {prof.apellidos}
                    </h4>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                      Colegiatura: {prof.colegiatura}
                    </p>
                  </div>
                </button>
              ))}
          </div>
        )}

        {/* Paso 3: Fecha */}
        {paso === 'fecha' && (
          <div className="space-y-2.5">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
              Elige el día de tu cita (atención de lunes a sábado). Solo se muestran horarios con cupos libres:
            </p>
            {diasDisponibles.map((dia) => {
              const esSeleccionado =
                fecha?.getFullYear() === dia.getFullYear() &&
                fecha?.getMonth() === dia.getMonth() &&
                fecha?.getDate() === dia.getDate();

              const cuposDisponiblesDia = especialidad
                ? obtenerCuposDisponibles(especialidad.id, profesional?.id, dia).filter((c) => c.disponible).length
                : 0;

              return (
                <button
                  key={dia.toISOString()}
                  type="button"
                  onClick={() => {
                    setFecha(dia);
                    setCupoSeleccionado(null);
                    setPaso('horario');
                  }}
                  className={`w-full p-3.5 rounded-2xl border text-left flex items-center justify-between transition-all cursor-pointer ${
                    esSeleccionado
                      ? 'border-[#00629E] bg-blue-50/50 dark:bg-blue-950/30 dark:border-[#9CCAFF]'
                      : 'bg-white dark:bg-[#1E2124] border-gray-200 dark:border-gray-800 hover:border-gray-400'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 rounded-xl bg-blue-50 dark:bg-blue-950 text-[#00629E] dark:text-[#9CCAFF]">
                      <Calendar className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-semibold text-sm text-gray-900 dark:text-white">
                        {FormatoFecha.fechaLarga(dia)}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {FormatoFecha.fechaCorta(dia)}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {cuposDisponiblesDia > 0 ? (
                      <span className="text-xs font-semibold text-emerald-700 dark:text-emerald-300 bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-1 rounded-full border border-emerald-200 dark:border-emerald-800 flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                        {cuposDisponiblesDia} disponibles
                      </span>
                    ) : (
                      <span className="text-xs font-medium text-gray-400 dark:text-gray-500 bg-gray-100 dark:bg-gray-800 px-2.5 py-1 rounded-full">
                        Sin cupos
                      </span>
                    )}
                    <span className="text-xs font-semibold text-[#00629E] dark:text-[#9CCAFF]">
                      Ver horarios →
                    </span>
                  </div>
                </button>
              );
            })}
          </div>
        )}

        {/* Paso 4: Horario (HU-05) */}
        {paso === 'horario' && (
          <div className="space-y-6 flex-1 flex flex-col">
            {fecha && (
              <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-gray-200 dark:border-gray-800 gap-2">
                <div>
                  <span className="text-sm font-semibold text-gray-900 dark:text-white block">
                    {FormatoFecha.fechaLarga(fecha)}
                  </span>
                  <span className="text-xs text-emerald-600 dark:text-emerald-400 font-medium">
                    {cupos.length} {cupos.length === 1 ? 'horario disponible' : 'horarios disponibles'} para reservar
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setPaso('fecha')}
                  className="text-xs text-[#00629E] dark:text-[#9CCAFF] hover:underline font-semibold cursor-pointer text-left sm:text-right"
                >
                  {Cadenas.cambiar} fecha
                </button>
              </div>
            )}

            {cupos.length === 0 ? (
              <div className="text-center py-12 px-4 rounded-2xl bg-amber-50/50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800">
                <Clock className="w-8 h-8 text-amber-600 dark:text-amber-400 mx-auto mb-2" />
                <h4 className="font-semibold text-sm text-gray-900 dark:text-white">
                  No hay horarios disponibles para esta fecha
                </h4>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-1 max-w-sm mx-auto">
                  Todos los cupos para este día ya han sido ocupados o el horario de atención concluyó.
                </p>
                <button
                  type="button"
                  onClick={() => setPaso('fecha')}
                  className="mt-4 px-4 py-2.5 rounded-xl bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] text-xs font-semibold hover:opacity-90 cursor-pointer shadow-sm"
                >
                  Elegir otra fecha con horarios libres
                </button>
              </div>
            ) : (
              <div className="space-y-6 flex-1">
                {cuposManana.length > 0 && (
                  <div>
                    <h4 className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3 flex items-center justify-between">
                      <span>{Cadenas.turnoManana}</span>
                      <span className="text-[11px] font-normal lowercase text-gray-400">
                        ({cuposManana.length} disponibles)
                      </span>
                    </h4>
                    <div className="grid grid-cols-3 sm:grid-cols-4 gap-2.5">
                      {cuposManana.map((c) => {
                        const seleccionado = cupoSeleccionado?.id === c.id;
                        const horaTexto = FormatoFecha.hora(c.fechaHoraInicio);
                        const prof = profesionalDe(c.profesionalId);

                        return (
                          <button
                            key={c.id}
                            type="button"
                            onClick={() => handleElegirCupo(c)}
                            className={`min-h-[50px] p-2.5 rounded-xl text-center border text-xs font-semibold transition-all cursor-pointer ${
                              seleccionado
                                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] border-transparent shadow-md ring-2 ring-[#00629E]/30 dark:ring-[#9CCAFF]/40'
                                : 'bg-white dark:bg-[#1E2124] text-gray-800 dark:text-gray-200 border-gray-200 dark:border-gray-700 hover:border-[#00629E] dark:hover:border-[#9CCAFF] hover:bg-blue-50/40 dark:hover:bg-blue-950/20'
                            }`}
                          >
                            <span className="block font-bold">{horaTexto}</span>
                            {!profesional && prof && (
                              <span className="text-[10px] block font-normal opacity-80 truncate">
                                Dr(a). {prof.apellidos.split(' ')[0]}
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                )}

                {cuposTarde.length > 0 && (
                  <div>
                    <h4 className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3 flex items-center justify-between">
                      <span>{Cadenas.turnoTarde}</span>
                      <span className="text-[11px] font-normal lowercase text-gray-400">
                        ({cuposTarde.length} disponibles)
                      </span>
                    </h4>
                    <div className="grid grid-cols-3 sm:grid-cols-4 gap-2.5">
                      {cuposTarde.map((c) => {
                        const seleccionado = cupoSeleccionado?.id === c.id;
                        const horaTexto = FormatoFecha.hora(c.fechaHoraInicio);
                        const prof = profesionalDe(c.profesionalId);

                        return (
                          <button
                            key={c.id}
                            type="button"
                            onClick={() => handleElegirCupo(c)}
                            className={`min-h-[50px] p-2.5 rounded-xl text-center border text-xs font-semibold transition-all cursor-pointer ${
                              seleccionado
                                ? 'bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] border-transparent shadow-md ring-2 ring-[#00629E]/30 dark:ring-[#9CCAFF]/40'
                                : 'bg-white dark:bg-[#1E2124] text-gray-800 dark:text-gray-200 border-gray-200 dark:border-gray-700 hover:border-[#00629E] dark:hover:border-[#9CCAFF] hover:bg-blue-50/40 dark:hover:bg-blue-950/20'
                            }`}
                          >
                            <span className="block font-bold">{horaTexto}</span>
                            {!profesional && prof && (
                              <span className="text-[10px] block font-normal opacity-80 truncate">
                                Dr(a). {prof.apellidos.split(' ')[0]}
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>
            )}

            <div className="pt-4 border-t border-gray-200 dark:border-gray-800 space-y-2">
              {cupoSeleccionado && (
                <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 flex items-center justify-between text-xs">
                  <span className="font-semibold text-emerald-800 dark:text-emerald-300">
                    ✓ Horario seleccionado: {FormatoFecha.hora(cupoSeleccionado.fechaHoraInicio)}
                  </span>
                  <span className="text-emerald-700 dark:text-emerald-400 font-medium">
                    Listo para confirmar
                  </span>
                </div>
              )}
              <button
                type="button"
                disabled={!cupoSeleccionado}
                onClick={handleAvanzarAConfirmacion}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-bold text-sm transition-all cursor-pointer disabled:opacity-40 min-h-[48px] shadow-sm flex items-center justify-center gap-2"
              >
                <span>
                  {cupoSeleccionado
                    ? `Continuar con horario ${FormatoFecha.hora(cupoSeleccionado.fechaHoraInicio)} →`
                    : 'Selecciona un horario arriba para continuar'}
                </span>
              </button>
            </div>
          </div>
        )}

        {/* Paso 5: Confirmación (HU-06) */}
        {paso === 'confirmacion' && cupoSeleccionado && (
          <div className="space-y-6 flex-1 flex flex-col">
            <div className="bg-white dark:bg-[#1E2124] rounded-3xl p-6 border border-gray-200 dark:border-gray-800 shadow-sm space-y-4">
              <div className="flex items-center gap-3 pb-3 border-b border-gray-100 dark:border-gray-800">
                <FileCheck2 className="w-6 h-6 text-[#00629E] dark:text-[#9CCAFF]" />
                <h3 className="font-bold text-base text-gray-900 dark:text-white">
                  Resumen de tu cita
                </h3>
              </div>

              <div className="space-y-3 text-sm">
                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteEspecialidad}</span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {especialidad?.nombre}
                  </span>
                </div>

                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteProfesional}</span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {profesionalDe(cupoSeleccionado.profesionalId)?.nombres}{' '}
                    {profesionalDe(cupoSeleccionado.profesionalId)?.apellidos}
                  </span>
                </div>

                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteFecha}</span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {FormatoFecha.fechaLarga(cupoSeleccionado.fechaHoraInicio)}
                  </span>
                </div>

                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteHora}</span>
                  <span className="font-semibold text-[#00629E] dark:text-[#9CCAFF]">
                    {FormatoFecha.hora(cupoSeleccionado.fechaHoraInicio)}
                  </span>
                </div>

                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteSede}</span>
                  <span className="font-semibold text-gray-900 dark:text-white text-right max-w-[200px]">
                    {sedeDe(cupoSeleccionado.sedeId)?.nombre}
                  </span>
                </div>

                <div className="flex justify-between py-1">
                  <span className="text-gray-500 dark:text-gray-400">{Cadenas.comprobanteConsultorio}</span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {consultorioDe(cupoSeleccionado.consultorioId)?.codigo} (Piso{' '}
                    {consultorioDe(cupoSeleccionado.consultorioId)?.piso})
                  </span>
                </div>
              </div>
            </div>

            <div className="p-3.5 rounded-2xl bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-900 text-xs text-blue-900 dark:text-blue-300">
              {Cadenas.recordatorioProgramado}
            </div>

            <div className="mt-auto pt-4">
              <button
                type="button"
                disabled={confirmando}
                onClick={handleConfirmarCita}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-sm transition-all cursor-pointer flex items-center justify-center gap-2 min-h-[48px]"
              >
                {confirmando ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>{Cadenas.reservandoEspera}</span>
                  </>
                ) : (
                  <span>
                    {citaAReprogramar ? 'Confirmar reprogramación' : Cadenas.confirmarReserva}
                  </span>
                )}
              </button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
};
