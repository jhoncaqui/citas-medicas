import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/rol_usuario.dart';

/// DTO del paciente.
///
/// Ojo con lo que NO esta aqui: la clave. Nunca viaja de vuelta desde el
/// backend ni se persiste en el dispositivo junto al perfil.
class PacienteDto {
  const PacienteDto({
    required this.id,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.telefono,
    required this.consentimientoOtorgado,
    this.fechaConsentimiento,
    this.rol = 'paciente',
  });

  final String id;
  final String tipoDocumento;
  final String numeroDocumento;
  final String nombres;
  final String apellidos;
  final String correo;
  final String telefono;
  final bool consentimientoOtorgado;

  /// ISO 8601 con zona horaria, segun la convencion del backend.
  final String? fechaConsentimiento;

  /// Clave de [RolUsuario]. Las cuentas guardadas antes de que existieran los
  /// roles no traen este campo y se leen como `paciente`.
  final String rol;

  factory PacienteDto.fromJson(Map<String, dynamic> json) => PacienteDto(
    id: json['id'] as String,
    tipoDocumento: (json['tipoDocumento'] as String?) ?? 'DNI',
    numeroDocumento: json['numeroDocumento'] as String,
    nombres: json['nombres'] as String,
    apellidos: json['apellidos'] as String,
    correo: (json['correo'] as String?) ?? '',
    telefono: (json['telefono'] as String?) ?? '',
    consentimientoOtorgado: (json['consentimientoOtorgado'] as bool?) ?? false,
    fechaConsentimiento: json['fechaConsentimiento'] as String?,
    rol: (json['rol'] as String?) ?? 'paciente',
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tipoDocumento': tipoDocumento,
    'numeroDocumento': numeroDocumento,
    'nombres': nombres,
    'apellidos': apellidos,
    'correo': correo,
    'telefono': telefono,
    'consentimientoOtorgado': consentimientoOtorgado,
    'fechaConsentimiento': fechaConsentimiento,
    'rol': rol,
  };

  Paciente aDominio() => Paciente(
    id: id,
    tipoDocumento: TipoDocumento.desdeClave(tipoDocumento),
    numeroDocumento: numeroDocumento,
    nombres: nombres,
    apellidos: apellidos,
    correo: correo,
    telefono: telefono,
    consentimientoOtorgado: consentimientoOtorgado,
    fechaConsentimiento: fechaConsentimiento == null
        ? null
        : DateTime.tryParse(fechaConsentimiento!),
    rol: RolUsuario.desdeClave(rol),
  );

  factory PacienteDto.desdeDominio(Paciente p) => PacienteDto(
    id: p.id,
    tipoDocumento: p.tipoDocumento.clave,
    numeroDocumento: p.numeroDocumento,
    nombres: p.nombres,
    apellidos: p.apellidos,
    correo: p.correo,
    telefono: p.telefono,
    consentimientoOtorgado: p.consentimientoOtorgado,
    fechaConsentimiento: p.fechaConsentimiento?.toIso8601String(),
    rol: p.rol.clave,
  );
}

/// Respuesta de registro e inicio de sesion: perfil mas token.
class SesionDto {
  const SesionDto({required this.paciente, required this.token});

  final PacienteDto paciente;

  /// Va a `Authorization: Bearer` y se guarda en el almacen seguro.
  final String token;

  factory SesionDto.fromJson(Map<String, dynamic> json) => SesionDto(
    paciente: PacienteDto.fromJson(json['paciente'] as Map<String, dynamic>),
    token: json['token'] as String,
  );
}
