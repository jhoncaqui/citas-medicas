import 'package:citas_medicas_app/data/datasources/fake/fake_catalogo_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fixtures.dart';
import 'package:citas_medicas_app/data/repositories/catalogo_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/entities/rol_usuario.dart';
import 'package:citas_medicas_app/presentation/viewmodels/administracion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_sesion.dart';

const _admin = Paciente(
  id: 'adm-1',
  tipoDocumento: TipoDocumento.usuario,
  numeroDocumento: 'ADMIN',
  nombres: 'Admin',
  apellidos: 'Ficticio',
  correo: 'admin@ejemplo.test',
  telefono: '',
  consentimientoOtorgado: true,
  rol: RolUsuario.administrador,
);

const _paciente = Paciente(
  id: 'pac-1',
  tipoDocumento: TipoDocumento.dni,
  numeroDocumento: '12345678',
  nombres: 'Ana',
  apellidos: 'Ficticia',
  correo: 'ana@ejemplo.test',
  telefono: '999888777',
  consentimientoOtorgado: true,
);

Future<AdministracionViewModel> _montar({required Paciente cuenta}) async {
  final sesion = SesionViewModel(
    PacienteRepositoryStub(paciente: cuenta),
    PreferenciasStub(),
  );
  await sesion.restaurar();
  final repo = CatalogoRepositoryImpl(
    const FakeCatalogoDataSource(latencia: Duration.zero),
  );
  final vm = AdministracionViewModel(repo, sesion);
  await vm.cargar();
  return vm;
}

void main() {
  // El catalogo es estado compartido (mutable). Cada test parte de la semilla.
  setUp(Fixtures.reiniciar);
  tearDown(Fixtures.reiniciar);

  group('Carga (solo administracion)', () {
    test('un administrador ve todo el catalogo, incluido lo inactivo', () async {
      final vm = await _montar(cuenta: _admin);

      expect(vm.puedeGestionar, isTrue);
      // 4 especialidades sembradas: una de ellas inactiva (Dermatologia).
      expect(vm.especialidades.length, 4);
      expect(vm.especialidades.any((e) => !e.activa), isTrue);
      expect(vm.profesionales.length, 4);
    });

    test('un paciente no puede gestionar el catalogo (RN-01)', () async {
      final vm = await _montar(cuenta: _paciente);

      expect(vm.puedeGestionar, isFalse);
      expect(vm.impedimento, isNotNull);
      // Sin privilegios, no se cargan registros.
      expect(vm.especialidades, isEmpty);
      expect(vm.profesionales, isEmpty);
    });
  });

  group('Especialidades — CRUD', () {
    test('crear agrega una especialidad nueva', () async {
      final vm = await _montar(cuenta: _admin);

      final ok = await vm.guardarEspecialidad(
        nombre: 'Traumatologia',
        descripcion: 'Lesiones del aparato locomotor.',
        activa: true,
      );

      expect(ok, isTrue);
      expect(vm.especialidades.length, 5);
      expect(vm.especialidades.any((e) => e.nombre == 'Traumatologia'), isTrue);
    });

    test('editar cambia los datos de una especialidad', () async {
      final vm = await _montar(cuenta: _admin);
      final objetivo = vm.especialidades.firstWhere((e) => e.activa);

      final ok = await vm.guardarEspecialidad(
        id: objetivo.id,
        nombre: 'Medicina Interna',
        descripcion: objetivo.descripcion,
        activa: true,
      );

      expect(ok, isTrue);
      expect(vm.especialidades.length, 4);
      final actualizada = vm.especialidades.firstWhere(
        (e) => e.id == objetivo.id,
      );
      expect(actualizada.nombre, 'Medicina Interna');
    });

    test('eliminar quita una especialidad sin profesionales', () async {
      final vm = await _montar(cuenta: _admin);
      // Se crea una especialidad nueva, sin profesionales asignados.
      await vm.guardarEspecialidad(
        nombre: 'Nutricion',
        descripcion: 'Alimentacion y dietetica.',
        activa: true,
      );
      final nueva = vm.especialidades.firstWhere((e) => e.nombre == 'Nutricion');

      final ok = await vm.eliminarEspecialidad(nueva.id);

      expect(ok, isTrue);
      expect(vm.especialidades.any((e) => e.id == nueva.id), isFalse);
    });

    test('no se elimina una especialidad con profesionales asignados', () async {
      final vm = await _montar(cuenta: _admin);
      // esp-demo-01 (Medicina General) tiene profesionales sembrados.
      final conProfesionales = vm.especialidades.firstWhere(
        (e) => e.id == 'esp-demo-01',
      );

      final ok = await vm.eliminarEspecialidad(conProfesionales.id);

      expect(ok, isFalse);
      expect(vm.fallo, isNotNull);
      expect(
        vm.especialidades.any((e) => e.id == 'esp-demo-01'),
        isTrue,
        reason: 'La especialidad sigue estando porque no se pudo eliminar',
      );
    });
  });

  group('Profesionales — CRUD', () {
    test('crear agrega un profesional nuevo', () async {
      final vm = await _montar(cuenta: _admin);

      final ok = await vm.guardarProfesional(
        nombres: 'Jorge',
        apellidos: 'Perez Lima',
        especialidadId: 'esp-demo-01',
        colegiatura: 'CMP-999999',
      );

      expect(ok, isTrue);
      expect(vm.profesionales.length, 5);
      expect(
        vm.profesionales.any((p) => p.nombreCompleto == 'Jorge Perez Lima'),
        isTrue,
      );
    });

    test('editar cambia los datos de un profesional', () async {
      final vm = await _montar(cuenta: _admin);
      final objetivo = vm.profesionales.first;

      final ok = await vm.guardarProfesional(
        id: objetivo.id,
        nombres: objetivo.nombres,
        apellidos: 'Apellido Cambiado',
        especialidadId: objetivo.especialidadId,
        colegiatura: objetivo.colegiatura,
      );

      expect(ok, isTrue);
      final actualizado = vm.profesionales.firstWhere(
        (p) => p.id == objetivo.id,
      );
      expect(actualizado.apellidos, 'Apellido Cambiado');
    });

    test('eliminar quita un profesional', () async {
      final vm = await _montar(cuenta: _admin);
      final objetivo = vm.profesionales.first;

      final ok = await vm.eliminarProfesional(objetivo.id);

      expect(ok, isTrue);
      expect(vm.profesionales.any((p) => p.id == objetivo.id), isFalse);
    });
  });

  group('RN-01 en las escrituras', () {
    test('un paciente no puede crear registros', () async {
      final vm = await _montar(cuenta: _paciente);

      final ok = await vm.guardarEspecialidad(
        nombre: 'Intento No Autorizado',
        descripcion: 'No deberia guardarse.',
        activa: true,
      );

      expect(ok, isFalse);
      // El catalogo compartido no se toco.
      expect(
        Fixtures.especialidades.any((e) => e.nombre == 'Intento No Autorizado'),
        isFalse,
      );
    });
  });
}
