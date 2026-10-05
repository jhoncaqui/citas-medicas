import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dictado por voz (voz a texto) del asistente.
///
/// Se aisla `speech_to_text` tras esta interfaz (RNF-12: nada especifico de
/// plataforma suelto por el codigo) para poder sustituirlo en los tests por un
/// doble. El reconocimiento ocurre en el dispositivo; la aplicacion no envia
/// audio a ningun servidor.
abstract interface class ServicioDictado {
  /// Prepara el motor y pide el permiso de microfono. Devuelve `true` si el
  /// dictado quedo disponible. Es idempotente: llamarlo dos veces no reinicia.
  Future<bool> inicializar();

  /// `true` tras un [inicializar] con exito.
  bool get disponible;

  /// `true` mientras se esta escuchando al paciente.
  bool get escuchando;

  /// Empieza a escuchar. [alTranscribir] se invoca con el texto reconocido
  /// hasta el momento ([definitivo] es `true` en el resultado final).
  /// [alTerminar] se llama cuando el dictado se detiene por si solo (silencio),
  /// y [alFallar] si el motor da un error.
  Future<void> escuchar({
    required String localeId,
    required void Function(String texto, bool definitivo) alTranscribir,
    void Function()? alTerminar,
    void Function(String mensaje)? alFallar,
  });

  /// Detiene el dictado conservando lo ya reconocido.
  Future<void> detener();

  /// Cancela el dictado descartando lo reconocido.
  Future<void> cancelar();
}

/// Implementacion sobre `speech_to_text`.
class ServicioDictadoImpl implements ServicioDictado {
  ServicioDictadoImpl([SpeechToText? motor]) : _motor = motor ?? SpeechToText();

  final SpeechToText _motor;

  bool _inicializado = false;
  bool _disponible = false;

  // Los listeners de estado y error se registran una sola vez en `initialize`;
  // se guardan aqui los de la escucha en curso para poder enrutarlos.
  void Function()? _alTerminar;
  void Function(String mensaje)? _alFallar;

  @override
  bool get disponible => _disponible;

  @override
  bool get escuchando => _motor.isListening;

  @override
  Future<bool> inicializar() async {
    if (_inicializado) return _disponible;
    _inicializado = true;
    try {
      _disponible = await _motor.initialize(
        onStatus: _alCambiarEstado,
        onError: _alError,
      );
    } catch (_) {
      // Sin motor de voz o permiso denegado: el chat sigue por teclado.
      _disponible = false;
    }
    return _disponible;
  }

  @override
  Future<void> escuchar({
    required String localeId,
    required void Function(String texto, bool definitivo) alTranscribir,
    void Function()? alTerminar,
    void Function(String mensaje)? alFallar,
  }) async {
    _alTerminar = alTerminar;
    _alFallar = alFallar;
    await _motor.listen(
      onResult: (resultado) =>
          alTranscribir(resultado.recognizedWords, resultado.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> detener() => _motor.stop();

  @override
  Future<void> cancelar() => _motor.cancel();

  void _alCambiarEstado(String estado) {
    if (estado == 'done' || estado == 'notListening') _alTerminar?.call();
  }

  void _alError(SpeechRecognitionError error) =>
      _alFallar?.call(error.errorMsg);
}
