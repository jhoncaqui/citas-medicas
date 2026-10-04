import 'package:citas_medicas_app/core/config/app_config.dart';
import 'package:citas_medicas_app/core/config/feature_flags.dart';
import 'package:citas_medicas_app/core/error/resultado.dart';
import 'package:citas_medicas_app/core/mapas/servicio_mapas.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_catalogo_datasource.dart';
import 'package:citas_medicas_app/data/repositories/catalogo_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/cita.dart';
import 'package:citas_medicas_app/domain/entities/cupo_disponible.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/entities/rol_usuario.dart';
import 'package:citas_medicas_app/domain/entities/sede.dart';
import 'package:citas_medicas_app/domain/repositories/cita_repository.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/screens/indicadores_screen.dart';
import 'package:citas_medicas_app/presentation/screens/ubicacion_screen.dart';
import 'package:citas_medicas_app/presentation/viewmodels/indicadores_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/ubicacion_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'dobles_sesion.dart';

final _ahora = DateTime(2026, 9, 16, 10, 0);
DateTime _reloj() => _ahora;

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

/// Cuenta de administracion: la unica que puede ver el panel (RN-01).
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

Cita _cita({
  required String id,
  EstadoCita estado = EstadoCita.confirmada,
  CanalReserva canal = CanalReserva.flujoGuiado,
}) =>
    Cita(
      id: id,
      pacienteId: 'pac-1',
      cupoId: 'cupo-$id',
      estado: estado,
      fechaCreacion: _ahora.subtract(const Duration(days: 2)),
      canalReserva: canal,
      especialidadId: 'esp-demo-01',
      profesionalId: 'prof-demo-01',
    );

class _CitasStub implements CitaRepository {
  _CitasStub(this.citas);

  final List<Cita> citas;

  /// Cuantas veces se pidieron TODAS las citas de la clinica.
  int vecesTodasLasCitas = 0;

  @override
  Future<Resultado<List<Cita>>> obtenerTodasLasCitas() async {
    vecesTodasLasCitas++;
    return Resultado<List<Cita>>.exito(citas);
  }

  @override
  Future<Resultado<List<Cita>>> obtenerCitas({
    required String pacienteId,
    EstadoCita? estado,
  }) async =>
      Resultado<List<Cita>>.exito(citas);

  @override
  Future<Resultado<List<Cita>>> obtenerHistorialLocal(
    String pacienteId, {
    EstadoCita? estado,
  }) async =>
      Resultado<List<Cita>>.exito(citas);

  @override
  Future<Resultado<DateTime?>> obtenerFechaUltimaSincronizacion([
    String? pacienteId,
  ]) async =>
      Resultado<DateTime?>.exito(_ahora);

  @override
  Future<Resultado<List<CupoDisponible>>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
    TurnoDia? turno,
  }) async =>
      const Resultado<List<CupoDisponible>>.exito(<CupoDisponible>[]);

  @override
  Future<Resultado<Cita>> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required CanalReserva canal,
    required String claveIdempotencia,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Resultado<Cita>> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Resultado<Cita>> cancelar(String citaId) async =>
      throw UnimplementedError();
}

/// Servicio de mapas que registra si se le pidio abrir indicaciones.
class _MapasStub implements ServicioMapas {
  int llamadas = 0;
  Sede? ultimaSede;
  bool resultado = true;

  @override
  Future<bool> abrirIndicaciones(Sede sede) async {
    llamadas++;
    ultimaSede = sede;
    return resultado;
  }
}

