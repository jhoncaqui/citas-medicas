import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/sede.dart';

/// Contrato para abrir indicaciones de desplazamiento hacia una sede.
///
/// RNF-12: la dependencia de plataforma queda detras de esta interfaz. La
/// aplicacion no llama a `url_launcher` directamente.
abstract interface class ServicioMapas {
  /// Abre la aplicacion de mapas del dispositivo con la ruta hacia [sede].
  ///
  /// Devuelve `false` si no hay ninguna aplicacion capaz de atenderlo, para
  /// que la pantalla pueda decirlo en lugar de quedarse en silencio.
  Future<bool> abrirIndicaciones(Sede sede);
}

class ServicioMapasImpl implements ServicioMapas {
  const ServicioMapasImpl();

  @override
  Future<bool> abrirIndicaciones(Sede sede) async {
    // Esquema geo: lo entienden Google Maps y cualquier otra aplicacion de
    // mapas instalada, sin atar la aplicacion a un proveedor concreto.
    final geo = Uri.parse(
      'geo:${sede.latitud},${sede.longitud}'
      '?q=${sede.latitud},${sede.longitud}(${Uri.encodeComponent(sede.nombre)})',
    );

    if (await canLaunchUrl(geo)) {
      return launchUrl(geo, mode: LaunchMode.externalApplication);
    }

    // Sin aplicacion de mapas, el navegador sirve igual.
    final web = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${sede.latitud},${sede.longitud}',
    );
    if (await canLaunchUrl(web)) {
      return launchUrl(web, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
