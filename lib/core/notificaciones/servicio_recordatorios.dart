import 'package:flutter/foundation.dart';

import '../../domain/entities/cita.dart';
import '../../domain/repositories/preferencias_repository.dart';
import '../../domain/rules/rn06_rn07_rn08_gestion.dart';
import '../utils/formato_fecha.dart';

/// Recordatorio programado para una cita.
class RecordatorioProgramado {
  const RecordatorioProgramado({
    required this.citaId,
    required this.momento,
    required this.titulo,
    required this.cuerpo,
  });

  final String citaId;
  final DateTime momento;
  final String titulo;
  final String cuerpo;

  @override
  String toString() =>
      'RecordatorioProgramado($citaId, ${momento.toIso8601String()})';
}

/// Contrato del servicio de recordatorios (HU-08).
///
/// RNF-12: Firebase Cloud Messaging queda detras de esta interfaz. Si el
/// proyecto se lleva a iOS, o si se cambia de proveedor, solo cambia la
/// implementacion.
abstract interface class ServicioRecordatorios {
  /// Solicita el permiso de notificaciones si aun no se hizo.
  ///
  /// Seccion 11: se invoca **solo al confirmar la primera cita**, nunca al
  /// arrancar la aplicacion. Devuelve `true` si se puede notificar.
  Future<bool> asegurarPermiso();

  /// Programa el recordatorio de [cita] segun RN-07.
  ///
  /// Devuelve el recordatorio programado, o `null` si la cita no admite uno
  /// (ya no esta activa, o el momento de aviso ya paso).
  Future<RecordatorioProgramado?> programar(Cita cita);

  /// Cancela el recordatorio de una cita cancelada o reprogramada.
  Future<void> cancelar(String citaId);

  /// Recordatorios vigentes, para poder inspeccionarlos.
  Future<List<RecordatorioProgramado>> programados();
}

/// Implementacion de desarrollo: registra los recordatorios en consola.
///
/// Usa `debugPrint` y no `developer.log` a proposito: en Android solo el
/// primero llega a `logcat`, que es donde se puede comprobar en el dispositivo
/// que RN-07 calculo bien el momento del aviso.
///
/// Es la que se usa mientras `FeatureFlags.usarFirebase` esta en `false`. No
/// envia nada: deja constancia de *cuando* se habria enviado y con que
/// contenido, que es lo que permite comprobar RN-07 sin un proyecto de
/// Firebase.
class RecordatoriosEnConsola implements ServicioRecordatorios {
  RecordatoriosEnConsola(this._preferencias, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  final PreferenciasRepository _preferencias;
  final DateTime Function() _reloj;

  final Map<String, RecordatorioProgramado> _programados =
      <String, RecordatorioProgramado>{};

  @override
  Future<bool> asegurarPermiso() async {
    final yaSolicitado = await _preferencias
        .obtenerPermisoNotificacionesSolicitado();

    if (yaSolicitado.valorONull ?? false) return true;

    // Sin Firebase no hay dialogo de sistema que mostrar. Se deja constancia
    // del momento en que se habria pedido, que es lo que exige la seccion 11:
    // al confirmar la primera cita, no al arrancar.
    debugPrint(
      '[recordatorios] Se solicitaria el permiso POST_NOTIFICATIONS ahora '
      '(primera cita confirmada).',
    );
    await _preferencias.guardarPermisoNotificacionesSolicitado(true);
    return true;
  }

  @override
  Future<RecordatorioProgramado?> programar(Cita cita) async {
    final momento = Rn07Recordatorio.momentoDeAviso(
      cita: cita,
      ahora: _reloj(),
    );
    if (momento == null) {
      debugPrint(
        '[recordatorios] La cita ${cita.id} no admite recordatorio (RN-07).',
      );
      return null;
    }

    final inicio = cita.fechaHoraInicio!;
    final recordatorio = RecordatorioProgramado(
      citaId: cita.id,
      momento: momento,
      titulo: 'Recordatorio de tu cita',
      cuerpo:
          'Tienes una cita el ${FormatoFecha.fechaCorta(inicio)} '
          'a las ${FormatoFecha.hora(inicio)}.',
    );

    _programados[cita.id] = recordatorio;
    debugPrint(
      '[recordatorios] Programado para ${momento.toIso8601String()} '
      '(cita ${cita.id}): ${recordatorio.cuerpo}',
    );
    return recordatorio;
  }

  @override
  Future<void> cancelar(String citaId) async {
    if (_programados.remove(citaId) != null) {
      debugPrint('[recordatorios] Cancelado (cita $citaId).');
    }
  }

  @override
  Future<List<RecordatorioProgramado>> programados() async =>
      _programados.values.toList();
}
