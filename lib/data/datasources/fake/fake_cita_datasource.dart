// =====================================================================
// DISPONIBILIDAD Y CITAS EN MEMORIA — DATOS FICTICIOS
// =====================================================================
//
// Sustituye al backend Spring Boot mientras `FeatureFlags.usarBackendReal`
// este en `false`. Los cupos salen de `fixtures.dart` y son inventados.
//
// Reproduce el comportamiento que el backend debe garantizar:
//   - RN-03: confirmar una reserva bloquea el cupo de inmediato; un segundo
//     intento sobre el mismo cupo se rechaza.
//   - RNF-07: la clave de idempotencia deduplica reintentos, de modo que una
//     caida de red a mitad de la confirmacion no genera dos citas.
//
// El estado se persiste en la misma base sqflite que usa la aplicacion: sin
// eso, cerrar la app equivaldria a que el servidor olvidara todas las citas,
// y el historial de HU-09 apareceria vacio justo despues de reservar.
// =====================================================================

import '../../../core/config/app_config.dart';
import '../../../core/error/excepciones.dart';
import '../../../domain/entities/cupo_disponible.dart';
import '../../../domain/entities/estado_cita.dart';
import '../../models/cita_dto.dart';
import '../local/cita_local_datasource.dart';
import '../remote/cita_remote_datasource.dart';
import 'fixtures.dart';

class FakeCitaDataSource implements CitaDataSource {
  FakeCitaDataSource({
    CitaLocalDataSource? persistencia,
    this.latencia = AppConfig.latenciaSimulada,
    DateTime Function()? reloj,
  }) : _persistencia = persistencia,
       _reloj = reloj ?? DateTime.now;

  /// Almacen del «servidor» simulado.
  ///
  /// Cuando se inyecta, las citas sobreviven al cierre de la aplicacion. Los
  /// tests lo omiten y trabajan solo en memoria.
  final CitaLocalDataSource? _persistencia;

  final Duration latencia;
  final DateTime Function() _reloj;

  /// Citas creadas, indexadas por identificador.
  final Map<String, CitaDto> _citas = <String, CitaDto>{};

  /// RNF-07: clave de idempotencia -> identificador de la cita creada.
  final Map<String, String> _porClaveIdempotencia = <String, String>{};

  /// Cupos bloqueados. Incluye los que ocupa este paciente y los que
  /// [ocuparCupoExternamente] marca como tomados por otra persona.
  final Set<String> _cuposOcupados = <String>{};

  /// Simula que **otro paciente** reserva el cupo mientras este tiene la
  /// pantalla abierta. Es el caso que HU-05 exige manejar.
  void ocuparCupoExternamente(String cupoId) => _cuposOcupados.add(cupoId);

  int _contadorIds = 0;

  bool _cargado = false;

  /// Reconstruye el estado del «servidor» desde la base local.
  ///
  /// Se hace una sola vez por instancia y de forma perezosa: la primera
  /// operacion que lo necesite lo dispara.
  Future<void> _asegurarCargado() async {
    final persistencia = _persistencia;
    if (_cargado || persistencia == null) return;
    _cargado = true;

    try {
      for (final cita in await persistencia.obtenerTodas()) {
        _citas[cita.id] = cita;
        final clave = cita.claveIdempotencia;
        if (clave != null) _porClaveIdempotencia[clave] = cita.id;
        // RN-03: un cupo con cita activa sigue bloqueado tras reiniciar.
        if (EstadoCita.desdeClave(cita.estado).esActiva) {
          _cuposOcupados.add(cita.cupoId);
        }
      }
    } catch (_) {
      // Sin estado previo: se empieza en limpio.
    }
  }

  Future<void> _persistir(CitaDto cita) async {
    try {
      await _persistencia?.guardarCita(cita);
    } catch (_) {
      // El modo demostracion sigue funcionando en memoria.
    }
  }

  // -------------------------------------------------------------------

