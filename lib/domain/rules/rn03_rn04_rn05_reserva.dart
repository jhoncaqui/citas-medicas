import '../entities/cita.dart';
import '../entities/cupo_disponible.dart';
import 'resultado_regla.dart';

/// **RN-03** — Un cupo solo puede estar asignado a una cita activa a la vez.
/// La confirmacion bloquea el cupo de forma inmediata.
///
/// La comprobacion del cliente es una primera barrera que evita enviar al
/// backend una reserva condenada a fallar y, sobre todo, permite avisar al
/// paciente en el acto (HU-05: «el cupo que se ocupa durante la sesion»). La
/// garantia real es del backend, que es quien serializa las reservas.
class Rn03CupoUnico {
  const Rn03CupoUnico._();

  static const String codigo = 'RN-03';

  static ResultadoRegla validar({
    required CupoDisponible cupo,
    required List<Cita> citasDelSistema,
  }) {
    if (!cupo.disponible) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ese horario acaba de ocuparse. Elige otro, por favor.',
      );
    }

    final ocupado = citasDelSistema.any(
      (c) => c.cupoId == cupo.id && c.estado.esActiva,
    );
    if (ocupado) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Ese horario acaba de ocuparse. Elige otro, por favor.',
      );
    }

    return const ResultadoRegla.valida(codigo);
  }
}

/// **RN-04** — No se admiten reservas en fechas u horarios anteriores al
/// momento de la solicitud.
///
/// [ahora] se recibe como parametro en lugar de leer el reloj del sistema,
/// para que la regla sea pura y comprobable.
class Rn04NoEnElPasado {
  const Rn04NoEnElPasado._();

  static const String codigo = 'RN-04';

  /// Margen minimo entre la solicitud y el inicio de la cita.
  ///
  /// Un cupo que empieza dentro de dos minutos es tecnicamente futuro, pero
  /// no es reservable en la practica: el paciente no llega. El margen evita
  /// ofrecer horarios inutiles.
  static const Duration margenMinimo = Duration(minutes: 15);

  static ResultadoRegla validar({
    required DateTime fechaHoraInicio,
    required DateTime ahora,
  }) {
    if (!fechaHoraInicio.isAfter(ahora)) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'No se pueden reservar horarios que ya pasaron.',
        campo: 'fecha',
      );
    }

    if (fechaHoraInicio.difference(ahora) < margenMinimo) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Ese horario esta demasiado proximo. Elige uno con al menos '
            '${margenMinimo.inMinutes} minutos de anticipacion.',
        campo: 'fecha',
      );
    }

    return const ResultadoRegla.valida(codigo);
  }

  /// Filtra una lista de cupos dejando solo los reservables.
  static List<CupoDisponible> filtrar(
    List<CupoDisponible> cupos, {
    required DateTime ahora,
  }) => cupos
      .where(
        (c) => validar(fechaHoraInicio: c.fechaHoraInicio, ahora: ahora).cumple,
      )
      .toList();
}

/// **RN-05** — Un paciente no puede tener mas de una cita activa con la misma
/// especialidad y el mismo profesional en la misma fecha.
///
/// Se compara solo la parte de fecha: dos citas el mismo dia con el mismo
/// profesional infringen la regla aunque sean a horas distintas.
class Rn05SinDuplicados {
  const Rn05SinDuplicados._();

  static const String codigo = 'RN-05';

  static ResultadoRegla validar({
    required String especialidadId,
    required String profesionalId,
    required DateTime fechaHoraInicio,
    required List<Cita> citasDelPaciente,
  }) {
    final fecha = _soloFecha(fechaHoraInicio);

    final duplicada = citasDelPaciente.any((c) {
      if (!c.estado.esActiva) return false;
      if (c.especialidadId != especialidadId) return false;
      if (c.profesionalId != profesionalId) return false;
      final inicio = c.fechaHoraInicio;
      if (inicio == null) return false;
      return _soloFecha(inicio) == fecha;
    });

    if (duplicada) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Ya tienes una cita ese dia con ese profesional para la '
            'misma especialidad.',
      );
    }

    return const ResultadoRegla.valida(codigo);
  }

  static DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);
}
