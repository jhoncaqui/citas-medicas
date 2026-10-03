import 'package:citas_medicas_app/app/router.dart';
import 'package:citas_medicas_app/app/theme/app_theme.dart';
import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/error/resultado.dart';
import 'package:citas_medicas_app/domain/entities/consultorio.dart';
import 'package:citas_medicas_app/domain/entities/especialidad.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/entities/rol_usuario.dart';
import 'package:citas_medicas_app/domain/entities/profesional.dart';
import 'package:citas_medicas_app/domain/entities/sede.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_asistente_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_cita_datasource.dart';
import 'package:citas_medicas_app/data/repositories/asistente_repository_impl.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/repositories/catalogo_repository.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/screens/inicio_screen.dart';
import 'package:citas_medicas_app/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/conversacion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/inicio_sesion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/reserva_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/tema_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'dobles_sesion.dart';

/// Repositorio de catalogo controlado por el test.
class _CatalogoRepositoryStub implements CatalogoRepository {
  _CatalogoRepositoryStub({this.especialidades = const [], this.fallo});

  final List<Especialidad> especialidades;
  final FalloApp? fallo;

  @override
  Future<Resultado<List<Especialidad>>> obtenerEspecialidades() async {
    if (fallo != null) return Resultado<List<Especialidad>>.fallo(fallo!);
    return Resultado<List<Especialidad>>.exito(especialidades);
  }

  @override
  Future<Resultado<List<Profesional>>> obtenerProfesionales({
    String? especialidadId,
  }) async =>
      const Resultado<List<Profesional>>.exito(<Profesional>[]);

  @override
  Future<Resultado<List<Sede>>> obtenerSedes() async =>
      const Resultado<List<Sede>>.exito(<Sede>[]);

  @override
  Future<Resultado<List<Consultorio>>> obtenerConsultorios({
    String? sedeId,
  }) async =>
      const Resultado<List<Consultorio>>.exito(<Consultorio>[]);
}

const _pacienteDemo = Paciente(
  id: 'pac-1',
  tipoDocumento: TipoDocumento.dni,
  numeroDocumento: '12345678',
  nombres: 'Ana Maria',
  apellidos: 'Ficticia',
  correo: 'ana@ejemplo.test',
  telefono: '999888777',
  consentimientoOtorgado: true,
);

