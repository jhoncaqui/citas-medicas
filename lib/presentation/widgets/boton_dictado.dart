import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/config/feature_flags.dart';
import '../../core/voz/servicio_dictado.dart';
import '../../l10n/cadenas.dart';

/// Boton de microfono para dictar un mensaje por voz.
///
/// Llena el campo de texto con lo que se va reconociendo mediante [onTexto];
/// el paciente revisa y envia. Nada se envia por voz de forma automatica.
///
/// El permiso de microfono se pide al pulsar, nunca al arrancar. Si el
/// dispositivo no tiene reconocimiento de voz, el boton lo avisa y el chat
/// sigue funcionando por teclado.
class BotonDictado extends StatefulWidget {
  const BotonDictado({required this.onTexto, this.habilitado = true, super.key});

  /// Se invoca con el texto reconocido hasta el momento.
  final ValueChanged<String> onTexto;

  final bool habilitado;

  @override
  State<BotonDictado> createState() => _BotonDictadoState();
}

class _BotonDictadoState extends State<BotonDictado> {
  bool _escuchando = false;
  bool _ocupado = false;

  @override
  Widget build(BuildContext context) {
    // Bandera de compilacion: con el dictado apagado, el boton no existe.
    if (!FeatureFlags.usarDictado) return const SizedBox.shrink();

    final esquema = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: AppTheme.areaTactilMinima,
      child: IconButton(
        tooltip: _escuchando ? Cadenas.dictadoDetener : Cadenas.dictadoTooltip,
        onPressed: widget.habilitado && !_ocupado ? _alternar : null,
        icon: _ocupado
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _escuchando ? Icons.stop : Icons.mic,
                color: _escuchando ? esquema.error : null,
                semanticLabel: Cadenas.semanticaDictar,
              ),
      ),
    );
  }

  Future<void> _alternar() async {
    final servicio = context.read<ServicioDictado>();
    final mensajero = ScaffoldMessenger.of(context);

    if (_escuchando) {
      await servicio.detener();
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    setState(() => _ocupado = true);
    final disponible = await servicio.inicializar();
    if (!mounted) return;
    setState(() => _ocupado = false);

    if (!disponible) {
      mensajero.showSnackBar(
        const SnackBar(content: Text(Cadenas.dictadoNoDisponible)),
      );
      return;
    }

    setState(() => _escuchando = true);
    await servicio.escuchar(
      localeId: AppConfig.localeCompleto,
      alTranscribir: (texto, _) => widget.onTexto(texto),
      alTerminar: () {
        if (mounted) setState(() => _escuchando = false);
      },
      alFallar: (_) {
        if (!mounted) return;
        setState(() => _escuchando = false);
        mensajero.showSnackBar(
          const SnackBar(content: Text(Cadenas.dictadoError)),
        );
      },
    );
  }
}
