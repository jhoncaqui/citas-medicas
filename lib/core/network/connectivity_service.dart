import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de conectividad del dispositivo.
///
/// RNF-07: la aplicacion debe reaccionar a la perdida de conexion
/// conservando el estado de la operacion en curso. Se aisla `connectivity_plus`
/// tras esta clase para cumplir RNF-12 (nada especifico de plataforma suelto
/// por el codigo).
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// `true` si hay alguna interfaz de red activa.
  ///
  /// Tener interfaz no garantiza que el backend responda; es una primera
  /// barrera para no lanzar peticiones condenadas a fallar.
  Future<bool> get hayConexion async {
    final resultados = await _connectivity.checkConnectivity();
    return _hayRed(resultados);
  }

  /// Emite `true`/`false` cada vez que cambia la conectividad.
  Stream<bool> get cambios =>
      _connectivity.onConnectivityChanged.map(_hayRed).distinct();

  bool _hayRed(List<ConnectivityResult> resultados) =>
      resultados.any((r) => r != ConnectivityResult.none);
}
