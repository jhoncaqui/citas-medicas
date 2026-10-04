/// Intenciones que el motor Rasa puede devolver para un mensaje del paciente.
enum IntencionAsistente {
  reservar('reservar'),
  consultar('consultar'),
  reprogramar('reprogramar'),
  cancelar('cancelar'),
  noReconocida('no_reconocida');

  const IntencionAsistente(this.clave);

  /// Valor tal como lo emite Rasa.
  final String clave;

  /// Solo las intenciones reconocidas disparan una accion.
  bool get esAccionable => this != IntencionAsistente.noReconocida;

  static IntencionAsistente desdeClave(String? clave) =>
      IntencionAsistente.values.firstWhere(
        (i) => i.clave == clave,
        orElse: () => IntencionAsistente.noReconocida,
      );
}

/// Turno del dia, extraido del lenguaje natural ("en la manana", "por la tarde").
enum TurnoDia {
  manana('manana', 'Manana'),
  tarde('tarde', 'Tarde');

  const TurnoDia(this.clave, this.etiqueta);

  final String clave;
  final String etiqueta;

  static TurnoDia? desdeClave(String? clave) {
    if (clave == null) return null;
    for (final t in TurnoDia.values) {
      if (t.clave == clave) return t;
    }
    return null;
  }
}

/// Rol de quien emite un mensaje de la conversacion.
enum RolMensaje {
  paciente('paciente'),
  asistente('asistente');

  const RolMensaje(this.clave);
  final String clave;

  static RolMensaje desdeClave(String clave) => RolMensaje.values.firstWhere(
    (r) => r.clave == clave,
    orElse: () => throw ArgumentError('Rol de mensaje desconocido: $clave'),
  );
}

/// Canal por el que se origino una reserva. Alimenta el indicador de
/// «proporcion de reservas autogestionadas» (HU-11).
enum CanalReserva {
  conversacional('conversacional', 'Asistente'),
  flujoGuiado('flujo_guiado', 'Flujo guiado'),
  presencial('presencial', 'Presencial'),
  telefonico('telefonico', 'Telefonico');

  const CanalReserva(this.clave, this.etiqueta);

  final String clave;
  final String etiqueta;

  /// El paciente la gestiono por si mismo desde la aplicacion.
  bool get esAutogestionada =>
      this == CanalReserva.conversacional || this == CanalReserva.flujoGuiado;

  static CanalReserva desdeClave(String clave) =>
      CanalReserva.values.firstWhere(
        (c) => c.clave == clave,
        orElse: () =>
            throw ArgumentError('Canal de reserva desconocido: $clave'),
      );
}

/// Tipo de documento de identidad admitido (RN-02).
enum TipoDocumento {
  dni('DNI', 'DNI'),
  carneExtranjeria('CE', 'Carne de extranjeria'),

  /// Identificador de las cuentas de administracion. No es un documento de
  /// identidad y **no se ofrece en el registro**: esas cuentas no las crea el
  /// propio interesado desde la aplicacion.
  usuario('USR', 'Usuario');

  const TipoDocumento(this.clave, this.etiqueta);

  final String clave;
  final String etiqueta;

  /// Tipos que un paciente puede elegir al registrarse.
  static const List<TipoDocumento> registrables = <TipoDocumento>[
    TipoDocumento.dni,
    TipoDocumento.carneExtranjeria,
  ];

  static TipoDocumento desdeClave(String clave) =>
      TipoDocumento.values.firstWhere(
        (t) => t.clave == clave,
        orElse: () =>
            throw ArgumentError('Tipo de documento desconocido: $clave'),
      );
}
