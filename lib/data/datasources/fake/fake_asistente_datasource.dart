// =====================================================================
// RECONOCEDOR LOCAL DE INTENCIONES — SUSTITUYE A RASA MIENTRAS NO ESTE
// DESPLEGADO
// =====================================================================
//
// Resuelve las intenciones con expresiones regulares sobre el texto y
// devuelve EXACTAMENTE la misma estructura que devolvera Rasa
// ([RespuestaAsistenteDto]). El resto de la aplicacion no debe notar la
// diferencia.
//
// La confianza que emite es una heuristica, no una probabilidad. Separa dos
// tipos de senal:
//
//   - FUERTES: frases inequivocas y completas («quiero una cita», «ver mis
//     citas»). Por si solas bastan para actuar: el asistente reconoce la
//     intencion y pide los datos que falten.
//   - DEBILES: verbos sueltos o palabras ambiguas («reservar», «cita»,
//     «cambiar»). Sugieren la intencion pero necesitan corroborarse con otra
//     senal o con una entidad concreta antes de pasar del umbral.
//
// Asi «quiero una cita» avanza —que es lo que un paciente espera— mientras
// que «reservar» a secas sigue pidiendo precision.
// =====================================================================

import '../../../core/config/app_config.dart';
import '../../../core/utils/fechas_naturales.dart';
import '../../../domain/entities/intencion_asistente.dart';
import '../../../domain/rules/rn09_guardarrail_clinico.dart';
import '../../../l10n/cadenas.dart';
import '../../models/asistente_dto.dart';
import '../remote/asistente_remote_datasource.dart';
import 'fixtures.dart';

class FakeAsistenteDataSource implements AsistenteDataSource {
  const FakeAsistenteDataSource({
    this.latencia = AppConfig.latenciaSimulada,
    this.ahora,
  });

  final Duration latencia;

  /// Reloj inyectable, para que los tests sean deterministas.
  final DateTime Function()? ahora;

  // -------------------------------------------------------------------
  // Patrones por intencion
  // -------------------------------------------------------------------

  /// Frases inequivocas: identifican la intencion con confianza suficiente
  /// para actuar. Se evitan expresiones que sean subcadena de otra intencion
  /// (p. ej. «una cita» a secas) para no confundir «cancelar una cita» con
  /// «reservar».
  static const Map<IntencionAsistente, List<String>> _patronesFuertes =
      <IntencionAsistente, List<String>>{
        IntencionAsistente.reservar: <String>[
          'quiero una cita',
          'quiero cita',
          'quiero agendar',
          'quiero reservar',
          'quiero sacar una cita',
          'quiero pedir una cita',
          'quiero separar una cita',
          'necesito una cita',
          'necesito cita',
          'necesito agendar',
          'necesito reservar',
          'quisiera una cita',
          'quisiera cita',
          'quisiera agendar',
          'quisiera reservar',
          'deseo una cita',
          'deseo agendar',
          'me gustaria una cita',
          'me gustaria agendar',
          'me gustaria sacar una cita',
          'reservar una cita',
          'reservar cita',
          'agendar una cita',
          'agendar cita',
          'sacar una cita',
          'sacar cita',
          'pedir una cita',
          'pedir cita',
          'solicitar una cita',
          'solicitar cita',
          'separar una cita',
          'nueva cita',
          'sacar un turno',
          'sacar turno',
          'pedir un turno',
          'pedir turno',
          'agendar turno',
        ],
        IntencionAsistente.consultar: <String>[
          'ver mis citas',
          'ver mi cita',
          'mis citas',
          'que citas tengo',
          'que cita tengo',
          'cuando es mi cita',
          'cuando tengo mi cita',
          'cuando tengo cita',
          'revisar mi cita',
          'revisar mis citas',
          'tengo alguna cita',
          'mi proxima cita',
          'consultar mis citas',
          'consultar mi cita',
        ],
        IntencionAsistente.reprogramar: <String>[
          'reprogramar mi cita',
          'reprogramar la cita',
          'reagendar mi cita',
          'cambiar mi cita',
          'cambiar la cita',
          'cambiar de fecha',
          'cambiar la fecha',
          'cambiar de dia',
          'cambiar la hora',
          'cambiar mi hora',
          'mover mi cita',
          'mover la cita',
          'posponer mi cita',
          'posponer la cita',
          'pasar mi cita para otro dia',
        ],
        IntencionAsistente.cancelar: <String>[
          'cancelar mi cita',
          'cancelar la cita',
          'quiero cancelar',
          'necesito cancelar',
          'anular mi cita',
          'anular la cita',
          'dar de baja mi cita',
          'eliminar mi cita',
          'ya no quiero la cita',
          'ya no quiero mi cita',
        ],
      };