  @override
  Future<List<CupoDto>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
  }) async {
    await Future<void>.delayed(latencia);
    // RN-03: sin esto, un cupo reservado antes de reiniciar volveria a
    // ofrecerse como libre.
    await _asegurarCargado();

    final profesionalesDeEspecialidad = Fixtures.profesionales
        .where((p) => p.especialidadId == especialidadId)
        .map((p) => p.id)
        .toSet();

    if (profesionalesDeEspecialidad.isEmpty) return const <CupoDto>[];

    final ahora = _reloj();
    final cupos = Fixtures.generarCupos(desde: ahora);

    final filtrados = cupos.where((c) {
      if (!profesionalesDeEspecialidad.contains(c.profesionalId)) return false;
      if (profesionalId != null && c.profesionalId != profesionalId) {
        return false;
      }
      if (fecha != null && !_mismoDia(c.fechaHoraInicio, fecha)) return false;
      return true;
    });

    return filtrados
        .map(
          (c) => CupoDto.desdeDominio(
            c.copyWith(disponible: !_cuposOcupados.contains(c.id)),
          ),
        )
        .toList();
  }

  @override
  Future<CitaDto> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required String canal,
    required String claveIdempotencia,
  }) async {
    await Future<void>.delayed(latencia);
    await _asegurarCargado();

    // RNF-07: el mismo intento devuelve la misma cita, sin crear otra.
    final yaCreada = _porClaveIdempotencia[claveIdempotencia];
    if (yaCreada != null) return _citas[yaCreada]!;

    // RN-03: el cupo solo admite una cita activa.
    if (_cuposOcupados.contains(cupoId)) {
      throw const FalloReglaNegocio(
        'Ese horario acaba de ocuparse. Elige otro, por favor.',
        regla: 'RN-03',
      );
    }

    final cupo = _buscarCupo(cupoId);
    if (cupo == null) {
      throw const FalloNoEncontrado('Ese horario ya no esta disponible.');
    }

    final ahora = _reloj();
    // El contador hace el id unico aunque el reloj no avance: un id derivado
    // solo del tiempo colisiona si dos reservas comparten instante, y la
    // segunda pisaria a la primera.
    final id = 'cita-${ahora.microsecondsSinceEpoch}-${_contadorIds++}';
    final profesional = Fixtures.profesionales
        .where((p) => p.id == cupo.profesionalId)
        .firstOrNull;

    final cita = CitaDto(
      id: id,
      pacienteId: pacienteId,
      cupoId: cupoId,
      estado: EstadoCita.confirmada.clave,
      fechaCreacion: ahora.toIso8601String(),
      canalReserva: canal,
      claveIdempotencia: claveIdempotencia,
      especialidadId: profesional?.especialidadId,
      profesionalId: cupo.profesionalId,
      sedeId: cupo.sedeId,
      consultorioId: cupo.consultorioId,
      fechaHoraInicio: cupo.fechaHoraInicio.toIso8601String(),
    );

    _citas[id] = cita;
    _porClaveIdempotencia[claveIdempotencia] = id;
    // RN-03: la confirmacion bloquea el cupo de forma inmediata.
    _cuposOcupados.add(cupoId);
    await _persistir(cita);

    return cita;
  }

  @override
  Future<List<CitaDto>> obtenerCitas({
    required String pacienteId,
    String? estado,
  }) async {
    await Future<void>.delayed(latencia);
    await _asegurarCargado();
    return _citas.values
        .where((c) => c.pacienteId == pacienteId)
        .where((c) => estado == null || c.estado == estado)
        .toList();
  }

  @override
  Future<List<CitaDto>> obtenerTodasLasCitas() async {
    await Future<void>.delayed(latencia);
    await _asegurarCargado();
    return _citas.values.toList();
  }

  @override
  Future<CitaDto> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  }) async {
    await Future<void>.delayed(latencia);
    await _asegurarCargado();

    final actual = _citas[citaId];
    if (actual == null) throw const FalloNoEncontrado();

    if (_cuposOcupados.contains(nuevoCupoId)) {
      throw const FalloReglaNegocio(
        'Ese horario acaba de ocuparse. Elige otro, por favor.',
        regla: 'RN-03',
      );
    }

    final nuevoCupo = _buscarCupo(nuevoCupoId);
    if (nuevoCupo == null) {
      throw const FalloNoEncontrado('Ese horario ya no esta disponible.');
    }

    // El cupo anterior queda libre y el nuevo pasa a estar bloqueado.
    _cuposOcupados.remove(actual.cupoId);
    _cuposOcupados.add(nuevoCupoId);

    final actualizada = CitaDto(
      id: actual.id,
      pacienteId: actual.pacienteId,
      cupoId: nuevoCupoId,
      estado: EstadoCita.reprogramada.clave,
      fechaCreacion: actual.fechaCreacion,
      canalReserva: actual.canalReserva,
      claveIdempotencia: actual.claveIdempotencia,
      especialidadId: actual.especialidadId,
      profesionalId: nuevoCupo.profesionalId,
      sedeId: nuevoCupo.sedeId,
      consultorioId: nuevoCupo.consultorioId,
      fechaHoraInicio: nuevoCupo.fechaHoraInicio.toIso8601String(),
    );

    _citas[citaId] = actualizada;
    await _persistir(actualizada);
    return actualizada;
  }

  @override
  Future<CitaDto> cancelar(String citaId) async {
    await Future<void>.delayed(latencia);
    await _asegurarCargado();

    final actual = _citas[citaId];
    if (actual == null) throw const FalloNoEncontrado();

    // Cancelar libera el cupo para otros pacientes.
    _cuposOcupados.remove(actual.cupoId);

    final cancelada = CitaDto(
      id: actual.id,
      pacienteId: actual.pacienteId,
      cupoId: actual.cupoId,
      estado: EstadoCita.cancelada.clave,
      fechaCreacion: actual.fechaCreacion,
      canalReserva: actual.canalReserva,
      claveIdempotencia: actual.claveIdempotencia,
      especialidadId: actual.especialidadId,
      profesionalId: actual.profesionalId,
      sedeId: actual.sedeId,
      consultorioId: actual.consultorioId,
      fechaHoraInicio: actual.fechaHoraInicio,
    );

    _citas[citaId] = cancelada;
    await _persistir(cancelada);
    return cancelada;
  }

  // -------------------------------------------------------------------

  CupoDisponible? _buscarCupo(String cupoId) {
    final cupos = Fixtures.generarCupos(desde: _reloj());
    for (final c in cupos) {
      if (c.id == cupoId) return c;
    }
    return null;
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
