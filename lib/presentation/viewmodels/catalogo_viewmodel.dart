import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../domain/entities/especialidad.dart';
import '../../domain/repositories/catalogo_repository.dart';

/// Estados posibles de una carga. Evita las tres banderas booleanas sueltas
/// (`cargando`, `error`, `vacio`) que siempre acaban contradiciendose.
enum EstadoCarga { inicial, cargando, exito, error }

/// ViewModel de los catalogos.
///
/// RNF-03: notifica un unico cambio por transicion de estado, para que los
/// `Selector`/`Consumer` acotados de la vista no reconstruyan de mas.
class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel(this._repositorio);

  final CatalogoRepository _repositorio;

  EstadoCarga _estado = EstadoCarga.inicial;
  EstadoCarga get estado => _estado;

  List<Especialidad> _especialidades = const <Especialidad>[];

  /// Solo las especialidades activas: una inactiva no se oferta.
  List<Especialidad> get especialidades => _especialidades;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  bool get estaCargando => _estado == EstadoCarga.cargando;

  Future<void> cargarEspecialidades() async {
    if (_estado == EstadoCarga.cargando) return;

    _estado = EstadoCarga.cargando;
    _fallo = null;
    notifyListeners();

    final resultado = await _repositorio.obtenerEspecialidades();

    resultado.when(
      exito: (lista) {
        _especialidades = lista.where((e) => e.activa).toList();
        _estado = EstadoCarga.exito;
      },
      fallo: (f) {
        _fallo = f;
        _estado = EstadoCarga.error;
      },
    );

    notifyListeners();
  }
}
