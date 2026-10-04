import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/error/resultado.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/repositories/paciente_repository.dart';
import 'package:citas_medicas_app/domain/repositories/preferencias_repository.dart';
import 'package:citas_medicas_app/domain/rules/rn10_consentimiento.dart';

/// Dobles de prueba compartidos por los tests de widget de la Fase 1.

/// Repositorio de cuentas en memoria.
///
/// Mantiene el paciente actual y simula registro, inicio de sesion y los
/// cambios de consentimiento sin tocar almacenamiento ni red.
class PacienteRepositoryStub implements PacienteRepository {
  PacienteRepositoryStub({
    this.paciente,
    this.falloEnInicioSesion,
    this.falloEnRegistro,
  });

  /// Paciente devuelto por [obtenerSesionActiva]. `null` = sin sesion.
  Paciente? paciente;

  /// Si se indica, [iniciarSesion] falla con este error.
  final FalloApp? falloEnInicioSesion;

  /// Si se indica, [registrar] falla con este error.
  final FalloApp? falloEnRegistro;

  int vecesRegistrar = 0;
  int vecesIniciarSesion = 0;
  int vecesEliminarDatos = 0;

  /// Ultimas credenciales recibidas, para comprobar la normalizacion.
  String? ultimoDocumentoRecibido;
  Paciente? ultimoPacienteRecibido;

  @override
  Future<Resultado<Paciente>> registrar({
    required Paciente paciente,
    required String clave,
  }) async {
    vecesRegistrar++;
    ultimoPacienteRecibido = paciente;

    if (falloEnRegistro != null) {
      return Resultado<Paciente>.fallo(falloEnRegistro!);
    }

    final creado = paciente.copyWith(id: 'pac-nuevo');
    this.paciente = creado;
    return Resultado<Paciente>.exito(creado);
  }

  @override
  Future<Resultado<Paciente>> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  }) async {
    vecesIniciarSesion++;
    ultimoDocumentoRecibido = numeroDocumento;

    if (falloEnInicioSesion != null) {
      return Resultado<Paciente>.fallo(falloEnInicioSesion!);
    }

    final actual = paciente;
    if (actual == null) return const Resultado.fallo(FalloAutenticacion());
    return Resultado<Paciente>.exito(actual);
  }

  @override
  Future<Resultado<void>> cerrarSesion() async {
    paciente = null;
    return const Resultado<void>.exito(null);
  }

  @override
  Future<Resultado<Paciente?>> obtenerSesionActiva() async =>
      Resultado<Paciente?>.exito(paciente);

  @override
  Future<Resultado<Paciente>> obtenerPorId(String id) async {
    final actual = paciente;
    if (actual == null) return const Resultado.fallo(FalloNoEncontrado());
    return Resultado<Paciente>.exito(actual);
  }

  @override
  Future<Resultado<Paciente>> otorgarConsentimiento(String pacienteId) async {
    final actual = paciente;
    if (actual == null) return const Resultado.fallo(FalloNoEncontrado());
    paciente = Rn10Consentimiento.otorgar(actual, ahora: DateTime(2026, 9, 15));
    return Resultado<Paciente>.exito(paciente!);
  }

  @override
  Future<Resultado<Paciente>> revocarConsentimiento(String pacienteId) async {
    final actual = paciente;
    if (actual == null) return const Resultado.fallo(FalloNoEncontrado());
    paciente = Rn10Consentimiento.revocar(actual);
    return Resultado<Paciente>.exito(paciente!);
  }

  @override
  Future<Resultado<void>> solicitarEliminacionDeDatos(
    String pacienteId,
  ) async {
    vecesEliminarDatos++;
    paciente = null;
    return const Resultado<void>.exito(null);
  }
}

/// Preferencias en memoria, para no depender de `shared_preferences`.
class PreferenciasStub implements PreferenciasRepository {
  bool? temaOscuro;
  bool limpiado = false;

  @override
  Future<Resultado<bool?>> obtenerPreferenciaTemaOscuro() async =>
      Resultado<bool?>.exito(temaOscuro);

  @override
  Future<Resultado<void>> guardarPreferenciaTemaOscuro(bool? oscuro) async {
    temaOscuro = oscuro;
    return const Resultado<void>.exito(null);
  }

  @override
  Future<Resultado<bool>> obtenerIntroduccionVista() async =>
      const Resultado<bool>.exito(false);

  @override
  Future<Resultado<void>> guardarIntroduccionVista(bool vista) async =>
      const Resultado<void>.exito(null);

  /// Se guarda de verdad: HU-08 comprueba que el permiso se pide una sola vez.
  bool permisoNotificacionesSolicitado = false;

  @override
  Future<Resultado<bool>> obtenerPermisoNotificacionesSolicitado() async =>
      Resultado<bool>.exito(permisoNotificacionesSolicitado);

  @override
  Future<Resultado<void>> guardarPermisoNotificacionesSolicitado(
    bool valor,
  ) async {
    permisoNotificacionesSolicitado = valor;
    return const Resultado<void>.exito(null);
  }

  @override
  Future<Resultado<void>> limpiarTodo() async {
    limpiado = true;
    return const Resultado<void>.exito(null);
  }
}
