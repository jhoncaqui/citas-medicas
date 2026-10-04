import '../../domain/entities/especialidad.dart';

/// DTO de transporte. Es una clase distinta de [Especialidad]: la capa de
/// dominio no debe cambiar porque el backend renombre un campo.
class EspecialidadDto {
  const EspecialidadDto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activa,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final bool activa;

  factory EspecialidadDto.fromJson(Map<String, dynamic> json) =>
      EspecialidadDto(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: (json['descripcion'] as String?) ?? '',
        activa: (json['activa'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'activa': activa,
  };

  Especialidad aDominio() => Especialidad(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    activa: activa,
  );

  factory EspecialidadDto.desdeDominio(Especialidad e) => EspecialidadDto(
    id: e.id,
    nombre: e.nombre,
    descripcion: e.descripcion,
    activa: e.activa,
  );
}
