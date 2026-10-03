import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/formato_fecha.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/mensaje_conversacion.dart';
import '../../domain/repositories/asistente_repository.dart';
import '../../l10n/cadenas.dart';
import 'reserva_viewmodel.dart';

/// HU-03 — Solicitud de cita en lenguaje natural.
///
/// Tres reglas de comportamiento que no son negociables:
///
/// 1. **Umbral de confianza.** Por debajo de `AppConfig.umbralConfianza` el
///    asistente pide reformulacion y **no ejecuta ninguna accion**.
/// 2. **Fallback obligatorio.** Tras
///    `AppConfig.intentosAntesDeFlujoGuiado` intentos fallidos consecutivos
///    se ofrece el flujo guiado por menus (HU-04), que permite completar la
///    reserva sin depender del modelo.
/// 3. **La fecha resuelta siempre se muestra** para que el paciente la
///    confirme. Ninguna interpretacion se da por buena en silencio.
class ConversacionViewModel extends ChangeNotifier {
  ConversacionViewModel(
    this._asistente,
    this._reserva, {
    DateTime Function()? reloj,
    Random? aleatorio,
  }) : _reloj = reloj ?? DateTime.now,
       _aleatorio = aleatorio ?? Random() {
    _idConversacion = _generarIdConversacion();
    _mensajes.add(
      MensajeConversacion(
        id: _siguienteId(),
        rol: RolMensaje.asistente,
        texto: Cadenas.asistenteSaludo,
        marcaTiempo: _reloj(),
      ),
    );
  }

  final AsistenteRepository _asistente;
  final ReservaViewModel _reserva;
  final DateTime Function() _reloj;
  final Random _aleatorio;

  /// RNF-10: identificador **de la conversacion**, no del paciente. Se genera
  /// al azar en cada sesion de chat y no se deriva de ningun dato personal.
  late final String _idConversacion;

  final List<MensajeConversacion> _mensajes = <MensajeConversacion>[];
  List<MensajeConversacion> get mensajes => List.unmodifiable(_mensajes);

  int _contador = 0;

  bool _procesando = false;
  bool get procesando => _procesando;

  /// Intentos fallidos consecutivos.
  int _intentosFallidos = 0;
  int get intentosFallidos => _intentosFallidos;

  /// `true` cuando toca ofrecer el flujo guiado (HU-04).
  bool get debeOfrecerFlujoGuiado =>
      _intentosFallidos >= AppConfig.intentosAntesDeFlujoGuiado;

  /// El ofrecimiento del flujo guiado ya se hizo en esta racha de fallos.
  bool _flujoGuiadoOfrecido = false;

  /// Fecha interpretada pendiente de que el paciente la confirme.
  DateTime? _fechaPorConfirmar;
  DateTime? get fechaPorConfirmar => _fechaPorConfirmar;

  Map<String, String> _entidadesPendientes = const <String, String>{};

  /// `true` cuando ya hay especialidad y fecha y se puede pasar a horarios.
  bool _listoParaHorarios = false;
  bool get listoParaHorarios => _listoParaHorarios;

  // -------------------------------------------------------------------

  Future<void> enviar(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || _procesando) return;

    _agregar(RolMensaje.paciente, limpio);
    _procesando = true;
    notifyListeners();

    final resultado = await _asistente.analizarMensaje(
      texto: limpio,
      idConversacion: _idConversacion,
    );

    await resultado.when(
      exito: _procesarRespuesta,
      fallo: (fallo) async {
        _agregar(RolMensaje.asistente, fallo.mensaje);
        _intentosFallidos++;
      },
    );

