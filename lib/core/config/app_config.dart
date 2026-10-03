/// Parametros de configuracion de la aplicacion.
///
/// Los plazos de las reglas RN-06 y RN-07 NO estan fijados en duro: son
/// parametros pendientes de la entrevista al personal de admision de la
/// clinica. Los valores presentes son marcadores de trabajo y deben
/// sustituirse por el dato real cuando se levante la informacion.
class AppConfig {
  const AppConfig._();

  // ---------------------------------------------------------------------
  // Red
  // ---------------------------------------------------------------------

  /// URL base del backend Spring Boot. Se inyecta por `--dart-define` para no
  /// versionar direcciones de infraestructura.
  static const String urlBaseApi = String.fromEnvironment(
    'URL_BASE_API',
    defaultValue: 'https://localhost:8443/api/v1',
  );

  /// RNF-02: la consulta de disponibilidad y la confirmacion deben resolverse
  /// en menos de 3 s. El cliente corta a los 10 s.
  static const Duration timeoutHttp = Duration(seconds: 10);

  /// RNF-02: un unico reintento, para no multiplicar la espera del paciente.
  static const int reintentosHttp = 1;

  /// Latencia simulada de las fuentes falsas, para que la interfaz se pruebe
  /// en condiciones parecidas a las reales.
  static const Duration latenciaSimulada = Duration(milliseconds: 450);

  // ---------------------------------------------------------------------
  // Reglas de negocio parametrizables
  // ---------------------------------------------------------------------

  /// RN-06 — «N horas». Antelacion minima con la que un paciente puede
  /// cancelar o reprogramar por su cuenta.
  ///
  /// PENDIENTE: valor definitivo a confirmar con el personal de admision.
  static const int horasMinimasParaAutogestion = 24;

  /// RN-07 — «M horas». Antelacion con la que se emite el recordatorio
  /// automatico.
  ///
  /// PENDIENTE: valor definitivo a confirmar con el personal de admision.
  static const int horasAntelacionRecordatorio = 24;

  /// RN-08 — margen tras la hora de la cita sin atencion registrada a partir
  /// del cual se marca inasistencia.
  ///
  /// PENDIENTE: valor definitivo a confirmar con el personal de admision.
  static const int horasParaMarcarInasistencia = 2;

  // ---------------------------------------------------------------------
  // Asistente conversacional
  // ---------------------------------------------------------------------

  /// Por debajo de este umbral el asistente pide reformulacion y no ejecuta
  /// ninguna accion.
  static const double umbralConfianza = 0.70;

  /// Tras este numero de intentos fallidos consecutivos se ofrece el flujo
  /// guiado por menus (HU-04).
  static const int intentosAntesDeFlujoGuiado = 2;

  // ---------------------------------------------------------------------
  // Localizacion
  // ---------------------------------------------------------------------

  static const String codigoIdioma = 'es';
  static const String codigoPais = 'PE';
  static const String localeCompleto = 'es_PE';
  static const String zonaHoraria = 'America/Lima';
}
