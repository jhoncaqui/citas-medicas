import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../core/network/connectivity_service.dart';
import '../../domain/entities/cita.dart';
import '../../domain/entities/cupo_disponible.dart';
import '../../domain/entities/estado_cita.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/repositories/cita_repository.dart';
import '../../domain/rules/rn03_rn04_rn05_reserva.dart';
import '../../domain/rules/rn06_rn07_rn08_gestion.dart';
import '../datasources/local/cita_local_datasource.dart';
import '../datasources/remote/cita_remote_datasource.dart';
import '../models/cita_dto.dart';

/// Implementa el contrato de citas sobre una fuente remota y la cache local.
///
/// Politica de datos:
///
/// - **Disponibilidad** (cupos): siempre remota. Un cupo cacheado es un cupo
///   que probablemente ya no existe.
/// - **Historial**: remoto cuando hay conexion, guardando siempre en sqflite;
///   local cuando no la hay (HU-09). El paciente ve sus citas aunque este sin
///   cobertura, y se le informa de cuando son los datos.
class CitaRepositoryImpl implements CitaRepository {
  CitaRepositoryImpl(
    this._fuente, {
    CitaLocalDataSource? local,
    ConnectivityService? conectividad,
    DateTime Function()? reloj,
  }) : _local = local,
       _conectividad = conectividad,
       _reloj = reloj ?? DateTime.now;

  // Los tres parametros opcionales se declaran con nombre publico y se
  // asignan a campos privados: el nombre del parametro forma parte de la API
  // del constructor y no deberia llevar guion bajo.

  final CitaDataSource _fuente;

  /// `null` en los tests que no necesitan persistencia.
  final CitaLocalDataSource? _local;

  final ConnectivityService? _conectividad;
  final DateTime Function() _reloj;

  /// `true` si el ultimo historial devuelto salio de la cache local.
  bool _ultimoHistorialDesdeCache = false;
  bool get ultimoHistorialDesdeCache => _ultimoHistorialDesdeCache;

