import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local de la aplicacion.
///
/// Guarda el historial de citas para que HU-09 funcione sin conexion, y la
/// marca de la ultima sincronizacion para poder informarla.
///
/// **Lo que NO se guarda aqui**: credenciales, token de sesion ni datos
/// sensibles del paciente. Solo sus citas, que es lo que el historial
/// necesita mostrar (RNF-08).
class BaseDatos {
  BaseDatos({String? nombreArchivo})
    : _nombreArchivo = nombreArchivo ?? 'citas_medicas.db';

  final String _nombreArchivo;
  Database? _db;

  static const int versionEsquema = 1;

  static const String tablaCitas = 'citas';
  static const String tablaSincronizacion = 'sincronizacion';

  Future<Database> get instancia async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = await _resolverRuta();
    return openDatabase(
      ruta,
      version: versionEsquema,
      onCreate: (db, version) async => _crearEsquema(db),
      onUpgrade: (db, anterior, nueva) async {
        // Version 1: no hay migraciones todavia. Cuando las haya, cada salto
        // se aplica aqui en orden, sin borrar datos del paciente.
      },
    );
  }

  static Future<void> _crearEsquema(Database db) async {
    await db.execute('''
      CREATE TABLE $tablaCitas (
        id TEXT PRIMARY KEY,
        pacienteId TEXT NOT NULL,
        cupoId TEXT NOT NULL,
        estado TEXT NOT NULL,
        fechaCreacion TEXT NOT NULL,
        canalReserva TEXT NOT NULL,
        fechaAtencion TEXT,
        claveIdempotencia TEXT,
        especialidadId TEXT,
        profesionalId TEXT,
        sedeId TEXT,
        consultorioId TEXT,
        fechaHoraInicio TEXT
      )
    ''');

    // El historial se consulta siempre por paciente y ordenado por fecha.
    await db.execute(
      'CREATE INDEX idx_citas_paciente ON $tablaCitas(pacienteId, fechaHoraInicio)',
    );

    await db.execute('''
      CREATE TABLE $tablaSincronizacion (
        pacienteId TEXT PRIMARY KEY,
        momento TEXT NOT NULL
      )
    ''');
  }

  /// Resuelve la ruta del archivo.
  ///
  /// `:memory:` y las rutas absolutas se usan tal cual: unirlas al directorio
  /// de bases de datos produciria una ruta invalida. Es lo que permite que
  /// los tests abran una base en memoria con la misma clase que la
  /// aplicacion usa en el dispositivo.
  Future<String> _resolverRuta() async {
    if (_nombreArchivo == inMemoryDatabasePath) return _nombreArchivo;
    if (p.isAbsolute(_nombreArchivo)) return _nombreArchivo;
    return p.join(await getDatabasesPath(), _nombreArchivo);
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }

  /// HU-12: al eliminar los datos del paciente no debe quedar rastro local.
  Future<void> borrarTodo() async {
    final db = await instancia;
    await db.delete(tablaCitas);
    await db.delete(tablaSincronizacion);
  }
}
