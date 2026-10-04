import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/error/excepciones.dart';
import '../../core/notificaciones/servicio_recordatorios.dart';
import '../../domain/entities/cita.dart';
import '../../domain/entities/consultorio.dart';
import '../../domain/entities/cupo_disponible.dart';
import '../../domain/entities/especialidad.dart';
import '../../domain/entities/intencion_asistente.dart';
import '../../domain/entities/profesional.dart';
import '../../domain/entities/sede.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../../domain/repositories/cita_repository.dart';
import '../../domain/rules/rn01_autenticacion.dart';
import '../../domain/rules/rn03_rn04_rn05_reserva.dart';
import '../../domain/rules/rn06_rn07_rn08_gestion.dart';
import 'sesion_viewmodel.dart';

/// Pasos del flujo guiado (HU-04).
enum PasoReserva { especialidad, profesional, fecha, horario, confirmacion }

/// Estado compartido de una reserva en curso.
///
/// Lo usan **los dos flujos**: el conversacional (HU-03) rellena los mismos
/// campos que el guiado (HU-04). Por eso una conversacion que se atasca puede
/// continuar en el menu sin perder lo ya dicho, que es lo que exige el
/// fallback obligatorio de la seccion 8.
class ReservaViewModel extends ChangeNotifier {
  ReservaViewModel(
    this._catalogo,
    this._citas,
    this._sesion, {
    ServicioRecordatorios? recordatorios,
    DateTime Function()? reloj,
    Random? aleatorio,
  }) : _recordatorios = recordatorios,
       _reloj = reloj ?? DateTime.now,
       _aleatorio = aleatorio ?? Random();

  // `recordatorios` se declara con nombre publico aunque el campo sea
  // privado: el nombre del parametro es parte de la API del constructor.

  final CatalogoRepository _catalogo;
  final CitaRepository _citas;
  final SesionViewModel _sesion;

  /// `null` en los tests que no necesitan comprobar los recordatorios.
  final ServicioRecordatorios? _recordatorios;
  final DateTime Function() _reloj;
  final Random _aleatorio;

  // ------------------------- Estado -------------------------

  PasoReserva _paso = PasoReserva.especialidad;
  PasoReserva get paso => _paso;

  List<Especialidad> _especialidades = const <Especialidad>[];
  List<Especialidad> get especialidades => _especialidades;

  List<Profesional> _profesionales = const <Profesional>[];
  List<Profesional> get profesionales => _profesionales;

  List<CupoDisponible> _cupos = const <CupoDisponible>[];
  List<CupoDisponible> get cupos => _cupos;

  List<Sede> _sedes = const <Sede>[];
  List<Consultorio> _consultorios = const <Consultorio>[];

  Especialidad? _especialidad;
  Especialidad? get especialidad => _especialidad;

  /// `null` significa «cualquier profesional disponible».
  Profesional? _profesional;
  Profesional? get profesional => _profesional;

  DateTime? _fecha;
  DateTime? get fecha => _fecha;

  TurnoDia? _turno;
  TurnoDia? get turno => _turno;

  CupoDisponible? _cupoSeleccionado;
  CupoDisponible? get cupoSeleccionado => _cupoSeleccionado;

  /// Canal por el que se origino la reserva (HU-11).
  CanalReserva canal = CanalReserva.flujoGuiado;

  bool _cargando = false;
  bool get cargando => _cargando;

  bool _confirmando = false;
  bool get confirmando => _confirmando;

  FalloApp? _fallo;
  FalloApp? get fallo => _fallo;

  Cita? _citaConfirmada;
  Cita? get citaConfirmada => _citaConfirmada;

  /// RNF-07 — identifica el intento de reserva.
  ///
  /// Se genera al entrar en la confirmacion y **no cambia entre reintentos**:
  /// si la red se cae tras enviar la peticion pero antes de recibir la
  /// respuesta, el reintento lleva la misma clave y el backend devuelve la
  /// cita ya creada en lugar de crear una segunda.
  String? _claveIdempotencia;
  String? get claveIdempotencia => _claveIdempotencia;

  /// Cita que se esta reprogramando (HU-07). `null` en una reserva nueva.
  ///
  /// Reprogramar es elegir un horario: el mismo problema que elegirlo la
  /// primera vez, asi que reutiliza este ViewModel y el flujo guiado en lugar
  /// de duplicar ambos.
  Cita? _citaAReprogramar;
  Cita? get citaAReprogramar => _citaAReprogramar;
  bool get esReprogramacion => _citaAReprogramar != null;

  // ------------------------- Datos derivados -------------------------

