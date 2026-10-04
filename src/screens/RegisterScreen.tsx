import React, { useState } from 'react';
import { ArrowLeft, Eye, EyeOff, Loader2 } from 'lucide-react';
import { CabeceraConLogo } from '../components/LogoClinica';
import { Cadenas } from '../constants/cadenas';
import { useAuth } from '../context/AuthContext';
import { TipoDocumento } from '../types';
import { Rn02DocumentoIdentidad } from '../domain/rules/rn02DocumentoIdentidad';
import { ValidacionesRegistro } from '../domain/rules/validacionesRegistro';
import { Rn10Consentimiento } from '../domain/rules/rn10Consentimiento';

interface RegisterScreenProps {
  onGoToLogin: () => void;
  onRegisterSuccess: () => void;
}

export const RegisterScreen: React.FC<RegisterScreenProps> = ({ onGoToLogin, onRegisterSuccess }) => {
  const { registrar, error, limpiarError, loading } = useAuth();

  const [tipoDocumento, setTipoDocumento] = useState<TipoDocumento>('DNI');
  const [numeroDocumento, setNumeroDocumento] = useState('');
  const [nombres, setNombres] = useState('');
  const [apellidos, setApellidos] = useState('');
  const [correo, setCorreo] = useState('');
  const [telefono, setTelefono] = useState('');
  const [clave, setClave] = useState('');
  const [confirmarClave, setConfirmarClave] = useState('');
  const [consentimiento, setConsentimiento] = useState(false);
  const [mostrarClave, setMostrarClave] = useState(false);

  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [generalError, setGeneralError] = useState<string | null>(null);

  const validateAll = (): boolean => {
    const errors: Record<string, string> = {};

    const valDoc = Rn02DocumentoIdentidad.validar(tipoDocumento, numeroDocumento);
    if (valDoc.infringida && valDoc.mensaje) errors.numeroDocumento = valDoc.mensaje;

    const valNom = ValidacionesRegistro.validarNombres(nombres);
    if (valNom.infringida && valNom.mensaje) errors.nombres = valNom.mensaje;

    const valApe = ValidacionesRegistro.validarApellidos(apellidos);
    if (valApe.infringida && valApe.mensaje) errors.apellidos = valApe.mensaje;

    const valCor = ValidacionesRegistro.validarCorreo(correo);
    if (valCor.infringida && valCor.mensaje) errors.correo = valCor.mensaje;

    const valTel = ValidacionesRegistro.validarTelefono(telefono);
    if (valTel.infringida && valTel.mensaje) errors.telefono = valTel.mensaje;

    const valCla = ValidacionesRegistro.validarClave(clave);
    if (valCla.infringida && valCla.mensaje) errors.clave = valCla.mensaje;

    const valConf = ValidacionesRegistro.validarConfirmacionClave(clave, confirmarClave);
    if (valConf.infringida && valConf.mensaje) errors.confirmarClave = valConf.mensaje;

    const valCons = Rn10Consentimiento.validarParaRegistro(consentimiento);
    if (valCons.infringida && valCons.mensaje) errors.consentimiento = valCons.mensaje;

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setGeneralError(null);
    limpiarError();

    if (!validateAll()) return;

    const nuevoPaciente = {
      id: `pac-${Date.now()}`,
      tipoDocumento,
      numeroDocumento: Rn02DocumentoIdentidad.normalizar(numeroDocumento),
      nombres: nombres.trim(),
      apellidos: apellidos.trim(),
      correo: correo.trim().toLowerCase(),
      telefono: telefono.trim(),
      consentimientoOtorgado: true,
      fechaConsentimiento: new Date().toISOString(),
      rol: 'paciente' as const,
    };

    const exito = await registrar(nuevoPaciente, clave);
    if (exito) {
      onRegisterSuccess();
    }
  };

  return (
    <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] py-8 px-4 flex justify-center">
      <div className="w-full max-w-lg bg-white dark:bg-[#1E2124] rounded-3xl p-6 sm:p-8 shadow-sm border border-gray-200 dark:border-gray-800 transition-colors">
        <button
          type="button"
          onClick={onGoToLogin}
          className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white mb-4 cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Volver a iniciar sesión</span>
        </button>

        <CabeceraConLogo
          titulo={Cadenas.tituloRegistro}
          subtitulo={Cadenas.subtituloRegistro}
          altoLogo={56}
        />

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Tipo de Documento */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
              {Cadenas.tipoDocumento}
            </label>
            <div className="grid grid-cols-2 gap-2 bg-gray-100 dark:bg-gray-800 p-1 rounded-xl">
              <button
                type="button"
                onClick={() => setTipoDocumento('DNI')}
                className={`py-2 text-xs font-semibold rounded-lg transition-colors cursor-pointer ${
                  tipoDocumento === 'DNI'
                    ? 'bg-white dark:bg-gray-700 text-[#00629E] dark:text-[#9CCAFF] shadow-sm'
                    : 'text-gray-600 dark:text-gray-400 hover:text-gray-900'
                }`}
              >
                DNI (8 dígitos)
              </button>
              <button
                type="button"
                onClick={() => setTipoDocumento('CE')}
                className={`py-2 text-xs font-semibold rounded-lg transition-colors cursor-pointer ${
                  tipoDocumento === 'CE'
                    ? 'bg-white dark:bg-gray-700 text-[#00629E] dark:text-[#9CCAFF] shadow-sm'
                    : 'text-gray-600 dark:text-gray-400 hover:text-gray-900'
                }`}
              >
                Carné de Extranjería
              </button>
            </div>
          </div>

          {/* Número de Documento */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
              {Cadenas.numeroDocumento}
            </label>
            <input
              type="text"
              value={numeroDocumento}
              onChange={(e) => setNumeroDocumento(e.target.value)}
              placeholder={tipoDocumento === 'DNI' ? '8 dígitos' : '9 a 12 caracteres'}
              maxLength={tipoDocumento === 'DNI' ? 10 : 14}
              className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 ${
                fieldErrors.numeroDocumento
                  ? 'border-red-500 focus:ring-red-400'
                  : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
              }`}
            />
            {fieldErrors.numeroDocumento && (
              <p className="text-[11px] text-red-500 mt-1">{fieldErrors.numeroDocumento}</p>
            )}
          </div>

          {/* Nombres y Apellidos */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                {Cadenas.nombres}
              </label>
              <input
                type="text"
                value={nombres}
                onChange={(e) => setNombres(e.target.value)}
                placeholder="Nombres completos"
                className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 ${
                  fieldErrors.nombres
                    ? 'border-red-500 focus:ring-red-400'
                    : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
                }`}
              />
              {fieldErrors.nombres && (
                <p className="text-[11px] text-red-500 mt-1">{fieldErrors.nombres}</p>
              )}
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                {Cadenas.apellidos}
              </label>
              <input
                type="text"
                value={apellidos}
                onChange={(e) => setApellidos(e.target.value)}
                placeholder="Apellidos completos"
                className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 ${
                  fieldErrors.apellidos
                    ? 'border-red-500 focus:ring-red-400'
                    : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
                }`}
              />
              {fieldErrors.apellidos && (
                <p className="text-[11px] text-red-500 mt-1">{fieldErrors.apellidos}</p>
              )}
            </div>
          </div>

          {/* Correo y Teléfono */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                {Cadenas.correo}
              </label>
              <input
                type="email"
                value={correo}
                onChange={(e) => setCorreo(e.target.value)}
                placeholder="ejemplo@correo.com"
                className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 ${
                  fieldErrors.correo
                    ? 'border-red-500 focus:ring-red-400'
                    : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
                }`}
              />
              {fieldErrors.correo && (
                <p className="text-[11px] text-red-500 mt-1">{fieldErrors.correo}</p>
              )}
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                {Cadenas.telefono}
              </label>
              <input
                type="tel"
                value={telefono}
                onChange={(e) => setTelefono(e.target.value)}
                placeholder="9 dígitos (inicia con 9)"
                maxLength={9}
                className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 ${
                  fieldErrors.telefono
                    ? 'border-red-500 focus:ring-red-400'
                    : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
                }`}
              />
              {fieldErrors.telefono && (
                <p className="text-[11px] text-red-500 mt-1">{fieldErrors.telefono}</p>
              )}
            </div>
          </div>

          {/* Clave y Confirmar Clave */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                {Cadenas.clave}
              </label>
              <div className="relative">
                <input
                  type={mostrarClave ? 'text' : 'password'}
                  value={clave}
                  onChange={(e) => setClave(e.target.value)}
                  placeholder="Mínimo 8 caracteres"
                  className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 pr-10 ${
                    fieldErrors.clave
                      ? 'border-red-500 focus:ring-red-400'
                      : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
                  }`}
                />
                <button
                  type="button"
                  onClick={() => setMostrarClave(!mostrarClave)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 cursor-pointer"
                >
                  {mostrarClave ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {fieldErrors.clave && (
                <p className="text-[11px] text-red-500 mt-1">{fieldErrors.clave}</p>
              )}
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                {Cadenas.confirmarClave}
              </label>
              <input
                type={mostrarClave ? 'text' : 'password'}
                value={confirmarClave}
                onChange={(e) => setConfirmarClave(e.target.value)}
                placeholder="Repite la contraseña"
                className={`w-full px-4 py-2.5 rounded-xl border bg-transparent text-sm focus:outline-none focus:ring-2 ${
                  fieldErrors.confirmarClave
                    ? 'border-red-500 focus:ring-red-400'
                    : 'border-gray-300 dark:border-gray-700 focus:ring-[#00629E] dark:focus:ring-[#9CCAFF]'
                }`}
              />
              {fieldErrors.confirmarClave && (
                <p className="text-[11px] text-red-500 mt-1">{fieldErrors.confirmarClave}</p>
              )}
            </div>
          </div>

          {/* RN-10: Consentimiento Informado */}
          <div className="pt-2">
            <label className="flex items-start gap-3 p-3.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-800/40 cursor-pointer">
              <input
                type="checkbox"
                checked={consentimiento}
                onChange={(e) => setConsentimiento(e.target.checked)}
                className="mt-1 w-4 h-4 text-[#00629E] rounded focus:ring-[#00629E] cursor-pointer"
              />
              <div className="text-xs">
                <span className="font-semibold text-gray-900 dark:text-white block">
                  {Cadenas.consentimientoEtiqueta}
                </span>
                <span className="text-gray-500 dark:text-gray-400 mt-0.5 block leading-relaxed">
                  {Cadenas.consentimientoDetalle}
                </span>
              </div>
            </label>
            {fieldErrors.consentimiento && (
              <p className="text-[11px] text-red-500 mt-1">{fieldErrors.consentimiento}</p>
            )}
          </div>

          {(generalError || error) && (
            <div className="p-3 rounded-xl bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900 text-xs text-red-600 dark:text-red-400 font-medium">
              {generalError || error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 rounded-xl bg-[#00629E] hover:bg-[#004e7e] dark:bg-[#9CCAFF] dark:hover:bg-[#b0d5ff] text-white dark:text-[#003258] font-semibold text-sm transition-colors shadow-sm flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-6 min-h-[48px]"
          >
            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : Cadenas.crearCuenta}
          </button>
        </form>

        <div className="mt-5 text-center">
          <button
            type="button"
            onClick={onGoToLogin}
            disabled={loading}
            className="text-xs text-[#00629E] dark:text-[#9CCAFF] hover:underline font-medium cursor-pointer"
          >
            {Cadenas.yaTengoCuenta}
          </button>
        </div>
      </div>
    </div>
  );
};
