import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/mensaje_conversacion.dart';
import '../../domain/repositories/asistente_repository.dart';
import '../../domain/rules/rn09_guardarrail_clinico.dart';
import '../../l10n/cadenas.dart';
import '../datasources/remote/asistente_remote_datasource.dart';

/// Implementa el contrato del asistente sobre una [AsistenteDataSource].
///
/// Dos responsabilidades propias del repositorio, que no delega:
///
/// - **RN-09**: el guardarrail clinico se evalua *antes* de enviar nada. Si
///   el mensaje pide orientacion clinica, se deriva al canal de atencion y el
///   texto **no sale del dispositivo**. Asi la regla se cumple aunque el
///   modelo de Rasa no este entrenado para ello, y de paso se evita enviar un
///   relato de sintomas a un servicio de entrenamiento.
/// - **RNF-10**: lo que se envia va disociado del titular. La firma no acepta
///   identificador de paciente y el repositorio no lo adjunta.
class AsistenteRepositoryImpl implements AsistenteRepository {
  const AsistenteRepositoryImpl(this._fuente);

  final AsistenteDataSource _fuente;

  @override
  Future<Resultado<RespuestaAsistente>> analizarMensaje({
    required String texto,
    required String idConversacion,
  }) async {
    // RN-09 — se resuelve en el cliente y se corta aqui.
    if (Rn09GuardarrailClinico.requiereDerivacion(texto)) {
      return const Resultado<RespuestaAsistente>.exito(
        RespuestaAsistente(
          // Derivar no es «no entender»: la confianza es total, pero no hay
          // accion que ejecutar porque la aplicacion no orienta clinicamente.
          intencion: IntencionAsistente.noReconocida,
          confianza: 1.0,
          respuesta: Cadenas.derivacionCanalAtencion,
          derivadoACanalAtencion: true,
        ),
      );
    }

    try {
      final dto = await _fuente.analizarMensaje(
        texto: texto,
        idConversacion: idConversacion,
      );
      return Resultado<RespuestaAsistente>.exito(dto.aDominio());
    } on FalloApp catch (fallo) {
      return Resultado<RespuestaAsistente>.fallo(fallo);
    } catch (e) {
      return Resultado<RespuestaAsistente>.fallo(
        FalloServidor(
          'El asistente no esta disponible en este momento.',
          codigo: 'ASISTENTE_NO_DISPONIBLE',
          detalles: e.toString(),
        ),
      );
    }
  }
}
