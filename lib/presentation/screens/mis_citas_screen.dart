import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/utils/formato_fecha.dart';
import '../../domain/entities/cita.dart';
import '../../domain/entities/estado_cita.dart';
import '../../domain/rules/rn06_rn07_rn08_gestion.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/mis_citas_viewmodel.dart';
import '../viewmodels/reserva_viewmodel.dart';

/// HU-07 y HU-09 — Mis citas.
class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MisCitasViewModel>().cargar();

      // Los nombres de especialidad, profesional y sede salen del catalogo.
      // Si se entra aqui sin haber pasado por el flujo de reserva, todavia no
      // esta cargado y las tarjetas se quedarian sin esos datos.
      final reserva = context.read<ReservaViewModel>();
      if (reserva.especialidades.isEmpty) reserva.iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisCitasViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(Cadenas.misCitas),
        actions: <Widget>[
          IconButton(
            tooltip: Cadenas.actualizar,
            onPressed: vm.cargando ? null : vm.cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _BarraSincronizacion(),
            Expanded(
              child: vm.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _Contenido(vm: vm),
            ),
          ],
        ),
      ),
    );
  }
}

/// HU-09 — indica siempre de cuando son los datos.
class _BarraSincronizacion extends StatelessWidget {
  const _BarraSincronizacion();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisCitasViewModel>();
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final sincronizacion = vm.ultimaSincronizacion;
    final texto = sincronizacion == null
        ? Cadenas.nuncaSincronizado
        : '${Cadenas.ultimaSincronizacion} '
              '${FormatoFecha.desde(sincronizacion, ahora: vm.ahora)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: esquema.surfaceContainerHighest,
      child: Row(
        children: <Widget>[
          Icon(
            vm.sinConexion
                ? Icons.cloud_off_outlined
                : Icons.cloud_done_outlined,
            size: 18,
            color: esquema.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.sinConexion ? '${Cadenas.sinConexionAviso}. $texto' : texto,
              style: textos.bodySmall?.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.vm});

  final MisCitasViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.proximas.isEmpty && vm.pasadas.isEmpty) {
      return _Vacio(mensaje: vm.fallo?.mensaje ?? Cadenas.sinCitas);
    }

    return Semantics(
      label: Cadenas.semanticaListaCitas,
      container: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (vm.fallo != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                vm.fallo!.mensaje,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            Cadenas.proximasCitas,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (vm.proximas.isEmpty)
            Text(
              Cadenas.sinCitasProximas,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final cita in vm.proximas) ...<Widget>[
              _TarjetaCita(cita: cita, gestionable: true),
              const SizedBox(height: 12),
            ],

          if (vm.pasadas.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              Cadenas.citasAnteriores,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final cita in vm.pasadas) ...<Widget>[
              _TarjetaCita(cita: cita, gestionable: false),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TarjetaCita extends StatelessWidget {
  const _TarjetaCita({required this.cita, required this.gestionable});

  final Cita cita;
  final bool gestionable;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisCitasViewModel>();
    final reserva = context.read<ReservaViewModel>();
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final inicio = cita.fechaHoraInicio;
    final especialidad = reserva.especialidadDe(cita.especialidadId);
    final profesional = reserva.profesionalDe(cita.profesionalId);
    final sede = reserva.sedeDe(cita.sedeId);

    final puedeCancelar = gestionable && vm.puedeCancelar(cita);
    final puedeReprogramar = gestionable && vm.puedeReprogramar(cita);
    final motivo = gestionable
        ? vm.motivoBloqueo(cita, AccionAutogestion.cancelar)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    // Mientras el catalogo carga, se muestra el estado en vez
                    // de un titulo que no dice nada de esta cita.
                    especialidad?.nombre ?? Cadenas.cargando,
                    style: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _Estado(estado: cita.estado),
              ],
            ),
            const SizedBox(height: 8),

            if (inicio != null)
              Text(
                '${FormatoFecha.fechaLarga(inicio)} · '
                '${FormatoFecha.hora(inicio)}',
                style: textos.bodyMedium,
              ),
            if (profesional != null)
              Text(
                profesional.nombreCompleto,
                style: textos.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            if (sede != null)
              Text(
                sede.nombre,
                style: textos.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),

            if (gestionable) ...<Widget>[
              const SizedBox(height: 16),
              // RN-06: cuando el plazo ya paso se explica por que, en lugar de
              // dejar botones muertos sin motivo.
              if (!puedeCancelar && !puedeReprogramar && motivo != null)
                Text(
                  motivo,
                  style: textos.bodySmall?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: puedeReprogramar && !vm.ocupado
                            ? () => _reprogramar(context, cita)
                            : null,
                        child: const Text(Cadenas.reprogramar),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: puedeCancelar && !vm.ocupado
                            ? () => _cancelar(context, vm, cita)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: esquema.error,
                          side: BorderSide(color: esquema.error),
                        ),
                        child: const Text(Cadenas.cancelarCita),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelar(
    BuildContext context,
    MisCitasViewModel vm,
    Cita cita,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final esquema = Theme.of(context).colorScheme;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(Cadenas.cancelarCita),
        content: const Text(Cadenas.cancelarCitaAviso),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text(Cadenas.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: TextButton.styleFrom(foregroundColor: esquema.error),
            child: const Text(Cadenas.confirmar),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (await vm.cancelar(cita)) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Cadenas.citaCancelada)),
      );
    }
  }

  /// Reprogramar reutiliza el flujo guiado: elegir un horario nuevo es
  /// exactamente el mismo problema que elegirlo la primera vez.
  void _reprogramar(BuildContext context, Cita cita) {
    context.read<ReservaViewModel>().prepararReprogramacion(cita);
    Navigator.of(context).pushNamed(Rutas.flujoGuiado);
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.estado});

  final EstadoCita estado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    // El color acompana al texto, nunca lo sustituye (WCAG 1.4.1).
    final color = switch (estado) {
      EstadoCita.confirmada || EstadoCita.reprogramada => esquema.primary,
      EstadoCita.cancelada || EstadoCita.inasistencia => esquema.error,
      _ => esquema.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        estado.etiqueta,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed(Rutas.flujoGuiado),
            child: const Text(Cadenas.reservarAhora),
          ),
        ],
      ),
    ),
  );
}
