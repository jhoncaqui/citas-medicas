import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../domain/rules/rn01_autenticacion.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/catalogo_viewmodel.dart';
import '../viewmodels/sesion_viewmodel.dart';
import '../viewmodels/tema_viewmodel.dart';
import '../widgets/aviso_modo_demostracion.dart';
import '../widgets/tarjeta_accion.dart';

/// Pantalla de inicio.
///
/// RNF-05: desde aqui se llega al flujo de reserva en un solo toque, muy por
/// debajo del maximo de tres.
/// Seccion 12: envuelta en [SafeArea] porque al apuntar a API 36 el contenido
/// se dibuja detras de las barras del sistema y no se puede desactivar el
/// modo edge-to-edge.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();
    // La carga se dispara fuera del build para no llamar a notifyListeners
    // mientras el arbol se esta construyendo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogoViewModel>().cargarEspecialidades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar.medium(
              title: const Text(Cadenas.nombreApp),
              actions: const <Widget>[_BotonTema(), _BotonPrivacidad()],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.list(
                children: <Widget>[
                  const _Saludo(),
                  const SizedBox(height: 4),
                  Text(
                    Cadenas.descripcionApp,
                    style: textos.bodyLarge?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AvisoModoDemostracion(),
                  const _AvisoConsentimientoRevocado(),
                  const SizedBox(height: 24),

                  // RNF-05: un solo toque hasta el flujo de reserva.
                  _AccionProtegida(
                    operacion: OperacionProtegida.reservar,
                    titulo: Cadenas.reservarConAsistente,
                    detalle: Cadenas.reservarConAsistenteDetalle,
                    icono: Icons.forum_outlined,
                    destacada: true,
                    ruta: Rutas.conversacion,
                  ),
                  const SizedBox(height: 12),
                  _AccionProtegida(
                    operacion: OperacionProtegida.reservar,
                    titulo: Cadenas.reservarPasoAPaso,
                    detalle: Cadenas.reservarPasoAPasoDetalle,
                    icono: Icons.list_alt_outlined,
                    ruta: Rutas.flujoGuiado,
                  ),
                  const SizedBox(height: 12),
                  _AccionProtegida(
                    operacion: OperacionProtegida.consultarHistorial,
                    titulo: Cadenas.misCitas,
                    detalle: Cadenas.misCitasDetalle,
                    icono: Icons.event_available_outlined,
                    ruta: Rutas.misCitas,
                  ),
                  const SizedBox(height: 12),
                  // HU-11: el panel es para el personal de administracion.
                  // A un paciente ni se le anuncia: no es una funcion que
                  // «le falte para usar», sino una que no le corresponde.
                  const _TarjetaIndicadores(),
                  const _TarjetaAdministracion(),
                  TarjetaAccion(
                    titulo: Cadenas.ubicacionSedes,
                    detalle: Cadenas.ubicacionSedesDetalle,
                    icono: Icons.place_outlined,
                    onPressed: () => _irA(context, Rutas.ubicacion),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    Cadenas.especialidadesDisponibles,
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ListaEspecialidades(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _irA(BuildContext context, String ruta) =>
      Navigator.of(context).pushNamed(ruta);
}

/// Saluda al paciente por su nombre de pila.
class _Saludo extends StatelessWidget {
  const _Saludo();

  @override
  Widget build(BuildContext context) {
    final nombres = context.select<SesionViewModel, String?>(
      (vm) => vm.paciente?.nombres,
    );
    if (nombres == null || nombres.isEmpty) return const SizedBox.shrink();

    // Solo el primer nombre: mas cercano y menos invasivo que el nombre
    // completo en una pantalla que puede quedar a la vista de terceros.
    final primerNombre = nombres.trim().split(' ').first;

    return Text(
      '${Cadenas.saludo}, $primerNombre',
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// Acceso a privacidad y datos (HU-12).
class _BotonPrivacidad extends StatelessWidget {
  const _BotonPrivacidad();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: Cadenas.semanticaIrAPrivacidad,
    icon: const Icon(Icons.shield_outlined),
    onPressed: () => Navigator.of(context).pushNamed(Rutas.privacidad),
  );
}

/// RN-10: si el paciente revoco el consentimiento, se le explica por que no
/// puede reservar y se le ofrece la via para volver a autorizarlo. No se le
/// insiste ni se le vuelve a pedir por su cuenta.
class _AvisoConsentimientoRevocado extends StatelessWidget {
  const _AvisoConsentimientoRevocado();

  @override
  Widget build(BuildContext context) {
    final otorgado = context.select<SesionViewModel, bool>(
      (vm) => vm.paciente?.consentimientoOtorgado ?? true,
    );
    if (otorgado) return const SizedBox.shrink();

    final esquema = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esquema.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: esquema.error),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Cadenas.consentimientoRevocado,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: esquema.onSurface),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Rutas.privacidad),
              child: const Text(Cadenas.tituloPrivacidad),
            ),
          ],
        ),
      ),
    );
  }
}

