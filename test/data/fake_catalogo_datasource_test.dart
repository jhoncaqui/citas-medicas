import 'package:citas_medicas_app/data/datasources/fake/fake_catalogo_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fixtures.dart';
import 'package:citas_medicas_app/data/repositories/catalogo_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sin latencia: los tests no deben esperar de verdad.
  const fuente = FakeCatalogoDataSource(latencia: Duration.zero);
  const repositorio = CatalogoRepositoryImpl(fuente);

  group('FakeCatalogoDataSource', () {
    test('devuelve las especialidades de los fixtures', () async {
      final resultado = await repositorio.obtenerEspecialidades();
      expect(resultado.esExito, isTrue);
      expect(resultado.valorONull, hasLength(Fixtures.especialidades.length));
    });

    test('filtra profesionales por especialidad', () async {
      final resultado =
          await repositorio.obtenerProfesionales(especialidadId: 'esp-demo-01');
      expect(resultado.esExito, isTrue);
      final profesionales = resultado.valorONull!;
      expect(profesionales, isNotEmpty);
      expect(
        profesionales.every((p) => p.especialidadId == 'esp-demo-01'),
        isTrue,
      );
    });

    test('filtra consultorios por sede', () async {
      final resultado =
          await repositorio.obtenerConsultorios(sedeId: 'sede-demo-01');
      final consultorios = resultado.valorONull!;
      expect(consultorios, isNotEmpty);
      expect(consultorios.every((c) => c.sedeId == 'sede-demo-01'), isTrue);
    });
  });

  group('Fixtures.generarCupos', () {
    test('no genera cupos anteriores al momento indicado (RN-04)', () {
      final ahora = DateTime(2026, 9, 15, 10, 15);
      final cupos = Fixtures.generarCupos(desde: ahora, dias: 3);

      expect(cupos, isNotEmpty);
      expect(
        cupos.every((c) => c.fechaHoraInicio.isAfter(ahora)),
        isTrue,
        reason: 'RN-04 prohibe ofrecer cupos en el pasado',
      );
    });

    test('no genera cupos en domingo', () {
      final cupos = Fixtures.generarCupos(
        desde: DateTime(2026, 9, 14),
        dias: 14,
      );
      expect(
        cupos.any((c) => c.fechaHoraInicio.weekday == DateTime.sunday),
        isFalse,
      );
    });

    test('todos los cupos nacen disponibles y con identificador unico', () {
      final cupos = Fixtures.generarCupos(
        desde: DateTime(2026, 9, 15, 7),
        dias: 2,
      );
      expect(cupos.every((c) => c.disponible), isTrue);
      expect(cupos.map((c) => c.id).toSet(), hasLength(cupos.length));
    });
  });
}
