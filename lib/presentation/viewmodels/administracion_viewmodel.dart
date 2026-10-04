import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../core/error/resultado.dart';
import '../../domain/entities/especialidad.dart';
import '../../domain/entities/profesional.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../../domain/rules/rn01_autenticacion.dart';
import 'sesion_viewmodel.dart';

/// Gestion del catalogo por el personal de administracion.
///
/// Da de alta, edita y elimina especialidades y profesionales. Es una funcion
/// exclusiva de las cuentas de administracion: RN-01 se comprueba aqui, no solo
/// al pintar la tarjeta del inicio, para que ni navegando directamente a la
/// ruta se llegue a modificar el catalogo sin privilegios.
///
/// A diferencia del catalogo que ve el paciente, aqui se cargan tambien las
/// especialidades inactivas: el administrador necesita verlas para reactivarlas
/// o eliminarlas.
class AdministracionViewModel extends ChangeNotifier {
  AdministracionViewModel(this._catalogo, this._sesion);

  final CatalogoRepository _catalogo;
  final SesionViewModel _sesion;

  List<Especialidad> _especialidades = const <Especialidad>[];
  List<Especialidad> get especialidades => _especialidades;

  List<Profesional> _profesionales = const <Profesional>[];
  List<Profesional> get profesionales => _profesionales;

  bool _cargando = false;
  bool get cargando => _cargando;

  bool _ocupado = false;
  bool get ocupado => _ocupado;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  /// `null` si la cuenta puede gestionar el catalogo; el motivo si no.
  String? get impedimento =>
      _sesion.impedimentoPara(OperacionProtegida.gestionarCatalogo);

  bool get puedeGestionar => impedimento == null;

  /// Nombre de la especialidad de un profesional, para mostrarlo en la lista.
  String nombreEspecialidad(String especialidadId) => _especialidades
      .where((e) => e.id == especialidadId)
      .map((e) => e.nombre)
      .firstOrNull ??
      'Sin especialidad';

  // -------------------------------------------------------------------

  Future<void> cargar() async {
    final motivo = impedimento;
    if (motivo != null) {
      _fallo = FalloReglaNegocio(motivo, regla: 'RN-01');
      notifyListeners();
      return;
    }

    _cargando = true;
    _fallo = null;
    notifyListeners();

    final especialidades = await _catalogo.obtenerEspecialidades();
    especialidades.when(
      exito: (lista) => _especialidades = lista,
      fallo: (f) => _fallo = f,
    );

    final profesionales = await _catalogo.obtenerProfesionales();
    profesionales.when(
      exito: (lista) => _profesionales = lista,
      fallo: (f) => _fallo = f,
    );

    _cargando = false;
    notifyListeners();
  }

  // ---------------- Especialidades ----------------

  Future<bool> guardarEspecialidad({
    String? id,
    required String nombre,
    required String descripcion,
    required bool activa,
  }) {
    final especialidad = Especialidad(
      id: id ?? '',
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      activa: activa,
    );
    return _operacion(
      () => id == null
          ? _catalogo.crearEspecialidad(especialidad)
          : _catalogo.actualizarEspecialidad(especialidad),
    );
  }

  Future<bool> eliminarEspecialidad(String id) =>
      _operacion(() => _catalogo.eliminarEspecialidad(id));

  // ---------------- Profesionales ----------------

  Future<bool> guardarProfesional({
    String? id,
    required String nombres,
    required String apellidos,
    required String especialidadId,
    required String colegiatura,
  }) {
    final profesional = Profesional(
      id: id ?? '',
      nombres: nombres.trim(),
      apellidos: apellidos.trim(),
      especialidadId: especialidadId,
      colegiatura: colegiatura.trim(),
    );
    return _operacion(
      () => id == null
          ? _catalogo.crearProfesional(profesional)
          : _catalogo.actualizarProfesional(profesional),
    );
  }

  Future<bool> eliminarProfesional(String id) =>
      _operacion(() => _catalogo.eliminarProfesional(id));

  // -------------------------------------------------------------------

  /// Ejecuta una accion de escritura: gestiona `ocupado`/`fallo`, recarga el
  /// catalogo si tuvo exito y expone el fallo si lo hubo.
  ///
  /// El repositorio nunca lanza: devuelve el fallo dentro del [Resultado], asi
  /// que el motivo (p. ej. «no puedes eliminar una especialidad con
  /// profesionales») se extrae de ahi y se muestra en la pantalla.
  Future<bool> _operacion<T>(Future<Resultado<T>> Function() accion) async {
    final motivo = impedimento;
    if (motivo != null) {
      _fallo = FalloReglaNegocio(motivo, regla: 'RN-01');
      notifyListeners();
      return false;
    }

    _ocupado = true;
    _fallo = null;
    notifyListeners();

    final exito = (await accion()).when(
      exito: (_) => true,
      fallo: (f) {
        _fallo = f;
        return false;
      },
    );

    if (exito) {
      await _recargarSilencioso();
    }

    _ocupado = false;
    notifyListeners();
    return exito;
  }

  /// Recarga listas sin tocar `cargando` (ya estamos dentro de una operacion).
  Future<void> _recargarSilencioso() async {
    final especialidades = await _catalogo.obtenerEspecialidades();
    especialidades.when(
      exito: (lista) => _especialidades = lista,
      fallo: (f) => _fallo = f,
    );
    final profesionales = await _catalogo.obtenerProfesionales();
    profesionales.when(
      exito: (lista) => _profesionales = lista,
      fallo: (f) => _fallo = f,
    );
  }

  void limpiarFallo() {
    if (_fallo == null) return;
    _fallo = null;
    notifyListeners();
  }
}
