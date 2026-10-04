import 'package:citas_medicas_app/data/datasources/fake/fake_cita_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fixtures.dart';
import 'package:citas_medicas_app/data/datasources/local/base_datos.dart';
import 'package:citas_medicas_app/data/datasources/local/cita_local_datasource.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reproduce el defecto encontrado al probar la aplicacion en el emulador: se
/// reservaba una cita, se cerraba la aplicacion y el historial aparecia vacio
/// aunque la cita estuviera guardada en sqflite.
///
/// La causa era que el «servidor» simulado guardaba las citas solo en memoria:
/// al reiniciar devolvia una lista vacia, y esa lista vacia sobrescribia la
/// cache local.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final ahora = DateTime(2026, 9, 21, 7, 0);
  DateTime reloj() => ahora;

  late BaseDatos baseDatos;
  late CitaLocalDataSource local;

  setUp(() {
    // Una sola base compartida entre «reinicios», como en el dispositivo.
    baseDatos = BaseDatos(nombreArchivo: inMemoryDatabasePath);
    local = CitaLocalDataSource(baseDatos);
  });

  tearDown(() async => baseDatos.cerrar());

  /// Simula abrir la aplicacion: instancias nuevas sobre la misma base.
  ({FakeCitaDataSource fuente, CitaRepositoryImpl repo}) arrancar() {
    final fuente = FakeCitaDataSource(
      persistencia: local,
      latencia: Duration.zero,
      reloj: reloj,
    );
    return (
      fuente: fuente,
      repo: CitaRepositoryImpl(fuente, local: local, reloj: reloj),
    );
  }

  String primerCupo() {
    final profesionales = Fixtures.profesionales
        .where((p) => p.especialidadId == 'esp-demo-01')
        .map((p) => p.id)
        .toSet();
    return Fixtures.generarCupos(desde: ahora)
        .firstWhere((c) => profesionales.contains(c.profesionalId))
        .id;
  }

  test('la cita reservada sigue en el historial tras reiniciar', () async {
    final primera = arrancar();
    final reserva = await primera.repo.confirmarReserva(
      pacienteId: 'pac-1',
      cupoId: primerCupo(),
      canal: CanalReserva.flujoGuiado,
      claveIdempotencia: 'k1',
    );
    expect(reserva.esExito, isTrue);

    // Se cierra la aplicacion y se vuelve a abrir.
    final segunda = arrancar();
    final historial = await segunda.repo.obtenerCitas(pacienteId: 'pac-1');

    expect(
      historial.valorONull,
      hasLength(1),
      reason: 'El historial no puede vaciarse al reiniciar la aplicacion',
    );
    expect(historial.valorONull!.single.id, reserva.valorONull!.id);
  });

  test('RN-03: el cupo reservado sigue ocupado tras reiniciar', () async {
    final cupoId = primerCupo();

    final primera = arrancar();
    await primera.repo.confirmarReserva(
      pacienteId: 'pac-1',
      cupoId: cupoId,
      canal: CanalReserva.flujoGuiado,
      claveIdempotencia: 'k1',
    );

    final segunda = arrancar();
    final cupos = await segunda.repo.obtenerCupos(especialidadId: 'esp-demo-01');
    final elCupo = cupos.valorONull!.where((c) => c.id == cupoId).firstOrNull;

    expect(
      elCupo?.disponible,
      isFalse,
      reason: 'Un cupo con cita activa no puede volver a ofrecerse libre',
    );
  });

  test('RNF-07: la idempotencia sobrevive al reinicio', () async {
    final cupoId = primerCupo();

    final primera = arrancar();
    final original = await primera.repo.confirmarReserva(
      pacienteId: 'pac-1',
      cupoId: cupoId,
      canal: CanalReserva.flujoGuiado,
      claveIdempotencia: 'misma-clave',
    );

    // La aplicacion se reinicia y el reintento llega con la misma clave.
    final segunda = arrancar();
    final reintento = await segunda.repo.confirmarReserva(
      pacienteId: 'pac-1',
      cupoId: cupoId,
      canal: CanalReserva.flujoGuiado,
      claveIdempotencia: 'misma-clave',
    );

    expect(reintento.valorONull!.id, original.valorONull!.id);

    final historial = await segunda.repo.obtenerCitas(pacienteId: 'pac-1');
    expect(historial.valorONull, hasLength(1));
  });

  test('cancelar sobrevive al reinicio y libera el cupo', () async {
    final cupoId = primerCupo();

    final primera = arrancar();
    final cita = await primera.repo.confirmarReserva(
      pacienteId: 'pac-1',
      cupoId: cupoId,
      canal: CanalReserva.flujoGuiado,
      claveIdempotencia: 'k1',
    );
    await primera.repo.cancelar(cita.valorONull!.id);

    final segunda = arrancar();
    final historial = await segunda.repo.obtenerCitas(pacienteId: 'pac-1');
    expect(historial.valorONull!.single.estado, EstadoCita.cancelada);

    final cupos = await segunda.repo.obtenerCupos(especialidadId: 'esp-demo-01');
    final elCupo = cupos.valorONull!.where((c) => c.id == cupoId).firstOrNull;
    expect(elCupo?.disponible, isTrue);
  });
}
