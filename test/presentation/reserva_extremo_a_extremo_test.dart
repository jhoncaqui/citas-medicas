import 'package:citas_medicas_app/app/router.dart';
import 'package:citas_medicas_app/app/theme/app_theme.dart';
import 'package:citas_medicas_app/core/config/app_config.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_asistente_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_catalogo_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_cita_datasource.dart';
import 'package:citas_medicas_app/data/repositories/asistente_repository_impl.dart';
import 'package:citas_medicas_app/data/repositories/catalogo_repository_impl.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/screens/comprobante_screen.dart';
import 'package:citas_medicas_app/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/conversacion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/reserva_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/tema_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'dobles_sesion.dart';

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

/// Lunes 21 de setiembre de 2026 a las 07:00: quedan cupos por delante.
final _ahora = DateTime(2026, 9, 21, 7, 0);
DateTime _reloj() => _ahora;

({Widget arbol, ReservaViewModel reserva, FakeCitaDataSource citas}) _app({
  Paciente? paciente = _paciente,
}) {
  final citas = FakeCitaDataSource(latencia: Duration.zero, reloj: _reloj);
  final sesion = SesionViewModel(
    PacienteRepositoryStub(paciente: paciente),
    PreferenciasStub(),
  )..restaurar();

  final reserva = ReservaViewModel(
    const CatalogoRepositoryImpl(
      FakeCatalogoDataSource(latencia: Duration.zero),
    ),
    CitaRepositoryImpl(citas, reloj: _reloj),
    sesion,
    reloj: _reloj,
  );

  final arbol = MultiProvider(
    providers: [
      ChangeNotifierProvider<TemaViewModel>(
        create: (_) => TemaViewModel(PreferenciasStub()),
      ),
      ChangeNotifierProvider<CatalogoViewModel>(
        create: (_) => CatalogoViewModel(
          const CatalogoRepositoryImpl(
            FakeCatalogoDataSource(latencia: Duration.zero),
          ),
        ),
      ),
      ChangeNotifierProvider<SesionViewModel>.value(value: sesion),
      ChangeNotifierProvider<ReservaViewModel>.value(value: reserva),
      ChangeNotifierProvider<ConversacionViewModel>(
        create: (_) => ConversacionViewModel(
          const AsistenteRepositoryImpl(
            FakeAsistenteDataSource(latencia: Duration.zero),
          ),
          reserva,
          reloj: _reloj,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      initialRoute: Rutas.flujoGuiado,
      routes: AppRouter.rutas,
      onUnknownRoute: AppRouter.rutaDesconocida,
    ),
  );

  return (arbol: arbol, reserva: reserva, citas: citas);
}

void _viewportAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() => initializeDateFormatting(AppConfig.localeCompleto));

  group('HU-04 a HU-06 — reserva completa por el flujo guiado', () {
    testWidgets('el paciente completa una reserva y ve su comprobante',
        (tester) async {
      _viewportAlto(tester);
      final app = _app();
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      // Paso 1 — especialidad.
      expect(find.text(Cadenas.pasoEspecialidad), findsOneWidget);
      await tester.tap(find.text('Medicina General'));
      await tester.pumpAndSettle();

      // Paso 2 — profesional: se acepta «cualquiera».
      expect(find.text(Cadenas.pasoProfesional), findsOneWidget);
      await tester.tap(find.text(Cadenas.cualquierProfesional));
      await tester.pumpAndSettle();

      // Paso 3 — fecha: se elige el primer dia ofrecido.
      expect(find.text(Cadenas.pasoFecha), findsOneWidget);
      final primerDia = find.byType(InkWell).first;
      await tester.tap(primerDia);
      await tester.pumpAndSettle();

      // Paso 4 — horario.
      expect(find.text(Cadenas.pasoHorario), findsOneWidget);
      expect(
        find.byType(ChoiceChip),
        findsWidgets,
        reason: 'HU-05: deben ofrecerse horarios reales',
      );
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, Cadenas.siguiente));
      await tester.pumpAndSettle();

      // Paso 5 — confirmacion.
      expect(find.text(Cadenas.pasoConfirmacion), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, Cadenas.confirmarReserva),
      );
      await tester.pumpAndSettle();

      // HU-06 — comprobante.
      expect(find.byType(ComprobanteScreen), findsOneWidget);
      expect(find.text(Cadenas.reservaConfirmada), findsOneWidget);
      expect(find.text(Cadenas.comprobanteEspecialidad), findsOneWidget);
      expect(find.text(Cadenas.comprobanteProfesional), findsOneWidget);
      expect(find.text(Cadenas.comprobanteFecha), findsOneWidget);
      expect(find.text(Cadenas.comprobanteHora), findsOneWidget);
      expect(find.text(Cadenas.comprobanteSede), findsOneWidget);

      expect(app.reserva.citaConfirmada, isNotNull);
      expect(app.reserva.citaConfirmada!.canalReserva,
          CanalReserva.flujoGuiado);
    });

    testWidgets('ODS 12: el comprobante no ofrece impresion', (tester) async {
      _viewportAlto(tester);
      final app = _app();
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medicina General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Cadenas.cualquierProfesional));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, Cadenas.siguiente));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, Cadenas.confirmarReserva),
      );
      await tester.pumpAndSettle();

      // El aviso explica que no hace falta imprimir; lo que no debe existir
      // es un control que ofrezca hacerlo.
      expect(find.text(Cadenas.comprobanteSinImpresion), findsOneWidget);
      expect(find.byIcon(Icons.print), findsNothing);
      expect(find.byIcon(Icons.print_outlined), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.download), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
    });

    testWidgets('RNF-04: los chips de horario alcanzan los 48 dp',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(_app().arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medicina General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Cadenas.cualquierProfesional));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      final tamano = tester.getSize(find.byType(ChoiceChip).first);
      expect(
        tamano.height,
        greaterThanOrEqualTo(AppTheme.areaTactilMinima),
      );
    });
  });

  group('HU-05 — el cupo que se ocupa durante la sesion', () {
    testWidgets('un cupo tomado por otra persona no se puede elegir',
        (tester) async {
      _viewportAlto(tester);
      final app = _app();
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medicina General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Cadenas.cualquierProfesional));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Otra persona reserva el primer cupo y se recarga la disponibilidad.
      // `runAsync` es imprescindible: dentro de `testWidgets` el reloj esta
      // falseado y los `Future.delayed` del repositorio no avanzarian solos.
      final primerCupo = app.reserva.cupos.first;
      app.citas.ocuparCupoExternamente(primerCupo.id);
      await tester.runAsync(() => app.reserva.cargarCupos());
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).first);
      expect(
        chip.onSelected,
        isNull,
        reason: 'Un cupo ocupado debe quedar deshabilitado, no desaparecer',
      );
    });
  });

  group('RN-01 y RN-10 en la confirmacion', () {
    testWidgets('sin consentimiento vigente, confirmar no crea la cita',
        (tester) async {
      _viewportAlto(tester);
      final app = _app(
        paciente: _paciente.copyWith(consentimientoOtorgado: false),
      );
      await tester.pumpWidget(app.arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medicina General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Cadenas.cualquierProfesional));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, Cadenas.siguiente));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, Cadenas.confirmarReserva),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ComprobanteScreen), findsNothing);
      expect(app.reserva.citaConfirmada, isNull);
      expect(app.reserva.fallo, isNotNull);
    });
  });

  group('RNF-07 — sin reservas duplicadas', () {
    // Sin arbol de widgets: es comportamiento del ViewModel, y montar la
    // pantalla solo anadiria indicadores de carga que `pumpAndSettle` tendria
    // que esperar.
    test('reintentar el mismo intento no crea una segunda cita', () async {
      final citas = FakeCitaDataSource(latencia: Duration.zero, reloj: _reloj);
      final repo = CitaRepositoryImpl(citas, reloj: _reloj);
      final vm = ReservaViewModel(
        const CatalogoRepositoryImpl(
          FakeCatalogoDataSource(latencia: Duration.zero),
        ),
        repo,
        SesionViewModel(
          PacienteRepositoryStub(paciente: _paciente),
          PreferenciasStub(),
        )..restaurar(),
        reloj: _reloj,
      );

      await vm.iniciar();
      await vm.elegirEspecialidad(vm.especialidades.first);
      vm.elegirFecha(_ahora.add(const Duration(days: 1)));
      await vm.cargarCupos();
      vm.elegirCupo(vm.cupos.first);
      vm.prepararConfirmacionDirecta();

      final clave = vm.claveIdempotencia;
      expect(clave, isNotNull);

      expect(await vm.confirmar(), isTrue);
      final primera = vm.citaConfirmada!;

      // El mismo intento, reenviado: el backend debe devolver la misma cita.
      final reintento = await repo.confirmarReserva(
        pacienteId: _paciente.id,
        cupoId: primera.cupoId,
        canal: CanalReserva.flujoGuiado,
        claveIdempotencia: clave!,
      );

      expect(reintento.valorONull!.id, primera.id);

      final todas = await repo.obtenerCitas(pacienteId: _paciente.id);
      expect(
        todas.valorONull,
        hasLength(1),
        reason: 'RNF-07: una caida de red no debe generar dos reservas',
      );
    });

    test('la clave se libera solo cuando la reserva queda confirmada',
        () async {
      final citas = FakeCitaDataSource(latencia: Duration.zero, reloj: _reloj);
      final vm = ReservaViewModel(
        const CatalogoRepositoryImpl(
          FakeCatalogoDataSource(latencia: Duration.zero),
        ),
        CitaRepositoryImpl(citas, reloj: _reloj),
        SesionViewModel(
          PacienteRepositoryStub(paciente: _paciente),
          PreferenciasStub(),
        )..restaurar(),
        reloj: _reloj,
      );

      await vm.iniciar();
      await vm.elegirEspecialidad(vm.especialidades.first);
      vm.elegirFecha(_ahora.add(const Duration(days: 1)));
      await vm.cargarCupos();

      // Otra persona toma el cupo justo antes de confirmar: la reserva falla
      // y la clave debe conservarse para el siguiente intento.
      final cupo = vm.cupos.first;
      vm.elegirCupo(cupo);
      vm.prepararConfirmacionDirecta();
      final clave = vm.claveIdempotencia;

      citas.ocuparCupoExternamente(cupo.id);
      expect(await vm.confirmar(), isFalse);

      expect(
        vm.claveIdempotencia,
        clave,
        reason: 'Si la reserva no se confirmo, el reintento usa la misma clave',
      );
    });
  });
}
