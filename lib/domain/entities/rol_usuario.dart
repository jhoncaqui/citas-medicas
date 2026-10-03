/// Papel de una cuenta dentro de la aplicacion.
///
/// La distincion existe porque el panel de indicadores (HU-11) es para el
/// personal de admision y no para los pacientes, y porque RN-01 reserva las
/// operaciones sobre citas a «un paciente registrado y autenticado».
enum RolUsuario {
  paciente('paciente'),
  administrador('administrador');

  const RolUsuario(this.clave);

  /// Valor que viaja por la API y se guarda en el almacen.
  final String clave;

  /// Una clave desconocida cae en `paciente`, el rol con menos privilegios:
  /// ante un valor inesperado nunca se concede acceso de administracion.
  static RolUsuario desdeClave(String? clave) => RolUsuario.values.firstWhere(
    (r) => r.clave == clave,
    orElse: () => RolUsuario.paciente,
  );
}
