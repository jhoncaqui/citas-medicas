import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../core/network/api_client.dart';
import '../../core/security/almacen_seguro.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/paciente_repository.dart';
import '../datasources/remote/paciente_remote_datasource.dart';
import '../models/paciente_dto.dart';

/// Implementa el contrato de cuentas sobre una [PacienteDataSource].
///
/// Es el unico punto que toca el almacen seguro: guarda el token al abrir
/// sesion y lo borra al cerrarla o al eliminar los datos (HU-12).
class PacienteRepositoryImpl implements PacienteRepository {
  /// [_api] se pasa solo cuando se usa el backend real: hay que inyectarle el
  /// token recuperado del almacen seguro. Con las fuentes falsas es `null`.
  PacienteRepositoryImpl(this._fuente, this._almacen, [this._api]);

  final PacienteDataSource _fuente;
  final AlmacenSeguro _almacen;
  final ApiClient? _api;

  @override
  Future<Resultado<Paciente>> registrar({
    required Paciente paciente,
    required String clave,
  }) => _ejecutar(() async {
    final sesion = await _fuente.registrar(
      paciente: PacienteDto.desdeDominio(paciente),
      clave: clave,
    );
    await _abrirSesion(sesion);
    return sesion.paciente.aDominio();
  });

  @override
  Future<Resultado<Paciente>> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  }) => _ejecutar(() async {
    final sesion = await _fuente.iniciarSesion(
      numeroDocumento: numeroDocumento,
      clave: clave,
    );
    await _abrirSesion(sesion);
    return sesion.paciente.aDominio();
  });

  @override
  Future<Resultado<void>> cerrarSesion() => _ejecutar(_cerrarSesionLocal);

  @override
  Future<Resultado<Paciente?>> obtenerSesionActiva() => _ejecutar(() async {
    final token = await _almacen.leer(AlmacenSeguroImpl.claveToken);
    final id = await _almacen.leer(AlmacenSeguroImpl.claveIdPaciente);
    if (token == null || id == null) return null;

    _api?.token = token;

    try {
      return (await _fuente.obtenerPorId(id)).aDominio();
    } on FalloNoEncontrado {
      // El perfil ya no existe: la sesion guardada es basura, se limpia
      // en lugar de dejar al usuario en un estado a medias.
      await _cerrarSesionLocal();
      return null;
    } on FalloAutenticacion {
      // Token caducado o revocado por el backend.
      await _cerrarSesionLocal();
      return null;
    }
  });

  @override
  Future<Resultado<Paciente>> obtenerPorId(String id) =>
      _ejecutar(() async => (await _fuente.obtenerPorId(id)).aDominio());

  @override
  Future<Resultado<Paciente>> otorgarConsentimiento(String pacienteId) =>
      _ejecutar(
        () async =>
            (await _fuente.otorgarConsentimiento(pacienteId)).aDominio(),
      );

  @override
  Future<Resultado<Paciente>> revocarConsentimiento(String pacienteId) =>
      _ejecutar(
        () async =>
            (await _fuente.revocarConsentimiento(pacienteId)).aDominio(),
      );

  @override
  Future<Resultado<void>> solicitarEliminacionDeDatos(String pacienteId) =>
      _ejecutar(() async {
        await _fuente.solicitarEliminacionDeDatos(pacienteId);
        // HU-12: eliminada la cuenta, no queda rastro de sesion en el
        // dispositivo.
        await _cerrarSesionLocal();
      });

  // -------------------------------------------------------------------

  Future<void> _abrirSesion(SesionDto sesion) async {
    await _almacen.escribir(AlmacenSeguroImpl.claveToken, sesion.token);
    await _almacen.escribir(
      AlmacenSeguroImpl.claveIdPaciente,
      sesion.paciente.id,
    );
    _api?.token = sesion.token;
  }

  Future<void> _cerrarSesionLocal() async {
    await _almacen.eliminar(AlmacenSeguroImpl.claveToken);
    await _almacen.eliminar(AlmacenSeguroImpl.claveIdPaciente);
    _api?.token = null;
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
