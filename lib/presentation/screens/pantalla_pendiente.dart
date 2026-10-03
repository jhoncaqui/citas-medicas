import 'package:material_ui/material_ui.dart';

/// Marcador de una pantalla todavia no implementada.
///
/// Existe para que la navegacion de la Fase 0 sea real y verificable: cada
/// destino de la pantalla de inicio abre una pantalla de verdad, con su
/// AppBar y su boton de retroceso, en lugar de un callback vacio. Cada una se
/// sustituye por la pantalla definitiva en la fase que indica [fase].
class PantallaPendiente extends StatelessWidget {
  const PantallaPendiente({
    required this.titulo,
    required this.fase,
    required this.historias,
    super.key,
  });

  final String titulo;

  /// Fase del plan de ejecucion en la que se implementa.
  final String fase;

  /// Historias de usuario que cubrira, por ejemplo `HU-03, HU-04`.
  final String historias;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      // Seccion 12: edge-to-edge obligatorio en API 36.
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.construction_outlined,
                  size: 48,
                  color: esquema.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pendiente de la $fase',
                  style: textos.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta pantalla cubrira $historias.',
                  style: textos.bodyMedium?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
