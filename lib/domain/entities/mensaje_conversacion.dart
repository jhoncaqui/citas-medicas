import 'intencion_asistente.dart';

/// Un turno de la conversacion entre el paciente y el asistente.
class MensajeConversacion {
  const MensajeConversacion({
    required this.id,
    required this.rol,
    required this.texto,
    required this.marcaTiempo,
    this.intencionDetectada,
    this.confianza,
    this.entidades = const <String, String>{},
  });

  final String id;
  final RolMensaje rol;
  final String texto;
  final DateTime marcaTiempo;

  /// Solo para mensajes del asistente: que entendio del turno del paciente.
  final IntencionAsistente? intencionDetectada;

  /// Confianza del modelo, entre 0 y 1. Se compara contra
  /// `AppConfig.umbralConfianza`.
  final double? confianza;

  /// Entidades extraidas: especialidad, profesional, fecha, turno, hora.
  final Map<String, String> entidades;

  bool get esDelPaciente => rol == RolMensaje.paciente;

  MensajeConversacion copyWith({
    String? id,
    RolMensaje? rol,
    String? texto,
    DateTime? marcaTiempo,
    IntencionAsistente? intencionDetectada,
    double? confianza,
    Map<String, String>? entidades,
  }) => MensajeConversacion(
    id: id ?? this.id,
    rol: rol ?? this.rol,
    texto: texto ?? this.texto,
    marcaTiempo: marcaTiempo ?? this.marcaTiempo,
    intencionDetectada: intencionDetectada ?? this.intencionDetectada,
    confianza: confianza ?? this.confianza,
    entidades: entidades ?? this.entidades,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MensajeConversacion) return false;
    if (other.entidades.length != entidades.length) return false;
    for (final clave in entidades.keys) {
      if (other.entidades[clave] != entidades[clave]) return false;
    }
    return other.id == id &&
        other.rol == rol &&
        other.texto == texto &&
        other.marcaTiempo == marcaTiempo &&
        other.intencionDetectada == intencionDetectada &&
        other.confianza == confianza;
  }

  @override
  int get hashCode => Object.hash(
    id,
    rol,
    texto,
    marcaTiempo,
    intencionDetectada,
    confianza,
    Object.hashAllUnordered(
      entidades.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'MensajeConversacion($id, ${rol.clave})';
}

/// Lo que devuelve el backend al analizar un mensaje del paciente.
///
/// Es la misma forma que entrega Rasa, de modo que
/// `FakeAsistenteDataSource` y el cliente real sean intercambiables.
class RespuestaAsistente {
  const RespuestaAsistente({
    required this.intencion,
    required this.confianza,
    required this.respuesta,
    this.entidades = const <String, String>{},
    this.derivadoACanalAtencion = false,
  });

  final IntencionAsistente intencion;
  final double confianza;

  /// Texto que el asistente muestra al paciente.
  final String respuesta;

  final Map<String, String> entidades;

  /// RN-09: el mensaje pedia orientacion clinica y se derivo al canal de
  /// atencion sin sugerir especialidad.
  final bool derivadoACanalAtencion;

  /// `true` si la confianza alcanza el umbral configurado y por tanto se
  /// puede ejecutar una accion.
  bool superaUmbral(double umbral) =>
      confianza >= umbral && intencion.esAccionable;

  @override
  String toString() =>
      'RespuestaAsistente(${intencion.clave}, ${confianza.toStringAsFixed(2)})';
}
