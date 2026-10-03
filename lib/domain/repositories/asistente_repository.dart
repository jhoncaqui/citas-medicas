import '../../core/error/resultado.dart';
import '../entities/mensaje_conversacion.dart';

/// Puente hacia el motor conversacional.
///
/// La aplicacion no ejecuta el modelo: envia el texto al backend y recibe
/// intencion, entidades y confianza.
abstract interface class AsistenteRepository {
  /// POST /api/v1/asistente/mensajes
  ///
  /// RNF-10: [texto] debe llegar disociado del titular. La implementacion es
  /// responsable de no adjuntar nombre, documento ni identificador de
  /// paciente.
  Future<Resultado<RespuestaAsistente>> analizarMensaje({
    required String texto,
    required String idConversacion,
  });
}
