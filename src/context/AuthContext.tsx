import React, { createContext, useContext, useEffect, useState } from 'react';
import { OperacionProtegida, Paciente } from '../types';
import { StorageService } from '../services/storageService';
import { Rn01Autenticacion } from '../domain/rules/rn01Autenticacion';
import { Rn10Consentimiento } from '../domain/rules/rn10Consentimiento';

interface AuthContextType {
  paciente: Paciente | null;
  loading: boolean;
  error: string | null;
  iniciarSesion: (numeroDocumento: string, clave: string) => Promise<boolean>;
  registrar: (paciente: Paciente, clave: string) => Promise<boolean>;
  cerrarSesion: () => void;
  otorgarConsentimiento: () => Promise<boolean>;
  revocarConsentimiento: () => Promise<boolean>;
  eliminarMisDatos: () => Promise<boolean>;
  impedimentoPara: (operacion: OperacionProtegida) => string | null;
  limpiarError: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [paciente, setPaciente] = useState<Paciente | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const initAuth = async () => {
      try {
        await StorageService.sembrarCuentasIniciales();
        const sesion = StorageService.obtenerSesion();
        setPaciente(sesion);
      } catch (e: any) {
        console.error('Error restaurando sesión:', e);
      } finally {
        setLoading(false);
      }
    };
    initAuth();
  }, []);

  const iniciarSesion = async (numeroDocumento: string, clave: string): Promise<boolean> => {
    setLoading(true);
    setError(null);
    try {
      const p = await StorageService.iniciarSesion(numeroDocumento, clave);
      setPaciente(p);
      return true;
    } catch (e: any) {
      setError(e.message || 'Error al iniciar sesión.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const registrar = async (nuevoPaciente: Paciente, clave: string): Promise<boolean> => {
    setLoading(true);
    setError(null);
    try {
      const p = await StorageService.registrarPaciente(nuevoPaciente, clave);
      setPaciente(p);
      return true;
    } catch (e: any) {
      setError(e.message || 'Error al registrar.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const cerrarSesion = () => {
    StorageService.cerrarSesion();
    setPaciente(null);
    setError(null);
  };

  const otorgarConsentimiento = async (): Promise<boolean> => {
    if (!paciente) return false;
    setLoading(true);
    try {
      const actualizado = await StorageService.actualizarConsentimiento(paciente.id, true);
      setPaciente(actualizado);
      return true;
    } catch (e: any) {
      setError(e.message || 'Error al otorgar consentimiento.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const revocarConsentimiento = async (): Promise<boolean> => {
    if (!paciente) return false;
    setLoading(true);
    try {
      const actualizado = await StorageService.actualizarConsentimiento(paciente.id, false);
      setPaciente(actualizado);
      return true;
    } catch (e: any) {
      setError(e.message || 'Error al revocar consentimiento.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const eliminarMisDatos = async (): Promise<boolean> => {
    if (!paciente) return false;
    setLoading(true);
    try {
      await StorageService.eliminarDatosPaciente(paciente.id);
      setPaciente(null);
      return true;
    } catch (e: any) {
      setError(e.message || 'Error al eliminar datos.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const impedimentoPara = (operacion: OperacionProtegida): string | null => {
    const valAut = Rn01Autenticacion.validar(paciente, operacion);
    if (valAut.infringida) return valAut.mensaje || 'Operación no permitida.';

    if (operacion !== 'verIndicadores') {
      const valCons = Rn10Consentimiento.validarVigente(paciente);
      if (valCons.infringida) return valCons.mensaje || 'Consentimiento requerido.';
    }

    return null;
  };

  const limpiarError = () => setError(null);

  return (
    <AuthContext.Provider
      value={{
        paciente,
        loading,
        error,
        iniciarSesion,
        registrar,
        cerrarSesion,
        otorgarConsentimiento,
        revocarConsentimiento,
        eliminarMisDatos,
        impedimentoPara,
        limpiarError,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
