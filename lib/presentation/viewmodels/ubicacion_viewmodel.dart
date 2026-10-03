import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../core/mapas/servicio_mapas.dart';
import '../../domain/entities/consultorio.dart';
import '../../domain/entities/sede.dart';
import '../../domain/repositories/catalogo_repository.dart';

/// HU-10 — Ubicacion de sede y consultorio.
class UbicacionViewModel extends ChangeNotifier {
  UbicacionViewModel(this._catalogo, this._mapas);

  final CatalogoRepository _catalogo;
  final ServicioMapas _mapas;

  List<Sede> _sedes = const <Sede>[];
  List<Sede> get sedes => _sedes;

  List<Consultorio> _consultorios = const <Consultorio>[];

  Sede? _seleccionada;
  Sede? get seleccionada => _seleccionada;

  bool _cargando = false;
  bool get cargando => _cargando;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  /// Consultorios de la sede seleccionada.
  List<Consultorio> get consultoriosDeLaSede {
    final sede = _seleccionada;
    if (sede == null) return const <Consultorio>[];
    return _consultorios.where((c) => c.sedeId == sede.id).toList();
  }

  Future<void> cargar() async {
    _cargando = true;
    _fallo = null;
    notifyListeners();

    final sedes = await _catalogo.obtenerSedes();
    sedes.when(
      exito: (lista) {
        _sedes = lista;
        // Con una sola sede no tiene sentido obligar a elegirla.
        _seleccionada ??= lista.isEmpty ? null : lista.first;
      },
      fallo: (f) => _fallo = f,
    );

    final consultorios = await _catalogo.obtenerConsultorios();
    consultorios.when(exito: (l) => _consultorios = l, fallo: (_) {});

    _cargando = false;
    notifyListeners();
  }

  void seleccionar(Sede sede) {
    if (_seleccionada?.id == sede.id) return;
    _seleccionada = sede;
    notifyListeners();
  }

  /// Abre las indicaciones de desplazamiento. Devuelve `false` si no hay
  /// ninguna aplicacion que pueda atenderlo.
  Future<bool> abrirIndicaciones() async {
    final sede = _seleccionada;
    if (sede == null) return false;
    try {
      return await _mapas.abrirIndicaciones(sede);
    } catch (_) {
      return false;
    }
  }
}