void _viewportAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() => initializeDateFormatting(AppConfig.localeCompleto));

  // ------------------------------------------------------------------
  // HU-11 — Panel de indicadores
  // ------------------------------------------------------------------

  group('HU-11 — panel de indicadores', () {
    late _CitasStub repositorio;

    Future<Widget> montarIndicadores(
      List<Cita> citas, {
      Paciente cuenta = _admin,
    }) async {
      repositorio = _CitasStub(citas);
      final sesion = SesionViewModel(
        PacienteRepositoryStub(paciente: cuenta),
        PreferenciasStub(),
      );
      await sesion.restaurar();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SesionViewModel>.value(value: sesion),
          ChangeNotifierProvider<IndicadoresViewModel>(
            create: (_) => IndicadoresViewModel(
              repositorio,
              sesion,
              reloj: _reloj,
            ),
          ),
        ],
        child: const MaterialApp(home: IndicadoresScreen()),
      );
    }

    testWidgets('RN-01: un paciente no ve las cifras ni se consultan datos',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        await montarIndicadores(<Cita>[_cita(id: '1')], cuenta: _paciente),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Esta seccion es solo para el personal de administracion.'),
        findsOneWidget,
      );
      expect(find.text(Cadenas.indicadorReservadas), findsNothing);
      expect(
        repositorio.vecesTodasLasCitas,
        0,
        reason: 'A un paciente no se le piden las citas de los demas',
      );
    });

    testWidgets('un administrador consulta las citas de TODA la clinica',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        await montarIndicadores(<Cita>[_cita(id: '1'), _cita(id: '2')]),
      );
      await tester.pumpAndSettle();

      expect(repositorio.vecesTodasLasCitas, 1);
      expect(find.text(Cadenas.indicadorReservadas), findsOneWidget);
    });

    testWidgets('muestra el aviso de alcance de las cifras', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(await montarIndicadores(const <Cita>[]));
      await tester.pumpAndSettle();

      expect(
        find.text(Cadenas.indicadorAvisoAlcance),
        findsOneWidget,
        reason: 'Sin backend, las cifras no son de toda la clinica y hay que '
            'decirlo',
      );
    });

    testWidgets('sin citas lo dice en vez de mostrar ceros', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(await montarIndicadores(const <Cita>[]));
      await tester.pumpAndSettle();

      expect(find.text(Cadenas.indicadorSinDatos), findsOneWidget);
      expect(find.text(Cadenas.indicadorReservadas), findsNothing);
    });

    testWidgets('muestra las cifras cuando hay citas', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        await montarIndicadores(<Cita>[
          _cita(id: '1', canal: CanalReserva.conversacional),
          _cita(id: '2', estado: EstadoCita.cancelada),
          _cita(
            id: '3',
            estado: EstadoCita.inasistencia,
            canal: CanalReserva.presencial,
          ),
          _cita(id: '4', estado: EstadoCita.atendida),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text(Cadenas.indicadorReservadas), findsOneWidget);
      expect(find.text(Cadenas.indicadorAutogestion), findsWidgets);
      // 3 de 4 vienen de la aplicacion.
      expect(find.text('75 %'), findsOneWidget);
    });

    testWidgets('sin citas cerradas la tasa no se presenta como 0 %',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        await montarIndicadores(<Cita>[_cita(id: '1')]),
      );
      await tester.pumpAndSettle();

      expect(find.text(Cadenas.indicadorSinDenominador), findsWidgets);
    });

    testWidgets('cambiar de periodo recalcula', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(
        await montarIndicadores(<Cita>[_cita(id: '1'), _cita(id: '2')]),
      );
      await tester.pumpAndSettle();

      // Las citas se crearon hace 2 dias: entran en «ultimos 7».
      await tester.tap(find.text(PeriodoIndicadores.ultimos7.etiqueta));
      await tester.pumpAndSettle();
      expect(find.text(Cadenas.indicadorSinDatos), findsNothing);
    });
  });

  // ------------------------------------------------------------------
  // HU-10 — Ubicacion
  // ------------------------------------------------------------------

  group('HU-10 — ubicacion de sedes', () {
    late _MapasStub mapas;

    Widget montarUbicacion() {
      mapas = _MapasStub();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UbicacionViewModel>(
            create: (_) => UbicacionViewModel(
              const CatalogoRepositoryImpl(
                FakeCatalogoDataSource(latencia: Duration.zero),
              ),
              mapas,
            ),
          ),
        ],
        child: const MaterialApp(home: UbicacionScreen()),
      );
    }

    testWidgets('con usarMapas en false muestra direccion y referencia',
        (tester) async {
      _viewportAlto(tester);
      // La bandera es una constante de compilacion; en los tests vale false.
      expect(FeatureFlags.usarMapas, isFalse);

      await tester.pumpWidget(montarUbicacion());
      await tester.pumpAndSettle();

      expect(find.text(Cadenas.mapaNoDisponible), findsOneWidget);
      expect(find.text(Cadenas.direccion), findsOneWidget);
      expect(find.text(Cadenas.referencia), findsOneWidget);
      expect(
        find.textContaining('Av. Defensores del Morro 1221'),
        findsOneWidget,
        reason: 'Sin mapa, la direccion sigue siendo suficiente para llegar',
      );
    });

    testWidgets('permite elegir entre varias sedes', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(montarUbicacion());
      await tester.pumpAndSettle();

      expect(find.text('Sede Defensores del Morro'), findsWidgets);
      expect(find.text('Sede Prolongacion Huaylas'), findsWidgets);

      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Sede Prolongacion Huaylas'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Av. Prol. Huaylas 365'), findsOneWidget);
    });

    testWidgets('abrir indicaciones delega en el servicio de mapas',
        (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(montarUbicacion());
      await tester.pumpAndSettle();

      await tester.tap(find.text(Cadenas.abrirEnMapas));
      await tester.pumpAndSettle();

      expect(mapas.llamadas, 1);
      expect(mapas.ultimaSede?.nombre, 'Sede Defensores del Morro');
    });

    testWidgets('si no hay aplicacion de mapas se avisa', (tester) async {
      _viewportAlto(tester);
      final arbol = montarUbicacion();
      mapas.resultado = false;

      await tester.pumpWidget(arbol);
      await tester.pumpAndSettle();

      await tester.tap(find.text(Cadenas.abrirEnMapas));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('muestra los consultorios de la sede', (tester) async {
      _viewportAlto(tester);
      await tester.pumpWidget(montarUbicacion());
      await tester.pumpAndSettle();

      expect(find.textContaining('C-101'), findsOneWidget);
      expect(find.textContaining('C-204'), findsOneWidget);
      // Los de la otra sede no.
      expect(find.textContaining('N-301'), findsNothing);
    });
  });
}
