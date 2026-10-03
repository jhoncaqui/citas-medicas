import 'package:material_ui/material_ui.dart';

import '../../l10n/cadenas.dart';

/// Espacio reservado para el logo de la clinica.
///
/// Carga `assets/images/logo.png`. El archivo que acompana al proyecto es un
/// **marcador neutro**: basta con sustituirlo por el logo real conservando el
/// nombre, sin tocar codigo.
///
/// Si el archivo faltara, el widget no rompe la pantalla: dibuja el mismo
/// hueco en codigo. Una pantalla de inicio de sesion que no se puede usar
/// porque falta una imagen decorativa seria un mal negocio.
///
/// RNF-04: el logo es decorativo, asi que se marca como tal para que el lector
/// de pantalla lo ignore; anunciarlo solo anadiria ruido antes del formulario.
class LogoClinica extends StatelessWidget {
  const LogoClinica({this.alto = 96, super.key});

  /// Alto en dp. El ancho se ajusta conservando la proporcion.
  final double alto;

  static const String rutaAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        height: alto,
        child: Image.asset(
          rutaAsset,
          fit: BoxFit.contain,
          // Un logo no debe crecer con el escalado de fuente del sistema: el
          // espacio que ocupa esta pensado para dejar sitio al formulario.
          errorBuilder: (context, error, stack) => _Hueco(alto: alto),
        ),
      ),
    );
  }
}

/// Lo que se ve si el asset no esta disponible.
class _Hueco extends StatelessWidget {
  const _Hueco({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      height: alto,
      width: alto,
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esquema.outline),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: alto * 0.4,
        color: esquema.onSurfaceVariant,
      ),
    );
  }
}

/// Cabecera de las pantallas de cuenta: logo, titulo y subtitulo.
///
/// Existe para que el inicio de sesion y el registro compartan la misma
/// composicion en lugar de repetirla con medidas ligeramente distintas.
class CabeceraConLogo extends StatelessWidget {
  const CabeceraConLogo({
    required this.titulo,
    required this.subtitulo,
    this.altoLogo = 96,
    super.key,
  });

  final String titulo;
  final String subtitulo;
  final double altoLogo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        LogoClinica(alto: altoLogo),
        const SizedBox(height: 20),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Pie con el aviso de modo demostracion, para no dejar la pantalla de inicio
/// de sesion sin contexto sobre que datos se estan usando.
class PieDemostracion extends StatelessWidget {
  const PieDemostracion({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Text(
      Cadenas.avisoDatosFicticios,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: esquema.onSurfaceVariant),
    );
  }
}
