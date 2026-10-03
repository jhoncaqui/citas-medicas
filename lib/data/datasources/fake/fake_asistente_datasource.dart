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
// La confianza que emite es una heuristica, no una probabilidad: cuenta
// cuantas senales del mensaje encajan con la intencion. Se comporta como la
// de un modelo real frente al umbral de `AppConfig.umbralConfianza`, que es
// lo que la aplicacion necesita poder probar.
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

  static const Map<IntencionAsistente, List<String>> _patrones =
      <IntencionAsistente, List<String>>{
        IntencionAsistente.reservar: <String>[
          'reservar',
          'reserva',
          'sacar cita',
          'sacar una cita',
          'agendar',
          'agenda',
          'quiero una cita',
          'necesito una cita',
          'pedir cita',
          'pedir una cita',
          'separar',
          'programar',
          'nueva cita',
          'quiero cita',
        ],
        IntencionAsistente.consultar: <String>[
          'consultar',
          'ver mis citas',
          'mis citas',
          'que citas tengo',
          'cuando es mi cita',
          'cuando tengo',
          'revisar mi cita',
          'tengo alguna cita',
          'mi proxima cita',
        ],
        IntencionAsistente.reprogramar: <String>[
          'reprogramar',
          'reprograma',
          'cambiar mi cita',
          'cambiar la cita',
          'cambiar de fecha',
          'mover mi cita',
          'mover la cita',
          'posponer',
          'otro dia',
          'otra fecha',
        ],
        IntencionAsistente.cancelar: <String>[
          'cancelar',
          'cancela',
          'anular',
          'ya no quiero',
          'ya no podre',
          'dar de baja mi cita',
          'eliminar mi cita',
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

    final (intencion, aciertos) = _clasificar(normalizado);

    if (intencion == IntencionAsistente.noReconocida) {
      return const RespuestaAsistenteDto(
        intencion: 'no_reconocida',
        confianza: 0.0,
        respuesta: Cadenas.asistenteNoEntendi,
      );
    }

    return RespuestaAsistenteDto(
      intencion: intencion.clave,
      confianza: _confianza(aciertos: aciertos, entidades: entidades),
      respuesta: '',
      entidades: entidades,
    );
  }

  // -------------------------------------------------------------------

  static (IntencionAsistente, int) _clasificar(String normalizado) {
    var mejor = IntencionAsistente.noReconocida;
    var mejorAciertos = 0;

    for (final entrada in _patrones.entries) {
      final aciertos = entrada.value
          .where((p) => normalizado.contains(p))
          .length;
      if (aciertos > mejorAciertos) {
        mejorAciertos = aciertos;
        mejor = entrada.key;
      }
    }
    return (mejor, mejorAciertos);
  }

  /// Heuristica de confianza.
  ///
  /// Parte de 0.55 con una sola senal —por debajo del umbral de 0.70, de modo
  /// que «reservar» a secas pide precision en lugar de actuar— y sube con
  /// cada senal adicional: mas patrones coincidentes o entidades extraidas.
  static double _confianza({
    required int aciertos,
    required Map<String, String> entidades,
  }) {
    var valor = 0.55 + (aciertos - 1) * 0.10;
    if (entidades.containsKey('especialidad')) valor += 0.15;
    if (entidades.containsKey('fecha')) valor += 0.10;
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
    // sintoma (RN-09).
    for (final especialidad in Fixtures.especialidades) {
      if (!especialidad.activa) continue;
      final nombre = FechasNaturales.normalizar(especialidad.nombre);
      if (normalizado.contains(nombre)) {
        entidades['especialidad'] = especialidad.id;
        break;
      }
    }

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
}
