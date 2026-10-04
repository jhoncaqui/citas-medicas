import 'package:citas_medicas_app/data/datasources/fake/fake_cita_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fixtures.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Lunes 21 de setiembre de 2026, 07:00: hay cupos por delante ese mismo dia.
  final ahora = DateTime(2026, 9, 21, 7, 0);
  DateTime reloj() => ahora;

  late FakeCitaDataSource fuente;
  late CitaRepositoryImpl repo;

  setUp(() {
    fuente = FakeCitaDataSource(latencia: Duration.zero, reloj: reloj);
    repo = CitaRepositoryImpl(fuente, reloj: reloj);
  });

  String primerCupoDe(String especialidadId) {
    final cupos = Fixtures.generarCupos(desde: ahora);
    final profesionales = Fixtures.profesionales
        .where((p) => p.especialidadId == especialidadId)
        .map((p) => p.id)
        .toSet();
    return cupos.firstWhere((c) => profesionales.contains(c.profesionalId)).id;
  }

  group('RNF-07 — idempotencia', () {
    test('dos confirmaciones con la misma clave crean UNA sola cita', () async {
      final cupoId = primerCupoDe('esp-demo-01');

      final primera = await repo.confirmarReserva(
        pacienteId: 'pac-1',
        cupoId: cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: 'intento-unico',
      );
      // Simula el reintento tras una caida de red: misma clave.
      final segunda = await repo.confirmarReserva(
        pacienteId: 'pac-1',
        cupoId: cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: 'intento-unico',
      );

      expect(primera.esExito, isTrue);
      expect(segunda.esExito, isTrue);
      expect(
        segunda.valorONull!.id,
        primera.valorONull!.id,
        reason: 'RNF-07: el reintento debe devolver la cita ya creada',
      );

      final citas = await repo.obtenerCitas(pacienteId: 'pac-1');
      expect(
        citas.valorONull,
        hasLength(1),
        reason: 'No debe haberse creado una segunda cita',
      );
    });

    test('claves distintas sobre el mismo cupo: la segunda se rechaza (RN-03)',
        () async {
      final cupoId = primerCupoDe('esp-demo-01');

      await repo.confirmarReserva(
        pacienteId: 'pac-1',
        cupoId: cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: 'intento-a',
      );
      final segunda = await repo.confirmarReserva(
        pacienteId: 'pac-2',
        cupoId: cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: 'intento-b',
      );

      expect(segunda.esFallo, isTrue);
      expect(segunda.falloONull!.mensaje, contains('ocuparse'));
    });
  });

  group('RN-03 — el cupo se bloquea al confirmar', () {
    test('tras reservar, el cupo deja de ofrecerse como disponible', () async {
      final cupoId = primerCupoDe('esp-demo-01');

      await repo.confirmarReserva(
        pacienteId: 'pac-1',
        cupoId: cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: 'k1',
      );

      final cupos = await repo.obtenerCupos(especialidadId: 'esp-demo-01');
      final elCupo =
          cupos.valorONull!.where((c) => c.id == cupoId).firstOrNull;
      expect(elCupo?.disponible, isFalse);
    });

    test('cancelar libera el cupo', () async {
      final cupoId = primerCupoDe('esp-demo-01');

      final cita = await repo.confirmarReserva(
        pacienteId: 'pac-1',
        cupoId: cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: 'k1',
      );
      await repo.cancelar(cita.valorONull!.id);

      final cupos = await repo.obtenerCupos(especialidadId: 'esp-demo-01');
      final elCupo =
          cupos.valorONull!.where((c) => c.id == cupoId).firstOrNull;
      expect(elCupo?.disponible, isTrue);
    });
  });

  group('HU-05 — disponibilidad real', () {
    test('un cupo ocupado por otra persona aparece como no disponible',
        () async {
      final cupoId = primerCupoDe('esp-demo-01');
      fuente.ocuparCupoExternamente(cupoId);

      final cupos = await repo.obtenerCupos(especialidadId: 'esp-demo-01');
      final elCupo =
          cupos.valorONull!.where((c) => c.id == cupoId).firstOrNull;
      expect(elCupo?.disponible, isFalse);
    });

    test('reservar un cupo tomado por otra persona falla', () async {
      final cupoId = primerCupoDe('esp-demo-01');
      fuente.ocuparCupoExternamente(cupoId);

      final resultado = await repo.confirmarReserva(
        pacienteId: 'pac-1',
        cupoId: cupoId,
        canal: CanalReserva.conversacional,
        claveIdempotencia: 'k1',
      );
      expect(resultado.esFallo, isTrue);
    });
  });

  group('RN-04 aplicado al listar cupos', () {
    test('el repositorio nunca devuelve cupos en el pasado', () async {
      final cupos = await repo.obtenerCupos(especialidadId: 'esp-demo-01');
      expect(
        cupos.valorONull!.every((c) => c.fechaHoraInicio.isAfter(ahora)),
        isTrue,
      );
    });

    test('los cupos vienen ordenados por hora', () async {
      final cupos = (await repo.obtenerCupos(
        especialidadId: 'esp-demo-01',
      ))
          .valorONull!;
      for (var i = 1; i < cupos.length; i++) {
        expect(
          cupos[i].fechaHoraInicio.isBefore(cupos[i - 1].fechaHoraInicio),
          isFalse,
        );
      }
    });

    test('el filtro por turno separa manana de tarde', () async {
      final manana = (await repo.obtenerCupos(
        especialidadId: 'esp-demo-01',
        turno: TurnoDia.manana,
      ))
          .valorONull!;
      expect(manana.every((c) => c.fechaHoraInicio.hour < 12), isTrue);

      final tarde = (await repo.obtenerCupos(
        especialidadId: 'esp-demo-01',
        turno: TurnoDia.tarde,
      ))
          .valorONull!;
      expect(tarde.every((c) => c.fechaHoraInicio.hour >= 12), isTrue);
    });
  });

  test('la cita confirmada queda con los datos del comprobante (HU-06)',
      () async {
    final cupoId = primerCupoDe('esp-demo-01');
    final resultado = await repo.confirmarReserva(
      pacienteId: 'pac-1',
      cupoId: cupoId,
      canal: CanalReserva.conversacional,
      claveIdempotencia: 'k1',
    );

    final cita = resultado.valorONull!;
    expect(cita.estado, EstadoCita.confirmada);
    expect(cita.especialidadId, 'esp-demo-01');
    expect(cita.profesionalId, isNotNull);
    expect(cita.sedeId, isNotNull);
    expect(cita.consultorioId, isNotNull);
    expect(cita.fechaHoraInicio, isNotNull);
    expect(cita.canalReserva, CanalReserva.conversacional);
  });
}
