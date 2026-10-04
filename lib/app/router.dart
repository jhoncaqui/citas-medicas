import 'package:material_ui/material_ui.dart';

import '../l10n/cadenas.dart';
import '../presentation/screens/administracion_screen.dart';
import '../presentation/screens/comprobante_screen.dart';
import '../presentation/screens/conversacion_screen.dart';
import '../presentation/screens/flujo_guiado_screen.dart';
import '../presentation/screens/indicadores_screen.dart';
import '../presentation/screens/inicio_screen.dart';
import '../presentation/screens/inicio_sesion_screen.dart';
import '../presentation/screens/mis_citas_screen.dart';
import '../presentation/screens/pantalla_pendiente.dart';
import '../presentation/screens/privacidad_screen.dart';
import '../presentation/screens/puerta_entrada.dart';
import '../presentation/screens/registro_screen.dart';
import '../presentation/screens/ubicacion_screen.dart';

/// Nombres de ruta. Se declaran como constantes para que ninguna pantalla
/// navegue con una cadena suelta.
class Rutas {
  const Rutas._();

  /// Raiz: decide entre inicio de sesion e inicio segun RN-01.
  static const String raiz = '/';

  static const String inicio = '/inicio';
  static const String registro = '/registro';
  static const String inicioSesion = '/inicio-sesion';
  static const String privacidad = '/privacidad';

  static const String conversacion = '/conversacion';
  static const String flujoGuiado = '/reserva-guiada';
  static const String misCitas = '/mis-citas';
  static const String ubicacion = '/ubicacion';

  static const String comprobante = '/comprobante';
  static const String indicadores = '/indicadores';
  static const String administracion = '/administracion';
}

/// Tabla de rutas de la aplicacion.
class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get rutas => <String, WidgetBuilder>{
    Rutas.raiz: (_) => const PuertaEntrada(),
    Rutas.inicio: (_) => const InicioScreen(),

    // Fase 1
    Rutas.registro: (_) => const RegistroScreen(),
    Rutas.inicioSesion: (_) => const InicioSesionScreen(),
    Rutas.privacidad: (_) => const PrivacidadScreen(),

    // Fase 2
    Rutas.conversacion: (_) => const ConversacionScreen(),
    Rutas.flujoGuiado: (_) => const FlujoGuiadoScreen(),
    Rutas.comprobante: (_) => const ComprobanteScreen(),

    // Fase 3
    Rutas.misCitas: (_) => const MisCitasScreen(),

    // Fase 4
    Rutas.ubicacion: (_) => const UbicacionScreen(),
    Rutas.indicadores: (_) => const IndicadoresScreen(),
    Rutas.administracion: (_) => const AdministracionScreen(),
  };

  /// Se invoca cuando se navega a un nombre que no esta en [rutas]. Evita la
  /// pantalla roja por defecto.
  static Route<dynamic> rutaDesconocida(RouteSettings settings) =>
      MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const PantallaPendiente(
          titulo: Cadenas.nombreApp,
          fase: 'proxima fase',
          historias: 'esta seccion',
        ),
      );
}