  /// Reloj del ViewModel.
  ///
  /// Las pantallas deben usar este y no `DateTime.now()`: RN-04 se evalua con
  /// este reloj, y si la vista ofreciera dias calculados con otro, podria
  /// mostrar fechas que la regla despues rechaza.
  DateTime get ahora => _reloj();

  Profesional? profesionalDe(String? id) =>
      id == null ? null : _profesionales.where((p) => p.id == id).firstOrNull;

  Sede? sedeDe(String? id) =>
      id == null ? null : _sedes.where((s) => s.id == id).firstOrNull;

  Consultorio? consultorioDe(String? id) =>
      id == null ? null : _consultorios.where((c) => c.id == id).firstOrNull;

  Especialidad? especialidadDe(String? id) =>
      id == null ? null : _especialidades.where((e) => e.id == id).firstOrNull;

  /// Cupos del turno indicado, para agrupar la seleccion de horario.
  List<CupoDisponible> cuposDelTurno(TurnoDia turno) => _cupos
      .where(
        (c) => turno == TurnoDia.manana
            ? c.fechaHoraInicio.hour < 12
            : c.fechaHoraInicio.hour >= 12,
      )
      .toList();

  bool get puedeConfirmar =>
      _especialidad != null && _cupoSeleccionado != null && !_confirmando;

  // ------------------------- Carga -------------------------

  Future<void> iniciar({CanalReserva canal = CanalReserva.flujoGuiado}) async {
    this.canal = canal;
    _fallo = null;
    await cargarEspecialidades();
    await _cargarCatalogosDeApoyo();
  }

  Future<void> cargarEspecialidades() async {
    _cargando = true;
    notifyListeners();

    final resultado = await _catalogo.obtenerEspecialidades();
    resultado.when(
      exito: (lista) => _especialidades = lista.where((e) => e.activa).toList(),
      fallo: (f) => _fallo = f,
    );

    _cargando = false;
    notifyListeners();
  }

  /// Sedes y consultorios se necesitan para el comprobante (HU-06). Se cargan
  /// una vez al inicio en lugar de una peticion por cupo (ODS 12: agrupar
  /// llamadas de red).
  Future<void> _cargarCatalogosDeApoyo() async {
    final sedes = await _catalogo.obtenerSedes();
    sedes.when(exito: (l) => _sedes = l, fallo: (_) {});

    final consultorios = await _catalogo.obtenerConsultorios();
    consultorios.when(exito: (l) => _consultorios = l, fallo: (_) {});
  }

  Future<void> cargarProfesionales() async {
    final especialidad = _especialidad;
    if (especialidad == null) return;

    _cargando = true;
    notifyListeners();

    final resultado = await _catalogo.obtenerProfesionales(
      especialidadId: especialidad.id,
    );
    resultado.when(
      exito: (lista) => _profesionales = lista,
      fallo: (f) => _fallo = f,
    );

    _cargando = false;
    notifyListeners();
  }

  /// HU-05 — consulta de cupos realmente disponibles.
  Future<void> cargarCupos() async {
    final especialidad = _especialidad;
    if (especialidad == null) return;

    _cargando = true;
    _fallo = null;
    notifyListeners();

    final resultado = await _citas.obtenerCupos(
      especialidadId: especialidad.id,
      profesionalId: _profesional?.id,
      fecha: _fecha,
      turno: _turno,
    );

    resultado.when(
      exito: (lista) {
        _cupos = lista;
        // Si el cupo elegido desaparecio de la lista mientras el paciente
        // decidia, deja de estar seleccionado (HU-05).
        if (_cupoSeleccionado != null &&
            !lista.any((c) => c.id == _cupoSeleccionado!.id && c.disponible)) {
          _cupoSeleccionado = null;
        }
      },
      fallo: (f) => _fallo = f,
    );

    _cargando = false;
    notifyListeners();
  }

  // ------------------------- Seleccion -------------------------

  Future<void> elegirEspecialidad(Especialidad especialidad) async {
    if (_especialidad?.id == especialidad.id) return;
    _especialidad = especialidad;
    // Cambiar de especialidad invalida lo elegido despues.
    _profesional = null;
    _cupoSeleccionado = null;
    _cupos = const <CupoDisponible>[];
    notifyListeners();
    await cargarProfesionales();
  }

  void elegirProfesional(Profesional? profesional) {
    _profesional = profesional;
    _cupoSeleccionado = null;
    notifyListeners();
  }

  void elegirFecha(DateTime fecha) {
    _fecha = DateTime(fecha.year, fecha.month, fecha.day);
    _cupoSeleccionado = null;
    notifyListeners();
  }

