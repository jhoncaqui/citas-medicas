import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Formateo de fechas y horas en espanol de Peru.
///
/// Centralizado aqui para que ninguna pantalla construya cadenas de fecha por
/// su cuenta y para que el comprobante y el historial se vean identicos.
class FormatoFecha {
  const FormatoFecha._();

  static const String _locale = AppConfig.localeCompleto;

  /// `lunes, 15 de setiembre de 2026`
  static String fechaLarga(DateTime fecha) =>
      DateFormat("EEEE, d 'de' MMMM 'de' y", _locale).format(fecha);

  /// `15/09/2026`
  static String fechaCorta(DateTime fecha) =>
      DateFormat('dd/MM/y', _locale).format(fecha);

  /// `08:30 a. m.`
  static String hora(DateTime fecha) =>
      DateFormat('hh:mm a', _locale).format(fecha);

  /// `15/09/2026, 08:30 a. m.`
  static String fechaYHora(DateTime fecha) =>
      '${fechaCorta(fecha)}, ${hora(fecha)}';

  /// Texto relativo para la ultima sincronizacion del historial (HU-09).
  static String desde(DateTime momento, {DateTime? ahora}) {
    final referencia = ahora ?? DateTime.now();
    final diferencia = referencia.difference(momento);

    if (diferencia.isNegative) return 'hace unos instantes';
    if (diferencia.inMinutes < 1) return 'hace unos segundos';
    if (diferencia.inMinutes < 60) {
      final m = diferencia.inMinutes;
      return 'hace $m ${m == 1 ? 'minuto' : 'minutos'}';
    }
    if (diferencia.inHours < 24) {
      final h = diferencia.inHours;
      return 'hace $h ${h == 1 ? 'hora' : 'horas'}';
    }
    if (diferencia.inDays < 30) {
      final d = diferencia.inDays;
      return 'hace $d ${d == 1 ? 'dia' : 'dias'}';
    }
    return 'el ${fechaCorta(momento)}';
  }
}
