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

  /// El backend puede devolver la coleccion en la raiz o bajo `datos`.
  List<Map<String, dynamic>> _lista(Map<String, dynamic> respuesta) {
    final datos = respuesta['datos'] ?? respuesta['contenido'];
    if (datos is List) {
      return datos.cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }
}
