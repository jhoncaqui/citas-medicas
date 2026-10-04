import '../../../core/config/app_config.dart';
import '../../../core/error/excepciones.dart';
import '../../../domain/entities/especialidad.dart';
import '../../../domain/entities/profesional.dart';
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
///
/// El CRUD del catalogo (altas, ediciones y bajas que hace el personal de
/// administracion) muta las listas de `Fixtures`, de modo que el cambio es
/// visible de inmediato en el resto del modo demostracion: al dar de alta un
/// profesional, el generador de cupos empieza a ofrecer sus horarios.
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

  // ---------------- Gestion del catalogo ----------------

  @override
  Future<EspecialidadDto> crearEspecialidad(
    EspecialidadDto especialidad,
  ) async {
    await Future<void>.delayed(latencia);
    final creada = Especialidad(
      id: Fixtures.nuevoIdEspecialidad(),
      nombre: especialidad.nombre,
      descripcion: especialidad.descripcion,
      activa: especialidad.activa,
    );
    Fixtures.especialidades.add(creada);
    return EspecialidadDto.desdeDominio(creada);
  }

  @override
  Future<EspecialidadDto> actualizarEspecialidad(
    EspecialidadDto especialidad,
  ) async {
    await Future<void>.delayed(latencia);
    final indice = Fixtures.especialidades.indexWhere(
      (e) => e.id == especialidad.id,
    );
    if (indice < 0) {
      throw const FalloNoEncontrado('La especialidad ya no existe.');
    }
    Fixtures.especialidades[indice] = especialidad.aDominio();
    return especialidad;
  }

  @override
  Future<void> eliminarEspecialidad(String id) async {
    await Future<void>.delayed(latencia);
    // No se puede eliminar una especialidad que tiene profesionales asignados:
    // dejaria cupos y citas apuntando a un registro inexistente.
    final enUso = Fixtures.profesionales.any((p) => p.especialidadId == id);
    if (enUso) {
      throw const FalloReglaNegocio(
        'No puedes eliminar una especialidad con profesionales asignados. '
        'Reasigna o elimina primero a esos profesionales.',
        regla: 'RN-CAT',
      );
    }
    Fixtures.especialidades.removeWhere((e) => e.id == id);
  }

  @override
  Future<ProfesionalDto> crearProfesional(ProfesionalDto profesional) async {
    await Future<void>.delayed(latencia);
    final creado = Profesional(
      id: Fixtures.nuevoIdProfesional(),
      nombres: profesional.nombres,
      apellidos: profesional.apellidos,
      especialidadId: profesional.especialidadId,
      colegiatura: profesional.colegiatura,
    );
    Fixtures.profesionales.add(creado);
    return ProfesionalDto.desdeDominio(creado);
  }

  @override
  Future<ProfesionalDto> actualizarProfesional(
    ProfesionalDto profesional,
  ) async {
    await Future<void>.delayed(latencia);
    final indice = Fixtures.profesionales.indexWhere(
      (p) => p.id == profesional.id,
    );
    if (indice < 0) {
      throw const FalloNoEncontrado('El profesional ya no existe.');
    }
    Fixtures.profesionales[indice] = profesional.aDominio();
    return profesional;
  }

  @override
  Future<void> eliminarProfesional(String id) async {
    await Future<void>.delayed(latencia);
    Fixtures.profesionales.removeWhere((p) => p.id == id);
  }
}
