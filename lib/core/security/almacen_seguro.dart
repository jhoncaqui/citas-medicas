import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contrato de almacenamiento cifrado.
///
/// RNF-12: `flutter_secure_storage` queda aislado tras esta interfaz. Si el
/// proyecto se lleva a iOS, o si hay que sustituir el paquete, solo cambia la
/// implementacion; ni los repositorios ni los ViewModels se enteran.
///
/// RNF-08: aqui, y **solo** aqui, vive el token de sesion. Nunca en
/// `shared_preferences`.
abstract interface class AlmacenSeguro {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> eliminar(String clave);
  Future<void> limpiarTodo();
}

/// Implementacion sobre `flutter_secure_storage`.
///
/// En Android cifra con AES-GCM y protege la clave con RSA-OAEP en el
/// Keystore del sistema. Desde la version 11 del paquete ese es el
/// comportamiento por defecto de [AndroidOptions] y ya no hace falta
/// activarlo: el antiguo `encryptedSharedPreferences` desaparecio.
class AlmacenSeguroImpl implements AlmacenSeguro {
  AlmacenSeguroImpl({FlutterSecureStorage? almacen})
    : _almacen =
          almacen ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _almacen;

  // Claves de almacenamiento.
  static const String claveToken = 'token_sesion';
  static const String claveIdPaciente = 'id_paciente_sesion';

  @override
  Future<String?> leer(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) =>
      _almacen.write(key: clave, value: valor);

  @override
  Future<void> eliminar(String clave) => _almacen.delete(key: clave);

  @override
  Future<void> limpiarTodo() => _almacen.deleteAll();
}

/// Almacen en memoria, para tests y para el modo de desarrollo sin
/// dependencia de plataforma.
class AlmacenSeguroEnMemoria implements AlmacenSeguro {
  final Map<String, String> _datos = <String, String>{};

  @override
  Future<String?> leer(String clave) async => _datos[clave];

  @override
  Future<void> escribir(String clave, String valor) async =>
      _datos[clave] = valor;

  @override
  Future<void> eliminar(String clave) async => _datos.remove(clave);

  @override
  Future<void> limpiarTodo() async => _datos.clear();
}
