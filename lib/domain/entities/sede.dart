/// Sede fisica de la clinica. Las coordenadas alimentan HU-10.
class Sede {
  const Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.referencia,
  });

  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;

  /// Referencia en texto. Es lo que se muestra cuando `usarMapas` esta en
  /// `false`, de modo que la pantalla de ubicacion siga siendo util sin la
  /// clave de Google Maps.
  final String? referencia;

  Sede copyWith({
    String? id,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    String? referencia,
  }) => Sede(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    direccion: direccion ?? this.direccion,
    latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud,
    referencia: referencia ?? this.referencia,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sede &&
          other.id == id &&
          other.nombre == nombre &&
          other.direccion == direccion &&
          other.latitud == latitud &&
          other.longitud == longitud &&
          other.referencia == referencia;

  @override
  int get hashCode =>
      Object.hash(id, nombre, direccion, latitud, longitud, referencia);

  @override
  String toString() => 'Sede($id, $nombre)';
}
