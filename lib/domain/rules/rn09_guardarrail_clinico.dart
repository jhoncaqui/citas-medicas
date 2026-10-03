import 'resultado_regla.dart';

/// **RN-09** — El asistente no formula diagnosticos ni recomienda
/// especialidades con criterio clinico; deriva al canal de atencion.
///
/// La deteccion es deliberadamente **amplia**: ante la duda, deriva. El coste
/// de derivar de mas es que el paciente use el flujo guiado por menus; el
/// coste de no derivar es que la aplicacion parezca orientar clinicamente,
/// que es lo que la regla prohibe.
///
/// Esta comprobacion vive en el cliente y se ejecuta **antes** de enviar el
/// texto al motor conversacional, de modo que la regla se cumple aunque el
/// modelo de Rasa no este entrenado para ello.
class Rn09GuardarrailClinico {
  const Rn09GuardarrailClinico._();

  static const String codigo = 'RN-09';

  /// Terminos que denotan un sintoma o una dolencia.
  ///
  /// No es una lista clinica: es una lista de palabras que, cuando aparecen
  /// en el mensaje de un paciente, indican que esta describiendo como se
  /// siente en lugar de gestionar una cita.
  static const List<String> _sintomas = <String>[
    'dolor',
    'duele',
    'dolencia',
    'molestia',
    'malestar',
    'fiebre',
    'temperatura',
    'escalofrio',
    'tos',
    'gripe',
    'resfriado',
    'catarro',
    'mareo',
    'mareado',
    'vertigo',
    'desmayo',
    'nausea',
    'vomito',
    'vomitar',
    'diarrea',
    'estrenimiento',
    'sangrado',
    'sangre',
    'herida',
    'golpe',
    'fractura',
    'ardor',
    'arde',
    'ardiendo',
    'picazon',
    'comezon',
    'sarpullido',
    'roncha',
    'erupcion',
    'orinar',
    'hinchazon',
    'inflamacion',
    'inflamado',
    'ahogo',
    'falta de aire',
    'respirar',
    'palpitacion',
    'presion alta',
    'presion baja',
    'cansancio',
    'fatiga',
    'debilidad',
    'insomnio',
    'ansiedad',
    'depresion',
    'angustia',
    'sintoma',
    'sintomas',
    'enfermo',
    'enferma',
    'siento mal',
    'me siento',
    'tengo malestar',
  ];

  /// Frases con las que se pide orientacion clinica de forma explicita.
  static const List<String> _peticionesDeOrientacion = <String>[
    'que tengo',
    'que me pasa',
    'sera grave',
    'es grave',
    'que especialista',
    'que especialidad me',
    'a que especialista',
    'con quien me atiendo',
    'con que doctor debo',
    'que doctor necesito',
    'que me recomiendas',
    'que recomiendas',
    'me recomiendas',
    'que debo tomar',
    'que medicamento',
    'que pastilla',
    'es normal que',
    'diagnostico',
    'diagnosticar',
    'necesito un especialista para',
  ];

  /// `true` si el mensaje pide orientacion clinica y debe derivarse.
  static bool requiereDerivacion(String texto) => evaluar(texto).infringida;

  static ResultadoRegla evaluar(String texto) {
    final normalizado = normalizar(texto);

    for (final frase in _peticionesDeOrientacion) {
      if (normalizado.contains(frase)) {
        return const ResultadoRegla.infringe(
          codigo,
          mensaje: 'El mensaje pide orientacion clinica.',
        );
      }
    }

    for (final sintoma in _sintomas) {
      if (_contienePalabra(normalizado, sintoma)) {
        return const ResultadoRegla.infringe(
          codigo,
          mensaje: 'El mensaje describe un sintoma.',
        );
      }
    }

    return const ResultadoRegla.valida(codigo);
  }

  /// Minusculas y sin tildes, para que «dolor de cabeza» y «DOLOR» se
  /// detecten igual.
  static String normalizar(String texto) {
    const conTilde = 'áéíóúàèìòùäëïöüâêîôûñ';
    const sinTilde = 'aeiouaeiouaeiouaeioun';

    var resultado = texto.toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  /// Busca el termino como palabra completa cuando es una sola palabra, para
  /// que «tos» no dispare dentro de «todos» ni «gripe» dentro de otra cosa.
  static bool _contienePalabra(String texto, String termino) {
    if (termino.contains(' ')) return texto.contains(termino);
    final patron = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(termino)}([^a-z0-9]|\$)',
    );
    return patron.hasMatch(texto);
  }
}
