// =====================================================================
// AUTENTICACION LOCAL DE DESARROLLO — NO ES UN SISTEMA DE AUTENTICACION
// =====================================================================
//
// Sustituye a Firebase Authentication mientras `FeatureFlags.usarFirebase`
// este en `false`, para que la aplicacion sea demostrable en el emulador sin
// un proyecto de Firebase.
//
// Limitaciones deliberadas, porque todo ocurre en el dispositivo:
//   - No hay verificacion de correo ni recuperacion de contrasena.
//   - El "token" es un identificador local, no un JWT firmado.
//   - Las cuentas viven solo en este dispositivo.
//
// Lo que si respeta, porque son requisitos y no detalles de implementacion:
//   - La clave NUNCA se guarda en claro: se almacena SHA-256 con sal por
//     cuenta.
//   - Todo se guarda en el almacen cifrado, nunca en shared_preferences
//     (RNF-08).
//   - El fallo de inicio de sesion no revela cual credencial fallo (HU-02).
// =====================================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/excepciones.dart';
import '../../../core/security/almacen_seguro.dart';
import '../../../domain/rules/rn02_documento_identidad.dart';
import '../../models/paciente_dto.dart';
import '../remote/paciente_remote_datasource.dart';

/// Cuenta que se crea de antemano, con su clave en claro.
///
/// La clave solo existe aqui, en el momento de sembrar: lo que llega al
/// almacen es el hash con sal, igual que en una cuenta registrada.
class CuentaInicial {
  const CuentaInicial({required this.perfil, required this.clave});

  final PacienteDto perfil;
  final String clave;
}

class FakePacienteDataSource implements PacienteDataSource {
  FakePacienteDataSource(
    this._almacen, {
    this.cuentasIniciales = const <CuentaInicial>[],
    this.latencia = AppConfig.latenciaSimulada,
    Random? aleatorio,
  }) : _aleatorio = aleatorio ?? Random.secure();

  final AlmacenSeguro _almacen;
  final Duration latencia;
  final Random _aleatorio;

  /// Cuentas de demostracion a sembrar. Vacia por defecto: los tests y
  /// cualquier arranque que no las pida trabajan con un almacen limpio.
  final List<CuentaInicial> cuentasIniciales;

  static const String _claveCuentas = 'cuentas_desarrollo';

  /// Documentos ya sembrados alguna vez. Sirve para sembrar cada cuenta **una
  /// sola vez**: si el titular la elimina (HU-12), no reaparece en la
  /// siguiente lectura.
  static const String _claveSembradas = 'cuentas_demo_sembradas';
  // -------------------------------------------------------------------
  // Operaciones
  // -------------------------------------------------------------------

  @override
  Future<SesionDto> registrar({
    required PacienteDto paciente,
    required String clave,
  }) async {
    await Future<void>.delayed(latencia);

    final cuentas = await _leerCuentas();
    final documento = paciente.numeroDocumento;

    // RN-02: el documento es el identificador unico del paciente.
    if (cuentas.containsKey(documento)) {
      throw const FalloValidacion(
        'Ya existe una cuenta registrada con este documento.',
        campo: 'numeroDocumento',
      );
    }

    final sal = _generarSal();
    final id = 'pac-local-${DateTime.now().microsecondsSinceEpoch}';
    // El rol NO se toma de lo que envia el cliente: quien se registra desde
    // la aplicacion es siempre paciente. Las cuentas de administracion solo
    // nacen sembradas, nunca por autoservicio.
    final registrado = PacienteDto(
      id: id,
      tipoDocumento: paciente.tipoDocumento,
      numeroDocumento: documento,
      nombres: paciente.nombres,
      apellidos: paciente.apellidos,
      correo: paciente.correo,
      telefono: paciente.telefono,
      consentimientoOtorgado: paciente.consentimientoOtorgado,
      fechaConsentimiento: paciente.fechaConsentimiento,
    );

    cuentas[documento] = <String, dynamic>{
      'paciente': registrado.toJson(),
      'sal': sal,
      'hash': _hashear(clave, sal),
    };
    await _guardarCuentas(cuentas);

    return SesionDto(paciente: registrado, token: _generarToken(id));
  }

  @override
  Future<SesionDto> iniciarSesion({
    required String numeroDocumento,
    required String clave,
  }) async {
    await Future<void>.delayed(latencia);

    final cuentas = await _leerCuentas();
    final cuenta = cuentas[numeroDocumento];

    // HU-02: el mismo fallo para «no existe» y para «clave incorrecta». Un
    // mensaje distinto permitiria averiguar que documentos estan registrados.
    if (cuenta == null) throw const FalloAutenticacion();

    final sal = cuenta['sal'] as String;
    final hashGuardado = cuenta['hash'] as String;
    if (_hashear(clave, sal) != hashGuardado) {
      throw const FalloAutenticacion();
    }

    final dto = PacienteDto.fromJson(
      cuenta['paciente'] as Map<String, dynamic>,
    );
    return SesionDto(paciente: dto, token: _generarToken(dto.id));
  }

  @override
  Future<PacienteDto> obtenerPorId(String id) async {
    await Future<void>.delayed(latencia);
    final cuentas = await _leerCuentas();

    for (final cuenta in cuentas.values) {
      final dto = PacienteDto.fromJson(
        cuenta['paciente'] as Map<String, dynamic>,
      );
      if (dto.id == id) return dto;
    }
    throw const FalloNoEncontrado('No se encontro el paciente.');
  }

