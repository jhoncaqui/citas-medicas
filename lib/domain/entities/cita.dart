import 'estado_cita.dart';
import 'intencion_asistente.dart';

/// Reserva de un cupo por parte de un paciente.
class Cita {
  const Cita({
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
  final EstadoCita estado;
  final DateTime fechaCreacion;

  /// Momento en que se registro la atencion. Si sigue nulo pasada la hora de
  /// la cita, RN-08 la marca como inasistencia.
  final DateTime? fechaAtencion;

  final CanalReserva canalReserva;

  /// RNF-07: identifica el intento de reserva para que un reintento tras una
  /// caida de red no genere una cita duplicada.
  final String? claveIdempotencia;

  // Datos denormalizados del cupo. Permiten mostrar el comprobante y el
  // historial sin conexion (HU-09) sin tener que resolver cada referencia.
  final String? especialidadId;
  final String? profesionalId;
  final String? sedeId;
  final String? consultorioId;
  final DateTime? fechaHoraInicio;

  bool get esActiva => estado.esActiva;

  Cita copyWith({
    String? id,
    String? pacienteId,
    String? cupoId,
    EstadoCita? estado,
    DateTime? fechaCreacion,
    DateTime? fechaAtencion,
    CanalReserva? canalReserva,
    String? claveIdempotencia,
    String? especialidadId,
    String? profesionalId,
    String? sedeId,
    String? consultorioId,
    DateTime? fechaHoraInicio,
    bool limpiarFechaAtencion = false,
  }) => Cita(
    id: id ?? this.id,
    pacienteId: pacienteId ?? this.pacienteId,
    cupoId: cupoId ?? this.cupoId,
    estado: estado ?? this.estado,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    fechaAtencion: limpiarFechaAtencion
        ? null
        : (fechaAtencion ?? this.fechaAtencion),
    canalReserva: canalReserva ?? this.canalReserva,
    claveIdempotencia: claveIdempotencia ?? this.claveIdempotencia,
    especialidadId: especialidadId ?? this.especialidadId,
    profesionalId: profesionalId ?? this.profesionalId,
    sedeId: sedeId ?? this.sedeId,
    consultorioId: consultorioId ?? this.consultorioId,
    fechaHoraInicio: fechaHoraInicio ?? this.fechaHoraInicio,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cita &&
          other.id == id &&
          other.pacienteId == pacienteId &&
          other.cupoId == cupoId &&
          other.estado == estado &&
          other.fechaCreacion == fechaCreacion &&
          other.fechaAtencion == fechaAtencion &&
          other.canalReserva == canalReserva &&
          other.claveIdempotencia == claveIdempotencia &&
          other.especialidadId == especialidadId &&
          other.profesionalId == profesionalId &&
          other.sedeId == sedeId &&
          other.consultorioId == consultorioId &&
          other.fechaHoraInicio == fechaHoraInicio;

  @override
  int get hashCode => Object.hash(
    id,
    pacienteId,
    cupoId,
    estado,
    fechaCreacion,
    fechaAtencion,
    canalReserva,
    claveIdempotencia,
    especialidadId,
    profesionalId,
    sedeId,
    consultorioId,
    fechaHoraInicio,
  );

  @override
  String toString() => 'Cita($id, ${estado.clave}, $fechaHoraInicio)';
}
