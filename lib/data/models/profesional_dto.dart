import '../../domain/entities/profesional.dart';

class ProfesionalDto {
  const ProfesionalDto({
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
  final String colegiatura;

  factory ProfesionalDto.fromJson(Map<String, dynamic> json) => ProfesionalDto(
    id: json['id'] as String,
    nombres: json['nombres'] as String,
    apellidos: json['apellidos'] as String,
    especialidadId: json['especialidadId'] as String,
    colegiatura: (json['colegiatura'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombres': nombres,
    'apellidos': apellidos,
    'especialidadId': especialidadId,
    'colegiatura': colegiatura,
  };

  Profesional aDominio() => Profesional(
    id: id,
    nombres: nombres,
    apellidos: apellidos,
    especialidadId: especialidadId,
    colegiatura: colegiatura,
  );

  factory ProfesionalDto.desdeDominio(Profesional p) => ProfesionalDto(
    id: p.id,
    nombres: p.nombres,
    apellidos: p.apellidos,
    especialidadId: p.especialidadId,
    colegiatura: p.colegiatura,
  );
}
