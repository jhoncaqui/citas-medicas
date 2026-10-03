import '../../domain/entities/cita.dart';
import '../../domain/entities/cupo_disponible.dart';
import '../../domain/entities/estado_cita.dart';
import '../../domain/entities/intencion_asistente.dart';

class CupoDto {
  const CupoDto({
    required this.id,
    required this.profesionalId,
    required this.sedeId,
    required this.consultorioId,
    required this.fechaHoraInicio,
    required this.duracionMinutos,
    required this.disponible,
  });

  final String id;
  final String profesionalId;
  final String sedeId;
  final String consultorioId;

  /// ISO 8601 con zona horaria.
  final String fechaHoraInicio;

  final int duracionMinutos;
  final bool disponible;

  factory CupoDto.fromJson(Map<String, dynamic> json) => CupoDto(
    id: json['id'] as String,
    profesionalId: json['profesionalId'] as String,
    sedeId: json['sedeId'] as String,
    consultorioId: json['consultorioId'] as String,
    fechaHoraInicio: json['fechaHoraInicio'] as String,
    duracionMinutos: (json['duracionMinutos'] as num?)?.toInt() ?? 30,
    disponible: (json['disponible'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'profesionalId': profesionalId,
    'sedeId': sedeId,
    'consultorioId': consultorioId,
    'fechaHoraInicio': fechaHoraInicio,
    'duracionMinutos': duracionMinutos,
    'disponible': disponible,
  };

  CupoDisponible aDominio() => CupoDisponible(
    id: id,
    profesionalId: profesionalId,
    sedeId: sedeId,
    consultorioId: consultorioId,
    fechaHoraInicio: DateTime.parse(fechaHoraInicio),
    duracionMinutos: duracionMinutos,
    disponible: disponible,
  );

  factory CupoDto.desdeDominio(CupoDisponible c) => CupoDto(
    id: c.id,
    profesionalId: c.profesionalId,
    sedeId: c.sedeId,
    consultorioId: c.consultorioId,
    fechaHoraInicio: c.fechaHoraInicio.toIso8601String(),
    duracionMinutos: c.duracionMinutos,
    disponible: c.disponible,
  );
}

class CitaDto {
  const CitaDto({
    required this.id,
    required this.pacienteId,
    required this.cupoId,
    required this.estado,
    required this.fechaCreacion,
    required this.canalReserva,
    this.fechaAtencion,
    this.claveIdempotencia,
    this.especialidadId,
    this.profesionalId,
    this.sedeId,
    this.consultorioId,
    this.fechaHoraInicio,
  });

  final String id;
  final String pacienteId;
  final String cupoId;
  final String estado;
  final String fechaCreacion;
  final String canalReserva;
  final String? fechaAtencion;
  final String? claveIdempotencia;
  final String? especialidadId;
  final String? profesionalId;
  final String? sedeId;
  final String? consultorioId;
  final String? fechaHoraInicio;

  factory CitaDto.fromJson(Map<String, dynamic> json) => CitaDto(
    id: json['id'] as String,
    pacienteId: json['pacienteId'] as String,
    cupoId: json['cupoId'] as String,
    estado: json['estado'] as String,
    fechaCreacion: json['fechaCreacion'] as String,
    canalReserva: (json['canalReserva'] as String?) ?? 'conversacional',
    fechaAtencion: json['fechaAtencion'] as String?,
    claveIdempotencia: json['claveIdempotencia'] as String?,
    especialidadId: json['especialidadId'] as String?,
    profesionalId: json['profesionalId'] as String?,
    sedeId: json['sedeId'] as String?,
    consultorioId: json['consultorioId'] as String?,
    fechaHoraInicio: json['fechaHoraInicio'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'pacienteId': pacienteId,
    'cupoId': cupoId,
    'estado': estado,
    'fechaCreacion': fechaCreacion,
    'canalReserva': canalReserva,
    'fechaAtencion': fechaAtencion,
    'claveIdempotencia': claveIdempotencia,
    'especialidadId': especialidadId,
    'profesionalId': profesionalId,
    'sedeId': sedeId,
    'consultorioId': consultorioId,
    'fechaHoraInicio': fechaHoraInicio,
  };

  Cita aDominio() => Cita(
    id: id,
    pacienteId: pacienteId,
    cupoId: cupoId,
    estado: EstadoCita.desdeClave(estado),
    fechaCreacion: DateTime.parse(fechaCreacion),
    canalReserva: CanalReserva.desdeClave(canalReserva),
    fechaAtencion: fechaAtencion == null
        ? null
        : DateTime.tryParse(fechaAtencion!),
    claveIdempotencia: claveIdempotencia,
    especialidadId: especialidadId,
    profesionalId: profesionalId,
    sedeId: sedeId,
    consultorioId: consultorioId,
    fechaHoraInicio: fechaHoraInicio == null
        ? null
        : DateTime.tryParse(fechaHoraInicio!),
  );

  factory CitaDto.desdeDominio(Cita c) => CitaDto(
    id: c.id,
    pacienteId: c.pacienteId,
    cupoId: c.cupoId,
    estado: c.estado.clave,
    fechaCreacion: c.fechaCreacion.toIso8601String(),
    canalReserva: c.canalReserva.clave,
    fechaAtencion: c.fechaAtencion?.toIso8601String(),
    claveIdempotencia: c.claveIdempotencia,
    especialidadId: c.especialidadId,
    profesionalId: c.profesionalId,
    sedeId: c.sedeId,
    consultorioId: c.consultorioId,
    fechaHoraInicio: c.fechaHoraInicio?.toIso8601String(),
  );
}