  /// Senales debiles: verbos sueltos o palabras ambiguas. Suman, pero por si
  /// solas no superan el umbral.
  static const Map<IntencionAsistente, List<String>> _patronesDebiles =
      <IntencionAsistente, List<String>>{
        IntencionAsistente.reservar: <String>[
          'reservar',
          'reserva',
          'agendar',
          'agenda',
          'separar',
          'programar',
          'cita',
          'turno',
        ],
        IntencionAsistente.consultar: <String>[
          'consultar',
          'revisar',
          'proxima cita',
          'mis reservas',
        ],
        IntencionAsistente.reprogramar: <String>[
          'reprogramar',
          'reprograma',
          'reagendar',
          'mover',
          'posponer',
          'otro dia',
          'otra fecha',
          'cambiar',
        ],
        IntencionAsistente.cancelar: <String>[
          'cancelar',
          'cancela',
          'anular',
          'ya no quiero',
          'ya no podre',
          'ya no puedo',
          'no podre ir',
          'no puedo ir',
        ],
      };

  @override
  Future<RespuestaAsistenteDto> analizarMensaje({
    required String texto,
    required String idConversacion,
  }) async {
    await Future<void>.delayed(latencia);
    return analizar(texto, ahora: ahora?.call() ?? DateTime.now());
  }

  /// Version sincrona y con reloj explicito, para los tests.
  static RespuestaAsistenteDto analizar(
    String texto, {
    required DateTime ahora,
  }) {
    // RN-09 primero: si el mensaje pide orientacion clinica se deriva sin
    // intentar siquiera clasificar la intencion, y sin sugerir especialidad.
    if (Rn09GuardarrailClinico.requiereDerivacion(texto)) {
      return const RespuestaAsistenteDto(
        intencion: 'no_reconocida',
        confianza: 1.0,
        respuesta: Cadenas.derivacionCanalAtencion,
        derivadoACanalAtencion: true,
      );
    }

    final normalizado = FechasNaturales.normalizar(texto);
    final entidades = _extraerEntidades(normalizado, texto, ahora: ahora);

    final (intencion, fuertes, debiles) = _clasificar(normalizado);

    if (intencion == IntencionAsistente.noReconocida) {
      // Se devuelven las entidades aunque no se reconozca la intencion: en una
      // conversacion en curso, «medicina general» o «manana» no traen ningun
      // verbo de intencion pero SI son la respuesta a lo que el asistente
      // acaba de preguntar. El ViewModel las usa para seguir el relleno.
      return RespuestaAsistenteDto(
        intencion: 'no_reconocida',
        confianza: 0.0,
        respuesta: Cadenas.asistenteNoEntendi,
        entidades: entidades,
      );
    }

    return RespuestaAsistenteDto(
      intencion: intencion.clave,
      confianza: _confianza(
        fuertes: fuertes,
        debiles: debiles,
        entidades: entidades,
      ),
      respuesta: '',
      entidades: entidades,
    );
  }

  // -------------------------------------------------------------------

  /// Elige la intencion con mas senales. Una senal fuerte pesa mucho mas que
  /// una debil (factor 10), de modo que cualquier frase inequivoca gana a un
  /// puñado de palabras sueltas de otra intencion.
  static (IntencionAsistente, int, int) _clasificar(String normalizado) {
    var mejor = IntencionAsistente.noReconocida;
    var mejorFuertes = 0;
    var mejorDebiles = 0;
    var mejorPuntaje = 0;

    for (final intencion in _patronesFuertes.keys) {
      final fuertes = (_patronesFuertes[intencion] ?? const <String>[])
          .where(normalizado.contains)
          .length;
      final debiles = (_patronesDebiles[intencion] ?? const <String>[])
          .where(normalizado.contains)
          .length;
      final puntaje = fuertes * 10 + debiles;
      if (puntaje > mejorPuntaje) {
        mejorPuntaje = puntaje;
        mejorFuertes = fuertes;
        mejorDebiles = debiles;
        mejor = intencion;
      }
    }
    return (mejor, mejorFuertes, mejorDebiles);
  }

  /// Heuristica de confianza.
  ///
  /// Una frase fuerte parte de 0.80 —por encima del umbral de 0.70, para que
  /// «quiero una cita» avance a pedir los datos que falten—. Las señales
  /// debiles parten de 0.55 y necesitan sumar otra senal o una entidad para
  /// cruzar el umbral, de modo que «reservar» a secas siga pidiendo precision.
  static double _confianza({
    required int fuertes,
    required int debiles,
    required Map<String, String> entidades,
  }) {
    var valor = fuertes > 0
        ? 0.80 + (fuertes - 1) * 0.05
        : 0.55 + (debiles - 1) * 0.10;
    if (entidades.containsKey('especialidad')) valor += 0.10;
    if (entidades.containsKey('fecha')) valor += 0.05;
    if (entidades.containsKey('turno') || entidades.containsKey('hora')) {
      valor += 0.05;
    }
    return valor.clamp(0.0, 0.99);
  }

