import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config/feature_flags.dart';
import '../../domain/entities/sede.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/ubicacion_viewmodel.dart';

/// HU-10 — Ubicacion de sede y consultorio.
///
/// Con `FeatureFlags.usarMapas` en `false` **no se instancia el mapa**: la
/// pantalla muestra direccion y referencia en texto, que es informacion
/// suficiente para llegar. Asi la aplicacion sigue siendo util sin la clave
/// de API, y el permiso de ubicacion no se pide nunca de mas.
class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UbicacionViewModel>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UbicacionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(Cadenas.ubicacionSedes)),
      body: SafeArea(
        child: vm.cargando
            ? const Center(child: CircularProgressIndicator())
            : vm.sedes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    vm.fallo?.mensaje ?? Cadenas.sinSedes,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            : _Contenido(vm: vm),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.vm});

  final UbicacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final sede = vm.seleccionada;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (vm.sedes.length > 1) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final s in vm.sedes)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: ChoiceChip(
                    label: Text(s.nombre),
                    selected: sede?.id == s.id,
                    onSelected: (_) => vm.seleccionar(s),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        if (sede != null) ...<Widget>[
          _Mapa(sede: sede),
          const SizedBox(height: 24),
          _Datos(sede: sede, vm: vm),
        ],
      ],
    );
  }
}

/// El mapa real solo se construye con la bandera activa.
class _Mapa extends StatelessWidget {
  const _Mapa({required this.sede});

  final Sede sede;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.usarMapas) return const _MapaNoDisponible();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Semantics(
          label: Cadenas.semanticaMapa,
          image: true,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(sede.latitud, sede.longitud),
              zoom: 16,
            ),
            markers: <Marker>{
              Marker(
                markerId: MarkerId(sede.id),
                position: LatLng(sede.latitud, sede.longitud),
                infoWindow: InfoWindow(
                  title: sede.nombre,
                  snippet: sede.direccion,
                ),
              ),
            },
            // Seccion 11: el permiso de ubicacion no se pide para ver donde
            // esta la sede. Solo haria falta para mostrar «tu posicion», que
            // no es lo que HU-10 necesita.
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
        ),
      ),
    );
  }
}

class _MapaNoDisponible extends StatelessWidget {
  const _MapaNoDisponible();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esquema.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.map_outlined, color: esquema.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Cadenas.mapaNoDisponible,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Datos extends StatelessWidget {
  const _Datos({required this.sede, required this.vm});

  final Sede sede;
  final UbicacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          sede.nombre,
          style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        _Dato(etiqueta: Cadenas.direccion, valor: sede.direccion),
        if (sede.referencia != null)
          _Dato(etiqueta: Cadenas.referencia, valor: sede.referencia!),

        if (vm.consultoriosDeLaSede.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            Cadenas.comprobanteConsultorio,
            style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final c in vm.consultoriosDeLaSede)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${c.codigo} · piso ${c.piso}',
                style: textos.bodyLarge,
              ),
            ),
        ],

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _abrir(context),
          icon: const Icon(Icons.directions_outlined),
          label: const Text(Cadenas.abrirEnMapas),
        ),
      ],
    );
  }

  Future<void> _abrir(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    if (!await vm.abrirIndicaciones()) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Cadenas.errorGenerico)),
      );
    }
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            etiqueta,
            style: textos.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
          ),
          Text(valor, style: textos.bodyLarge),
        ],
      ),
    );
  }
}
