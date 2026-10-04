import '../entities/cita.dart';
import '../entities/estado_cita.dart';
import '../entities/intencion_asistente.dart';

/// Indicadores del panel de admision (HU-11).
///
/// Se calculan sobre las citas ya conocidas, sin inventar datos: cada cifra
/// sale de contar citas reales. Las proporciones devuelven `null` cuando el
/// denominador es cero, porque mostrar «0 %» sobre cero casos es enganoso.
class Indicadores {
  const Indicadores({
    required this.reservadas,
    required this.canceladas,
    required this.inasistencias,
    required this.atendidas,
    required this.autogestionadas,
    required this.desde,
    required this.hasta,
  });

  /// Total de citas creadas en el periodo, sea cual sea su estado final.
  final int reservadas;

  final int canceladas;
  final int inasistencias;
  final int atendidas;

  /// Reservas originadas por el propio paciente desde la aplicacion.
  final int autogestionadas;

  final DateTime? desde;
  final DateTime? hasta;

  /// Citas ya cerradas: son el denominador de la tasa de inasistencia.
  int get cerradas => atendidas + inasistencias;

  /// Proporcion de inasistencias sobre las citas que ya pasaron.
  ///
  /// `null` si todavia no hay ninguna cerrada.
  double? get tasaInasistencia =>
      cerradas == 0 ? null : inasistencias / cerradas;

  /// Proporcion de cancelaciones sobre el total reservado.
  double? get tasaCancelacion =>
      reservadas == 0 ? null : canceladas / reservadas;

  /// **Proporcion de reservas autogestionadas**: el indicador que mide si la
  /// aplicacion esta descargando de trabajo al personal de admision.
  double? get tasaAutogestion =>
      reservadas == 0 ? null : autogestionadas / reservadas;

  bool get sinDatos => reservadas == 0;

  /// Calcula los indicadores sobre [citas], opcionalmente acotando al periodo
  /// [desde]–[hasta] por fecha de creacion de la cita.
  factory Indicadores.calcular(
    List<Cita> citas, {
    DateTime? desde,
    DateTime? hasta,
  }) {
    final enPeriodo = citas.where((c) {
      if (desde != null && c.fechaCreacion.isBefore(desde)) return false;
      if (hasta != null && c.fechaCreacion.isAfter(hasta)) return false;
      return true;
    }).toList();

    return Indicadores(
      reservadas: enPeriodo.length,
      canceladas: enPeriodo
          .where((c) => c.estado == EstadoCita.cancelada)
          .length,
      inasistencias: enPeriodo
          .where((c) => c.estado == EstadoCita.inasistencia)
          .length,
      atendidas: enPeriodo.where((c) => c.estado == EstadoCita.atendida).length,
      autogestionadas: enPeriodo
          .where((c) => c.canalReserva.esAutogestionada)
          .length,
      desde: desde,
      hasta: hasta,
    );
  }

  /// Reparto de reservas por canal, para saber de donde vienen las citas.
  static Map<CanalReserva, int> porCanal(List<Cita> citas) {
    final conteo = <CanalReserva, int>{
      for (final canal in CanalReserva.values) canal: 0,
    };
    for (final cita in citas) {
      conteo[cita.canalReserva] = (conteo[cita.canalReserva] ?? 0) + 1;
    }
    return conteo;
  }

  @override
  String toString() =>
      'Indicadores(reservadas: $reservadas, '
      'canceladas: $canceladas, inasistencias: $inasistencias)';
}
