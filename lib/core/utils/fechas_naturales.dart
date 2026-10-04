import '../../domain/entities/intencion_asistente.dart';

/// Resultado de interpretar una expresion de fecha en lenguaje natural.
class FechaInterpretada {
  const FechaInterpretada({
    required this.fecha,
    required this.expresionOriginal,
    this.turno,
    this.hora,
  });

  /// Fecha concreta resuelta, sin hora.
  final DateTime fecha;

  /// Texto tal como lo escribio el paciente («el lunes», «manana»).
  final String expresionOriginal;

  final TurnoDia? turno;

  /// Hora concreta, si el paciente la indico («a las 10», «10:30»).
  final Duration? hora;

  /// Fecha y hora combinadas. Si no hay hora, se usa el inicio del turno, y
  /// si tampoco hay turno, el inicio del dia.
  DateTime get fechaHora {
    if (hora != null) return fecha.add(hora!);
    return switch (turno) {
      TurnoDia.manana => fecha.add(const Duration(hours: 8)),
      TurnoDia.tarde => fecha.add(const Duration(hours: 14)),
      null => fecha,
    };
  }

  @override
  String toString() => 'FechaInterpretada($fecha, turno: $turno, hora: $hora)';
}

/// Normalizacion de fechas en espanol del lado del cliente.
///
/// El motor conversacional devuelve la entidad de fecha tal como la escribio
/// el paciente («manana», «el lunes»); resolverla a una fecha concreta es
/// responsabilidad de la aplicacion, que conoce el dia de hoy del dispositivo.
///
/// **La fecha resuelta siempre se muestra al paciente para que la confirme.**
/// Ninguna interpretacion se da por buena en silencio: es la diferencia entre
/// equivocarse y equivocarse sin que nadie se entere.
class FechasNaturales {
  const FechasNaturales._();

  static const Map<String, int> _diasSemana = <String, int>{
    'lunes': DateTime.monday,
    'martes': DateTime.tuesday,
    'miercoles': DateTime.wednesday,
    'jueves': DateTime.thursday,
    'viernes': DateTime.friday,
    'sabado': DateTime.saturday,
    'domingo': DateTime.sunday,
  };

  static const Map<String, int> _meses = <String, int>{
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'setiembre': 9,
    'septiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
  };