Widget _montar({
  required CatalogoRepository catalogo,
  Paciente? paciente = _pacienteDemo,
}) {
  final preferencias = PreferenciasStub();
  final sesion = SesionViewModel(
    PacienteRepositoryStub(paciente: paciente),
    preferencias,
  );

  // Las pantallas de reserva son destinos reales de la navegacion desde
  // Inicio, asi que sus ViewModels tienen que estar disponibles.
  final reserva = ReservaViewModel(
    catalogo,
    CitaRepositoryImpl(FakeCitaDataSource(latencia: Duration.zero)),
    sesion,
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TemaViewModel>(
        create: (_) => TemaViewModel(preferencias),
      ),
      ChangeNotifierProvider<CatalogoViewModel>(
        create: (_) => CatalogoViewModel(catalogo),
      ),
      ChangeNotifierProvider<SesionViewModel>.value(value: sesion),
      ChangeNotifierProvider<InicioSesionViewModel>(
        create: (_) => InicioSesionViewModel(sesion),
      ),
      ChangeNotifierProvider<ReservaViewModel>.value(value: reserva),
      ChangeNotifierProvider<ConversacionViewModel>(
        create: (_) => ConversacionViewModel(
          const AsistenteRepositoryImpl(
            FakeAsistenteDataSource(latencia: Duration.zero),
          ),
          reserva,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      initialRoute: Rutas.raiz,
      routes: AppRouter.rutas,
      onUnknownRoute: AppRouter.rutaDesconocida,
    ),
  );
}

/// La pantalla de inicio crecio con el panel de indicadores y ya no cabe en
/// los 600 px del viewport por defecto.
void _viewportAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  const especialidadesDemo = <Especialidad>[
    Especialidad(
      id: 'esp-demo-01',
      nombre: 'Medicina General',
      descripcion: 'Descripcion de prueba.',
    ),
    Especialidad(
      id: 'esp-demo-04',
      nombre: 'Dermatologia',
      descripcion: 'No debe mostrarse.',
      activa: false,
    ),
  ];

  testWidgets('un paciente ve sus cuatro acciones y NO los indicadores',
      (tester) async {
    _viewportAlto(tester);
    await tester.pumpWidget(
      _montar(catalogo: _CatalogoRepositoryStub(especialidades: const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text(Cadenas.reservarConAsistente), findsOneWidget);
    expect(find.text(Cadenas.reservarPasoAPaso), findsOneWidget);
    expect(find.text(Cadenas.misCitas), findsOneWidget);
    expect(find.text(Cadenas.ubicacionSedes), findsOneWidget);
    expect(
      find.text(Cadenas.tituloIndicadores),
      findsNothing,
      reason: 'El panel es del personal de administracion: a un paciente ni '
          'se le anuncia',
    );
  });

  group('cuenta de administracion', () {
    final admin = _pacienteDemo.copyWith(
      id: 'adm-1',
      nombres: 'Jhon Daniel',
      tipoDocumento: TipoDocumento.usuario,
      numeroDocumento: 'JCAQUI',
      rol: RolUsuario.administrador,
    );

    testWidgets('ve la tarjeta de indicadores', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        _montar(
          catalogo: _CatalogoRepositoryStub(especialidades: const []),
          paciente: admin,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Cadenas.tituloIndicadores), findsOneWidget);
      // Saluda por el primer nombre.
      expect(find.text('${Cadenas.saludo}, Jhon'), findsOneWidget);
    });

    testWidgets('las acciones de paciente explican por que no estan disponibles',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        _montar(
          catalogo: _CatalogoRepositoryStub(especialidades: const []),
          paciente: admin,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Cadenas.reservarConAsistente));
      await tester.pump();

      // No navega: sigue en Inicio y avisa.
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('cuentas de administracion'),
        findsWidgets,
      );
    });
  });

  testWidgets('saluda al paciente por su primer nombre', (tester) async {
    await tester.pumpWidget(
      _montar(catalogo: _CatalogoRepositoryStub(especialidades: const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('${Cadenas.saludo}, Ana'), findsOneWidget);
  });

  testWidgets('lista solo las especialidades activas', (tester) async {
    await tester.pumpWidget(
      _montar(
        catalogo: _CatalogoRepositoryStub(especialidades: especialidadesDemo),
      ),
    );
    await tester.pumpAndSettle();

    // La lista queda por debajo del pliegue en el viewport del test.
    await tester.scrollUntilVisible(
      find.text('Medicina General'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Medicina General'), findsOneWidget);
    expect(find.text('Dermatologia'), findsNothing);
  });

  testWidgets('RNF-05: un solo toque lleva al flujo de reserva',
      (tester) async {
    await tester.pumpWidget(
      _montar(catalogo: _CatalogoRepositoryStub(especialidades: const [])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Cadenas.reservarConAsistente));
    await tester.pumpAndSettle();

    // Ya no estamos en Inicio: se navego a la pantalla de conversacion.
    expect(find.byType(InicioScreen), findsNothing);
    expect(find.text(Cadenas.reservarConAsistente), findsOneWidget);
  });

  testWidgets('un fallo del repositorio muestra el mensaje y permite reintentar',
      (tester) async {
    await tester.pumpWidget(
      _montar(
        catalogo: _CatalogoRepositoryStub(fallo: const FalloConexion()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(Cadenas.reintentar),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(const FalloConexion().mensaje), findsOneWidget);
    expect(find.text(Cadenas.reintentar), findsOneWidget);
  });

  testWidgets('RNF-04: las acciones principales alcanzan los 48 dp tactiles',
      (tester) async {
    _viewportAlto(tester);
    await tester.pumpWidget(
      _montar(catalogo: _CatalogoRepositoryStub(especialidades: const [])),
    );
    await tester.pumpAndSettle();

    for (final titulo in <String>[
      Cadenas.reservarConAsistente,
      Cadenas.reservarPasoAPaso,
      Cadenas.misCitas,
      Cadenas.ubicacionSedes,
    ]) {
      final tamano = tester.getSize(
        find.ancestor(of: find.text(titulo), matching: find.byType(InkWell)),
      );
      expect(
        tamano.height,
        greaterThanOrEqualTo(AppTheme.areaTactilMinima),
        reason: 'La accion "$titulo" no alcanza el area tactil minima',
      );
    }
  });

  testWidgets('RNF-04: la interfaz soporta el escalado de fuente del sistema',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _montar(
          catalogo: _CatalogoRepositoryStub(especialidades: especialidadesDemo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(Cadenas.reservarConAsistente), findsOneWidget);
  });

  group('RN-01 / RN-10 en la pantalla de inicio', () {
    testWidgets('sin sesion se muestra el inicio de sesion, no el inicio',
        (tester) async {
      await tester.pumpWidget(
        _montar(
          catalogo: _CatalogoRepositoryStub(especialidades: const []),
          paciente: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InicioScreen), findsNothing);
      expect(find.text(Cadenas.entrar), findsOneWidget);
    });

    testWidgets(
        'con el consentimiento revocado, reservar no navega y explica el motivo',
        (tester) async {
      await tester.pumpWidget(
        _montar(
          catalogo: _CatalogoRepositoryStub(especialidades: const []),
          paciente: _pacienteDemo.copyWith(consentimientoOtorgado: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Cadenas.reservarConAsistente));
      await tester.pump();

      // Sigue en Inicio y aparece el aviso en lugar de la pantalla siguiente.
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('con el consentimiento revocado se ofrece ir a privacidad',
        (tester) async {
      await tester.pumpWidget(
        _montar(
          catalogo: _CatalogoRepositoryStub(especialidades: const []),
          paciente: _pacienteDemo.copyWith(consentimientoOtorgado: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Cadenas.consentimientoRevocado), findsOneWidget);
      expect(find.text(Cadenas.tituloPrivacidad), findsOneWidget);
    });
  });
}
