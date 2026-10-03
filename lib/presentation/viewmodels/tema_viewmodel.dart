import 'package:material_ui/material_ui.dart';

import '../../domain/repositories/preferencias_repository.dart';

/// Gestiona la preferencia de tema del paciente.
///
/// ODS 12 (decision 5): el tema oscuro respeta por defecto la preferencia del
/// sistema. [ThemeMode.system] es el valor inicial y solo cambia si el
/// paciente lo elige de forma explicita.
class TemaViewModel extends ChangeNotifier {
  TemaViewModel(this._preferencias);

  final PreferenciasRepository _preferencias;

  ThemeMode _modo = ThemeMode.system;
  ThemeMode get modo => _modo;

  /// Carga la preferencia guardada. Si nunca se guardo ninguna, se mantiene
  /// [ThemeMode.system].
  Future<void> cargar() async {
    final resultado = await _preferencias.obtenerPreferenciaTemaOscuro();
    final oscuro = resultado.valorONull;
    final nuevo = switch (oscuro) {
      null => ThemeMode.system,
      true => ThemeMode.dark,
      false => ThemeMode.light,
    };
    if (nuevo != _modo) {
      _modo = nuevo;
      notifyListeners();
    }
  }

  Future<void> cambiar(ThemeMode nuevo) async {
    if (nuevo == _modo) return;
    _modo = nuevo;
    notifyListeners();
    await _preferencias.guardarPreferenciaTemaOscuro(switch (nuevo) {
      ThemeMode.system => null,
      ThemeMode.dark => true,
      ThemeMode.light => false,
    });
  }
}
