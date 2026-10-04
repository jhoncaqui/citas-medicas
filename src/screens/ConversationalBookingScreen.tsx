import React, { useEffect, useRef, useState } from 'react';
import {
  ArrowLeft,
  Bot,
  Calendar,
  CheckCircle2,
  Clock,
  ListOrdered,
  Mic,
  MicOff,
  Radio,
  Send,
  Sparkles,
  Stethoscope,
  StopCircle,
  User,
  Volume2,
  VolumeX,
} from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Cadenas } from '../constants/cadenas';
import { CupoDisponible, MensajeConversacion } from '../types';
import { AsistenteService } from '../services/asistenteService';
import { FormatoFecha } from '../utils/fechasNaturales';
import { useClinic } from '../context/ClinicContext';
import { VoiceService } from '../services/voiceService';

interface ConversationalBookingScreenProps {
  onBack: () => void;
  onBookingSuccess?: () => void;
  onGoToGuided: (prefill?: {
    especialidadId?: string;
    fecha?: Date;
    turno?: 'manana' | 'tarde';
    profesionalId?: string;
    cupo?: CupoDisponible;
    cupoId?: string;
    irAConfirmacion?: boolean;
  }) => void;
}

const SUGERENCIAS_VOZ = [
  'Cita en Medicina General para mañana por la tarde',
  'Quiero atenderme con Pediatría este lunes',
  'Consulta de Dermatología para este viernes',
  'Cita con el doctor Carlos Ramírez',
];

