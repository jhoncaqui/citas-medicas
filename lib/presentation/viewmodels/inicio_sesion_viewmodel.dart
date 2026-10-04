import 'package:material_ui/material_ui.dart';

import '../../domain/rules/rn02_documento_identidad.dart';
import '../../l10n/cadenas.dart';
import 'sesion_viewmodel.dart';

/// HU-02 — Inicio de sesion seguro.
///
/// Los mensajes de error **no revelan cual credencial fallo**. Por eso aqui
/// solo se comprueba que los campos no esten vacios: una validacion de
/// formato del documento en esta pantalla permitiria distinguir «documento
/// mal escrito» de «documento no registrado», que es justo la informacion que
/// no se debe filtrar.
class InicioSesionViewModel extends ChangeNotifier {
  InicioSesionViewModel(this._sesion) {
    // `ocupado` y `mensajeFallo` viven en el ViewModel de sesion.
    _sesion.addListener(notifyListeners);
  }

  final SesionViewModel _sesion;

  @override
  void dispose() {
    _sesion.removeListener(notifyListeners);
    super.dispose();
  }

  String _numeroDocumento = '';
  String _clave = '';

  bool get ocupado => _sesion.ocupado;

  /// Error de campo vacio. No describe el contenido, solo su ausencia.
  final Map<String, String> _errores = <String, String>{};
  String? errorDe(String campo) => _errores[campo];

  /// Mensaje generico devuelto por el repositorio.
  String? get mensajeFallo => _sesion.fallo?.mensaje;

  void cambiarNumeroDocumento(String valor) {
    _numeroDocumento = valor;
    if (_errores.remove('numeroDocumento') != null) notifyListeners();
  }

  void cambiarClave(String valor) {
    _clave = valor;
    if (_errores.remove('clave') != null) notifyListeners();
  }

  Future<bool> enviar() async {
    _errores.clear();

    if (_numeroDocumento.trim().isEmpty) {
      _errores['numeroDocumento'] = Cadenas.ingresaDocumentoOUsuario;
    }
    if (_clave.isEmpty) {
      _errores['clave'] = 'Ingresa tu contrasena.';
    }

    if (_errores.isNotEmpty) {
      notifyListeners();
      return false;
    }

    return _sesion.iniciarSesion(
      numeroDocumento: Rn02DocumentoIdentidad.normalizar(_numeroDocumento),
      clave: _clave,
    );
  }

  void limpiarFallo() => _sesion.limpiarFallo();
}
