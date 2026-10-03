import 'package:citas_medicas_app/app/router.dart';
import 'package:citas_medicas_app/app/theme/app_theme.dart';
import 'package:citas_medicas_app/core/config/app_config.dart';
import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/error/resultado.dart';
import 'package:citas_medicas_app/domain/entities/consultorio.dart';
import 'package:citas_medicas_app/domain/entities/especialidad.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/entities/profesional.dart';
import 'package:citas_medicas_app/domain/entities/sede.dart';
import 'package:citas_medicas_app/domain/repositories/catalogo_repository.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/screens/inicio_screen.dart';
import 'package:citas_medicas_app/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/inicio_sesion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/registro_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/tema_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'dobles_sesion.dart';

class _CatalogoVacio implements CatalogoRepository {
  const _CatalogoVacio();

  @override
  Future<Resultado<List<Especialidad>>> obtenerEspecialidades() async =>
      const Resultado<List<Especialidad>>.exito(<Especialidad>[]);

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

/// La fecha va poblada para que la pantalla de privacidad pueda mostrarla.
final _pacienteDemo = Paciente(
  id: 'pac-1',
  tipoDocumento: TipoDocumento.dni,
  numeroDocumento: '12345678',
  nombres: 'Ana Maria',
  apellidos: 'Ficticia',
  correo: 'ana@ejemplo.test',
  telefono: '999888777',
  consentimientoOtorgado: true,
  fechaConsentimiento: DateTime(2026, 9, 15),
);

/// Monta la aplicacion en [rutaInicial] con los dobles indicados.
({Widget arbol, PacienteRepositoryStub repo, PreferenciasStub prefs}) _app({
  required String rutaInicial,
  Paciente? paciente,
  FalloApp? falloEnInicioSesion,
  FalloApp? falloEnRegistro,
}) {
  final repo = PacienteRepositoryStub(
    paciente: paciente,
    falloEnInicioSesion: falloEnInicioSesion,
    falloEnRegistro: falloEnRegistro,
  );
  final prefs = PreferenciasStub();
  final sesion = SesionViewModel(repo, prefs);

  // Al abrir una pantalla directamente por ruta no pasamos por la puerta de
  // entrada, que es quien normalmente dispara la restauracion de la sesion.
  sesion.restaurar();

  final arbol = MultiProvider(
    providers: [
      ChangeNotifierProvider<TemaViewModel>(create: (_) => TemaViewModel(prefs)),
      ChangeNotifierProvider<CatalogoViewModel>(
        create: (_) => CatalogoViewModel(const _CatalogoVacio()),
      ),
      ChangeNotifierProvider<SesionViewModel>.value(value: sesion),
      ChangeNotifierProvider<RegistroViewModel>(
        create: (_) => RegistroViewModel(sesion),
      ),
      ChangeNotifierProvider<InicioSesionViewModel>(
        create: (_) => InicioSesionViewModel(sesion),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      initialRoute: rutaInicial,
      routes: AppRouter.rutas,
      onUnknownRoute: AppRouter.rutaDesconocida,
    ),
  );

  return (arbol: arbol, repo: repo, prefs: prefs);
}

/// Amplia el viewport del test.
///
/// El formulario de registro es mas alto que los 600 px del viewport por
/// defecto, y un `ListView` no monta lo que queda fuera de pantalla: sin esto,
/// los ultimos campos sencillamente no existen en el arbol.
void _viewportAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Rellena el formulario de registro con datos validos.
Future<void> _rellenarRegistro(
  WidgetTester tester, {
  String documento = '12345678',
  String clave = 'clave1234',
  String? confirmacion,
}) async {
  Future<void> escribir(String etiqueta, String valor) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(etiqueta),
        matching: find.byType(TextField),
      ),
      valor,
    );
  }

  await escribir(Cadenas.numeroDocumento, documento);
  await escribir(Cadenas.nombres, 'Ana Maria');
  await escribir(Cadenas.apellidos, 'Ficticia Ejemplo');
  await escribir(Cadenas.correo, 'ana@ejemplo.test');
  await escribir(Cadenas.telefono, '999888777');
  await escribir(Cadenas.clave, clave);
  await escribir(Cadenas.confirmarClave, confirmacion ?? clave);
  await tester.pump();
}

Future<void> _marcarConsentimiento(WidgetTester tester) async {
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
}

