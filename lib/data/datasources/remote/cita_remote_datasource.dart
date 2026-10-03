import '../../../core/network/api_client.dart';
import '../../models/cita_dto.dart';

/// Contrato de la fuente de datos de disponibilidad y citas.
abstract interface class CitaDataSource {
  /// GET /api/v1/cupos?especialidadId=&profesionalId=&fecha=
  Future<List<CupoDto>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
  });

  /// POST /api/v1/citas
  ///
  /// RNF-07: [claveIdempotencia] identifica el intento de reserva. Repetir la
  /// llamada con la misma clave debe devolver la cita ya creada, no crear una
  /// segunda.
  Future<CitaDto> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required String canal,
    required String claveIdempotencia,
  });

  /// GET /api/v1/citas?pacienteId=&estado=
  Future<List<CitaDto>> obtenerCitas({
    required String pacienteId,
    String? estado,
  });

  /// GET /api/v1/citas, sin filtro de paciente. Solo administracion.
  Future<List<CitaDto>> obtenerTodasLasCitas();

  /// PATCH /api/v1/citas/{id}/reprogramar
  Future<CitaDto> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  });

  /// PATCH /api/v1/citas/{id}/cancelar
  Future<CitaDto> cancelar(String citaId);
}

class ApiCitaDataSource implements CitaDataSource {
  ApiCitaDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<CupoDto>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
  }) async {
    final respuesta = await _api.get(
      '/cupos',
      parametros: <String, String>{
        'especialidadId': especialidadId,
        'profesionalId': ?profesionalId,
        'fecha': ?fecha?.toIso8601String(),
      },
    );
    return _lista(respuesta).map(CupoDto.fromJson).toList();
  }

  @override
  Future<CitaDto> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required String canal,
    required String claveIdempotencia,
  }) async {
    final respuesta = await _api.post(
      '/citas',
      cuerpo: <String, dynamic>{
        'pacienteId': pacienteId,
        'cupoId': cupoId,
        'canalReserva': canal,
        'claveIdempotencia': claveIdempotencia,
      },
      // Cabecera estandar de idempotencia, para que el backend pueda
      // deduplicar sin mirar el cuerpo.
      cabecerasExtra: <String, String>{'Idempotency-Key': claveIdempotencia},
    );
    return CitaDto.fromJson(respuesta);
  }

  @override
  Future<List<CitaDto>> obtenerCitas({
    required String pacienteId,
    String? estado,
  }) async {
    final respuesta = await _api.get(
      '/citas',
      parametros: <String, String>{'pacienteId': pacienteId, 'estado': ?estado},
    );
    return _lista(respuesta).map(CitaDto.fromJson).toList();
  }

  @override
  Future<List<CitaDto>> obtenerTodasLasCitas() async {
    final respuesta = await _api.get('/citas');
    return _lista(respuesta).map(CitaDto.fromJson).toList();
  }

  @override
  Future<CitaDto> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  }) async => CitaDto.fromJson(
    await _api.patch(
      '/citas/$citaId/reprogramar',
      cuerpo: <String, dynamic>{'cupoId': nuevoCupoId},
    ),
  );

  @override
  Future<CitaDto> cancelar(String citaId) async =>
      CitaDto.fromJson(await _api.patch('/citas/$citaId/cancelar'));

  List<Map<String, dynamic>> _lista(Map<String, dynamic> respuesta) {
    final datos = respuesta['datos'] ?? respuesta['contenido'];
    if (datos is List) return datos.cast<Map<String, dynamic>>();
    return const <Map<String, dynamic>>[];
  }
}
