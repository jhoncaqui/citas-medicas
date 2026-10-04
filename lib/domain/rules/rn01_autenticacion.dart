import '../entities/paciente.dart';
import 'resultado_regla.dart';

/// Operaciones sobre citas que RN-01 protege.
enum OperacionProtegida {
  reservar('reservar una cita'),
  reprogramar('reprogramar una cita'),
  cancelar('cancelar una cita'),
  consultarHistorial('consultar tu historial'),

  /// Panel de indicadores (HU-11): solo para el personal de administracion.
  verIndicadores('ver los indicadores', soloAdministracion: true),

  /// Gestion del catalogo (altas, ediciones y bajas de especialidades y
  /// profesionales): solo para el personal de administracion.
  gestionarCatalogo('gestionar el catalogo', soloAdministracion: true);

  const OperacionProtegida(this.descripcion, {this.soloAdministracion = false});

  final String descripcion;

  /// `true` si la operacion es exclusiva de las cuentas de administracion.
  /// Las demas son operaciones de paciente.
  final bool soloAdministracion;
}

/// **RN-01** — Solo un paciente registrado y autenticado puede reservar,
/// reprogramar o cancelar una cita.
///
/// La regla vive en el dominio, no en el router: proteger unicamente la
/// navegacion dejaria la puerta abierta a que un ViewModel invocase la
/// operacion por otra via. Toda operacion protegida la consulta antes de
/// tocar el repositorio.
///
/// **Roles.** Reservar, reprogramar, cancelar y consultar el historial son
/// operaciones *de paciente*: una cuenta de administracion no las hace, tanto
/// porque el enunciado de la regla habla de «un paciente» como porque una
/// reserva hecha por el personal distorsionaria los propios indicadores. Ver
/// los indicadores es la operacion inversa: solo administracion.
class Rn01Autenticacion {
  const Rn01Autenticacion._();

  static const String codigo = 'RN-01';

  /// [pacienteAutenticado] es `null` cuando no hay sesion activa.
  static ResultadoRegla validar({
    required Paciente? pacienteAutenticado,
    required OperacionProtegida operacion,
  }) {
    if (pacienteAutenticado == null) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje: 'Inicia sesion para ${operacion.descripcion}.',
      );
    }

    if (operacion.soloAdministracion) {
      if (!pacienteAutenticado.esAdministrador) {
        return const ResultadoRegla.infringe(
          codigo,
          mensaje: 'Esta seccion es solo para el personal de administracion.',
        );
      }
      return const ResultadoRegla.valida(codigo);
    }

    if (pacienteAutenticado.esAdministrador) {
      return ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Las cuentas de administracion no pueden '
            '${operacion.descripcion}.',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  /// Comprueba ademas que la operacion recae sobre datos del propio paciente.
  ///
  /// Un paciente autenticado no puede gestionar la cita de otro: sin esta
  /// comprobacion, RN-01 se cumpliria formalmente mientras se manipulan datos
  /// ajenos.
  static ResultadoRegla validarTitularidad({
    required Paciente? pacienteAutenticado,
    required String pacienteIdDelRecurso,
    required OperacionProtegida operacion,
  }) {
    final base = validar(
      pacienteAutenticado: pacienteAutenticado,
      operacion: operacion,
    );
    if (base.infringida) return base;

    if (pacienteAutenticado!.id != pacienteIdDelRecurso) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'No puedes gestionar una cita que no te pertenece.',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }
}