  void elegirTurno(TurnoDia? turno) {
    _turno = turno;
    notifyListeners();
  }

  /// Devuelve el motivo del rechazo, o `null` si el cupo es elegible.
  String? elegirCupo(CupoDisponible cupo) {
    // RN-04 — nunca en el pasado.
    final rn04 = Rn04NoEnElPasado.validar(
      fechaHoraInicio: cupo.fechaHoraInicio,
      ahora: _reloj(),
    );
    if (rn04.infringida) return rn04.mensaje;

    // RN-03 — el cupo debe seguir libre.
    final rn03 = Rn03CupoUnico.validar(cupo: cupo, citasDelSistema: const []);
    if (rn03.infringida) return rn03.mensaje;

    _cupoSeleccionado = cupo;
    notifyListeners();
    return null;
  }

  // ------------------------- Navegacion del flujo guiado -------------------------

  void irA(PasoReserva paso) {
    _paso = paso;
    notifyListeners();
  }

  Future<void> avanzar() async {
    switch (_paso) {
      case PasoReserva.especialidad:
        if (_especialidad == null) return;
        _paso = PasoReserva.profesional;
      case PasoReserva.profesional:
        _paso = PasoReserva.fecha;
      case PasoReserva.fecha:
        if (_fecha == null) return;
        _paso = PasoReserva.horario;
        notifyListeners();
        await cargarCupos();
        return;
      case PasoReserva.horario:
        if (_cupoSeleccionado == null) return;
        _prepararConfirmacion();
        _paso = PasoReserva.confirmacion;
      case PasoReserva.confirmacion:
        return;
    }
    notifyListeners();
  }

  void retroceder() {
    _paso = switch (_paso) {
      PasoReserva.especialidad => PasoReserva.especialidad,
      PasoReserva.profesional => PasoReserva.especialidad,
      PasoReserva.fecha => PasoReserva.profesional,
      PasoReserva.horario => PasoReserva.fecha,
      PasoReserva.confirmacion => PasoReserva.horario,
    };
    notifyListeners();
  }

  /// Genera la clave de idempotencia del intento, si aun no existe.
  void _prepararConfirmacion() {
    _claveIdempotencia ??= _generarClave();
  }

  /// HU-07 — prepara el flujo para reprogramar [cita].
  ///
  /// Se conserva la especialidad de la cita original: reprogramar es cambiar
  /// el horario, no la especialidad. Si el paciente quiere otra cosa, lo suyo
  /// es cancelar y reservar de nuevo.
  void prepararReprogramacion(Cita cita) {
    reiniciar();
    _citaAReprogramar = cita;
    _especialidad = especialidadDe(cita.especialidadId);
    _paso = _especialidad == null
        ? PasoReserva.especialidad
        : PasoReserva.fecha;
    notifyListeners();
  }

  /// Entra directamente en la confirmacion desde el flujo conversacional.
  void prepararConfirmacionDirecta() {
    _prepararConfirmacion();
    _paso = PasoReserva.confirmacion;
    notifyListeners();
  }

  // ------------------------- Confirmacion (HU-06) -------------------------

