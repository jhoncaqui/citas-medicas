import React, { useState } from 'react';
import { Loader2 } from 'lucide-react';
import { useAuth } from './context/AuthContext';
import { LoginScreen } from './screens/LoginScreen';
import { RegisterScreen } from './screens/RegisterScreen';
import { HomeScreen } from './screens/HomeScreen';
import { ConversationalBookingScreen } from './screens/ConversationalBookingScreen';
import { GuidedBookingScreen } from './screens/GuidedBookingScreen';
import { MyAppointmentsScreen } from './screens/MyAppointmentsScreen';
import { LocationsScreen } from './screens/LocationsScreen';
import { IndicatorsScreen } from './screens/IndicatorsScreen';
import { PrivacyScreen } from './screens/PrivacyScreen';
import { ComprobanteScreen } from './screens/ComprobanteScreen';
import { AdminControlScreen } from './screens/AdminControlScreen';
import { Cita, CupoDisponible } from './types';

export const App: React.FC = () => {
  const { paciente, loading } = useAuth();

  const [authView, setAuthView] = useState<'login' | 'register'>('login');
  const [currentRoute, setCurrentRoute] = useState<string>('home');
  const [guidedPrefill, setGuidedPrefill] = useState<{
    especialidadId?: string;
    fecha?: Date;
    turno?: 'manana' | 'tarde';
    profesionalId?: string;
    cupo?: CupoDisponible;
    cupoId?: string;
    irAConfirmacion?: boolean;
  } | undefined>(undefined);
  const [citaAReprogramar, setCitaAReprogramar] = useState<Cita | null>(null);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#FCFCFF] dark:bg-[#121417] flex items-center justify-center p-4">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-8 h-8 text-[#00629E] dark:text-[#9CCAFF] animate-spin" />
          <span className="text-xs text-gray-500">Cargando aplicación...</span>
        </div>
      </div>
    );
  }

  // Si no hay sesión autenticada: Puerta de Entrada (RN-01)
  if (!paciente) {
    if (authView === 'register') {
      return (
        <RegisterScreen
          onGoToLogin={() => setAuthView('login')}
          onRegisterSuccess={() => {
            setCurrentRoute('home');
          }}
        />
      );
    }
    return (
      <LoginScreen
        onGoToRegister={() => setAuthView('register')}
        onLoginSuccess={() => {
          setCurrentRoute('home');
        }}
      />
    );
  }

  // Rutas con paciente autenticado
  switch (currentRoute) {
    case 'conversacion':
      return (
        <ConversationalBookingScreen
          onBack={() => setCurrentRoute('home')}
          onBookingSuccess={() => {
            setGuidedPrefill(undefined);
            setCitaAReprogramar(null);
            setCurrentRoute('comprobante');
          }}
          onGoToGuided={(prefill) => {
            setGuidedPrefill(prefill);
            setCitaAReprogramar(null);
            setCurrentRoute('flujoGuiado');
          }}
        />
      );

    case 'flujoGuiado':
      return (
        <GuidedBookingScreen
          onBack={() => {
            setGuidedPrefill(undefined);
            setCitaAReprogramar(null);
            setCurrentRoute('home');
          }}
          onBookingSuccess={() => {
            setGuidedPrefill(undefined);
            setCitaAReprogramar(null);
            setCurrentRoute('comprobante');
          }}
          initialData={guidedPrefill}
          citaAReprogramar={citaAReprogramar}
        />
      );

    case 'misCitas':
      return (
        <MyAppointmentsScreen
          onBack={() => setCurrentRoute('home')}
          onGoToBooking={() => {
            setGuidedPrefill(undefined);
            setCitaAReprogramar(null);
            setCurrentRoute('flujoGuiado');
          }}
          onReprogramar={(cita) => {
            setCitaAReprogramar(cita);
            setGuidedPrefill(undefined);
            setCurrentRoute('flujoGuiado');
          }}
        />
      );

    case 'ubicacion':
      return <LocationsScreen onBack={() => setCurrentRoute('home')} />;

    case 'indicadores':
      return <IndicatorsScreen onBack={() => setCurrentRoute('home')} />;

    case 'privacidad':
      return (
        <PrivacyScreen
          onBack={() => setCurrentRoute('home')}
          onLogoutOrDelete={() => {
            setAuthView('login');
          }}
        />
      );

    case 'comprobante':
      return <ComprobanteScreen onBackToHome={() => setCurrentRoute('home')} />;

    case 'adminControl':
      return (
        <AdminControlScreen
          onBack={() => setCurrentRoute('home')}
          onReprogramarCita={(cita) => {
            setCitaAReprogramar(cita);
            setGuidedPrefill(undefined);
            setCurrentRoute('flujoGuiado');
          }}
        />
      );

    case 'home':
    default:
      return (
        <HomeScreen
          onNavigate={(route) => {
            setGuidedPrefill(undefined);
            setCitaAReprogramar(null);
            setCurrentRoute(route);
          }}
        />
      );
  }
};
