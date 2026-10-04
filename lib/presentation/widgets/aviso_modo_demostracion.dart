import 'package:material_ui/material_ui.dart';

import '../../core/config/feature_flags.dart';
import '../../l10n/cadenas.dart';

/// Banda que advierte que los datos en pantalla son ficticios.
///
/// Solo aparece mientras `FeatureFlags.usarBackendReal` este en `false`. No es
/// un patron oscuro: informa, no persuade, y desaparece sola cuando la
/// aplicacion se conecta al backend real.
class AvisoModoDemostracion extends StatelessWidget {
  const AvisoModoDemostracion({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.usarBackendReal) return const SizedBox.shrink();

    final esquema = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esquema.outline),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 20, color: esquema.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Cadenas.avisoDatosFicticios,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