  Future<bool> confirmar() async {
    final paciente = _sesion.paciente;
    final cupo = _cupoSeleccionado;
    if (cupo == null) return false;

    // RN-01 y RN-10 se vuelven a comprobar aqui: proteger solo la navegacion
    // dejaria la puerta abierta a llegar por otra via.
    final impedimento = _sesion.impedimentoPara(OperacionProtegida.reservar);
    if (impedimento != null || paciente == null) {
      _fallo = FalloReglaNegocio(
        impedimento ?? 'Inicia sesion para reservar una cita.',
        regla: 'RN-01',
      );
      notifyListeners();
      return false;
    }

    // RN-04 — el tiempo pasa mientras el paciente decide.
    final rn04 = Rn04NoEnElPasado.validar(
      fechaHoraInicio: cupo.fechaHoraInicio,
      ahora: _reloj(),
    );
    if (rn04.infringida) {
      _fallo = FalloReglaNegocio(rn04.mensaje!, regla: rn04.regla);
      _cupoSeleccionado = null;
      notifyListeners();
      return false;
    }

    // RN-06 — al reprogramar, el plazo se vuelve a comprobar aqui: entre que
    // la pantalla anterior habilito el boton y este momento pudo pasar el
    // tiempo suficiente para que deje de estar permitido.
    if (_citaAReprogramar != null) {
      final rn06 = Rn06Autogestion.validar(
        cita: _citaAReprogramar!,
        accion: AccionAutogestion.reprogramar,
        ahora: _reloj(),
      );
      if (rn06.infringida) {
        _fallo = FalloReglaNegocio(rn06.mensaje!, regla: rn06.regla);
        notifyListeners();
        return false;
      }
    }

    // RN-05 — no dos citas activas el mismo dia con el mismo profesional y
    // especialidad.
    final existentes = await _citas.obtenerCitas(pacienteId: paciente.id);
    final citasDelPaciente = (existentes.valorONull ?? const <Cita>[])
        // Al reprogramar, la propia cita no cuenta como duplicado de si
        // misma: sin esta exclusion, mover una cita a otra hora del mismo dia
        // se rechazaria siempre.
        .where((c) => c.id != _citaAReprogramar?.id)
        .toList();
    final rn05 = Rn05SinDuplicados.validar(
      especialidadId: _especialidad!.id,
      profesionalId: cupo.profesionalId,
      fechaHoraInicio: cupo.fechaHoraInicio,
      citasDelPaciente: citasDelPaciente,
    );
    if (rn05.infringida) {
      _fallo = FalloReglaNegocio(rn05.mensaje!, regla: rn05.regla);
      notifyListeners();
      return false;
    }

    _prepararConfirmacion();
    _confirmando = true;
    _fallo = null;
    notifyListeners();

    final aReprogramar = _citaAReprogramar;
    final resultado = aReprogramar == null
        ? await _citas.confirmarReserva(
            pacienteId: paciente.id,
            cupoId: cupo.id,
            canal: canal,
            claveIdempotencia: _claveIdempotencia!,
          )
        : await _citas.reprogramar(
            citaId: aReprogramar.id,
            nuevoCupoId: cupo.id,
          );

    final exito = resultado.when(
      exito: (cita) {
        _citaConfirmada = cita;
        // La clave se retira solo cuando la reserva esta confirmada: hasta
        // entonces cualquier reintento debe reutilizarla (RNF-07).
        _claveIdempotencia = null;
        _citaAReprogramar = null;
        return true;
      },
      fallo: (f) {
        _fallo = f;
        return false;
      },
    );

    if (exito) await _programarRecordatorio(_citaConfirmada!);

    _confirmando = false;
    notifyListeners();
    return exito;
  }

  /// HU-08 y seccion 11.
  ///
  /// El permiso de notificaciones se pide **aqui**, al confirmar una cita, y
  /// no al arrancar la aplicacion. Un fallo al programar el recordatorio no
  /// invalida la reserva: la cita ya existe.
  Future<void> _programarRecordatorio(Cita cita) async {
    final servicio = _recordatorios;
    if (servicio == null) return;
    try {
      await servicio.asegurarPermiso();
      await servicio.programar(cita);
    } catch (_) {
      // Sin recordatorio, pero con la cita confirmada.
    }
  }

  // ------------------------- Desde el asistente -------------------------

  /// Aplica lo que el asistente entendio. Devuelve `true` si con lo aplicado
  /// ya se puede buscar horarios.
  Future<bool> aplicarEntidades(Map<String, String> entidades) async {
    final especialidadId = entidades['especialidad'];
    if (especialidadId != null) {
      final especialidad = especialidadDe(especialidadId);
      if (especialidad != null) await elegirEspecialidad(especialidad);
    }

    final profesionalId = entidades['profesional'];
    if (profesionalId != null) {
      final profesional = profesionalDe(profesionalId);
      if (profesional != null) elegirProfesional(profesional);
    }

    final fechaIso = entidades['fecha'];
    if (fechaIso != null) {
      final fecha = DateTime.tryParse(fechaIso);
      if (fecha != null) elegirFecha(fecha);
    }

    final turno = TurnoDia.desdeClave(entidades['turno']);
    if (turno != null) elegirTurno(turno);

    return _especialidad != null && _fecha != null;
  }

  // ------------------------- Utilidades -------------------------

  void limpiarFallo() {
    if (_fallo == null) return;
    _fallo = null;
    notifyListeners();
  }

  /// Deja el ViewModel listo para una reserva nueva.
  void reiniciar() {
    _paso = PasoReserva.especialidad;
    _especialidad = null;
    _profesional = null;
    _fecha = null;
    _turno = null;
    _cupoSeleccionado = null;
    _cupos = const <CupoDisponible>[];
    _citaConfirmada = null;
    _claveIdempotencia = null;
    _citaAReprogramar = null;
    _fallo = null;
    notifyListeners();
  }

  String _generarClave() {
    final bytes = List<int>.generate(8, (_) => _aleatorio.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'res-${_reloj().microsecondsSinceEpoch}-$hex';
  }
}
