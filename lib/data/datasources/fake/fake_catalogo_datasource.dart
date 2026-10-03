import '../../../core/config/app_config.dart';
import '../../models/especialidad_dto.dart';
import '../../models/profesional_dto.dart';
import '../../models/sede_dto.dart';
import '../remote/catalogo_remote_datasource.dart';
import 'fixtures.dart';

/// Fuente de catalogos sobre fixtures locales.
///
/// Reproduce la latencia del backend para que la interfaz se pruebe con
/// indicadores de carga reales y no con respuestas instantaneas.
///
/// Los datos que devuelve son FICTICIOS. Ver `fixtures.dart`.
class FakeCatalogoDataSource implements CatalogoDataSource {
  const FakeCatalogoDataSource({this.latencia = AppConfig.latenciaSimulada});

  final Duration latencia;

  @override
  Future<List<EspecialidadDto>> obtenerEspecialidades() async {
    await Future<void>.delayed(latencia);
    return Fixtures.especialidades.map(EspecialidadDto.desdeDominio).toList();
  }

  @override
  Future<List<ProfesionalDto>> obtenerProfesionales({
    String? especialidadId,
  }) async {
    await Future<void>.delayed(latencia);
    return Fixtures.profesionales
        .where(
          (p) => especialidadId == null || p.especialidadId == especialidadId,
        )
        .map(ProfesionalDto.desdeDominio)
        .toList();
  }

  @override
  Future<List<SedeDto>> obtenerSedes() async {
    await Future<void>.delayed(latencia);
    return Fixtures.sedes.map(SedeDto.desdeDominio).toList();
  }

  @override
  Future<List<ConsultorioDto>> obtenerConsultorios({String? sedeId}) async {
    await Future<void>.delayed(latencia);
    return Fixtures.consultorios
        .where((c) => sedeId == null || c.sedeId == sedeId)
        .map(ConsultorioDto.desdeDominio)
        .toList();
  }
}