  @override
  Future<PacienteDto> otorgarConsentimiento(String pacienteId) =>
      _actualizarConsentimiento(pacienteId, otorgado: true);

  @override
  Future<PacienteDto> revocarConsentimiento(String pacienteId) =>
      _actualizarConsentimiento(pacienteId, otorgado: false);

  /// HU-12: en el modo local, la solicitud de eliminacion se ejecuta de
  /// inmediato porque no hay backend que tramitarla. Con el backend real, la
  /// peticion queda registrada y la elimina el responsable del tratamiento.
  @override
  Future<void> solicitarEliminacionDeDatos(String pacienteId) async {
    await Future<void>.delayed(latencia);
    final cuentas = await _leerCuentas();

    final documento = _documentoDe(cuentas, pacienteId);
    if (documento == null) throw const FalloNoEncontrado();

    cuentas.remove(documento);
    await _guardarCuentas(cuentas);
  }

  // -------------------------------------------------------------------
  // Internos
  // -------------------------------------------------------------------

  Future<PacienteDto> _actualizarConsentimiento(
    String pacienteId, {
    required bool otorgado,
  }) async {
    await Future<void>.delayed(latencia);
    final cuentas = await _leerCuentas();

    final documento = _documentoDe(cuentas, pacienteId);
    if (documento == null) throw const FalloNoEncontrado();

    final cuenta = Map<String, dynamic>.from(cuentas[documento]!);
    final actual = PacienteDto.fromJson(
      cuenta['paciente'] as Map<String, dynamic>,
    );

    final actualizado = PacienteDto(
      id: actual.id,
      tipoDocumento: actual.tipoDocumento,
      numeroDocumento: actual.numeroDocumento,
      nombres: actual.nombres,
      apellidos: actual.apellidos,
      correo: actual.correo,
      telefono: actual.telefono,
      consentimientoOtorgado: otorgado,
      fechaConsentimiento: otorgado ? DateTime.now().toIso8601String() : null,
      // Sin esto, otorgar o revocar el consentimiento degradaria a un
      // administrador a paciente.
      rol: actual.rol,
    );

    cuenta['paciente'] = actualizado.toJson();
    cuentas[documento] = cuenta;
    await _guardarCuentas(cuentas);

    return actualizado;
  }

  String? _documentoDe(
    Map<String, Map<String, dynamic>> cuentas,
    String pacienteId,
  ) {
    for (final entrada in cuentas.entries) {
      final dto = PacienteDto.fromJson(
        entrada.value['paciente'] as Map<String, dynamic>,
      );
      if (dto.id == pacienteId) return entrada.key;
    }
    return null;
  }

  Future<Map<String, Map<String, dynamic>>> _leerCuentas() async {
    final crudo = await _almacen.leer(_claveCuentas);
    final cuentas = (crudo == null || crudo.isEmpty)
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(crudo) as Map<String, dynamic>).map(
            (clave, valor) =>
                MapEntry(clave, Map<String, dynamic>.from(valor as Map)),
          );

    if (await _sembrar(cuentas)) await _guardarCuentas(cuentas);
    return cuentas;
  }

  /// Anade las cuentas iniciales que aun no se hayan sembrado.
  ///
  /// Devuelve `true` si cambio algo. Una cuenta se siembra una unica vez por
  /// almacen; si el titular la elimina despues, no se recrea. Tampoco se
  /// pisa una cuenta que ya exista con ese documento.
  Future<bool> _sembrar(Map<String, Map<String, dynamic>> cuentas) async {
    if (cuentasIniciales.isEmpty) return false;

    final crudo = await _almacen.leer(_claveSembradas);
    final sembradas = <String>{
      if (crudo != null && crudo.isNotEmpty)
        ...(jsonDecode(crudo) as List<dynamic>).cast<String>(),
    };

    var cambio = false;
    for (final inicial in cuentasIniciales) {
      final documento = Rn02DocumentoIdentidad.normalizar(
        inicial.perfil.numeroDocumento,
      );
      if (sembradas.contains(documento)) continue;

      if (!cuentas.containsKey(documento)) {
        final sal = _generarSal();
        cuentas[documento] = <String, dynamic>{
          'paciente': inicial.perfil.toJson(),
          'sal': sal,
          'hash': _hashear(inicial.clave, sal),
        };
        cambio = true;
      }
      sembradas.add(documento);
    }

    await _almacen.escribir(_claveSembradas, jsonEncode(sembradas.toList()));
    return cambio;
  }

  Future<void> _guardarCuentas(Map<String, Map<String, dynamic>> cuentas) =>
      _almacen.escribir(_claveCuentas, jsonEncode(cuentas));

  /// Sal aleatoria de 16 bytes, distinta por cuenta.
  String _generarSal() {
    final bytes = List<int>.generate(16, (_) => _aleatorio.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashear(String clave, String sal) =>
      sha256.convert(utf8.encode('$sal:$clave')).toString();

  String _generarToken(String pacienteId) {
    final bytes = List<int>.generate(24, (_) => _aleatorio.nextInt(256));
    return 'local.$pacienteId.${base64Url.encode(bytes)}';
  }
}
