import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/mensaje_conversacion.dart';

/// Respuesta del backend al analizar un mensaje.
///
/// Reproduce la forma que devuelve Rasa: intencion, confianza y entidades.
/// `FakeAsistenteDataSource` construye exactamente esta misma estructura, de
/// modo que el resto de la aplicacion no distingue una de otra.
class RespuestaAsistenteDto {
  const RespuestaAsistenteDto({
    required this.intencion,
    required this.confianza,
    required this.respuesta,
    this.entidades = const <String, String>{},
    this.derivadoACanalAtencion = false,
  });

  /// Clave de intencion tal como la emite Rasa.
  final String intencion;

  final double confianza;
  final String respuesta;
  final Map<String, String> entidades;
  final bool derivadoACanalAtencion;

  factory RespuestaAsistenteDto.fromJson(Map<String, dynamic> json) {
    // Rasa anida la intencion: {"intent": {"name": ..., "confidence": ...}}
    final intent = json['intent'];
    final String nombre;
    final double confianza;

    if (intent is Map<String, dynamic>) {
      nombre = (intent['name'] as String?) ?? 'no_reconocida';
      confianza = ((intent['confidence'] as num?) ?? 0).toDouble();
    } else {
      nombre = (json['intencion'] as String?) ?? 'no_reconocida';
      confianza = ((json['confianza'] as num?) ?? 0).toDouble();
    }

    return RespuestaAsistenteDto(
      intencion: nombre,
      confianza: confianza,
      respuesta:
          (json['respuesta'] as String?) ?? (json['text'] as String?) ?? '',
      entidades: _entidades(json['entidades'] ?? json['entities']),
      derivadoACanalAtencion:
          (json['derivadoACanalAtencion'] as bool?) ?? false,
    );
  }

  /// Rasa entrega las entidades como lista de `{entity, value}`; el backend
  /// propio puede simplificarlas a un mapa. Se admiten ambas formas.
  static Map<String, String> _entidades(Object? crudo) {
    if (crudo is Map) {
      return crudo.map((k, v) => MapEntry('$k', '$v'));
    }
    if (crudo is List) {
      final mapa = <String, String>{};
      for (final e in crudo) {
        if (e is Map && e['entity'] != null && e['value'] != null) {
          mapa['${e['entity']}'] = '${e['value']}';
        }
      }
      return mapa;
    }
    return const <String, String>{};
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'intencion': intencion,
    'confianza': confianza,
    'respuesta': respuesta,
    'entidades': entidades,
    'derivadoACanalAtencion': derivadoACanalAtencion,
  };

  RespuestaAsistente aDominio() => RespuestaAsistente(
    intencion: IntencionAsistente.desdeClave(intencion),
    confianza: confianza,
    respuesta: respuesta,
    entidades: entidades,
    derivadoACanalAtencion: derivadoACanalAtencion,
  );
}
