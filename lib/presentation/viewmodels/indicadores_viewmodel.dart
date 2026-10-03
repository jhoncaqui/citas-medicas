import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../domain/entities/cita.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/repositories/cita_repository.dart';
import '../../domain/rules/indicadores.dart';
import '../../domain/rules/rn01_autenticacion.dart';
import 'sesion_viewmodel.dart';

/// Periodos que ofrece el panel.
enum PeriodoIndicadores {
  ultimos7('Ultimos 7 dias', 7),
  ultimos30('Ultimos 30 dias', 30),
  todo('Todo el historial', null);

  const PeriodoIndicadores(this.etiqueta, this.dias);

  final String etiqueta;
  final int? dias;
}

/// HU-11 — Panel de indicadores para el personal de admision.
///
/// Solo lo cargan las cuentas de administracion (RN-01). Con las fuentes
/// falsas, «todas las citas» son las registradas en este dispositivo, no las
/// de la clinica real; la pantalla lo dice mientras no haya backend.
class IndicadoresViewModel extends ChangeNotifier {
  IndicadoresViewModel(this._citas, this._sesion, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  final CitaRepository _citas;
  final SesionViewModel _sesion;
  final DateTime Function() _reloj;

  List<Cita> _todas = const <Cita>[];

  PeriodoIndicadores _periodo = PeriodoIndicadores.ultimos30;
  PeriodoIndicadores get periodo => _periodo;

  bool _cargando = false;
  bool get cargando => _cargando;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  Indicadores get indicadores {
    final dias = _periodo.dias;
    return Indicadores.calcular(
      _todas,
      desde: dias == null ? null : _reloj().subtract(Duration(days: dias)),
    );
  }

  Map<CanalReserva, int> get porCanal => Indicadores.porCanal(_todas);

  Future<void> cargar() async {
    if (_sesion.paciente == null) return;

    // RN-01: se comprueba aqui y no solo al pintar la tarjeta del inicio. Ni
    // navegando directamente a la ruta se llega a los datos de otros
    // pacientes sin una cuenta de administracion.
    final impedimento = _sesion.impedimentoPara(
      OperacionProtegida.verIndicadores,
    );
    if (impedimento != null) {
      _todas = const <Cita>[];
      _fallo = FalloReglaNegocio(impedimento, regla: 'RN-01');
      notifyListeners();
      return;
    }

    _cargando = true;
    _fallo = null;
    notifyListeners();

    final resultado = await _citas.obtenerTodasLasCitas();
    resultado.when(exito: (lista) => _todas = lista, fallo: (f) => _fallo = f);

    _cargando = false;
    notifyListeners();
  }

  void cambiarPeriodo(PeriodoIndicadores nuevo) {
    if (nuevo == _periodo) return;
    _periodo = nuevo;
    notifyListeners();
  }
}
