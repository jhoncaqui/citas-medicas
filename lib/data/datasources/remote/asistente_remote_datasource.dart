import '../../../core/network/api_client.dart';
import '../../models/asistente_dto.dart';

/// Contrato del puente hacia el motor conversacional.
abstract interface class AsistenteDataSource {
  /// POST /api/v1/asistente/mensajes
  ///
  /// RNF-10: [texto] viaja **disociado del titular**. Ni esta firma ni las
  /// implementaciones aceptan identificador de paciente: `idConversacion` es
  /// un identificador efimero de sesion de chat, no del paciente.
  Future<RespuestaAsistenteDto> analizarMensaje({
    required String texto,
    required String idConversacion,
  });
}

class ApiAsistenteDataSource implements AsistenteDataSource {
  ApiAsistenteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<RespuestaAsistenteDto> analizarMensaje({
    required String texto,
    required String idConversacion,
  }) async {
    final respuesta = await _api.post(
      '/asistente/mensajes',
      cuerpo: <String, dynamic>{
        'texto': texto,
        // Identificador de la conversacion, no del paciente (RNF-10).
        'idConversacion': idConversacion,
      },
    );
    return RespuestaAsistenteDto.fromJson(respuesta);
  }
}