    _procesando = false;
    _ofrecerFlujoGuiadoSiProcede();
    notifyListeners();
  }

  Future<void> _procesarRespuesta(RespuestaAsistente respuesta) async {
    // RN-09 — derivacion al canal de atencion. No cuenta como intento
    // fallido: el asistente entendio perfectamente, simplemente no es algo
    // que le corresponda responder.
    if (respuesta.derivadoACanalAtencion) {
      _agregar(
        RolMensaje.asistente,
        respuesta.respuesta,
        intencion: respuesta.intencion,
        confianza: respuesta.confianza,
      );
      return;
    }

    // Umbral de confianza: por debajo, se pide reformulacion y NO se ejecuta
    // ninguna accion.
    if (!respuesta.superaUmbral(AppConfig.umbralConfianza)) {
      _agregar(
        RolMensaje.asistente,
        respuesta.intencion == IntencionAsistente.noReconocida
            ? Cadenas.asistenteNoEntendi
            : Cadenas.asistenteConfianzaBaja,
        intencion: respuesta.intencion,
        confianza: respuesta.confianza,
      );
      _intentosFallidos++;
      return;
    }

    _intentosFallidos = 0;
    _flujoGuiadoOfrecido = false;

    // La Fase 2 cubre la reserva; consultar, reprogramar y cancelar se
    // atienden desde «Mis citas» hasta que la Fase 3 los implemente.
    if (respuesta.intencion != IntencionAsistente.reservar) {
      _agregar(
        RolMensaje.asistente,
        Cadenas.asistenteSoloReservas,
        intencion: respuesta.intencion,
        confianza: respuesta.confianza,
      );
      return;
    }

    _entidadesPendientes = respuesta.entidades;
    await _pedirLoQueFalta(respuesta);
  }

  Future<void> _pedirLoQueFalta(RespuestaAsistente respuesta) async {
    final entidades = respuesta.entidades;

    if (!entidades.containsKey('especialidad')) {
      _agregar(
        RolMensaje.asistente,
        Cadenas.asistenteFaltaEspecialidad,
        intencion: respuesta.intencion,
        confianza: respuesta.confianza,
      );
      // Se aplica lo que si vino, para no perderlo.
      await _reserva.aplicarEntidades(entidades);
      return;
    }

    final fechaIso = entidades['fecha'];
    if (fechaIso == null) {
      _agregar(
        RolMensaje.asistente,
        Cadenas.asistenteFaltaFecha,
        intencion: respuesta.intencion,
        confianza: respuesta.confianza,
      );
      await _reserva.aplicarEntidades(entidades);
      return;
    }

    // Hay especialidad y fecha: se muestra la fecha resuelta para que el
    // paciente la confirme antes de buscar horarios.
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) {
      _agregar(RolMensaje.asistente, Cadenas.asistenteFaltaFecha);
      return;
    }

    _fechaPorConfirmar = fecha;
    _agregar(
      RolMensaje.asistente,
      '${Cadenas.asistenteConfirmaFecha}: ${FormatoFecha.fechaLarga(fecha)}. '
      '¿Es correcto?',
      intencion: respuesta.intencion,
      confianza: respuesta.confianza,
    );
  }

  /// El paciente confirma la fecha interpretada.
  Future<void> confirmarFecha() async {
    if (_fechaPorConfirmar == null) return;

    _agregar(RolMensaje.paciente, Cadenas.asistenteSiEsCorrecto);
    _fechaPorConfirmar = null;

    _listoParaHorarios = await _reserva.aplicarEntidades(_entidadesPendientes);
    notifyListeners();
  }

  /// El paciente rechaza la fecha interpretada.
  void rechazarFecha() {
    if (_fechaPorConfirmar == null) return;

    _agregar(RolMensaje.paciente, Cadenas.asistenteNoEsCorrecto);
    _fechaPorConfirmar = null;
    _agregar(RolMensaje.asistente, Cadenas.asistenteFaltaFecha);
    notifyListeners();
  }

  /// Marca que ya se navego a los horarios, para no repetir la transicion.
  void horariosAtendidos() {
    _listoParaHorarios = false;
  }

  // -------------------------------------------------------------------

  /// Ofrece el menu una sola vez por racha de fallos.
  ///
  /// Repetir el ofrecimiento en cada intento fallido posterior llenaria la
  /// conversacion de la misma sugerencia; el boton sigue visible en pantalla
  /// mientras dure la racha, asi que basta con decirlo una vez.
  void _ofrecerFlujoGuiadoSiProcede() {
    if (!debeOfrecerFlujoGuiado || _flujoGuiadoOfrecido) return;
    _flujoGuiadoOfrecido = true;
    _agregar(RolMensaje.asistente, Cadenas.asistenteOfrecerFlujoGuiado);
  }

  void _agregar(
    RolMensaje rol,
    String texto, {
    IntencionAsistente? intencion,
    double? confianza,
  }) {
    _mensajes.add(
      MensajeConversacion(
        id: _siguienteId(),
        rol: rol,
        texto: texto,
        marcaTiempo: _reloj(),
        intencionDetectada: intencion,
        confianza: confianza,
      ),
    );
  }

  String _siguienteId() => 'msg-${_contador++}';

  String _generarIdConversacion() {
    final bytes = List<int>.generate(8, (_) => _aleatorio.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
