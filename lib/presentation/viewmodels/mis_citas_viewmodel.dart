import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/notificaciones/servicio_recordatorios.dart';
import '../../domain/entities/cita.dart';
import '../../domain/repositories/cita_repository.dart';
import '../../domain/rules/rn01_autenticacion.dart';
import '../../domain/rules/rn06_rn07_rn08_gestion.dart';
import 'sesion_viewmodel.dart';

/// HU-07 y HU-09 — Gestion de citas e historial sin conexion.
class MisCitasViewModel extends ChangeNotifier {
  MisCitasViewModel(
    this._citas,
    this._sesion,
    this._recordatorios, {
    ConnectivityService? conectividad,
    DateTime Function()? reloj,
  }) : _conectividad = conectividad,
       _reloj = reloj ?? DateTime.now;

  // `conectividad` se declara con nombre publico aunque el campo sea privado:
  // el nombre del parametro es parte de la API del constructor.

  final CitaRepository _citas;
  final SesionViewModel _sesion;
  final ServicioRecordatorios _recordatorios;

  /// `null` en los tests que no necesitan simular la red.
  final ConnectivityService? _conectividad;

  final DateTime Function() _reloj;

  List<Cita> _todas = const <Cita>[];

  /// Citas activas, de la mas proxima a la mas lejana.
  List<Cita> get proximas {
    final activas = _todas.where((c) => c.esActiva).toList();
    activas.sort((a, b) {
      final fa = a.fechaHoraInicio ?? a.fechaCreacion;
      final fb = b.fechaHoraInicio ?? b.fechaCreacion;
      return fa.compareTo(fb);
    });
    return activas;
  }

  /// Citas ya cerradas: atendidas, canceladas o con inasistencia.
  List<Cita> get pasadas => _todas.where((c) => !c.esActiva).toList();

  bool _cargando = false;
  bool get cargando => _cargando;

  bool _ocupado = false;
  bool get ocupado => _ocupado;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  /// HU-09: momento de la ultima sincronizacion con el backend.
  DateTime? _ultimaSincronizacion;
  DateTime? get ultimaSincronizacion => _ultimaSincronizacion;

  /// `true` si lo que se muestra salio de la cache local.
  bool _sinConexion = false;
  bool get sinConexion => _sinConexion;

  DateTime get ahora => _reloj();

  // -------------------------------------------------------------------

  Future<void> cargar() async {
    final paciente = _sesion.paciente;
    if (paciente == null) return;

    _cargando = true;
    _fallo = null;
    notifyListeners();

    final resultado = await _citas.obtenerCitas(pacienteId: paciente.id);
    resultado.when(exito: (lista) => _todas = lista, fallo: (f) => _fallo = f);

    final sincronizacion = await _citas.obtenerFechaUltimaSincronizacion(
      paciente.id,
    );
    _ultimaSincronizacion = sincronizacion.valorONull;

    // «Sin conexion» es un hecho del dispositivo, no algo que se deduzca del
    // repositorio: se consulta directamente.
    _sinConexion = !(await _hayConexion());

    _cargando = false;
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // RN-06 — que puede hacer el paciente con cada cita
  // -------------------------------------------------------------------

  bool puedeCancelar(Cita cita) => Rn06Autogestion.sePuede(
    cita: cita,
    accion: AccionAutogestion.cancelar,
    ahora: _reloj(),
  );

  bool puedeReprogramar(Cita cita) => Rn06Autogestion.sePuede(
    cita: cita,
    accion: AccionAutogestion.reprogramar,
    ahora: _reloj(),
  );

  /// Motivo por el que no se puede gestionar, o `null` si si se puede.
  String? motivoBloqueo(Cita cita, AccionAutogestion accion) {
    final veredicto = Rn06Autogestion.validar(
      cita: cita,
      accion: accion,
      ahora: _reloj(),
    );
    return veredicto.cumple ? null : veredicto.mensaje;
  }

  // -------------------------------------------------------------------
  // HU-07 — cancelar
  // -------------------------------------------------------------------

  Future<bool> cancelar(Cita cita) async {
    // RN-01: la operacion se vuelve a comprobar antes de tocar el
    // repositorio, no solo al pintar el boton.
    final impedimento = _sesion.impedimentoPara(OperacionProtegida.cancelar);
    if (impedimento != null) {
      _fallo = FalloReglaNegocio(impedimento, regla: 'RN-01');
      notifyListeners();
      return false;
    }

    // RN-06: el tiempo pasa mientras la pantalla esta abierta.
    final veredicto = Rn06Autogestion.validar(
      cita: cita,
      accion: AccionAutogestion.cancelar,
      ahora: _reloj(),
    );
    if (veredicto.infringida) {
      _fallo = FalloReglaNegocio(veredicto.mensaje!, regla: veredicto.regla);
      notifyListeners();
      return false;
    }

    _ocupado = true;
    _fallo = null;
    notifyListeners();

    final resultado = await _citas.cancelar(cita.id);

    final exito = resultado.when(
      exito: (actualizada) {
        _reemplazar(actualizada);
        return true;
      },
      fallo: (f) {
        _fallo = f;
        return false;
      },
    );

    // Una cita cancelada no debe seguir avisando (RN-07).
    if (exito) await _recordatorios.cancelar(cita.id);

    _ocupado = false;
    notifyListeners();
    return exito;
  }

  // -------------------------------------------------------------------
  // HU-07 — reprogramar
  // -------------------------------------------------------------------

  Future<bool> reprogramar({
    required Cita cita,
    required String nuevoCupoId,
  }) async {
    final impedimento = _sesion.impedimentoPara(OperacionProtegida.reprogramar);
    if (impedimento != null) {
      _fallo = FalloReglaNegocio(impedimento, regla: 'RN-01');
      notifyListeners();
      return false;
    }

    final veredicto = Rn06Autogestion.validar(
      cita: cita,
      accion: AccionAutogestion.reprogramar,
      ahora: _reloj(),
    );
    if (veredicto.infringida) {
      _fallo = FalloReglaNegocio(veredicto.mensaje!, regla: veredicto.regla);
      notifyListeners();
      return false;
    }

    _ocupado = true;
    _fallo = null;
    notifyListeners();

    final resultado = await _citas.reprogramar(
      citaId: cita.id,
      nuevoCupoId: nuevoCupoId,
    );

    final exito = resultado.when(
      exito: (actualizada) {
        _reemplazar(actualizada);
        return true;
      },
      fallo: (f) {
        _fallo = f;
        return false;
      },
    );

    if (exito) {
      // El recordatorio anterior apunta a una hora que ya no existe.
      await _recordatorios.cancelar(cita.id);
      final actualizada = _todas.where((c) => c.id == cita.id).firstOrNull;
      if (actualizada != null) await _recordatorios.programar(actualizada);
    }

    _ocupado = false;
    notifyListeners();
    return exito;
  }

  // -------------------------------------------------------------------

  void limpiarFallo() {
    if (_fallo == null) return;
    _fallo = null;
    notifyListeners();
  }

  Future<bool> _hayConexion() async {
    final servicio = _conectividad;
    if (servicio == null) return true;
    try {
      return await servicio.hayConexion;
    } catch (_) {
      return true;
    }
  }

  void _reemplazar(Cita actualizada) {
    _todas = _todas
        .map((c) => c.id == actualizada.id ? actualizada : c)
        .toList();
  }
}
