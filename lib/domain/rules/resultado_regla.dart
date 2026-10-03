/// Veredicto de una regla de negocio.
///
/// Las reglas RN-01 a RN-10 se implementan como funciones puras que devuelven
/// este tipo: no lanzan excepciones, no tocan red ni almacenamiento y no
/// dependen del reloj del sistema salvo que reciban el instante como
/// parametro. Eso las hace comprobables con tests unitarios deterministas.
class ResultadoRegla {
  const ResultadoRegla._({
    required this.cumple,
    required this.regla,
    this.mensaje,
    this.campo,
  });

  /// La regla se cumple: la operacion puede continuar.
  const ResultadoRegla.valida(String regla)
    : this._(cumple: true, regla: regla);

  /// La regla se infringe. [mensaje] es el texto que se muestra al paciente.
  const ResultadoRegla.infringe(
    String regla, {
    required String mensaje,
    String? campo,
  }) : this._(cumple: false, regla: regla, mensaje: mensaje, campo: campo);

  final bool cumple;

  /// Codigo de la regla, por ejemplo `RN-02`.
  final String regla;

  /// Solo cuando [cumple] es `false`.
  final String? mensaje;

  /// Campo del formulario al que apunta el fallo, si aplica.
  final String? campo;

  bool get infringida => !cumple;

  @override
  String toString() => cumple
      ? 'ResultadoRegla($regla: cumple)'
      : 'ResultadoRegla($regla: $mensaje)';
}

/// Devuelve el primer veredicto infringido, o el ultimo si todos cumplen.
///
/// Permite encadenar varias reglas y quedarse con el primer motivo real de
/// rechazo, que es el que tiene sentido mostrar al paciente.
ResultadoRegla primeraInfraccion(List<ResultadoRegla> veredictos) {
  assert(veredictos.isNotEmpty, 'Se necesita al menos un veredicto');
  for (final v in veredictos) {
    if (v.infringida) return v;
  }
  return veredictos.last;
}
