import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/feature_flags.dart';
import 'core/network/api_client.dart';
import 'core/mapas/servicio_mapas.dart';
import 'core/network/connectivity_service.dart';
import 'core/notificaciones/servicio_recordatorios.dart';
import 'core/security/almacen_seguro.dart';
import 'core/voz/servicio_dictado.dart';
import 'data/datasources/fake/cuentas_demo.dart';
import 'data/datasources/fake/fake_asistente_datasource.dart';
import 'data/datasources/fake/fake_catalogo_datasource.dart';
import 'data/datasources/fake/fake_cita_datasource.dart';
import 'data/datasources/fake/fake_paciente_datasource.dart';
import 'data/datasources/local/base_datos.dart';
import 'data/datasources/local/cita_local_datasource.dart';
import 'data/datasources/local/preferencias_local_datasource.dart';
import 'data/datasources/remote/asistente_remote_datasource.dart';
import 'data/datasources/remote/catalogo_remote_datasource.dart';
import 'data/datasources/remote/cita_remote_datasource.dart';
import 'data/datasources/remote/paciente_remote_datasource.dart';
import 'data/repositories/asistente_repository_impl.dart';
import 'data/repositories/catalogo_repository_impl.dart';
import 'data/repositories/cita_repository_impl.dart';
import 'data/repositories/paciente_repository_impl.dart';
import 'data/repositories/preferencias_repository_impl.dart';
import 'domain/repositories/asistente_repository.dart';
import 'domain/repositories/catalogo_repository.dart';
import 'domain/repositories/cita_repository.dart';
import 'domain/repositories/paciente_repository.dart';
import 'domain/repositories/preferencias_repository.dart';
import 'presentation/viewmodels/administracion_viewmodel.dart';
import 'presentation/viewmodels/catalogo_viewmodel.dart';
import 'presentation/viewmodels/conversacion_viewmodel.dart';
import 'presentation/viewmodels/indicadores_viewmodel.dart';
import 'presentation/viewmodels/inicio_sesion_viewmodel.dart';
import 'presentation/viewmodels/mis_citas_viewmodel.dart';
import 'presentation/viewmodels/registro_viewmodel.dart';
import 'presentation/viewmodels/reserva_viewmodel.dart';
import 'presentation/viewmodels/sesion_viewmodel.dart';
import 'presentation/viewmodels/tema_viewmodel.dart';
import 'presentation/viewmodels/ubicacion_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necesario para que `intl` formatee fechas en es_PE.
  await initializeDateFormatting(AppConfig.localeCompleto);

  runApp(const Arranque());
}

/// Arma el grafo de dependencias y lo publica con `provider`.
///
/// La eleccion entre las fuentes reales y las falsas ocurre en un unico
/// punto: con [FeatureFlags.usarBackendReal] en `false`, el resto de la
/// aplicacion no se entera de la diferencia.
class Arranque extends StatelessWidget {
  const Arranque({super.key});

