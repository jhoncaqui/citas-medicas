import '../../core/error/resultado.dart';

/// Preferencias del paciente guardadas en el dispositivo.
///
/// RNF-08: aqui NO se guarda el token de sesion. El token vive en
/// almacenamiento seguro.
abstract interface class PreferenciasRepository {
  /// `null` significa «seguir la preferencia del sistema» (ODS 12).
  Future<Resultado<bool?>> obtenerPreferenciaTemaOscuro();

  Future<Resultado<void>> guardarPreferenciaTemaOscuro(bool? oscuro);

  /// El paciente ya vio la introduccion y no hay que volver a mostrarla.
  Future<Resultado<bool>> obtenerIntroduccionVista();

  Future<Resultado<void>> guardarIntroduccionVista(bool vista);

  /// Se pide `POST_NOTIFICATIONS` solo al confirmar la primera cita, no al
  /// arrancar (seccion 11).
  Future<Resultado<bool>> obtenerPermisoNotificacionesSolicitado();

  Future<Resultado<void>> guardarPermisoNotificacionesSolicitado(bool valor);

  /// Borra toda preferencia local. Se invoca al revocar el consentimiento
  /// (HU-12).
  Future<Resultado<void>> limpiarTodo();
}
