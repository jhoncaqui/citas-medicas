/// Jerarquia de fallos del dominio y de la infraestructura.
///
/// La capa de presentacion nunca ve una `SocketException` ni un codigo HTTP:
/// solo estos tipos, que ya traen un mensaje apto para mostrar al paciente.
sealed class FalloApp implements Exception {
  const FalloApp(this.mensaje, {this.codigo, this.detalles});

  /// Texto en espanol, listo para la interfaz.
  final String mensaje;

  /// Codigo del backend, cuando lo hay: `{codigo, mensaje, detalles}`.
  final String? codigo;

  final Object? detalles;

  @override
  String toString() => '$runtimeType($codigo): $mensaje';
}

/// No hay conexion de red, o se perdio a mitad de la operacion.
class FalloConexion extends FalloApp {
  const FalloConexion([
    super.mensaje = 'No hay conexion. Revisa tu red e intentalo de nuevo.',
  ]);
}

/// El servidor no respondio dentro de [AppConfig.timeoutHttp].
class FalloTiempoAgotado extends FalloApp {
  const FalloTiempoAgotado([
    super.mensaje =
        'El servidor tardo demasiado en responder. Intentalo de nuevo.',
  ]);
}

/// El servidor respondio con un error (4xx / 5xx).
class FalloServidor extends FalloApp {
  const FalloServidor(
    super.mensaje, {
    super.codigo,
    super.detalles,
    this.estadoHttp,
  });

  final int? estadoHttp;
}

/// Credenciales invalidas o sesion expirada.
///
/// HU-02: el mensaje es deliberadamente generico y no revela cual de las dos
/// credenciales fallo.
class FalloAutenticacion extends FalloApp {
  const FalloAutenticacion([
    super.mensaje = 'Los datos ingresados no son correctos.',
  ]);
}

/// Una regla de negocio (RN-01 a RN-10) rechazo la operacion.
class FalloReglaNegocio extends FalloApp {
  const FalloReglaNegocio(super.mensaje, {required this.regla});

  /// Codigo de la regla infringida, por ejemplo `RN-04`.
  final String regla;

  @override
  String toString() => 'FalloReglaNegocio($regla): $mensaje';
}

/// Datos de entrada que no superan la validacion (documento, correo, etc.).
class FalloValidacion extends FalloApp {
  const FalloValidacion(super.mensaje, {this.campo});

  final String? campo;
}

/// No se encontro el recurso solicitado.
class FalloNoEncontrado extends FalloApp {
  const FalloNoEncontrado([
    super.mensaje = 'No se encontro el recurso solicitado.',
  ]);
}

/// Fallo al leer o escribir en la base local (sqflite / preferencias).
class FalloAlmacenamientoLocal extends FalloApp {
  const FalloAlmacenamientoLocal([
    super.mensaje =
        'No se pudo acceder a los datos guardados en el dispositivo.',
  ]);
}
