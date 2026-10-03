import 'intencion_asistente.dart';
import 'rol_usuario.dart';

/// Titular de los datos y de las citas.
///
/// RN-10: el tratamiento de datos exige consentimiento informado previo,
/// otorgado en el registro y revocable desde la aplicacion (HU-12). Por eso
/// [consentimientoOtorgado] y [fechaConsentimiento] viven en la entidad y no
/// en una preferencia suelta.
class Paciente {
  const Paciente({
    required this.id,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.telefono,
    this.consentimientoOtorgado = false,
    this.fechaConsentimiento,
    this.rol = RolUsuario.paciente,
  });

  final String id;
  final TipoDocumento tipoDocumento;

  /// Identificador unico del paciente (RN-02).
  final String numeroDocumento;

  final String nombres;
  final String apellidos;
  final String correo;
  final String telefono;

  /// RN-10 / HU-12.
  final bool consentimientoOtorgado;
  final DateTime? fechaConsentimiento;

  /// Papel de la cuenta. Por defecto `paciente`: el rol con menos privilegios.
  final RolUsuario rol;

  bool get esAdministrador => rol == RolUsuario.administrador;

  String get nombreCompleto => '$nombres $apellidos';

  /// Iniciales para el avatar, sin exponer el nombre completo.
  String get iniciales {
    final n = nombres.trim().isEmpty ? '' : nombres.trim()[0];
    final a = apellidos.trim().isEmpty ? '' : apellidos.trim()[0];
    return '$n$a'.toUpperCase();
  }

  Paciente copyWith({
    String? id,
    TipoDocumento? tipoDocumento,
    String? numeroDocumento,
    String? nombres,
    String? apellidos,
    String? correo,
    String? telefono,
    bool? consentimientoOtorgado,
    DateTime? fechaConsentimiento,
    RolUsuario? rol,
    bool limpiarFechaConsentimiento = false,
  }) => Paciente(
    id: id ?? this.id,
    tipoDocumento: tipoDocumento ?? this.tipoDocumento,
    numeroDocumento: numeroDocumento ?? this.numeroDocumento,
    nombres: nombres ?? this.nombres,
    apellidos: apellidos ?? this.apellidos,
    correo: correo ?? this.correo,
    telefono: telefono ?? this.telefono,
    consentimientoOtorgado:
        consentimientoOtorgado ?? this.consentimientoOtorgado,
    fechaConsentimiento: limpiarFechaConsentimiento
        ? null
        : (fechaConsentimiento ?? this.fechaConsentimiento),
    rol: rol ?? this.rol,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Paciente &&
          other.id == id &&
          other.tipoDocumento == tipoDocumento &&
          other.numeroDocumento == numeroDocumento &&
          other.nombres == nombres &&
          other.apellidos == apellidos &&
          other.correo == correo &&
          other.telefono == telefono &&
          other.consentimientoOtorgado == consentimientoOtorgado &&
          other.fechaConsentimiento == fechaConsentimiento &&
          other.rol == rol;

  @override
  int get hashCode => Object.hash(
    id,
    tipoDocumento,
    numeroDocumento,
    nombres,
    apellidos,
    correo,
    telefono,
    consentimientoOtorgado,
    fechaConsentimiento,
    rol,
  );

  @override
  String toString() => 'Paciente($id, $tipoDocumento $numeroDocumento)';
}