  /// Minusculas y sin tildes.
  static String normalizar(String texto) {
    const conTilde = 'áéíóúàèìòùäëïöüâêîôûñ';
    const sinTilde = 'aeiouaeiouaeiouaeioun';
    var resultado = texto.toLowerCase().trim();
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  /// Interpreta [texto] respecto de [ahora]. Devuelve `null` si no reconoce
  /// ninguna expresion de fecha: en ese caso el asistente debe preguntar en
  /// lugar de inventarse un dia.
  static FechaInterpretada? interpretar(
    String texto, {
    required DateTime ahora,
  }) {
    final t = normalizar(texto);
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final turno = detectarTurno(t);
    final hora = detectarHora(t);

    DateTime? fecha;
    String expresion = texto.trim();

    // «manana» es ambigua: puede ser el dia siguiente o el turno del dia.
    // Se retiran primero las apariciones que son claramente turno («por la
    // manana», «en la manana»), y solo si queda alguna suelta se interpreta
    // como dia. Sin esto, «el viernes por la manana» se resolveria como el
    // dia de manana en lugar de como el viernes.
    final sinTurno = t
        .replaceAll(RegExp(r'(por|en|de|a)\s+la\s+manana'), ' ')
        .replaceAll(RegExp(r'la\s+manana'), ' ');

    // ---- Expresiones relativas ----
    if (_contiene(t, 'pasado manana')) {
      fecha = hoy.add(const Duration(days: 2));
      expresion = 'pasado manana';
    } else if (_contiene(sinTurno, 'manana')) {
      fecha = hoy.add(const Duration(days: 1));
      expresion = 'manana';
    } else if (_contiene(t, 'hoy')) {
      fecha = hoy;
      expresion = 'hoy';
    }

    // ---- Dia de la semana ----
    if (fecha == null) {
      for (final entrada in _diasSemana.entries) {
        if (!_contiene(t, entrada.key)) continue;

        final proximaSemana =
            _contiene(t, 'proxima semana') ||
            _contiene(t, 'siguiente semana') ||
            _contiene(t, 'que viene');

        fecha = _proximoDiaSemana(
          desde: hoy,
          diaSemana: entrada.value,
          saltarUnaSemana: proximaSemana,
        );
        expresion = entrada.key;
        break;
      }
    }

    // ---- «la proxima semana» sin dia concreto: el lunes siguiente ----
    if (fecha == null &&
        (_contiene(t, 'proxima semana') ||
            _contiene(t, 'siguiente semana') ||
            _contiene(t, 'semana que viene'))) {
      fecha = _proximoDiaSemana(
        desde: hoy,
        diaSemana: DateTime.monday,
        saltarUnaSemana: false,
      );
      expresion = 'la proxima semana';
    }

    // ---- «en N dias» ----
    if (fecha == null) {
      final enDias = RegExp(r'en (\d{1,2}) dias?').firstMatch(t);
      if (enDias != null) {
        final dias = int.parse(enDias.group(1)!);
        fecha = hoy.add(Duration(days: dias));
        expresion = enDias.group(0)!;
      }
    }

    // ---- Fecha explicita: «el 20 de octubre», «20/10» ----
    if (fecha == null) {
      fecha = _fechaExplicita(t, hoy: hoy);
      if (fecha != null) expresion = texto.trim();
    }

    if (fecha == null) return null;

    return FechaInterpretada(
      fecha: fecha,
      expresionOriginal: expresion,
      turno: turno,
      hora: hora,
    );
  }

  /// Turno del dia. «manana» solo cuenta como turno si va precedida de una
  /// preposicion («por la manana», «en la manana»); suelta, es el dia
  /// siguiente.
  static TurnoDia? detectarTurno(String textoNormalizado) {
    final t = textoNormalizado;
    if (_contiene(t, 'por la manana') ||
        _contiene(t, 'en la manana') ||
        _contiene(t, 'de la manana') ||
        _contiene(t, 'temprano')) {
      return TurnoDia.manana;
    }
    if (_contiene(t, 'tarde') || _contiene(t, 'mediodia')) {
      return TurnoDia.tarde;
    }
    return null;
  }

  /// Hora concreta: «a las 10», «10:30», «3 pm».
  static Duration? detectarHora(String textoNormalizado) {
    final t = textoNormalizado;

    final conMinutos = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(t);
    if (conMinutos != null) {
      final h = int.parse(conMinutos.group(1)!);
      final m = int.parse(conMinutos.group(2)!);
      if (h < 24 && m < 60) {
        return Duration(hours: _ajustarPorSufijo(h, t), minutes: m);
      }
    }

    final aLas = RegExp(r'a la?s? (\d{1,2})(?![:.\d])').firstMatch(t);
    if (aLas != null) {
      final h = int.parse(aLas.group(1)!);
      if (h < 24) return Duration(hours: _ajustarPorSufijo(h, t));
    }

    return null;
  }

  /// Convierte a 24 h cuando el texto dice «pm» o «de la tarde».
  static int _ajustarPorSufijo(int hora, String texto) {
    final esTarde =
        _contiene(texto, 'pm') ||
        _contiene(texto, 'de la tarde') ||
        _contiene(texto, 'por la tarde') ||
        _contiene(texto, 'de la noche');
    if (esTarde && hora < 12) return hora + 12;
    return hora;
  }

  /// Proximo [diaSemana] estrictamente posterior a [desde].
  ///
  /// «el lunes» dicho un lunes significa el lunes siguiente, no hoy: si el
  /// paciente quisiera hoy, diria «hoy».
  static DateTime _proximoDiaSemana({
    required DateTime desde,
    required int diaSemana,
    required bool saltarUnaSemana,
  }) {
    var dias = (diaSemana - desde.weekday + 7) % 7;
    if (dias == 0) dias = 7;
    if (saltarUnaSemana) dias += 7;
    return desde.add(Duration(days: dias));
  }

  /// «20 de octubre», «20/10», «20-10-2026».
  static DateTime? _fechaExplicita(String t, {required DateTime hoy}) {
    final conMes = RegExp(r'(\d{1,2}) de ([a-z]+)').firstMatch(t);
    if (conMes != null) {
      final dia = int.parse(conMes.group(1)!);
      final mes = _meses[conMes.group(2)!];
      if (mes != null && dia >= 1 && dia <= 31) {
        final candidata = DateTime(hoy.year, mes, dia);
        // Si la fecha ya paso este ano, se entiende que habla del proximo.
        return candidata.isBefore(hoy)
            ? DateTime(hoy.year + 1, mes, dia)
            : candidata;
      }
    }

    final numerica = RegExp(r'(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?')
        .firstMatch(t);
    if (numerica != null) {
      final dia = int.parse(numerica.group(1)!);
      final mes = int.parse(numerica.group(2)!);
      if (dia < 1 || dia > 31 || mes < 1 || mes > 12) return null;

      final anioTexto = numerica.group(3);
      if (anioTexto != null) {
        var anio = int.parse(anioTexto);
        if (anio < 100) anio += 2000;
        return DateTime(anio, mes, dia);
      }

      final candidata = DateTime(hoy.year, mes, dia);
      return candidata.isBefore(hoy)
          ? DateTime(hoy.year + 1, mes, dia)
          : candidata;
    }

    return null;
  }

  static bool _contiene(String texto, String termino) {
    if (termino.contains(' ')) return texto.contains(termino);
    final patron = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(termino)}([^a-z0-9]|\$)',
    );
    return patron.hasMatch(texto);
  }
}
