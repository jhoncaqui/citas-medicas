import '../../core/error/resultado.dart';
import '../entities/consultorio.dart';
import '../entities/especialidad.dart';
import '../entities/profesional.dart';
import '../entities/sede.dart';

/// Catalogos de la clinica: especialidades, profesionales, sedes y
/// consultorios.
///
/// Contrato puro: no conoce HTTP, sqflite ni Firebase.
abstract interface class CatalogoRepository {
  /// GET /api/v1/especialidades
  Future<Resultado<List<Especialidad>>> obtenerEspecialidades();

  /// GET /api/v1/profesionales?especialidadId=
  Future<Resultado<List<Profesional>>> obtenerProfesionales({
    String? especialidadId,
  });

  /// GET /api/v1/sedes
  Future<Resultado<List<Sede>>> obtenerSedes();

  Future<Resultado<List<Consultorio>>> obtenerConsultorios({String? sedeId});

  // ---------------- Gestion del catalogo (solo administracion) ----------------

  /// POST /api/v1/especialidades
  Future<Resultado<Especialidad>> crearEspecialidad(Especialidad especialidad);

  /// PATCH /api/v1/especialidades/{id}
  Future<Resultado<Especialidad>> actualizarEspecialidad(
    Especialidad especialidad,
  );

  /// DELETE /api/v1/especialidades/{id}
  Future<Resultado<void>> eliminarEspecialidad(String id);

  /// POST /api/v1/profesionales
  Future<Resultado<Profesional>> crearProfesional(Profesional profesional);

  /// PATCH /api/v1/profesionales/{id}
  Future<Resultado<Profesional>> actualizarProfesional(Profesional profesional);

  /// DELETE /api/v1/profesionales/{id}
  Future<Resultado<void>> eliminarProfesional(String id);
}