  @override
  Widget build(BuildContext context) {
    // Un unico cliente HTTP para toda la aplicacion: el token que se le
    // inyecta al abrir sesion debe valer para todas las peticiones.
    final api = FeatureFlags.usarBackendReal ? ApiClient() : null;

    return MultiProvider(
      providers: <SingleChildWidget>[
        // ---------------- Infraestructura ----------------
        // RNF-08: el token de sesion vive aqui, nunca en shared_preferences.
        Provider<AlmacenSeguro>(create: (_) => AlmacenSeguroImpl()),

        Provider<PreferenciasLocalDataSource>(
          create: (_) => PreferenciasLocalDataSource(),
        ),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        Provider<ServicioMapas>(create: (_) => const ServicioMapasImpl()),
        Provider<ServicioDictado>(create: (_) => ServicioDictadoImpl()),

        // sqflite: historial consultable sin conexion (HU-09).
        Provider<BaseDatos>(create: (_) => BaseDatos()),
        ProxyProvider<BaseDatos, CitaLocalDataSource>(
          update: (_, bd, _) => CitaLocalDataSource(bd),
        ),

        // ---------------- Fuentes de datos ----------------
        Provider<CatalogoDataSource>(
          create: (_) => api != null
              ? ApiCatalogoDataSource(api)
              : const FakeCatalogoDataSource(),
        ),
        ProxyProvider<AlmacenSeguro, PacienteDataSource>(
          update: (_, almacen, _) => api != null
              ? ApiPacienteDataSource(api)
              : FakePacienteDataSource(
                  almacen,
                  cuentasIniciales: FeatureFlags.sembrarCuentasDemo
                      ? CuentasDemo.todas
                      : const <CuentaInicial>[],
                ),
        ),
        // El «servidor» simulado guarda su estado en la misma base local:
        // sin eso, cerrar la aplicacion equivaldria a que el servidor
        // olvidara todas las citas.
        ProxyProvider<CitaLocalDataSource, CitaDataSource>(
          update: (_, local, _) => api != null
              ? ApiCitaDataSource(api)
              : FakeCitaDataSource(persistencia: local),
        ),
        Provider<AsistenteDataSource>(
          create: (_) => api != null
              ? ApiAsistenteDataSource(api)
              : const FakeAsistenteDataSource(),
        ),

        // ---------------- Repositorios ----------------
        ProxyProvider<CatalogoDataSource, CatalogoRepository>(
          update: (_, fuente, _) => CatalogoRepositoryImpl(fuente),
        ),
        ProxyProvider<PreferenciasLocalDataSource, PreferenciasRepository>(
          update: (_, local, _) => PreferenciasRepositoryImpl(local),
        ),
        ProxyProvider2<PacienteDataSource, AlmacenSeguro, PacienteRepository>(
          update: (_, fuente, almacen, _) =>
              PacienteRepositoryImpl(fuente, almacen, api),
        ),
        ProxyProvider3<
          CitaDataSource,
          CitaLocalDataSource,
          ConnectivityService,
          CitaRepository
        >(
          update: (_, fuente, local, conectividad, _) => CitaRepositoryImpl(
            fuente,
            local: local,
            conectividad: conectividad,
          ),
        ),
        ProxyProvider<AsistenteDataSource, AsistenteRepository>(
          update: (_, fuente, _) => AsistenteRepositoryImpl(fuente),
        ),

        // HU-08: con `usarFirebase` en false los recordatorios se registran
        // en consola en lugar de enviarse.
        ProxyProvider<PreferenciasRepository, ServicioRecordatorios>(
          update: (_, preferencias, _) => RecordatoriosEnConsola(preferencias),
        ),

        // ---------------- ViewModels ----------------
        ChangeNotifierProvider<TemaViewModel>(
          create: (context) =>
              TemaViewModel(context.read<PreferenciasRepository>())..cargar(),
        ),
        ChangeNotifierProvider<CatalogoViewModel>(
          create: (context) =>
              CatalogoViewModel(context.read<CatalogoRepository>()),
        ),
        ChangeNotifierProvider<SesionViewModel>(
          create: (context) => SesionViewModel(
            context.read<PacienteRepository>(),
            context.read<PreferenciasRepository>(),
          ),
        ),

        // Los ViewModels de formulario dependen del de sesion y se
        // reconstruyen con el.
        ChangeNotifierProxyProvider<SesionViewModel, RegistroViewModel>(
          create: (context) =>
              RegistroViewModel(context.read<SesionViewModel>()),
          update: (_, _, anterior) => anterior!,
        ),
        ChangeNotifierProxyProvider<SesionViewModel, InicioSesionViewModel>(
          create: (context) =>
              InicioSesionViewModel(context.read<SesionViewModel>()),
          update: (_, _, anterior) => anterior!,
        ),

        // La reserva es estado compartido entre el flujo conversacional y el
        // guiado: un unico ViewModel para los dos (seccion 8, fallback).
        ChangeNotifierProvider<ReservaViewModel>(
          create: (context) => ReservaViewModel(
            context.read<CatalogoRepository>(),
            context.read<CitaRepository>(),
            context.read<SesionViewModel>(),
            recordatorios: context.read<ServicioRecordatorios>(),
          ),
        ),
        ChangeNotifierProvider<UbicacionViewModel>(
          create: (context) => UbicacionViewModel(
            context.read<CatalogoRepository>(),
            context.read<ServicioMapas>(),
          ),
        ),
        ChangeNotifierProvider<IndicadoresViewModel>(
          create: (context) => IndicadoresViewModel(
            context.read<CitaRepository>(),
            context.read<SesionViewModel>(),
          ),
        ),
        ChangeNotifierProvider<AdministracionViewModel>(
          create: (context) => AdministracionViewModel(
            context.read<CatalogoRepository>(),
            context.read<SesionViewModel>(),
          ),
        ),
        ChangeNotifierProvider<MisCitasViewModel>(
          create: (context) => MisCitasViewModel(
            context.read<CitaRepository>(),
            context.read<SesionViewModel>(),
            context.read<ServicioRecordatorios>(),
            conectividad: context.read<ConnectivityService>(),
          ),
        ),
        ChangeNotifierProxyProvider<ReservaViewModel, ConversacionViewModel>(
          create: (context) => ConversacionViewModel(
            context.read<AsistenteRepository>(),
            context.read<ReservaViewModel>(),
          ),
          update: (_, _, anterior) => anterior!,
        ),
      ],
      child: const CitasMedicasApp(),
    );
  }
}
