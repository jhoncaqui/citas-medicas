import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../domain/entities/consultorio.dart';
import '../../domain/entities/especialidad.dart';
import '../../domain/entities/profesional.dart';
import '../../domain/entities/sede.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../datasources/remote/catalogo_remote_datasource.dart';
import '../models/especialidad_dto.dart';
import '../models/profesional_dto.dart';

/// Implementa el contrato de dominio sobre una [CatalogoDataSource], que
/// puede ser la real o la falsa. El repositorio no sabe cual le inyectaron.
class CatalogoRepositoryImpl implements CatalogoRepository {
  const CatalogoRepositoryImpl(this._fuente);

  final CatalogoDataSource _fuente;

  @override
  Future<Resultado<List<Especialidad>>> obtenerEspecialidades() =>
      _ejecutar(() async {
        final dtos = await _fuente.obtenerEspecialidades();
        return dtos.map((d) => d.aDominio()).toList();
      });

  @override
  Future<Resultado<List<Profesional>>> obtenerProfesionales({
    String? especialidadId,
  }) => _ejecutar(() async {
    final dtos = await _fuente.obtenerProfesionales(
      especialidadId: especialidadId,
    );
    return dtos.map((d) => d.aDominio()).toList();
  });

  @override
  Future<Resultado<List<Sede>>> obtenerSedes() => _ejecutar(() async {
    final dtos = await _fuente.obtenerSedes();
    return dtos.map((d) => d.aDominio()).toList();
  });

  @override
  Future<Resultado<List<Consultorio>>> obtenerConsultorios({String? sedeId}) =>
      _ejecutar(() async {
        final dtos = await _fuente.obtenerConsultorios(sedeId: sedeId);
        return dtos.map((d) => d.aDominio()).toList();
      });

  // ---------------- Gestion del catalogo ----------------

  @override
  Future<Resultado<Especialidad>> crearEspecialidad(
    Especialidad especialidad,
  ) => _ejecutar(() async {
    final dto = await _fuente.crearEspecialidad(
      EspecialidadDto.desdeDominio(especialidad),
    );
    return dto.aDominio();
  });

  @override
  Future<Resultado<Especialidad>> actualizarEspecialidad(
    Especialidad especialidad,
  ) => _ejecutar(() async {
    final dto = await _fuente.actualizarEspecialidad(
      EspecialidadDto.desdeDominio(especialidad),
    );
    return dto.aDominio();
  });

  @override
  Future<Resultado<void>> eliminarEspecialidad(String id) =>
      _ejecutar(() => _fuente.eliminarEspecialidad(id));

  @override
  Future<Resultado<Profesional>> crearProfesional(Profesional profesional) =>
      _ejecutar(() async {
        final dto = await _fuente.crearProfesional(
          ProfesionalDto.desdeDominio(profesional),
        );
        return dto.aDominio();
      });

  @override
  Future<Resultado<Profesional>> actualizarProfesional(
    Profesional profesional,
  ) => _ejecutar(() async {
    final dto = await _fuente.actualizarProfesional(
      ProfesionalDto.desdeDominio(profesional),
    );
    return dto.aDominio();
  });

  @override
  Future<Resultado<void>> eliminarProfesional(String id) =>
      _ejecutar(() => _fuente.eliminarProfesional(id));

  /// Convierte cualquier excepcion en un [Resultado], de modo que la capa de
  /// presentacion nunca tenga que capturar excepciones.
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
