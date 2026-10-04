/// Estados por los que puede pasar una cita.
enum EstadoCita {
  pendiente('pendiente', 'Pendiente'),
  confirmada('confirmada', 'Confirmada'),
  reprogramada('reprogramada', 'Reprogramada'),
  cancelada('cancelada', 'Cancelada'),
  atendida('atendida', 'Atendida'),
  inasistencia('inasistencia', 'Inasistencia');

  const EstadoCita(this.clave, this.etiqueta);

  /// Valor que viaja por la API y se guarda en sqflite.
  final String clave;

  /// Texto mostrado al paciente.
  final String etiqueta;

  /// Una cita activa ocupa un cupo y puede gestionarse (RN-03, RN-05).
  bool get esActiva =>
      this == EstadoCita.pendiente ||
      this == EstadoCita.confirmada ||
      this == EstadoCita.reprogramada;

  /// Estados terminales: ya no admiten reprogramacion ni cancelacion.
  bool get esTerminal => !esActiva;

  static EstadoCita desdeClave(String clave) => EstadoCita.values.firstWhere(
    (e) => e.clave == clave,
    orElse: () => throw ArgumentError('Estado de cita desconocido: $clave'),
  );
}
