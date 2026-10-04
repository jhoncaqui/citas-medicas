import 'package:material_ui/material_ui.dart';

import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/rules/resultado_regla.dart';
import '../../domain/rules/rn02_documento_identidad.dart';
import '../../domain/rules/rn10_consentimiento.dart';
import '../../domain/rules/validaciones_registro.dart';
import 'sesion_viewmodel.dart';

/// HU-01 — Registro con validacion del documento de identidad.
///
/// Toda la validacion delega en `domain/rules`: este ViewModel decide
/// *cuando* validar y como presentar el error, nunca *que* es valido.
class RegistroViewModel extends ChangeNotifier {
  RegistroViewModel(this._sesion) {
    // `ocupado` y `mensajeFallo` viven en el ViewModel de sesion: sin esta
    // suscripcion la pantalla no se enteraria de que la operacion empezo o
    // fallo.
    _sesion.addListener(notifyListeners);
  }

  final SesionViewModel _sesion;

  @override
  void dispose() {
    _sesion.removeListener(notifyListeners);
    super.dispose();
  }

  // ------------------------- Campos -------------------------

  TipoDocumento _tipoDocumento = TipoDocumento.dni;
  TipoDocumento get tipoDocumento => _tipoDocumento;

  String _numeroDocumento = '';
  String _nombres = '';
  String _apellidos = '';
  String _correo = '';
  String _telefono = '';
  String _clave = '';
  String _confirmacionClave = '';

  bool _consentimientoAceptado = false;
  bool get consentimientoAceptado => _consentimientoAceptado;

  bool get ocupado => _sesion.ocupado;

  /// Errores por nombre de campo. Vacio mientras no se haya intentado enviar
  /// o mientras el campo no se haya tocado.
  final Map<String, String> _errores = <String, String>{};
  Map<String, String> get errores => Map.unmodifiable(_errores);

  String? errorDe(String campo) => _errores[campo];

  /// Mensaje de fallo de la operacion de registro, distinto de los errores de
  /// campo.
  String? get mensajeFallo => _sesion.fallo?.mensaje;

  // ------------------------- Entrada -------------------------

  void cambiarTipoDocumento(TipoDocumento tipo) {
    if (tipo == _tipoDocumento) return;
    _tipoDocumento = tipo;
    // El numero anterior puede ser valido para un tipo e invalido para el
    // otro: se revalida en cuanto ya habia un error visible.
    if (_errores.containsKey('numeroDocumento')) _validarDocumento();
    notifyListeners();
  }

  void cambiarNumeroDocumento(String valor) {
    _numeroDocumento = valor;
    _revalidarSiTieneError('numeroDocumento', _validarDocumento);
  }

  void cambiarNombres(String valor) {
    _nombres = valor;
    _revalidarSiTieneError(
      'nombres',
      () => _aplicar(ValidacionesRegistro.validarNombres(_nombres)),
    );
  }

  void cambiarApellidos(String valor) {
    _apellidos = valor;
    _revalidarSiTieneError(
      'apellidos',
      () => _aplicar(ValidacionesRegistro.validarApellidos(_apellidos)),
    );
  }

  void cambiarCorreo(String valor) {
    _correo = valor;
    _revalidarSiTieneError(
      'correo',
      () => _aplicar(ValidacionesRegistro.validarCorreo(_correo)),
    );
  }

  void cambiarTelefono(String valor) {
    _telefono = valor;
    _revalidarSiTieneError(
      'telefono',
      () => _aplicar(ValidacionesRegistro.validarTelefono(_telefono)),
    );
  }

  void cambiarClave(String valor) {
    _clave = valor;
    _revalidarSiTieneError(
      'clave',
      () => _aplicar(ValidacionesRegistro.validarClave(_clave)),
    );
  }

  void cambiarConfirmacionClave(String valor) {
    _confirmacionClave = valor;
    _revalidarSiTieneError(
      'confirmacionClave',
      () => _aplicar(
        ValidacionesRegistro.validarConfirmacionClave(
          clave: _clave,
          confirmacion: _confirmacionClave,
        ),
      ),
    );
  }

  /// RN-10: el consentimiento es un acto explicito del paciente. La casilla
  /// nace desmarcada y nunca se premarca.
  void cambiarConsentimiento(bool aceptado) {
    _consentimientoAceptado = aceptado;
    if (aceptado) _errores.remove('consentimiento');
    notifyListeners();
  }

  // ------------------------- Envio -------------------------

  /// Valida todo el formulario y registra al paciente.
  ///
  /// Devuelve `true` si el registro se completo.
  Future<bool> enviar() async {
    _errores.clear();

    _validarDocumento();
    _aplicar(ValidacionesRegistro.validarNombres(_nombres));
    _aplicar(ValidacionesRegistro.validarApellidos(_apellidos));
    _aplicar(ValidacionesRegistro.validarCorreo(_correo));
    _aplicar(ValidacionesRegistro.validarTelefono(_telefono));
    _aplicar(ValidacionesRegistro.validarClave(_clave));
    _aplicar(
      ValidacionesRegistro.validarConfirmacionClave(
        clave: _clave,
        confirmacion: _confirmacionClave,
      ),
    );
    // RN-10: sin consentimiento no hay registro.
    _aplicar(
      Rn10Consentimiento.validarParaRegistro(aceptado: _consentimientoAceptado),
    );

    if (_errores.isNotEmpty) {
      notifyListeners();
      return false;
    }

    final ahora = DateTime.now();
    final paciente = Paciente(
      // El backend asigna el identificador definitivo.
      id: '',
      tipoDocumento: _tipoDocumento,
      numeroDocumento: Rn02DocumentoIdentidad.normalizar(_numeroDocumento),
      nombres: _nombres.trim(),
      apellidos: _apellidos.trim(),
      correo: ValidacionesRegistro.normalizarCorreo(_correo),
      telefono: ValidacionesRegistro.normalizarTelefono(_telefono),
      consentimientoOtorgado: true,
      fechaConsentimiento: ahora,
    );

    return _sesion.registrar(paciente: paciente, clave: _clave);
  }

  // ------------------------- Internos -------------------------

  void _validarDocumento() => _aplicar(
    Rn02DocumentoIdentidad.validar(
      tipo: _tipoDocumento,
      numero: _numeroDocumento,
    ),
  );

  /// Registra o limpia el error del campo al que apunta el veredicto.
  void _aplicar(ResultadoRegla veredicto) {
    final campo = veredicto.campo;
    if (campo == null) return;

    if (veredicto.infringida) {
      _errores[campo] = veredicto.mensaje!;
    } else {
      _errores.remove(campo);
    }
  }

  /// Revalida en cada pulsacion solo si el campo ya mostraba un error.
  ///
  /// Validar desde la primera letra convierte el formulario en un campo de
  /// minas rojo; una vez que el paciente ya vio el error, en cambio, conviene
  /// que desaparezca en cuanto lo corrija.
  void _revalidarSiTieneError(String campo, void Function() validar) {
    if (!_errores.containsKey(campo)) return;
    validar();
    notifyListeners();
  }
}
