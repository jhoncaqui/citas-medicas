import 'package:shared_preferences/shared_preferences.dart';

/// Acceso a `shared_preferences`.
///
/// RNF-08: aqui NO se guarda el token de sesion ni ningun dato sensible del
/// paciente. Solo preferencias de interfaz. El token vive en
/// `flutter_secure_storage`.
class PreferenciasLocalDataSource {
  /// El parametro existe para que los tests puedan inyectar una instancia
  /// ya inicializada con `SharedPreferences.setMockInitialValues`.
  PreferenciasLocalDataSource([this._preferencias]);

  SharedPreferences? _preferencias;

  static const String claveTemaOscuro = 'preferencia_tema_oscuro';
  static const String claveIntroduccionVista = 'introduccion_vista';
  static const String clavePermisoNotificaciones =
      'permiso_notificaciones_solicitado';

  Future<SharedPreferences> get _instancia async =>
      _preferencias ??= await SharedPreferences.getInstance();

  /// `null` significa «seguir al sistema».
  Future<bool?> leerBoolONull(String clave) async {
    final prefs = await _instancia;
    if (!prefs.containsKey(clave)) return null;
    return prefs.getBool(clave);
  }

  Future<bool> leerBool(String clave, {bool porDefecto = false}) async {
    final prefs = await _instancia;
    return prefs.getBool(clave) ?? porDefecto;
  }

  Future<void> escribirBool(String clave, bool valor) async {
    final prefs = await _instancia;
    await prefs.setBool(clave, valor);
  }

  Future<void> eliminar(String clave) async {
    final prefs = await _instancia;
    await prefs.remove(clave);
  }

  /// HU-12: se invoca al revocar el consentimiento.
  Future<void> limpiarTodo() async {
    final prefs = await _instancia;
    await prefs.clear();
  }
}
