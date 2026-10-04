import 'package:sqflite/sqflite.dart';

import '../../models/cita_dto.dart';
import 'base_datos.dart';

/// Cache local del historial de citas (HU-09).
///
/// La aplicacion escribe aqui cada vez que sincroniza con el backend, y lee
/// de aqui cuando no hay conexion. La fecha de la ultima sincronizacion se
/// guarda junto a los datos para poder informarla al paciente: un historial
/// sin conexion que no dice de cuando es resulta enganoso.
class CitaLocalDataSource {
  const CitaLocalDataSource(this._baseDatos);

  final BaseDatos _baseDatos;

  /// Reemplaza el historial del paciente por [citas] y marca la
  /// sincronizacion.
  ///
  /// Se hace en una transaccion: si algo falla a mitad, el paciente conserva
  /// el historial anterior en lugar de quedarse con uno incompleto.
  Future<void> guardarHistorial({
    required String pacienteId,
    required List<CitaDto> citas,
    required DateTime momento,
  }) async {
    final db = await _baseDatos.instancia;

    await db.transaction((txn) async {
      await txn.delete(
        BaseDatos.tablaCitas,
        where: 'pacienteId = ?',
        whereArgs: <Object>[pacienteId],
      );

      for (final cita in citas) {
        await txn.insert(
          BaseDatos.tablaCitas,
          _aFila(cita),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert(BaseDatos.tablaSincronizacion, <String, Object?>{
        'pacienteId': pacienteId,
        'momento': momento.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Inserta o actualiza una sola cita, sin tocar el resto del historial.
  Future<void> guardarCita(CitaDto cita) async {
    final db = await _baseDatos.instancia;
    await db.insert(
      BaseDatos.tablaCitas,
      _aFila(cita),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CitaDto>> obtenerHistorial(String pacienteId) async {
    final db = await _baseDatos.instancia;
    final filas = await db.query(
      BaseDatos.tablaCitas,
      where: 'pacienteId = ?',
      whereArgs: <Object>[pacienteId],
      orderBy: 'fechaHoraInicio DESC',
    );
    return filas.map(_deFila).toList();
  }

  /// Todas las citas guardadas, sin filtrar por paciente.
  ///
  /// La aplicacion no la usa: existe para que el «servidor» simulado del modo
  /// demostracion pueda reconstruir su estado completo al arrancar.
  Future<List<CitaDto>> obtenerTodas() async {
    final db = await _baseDatos.instancia;
    final filas = await db.query(BaseDatos.tablaCitas);
    return filas.map(_deFila).toList();
  }

  /// `null` si nunca se sincronizo para este paciente.
  Future<DateTime?> obtenerUltimaSincronizacion(String pacienteId) async {
    final db = await _baseDatos.instancia;
    final filas = await db.query(
      BaseDatos.tablaSincronizacion,
      where: 'pacienteId = ?',
      whereArgs: <Object>[pacienteId],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return DateTime.tryParse(filas.first['momento'] as String);
  }

  /// HU-12.
  Future<void> borrarTodo() => _baseDatos.borrarTodo();

  // -------------------------------------------------------------------

  static Map<String, Object?> _aFila(CitaDto c) => <String, Object?>{
    'id': c.id,
    'pacienteId': c.pacienteId,
    'cupoId': c.cupoId,
    'estado': c.estado,
    'fechaCreacion': c.fechaCreacion,
    'canalReserva': c.canalReserva,
    'fechaAtencion': c.fechaAtencion,
    'claveIdempotencia': c.claveIdempotencia,
    'especialidadId': c.especialidadId,
    'profesionalId': c.profesionalId,
    'sedeId': c.sedeId,
    'consultorioId': c.consultorioId,
    'fechaHoraInicio': c.fechaHoraInicio,
  };

  static CitaDto _deFila(Map<String, Object?> f) => CitaDto(
    id: f['id']! as String,
    pacienteId: f['pacienteId']! as String,
    cupoId: f['cupoId']! as String,
    estado: f['estado']! as String,
    fechaCreacion: f['fechaCreacion']! as String,
    canalReserva: f['canalReserva']! as String,
    fechaAtencion: f['fechaAtencion'] as String?,
    claveIdempotencia: f['claveIdempotencia'] as String?,
    especialidadId: f['especialidadId'] as String?,
    profesionalId: f['profesionalId'] as String?,
    sedeId: f['sedeId'] as String?,
    consultorioId: f['consultorioId'] as String?,
    fechaHoraInicio: f['fechaHoraInicio'] as String?,
  );
}
