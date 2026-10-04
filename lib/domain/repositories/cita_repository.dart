import '../../core/error/resultado.dart';
import '../entities/cita.dart';
import '../entities/cupo_disponible.dart';
import '../entities/estado_cita.dart';
import '../entities/intencion_asistente.dart';

/// Disponibilidad y ciclo de vida de las citas.
abstract interface class CitaRepository {
  /// GET /api/v1/cupos?especialidadId=&profesionalId=&fecha= — HU-05.
  Future<Resultado<List<CupoDisponible>>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
    TurnoDia? turno,
  });

  /// POST /api/v1/citas — HU-06.
  ///
  /// [claveIdempotencia] cumple RNF-07: reintentar el mismo intento tras una
  /// caida de red no debe crear una segunda cita.
  Future<Resultado<Cita>> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required CanalReserva canal,
    required String claveIdempotencia,
  });

  /// GET /api/v1/citas?pacienteId=&estado= — HU-09.
  Future<Resultado<List<Cita>>> obtenerCitas({
    required String pacienteId,
    EstadoCita? estado,
  });

  /// GET /api/v1/citas (sin `pacienteId`) — HU-11.
  ///
  /// Todas las citas de la clinica, para el panel de indicadores. **Solo para
  /// cuentas de administracion**: la comprobacion la hace RN-01 en el cliente,
  /// pero la garantia real tiene que darla el backend, que debe rechazar esta
  /// peticion a cualquier token que no sea de administracion.
  ///
  /// No se guarda en el dispositivo: un volcado de las citas de terceros en el
  /// telefono de quien administra no tiene justificacion.
  Future<Resultado<List<Cita>>> obtenerTodasLasCitas();

  /// PATCH /api/v1/citas/{id}/reprogramar — HU-07, sujeto a RN-06.
  Future<Resultado<Cita>> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  });

  /// PATCH /api/v1/citas/{id}/cancelar — HU-07, sujeto a RN-06.
  Future<Resultado<Cita>> cancelar(String citaId);

  /// Historial cacheado en sqflite, consultable sin conexion (HU-09).
  Future<Resultado<List<Cita>>> obtenerHistorialLocal(
    String pacienteId, {
    EstadoCita? estado,
  });

  /// Momento de la ultima sincronizacion con el backend, para informarlo en
  /// el historial sin conexion (HU-09). `null` si nunca se sincronizo.
  Future<Resultado<DateTime?>> obtenerFechaUltimaSincronizacion([
    String? pacienteId,
  ]);
}
