import '../entities/intencion_asistente.dart';
import 'resultado_regla.dart';

/// **RN-02** — El registro exige validar el numero de documento de identidad,
/// que es el identificador unico del paciente.
///
/// Se admiten dos tipos:
///
/// - **DNI**: exactamente 8 digitos. Es el documento de identidad peruano.
/// - **Carne de extranjeria (CE)**: entre 9 y 12 caracteres alfanumericos.
///   El formato ha variado entre emisiones, por eso se valida por longitud y
///   juego de caracteres en lugar de exigir una mascara rigida.
///
/// La regla NO calcula digito verificador: el DNI peruano lo tiene, pero su
/// algoritmo no es publico ni estable, y rechazar documentos validos por esa
/// via dejaria fuera a pacientes reales. La verificacion definitiva es
/// competencia del backend contra RENIEC/Migraciones.
class Rn02DocumentoIdentidad {
  const Rn02DocumentoIdentidad._();

  static const String codigo = 'RN-02';

  static final RegExp _soloDigitos = RegExp(r'^\d+$');
  static final RegExp _alfanumerico = RegExp(r'^[A-Za-z0-9]+$');

  static const int longitudDni = 8;
  static const int longitudMinimaCe = 9;
  static const int longitudMaximaCe = 12;

  /// Normaliza antes de validar: quita espacios y guiones, y pasa a
  /// mayusculas. Un paciente que escribe "12 345 678" no deberia ver un
  /// error de formato.
  static String normalizar(String valor) =>
      valor.replaceAll(RegExp(r'[\s\-.]'), '').toUpperCase();

  static ResultadoRegla validar({
    required TipoDocumento tipo,
    required String numero,
  }) {
    final limpio = normalizar(numero);

    if (limpio.isEmpty) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ingresa tu numero de documento.',
        campo: 'numeroDocumento',
      );
    }

    return switch (tipo) {
      TipoDocumento.dni => _validarDni(limpio),
      TipoDocumento.carneExtranjeria => _validarCarneExtranjeria(limpio),
      // Las cuentas de administracion no se registran desde la aplicacion.
      TipoDocumento.usuario => const ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Las cuentas de usuario no se registran desde la '
            'aplicacion.',
        campo: 'numeroDocumento',
      ),
    };
  }

  static ResultadoRegla _validarDni(String numero) {
    if (!_soloDigitos.hasMatch(numero)) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'El DNI solo puede contener numeros.',
        campo: 'numeroDocumento',
      );
    }
    if (numero.length != longitudDni) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'El DNI debe tener $longitudDni digitos.',
        campo: 'numeroDocumento',
      );
    }
    // Un documento con todos los digitos iguales (00000000, 11111111) no
    // existe; es el relleno tipico de las pruebas.
    if (numero.split('').toSet().length == 1) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'El numero de DNI no es valido.',
        campo: 'numeroDocumento',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  static ResultadoRegla _validarCarneExtranjeria(String numero) {
    if (!_alfanumerico.hasMatch(numero)) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'El carne de extranjeria solo admite letras y numeros.',
        campo: 'numeroDocumento',
      );
    }
    if (numero.length < longitudMinimaCe || numero.length > longitudMaximaCe) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje:
            'El carne de extranjeria debe tener entre '
            '$longitudMinimaCe y $longitudMaximaCe caracteres.',
        campo: 'numeroDocumento',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }
}
