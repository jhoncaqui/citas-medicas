import 'package:citas_medicas_app/data/datasources/fake/fake_cita_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fixtures.dart';
import 'package:citas_medicas_app/data/datasources/local/base_datos.dart';
import 'package:citas_medicas_app/data/datasources/local/cita_local_datasource.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// HU-11 — el panel de administracion necesita las citas de TODOS los
/// pacientes, no solo las de quien tiene la sesion abierta.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final ahora = DateTime(2026, 9, 21, 7, 0);
  DateTime reloj() => ahora;

  late BaseDatos bdLocal;
  late CitaLocalDataSource local;
  late CitaRepositoryImpl repo;

  setUp(() {
    // La cache del DISPOSITIVO (la que rellena el repositorio) es una base
    // aparte de la del «servidor» simulado, que aqui va solo en memoria.
    bdLocal = BaseDatos(nombreArchivo: inMemoryDatabasePath);
    local = CitaLocalDataSource(bdLocal);
    repo = CitaRepositoryImpl(
      FakeCitaDataSource(latencia: Duration.zero, reloj: reloj),
      local: local,
      reloj: reloj,
    );
  });

  tearDown(() async => bdLocal.cerrar());

  List<String> cuposLibres(int cuantos) {
    final profesionales = Fixtures.profesionales
        .where((p) => p.especialidadId == 'esp-demo-01')
        .map((p) => p.id)
        .toSet();
    return Fixtures.generarCupos(desde: ahora)
        .where((c) => profesionales.contains(c.profesionalId))
        .take(cuantos)
        .map((c) => c.id)
        .toList();
  }

  Future<void> reservar(String pacienteId, String cupoId, String clave) =>
      repo.confirmarReserva(
        pacienteId: pacienteId,
        cupoId: cupoId,
        canal: CanalReserva.conversacional,
        claveIdempotencia: clave,
      );

  test('devuelve las citas de todos los pacientes', () async {
    final cupos = cuposLibres(3);
    await reservar('pac-1', cupos[0], 'k1');
    await reservar('pac-2', cupos[1], 'k2');
    await reservar('pac-3', cupos[2], 'k3');

    final todas = await repo.obtenerTodasLasCitas();

    expect(todas.esExito, isTrue);
    expect(
      todas.valorONull!.map((c) => c.pacienteId).toSet(),
      <String>{'pac-1', 'pac-2', 'pac-3'},
    );
  });

  test('un paciente sigue viendo SOLO las suyas', () async {
    final cupos = cuposLibres(2);
    await reservar('pac-1', cupos[0], 'k1');
    await reservar('pac-2', cupos[1], 'k2');

    final suyas = await repo.obtenerCitas(pacienteId: 'pac-1');

    expect(suyas.valorONull, hasLength(1));
    expect(suyas.valorONull!.single.pacienteId, 'pac-1');
  });

  test('consultar todas NO guarda citas ajenas en el dispositivo', () async {
    final cupos = cuposLibres(2);
    // Se limpia lo que confirmarReserva guarda de la cita recien creada, para
    // aislar lo que hace exclusivamente la consulta de toda la clinica.
    await reservar('pac-1', cupos[0], 'k1');
    await reservar('pac-2', cupos[1], 'k2');
    await bdLocal.borrarTodo();

    await repo.obtenerTodasLasCitas();

    expect(await local.obtenerHistorial('pac-1'), isEmpty);
    expect(await local.obtenerHistorial('pac-2'), isEmpty);
    expect(
      await local.obtenerTodas(),
      isEmpty,
      reason: 'No debe quedar en el telefono de quien administra un volcado '
          'de las citas de los demas',
    );
  });

  test('sin ninguna cita devuelve una lista vacia, no un fallo', () async {
    final todas = await repo.obtenerTodasLasCitas();
    expect(todas.esExito, isTrue);
    expect(todas.valorONull, isEmpty);
  });
}
