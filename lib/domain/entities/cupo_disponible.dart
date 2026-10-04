/// Franja de atencion que un paciente puede reservar.
///
/// RN-03: un cupo solo puede estar asignado a una cita activa a la vez.
/// [disponible] refleja ese bloqueo.
class CupoDisponible {
  const CupoDisponible({
    required this.id,
    required this.profesionalId,
    required this.sedeId,
    required this.consultorioId,
    required this.fechaHoraInicio,
    required this.duracionMinutos,
    this.disponible = true,
  });

  final String id;
  final String profesionalId;
  final String sedeId;
  final String consultorioId;
  final DateTime fechaHoraInicio;
  final int duracionMinutos;
  final bool disponible;

  DateTime get fechaHoraFin =>
      fechaHoraInicio.add(Duration(minutes: duracionMinutos));

  /// Solo la fecha, sin hora. Se usa para agrupar cupos por dia y para RN-05.
  DateTime get soloFecha => DateTime(
    fechaHoraInicio.year,
    fechaHoraInicio.month,
    fechaHoraInicio.day,
  );

  CupoDisponible copyWith({
    String? id,
    String? profesionalId,
    String? sedeId,
    String? consultorioId,
    DateTime? fechaHoraInicio,
    int? duracionMinutos,
    bool? disponible,
  }) => CupoDisponible(
    id: id ?? this.id,
    profesionalId: profesionalId ?? this.profesionalId,
    sedeId: sedeId ?? this.sedeId,
    consultorioId: consultorioId ?? this.consultorioId,
    fechaHoraInicio: fechaHoraInicio ?? this.fechaHoraInicio,
    duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    disponible: disponible ?? this.disponible,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CupoDisponible &&
          other.id == id &&
          other.profesionalId == profesionalId &&
          other.sedeId == sedeId &&
          other.consultorioId == consultorioId &&
          other.fechaHoraInicio == fechaHoraInicio &&
          other.duracionMinutos == duracionMinutos &&
          other.disponible == disponible;

  @override
  int get hashCode => Object.hash(
    id,
    profesionalId,
    sedeId,
    consultorioId,
    fechaHoraInicio,
    duracionMinutos,
    disponible,
  );

  @override
  String toString() =>
      'CupoDisponible($id, $fechaHoraInicio, libre: $disponible)';
}