export const ConversationalBookingScreen: React.FC<ConversationalBookingScreenProps> = ({
  onBack,
  onGoToGuided,
}) => {
  const { especialidades, especialidadDe, obtenerCuposDisponibles, profesionalDe } = useClinic();

  const [mensajes, setMensajes] = useState<MensajeConversacion[]>([
    {
      id: 'msg-0',
      rol: 'asistente',
      texto: Cadenas.asistenteSaludo,
      marcaTiempo: new Date().toISOString(),
    },
  ]);

  const [inputTexto, setInputTexto] = useState('');
  const [procesando, setProcesando] = useState(false);
  const [intentosFallidos, setIntentosFallidos] = useState(0);
  const [fechaPorConfirmar, setFechaPorConfirmar] = useState<Date | null>(null);
  const [entidadesPendientes, setEntidadesPendientes] = useState<Record<string, string>>({});

  // Horarios disponibles sugeridos en el chat
  const [cuposSugeridosInfo, setCuposSugeridosInfo] = useState<{
    fecha: Date;
    especialidadId: string;
    profesionalId?: string;
    cupos: CupoDisponible[];
  } | null>(null);

  // Estados de voz
  const [escuchando, setEscuchando] = useState(false);
  const [interimTranscript, setInterimTranscript] = useState('');
  const [vozAutoActiva, setVozAutoActiva] = useState(true);
  const [mensajeReproduciendoId, setMensajeReproduciendoId] = useState<string | null>(null);
  const [mensajeVozError, setMensajeVozError] = useState<string | null>(null);

  const interimTranscriptRef = useRef('');
  const soporteReconocimiento = VoiceService.isRecognitionSupported();
  const soporteSintesis = VoiceService.isSynthesisSupported();

  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [mensajes, fechaPorConfirmar, cuposSugeridosInfo, escuchando, interimTranscript]);

  // Al desmontar, detener cualquier audio o escucha activa
  useEffect(() => {
    return () => {
      VoiceService.stopListening();
      VoiceService.stopSpeaking();
    };
  }, []);

  const agregarMensaje = (
    rol: 'paciente' | 'asistente',
    texto: string,
    extra?: { intencion?: any; confianza?: number }
  ) => {
    const nuevoId = `msg-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`;
    setMensajes((prev) => [
      ...prev,
      {
        id: nuevoId,
        rol,
        texto,
        marcaTiempo: new Date().toISOString(),
        intencionDetectada: extra?.intencion,
        confianza: extra?.confianza,
      },
    ]);

    // Si es asistente y la respuesta por voz está activada, leer en voz alta
    if (rol === 'asistente' && vozAutoActiva && soporteSintesis) {
      setMensajeReproduciendoId(nuevoId);
      VoiceService.speak(texto, () => {
        setMensajeReproduciendoId((curr) => (curr === nuevoId ? null : curr));
      });
    }
  };

  const reproducirMensajeManual = (m: MensajeConversacion) => {
    if (mensajeReproduciendoId === m.id) {
      VoiceService.stopSpeaking();
      setMensajeReproduciendoId(null);
    } else {
      VoiceService.stopSpeaking();
      setMensajeReproduciendoId(m.id);
      VoiceService.speak(m.texto, () => {
        setMensajeReproduciendoId((curr) => (curr === m.id ? null : curr));
      });
    }
  };

  const handleEnviar = (textoAEnviar?: string) => {
    const texto = (textoAEnviar || inputTexto).trim();
    if (!texto || procesando) return;

    // Si estaba escuchando, detener
    if (escuchando) {
      VoiceService.stopListening();
      setEscuchando(false);
      setInterimTranscript('');
      interimTranscriptRef.current = '';
    }

    setInputTexto('');
    agregarMensaje('paciente', texto);
    setProcesando(true);

    const normalizado = texto.toLowerCase();

    // 1. Revisar si estamos esperando confirmación verbal de fecha ("sí", "no")
    if (fechaPorConfirmar) {
      const esAfirmativo =
        normalizado.includes('sí') ||
        normalizado.includes('si') ||
        normalizado.includes('correcto') ||
        normalizado.includes('de acuerdo') ||
        normalizado.includes('afirmativo') ||
        normalizado.includes('exacto') ||
        normalizado.includes('claro') ||
        normalizado.includes('por favor') ||
        normalizado.includes('ok') ||
        normalizado.includes('vale') ||
        normalizado.includes('dale') ||
        normalizado.includes('así es') ||
        normalizado.includes('asi es') ||
        normalizado.includes('confirmo') ||
        normalizado.includes('confirma') ||
        normalizado.includes('proceder') ||
        normalizado.includes('adelante') ||
        normalizado.includes('perfecto') ||
        normalizado.includes('está bien') ||
        normalizado.includes('esta bien');

      if (esAfirmativo) {
        handleConfirmarFecha();
        setProcesando(false);
        return;
      }

      const esNegativo =
        normalizado.includes('no') ||
        normalizado.includes('incorrecto') ||
        normalizado.includes('cambiar') ||
        normalizado.includes('otra fecha') ||
        normalizado.includes('otro día') ||
        normalizado.includes('otro dia') ||
        normalizado.includes('cancelar');

      if (esNegativo) {
        handleRechazarFecha();
        setProcesando(false);
        return;
      }
    }

    setTimeout(() => {
      const ahora = new Date();
      const resultado = AsistenteService.analizar(texto, ahora);

      // RN-09: guardarraíl clínico
      if (resultado.derivadoACanalAtencion) {
        agregarMensaje('asistente', resultado.respuesta);
        setProcesando(false);
        return;
      }

      // Saludo simple
      if (resultado.intencion === 'saludo') {
        agregarMensaje('asistente', resultado.respuesta, {
          intencion: resultado.intencion,
          confianza: resultado.confianza,
        });
        setProcesando(false);
        return;
      }

      // Confirmación cuando no había fecha pendiente
      if (resultado.intencion === 'confirmacion') {
        if (fechaPorConfirmar) {
          handleConfirmarFecha();
        } else {
          agregarMensaje(
            'asistente',
            '¡Perfecto! Indícame qué especialidad o médico buscas (por ejemplo Medicina General o Pediatría) y para qué fecha te gustaría tu cita.'
          );
        }
        setProcesando(false);
        return;
      }

      // Si no es reserva ni reconocido
      if (resultado.intencion !== 'reservar') {
        if (resultado.intencion === 'no_reconocida') {
          agregarMensaje('asistente', resultado.respuesta, {
            intencion: resultado.intencion,
            confianza: resultado.confianza,
          });
          setIntentosFallidos((prev) => prev + 1);
        } else {
          agregarMensaje('asistente', Cadenas.asistenteSoloReservas, {
            intencion: resultado.intencion,
            confianza: resultado.confianza,
          });
        }
        setProcesando(false);
        return;
      }

      setIntentosFallidos(0);

      // Combinar entidades acumuladas con las nuevas reconocidas
      const todasEntidades = { ...entidadesPendientes, ...resultado.entidades };
      setEntidadesPendientes(todasEntidades);

      const espInfo = todasEntidades.especialidad ? especialidadDe(todasEntidades.especialidad) : undefined;
      const nombreEspecialidad = espInfo ? espInfo.nombre : '';

      // Si falta la especialidad
      if (!todasEntidades.especialidad) {
        agregarMensaje(
          'asistente',
          '¿Para qué especialidad necesitas la cita? Contamos con Medicina General, Pediatría, Cardiología y Dermatología.'
        );
        setProcesando(false);
        return;
      }

      // Si falta la fecha
      if (!todasEntidades.fecha) {
        const respuestaFecha = nombreEspecialidad
          ? `¡Perfecto! Consulta en ${nombreEspecialidad}. ¿Para qué fecha te gustaría tu cita? (Por ejemplo: mañana, este lunes, o el próximo viernes).`
          : Cadenas.asistenteFaltaFecha;
        agregarMensaje('asistente', respuestaFecha);
        setProcesando(false);
        return;
      }

      // Tenemos especialidad y fecha: pedir confirmación de fecha
      const fecha = new Date(todasEntidades.fecha);
      setFechaPorConfirmar(fecha);
      const detalleCita = nombreEspecialidad
        ? `${Cadenas.asistenteConfirmaFecha}: ${FormatoFecha.fechaLarga(fecha)} en ${nombreEspecialidad}. ¿Es correcto?`
        : `${Cadenas.asistenteConfirmaFecha}: ${FormatoFecha.fechaLarga(fecha)}. ¿Es correcto?`;
      agregarMensaje('asistente', detalleCita);
      setProcesando(false);
    }, 350);
  };

  // Reconocimiento de voz (Speech to Text)
  const toggleEscuchaVoz = () => {
    if (escuchando) {
      VoiceService.stopListening();
      setEscuchando(false);
      const pending = interimTranscriptRef.current.trim();
      interimTranscriptRef.current = '';
      setInterimTranscript('');
      if (pending) {
        handleEnviar(pending);
      }
    } else {
      setMensajeVozError(null);
      VoiceService.stopSpeaking();
      setMensajeReproduciendoId(null);
      interimTranscriptRef.current = '';

      const iniciado = VoiceService.startListening({
        onStart: () => {
          setEscuchando(true);
          setInterimTranscript('');
          interimTranscriptRef.current = '';
        },
        onResult: (trans, isFinal) => {
          interimTranscriptRef.current = trans;
          if (isFinal) {
            setInputTexto(trans);
            setInterimTranscript('');
            setEscuchando(false);
            interimTranscriptRef.current = '';
            setTimeout(() => {
              handleEnviar(trans);
            }, 250);
          } else {
            setInterimTranscript(trans);
          }
        },
        onError: (err) => {
          setEscuchando(false);
          const pending = interimTranscriptRef.current.trim();
          interimTranscriptRef.current = '';
          setInterimTranscript('');
          if (pending) {
            handleEnviar(pending);
          } else {
            setMensajeVozError(err);
            setTimeout(() => setMensajeVozError(null), 4000);
          }
        },
        onEnd: () => {
          setEscuchando(false);
          const pending = interimTranscriptRef.current.trim();
          if (pending) {
            interimTranscriptRef.current = '';
            setInterimTranscript('');
            setInputTexto(pending);
            setTimeout(() => {
              handleEnviar(pending);
            }, 250);
          } else {
            setInterimTranscript('');
          }
        },
      });

      if (!iniciado) {
        setEscuchando(false);
      }
    }
  };

  const handleConfirmarFecha = () => {
    if (!fechaPorConfirmar) return;
    agregarMensaje('paciente', Cadenas.asistenteSiEsCorrecto);

    const f = fechaPorConfirmar;
    const espId = entidadesPendientes.especialidad;
    const turno = entidadesPendientes.turno as 'manana' | 'tarde' | undefined;
    const profId = entidadesPendientes.profesional;

    setFechaPorConfirmar(null);

    // Obtener horarios estrictamente disponibles para esa fecha y especialidad
    const cuposLibres = (espId && f ? obtenerCuposDisponibles(espId, profId, f) : []).filter((c) => c.disponible);

    setCuposSugeridosInfo({
      fecha: f,
      especialidadId: espId,
      profesionalId: profId,
      cupos: cuposLibres,
    });

    const espNombre = espId ? especialidadDe(espId)?.nombre : '';

    setTimeout(() => {
      if (cuposLibres.length > 0) {
        agregarMensaje(
          'asistente',
          `¡Excelente! Para el ${FormatoFecha.fechaLarga(f)} en ${espNombre || 'la consulta'} encontré ${cuposLibres.length} horarios disponibles. Puedes elegir tu horario preferido aquí abajo o continuar:`
        );
      } else {
        agregarMensaje(
          'asistente',
          `Para el ${FormatoFecha.fechaLarga(f)} no quedan horarios disponibles en ${espNombre || 'esta especialidad'}. Puedes elegir otra fecha con el botón a continuación.`
        );
      }
    }, 250);
  };

  const handleRechazarFecha = () => {
    if (!fechaPorConfirmar) return;
    agregarMensaje('paciente', Cadenas.asistenteNoEsCorrecto);
    setFechaPorConfirmar(null);
    setCuposSugeridosInfo(null);

    // Limpiar fecha pendiente
    setEntidadesPendientes((prev) => {
      const copy = { ...prev };
      delete copy.fecha;
      return copy;
    });

    setTimeout(() => {
      agregarMensaje('asistente', Cadenas.asistenteFaltaFecha);
    }, 200);
  };

  const debeOfrecerFlujoGuiado = intentosFallidos >= 2;

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] flex flex-col transition-colors">
      <Navbar titulo={Cadenas.reservarConAsistente} onBack={onBack} />

      {/* Barra de Controles de Voz Superior */}
      <div className="bg-[#DEE3EB]/40 dark:bg-[#2A2E33]/40 border-b border-gray-200 dark:border-gray-800 px-4 py-2 flex items-center justify-between text-xs">
        <div className="flex items-center gap-2">
          <div
            className={`w-2.5 h-2.5 rounded-full ${
              escuchando
                ? 'bg-red-500 animate-ping'
                : soporteReconocimiento
                ? 'bg-emerald-500'
                : 'bg-amber-500'
            }`}
          />
          <span className="font-semibold text-gray-700 dark:text-gray-300">
            {escuchando
              ? '🎙️ Grabando voz... habla con naturalidad'
              : soporteReconocimiento
              ? 'Voz activa (presiona el micrófono)'
              : 'Modo texto activo'}
          </span>
        </div>

        <div className="flex items-center gap-2">
          {soporteSintesis && (
            <button
              type="button"
              onClick={() => {
                const nuevo = !vozAutoActiva;
                setVozAutoActiva(nuevo);
                if (!nuevo) VoiceService.stopSpeaking();
              }}
              className={`flex items-center gap-1 px-2.5 py-1 rounded-xl font-semibold transition-colors cursor-pointer ${
                vozAutoActiva
                  ? 'bg-blue-100 text-[#00629E] dark:bg-blue-950 dark:text-[#9CCAFF]'
                  : 'text-gray-500 hover:text-gray-800 dark:hover:text-gray-200'
              }`}
              title={vozAutoActiva ? 'Desactivar voz del asistente' : 'Activar voz del asistente'}
            >
              {vozAutoActiva ? <Volume2 className="w-3.5 h-3.5" /> : <VolumeX className="w-3.5 h-3.5" />}
              <span>{vozAutoActiva ? 'Voz activada' : 'Voz silenciada'}</span>
            </button>
          )}
        </div>
      </div>

      {/* Banner de error de voz si ocurriera */}
      {mensajeVozError && (
        <div className="bg-amber-50 dark:bg-amber-950/50 border-b border-amber-200 dark:border-amber-800 px-4 py-2 text-xs text-amber-800 dark:text-amber-200 flex items-center justify-between animate-in fade-in">
          <span>{mensajeVozError}</span>
          <button
            type="button"
            onClick={() => setMensajeVozError(null)}
            className="text-amber-900 dark:text-amber-100 font-bold ml-2 cursor-pointer"
          >
            ✕
          </button>
        </div>
      )}

      {/* Lista de mensajes */}
      <div className="flex-1 max-w-2xl w-full mx-auto p-4 overflow-y-auto space-y-3">
        {mensajes.map((m) => {
          const esPaciente = m.rol === 'paciente';
          const estaReproduciendo = mensajeReproduciendoId === m.id;

          return (
            <div
              key={m.id}
              className={`flex flex-col ${esPaciente ? 'items-end' : 'items-start'}`}
            >
              <div className="flex items-start gap-1.5 max-w-[88%]">
                {!esPaciente && soporteSintesis && (
                  <button
                    type="button"
                    onClick={() => reproducirMensajeManual(m)}
                    className={`mt-1 p-1.5 rounded-full transition-colors cursor-pointer shrink-0 ${
                      estaReproduciendo
                        ? 'bg-blue-600 text-white animate-pulse'
                        : 'text-gray-400 hover:text-[#00629E] dark:hover:text-[#9CCAFF] hover:bg-gray-100 dark:hover:bg-gray-800'
                    }`}
                    title={estaReproduciendo ? 'Detener lectura' : 'Escuchar mensaje'}
                  >
                    {estaReproduciendo ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
                  </button>
                )}

                <div
                  className={`rounded-2xl px-4 py-3 text-sm leading-relaxed ${
                    esPaciente
                      ? 'bg-[#CFE5FF] dark:bg-[#004A78] text-[#001D33] dark:text-[#CFE5FF] rounded-tr-xs'
                      : 'bg-white dark:bg-[#1E2124] text-[#1A1C1E] dark:text-[#E2E2E5] border border-gray-200 dark:border-gray-800 rounded-tl-xs shadow-xs'
                  }`}
                >
                  {m.texto}
                </div>
              </div>

              <span className="text-[10px] text-gray-400 dark:text-gray-500 mt-1 px-1">
                {new Date(m.marcaTiempo).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          );
        })}

        {/* Visualizador de voz en tiempo real mientras el usuario habla */}
        {escuchando && (
          <div className="p-4 rounded-2xl bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-950/40 dark:to-indigo-950/40 border border-blue-300 dark:border-blue-800 shadow-sm animate-in fade-in space-y-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="relative flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
                </span>
                <span className="text-xs font-bold text-[#00629E] dark:text-[#9CCAFF]">
                  Grabando voz... Habla con naturalidad
                </span>
              </div>

              <button
                type="button"
                onClick={toggleEscuchaVoz}
                className="px-2.5 py-1 rounded-lg bg-red-100 dark:bg-red-950/80 text-red-700 dark:text-red-300 text-xs font-semibold hover:bg-red-200 cursor-pointer flex items-center gap-1"
              >
                <StopCircle className="w-3.5 h-3.5" />
                <span>Detener y enviar</span>
              </button>
            </div>

            {/* Onda de audio visual interactiva */}
            <div className="flex items-center justify-center gap-1.5 py-2">
              <span className="w-1.5 bg-[#00629E] dark:bg-[#9CCAFF] rounded-full animate-bounce h-3"></span>
              <span className="w-1.5 bg-[#00629E] dark:bg-[#9CCAFF] rounded-full animate-bounce h-7 delay-75"></span>
              <span className="w-1.5 bg-[#00629E] dark:bg-[#9CCAFF] rounded-full animate-bounce h-5 delay-150"></span>
              <span className="w-1.5 bg-[#00629E] dark:bg-[#9CCAFF] rounded-full animate-bounce h-9 delay-100"></span>
              <span className="w-1.5 bg-[#00629E] dark:bg-[#9CCAFF] rounded-full animate-bounce h-6 delay-200"></span>
              <span className="w-1.5 bg-[#00629E] dark:bg-[#9CCAFF] rounded-full animate-bounce h-3 delay-75"></span>
            </div>

            <p className="text-xs italic text-gray-700 dark:text-gray-300 text-center min-h-[1.25rem] font-medium">
              {interimTranscript ? `"${interimTranscript}..."` : 'Escuchando tu voz...'}
            </p>
          </div>
        )}

        {/* Confirmación interactiva de fecha */}
        {fechaPorConfirmar && (
          <div className="p-4 bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-900 rounded-2xl space-y-3 animate-in fade-in">
            <div>
              <p className="text-xs font-bold text-[#00629E] dark:text-[#9CCAFF] flex items-center gap-1.5">
                <Calendar className="w-4 h-4" />
                <span>Confirmar fecha de tu cita:</span>
              </p>
              <p className="text-xs text-gray-600 dark:text-gray-300 mt-1">
                Presiona un botón o di por voz <span className="font-semibold text-[#00629E] dark:text-[#9CCAFF]">"Sí, es correcto"</span>
              </p>
            </div>

            <div className="flex gap-2">
              <button
                type="button"
                onClick={handleConfirmarFecha}
                className="flex-1 py-2.5 px-3 rounded-xl bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] text-xs font-semibold hover:opacity-90 transition-opacity cursor-pointer shadow-xs"
              >
                {Cadenas.asistenteSiEsCorrecto}
              </button>
              <button
                type="button"
                onClick={handleRechazarFecha}
                className="flex-1 py-2.5 px-3 rounded-xl border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 text-xs font-medium hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer"
              >
                {Cadenas.asistenteNoEsCorrecto}
              </button>
            </div>
          </div>
        )}

        {/* Muestra interactiva de HORARIOS DISPONIBLES directamente en el chat */}
        {cuposSugeridosInfo && (
          <div className="p-4 bg-emerald-50/70 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800 rounded-2xl space-y-3 animate-in fade-in shadow-xs">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-800 dark:text-emerald-300">
                <Clock className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                <span>Horarios disponibles ({cuposSugeridosInfo.cupos.length}):</span>
              </div>
              <span className="text-[11px] text-gray-500 dark:text-gray-400">
                {FormatoFecha.fechaCorta(cuposSugeridosInfo.fecha)}
              </span>
            </div>

            {cuposSugeridosInfo.cupos.length > 0 ? (
              <div className="space-y-2.5">
                <p className="text-xs text-gray-600 dark:text-gray-300 font-medium">
                  Toca un horario para pasar directamente a confirmar tu cita:
                </p>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {cuposSugeridosInfo.cupos.slice(0, 6).map((c) => {
                    const horaTexto = FormatoFecha.hora(c.fechaHoraInicio);
                    const prof = profesionalDe(c.profesionalId);
                    return (
                      <button
                        key={c.id}
                        type="button"
                        onClick={() => {
                          // Pasar directamente a la confirmación con el horario elegido sin volver a pedir elegir horario
                          onGoToGuided({
                            especialidadId: cuposSugeridosInfo.especialidadId,
                            fecha: cuposSugeridosInfo.fecha,
                            profesionalId: c.profesionalId,
                            cupo: c,
                            cupoId: c.id,
                            irAConfirmacion: true,
                          });
                        }}
                        className="p-3 rounded-xl border border-emerald-300 dark:border-emerald-700 bg-white dark:bg-[#1E2124] hover:bg-emerald-50 dark:hover:bg-emerald-950/50 hover:border-emerald-500 hover:ring-2 hover:ring-emerald-400/40 text-left transition-all cursor-pointer shadow-xs group"
                      >
                        <span className="block text-xs font-bold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-300">
                          {horaTexto}
                        </span>
                        {prof && (
                          <span className="text-[10px] text-gray-500 dark:text-gray-400 block truncate mt-0.5">
                            Dr(a). {prof.apellidos.split(' ')[0]}
                          </span>
                        )}
                        <span className="text-[9px] font-semibold text-emerald-600 dark:text-emerald-400 mt-1 inline-block">
                          Confirmar este horario →
                        </span>
                      </button>
                    );
                  })}
                </div>

                <div className="pt-2 flex gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      onGoToGuided({
                        especialidadId: cuposSugeridosInfo.especialidadId,
                        fecha: cuposSugeridosInfo.fecha,
                        profesionalId: cuposSugeridosInfo.profesionalId,
                      });
                    }}
                    className="w-full py-2.5 px-3 rounded-xl border border-gray-300 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 text-xs font-semibold cursor-pointer shadow-xs flex items-center justify-center gap-1.5 transition-colors"
                  >
                    <ListOrdered className="w-4 h-4 text-[#00629E] dark:text-[#9CCAFF]" />
                    <span>Ver lista completa ({cuposSugeridosInfo.cupos.length} horarios disponibles)</span>
                  </button>
                </div>
              </div>
            ) : (
              <div className="text-center py-3">
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  No hay cupos disponibles en esta fecha.
                </p>
                <button
                  type="button"
                  onClick={() => {
                    setCuposSugeridosInfo(null);
                    onGoToGuided({ especialidadId: cuposSugeridosInfo.especialidadId });
                  }}
                  className="mt-2 text-xs text-[#00629E] dark:text-[#9CCAFF] font-semibold underline cursor-pointer"
                >
                  Ver calendario completo de fechas libres
                </button>
              </div>
            )}
          </div>
        )}

        {/* Fallback obligatorio: Ofrecer flujo guiado si 2 fallos consecutivos */}
        {debeOfrecerFlujoGuiado && (
          <div className="p-4 bg-amber-50 dark:bg-amber-950/30 border border-amber-300 dark:border-amber-800 rounded-2xl space-y-2 animate-in fade-in">
            <p className="text-xs text-amber-800 dark:text-amber-300">
              {Cadenas.asistenteOfrecerFlujoGuiado}
            </p>
            <button
              type="button"
              onClick={() => onGoToGuided()}
              className="w-full py-2.5 px-4 rounded-xl bg-[#00629E] text-white dark:bg-[#9CCAFF] dark:text-[#003258] text-xs font-semibold flex items-center justify-center gap-2 hover:opacity-95 cursor-pointer shadow-xs"
            >
              <ListOrdered className="w-4 h-4" />
              <span>{Cadenas.asistenteIrAFlujoGuiado}</span>
            </button>
          </div>
        )}

        {procesando && (
          <div className="flex items-center gap-2 text-xs text-gray-400 dark:text-gray-500 py-1">
            <Bot className="w-4 h-4 animate-bounce text-[#00629E] dark:text-[#9CCAFF]" />
            <span>El asistente está procesando tu solicitud...</span>
          </div>
        )}

        {/* Sugerencias rápidas para hablar o escribir */}
        {mensajes.length <= 3 && !fechaPorConfirmar && !cuposSugeridosInfo && (
          <div className="pt-2">
            <p className="text-[11px] font-semibold text-gray-500 dark:text-gray-400 mb-2 flex items-center gap-1">
              <Sparkles className="w-3.5 h-3.5 text-amber-500" />
              <span>Ejemplos que puedes decir por voz o presionar:</span>
            </p>
            <div className="flex flex-wrap gap-1.5">
              {SUGERENCIAS_VOZ.map((sug, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => handleEnviar(sug)}
                  className="px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#1E2124] text-[11px] text-gray-700 dark:text-gray-300 hover:border-[#00629E] dark:hover:border-[#9CCAFF] hover:text-[#00629E] dark:hover:text-[#9CCAFF] transition-colors cursor-pointer text-left shadow-xs flex items-center gap-1.5"
                >
                  <Mic className="w-3 h-3 text-[#00629E] dark:text-[#9CCAFF] shrink-0" />
                  <span>{sug}</span>
                </button>
              ))}
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Barra de entrada de texto y micrófono inferior */}
      <div className="p-3 bg-white dark:bg-[#1A1C1E] border-t border-gray-200 dark:border-gray-800">
        <div className="max-w-2xl mx-auto flex items-center gap-2">
          {soporteReconocimiento && (
            <button
              type="button"
              onClick={toggleEscuchaVoz}
              className={`p-3 rounded-2xl transition-all cursor-pointer shrink-0 flex items-center justify-center ${
                escuchando
                  ? 'bg-red-500 text-white animate-pulse shadow-md ring-4 ring-red-200 dark:ring-red-950'
                  : 'bg-blue-50 dark:bg-blue-950 text-[#00629E] dark:text-[#9CCAFF] hover:bg-blue-100 dark:hover:bg-blue-900 border border-blue-200 dark:border-blue-900'
              }`}
              title={escuchando ? 'Detener micrófono' : 'Hablar por micrófono'}
            >
              {escuchando ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
            </button>
          )}

          <div className="flex-1 relative flex items-center">
            <input
              type="text"
              value={inputTexto}
              onChange={(e) => setInputTexto(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  handleEnviar();
                }
              }}
              placeholder={escuchando ? 'Escuchando tu voz...' : 'Escribe o presiona el micrófono...'}
              className="w-full py-3 pl-4 pr-11 rounded-2xl border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-[#2A2E33] text-gray-900 dark:text-white text-sm focus:outline-hidden focus:ring-2 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF] focus:border-transparent transition-all"
            />
            <button
              type="button"
              disabled={!inputTexto.trim() || procesando}
              onClick={() => handleEnviar()}
              className="absolute right-2 p-2 rounded-xl text-white bg-[#00629E] dark:bg-[#9CCAFF] dark:text-[#003258] disabled:opacity-40 disabled:cursor-not-allowed hover:opacity-90 transition-opacity cursor-pointer"
              title="Enviar mensaje"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
