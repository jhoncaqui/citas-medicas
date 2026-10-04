/// Especialidad medica ofertada por la clinica.
class Especialidad {
  const Especialidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.activa = true,
  });

  final String id;
  final String nombre;
  final String descripcion;

  /// Una especialidad inactiva no se ofrece para nuevas reservas.
  final bool activa;

  Especialidad copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    bool? activa,
  }) => Especialidad(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    activa: activa ?? this.activa,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Especialidad &&
          other.id == id &&
          other.nombre == nombre &&
          other.descripcion == descripcion &&
          other.activa == activa;

  @override
  int get hashCode => Object.hash(id, nombre, descripcion, activa);

  @override
  String toString() => 'Especialidad($id, $nombre)';
}
