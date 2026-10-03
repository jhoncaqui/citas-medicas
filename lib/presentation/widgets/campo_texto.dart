import 'package:material_ui/material_ui.dart';

import '../../l10n/cadenas.dart';

/// Campo de texto de los formularios de cuenta.
///
/// RNF-04:
/// - La etiqueta va como `label`, no como `hint`, para que no desaparezca al
///   escribir y siga anunciandose al lector de pantalla.
/// - El error se anuncia como region viva, de modo que el lector lo lea en
///   cuanto aparece en lugar de esperar a que el foco vuelva al campo.
/// - El boton de mostrar/ocultar contrasena lleva etiqueta semantica propia.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    required this.etiqueta,
    required this.onChanged,
    this.error,
    this.esClave = false,
    this.tipoTeclado,
    this.textoAyuda,
    this.autofillHints,
    this.maxCaracteres,
    this.habilitado = true,
    super.key,
  });

  final String etiqueta;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool esClave;
  final TextInputType? tipoTeclado;
  final String? textoAyuda;
  final Iterable<String>? autofillHints;
  final int? maxCaracteres;
  final bool habilitado;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late bool _oculto = widget.esClave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            enabled: widget.habilitado,
            obscureText: _oculto,
            keyboardType: widget.tipoTeclado,
            autofillHints: widget.autofillHints,
            maxLength: widget.maxCaracteres,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              labelText: widget.etiqueta,
              helperText: widget.textoAyuda,
              // El error se pinta aparte, debajo, para poder anunciarlo como
              // region viva; aqui solo se marca el borde.
              errorText: widget.error == null ? null : '',
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              counterText: '',
              suffixIcon: widget.esClave
                  ? IconButton(
                      tooltip: _oculto
                          ? Cadenas.semanticaMostrarClave
                          : Cadenas.semanticaOcultarClave,
                      icon: Icon(
                        _oculto ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _oculto = !_oculto),
                    )
                  : null,
            ),
          ),
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  widget.error!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