  static Map<String, String> _extraerEntidades(
    String normalizado,
    String original, {
    required DateTime ahora,
  }) {
    final entidades = <String, String>{};

    // Especialidad: se busca por nombre en el catalogo, nunca se deduce del
    // sintoma (RN-09). Tolera sinonimos de campo/profesion y errores de
    // tecleo.
    final especialidadId = _extraerEspecialidad(normalizado);
    if (especialidadId != null) entidades['especialidad'] = especialidadId;

    // Profesional, por apellido o nombre completo.
    for (final profesional in Fixtures.profesionales) {
      final nombre = FechasNaturales.normalizar(profesional.nombreCompleto);
      final apellidos = FechasNaturales.normalizar(profesional.apellidos);
      if (normalizado.contains(nombre) ||
          (apellidos.isNotEmpty &&
              normalizado.contains(nombre.split(' ').first))) {
        entidades['profesional'] = profesional.id;
        break;
      }
    }

    final fecha = FechasNaturales.interpretar(original, ahora: ahora);
    if (fecha != null) {
      entidades['fecha'] = fecha.fecha.toIso8601String();
      entidades['fecha_expresion'] = fecha.expresionOriginal;
      if (fecha.turno != null) entidades['turno'] = fecha.turno!.clave;
      if (fecha.hora != null) {
        entidades['hora'] =
            '${fecha.hora!.inHours}:'
            '${(fecha.hora!.inMinutes % 60).toString().padLeft(2, '0')}';
      }
    } else {
      final turno = FechasNaturales.detectarTurno(normalizado);
      if (turno != null) entidades['turno'] = turno.clave;
    }

    return entidades;
  }

  // -------------------------------------------------------------------
  // Reconocimiento tolerante de especialidades
  // -------------------------------------------------------------------

  /// Sinonimos de campo o de profesion (nunca sintomas ni partes del cuerpo:
  /// RN-09 prohibe deducir la especialidad de un criterio clinico). Las claves
  /// son el nombre normalizado de la especialidad.
  static const Map<String, List<String>> _sinonimosEspecialidad =
      <String, List<String>>{
        'medicina general': <String>['general', 'clinica general'],
        'pediatria': <String>['pediatra', 'pediatrico', 'pediatrica'],
        'cardiologia': <String>['cardio', 'cardiologo', 'cardiologa'],
        'dermatologia': <String>['dermatologo', 'dermatologa'],
      };

  static const Set<String> _palabrasVacias = <String>{
    'de', 'del', 'la', 'el', 'los', 'las', 'y', 'con', 'para', 'una', 'un',
  };

  /// Busca una especialidad activa en el texto. Tres pasadas, de la mas
  /// estricta a la mas tolerante: nombre completo, palabra clave o sinonimo, y
  /// por ultimo un token casi identico a una clave (un typo). Nunca deduce la
  /// especialidad de un sintoma.
  static String? _extraerEspecialidad(String normalizado) {
    // 1) Nombre completo como subcadena ("medicina general").
    for (final e in Fixtures.especialidades) {
      if (!e.activa) continue;
      if (normalizado.contains(FechasNaturales.normalizar(e.nombre))) {
        return e.id;
      }
    }
    // 2) Palabra clave del nombre o sinonimo, como palabra completa.
    for (final e in Fixtures.especialidades) {
      if (!e.activa) continue;
      for (final clave in _clavesEspecialidad(e.nombre)) {
        if (_contienePalabra(normalizado, clave)) return e.id;
      }
    }
    // 3) Tolerancia a un error de tecleo: token casi igual a una clave.
    final tokens = normalizado
        .split(RegExp('[^a-z0-9]+'))
        .where((t) => t.length >= 5)
        .toList();
    for (final e in Fixtures.especialidades) {
      if (!e.activa) continue;
      for (final clave in _clavesEspecialidad(e.nombre)) {
        if (clave.length < 5) continue;
        for (final token in tokens) {
          if (_distanciaEdicion(token, clave) <= 1) return e.id;
        }
      }
    }
    return null;
  }

  static List<String> _clavesEspecialidad(String nombre) {
    final normal = FechasNaturales.normalizar(nombre);
    final claves = <String>{};
    for (final palabra in normal.split(' ')) {
      if (palabra.length >= 4 && !_palabrasVacias.contains(palabra)) {
        claves.add(palabra);
      }
    }
    claves.addAll(_sinonimosEspecialidad[normal] ?? const <String>[]);
    return claves.toList();
  }

  static bool _contienePalabra(String texto, String palabra) {
    if (palabra.contains(' ')) return texto.contains(palabra);
    return RegExp('\\b${RegExp.escape(palabra)}\\b').hasMatch(texto);
  }

  /// Distancia de Levenshtein, acotada: con mas de dos caracteres de
  /// diferencia de longitud no vale la pena calcularla.
  static int _distanciaEdicion(String a, String b) {
    if ((a.length - b.length).abs() > 2) return 3;
    final fila = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      var previo = fila[0];
      fila[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final tmp = fila[j];
        final costo = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final borrar = fila[j] + 1;
        final insertar = fila[j - 1] + 1;
        final sustituir = previo + costo;
        fila[j] = borrar < insertar
            ? (borrar < sustituir ? borrar : sustituir)
            : (insertar < sustituir ? insertar : sustituir);
        previo = tmp;
      }
    }
    return fila[b.length];
  }
}
