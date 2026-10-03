import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/network/connectivity_service.dart';
import 'package:citas_medicas_app/data/datasources/local/base_datos.dart';
import 'package:citas_medicas_app/data/datasources/local/cita_local_datasource.dart';
import 'package:citas_medicas_app/data/datasources/remote/cita_remote_datasource.dart';
import 'package:citas_medicas_app/data/models/cita_dto.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Fuente remota controlada por el test.
class _RemotoStub implements CitaDataSource {
  // Los tests ajustan `citas` y `falla` por propiedad, no por constructor.
  List<CitaDto> citas = const <CitaDto>[];
  bool falla = false;
  int llamadas = 0;

  @override
  Future<List<CitaDto>> obtenerCitas({
    required String pacienteId,
    String? estado,
  }) async {
    llamadas++;
    if (falla) throw const FalloConexion();
    return citas.where((c) => c.pacienteId == pacienteId).toList();
  }

  @override
  Future<List<CitaDto>> obtenerTodasLasCitas() async => citas;

  @override
  Future<List<CupoDto>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
  }) async =>
      const <CupoDto>[];

  @override
  Future<CitaDto> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required String canal,
    required String claveIdempotencia,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CitaDto> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CitaDto> cancelar(String citaId) async => throw UnimplementedError();
}

/// Conectividad simulada.
class _SinRed implements ConnectivityService {
  _SinRed(this.conectado);

  bool conectado;

  @override
  Future<bool> get hayConexion async => conectado;

  @override
  Stream<bool> get cambios => Stream<bool>.value(conectado);
}

CitaDto _dto({
  required String id,
  String estado = 'confirmada',
  required DateTime inicio,
}) =>
    CitaDto(
      id: id,
      pacienteId: 'pac-1',
      cupoId: 'cupo-$id',
      estado: estado,
      fechaCreacion: DateTime(2026, 9, 1).toIso8601String(),
      canalReserva: 'flujo_guiado',
      especialidadId: 'esp-demo-01',
      profesionalId: 'prof-demo-01',
      fechaHoraInicio: inicio.toIso8601String(),
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final ahora = DateTime(2026, 9, 16, 10, 0);
  DateTime reloj() => ahora;

  late BaseDatos baseDatos;
  late CitaLocalDataSource local;
  late _RemotoStub remoto;

  setUp(() {
    baseDatos = BaseDatos(nombreArchivo: inMemoryDatabasePath);
    local = CitaLocalDataSource(baseDatos);
    remoto = _RemotoStub();
  });

  tearDown(() async => baseDatos.cerrar());

  CitaRepositoryImpl crear({required bool conectado}) => CitaRepositoryImpl(
        remoto,
        local: local,
        conectividad: _SinRed(conectado),
        reloj: reloj,
      );

  group('HU-09 — historial sin conexion', () {
    test('con conexion, el historial se guarda en la base local', () async {
      remoto.citas = <CitaDto>[
        _dto(id: '1', inicio: ahora.add(const Duration(days: 4))),
      ];

      final repo = crear(conectado: true);
      final resultado = await repo.obtenerCitas(pacienteId: 'pac-1');

      expect(resultado.esExito, isTrue);
      expect(await local.obtenerHistorial('pac-1'), hasLength(1));
      expect(await local.obtenerUltimaSincronizacion('pac-1'), ahora);
    });

    test('sin conexion se sirve el historial guardado, sin llamar a la red',
        () async {
      // Primero se sincroniza con red.
      remoto.citas = <CitaDto>[
        _dto(id: '1', inicio: ahora.add(const Duration(days: 4))),
      ];
      await crear(conectado: true).obtenerCitas(pacienteId: 'pac-1');
      final llamadasConRed = remoto.llamadas;

      // Ahora se pierde la conexion.
      final resultado =
          await crear(conectado: false).obtenerCitas(pacienteId: 'pac-1');

      expect(resultado.esExito, isTrue);
      expect(resultado.valorONull, hasLength(1));
      expect(
        remoto.llamadas,
        llamadasConRed,
        reason: 'Sin conexion no se debe intentar la peticion',
      );
    });

    test('sin conexion y sin historial guardado, la lista viene vacia',
        () async {
      final resultado =
          await crear(conectado: false).obtenerCitas(pacienteId: 'pac-1');

      expect(resultado.esExito, isTrue);
      expect(resultado.valorONull, isEmpty);
    });

    test('con conexion pero con fallo del servidor, se cae al historial local',
        () async {
      remoto.citas = <CitaDto>[
        _dto(id: '1', inicio: ahora.add(const Duration(days: 4))),
      ];
      await crear(conectado: true).obtenerCitas(pacienteId: 'pac-1');

      remoto.falla = true;
      final resultado = await crear(conectado: true)
          .obtenerCitas(pacienteId: 'pac-1');

      expect(
        resultado.valorONull,
        hasLength(1),
        reason: 'La cache es mejor que una pantalla vacia',
      );
    });

    test('la fecha de sincronizacion no cambia si no hubo sincronizacion',
        () async {
      remoto.citas = <CitaDto>[
        _dto(id: '1', inicio: ahora.add(const Duration(days: 4))),
      ];
      await crear(conectado: true).obtenerCitas(pacienteId: 'pac-1');

      await crear(conectado: false).obtenerCitas(pacienteId: 'pac-1');

      final fecha = await crear(conectado: false)
          .obtenerFechaUltimaSincronizacion('pac-1');
      expect(fecha.valorONull, ahora);
    });
  });

  group('RN-08 aplicada al historial', () {
    test('una cita confirmada ya pasada se muestra como inasistencia',
        () async {
      remoto.citas = <CitaDto>[
        _dto(id: '1', inicio: ahora.subtract(const Duration(days: 2))),
      ];

      final resultado =
          await crear(conectado: true).obtenerCitas(pacienteId: 'pac-1');

      expect(
        resultado.valorONull!.single.estado,
        EstadoCita.inasistencia,
        reason: 'RN-08 se aplica sin esperar a la siguiente sincronizacion',
      );
    });

    test('una cita futura conserva su estado', () async {
      remoto.citas = <CitaDto>[
        _dto(id: '1', inicio: ahora.add(const Duration(days: 2))),
      ];

      final resultado =
          await crear(conectado: true).obtenerCitas(pacienteId: 'pac-1');
      expect(resultado.valorONull!.single.estado, EstadoCita.confirmada);
    });
  });
}
