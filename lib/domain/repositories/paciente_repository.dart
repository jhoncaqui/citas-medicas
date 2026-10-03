import '../../core/error/resultado.dart';
import '../entities/paciente.dart';

/// Registro, sesion y consentimiento del paciente.
abstract interface class PacienteRepository {
  /// POST /api/v1/pacientes — HU-01.
  Future<Resultado<Paciente>> registrar({
    required Paciente paciente,
    required String clave,
  });

  /// HU-02. Devuelve [FalloAutenticacion] con un mensaje generico que no
  /// revela cual credencial fallo.
  Future<Resultado<Paciente>> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  });

  Future<Resultado<void>> cerrarSesion();

  /// Paciente de la sesion activa, o `null` si no hay ninguna.
  Future<Resultado<Paciente?>> obtenerSesionActiva();

  /// GET /api/v1/pacientes/{id}
  Future<Resultado<Paciente>> obtenerPorId(String id);

  /// POST /api/v1/pacientes/{id}/consentimiento — RN-10.
  Future<Resultado<Paciente>> otorgarConsentimiento(String pacienteId);

  /// DELETE /api/v1/pacientes/{id}/consentimiento — HU-12.
  Future<Resultado<Paciente>> revocarConsentimiento(String pacienteId);

  /// HU-12: solicitud de eliminacion de datos del titular.
  Future<Resultado<void>> solicitarEliminacionDeDatos(String pacienteId);
}
