import '../../../core/network/api_client.dart';
import '../../models/paciente_dto.dart';

/// Contrato de la fuente de datos de cuentas.
///
/// Dos implementaciones intercambiables: [ApiPacienteDataSource] contra el
/// backend real y `FakePacienteDataSource` con cuentas locales de desarrollo.
abstract interface class PacienteDataSource {
  /// POST /api/v1/pacientes
  Future<SesionDto> registrar({
    required PacienteDto paciente,
    required String clave,
  });

  Future<SesionDto> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  });

  /// GET /api/v1/pacientes/{id}
  Future<PacienteDto> obtenerPorId(String id);

  /// POST /api/v1/pacientes/{id}/consentimiento
  Future<PacienteDto> otorgarConsentimiento(String pacienteId);

  /// DELETE /api/v1/pacientes/{id}/consentimiento
  Future<PacienteDto> revocarConsentimiento(String pacienteId);

  /// HU-12: solicitud de eliminacion de datos del titular.
  Future<void> solicitarEliminacionDeDatos(String pacienteId);
}

class ApiPacienteDataSource implements PacienteDataSource {
  ApiPacienteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<SesionDto> registrar({
    required PacienteDto paciente,
    required String clave,
  }) async {
    final respuesta = await _api.post(
      '/pacientes',
      cuerpo: <String, dynamic>{...paciente.toJson(), 'clave': clave},
    );
    return SesionDto.fromJson(respuesta);
  }

  @override
  Future<SesionDto> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  }) async {
    final respuesta = await _api.post(
      '/pacientes/sesiones',
      cuerpo: <String, dynamic>{
        'numeroDocumento': numeroDocumento,
        'clave': clave,
      },
    );
    return SesionDto.fromJson(respuesta);
  }

  @override
  Future<PacienteDto> obtenerPorId(String id) async =>
      PacienteDto.fromJson(await _api.get('/pacientes/$id'));

  @override
  Future<PacienteDto> otorgarConsentimiento(String pacienteId) async =>
      PacienteDto.fromJson(
        await _api.post('/pacientes/$pacienteId/consentimiento'),
      );

  @override
  Future<PacienteDto> revocarConsentimiento(String pacienteId) async =>
      PacienteDto.fromJson(
        await _api.delete('/pacientes/$pacienteId/consentimiento'),
      );

  @override
  Future<void> solicitarEliminacionDeDatos(String pacienteId) =>
      _api.post('/pacientes/$pacienteId/eliminacion');
}
