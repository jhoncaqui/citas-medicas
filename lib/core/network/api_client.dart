import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../error/excepciones.dart';

/// Cliente HTTP del backend Spring Boot.
///
/// - RNF-02: corta a los [AppConfig.timeoutHttp] y reintenta una sola vez.
/// - RNF-08: rechaza cualquier URL que no sea HTTPS.
/// - Traduce los errores de transporte y los cuerpos `{codigo, mensaje,
///   detalles}` del backend a la jerarquia [FalloApp].
class ApiClient {
  ApiClient({http.Client? cliente, String? urlBase})
    : _cliente = cliente ?? http.Client(),
      _urlBase = urlBase ?? AppConfig.urlBaseApi;

  final http.Client _cliente;
  final String _urlBase;

  /// Token de sesion. Lo inyecta el repositorio desde el almacenamiento
  /// seguro; nunca se persiste aqui.
  String? _token;

  // ignore: avoid_setters_without_getters
  set token(String? valor) => _token = valor;

  Future<Map<String, dynamic>> get(
    String ruta, {
    Map<String, String>? parametros,
  }) => _enviar('GET', ruta, parametros: parametros);

  Future<Map<String, dynamic>> post(
    String ruta, {
    Map<String, dynamic>? cuerpo,
    Map<String, String>? cabecerasExtra,
  }) => _enviar('POST', ruta, cuerpo: cuerpo, cabecerasExtra: cabecerasExtra);

  Future<Map<String, dynamic>> patch(
    String ruta, {
    Map<String, dynamic>? cuerpo,
  }) => _enviar('PATCH', ruta, cuerpo: cuerpo);

  Future<Map<String, dynamic>> delete(String ruta) => _enviar('DELETE', ruta);

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String ruta, {
    Map<String, String>? parametros,
    Map<String, dynamic>? cuerpo,
    Map<String, String>? cabecerasExtra,
    int intento = 0,
  }) async {
    final uri = _construirUri(ruta, parametros);

    // RNF-08: solo HTTPS. El trafico en claro tambien esta bloqueado en el
    // manifiesto de Android; esta comprobacion evita que una URL mal
    // configurada llegue siquiera a intentarse.
    if (uri.scheme != 'https') {
      throw FalloServidor(
        'La configuracion de red no es segura. Contacta con soporte.',
        codigo: 'HTTPS_REQUERIDO',
        detalles: uri.toString(),
      );
    }

    final cabeceras = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
      ...?cabecerasExtra,
    };

    try {
      final http.Response respuesta = await switch (metodo) {
        'GET' => _cliente.get(uri, headers: cabeceras),
        'POST' => _cliente.post(
          uri,
          headers: cabeceras,
          body: cuerpo == null ? null : jsonEncode(cuerpo),
        ),
        'PATCH' => _cliente.patch(
          uri,
          headers: cabeceras,
          body: cuerpo == null ? null : jsonEncode(cuerpo),
        ),
        'DELETE' => _cliente.delete(uri, headers: cabeceras),
        _ => throw ArgumentError('Metodo HTTP no soportado: $metodo'),
      }.timeout(AppConfig.timeoutHttp);

      return _procesar(respuesta);
    } on TimeoutException {
      if (intento < AppConfig.reintentosHttp) {
        return _enviar(
          metodo,
          ruta,
          parametros: parametros,
          cuerpo: cuerpo,
          cabecerasExtra: cabecerasExtra,
          intento: intento + 1,
        );
      }
      throw const FalloTiempoAgotado();
    } on SocketException {
      if (intento < AppConfig.reintentosHttp) {
        return _enviar(
          metodo,
          ruta,
          parametros: parametros,
          cuerpo: cuerpo,
          cabecerasExtra: cabecerasExtra,
          intento: intento + 1,
        );
      }
      throw const FalloConexion();
    } on http.ClientException {
      throw const FalloConexion();
    }
  }

  Uri _construirUri(String ruta, Map<String, String>? parametros) {
    final base = Uri.parse('$_urlBase$ruta');
    if (parametros == null || parametros.isEmpty) return base;
    return base.replace(
      queryParameters: <String, String>{...base.queryParameters, ...parametros},
    );
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    final estado = respuesta.statusCode;
    final Map<String, dynamic> cuerpo = respuesta.body.isEmpty
        ? const <String, dynamic>{}
        : _decodificar(respuesta.body);

    if (estado >= 200 && estado < 300) return cuerpo;

    if (estado == 401 || estado == 403) throw const FalloAutenticacion();
    if (estado == 404) throw const FalloNoEncontrado();

    throw FalloServidor(
      (cuerpo['mensaje'] as String?) ??
          'El servidor no pudo procesar la solicitud.',
      codigo: cuerpo['codigo'] as String?,
      detalles: cuerpo['detalles'],
      estadoHttp: estado,
    );
  }

  Map<String, dynamic> _decodificar(String body) {
    final decodificado = jsonDecode(body);
    // El backend puede responder con una lista en la raiz; se envuelve para
    // mantener un unico tipo de retorno.
    if (decodificado is List) return <String, dynamic>{'datos': decodificado};
    return decodificado as Map<String, dynamic>;
  }

  void cerrar() => _cliente.close();
}
