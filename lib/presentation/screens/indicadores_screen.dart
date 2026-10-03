import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config/feature_flags.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../l10n/cadenas.dart';
import '../viewmodels/indicadores_viewmodel.dart';

/// HU-11 — Panel de indicadores para el personal de admision.
class IndicadoresScreen extends StatefulWidget {
  const IndicadoresScreen({super.key});

  @override
  State<IndicadoresScreen> createState() => _IndicadoresScreenState();
}

class _IndicadoresScreenState extends State<IndicadoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IndicadoresViewModel>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IndicadoresViewModel>();
    final datos = vm.indicadores;

    return Scaffold(
      appBar: AppBar(title: const Text(Cadenas.tituloIndicadores)),
      body: SafeArea(
        child: vm.cargando
            ? const Center(child: CircularProgressIndicator())
            : vm.fallo != null
            ? _Bloqueado(mensaje: vm.fallo!.mensaje)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  // Con el backend real las cifras SI son de la clinica y el
                  // aviso sobra.
                  if (!FeatureFlags.usarBackendReal) ...<Widget>[
                    const _AvisoAlcance(),
                    const SizedBox(height: 16),
                  ],
                  _SelectorPeriodo(vm: vm),
                  const SizedBox(height: 24),

                  if (datos.sinDatos)
                    Text(
                      Cadenas.indicadorSinDatos,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  else ...<Widget>[
                    _Cifra(
                      etiqueta: Cadenas.indicadorReservadas,
                      valor: '${datos.reservadas}',
                      destacada: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Cifra(
                            etiqueta: Cadenas.indicadorCanceladas,
                            valor: '${datos.canceladas}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Cifra(
                            etiqueta: Cadenas.indicadorInasistencias,
                            valor: '${datos.inasistencias}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Cifra(
                            etiqueta: Cadenas.indicadorAtendidas,
                            valor: '${datos.atendidas}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Cifra(
                            etiqueta: Cadenas.indicadorTasaInasistencia,
                            valor: _porcentaje(datos.tasaInasistencia),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Cifra(
                      etiqueta: Cadenas.indicadorAutogestion,
                      valor: _porcentaje(datos.tasaAutogestion),
                      detalle:
                          '${datos.autogestionadas} de ${datos.reservadas}',
                      destacada: true,
                    ),

                    const SizedBox(height: 32),
                    Text(
                      Cadenas.indicadorPorCanal,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _PorCanal(conteo: vm.porCanal, total: datos.reservadas),
                  ],
                ],
              ),
      ),
    );
  }

  /// Un denominador de cero no se presenta como «0 %».
  static String _porcentaje(double? valor) {
    if (valor == null) return Cadenas.indicadorSinDenominador;
    return '${(valor * 100).round()} %';
  }
}

/// Lo que ve quien llega aqui sin ser administrador (o sin sesion).
class _Bloqueado extends StatelessWidget {
  const _Bloqueado({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Semantics(
        liveRegion: true,
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
}

class _AvisoAlcance extends StatelessWidget {
  const _AvisoAlcance();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esquema.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 20, color: esquema.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Cadenas.indicadorAvisoAlcance,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorPeriodo extends StatelessWidget {
  const _SelectorPeriodo({required this.vm});

  final IndicadoresViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Cadenas.indicadorPeriodo,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final periodo in PeriodoIndicadores.values)
              ConstrainedBox(
                // RNF-04: area tactil minima.
                constraints: const BoxConstraints(minHeight: 48),
                child: ChoiceChip(
                  label: Text(periodo.etiqueta),
                  selected: vm.periodo == periodo,
                  onSelected: (_) => vm.cambiarPeriodo(periodo),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.etiqueta,
    required this.valor,
    this.detalle,
    this.destacada = false,
  });

  final String etiqueta;
  final String valor;
  final String? detalle;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Semantics(
      // El lector de pantalla anuncia la cifra junto a lo que significa, no
      // un numero suelto.
      label: '$etiqueta: $valor${detalle == null ? '' : '. $detalle'}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: destacada
              ? esquema.primaryContainer
              : esquema.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              etiqueta,
              style: textos.bodySmall?.copyWith(
                color: destacada
                    ? esquema.onPrimaryContainer
                    : esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: textos.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: destacada
                    ? esquema.onPrimaryContainer
                    : esquema.onSurface,
              ),
            ),
            if (detalle != null)
              Text(
                detalle!,
                style: textos.bodySmall?.copyWith(
                  color: destacada
                      ? esquema.onPrimaryContainer
                      : esquema.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PorCanal extends StatelessWidget {
  const _PorCanal({required this.conteo, required this.total});

  final Map<CanalReserva, int> conteo;
  final int total;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        for (final entrada in conteo.entries)
          if (entrada.value > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                label: '${entrada.key.etiqueta}: ${entrada.value} de $total',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entrada.key.etiqueta,
                            style: textos.bodyMedium,
                          ),
                        ),
                        Text(
                          '${entrada.value}',
                          style: textos.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // La barra acompana a la cifra; nunca la sustituye.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : entrada.value / total,
                        minHeight: 8,
                        backgroundColor: esquema.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
