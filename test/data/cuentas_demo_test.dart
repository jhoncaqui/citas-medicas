import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/security/almacen_seguro.dart';
import 'package:citas_medicas_app/data/datasources/fake/cuentas_demo.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_paciente_datasource.dart';
import 'package:citas_medicas_app/data/models/paciente_dto.dart';
import 'package:citas_medicas_app/data/repositories/paciente_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/rol_usuario.dart';
import 'package:citas_medicas_app/domain/rules/rn02_documento_identidad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AlmacenSeguroEnMemoria almacen;

  /// Una «apertura de la aplicacion»: instancias nuevas sobre el MISMO almacen,
  /// como al cerrar y reabrir la app en el dispositivo.
  FakePacienteDataSource abrir({List<CuentaInicial>? cuentas}) =>
      FakePacienteDataSource(
        almacen,
        cuentasIniciales: cuentas ?? CuentasDemo.todas,
        latencia: Duration.zero,
      );

  setUp(() => almacen = AlmacenSeguroEnMemoria());

  group('Contenido de las cuentas de demostracion', () {
    test('hay 3 administradores y 5 pacientes', () {
      expect(CuentasDemo.administradores, hasLength(3));
      expect(CuentasDemo.pacientes, hasLength(5));
      expect(CuentasDemo.todas, hasLength(8));
    });

    test('los administradores son jcaqui, emamani y ksaavedra', () {
      expect(
        CuentasDemo.administradores.map((c) => c.numeroDocumento).toSet(),
        <String>{'JCAQUI', 'EMAMANI', 'KSAAVEDRA'},
      );
    });

    test('los nombres de los administradores son los indicados', () {
      final porUsuario = {
        for (final c in CuentasDemo.administradores)
          c.numeroDocumento: '${c.apellidos}, ${c.nombres}',
      };
      expect(porUsuario['JCAQUI'], 'Caqui Calixto, Jhon Daniel');
      expect(porUsuario['EMAMANI'], 'Mamani Quispe, Elmer Willie');
      expect(porUsuario['KSAAVEDRA'], 'Saavedra Bautista, Karen Margarita');
    });

    test('los administradores tienen rol de administracion y los pacientes no',
        () {
      expect(
        CuentasDemo.administradores.every((c) => c.rol == 'administrador'),
        isTrue,
      );
      expect(
        CuentasDemo.pacientes.every((c) => c.rol == 'paciente'),
        isTrue,
      );
    });

    test('los identificadores son unicos', () {
      final documentos =
          CuentasDemo.todas.map((c) => c.perfil.numeroDocumento).toList();
      final ids = CuentasDemo.todas.map((c) => c.perfil.id).toList();
      expect(documentos.toSet(), hasLength(documentos.length));
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('los identificadores ya estan normalizados', () {
      // El inicio de sesion normaliza lo que se escribe (mayusculas, sin
      // separadores); si el sembrado no lo estuviera, nadie podria entrar.
      for (final c in CuentasDemo.todas) {
        expect(
          Rn02DocumentoIdentidad.normalizar(c.perfil.numeroDocumento),
          c.perfil.numeroDocumento,
          reason: '${c.perfil.numeroDocumento} no esta normalizado',
        );
      }
    });

    test('los datos de los pacientes son evidentemente ficticios', () {
      for (final p in CuentasDemo.pacientes) {
        expect(p.apellidos, contains('Ficticio'));
        expect(p.correo, endsWith('@ejemplo.test'));
        expect(
          p.numeroDocumento,
          startsWith('0000000'),
          reason: 'Ningun DNI real empieza asi: no puede ser el de alguien',
        );
      }
    });
  });

  group('Iniciar sesion con las cuentas sembradas', () {
    test('cada una de las 8 cuentas entra con la clave compartida', () async {
      final fuente = abrir();

      for (final c in CuentasDemo.todas) {
        final sesion = await fuente.iniciarSesion(
          numeroDocumento: c.perfil.numeroDocumento,
          clave: CuentasDemo.clave,
        );
        expect(sesion.paciente.id, c.perfil.id, reason: c.perfil.numeroDocumento);
        expect(sesion.token, isNotEmpty);
      }
    });

    test('el administrador entra con su usuario en minusculas', () async {
      final fuente = abrir();
      // Lo que escribe la persona pasa por la misma normalizacion que usa el
      // ViewModel de inicio de sesion.
      final escrito = Rn02DocumentoIdentidad.normalizar('jcaqui');

      final sesion = await fuente.iniciarSesion(
        numeroDocumento: escrito,
        clave: CuentasDemo.clave,
      );
      expect(sesion.paciente.aDominio().esAdministrador, isTrue);
      expect(sesion.paciente.nombres, 'Jhon Daniel');
    });

    test('un paciente sembrado entra como paciente, no como administrador',
        () async {
      final sesion = await abrir().iniciarSesion(
        numeroDocumento: '00000001',
        clave: CuentasDemo.clave,
      );
      expect(sesion.paciente.aDominio().rol, RolUsuario.paciente);
      expect(sesion.paciente.aDominio().esAdministrador, isFalse);
    });

    test('con una clave equivocada falla igual que con un usuario inexistente',
        () async {
      final fuente = abrir();

      Future<String> mensaje(String doc, String clave) async {
        try {
          await fuente.iniciarSesion(numeroDocumento: doc, clave: clave);
        } on FalloAutenticacion catch (e) {
          return e.mensaje;
        }
        fail('Deberia haber fallado');
      }

      final claveMala = await mensaje('JCAQUI', 'no-es-la-clave');
      final inexistente = await mensaje('NOEXISTE', CuentasDemo.clave);
      expect(claveMala, inexistente, reason: 'HU-02: no revelar cual fallo');
    });
  });

  group('Almacenamiento seguro de las claves sembradas', () {
    test('la clave no queda en claro en el almacen', () async {
      await abrir().iniciarSesion(
        numeroDocumento: 'JCAQUI',
        clave: CuentasDemo.clave,
      );

      final crudo = (await almacen.leer('cuentas_desarrollo'))!;
      expect(
        crudo.contains(CuentasDemo.clave),
        isFalse,
        reason: 'Sembrar no puede saltarse el hash con sal (RNF-08)',
      );
      expect(crudo, contains('"hash"'));
      expect(crudo, contains('"sal"'));
    });

    test('las ocho cuentas tienen hash distinto pese a compartir clave',
        () async {
      await abrir().iniciarSesion(
        numeroDocumento: 'JCAQUI',
        clave: CuentasDemo.clave,
      );

      final crudo = (await almacen.leer('cuentas_desarrollo'))!;
      final hashes = RegExp(r'"hash":"([a-f0-9]{64})"')
          .allMatches(crudo)
          .map((m) => m.group(1))
          .toSet();
      expect(hashes, hasLength(8), reason: 'La sal por cuenta no se aplico');
    });
  });

  group('Sembrado una sola vez', () {
    test('sin cuentas iniciales, el almacen queda limpio', () async {
      final fuente = abrir(cuentas: const <CuentaInicial>[]);

      await expectLater(
        fuente.iniciarSesion(numeroDocumento: 'JCAQUI', clave: CuentasDemo.clave),
        throwsA(isA<FalloAutenticacion>()),
      );
    });

    test('reabrir la aplicacion no duplica ni reinicia las cuentas', () async {
      await abrir().iniciarSesion(
        numeroDocumento: 'JCAQUI',
        clave: CuentasDemo.clave,
      );
      final antes = await almacen.leer('cuentas_desarrollo');

      // Segunda apertura: nada que sembrar, el almacen no cambia.
      await abrir().iniciarSesion(
        numeroDocumento: 'JCAQUI',
        clave: CuentasDemo.clave,
      );
      expect(await almacen.leer('cuentas_desarrollo'), antes);
    });

    test('una cuenta eliminada por su titular NO reaparece (HU-12)', () async {
      final fuente = abrir();
      final sesion = await fuente.iniciarSesion(
        numeroDocumento: '00000003',
        clave: CuentasDemo.clave,
      );

      await fuente.solicitarEliminacionDeDatos(sesion.paciente.id);

      // Ni en la misma apertura...
      await expectLater(
        fuente.iniciarSesion(numeroDocumento: '00000003', clave: CuentasDemo.clave),
        throwsA(isA<FalloAutenticacion>()),
      );
      // ...ni al reabrir la aplicacion.
      await expectLater(
        abrir().iniciarSesion(
          numeroDocumento: '00000003',
          clave: CuentasDemo.clave,
        ),
        throwsA(isA<FalloAutenticacion>()),
        reason: 'Eliminar los datos debe ser definitivo tambien en demo',
      );
    });

    test('no pisa una cuenta que ya existia con ese documento', () async {
      // Alguien se registro antes con el DNI que luego se quiere sembrar.
      final previo = abrir(cuentas: const <CuentaInicial>[]);
      await previo.registrar(
        paciente: const PacienteDto(
          id: '',
          tipoDocumento: 'DNI',
          numeroDocumento: '00000001',
          nombres: 'Otra',
          apellidos: 'Persona',
          correo: 'otra@ejemplo.test',
          telefono: '900000009',
          consentimientoOtorgado: true,
        ),
        clave: 'mi-propia-clave',
      );

      final conSembrado = abrir();
      // Sigue entrando con SU clave, no con la de demostracion.
      final sesion = await conSembrado.iniciarSesion(
        numeroDocumento: '00000001',
        clave: 'mi-propia-clave',
      );
      expect(sesion.paciente.nombres, 'Otra');
      await expectLater(
        conSembrado.iniciarSesion(
          numeroDocumento: '00000001',
          clave: CuentasDemo.clave,
        ),
        throwsA(isA<FalloAutenticacion>()),
      );
    });
  });

  group('Seguridad de los roles', () {
    test('nadie puede hacerse administrador registrandose', () async {
      final fuente = abrir(cuentas: const <CuentaInicial>[]);

      // Un cliente manipulado envia rol de administrador en el registro.
      final sesion = await fuente.registrar(
        paciente: const PacienteDto(
          id: '',
          tipoDocumento: 'DNI',
          numeroDocumento: '12345678',
          nombres: 'Intruso',
          apellidos: 'Ficticio',
          correo: 'intruso@ejemplo.test',
          telefono: '999888777',
          consentimientoOtorgado: true,
          rol: 'administrador',
        ),
        clave: 'clave-cualquiera',
      );

      expect(
        sesion.paciente.rol,
        'paciente',
        reason: 'El rol jamas se toma de lo que envia el cliente',
      );
    });

    test('un DNI sembrado no se puede volver a registrar', () async {
      final fuente = abrir();
      await expectLater(
        fuente.registrar(
          paciente: const PacienteDto(
            id: '',
            tipoDocumento: 'DNI',
            numeroDocumento: '00000002',
            nombres: 'Suplantador',
            apellidos: 'Ficticio',
            correo: 's@ejemplo.test',
            telefono: '900000009',
            consentimientoOtorgado: true,
          ),
          clave: 'otra-clave-123',
        ),
        throwsA(isA<FalloValidacion>()),
      );
    });

    test('revocar el consentimiento NO degrada a un administrador', () async {
      final fuente = abrir();
      final sesion = await fuente.iniciarSesion(
        numeroDocumento: 'JCAQUI',
        clave: CuentasDemo.clave,
      );

      final revocado = await fuente.revocarConsentimiento(sesion.paciente.id);
      expect(revocado.rol, 'administrador');

      final otorgado = await fuente.otorgarConsentimiento(sesion.paciente.id);
      expect(otorgado.rol, 'administrador');
    });

    test('el rol sobrevive al viaje por el repositorio y la sesion guardada',
        () async {
      final repo = PacienteRepositoryImpl(abrir(), almacen);

      final entrada = await repo.iniciarSesion(
        numeroDocumento: 'KSAAVEDRA',
        clave: CuentasDemo.clave,
      );
      expect(entrada.valorONull!.esAdministrador, isTrue);

      // Se «reabre» la aplicacion: la sesion se restaura del almacen seguro.
      final restaurada =
          await PacienteRepositoryImpl(abrir(), almacen).obtenerSesionActiva();
      expect(restaurada.valorONull!.esAdministrador, isTrue);
      expect(restaurada.valorONull!.nombres, 'Karen Margarita');
    });

    test('una cuenta guardada sin campo de rol se lee como paciente', () {
      // Cuentas creadas antes de que existieran los roles.
      final dto = PacienteDto.fromJson(<String, dynamic>{
        'id': 'pac-viejo',
        'numeroDocumento': '12345678',
        'nombres': 'Ana',
        'apellidos': 'Ficticia',
      });
      expect(dto.aDominio().rol, RolUsuario.paciente);
    });
  });
}
