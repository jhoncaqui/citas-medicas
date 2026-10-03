import 'resultado_regla.dart';

/// Validaciones del formulario de registro (HU-01) que no corresponden a una
/// regla RN numerada, pero sin las cuales el registro no es utilizable.
///
/// Se mantienen aqui, en el dominio y como funciones puras, para que la
/// pantalla no cargue con logica de validacion.
class ValidacionesRegistro {
  const ValidacionesRegistro._();

  static const String codigo = 'VAL';

  /// Longitud minima de la clave.
  ///
  /// Se prioriza la longitud sobre la exigencia de simbolos: las reglas de
  /// composicion empujan a los usuarios hacia claves predecibles y anotadas
  /// en papel, que es justo lo contrario de lo que buscamos.
  static const int longitudMinimaClave = 8;

  static final RegExp _correo = RegExp(
    r'^[\w.!#$%&*+/=?^`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$',
  );

  /// Telefono movil peruano: 9 digitos que empiezan por 9.
  static final RegExp _telefono = RegExp(r'^9\d{8}$');

  static ResultadoRegla validarNombres(String valor) {
    final limpio = valor.trim();
    if (limpio.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tus nombres.',
        campo: 'nombres',
      );
    }
    if (limpio.length < 2) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tus nombres completos.',
        campo: 'nombres',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  static ResultadoRegla validarApellidos(String valor) {
    final limpio = valor.trim();
    if (limpio.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tus apellidos.',
        campo: 'apellidos',
      );
    }
    if (limpio.length < 2) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tus apellidos completos.',
        campo: 'apellidos',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  static ResultadoRegla validarCorreo(String valor) {
    final limpio = valor.trim().toLowerCase();
    if (limpio.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tu correo electronico.',
        campo: 'correo',
      );
    }
    if (!_correo.hasMatch(limpio)) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'El correo electronico no tiene un formato valido.',
        campo: 'correo',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  static ResultadoRegla validarTelefono(String valor) {
    final limpio = valor.replaceAll(RegExp(r'[\s\-()]'), '');
    if (limpio.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tu numero de celular.',
        campo: 'telefono',
      );
    }
    if (!_telefono.hasMatch(limpio)) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'El celular debe tener 9 digitos y empezar con 9.',
        campo: 'telefono',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  static ResultadoRegla validarClave(String valor) {
    if (valor.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa una contrasena.',
        campo: 'clave',
      );
    }
    if (valor.length < longitudMinimaClave) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje:
            'La contrasena debe tener al menos '
            '$longitudMinimaClave caracteres.',
        campo: 'clave',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  static ResultadoRegla validarConfirmacionClave({
    required String clave,
    required String confirmacion,
  }) {
    if (confirmacion.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Repite la contrasena.',
        campo: 'confirmacionClave',
      );
    }
    if (clave != confirmacion) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Las contrasenas no coinciden.',
        campo: 'confirmacionClave',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  /// Normaliza el correo antes de guardarlo o compararlo.
  static String normalizarCorreo(String valor) => valor.trim().toLowerCase();

  /// Normaliza el telefono quitando separadores.
  static String normalizarTelefono(String valor) =>
      valor.replaceAll(RegExp(r'[\s\-()]'), '');
}