  @override
  Future<Resultado<List<CupoDisponible>>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
    TurnoDia? turno,
  }) => _ejecutar(() async {
    final dtos = await _fuente.obtenerCupos(
      especialidadId: especialidadId,
      profesionalId: profesionalId,
      fecha: fecha,
    );

    var cupos = dtos.map((d) => d.aDominio()).toList();

    // RN-04: nunca se ofrecen horarios anteriores al momento actual.
    cupos = Rn04NoEnElPasado.filtrar(cupos, ahora: _reloj());

    if (turno != null) {
      cupos = cupos.where((c) => _esDelTurno(c, turno)).toList();
    }

    cupos.sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
    return cupos;
  });

  @override
  Future<Resultado<Cita>> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required CanalReserva canal,
    required String claveIdempotencia,
  }) => _ejecutar(() async {
    final dto = await _fuente.confirmarReserva(
      pacienteId: pacienteId,
      cupoId: cupoId,
      canal: canal.clave,
      claveIdempotencia: claveIdempotencia,
    );
    // La cita recien creada entra en la cache sin esperar a la proxima
    // sincronizacion: el historial debe verla de inmediato.
    // El try/catch protege plataformas donde sqflite no esta disponible
    // (Flutter Web): la confirmacion ya existe en memoria y no debe fallar
    // porque la cache local no pudo escribir.
    try {
      await _local?.guardarCita(dto);
    } catch (_) {}
    return dto.aDominio();
  });

  @override
  Future<Resultado<List<Cita>>> obtenerCitas({
    required String pacienteId,
    EstadoCita? estado,
  }) async {
    final hayConexion = await _hayConexion();

    if (hayConexion) {
      final remoto = await _ejecutar<List<Cita>>(() async {
        final dtos = await _fuente.obtenerCitas(
          pacienteId: pacienteId,
          estado: estado?.clave,
        );

        final momento = _reloj();
        // Solo se cachea el historial completo: guardar un listado filtrado
        // borraria del cache las citas que el filtro dejo fuera.
        if (estado == null) {
          try {
            await _local?.guardarHistorial(
              pacienteId: pacienteId,
              citas: dtos,
              momento: momento,
            );
          } catch (_) {}
        }

        _ultimoHistorialDesdeCache = false;
        return _ordenarYCorregir(dtos);
      });

      // Con conexion pero con fallo del servidor, la cache sigue siendo mejor
      // que una pantalla vacia.
      if (remoto.esExito) return remoto;
    }

    return obtenerHistorialLocal(pacienteId, estado: estado);
  }

  @override
  Future<Resultado<List<Cita>>> obtenerTodasLasCitas() => _ejecutar(() async {
    // Siempre remoto y nunca a la cache local: no se guardan en el
    // dispositivo las citas de otros pacientes.
    final dtos = await _fuente.obtenerTodasLasCitas();
    return _ordenarYCorregir(dtos);
  });

  @override
  Future<Resultado<Cita>> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  }) => _ejecutar(() async {
    final dto = await _fuente.reprogramar(
      citaId: citaId,
      nuevoCupoId: nuevoCupoId,
    );
    try {
      await _local?.guardarCita(dto);
    } catch (_) {}
    return dto.aDominio();
  });

  @override
  Future<Resultado<Cita>> cancelar(String citaId) => _ejecutar(() async {
    final dto = await _fuente.cancelar(citaId);
    try {
      await _local?.guardarCita(dto);
    } catch (_) {}
    return dto.aDominio();
  });

  @override
  Future<Resultado<List<Cita>>> obtenerHistorialLocal(
    String pacienteId, {
    EstadoCita? estado,
  }) async {
    final local = _local;
    if (local == null) {
      return const Resultado<List<Cita>>.exito(<Cita>[]);
    }

    try {
      final dtos = await local.obtenerHistorial(pacienteId);
      _ultimoHistorialDesdeCache = true;

      final citas = _ordenarYCorregir(dtos);
      if (estado == null) return Resultado<List<Cita>>.exito(citas);
      return Resultado<List<Cita>>.exito(
        citas.where((c) => c.estado == estado).toList(),
      );
    } catch (e) {
      return Resultado<List<Cita>>.fallo(
        FalloAlmacenamientoLocal(
          'No se pudo leer el historial guardado en el dispositivo.',
        ),
      );
    }
  }

  @override
  Future<Resultado<DateTime?>> obtenerFechaUltimaSincronizacion([
    String? pacienteId,
  ]) async {
    final local = _local;
    if (local == null || pacienteId == null) {
      return const Resultado<DateTime?>.exito(null);
    }
    try {
      return Resultado<DateTime?>.exito(
        await local.obtenerUltimaSincronizacion(pacienteId),
      );
    } catch (_) {
      return const Resultado<DateTime?>.exito(null);
    }
  }

  /// HU-12: borra el historial guardado en el dispositivo.
  Future<void> borrarDatosLocales() async => _local?.borrarTodo();

  // -------------------------------------------------------------------

  /// Ordena de la mas proxima a la mas lejana y aplica RN-08.
  List<Cita> _ordenarYCorregir(List<CitaDto> dtos) {
    final ahora = _reloj();

    final citas = dtos
        .map((d) => d.aDominio())
        // RN-08: una cita confirmada cuya hora ya paso sin atencion
        // registrada se muestra como inasistencia, sin esperar a que el
        // backend lo confirme en la proxima sincronizacion.
        .map((c) => Rn08Inasistencia.aplicar(cita: c, ahora: ahora))
        .toList();

    citas.sort((a, b) {
      final fa = a.fechaHoraInicio ?? a.fechaCreacion;
      final fb = b.fechaHoraInicio ?? b.fechaCreacion;
      return fb.compareTo(fa);
    });
    return citas;
  }

  Future<bool> _hayConexion() async {
    final servicio = _conectividad;
    if (servicio == null) return true;
    try {
      return await servicio.hayConexion;
    } catch (_) {
      // Si no se puede determinar, se intenta la red: el peor caso es un
      // fallo que ya esta contemplado.
      return true;
    }
  }

  static bool _esDelTurno(CupoDisponible cupo, TurnoDia turno) {
    final hora = cupo.fechaHoraInicio.hour;
    return switch (turno) {
      TurnoDia.manana => hora < 12,
      TurnoDia.tarde => hora >= 12,
    };
  }

  Future<Resultado<T>> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return Resultado<T>.exito(await accion());
    } on FalloApp catch (fallo) {
      return Resultado<T>.fallo(fallo);
    } catch (e) {
      return Resultado<T>.fallo(
        FalloServidor(
          'Ocurrio un problema inesperado. Intentalo de nuevo.',
          codigo: 'ERROR_NO_CONTROLADO',
          detalles: e.toString(),
        ),
      );
    }
  }
}
