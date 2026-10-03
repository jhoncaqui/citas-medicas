import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/security/almacen_seguro.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_paciente_datasource.dart';
import 'package:citas_medicas_app/data/models/paciente_dto.dart';
import 'package:citas_medicas_app/data/repositories/paciente_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

const _nuevo = PacienteDto(
  id: '',
  tipoDocumento: 'DNI',
  numeroDocumento: '12345678',
  nombres: 'Nombre',
  apellidos: 'Apellido',
  correo: 'correo@ejemplo.test',
  telefono: '999888777',
  consentimientoOtorgado: true,
);

void main() {
  late AlmacenSeguroEnMemoria almacen;
  late FakePacienteDataSource fuente;

  setUp(() {
    almacen = AlmacenSeguroEnMemoria();
    fuente = FakePacienteDataSource(almacen, latencia: Duration.zero);
  });

  group('Registro', () {
    test('devuelve un paciente con id asignado y un token', () async {
      final sesion = await fuente.registrar(paciente: _nuevo, clave: 'clave1234');

      expect(sesion.paciente.id, isNotEmpty);
      expect(sesion.paciente.numeroDocumento, '12345678');
      expect(sesion.token, isNotEmpty);
    });

    test('rechaza un documento ya registrado (RN-02)', () async {
      await fuente.registrar(paciente: _nuevo, clave: 'clave1234');

      expect(
        () => fuente.registrar(paciente: _nuevo, clave: 'otraclave'),
        throwsA(isA<FalloValidacion>()),
      );
    });

    test('la clave NUNCA se guarda en claro', () async {
      const clave = 'claveSuperSecreta1';
      await fuente.registrar(paciente: _nuevo, clave: clave);

      final crudo = await almacen.leer('cuentas_desarrollo');
      expect(crudo, isNotNull);
      expect(
        crudo!.contains(clave),
        isFalse,
        reason: 'La clave aparece en claro en el almacenamiento',
      );
      expect(crudo, contains('hash'));
      expect(crudo, contains('sal'));
    });

    test('dos cuentas con la misma clave producen hashes distintos', () async {
      await fuente.registrar(paciente: _nuevo, clave: 'clave1234');
      await fuente.registrar(
        paciente: const PacienteDto(
          id: '',
          tipoDocumento: 'DNI',
          numeroDocumento: '87654321',
          nombres: 'Otro',
          apellidos: 'Paciente',
          correo: 'otro@ejemplo.test',
          telefono: '999111222',
          consentimientoOtorgado: true,
        ),
        clave: 'clave1234',
      );

      final crudo = (await almacen.leer('cuentas_desarrollo'))!;
      final hashes = RegExp(r'"hash":"([a-f0-9]{64})"')
          .allMatches(crudo)
          .map((m) => m.group(1))
          .toSet();
      expect(hashes, hasLength(2), reason: 'La sal por cuenta no se aplico');
    });
  });

  group('Inicio de sesion (HU-02)', () {
    test('con credenciales correctas devuelve la sesion', () async {
      await fuente.registrar(paciente: _nuevo, clave: 'clave1234');

      final sesion = await fuente.iniciarSesion(
        numeroDocumento: '12345678',
        clave: 'clave1234',
      );
      expect(sesion.paciente.numeroDocumento, '12345678');
    });

    test('documento inexistente y clave incorrecta dan el MISMO mensaje',
        () async {
      await fuente.registrar(paciente: _nuevo, clave: 'clave1234');

      String? mensajeInexistente;
      try {
        await fuente.iniciarSesion(
          numeroDocumento: '00000001',
          clave: 'loquesea',
        );
      } on FalloAutenticacion catch (e) {
        mensajeInexistente = e.mensaje;
      }

      String? mensajeClaveMala;
      try {
        await fuente.iniciarSesion(
          numeroDocumento: '12345678',
          clave: 'claveEquivocada',
        );
      } on FalloAutenticacion catch (e) {
        mensajeClaveMala = e.mensaje;
      }

      expect(mensajeInexistente, isNotNull);
      expect(
        mensajeInexistente,
        equals(mensajeClaveMala),
        reason: 'HU-02: el mensaje no debe revelar cual credencial fallo',
      );
    });
  });

  group('Consentimiento (RN-10 / HU-12)', () {
    test('revocar y volver a otorgar actualiza el perfil', () async {
      final sesion =
          await fuente.registrar(paciente: _nuevo, clave: 'clave1234');
      final id = sesion.paciente.id;

      final revocado = await fuente.revocarConsentimiento(id);
      expect(revocado.consentimientoOtorgado, isFalse);
      expect(revocado.fechaConsentimiento, isNull);

      final otorgado = await fuente.otorgarConsentimiento(id);
      expect(otorgado.consentimientoOtorgado, isTrue);
      expect(otorgado.fechaConsentimiento, isNotNull);
    });

    test('eliminar los datos borra la cuenta (HU-12)', () async {
      final sesion =
          await fuente.registrar(paciente: _nuevo, clave: 'clave1234');

      await fuente.solicitarEliminacionDeDatos(sesion.paciente.id);

      expect(
        () => fuente.iniciarSesion(
          numeroDocumento: '12345678',
          clave: 'clave1234',
        ),
        throwsA(isA<FalloAutenticacion>()),
      );
    });
  });

  group('PacienteRepositoryImpl y el almacen seguro (RNF-08)', () {
    test('el token se guarda al registrarse y se borra al cerrar sesion',
        () async {
      final repo = PacienteRepositoryImpl(fuente, almacen);

      final registro = await repo.registrar(
        paciente: _nuevo.aDominio(),
        clave: 'clave1234',
      );
      expect(registro.esExito, isTrue);
      expect(await almacen.leer(AlmacenSeguroImpl.claveToken), isNotNull);
      expect(await almacen.leer(AlmacenSeguroImpl.claveIdPaciente), isNotNull);

      await repo.cerrarSesion();
      expect(await almacen.leer(AlmacenSeguroImpl.claveToken), isNull);
      expect(await almacen.leer(AlmacenSeguroImpl.claveIdPaciente), isNull);
    });

    test('obtenerSesionActiva restaura la sesion guardada', () async {
      final repo = PacienteRepositoryImpl(fuente, almacen);
      await repo.registrar(paciente: _nuevo.aDominio(), clave: 'clave1234');

      final restaurada = await repo.obtenerSesionActiva();
      expect(restaurada.esExito, isTrue);
      expect(restaurada.valorONull?.numeroDocumento, '12345678');
    });

    test('sin sesion guardada devuelve null, no un fallo', () async {
      final repo = PacienteRepositoryImpl(fuente, almacen);
      final resultado = await repo.obtenerSesionActiva();

      expect(resultado.esExito, isTrue);
      expect(resultado.valorONull, isNull);
    });

    test('una sesion apuntando a una cuenta borrada se limpia sola', () async {
      final repo = PacienteRepositoryImpl(fuente, almacen);
      final registro =
          await repo.registrar(paciente: _nuevo.aDominio(), clave: 'clave1234');
      final id = registro.valorONull!.id;

      // La cuenta desaparece por detras, pero el token sigue en el almacen.
      await fuente.solicitarEliminacionDeDatos(id);
      await almacen.escribir(AlmacenSeguroImpl.claveToken, 'token-huerfano');
      await almacen.escribir(AlmacenSeguroImpl.claveIdPaciente, id);

      final resultado = await repo.obtenerSesionActiva();
      expect(resultado.valorONull, isNull);
      expect(await almacen.leer(AlmacenSeguroImpl.claveToken), isNull);
    });

    test('eliminar los datos deja el almacen seguro limpio (HU-12)', () async {
      final repo = PacienteRepositoryImpl(fuente, almacen);
      final registro =
          await repo.registrar(paciente: _nuevo.aDominio(), clave: 'clave1234');

      await repo.solicitarEliminacionDeDatos(registro.valorONull!.id);

      expect(await almacen.leer(AlmacenSeguroImpl.claveToken), isNull);
      expect(await almacen.leer(AlmacenSeguroImpl.claveIdPaciente), isNull);
    });
  });
}
