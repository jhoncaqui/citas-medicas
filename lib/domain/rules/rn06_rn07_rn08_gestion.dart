import '../../core/config/app_config.dart';
import '../entities/cita.dart';
import '../entities/estado_cita.dart';
import 'resultado_regla.dart';

/// Operaciones de autogestion que RN-06 limita en el tiempo.
enum AccionAutogestion {
  cancelar('cancelar'),
  reprogramar('reprogramar');

  const AccionAutogestion(this.verbo);
  final String verbo;
}

/// **RN-06** — La cancelacion o reprogramacion autogestionada se admite hasta
/// N horas antes del inicio.
///
/// **N no esta fijado en duro**: sale de
/// [AppConfig.horasMinimasParaAutogestion], pendiente de la entrevista al
/// personal de admision. La regla recibe el valor como parametro para que los
/// tests puedan comprobar el comportamiento con cualquier plazo, no solo con
/// el marcador de trabajo actual.
class Rn06Autogestion {
  const Rn06Autogestion._();

  static const String codigo = 'RN-06';

  static ResultadoRegla validar({
    required Cita cita,
    required AccionAutogestion accion,
    required DateTime ahora,
    int? horasMinimas,
  }) {
    final n = horasMinimas ?? AppConfig.horasMinimasParaAutogestion;

    // Una cita que ya no esta activa no se gestiona: no es cuestion de plazo.
    if (!cita.estado.esActiva) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Esta cita esta ${cita.estado.etiqueta.toLowerCase()} y ya no '
            'se puede ${accion.verbo}.',
      );
    }

    final inicio = cita.fechaHoraInicio;
    if (inicio == null) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje: 'No se pudo determinar la fecha de la cita.',
      );
    }

    if (!inicio.isAfter(ahora)) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje: 'La hora de la cita ya paso. Comunicate con la clinica.',
      );
    }

    final horasRestantes = inicio.difference(ahora).inMinutes / 60;
    if (horasRestantes < n) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Solo puedes ${accion.verbo} tu cita hasta $n horas antes. '
            'Comunicate con la clinica para gestionarla.',
      );
    }

    return const ResultadoRegla.valida(codigo);
  }

  /// Conveniencia para la interfaz: si el boton debe estar habilitado.
  static bool sePuede({
    required Cita cita,
    required AccionAutogestion accion,
    required DateTime ahora,
    int? horasMinimas,
  }) => validar(
    cita: cita,
    accion: accion,
    ahora: ahora,
    horasMinimas: horasMinimas,
  ).cumple;
}

/// **RN-07** — Se emite un recordatorio automatico con M horas de antelacion.
///
/// **M tampoco esta fijado en duro**: sale de
/// [AppConfig.horasAntelacionRecordatorio].
class Rn07Recordatorio {
  const Rn07Recordatorio._();

  static const String codigo = 'RN-07';

  /// Momento en que debe dispararse el recordatorio de [cita].
  ///
  /// Devuelve `null` si la cita no admite recordatorio: no esta activa, no
  /// tiene fecha, o el momento de aviso ya paso.
  static DateTime? momentoDeAviso({
    required Cita cita,
    required DateTime ahora,
    int? horasAntelacion,
  }) {
    if (!cita.estado.esActiva) return null;

    final inicio = cita.fechaHoraInicio;
    if (inicio == null) return null;

    final m = horasAntelacion ?? AppConfig.horasAntelacionRecordatorio;
    final aviso = inicio.subtract(Duration(hours: m));

    // Si el momento de aviso ya paso, no se programa nada: un recordatorio
    // que llega tarde es peor que ninguno.
    if (!aviso.isAfter(ahora)) return null;

    return aviso;
  }

  static ResultadoRegla validar({
    required Cita cita,
    required DateTime ahora,
    int? horasAntelacion,
  }) {
    final aviso = momentoDeAviso(
      cita: cita,
      ahora: ahora,
      horasAntelacion: horasAntelacion,
    );
    if (aviso == null) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Esta cita no admite recordatorio automatico.',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }
}

/// **RN-08** — Una cita confirmada sin atencion registrada se marca como
/// inasistencia y alimenta el indicador correspondiente.
///
/// El margen tras la hora de la cita sale de
/// [AppConfig.horasParaMarcarInasistencia], tambien pendiente de confirmar.
///
/// El cambio de estado lo hace el backend, que es quien sabe si hubo
/// atencion. Esta regla existe en el cliente para que el historial pueda
/// mostrar el estado correcto sin esperar a la siguiente sincronizacion.
class Rn08Inasistencia {
  const Rn08Inasistencia._();

  static const String codigo = 'RN-08';

  /// `true` si la cita debe considerarse inasistencia.
  static bool debeMarcarse({
    required Cita cita,
    required DateTime ahora,
    int? horasMargen,
  }) {
    if (cita.estado != EstadoCita.confirmada &&
        cita.estado != EstadoCita.reprogramada) {
      return false;
    }

    // Si hay atencion registrada, no hay inasistencia.
    if (cita.fechaAtencion != null) return false;

    final inicio = cita.fechaHoraInicio;
    if (inicio == null) return false;

    final margen = horasMargen ?? AppConfig.horasParaMarcarInasistencia;
    return ahora.isAfter(inicio.add(Duration(hours: margen)));
  }

  /// Devuelve la cita con el estado corregido, o la misma si no procede.
  static Cita aplicar({
    required Cita cita,
    required DateTime ahora,
    int? horasMargen,
  }) {
    if (!debeMarcarse(cita: cita, ahora: ahora, horasMargen: horasMargen)) {
      return cita;
    }
    return cita.copyWith(estado: EstadoCita.inasistencia);
  }

  /// Proporcion de inasistencias sobre las citas que ya pasaron (HU-11).
  ///
  /// Devuelve `null` si no hay citas pasadas: una proporcion sobre cero no
  /// significa nada y mostrar «0 %» seria enganoso.
  static double? proporcion(List<Cita> citas) {
    final pasadas = citas
        .where(
          (c) =>
              c.estado == EstadoCita.atendida ||
              c.estado == EstadoCita.inasistencia,
        )
        .toList();

    if (pasadas.isEmpty) return null;

    final inasistencias = pasadas
        .where((c) => c.estado == EstadoCita.inasistencia)
        .length;
    return inasistencias / pasadas.length;
  }
}
