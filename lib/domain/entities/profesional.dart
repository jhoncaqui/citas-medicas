/// Profesional de la salud que atiende una especialidad.
class Profesional {
  const Profesional({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.especialidadId,
    required this.colegiatura,
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String especialidadId;

  /// Numero de colegiatura profesional.
  final String colegiatura;

  String get nombreCompleto => '$nombres $apellidos';

  Profesional copyWith({
    String? id,
    String? nombres,
    String? apellidos,
    String? especialidadId,
    String? colegiatura,
  }) => Profesional(
    id: id ?? this.id,
    nombres: nombres ?? this.nombres,
    apellidos: apellidos ?? this.apellidos,
    especialidadId: especialidadId ?? this.especialidadId,
    colegiatura: colegiatura ?? this.colegiatura,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profesional &&
          other.id == id &&
          other.nombres == nombres &&
          other.apellidos == apellidos &&
          other.especialidadId == especialidadId &&
          other.colegiatura == colegiatura;

  @override
  int get hashCode =>
      Object.hash(id, nombres, apellidos, especialidadId, colegiatura);

  @override
  String toString() => 'Profesional($id, $nombreCompleto)';
}