Future<void> _pulsarCrearCuenta(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, Cadenas.crearCuenta),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.widgetWithText(FilledButton, Cadenas.crearCuenta));
  await tester.pumpAndSettle();
}

void main() {
  // `FormatoFecha` usa `intl` con locale es_PE. En la aplicacion lo inicializa
  // `main()`; en los tests hay que hacerlo explicitamente o las pantallas que
  // formatean fechas lanzan LocaleDataException.
  setUpAll(() => initializeDateFormatting(AppConfig.localeCompleto));

  group('HU-01 — Registro', () {
    testWidgets('muestra todos los campos del formulario', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(_app(rutaInicial: Rutas.registro).arbol);
      await tester.pumpAndSettle();

      for (final etiqueta in <String>[
        Cadenas.numeroDocumento,
        Cadenas.nombres,
        Cadenas.apellidos,
        Cadenas.correo,
        Cadenas.telefono,
        Cadenas.clave,
        Cadenas.confirmarClave,
      ]) {
        expect(find.text(etiqueta), findsWidgets, reason: 'Falta $etiqueta');
      }
    });

    testWidgets('RN-10: la casilla de consentimiento nace desmarcada',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(_app(rutaInicial: Rutas.registro).arbol);
      await tester.pumpAndSettle();

      final casilla = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(
        casilla.value,
        isFalse,
        reason: 'RN-10 exige un acto explicito: nunca premarcar',
      );
    });

    testWidgets('RN-10: sin consentimiento no se registra', (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.registro);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(tester);
      // Deliberadamente NO se marca el consentimiento.
      await _pulsarCrearCuenta(tester);

      expect(app.repo.vecesRegistrar, 0);
      expect(
        find.text('Debes aceptar el tratamiento de tus datos para registrarte.'),
        findsOneWidget,
      );
    });

    testWidgets('RN-02: un DNI invalido bloquea el registro', (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.registro);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(tester, documento: '1234');
      await _marcarConsentimiento(tester);
      await _pulsarCrearCuenta(tester);

      expect(app.repo.vecesRegistrar, 0);
      expect(find.text('El DNI debe tener 8 digitos.'), findsOneWidget);
    });

    testWidgets('las contrasenas que no coinciden bloquean el registro',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.registro);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(
        tester,
        clave: 'clave1234',
        confirmacion: 'otraClave99',
      );
      await _marcarConsentimiento(tester);
      await _pulsarCrearCuenta(tester);

      expect(app.repo.vecesRegistrar, 0);
      expect(find.text('Las contrasenas no coinciden.'), findsOneWidget);
    });

    testWidgets('con datos validos registra y entra a la aplicacion',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.registro);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(tester);
      await _marcarConsentimiento(tester);
      await _pulsarCrearCuenta(tester);

      expect(app.repo.vecesRegistrar, 1);
      expect(find.byType(InicioScreen), findsOneWidget);
    });

    testWidgets('RN-10: el paciente enviado lleva el consentimiento y su fecha',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.registro);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(tester);
      await _marcarConsentimiento(tester);
      await _pulsarCrearCuenta(tester);

      final enviado = app.repo.ultimoPacienteRecibido;
      expect(enviado, isNotNull);
      expect(enviado!.consentimientoOtorgado, isTrue);
      expect(enviado.fechaConsentimiento, isNotNull);
    });

    testWidgets('RN-02: el documento se normaliza antes de enviarse',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.registro);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(tester, documento: '12 345 678');
      await _marcarConsentimiento(tester);
      await _pulsarCrearCuenta(tester);

      expect(app.repo.ultimoPacienteRecibido?.numeroDocumento, '12345678');
    });

    testWidgets('un fallo del repositorio se muestra en pantalla',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(
        rutaInicial: Rutas.registro,
        falloEnRegistro: const FalloValidacion(
          'Ya existe una cuenta registrada con este documento.',
          campo: 'numeroDocumento',
        ),
      );
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await _rellenarRegistro(tester);
      await _marcarConsentimiento(tester);
      await _pulsarCrearCuenta(tester);

      expect(
        find.text('Ya existe una cuenta registrada con este documento.'),
        findsOneWidget,
      );
      expect(find.byType(InicioScreen), findsNothing);
    });
  });

  group('HU-02 — Inicio de sesion', () {
    testWidgets('los campos vacios no llegan al repositorio', (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.inicioSesion);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, Cadenas.entrar));
      await tester.pumpAndSettle();

      expect(app.repo.vecesIniciarSesion, 0);
      expect(find.text(Cadenas.ingresaDocumentoOUsuario), findsOneWidget);
      expect(find.text('Ingresa tu contrasena.'), findsOneWidget);
    });

    testWidgets('el fallo es generico y no revela cual credencial fallo',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(
        rutaInicial: Rutas.inicioSesion,
        falloEnInicioSesion: const FalloAutenticacion(),
      );
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.ancestor(
          of: find.text(Cadenas.documentoOUsuario),
          matching: find.byType(TextField),
        ),
        '12345678',
      );
      await tester.enterText(
        find.ancestor(
          of: find.text(Cadenas.clave),
          matching: find.byType(TextField),
        ),
        'claveEquivocada',
      );
      await tester.tap(find.widgetWithText(FilledButton, Cadenas.entrar));
      await tester.pumpAndSettle();

      const mensaje = 'Los datos ingresados no son correctos.';
      expect(find.text(mensaje), findsOneWidget);

      // El mensaje no menciona ni el documento ni la contrasena.
      expect(mensaje.toLowerCase(), isNot(contains('documento')));
      expect(mensaje.toLowerCase(), isNot(contains('contrasena')));
    });

    testWidgets('con credenciales correctas entra a la aplicacion',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(
        rutaInicial: Rutas.inicioSesion,
        paciente: _pacienteDemo,
      );
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.ancestor(
          of: find.text(Cadenas.documentoOUsuario),
          matching: find.byType(TextField),
        ),
        '12345678',
      );
      await tester.enterText(
        find.ancestor(
          of: find.text(Cadenas.clave),
          matching: find.byType(TextField),
        ),
        'clave1234',
      );
      await tester.tap(find.widgetWithText(FilledButton, Cadenas.entrar));
      await tester.pumpAndSettle();

      expect(app.repo.vecesIniciarSesion, 1);
      expect(find.byType(InicioScreen), findsOneWidget);
    });
  });

  group('HU-12 — Privacidad y datos', () {
    testWidgets('con consentimiento vigente ofrece revocar', (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.privacidad, paciente: _pacienteDemo);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      // La sesion se restaura sola al abrir la puerta de entrada; aqui se
      // carga directamente la pantalla, asi que se fuerza la restauracion.
      expect(find.text(Cadenas.revocarConsentimiento), findsOneWidget);
    });

    testWidgets('revocar pide confirmacion antes de aplicarse', (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.privacidad, paciente: _pacienteDemo);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text(Cadenas.revocarConsentimiento));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(Cadenas.revocarConsentimientoAviso), findsOneWidget);

      // Cancelar no cambia nada.
      await tester.tap(find.text(Cadenas.cancelar));
      await tester.pumpAndSettle();
      expect(app.repo.paciente?.consentimientoOtorgado, isTrue);
    });

    testWidgets('al confirmar, el consentimiento queda revocado',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.privacidad, paciente: _pacienteDemo);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text(Cadenas.revocarConsentimiento));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Cadenas.confirmar));
      await tester.pumpAndSettle();

      expect(app.repo.paciente?.consentimientoOtorgado, isFalse);
      expect(find.text(Cadenas.otorgarConsentimiento), findsOneWidget);
    });

    testWidgets('revocar cuesta lo mismo que volver a otorgar', (tester) async {
      _viewportAlto(tester);
      final app = _app(
        rutaInicial: Rutas.privacidad,
        paciente: _pacienteDemo.copyWith(consentimientoOtorgado: false),
      );
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      // Otorgar: un solo toque, sin dialogo ni pasos disuasorios.
      await tester.tap(find.text(Cadenas.otorgarConsentimiento));
      await tester.pumpAndSettle();

      expect(app.repo.paciente?.consentimientoOtorgado, isTrue);
    });

    testWidgets('eliminar los datos borra la cuenta y las preferencias',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(rutaInicial: Rutas.privacidad, paciente: _pacienteDemo);
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(Cadenas.eliminarMisDatos),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(Cadenas.eliminarMisDatos));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(Cadenas.confirmar));
      await tester.pumpAndSettle();

      expect(app.repo.vecesEliminarDatos, 1);
      expect(app.repo.paciente, isNull);
      expect(
        app.prefs.limpiado,
        isTrue,
        reason: 'HU-12: no debe quedar rastro en el dispositivo',
      );
    });
  });
}
