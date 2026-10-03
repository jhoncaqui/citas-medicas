import '../../domain/entities/consultorio.dart';
import '../../domain/entities/sede.dart';

class SedeDto {
  const SedeDto({
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
  final String? referencia;

  factory SedeDto.fromJson(Map<String, dynamic> json) => SedeDto(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    direccion: (json['direccion'] as String?) ?? '',
    latitud: (json['latitud'] as num).toDouble(),
    longitud: (json['longitud'] as num).toDouble(),
    referencia: json['referencia'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'direccion': direccion,
    'latitud': latitud,
    'longitud': longitud,
    'referencia': referencia,
  };

  Sede aDominio() => Sede(
    id: id,
    nombre: nombre,
    direccion: direccion,
    latitud: latitud,
    longitud: longitud,
    referencia: referencia,
  );

  factory SedeDto.desdeDominio(Sede s) => SedeDto(
    id: s.id,
    nombre: s.nombre,
    direccion: s.direccion,
    latitud: s.latitud,
    longitud: s.longitud,
    referencia: s.referencia,
  );
}

class ConsultorioDto {
  const ConsultorioDto({
    required this.id,
    required this.sedeId,
    required this.codigo,
    required this.piso,
  });

  final String id;
  final String sedeId;
  final String codigo;
  final int piso;

  factory ConsultorioDto.fromJson(Map<String, dynamic> json) => ConsultorioDto(
    id: json['id'] as String,
    sedeId: json['sedeId'] as String,
    codigo: json['codigo'] as String,
    piso: (json['piso'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sedeId': sedeId,
    'codigo': codigo,
    'piso': piso,
  };

  Consultorio aDominio() =>
      Consultorio(id: id, sedeId: sedeId, codigo: codigo, piso: piso);

  factory ConsultorioDto.desdeDominio(Consultorio c) => ConsultorioDto(
    id: c.id,
    sedeId: c.sedeId,
    codigo: c.codigo,
    piso: c.piso,
  );
}
