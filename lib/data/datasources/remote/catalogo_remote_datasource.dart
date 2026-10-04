import '../../../core/network/api_client.dart';
import '../../models/especialidad_dto.dart';
import '../../models/profesional_dto.dart';
import '../../models/sede_dto.dart';

/// Contrato de la fuente de datos de catalogos.
///
/// Tiene dos implementaciones intercambiables: [ApiCatalogoDataSource] contra
/// el backend real y `FakeCatalogoDataSource` con fixtures locales. El
/// repositorio elige una u otra segun `FeatureFlags.usarBackendReal`.
abstract interface class CatalogoDataSource {
  Future<List<EspecialidadDto>> obtenerEspecialidades();
  Future<List<ProfesionalDto>> obtenerProfesionales({String? especialidadId});
  Future<List<SedeDto>> obtenerSedes();
  Future<List<ConsultorioDto>> obtenerConsultorios({String? sedeId});

  // ---------------- Gestion del catalogo (solo administracion) ----------------
  // Alta, edicion y baja de especialidades y profesionales. El backend
  // protege estas rutas con el rol de administracion; el cliente ademas las
  // guarda con RN-01 antes de llamarlas.

  Future<EspecialidadDto> crearEspecialidad(EspecialidadDto especialidad);
  Future<EspecialidadDto> actualizarEspecialidad(EspecialidadDto especialidad);
  Future<void> eliminarEspecialidad(String id);

  Future<ProfesionalDto> crearProfesional(ProfesionalDto profesional);
  Future<ProfesionalDto> actualizarProfesional(ProfesionalDto profesional);
  Future<void> eliminarProfesional(String id);
}

/// Implementacion REST contra el backend Spring Boot.
class ApiCatalogoDataSource implements CatalogoDataSource {
  ApiCatalogoDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<EspecialidadDto>> obtenerEspecialidades() async {
    final respuesta = await _api.get('/especialidades');
    return _lista(respuesta).map(EspecialidadDto.fromJson).toList();
  }

  @override
  Future<List<ProfesionalDto>> obtenerProfesionales({
    String? especialidadId,
  }) async {
    final respuesta = await _api.get(
      '/profesionales',
      parametros: <String, String>{'especialidadId': ?especialidadId},
    );
    return _lista(respuesta).map(ProfesionalDto.fromJson).toList();
  }

  @override
  Future<List<SedeDto>> obtenerSedes() async {
    final respuesta = await _api.get('/sedes');
    return _lista(respuesta).map(SedeDto.fromJson).toList();
  }

  @override
  Future<List<ConsultorioDto>> obtenerConsultorios({String? sedeId}) async {
    final respuesta = await _api.get(
      '/consultorios',
      parametros: <String, String>{'sedeId': ?sedeId},
    );
    return _lista(respuesta).map(ConsultorioDto.fromJson).toList();
  }

  @override
  Future<EspecialidadDto> crearEspecialidad(EspecialidadDto especialidad) async {
    final respuesta = await _api.post(
      '/especialidades',
      cuerpo: especialidad.toJson(),
    );
    return EspecialidadDto.fromJson(_objeto(respuesta));
  }

  @override
  Future<EspecialidadDto> actualizarEspecialidad(
    EspecialidadDto especialidad,
  ) async {
    final respuesta = await _api.patch(
      '/especialidades/${especialidad.id}',
      cuerpo: especialidad.toJson(),
    );
    return EspecialidadDto.fromJson(_objeto(respuesta));
  }

  @override
  Future<void> eliminarEspecialidad(String id) =>
      _api.delete('/especialidades/$id');

  @override
  Future<ProfesionalDto> crearProfesional(ProfesionalDto profesional) async {
    final respuesta = await _api.post(
      '/profesionales',
      cuerpo: profesional.toJson(),
    );
    return ProfesionalDto.fromJson(_objeto(respuesta));
  }

  @override
  Future<ProfesionalDto> actualizarProfesional(
    ProfesionalDto profesional,
  ) async {
    final respuesta = await _api.patch(
      '/profesionales/${profesional.id}',
      cuerpo: profesional.toJson(),
    );
    return ProfesionalDto.fromJson(_objeto(respuesta));
  }

  @override
  Future<void> eliminarProfesional(String id) =>
      _api.delete('/profesionales/$id');

  /// El backend puede devolver la coleccion en la raiz o bajo `datos`.
  List<Map<String, dynamic>> _lista(Map<String, dynamic> respuesta) {
    final datos = respuesta['datos'] ?? respuesta['contenido'];
    if (datos is List) {
      return datos.cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }

  /// El backend puede devolver el objeto creado/actualizado en la raiz o bajo
  /// `datos`.
  Map<String, dynamic> _objeto(Map<String, dynamic> respuesta) {
    final datos = respuesta['datos'];
    if (datos is Map<String, dynamic>) return datos;
    return respuesta;
  }
}
