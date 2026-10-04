import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/paciente_repository.dart';
import '../../domain/repositories/preferencias_repository.dart';
import '../../domain/rules/rn01_autenticacion.dart';
import '../../domain/rules/rn10_consentimiento.dart';

/// Estado de la sesion del paciente.
enum EstadoSesion {
  /// Todavia no se comprobo si hay una sesion guardada.
  comprobando,

  /// No hay sesion activa.
  anonimo,

  /// Hay un paciente autenticado.
  autenticado,
}

/// Fuente unica de verdad sobre quien esta autenticado.
///
/// Lo consumen la pantalla de inicio, el guardian de rutas y todas las
/// operaciones protegidas por RN-01.
class SesionViewModel extends ChangeNotifier {
  SesionViewModel(this._pacientes, this._preferencias);

  final PacienteRepository _pacientes;
  final PreferenciasRepository _preferencias;

  EstadoSesion _estado = EstadoSesion.comprobando;
  EstadoSesion get estado => _estado;

  Paciente? _paciente;
  Paciente? get paciente => _paciente;

  bool get estaAutenticado => _paciente != null;

  bool _ocupado = false;
  bool get ocupado => _ocupado;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  /// Restaura la sesion guardada al arrancar la aplicacion.
  Future<void> restaurar() async {
    final resultado = await _pacientes.obtenerSesionActiva();
    resultado.when(
      exito: (p) {
        _paciente = p;
        _estado = p == null ? EstadoSesion.anonimo : EstadoSesion.autenticado;
      },
      fallo: (_) {
        // Un fallo al restaurar no debe bloquear el arranque: se trata como
        // «no hay sesion» y el paciente puede volver a entrar.
        _paciente = null;
        _estado = EstadoSesion.anonimo;
      },
    );
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // HU-01 / HU-02
  // -------------------------------------------------------------------

  Future<bool> registrar({required Paciente paciente, required String clave}) =>
      _operacion(() => _pacientes.registrar(paciente: paciente, clave: clave));

  Future<bool> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  }) => _operacion(
    () => _pacientes.iniciarSesion(
      numeroDocumento: numeroDocumento,
      clave: clave,
    ),
  );

  Future<void> cerrarSesion() async {
    await _pacientes.cerrarSesion();
    _paciente = null;
    _estado = EstadoSesion.anonimo;
    _fallo = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // HU-12 / RN-10
  // -------------------------------------------------------------------

  Future<bool> otorgarConsentimiento() async {
    final actual = _paciente;
    if (actual == null) return false;
    return _operacion(() => _pacientes.otorgarConsentimiento(actual.id));
  }

  Future<bool> revocarConsentimiento() async {
    final actual = _paciente;
    if (actual == null) return false;
    return _operacion(() => _pacientes.revocarConsentimiento(actual.id));
  }

  /// HU-12: elimina los datos y deja el dispositivo limpio.
  Future<bool> eliminarMisDatos() async {
    final actual = _paciente;
    if (actual == null) return false;

    _ocupado = true;
    _fallo = null;
    notifyListeners();

    final resultado = await _pacientes.solicitarEliminacionDeDatos(actual.id);

    var exito = false;
    await resultado.when(
      exito: (_) async {
        // Tambien se borran las preferencias locales: no debe quedar rastro
        // del paso del paciente por la aplicacion.
        await _preferencias.limpiarTodo();
        _paciente = null;
        _estado = EstadoSesion.anonimo;
        exito = true;
      },
      fallo: (f) async => _fallo = f,
    );

    _ocupado = false;
    notifyListeners();
    return exito;
  }

  // -------------------------------------------------------------------
  // RN-01 / RN-10: comprobaciones que consultan las operaciones protegidas
  // -------------------------------------------------------------------

  /// `null` si la operacion puede continuar; el mensaje del impedimento en
  /// caso contrario.
  String? impedimentoPara(OperacionProtegida operacion) {
    final autenticacion = Rn01Autenticacion.validar(
      pacienteAutenticado: _paciente,
      operacion: operacion,
    );
    if (autenticacion.infringida) return autenticacion.mensaje;

    final consentimiento = Rn10Consentimiento.validarVigente(
      paciente: _paciente,
    );
    if (consentimiento.infringida) return consentimiento.mensaje;

    return null;
  }

  bool puede(OperacionProtegida operacion) =>
      impedimentoPara(operacion) == null;

  // -------------------------------------------------------------------

  void limpiarFallo() {
    if (_fallo == null) return;
    _fallo = null;
    notifyListeners();
  }

  /// Ejecuta una operacion del repositorio gestionando `ocupado` y `fallo`.
  ///
  /// Cuando la operacion devuelve un [Paciente], ese paciente pasa a ser el
  /// de la sesion: registro, inicio de sesion y los cambios de consentimiento
  /// comparten ese comportamiento.
  Future<bool> _operacion<T>(Future<Resultado<T>> Function() accion) async {
    _ocupado = true;
    _fallo = null;
    notifyListeners();

    final resultado = await accion();

    final exito = resultado.when(
      exito: (T valor) {
        if (valor is Paciente) {
          _paciente = valor;
          _estado = EstadoSesion.autenticado;
        }
        return true;
      },
      fallo: (FalloApp f) {
        _fallo = f;
        return false;
      },
    );

    _ocupado = false;
    notifyListeners();
    return exito;
  }
}
