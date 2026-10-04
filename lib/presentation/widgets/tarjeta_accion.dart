import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

/// Tarjeta pulsable de accion principal.
///
/// RNF-04: expone un unico nodo [Semantics] con etiqueta y rol de boton, y
/// garantiza la altura minima tactil de 48 dp.
/// RNF-05: es el control que lleva al flujo de reserva en un solo toque desde
/// la pantalla de inicio.
class TarjetaAccion extends StatelessWidget {
  const TarjetaAccion({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.onPressed,
    this.destacada = false,
    super.key,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final VoidCallback onPressed;

  /// La accion preferente de la pantalla, resaltada con el color primario.
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final fondo = destacada
        ? esquema.primaryContainer
        : esquema.surfaceContainerHighest;
    final sobreFondo = destacada
        ? esquema.onPrimaryContainer
        : esquema.onSurface;

    return Semantics(
      button: true,
      // El detalle va dentro de la etiqueta para que el lector de pantalla
      // anuncie la accion completa en un solo foco.
      label: '$titulo. $detalle',
      excludeSemantics: true,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTheme.areaTactilMinima,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(icono, size: 28, color: sobreFondo),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          titulo,
                          style: textos.titleMedium?.copyWith(
                            color: sobreFondo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detalle,
                          style: textos.bodyMedium?.copyWith(
                            color: destacada
                                ? sobreFondo
                                : esquema.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: sobreFondo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
