import 'package:citas_medicas_app/data/datasources/local/base_datos.dart';
import 'package:citas_medicas_app/data/datasources/local/cita_local_datasource.dart';
import 'package:citas_medicas_app/data/models/cita_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

CitaDto _dto({
  required String id,
  String pacienteId = 'pac-1',
  String estado = 'confirmada',
  required DateTime inicio,
}) =>
    CitaDto(
      id: id,
      pacienteId: pacienteId,
      cupoId: 'cupo-$id',
      estado: estado,
      fechaCreacion: DateTime(2026, 9, 1).toIso8601String(),
      canalReserva: 'flujo_guiado',
      especialidadId: 'esp-demo-01',
      profesionalId: 'prof-demo-01',
      sedeId: 'sede-demo-01',
      consultorioId: 'cons-demo-01',
      fechaHoraInicio: inicio.toIso8601String(),
    );

void main() {
  // sqflite necesita el backend FFI para correr fuera de un dispositivo.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late BaseDatos baseDatos;
  late CitaLocalDataSource local;

  setUp(() async {
    // Base en memoria: cada test empieza limpio.
    baseDatos = BaseDatos(nombreArchivo: inMemoryDatabasePath);
    local = CitaLocalDataSource(baseDatos);
  });

  tearDown(() async => baseDatos.cerrar());

  group('HU-09 — historial persistido', () {
    test('lo guardado se recupera despues', () async {
      final citas = <CitaDto>[
        _dto(id: '1', inicio: DateTime(2026, 9, 20, 9)),
        _dto(id: '2', inicio: DateTime(2026, 9, 25, 15)),
      ];

      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: citas,
        momento: DateTime(2026, 9, 16, 10),
      );

      final recuperadas = await local.obtenerHistorial('pac-1');
      expect(recuperadas, hasLength(2));
      expect(recuperadas.map((c) => c.id).toSet(), <String>{'1', '2'});
    });

    test('se conserva la fecha de la ultima sincronizacion', () async {
      final momento = DateTime(2026, 9, 16, 10, 30);
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[_dto(id: '1', inicio: DateTime(2026, 9, 20, 9))],
        momento: momento,
      );

      expect(await local.obtenerUltimaSincronizacion('pac-1'), momento);
    });

    test('sin sincronizar devuelve null, no una fecha inventada', () async {
      expect(await local.obtenerUltimaSincronizacion('pac-1'), isNull);
    });

    test('el historial viene ordenado de la mas reciente a la mas antigua',
        () async {
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[
          _dto(id: 'antigua', inicio: DateTime(2026, 9, 18, 9)),
          _dto(id: 'reciente', inicio: DateTime(2026, 9, 28, 9)),
          _dto(id: 'media', inicio: DateTime(2026, 9, 22, 9)),
        ],
        momento: DateTime(2026, 9, 16),
      );

      final citas = await local.obtenerHistorial('pac-1');
      expect(
        citas.map((c) => c.id).toList(),
        <String>['reciente', 'media', 'antigua'],
      );
    });

    test('guardar el historial reemplaza el anterior, no lo acumula',
        () async {
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[_dto(id: '1', inicio: DateTime(2026, 9, 20, 9))],
        momento: DateTime(2026, 9, 16),
      );
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[_dto(id: '2', inicio: DateTime(2026, 9, 21, 9))],
        momento: DateTime(2026, 9, 17),
      );

      final citas = await local.obtenerHistorial('pac-1');
      expect(citas, hasLength(1));
      expect(citas.single.id, '2');
    });

    test('el historial de un paciente no toca el de otro', () async {
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[_dto(id: 'a', inicio: DateTime(2026, 9, 20, 9))],
        momento: DateTime(2026, 9, 16),
      );
      await local.guardarHistorial(
        pacienteId: 'pac-2',
        citas: <CitaDto>[
          _dto(id: 'b', pacienteId: 'pac-2', inicio: DateTime(2026, 9, 21, 9)),
        ],
        momento: DateTime(2026, 9, 16),
      );

      expect(await local.obtenerHistorial('pac-1'), hasLength(1));
      expect((await local.obtenerHistorial('pac-1')).single.id, 'a');
      expect((await local.obtenerHistorial('pac-2')).single.id, 'b');
    });

    test('guardarCita anade sin borrar el resto', () async {
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[_dto(id: '1', inicio: DateTime(2026, 9, 20, 9))],
        momento: DateTime(2026, 9, 16),
      );

      await local.guardarCita(_dto(id: '2', inicio: DateTime(2026, 9, 21, 9)));

      expect(await local.obtenerHistorial('pac-1'), hasLength(2));
    });

    test('guardarCita actualiza una cita existente en lugar de duplicarla',
        () async {
      final original = _dto(id: '1', inicio: DateTime(2026, 9, 20, 9));
      await local.guardarCita(original);

      final cancelada = _dto(
        id: '1',
        estado: 'cancelada',
        inicio: DateTime(2026, 9, 20, 9),
      );
      await local.guardarCita(cancelada);

      final citas = await local.obtenerHistorial('pac-1');
      expect(citas, hasLength(1));
      expect(citas.single.estado, 'cancelada');
    });

    test('todos los campos del comprobante sobreviven al viaje de ida y vuelta',
        () async {
      final original = _dto(id: '1', inicio: DateTime(2026, 9, 20, 9, 30));
      await local.guardarCita(original);

      final recuperada = (await local.obtenerHistorial('pac-1')).single;
      expect(recuperada.especialidadId, original.especialidadId);
      expect(recuperada.profesionalId, original.profesionalId);
      expect(recuperada.sedeId, original.sedeId);
      expect(recuperada.consultorioId, original.consultorioId);
      expect(recuperada.fechaHoraInicio, original.fechaHoraInicio);
      expect(recuperada.canalReserva, original.canalReserva);

      // Y el mapeo a dominio reconstruye la entidad completa.
      final dominio = recuperada.aDominio();
      expect(dominio.fechaHoraInicio, DateTime(2026, 9, 20, 9, 30));
    });
  });

  group('HU-12 — borrado local', () {
    test('borrarTodo no deja rastro del historial ni de la sincronizacion',
        () async {
      await local.guardarHistorial(
        pacienteId: 'pac-1',
        citas: <CitaDto>[_dto(id: '1', inicio: DateTime(2026, 9, 20, 9))],
        momento: DateTime(2026, 9, 16),
      );

      await local.borrarTodo();

      expect(await local.obtenerHistorial('pac-1'), isEmpty);
      expect(await local.obtenerUltimaSincronizacion('pac-1'), isNull);
    });
  });
}
