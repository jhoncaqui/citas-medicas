import 'package:flutter/foundation.dart';

/// Banderas de entorno que permiten ejecutar la aplicacion sin que existan
/// todavia el backend Spring Boot, el proyecto de Firebase ni la clave de
/// Google Maps.
///
/// Las de servicios externos (`usarBackendReal`, `usarFirebase`, `usarMapas`)
/// nacen en `false`: el criterio de aceptacion de la Fase 0 exige que la
/// aplicacion arranque y sea demostrable en el emulador sin ningun servicio
/// externo levantado.
///
/// Se pueden sobrescribir en tiempo de compilacion sin tocar el codigo:
///   flutter run --dart-define=USAR_BACKEND_REAL=true
class FeatureFlags {
  const FeatureFlags._();

  /// `true` usa [ApiRemoteDataSource] contra el backend REST real.
  /// `false` usa las fuentes falsas con fixtures locales.
  static const bool usarBackendReal = bool.fromEnvironment('USAR_BACKEND_REAL');

  /// Requiere `android/app/google-services.json`. Mientras este en `false`,
  /// la autenticacion usa una implementacion local de desarrollo y los
  /// recordatorios se registran en consola.
  static const bool usarFirebase = bool.fromEnvironment('USAR_FIREBASE');

  /// Requiere clave de API de Google Maps. Con la bandera apagada, la pantalla
  /// de ubicacion muestra direccion y referencia en texto.
  static const bool usarMapas = bool.fromEnvironment('USAR_MAPAS');

  /// Siembra las cuentas de demostracion (administradores y pacientes) en la
  /// autenticacion local.
  ///
  /// **Por defecto solo en compilaciones de desarrollo**: en release vale
  /// `false`, para que un AAB no salga con credenciales conocidas incrustadas.
  /// Se fuerza con `--dart-define=SEMBRAR_CUENTAS_DEMO=true` (por ejemplo, para
  /// una demostracion con el AAB) o `=false`.
  ///
  /// No tiene efecto con Firebase ni con el backend real: sin autenticacion
  /// local no hay donde sembrar.
  static const bool sembrarCuentasDemo = bool.fromEnvironment(
    'SEMBRAR_CUENTAS_DEMO',
    defaultValue: !kReleaseMode,
  );

  /// Muestra el microfono de dictado por voz en el asistente. Es una funcion
  /// del propio dispositivo (no depende de ningun servicio externo), por eso
  /// nace encendida; si el dispositivo no tiene reconocimiento de voz, el
  /// boton se oculta en tiempo de ejecucion.
  ///
  /// Se puede apagar con `--dart-define=USAR_DICTADO=false`.
  static const bool usarDictado = bool.fromEnvironment(
    'USAR_DICTADO',
    defaultValue: true,
  );
}
