import '../entities/paciente.dart';
import 'resultado_regla.dart';

/// **RN-10** — El tratamiento de datos requiere consentimiento informado
/// previo, otorgado en el registro y revocable desde la aplicacion (HU-12).
///
/// Dos consecuencias que la implementacion respeta:
///
/// 1. **Previo**: sin consentimiento no se completa el registro. No se acepta
///    un registro "a medias" que quede pendiente de aceptar despues.
/// 2. **Revocable**: revocar no puede ser mas dificil que otorgar. La
///    aplicacion no pide motivo, no interpone pasos disuasorios y no vuelve a
///    solicitarlo despues (seccion 11: sin patrones oscuros).
class Rn10Consentimiento {
  const Rn10Consentimiento._();

  static const String codigo = 'RN-10';

  /// Se invoca antes de enviar el registro (HU-01).
  static ResultadoRegla validarParaRegistro({required bool aceptado}) {
    if (!aceptado) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'Debes aceptar el tratamiento de tus datos para registrarte.',
        campo: 'consentimiento',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  /// Se invoca antes de cualquier operacion que trate datos del paciente.
  ///
  /// Si el consentimiento fue revocado, la aplicacion deja de operar con sus
  /// datos aunque la sesion siga tecnicamente abierta.
  static ResultadoRegla validarVigente({required Paciente? paciente}) {
    if (paciente == null) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje: 'No hay una sesion activa.',
      );
    }
    if (!paciente.consentimientoOtorgado) {
      return const ResultadoRegla.infringe(
        codigo,
        mensaje:
            'Revocaste el consentimiento para el tratamiento de tus '
            'datos. Para volver a reservar necesitas otorgarlo de nuevo.',
      );
    }
    return const ResultadoRegla.valida(codigo);
  }

  /// Marca el consentimiento como otorgado dejando constancia del momento.
  ///
  /// [ahora] se recibe como parametro en lugar de leer el reloj, para que la
  /// funcion sea pura y comprobable.
  static Paciente otorgar(Paciente paciente, {required DateTime ahora}) =>
      paciente.copyWith(
        consentimientoOtorgado: true,
        fechaConsentimiento: ahora,
      );

  /// Revoca el consentimiento y borra la fecha: no se conserva rastro del
  /// consentimiento anterior en el perfil local.
  static Paciente revocar(Paciente paciente) => paciente.copyWith(
    consentimientoOtorgado: false,
    limpiarFechaConsentimiento: true,
  );
}