/// Acceso al panel de indicadores; solo lo ven las cuentas de administracion.
class _TarjetaIndicadores extends StatelessWidget {
  const _TarjetaIndicadores();

  @override
  Widget build(BuildContext context) {
    final esAdministrador = context.select<SesionViewModel, bool>(
      (vm) => vm.paciente?.esAdministrador ?? false,
    );
    if (!esAdministrador) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaAccion(
        titulo: Cadenas.tituloIndicadores,
        detalle: Cadenas.indicadorAutogestion,
        icono: Icons.insights_outlined,
        destacada: true,
        onPressed: () => Navigator.of(context).pushNamed(Rutas.indicadores),
      ),
    );
  }
}

/// Acceso a la gestion del catalogo; solo lo ven las cuentas de
/// administracion. Les da el privilegio total sobre los registros de
/// especialidades y profesionales (alta, edicion y baja).
class _TarjetaAdministracion extends StatelessWidget {
  const _TarjetaAdministracion();

  @override
  Widget build(BuildContext context) {
    final esAdministrador = context.select<SesionViewModel, bool>(
      (vm) => vm.paciente?.esAdministrador ?? false,
    );
    if (!esAdministrador) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaAccion(
        titulo: Cadenas.tituloAdministracion,
        detalle: Cadenas.administracionDetalle,
        icono: Icons.manage_accounts_outlined,
        onPressed: () =>
            Navigator.of(context).pushNamed(Rutas.administracion),
      ),
    );
  }
}

/// Tarjeta de accion sujeta a RN-01 y RN-10.
///
/// Si la regla impide la operacion, la tarjeta no navega: explica el motivo.
/// Se deja visible en lugar de ocultarla para que el paciente entienda que la
/// funcion existe y que le falta para usarla.
class _AccionProtegida extends StatelessWidget {
  const _AccionProtegida({
    required this.operacion,
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.ruta,
    this.destacada = false,
  });

  final OperacionProtegida operacion;
  final String titulo;
  final String detalle;
  final IconData icono;
  final String ruta;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final impedimento = context.select<SesionViewModel, String?>(
      (vm) => vm.impedimentoPara(operacion),
    );

    return TarjetaAccion(
      titulo: titulo,
      detalle: impedimento ?? detalle,
      icono: icono,
      destacada: destacada && impedimento == null,
      onPressed: () {
        if (impedimento != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(impedimento)));
          return;
        }
        Navigator.of(context).pushNamed(ruta);
      },
    );
  }
}

/// RNF-03: se reconstruye solo con los cambios del ViewModel de catalogo, no
/// ante cualquier cambio del arbol de providers.
class _ListaEspecialidades extends StatelessWidget {
  const _ListaEspecialidades();

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogoViewModel>(
      builder: (context, vm, _) {
        return switch (vm.estado) {
          EstadoCarga.inicial || EstadoCarga.cargando => const _Cargando(),
          EstadoCarga.error => _Error(
            mensaje: vm.fallo?.mensaje ?? Cadenas.errorGenerico,
            onReintentar: vm.cargarEspecialidades,
          ),
          EstadoCarga.exito =>
            vm.especialidades.isEmpty
                ? const _Vacio()
                : Semantics(
                    label: Cadenas.semanticaListaEspecialidades,
                    container: true,
                    child: Column(
                      children: <Widget>[
                        for (final especialidad in vm.especialidades)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.medical_services_outlined,
                              ),
                              title: Text(especialidad.nombre),
                              subtitle: Text(especialidad.descripcion),
                            ),
                          ),
                      ],
                    ),
                  ),
        };
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => Semantics(
    label: Cadenas.semanticaCargando,
    liveRegion: true,
    child: const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(
      Cadenas.sinEspecialidades,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            mensaje,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: esquema.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text(Cadenas.reintentar),
          ),
        ],
      ),
    );
  }
}

/// Alterna entre claro y oscuro. Con el tema del sistema activo, el primer
/// toque adopta el contrario al que se esta viendo.
class _BotonTema extends StatelessWidget {
  const _BotonTema();

  @override
  Widget build(BuildContext context) {
    final modo = context.select<TemaViewModel, ThemeMode>((vm) => vm.modo);
    final esOscuroEfectivo = switch (modo) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    return IconButton(
      tooltip: Cadenas.semanticaCambiarTema,
      icon: Icon(esOscuroEfectivo ? Icons.light_mode : Icons.dark_mode),
      onPressed: () => context.read<TemaViewModel>().cambiar(
        esOscuroEfectivo ? ThemeMode.light : ThemeMode.dark,
      ),
    );
  }
}
