import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../domain/repositories/preferencias_repository.dart';
import '../datasources/local/preferencias_local_datasource.dart';

class PreferenciasRepositoryImpl implements PreferenciasRepository {
  const PreferenciasRepositoryImpl(this._local);

  final PreferenciasLocalDataSource _local;

  @override
  Future<Resultado<bool?>> obtenerPreferenciaTemaOscuro() => _ejecutar(
    () => _local.leerBoolONull(PreferenciasLocalDataSource.claveTemaOscuro),
  );

  @override
  Future<Resultado<void>> guardarPreferenciaTemaOscuro(bool? oscuro) =>
      _ejecutar(() async {
        const clave = PreferenciasLocalDataSource.claveTemaOscuro;
        // `null` equivale a «seguir al sistema»: se borra la clave en lugar de
        // guardar un tercer valor.
        if (oscuro == null) return _local.eliminar(clave);
        return _local.escribirBool(clave, oscuro);
      });

  @override
  Future<Resultado<bool>> obtenerIntroduccionVista() => _ejecutar(
    () => _local.leerBool(PreferenciasLocalDataSource.claveIntroduccionVista),
  );

  @override
  Future<Resultado<void>> guardarIntroduccionVista(bool vista) => _ejecutar(
    () => _local.escribirBool(
      PreferenciasLocalDataSource.claveIntroduccionVista,
      vista,
    ),
  );

  @override
  Future<Resultado<bool>> obtenerPermisoNotificacionesSolicitado() => _ejecutar(
    () =>
        _local.leerBool(PreferenciasLocalDataSource.clavePermisoNotificaciones),
  );

  @override
  Future<Resultado<void>> guardarPermisoNotificacionesSolicitado(bool valor) =>
      _ejecutar(
        () => _local.escribirBool(
          PreferenciasLocalDataSource.clavePermisoNotificaciones,
          valor,
        ),
      );

  @override
  Future<Resultado<void>> limpiarTodo() => _ejecutar(_local.limpiarTodo);

  Future<Resultado<T>> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return Resultado<T>.exito(await accion());
    } on FalloApp catch (fallo) {
      return Resultado<T>.fallo(fallo);
    } catch (_) {
      return Resultado<T>.fallo(const FalloAlmacenamientoLocal());
    }
  }
}
