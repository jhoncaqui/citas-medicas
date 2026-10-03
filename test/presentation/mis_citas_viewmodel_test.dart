import 'package:citas_medicas_app/core/config/app_config.dart';
import 'package:citas_medicas_app/core/error/excepciones.dart';
import 'package:citas_medicas_app/core/error/resultado.dart';
import 'package:citas_medicas_app/core/notificaciones/servicio_recordatorios.dart';
import 'package:citas_medicas_app/domain/entities/cita.dart';
import 'package:citas_medicas_app/domain/entities/cupo_disponible.dart';
import 'package:citas_medicas_app/domain/entities/estado_cita.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/repositories/cita_repository.dart';
import 'package:citas_medicas_app/domain/rules/rn06_rn07_rn08_gestion.dart';
import 'package:citas_medicas_app/presentation/viewmodels/mis_citas_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dobles_sesion.dart';

final _ahora = DateTime(2026, 9, 16, 10, 0);
DateTime _reloj() => _ahora;

const _paciente = Paciente(
  id: 'pac-1',
  tipoDocumento: TipoDocumento.dni,
  numeroDocumento: '12345678',
  nombres: 'Ana',
  apellidos: 'Ficticia',
  correo: 'ana@ejemplo.test',
  telefono: '999888777',
  consentimientoOtorgado: true,
);

Cita _cita({
  String id = 'cita-1',
  EstadoCita estado = EstadoCita.confirmada,
  required DateTime inicio,
}) =>
    Cita(
      id: id,
      pacienteId: 'pac-1',
      cupoId: 'cupo-$id',
      estado: estado,
      fechaCreacion: DateTime(2026, 9, 1),
      canalReserva: CanalReserva.flujoGuiado,
      especialidadId: 'esp-demo-01',
      profesionalId: 'prof-demo-01',
      fechaHoraInicio: inicio,
    );

/// Repositorio de citas controlado por el test.
class _CitasStub implements CitaRepository {
  _CitasStub(this.citas);

  List<Cita> citas;
  int vecesCancelar = 0;
  int vecesReprogramar = 0;
  FalloApp? falloAlCancelar;

  @override
  Future<Resultado<List<Cita>>> obtenerCitas({
    required String pacienteId,
    EstadoCita? estado,
  }) async =>
      Resultado<List<Cita>>.exito(citas);

  @override
  Future<Resultado<List<Cita>>> obtenerTodasLasCitas() async =>
      Resultado<List<Cita>>.exito(citas);

  @override
  Future<Resultado<Cita>> cancelar(String citaId) async {
    vecesCancelar++;
    if (falloAlCancelar != null) {
      return Resultado<Cita>.fallo(falloAlCancelar!);
    }
    final actualizada = citas
        .firstWhere((c) => c.id == citaId)
        .copyWith(estado: EstadoCita.cancelada);
    citas = citas.map((c) => c.id == citaId ? actualizada : c).toList();
    return Resultado<Cita>.exito(actualizada);
  }

  @override
  Future<Resultado<Cita>> reprogramar({
    required String citaId,
    required String nuevoCupoId,
  }) async {
    vecesReprogramar++;
    final actualizada = citas.firstWhere((c) => c.id == citaId).copyWith(
          estado: EstadoCita.reprogramada,
          cupoId: nuevoCupoId,
          fechaHoraInicio: _ahora.add(const Duration(days: 6)),
        );
    citas = citas.map((c) => c.id == citaId ? actualizada : c).toList();
    return Resultado<Cita>.exito(actualizada);
  }

  @override
  Future<Resultado<List<CupoDisponible>>> obtenerCupos({
    required String especialidadId,
    String? profesionalId,
    DateTime? fecha,
    TurnoDia? turno,
  }) async =>
      const Resultado<List<CupoDisponible>>.exito(<CupoDisponible>[]);

  @override
  Future<Resultado<Cita>> confirmarReserva({
    required String pacienteId,
    required String cupoId,
    required CanalReserva canal,
    required String claveIdempotencia,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Resultado<List<Cita>>> obtenerHistorialLocal(
    String pacienteId, {
    EstadoCita? estado,
  }) async =>
      Resultado<List<Cita>>.exito(citas);

  @override
  Future<Resultado<DateTime?>> obtenerFechaUltimaSincronizacion([
    String? pacienteId,
  ]) async =>
      Resultado<DateTime?>.exito(_ahora);
}

void main() {
  setUpAll(() => initializeDateFormatting(AppConfig.localeCompleto));

  late PreferenciasStub preferencias;
  late RecordatoriosEnConsola recordatorios;

  /// `restaurar()` es asincrono: sin esperarlo, el ViewModel todavia no tiene
  /// paciente y `cargar()` retorna sin hacer nada.
  Future<SesionViewModel> crearSesion({Paciente? paciente = _paciente}) async {
    final sesion = SesionViewModel(
      PacienteRepositoryStub(paciente: paciente),
      preferencias,
    );
    await sesion.restaurar();
    return sesion;
  }

  setUp(() {
    preferencias = PreferenciasStub();
    recordatorios = RecordatoriosEnConsola(preferencias, reloj: _reloj);
  });

  Future<MisCitasViewModel> crear(
    _CitasStub citas, {
    Paciente? paciente = _paciente,
  }) async =>
      MisCitasViewModel(
        citas,
        await crearSesion(paciente: paciente),
        recordatorios,
        reloj: _reloj,
      );

  group('HU-09 — separacion de proximas y anteriores', () {
    test('las activas van a proximas y el resto a anteriores', () async {
      final citas = _CitasStub(<Cita>[
        _cita(id: 'futura', inicio: _ahora.add(const Duration(days: 5))),
        _cita(
          id: 'cancelada',
          estado: EstadoCita.cancelada,
          inicio: _ahora.add(const Duration(days: 3)),
        ),
        _cita(
          id: 'atendida',
          estado: EstadoCita.atendida,
          inicio: _ahora.subtract(const Duration(days: 10)),
        ),
      ]);

      final vm = await crear(citas);
      await vm.cargar();

      expect(vm.proximas.map((c) => c.id), <String>['futura']);
      expect(
        vm.pasadas.map((c) => c.id).toSet(),
        <String>{'cancelada', 'atendida'},
      );
    });

    test('las proximas se ordenan de la mas cercana a la mas lejana',
        () async {
      final citas = _CitasStub(<Cita>[
        _cita(id: 'lejana', inicio: _ahora.add(const Duration(days: 10))),
        _cita(id: 'cercana', inicio: _ahora.add(const Duration(days: 2))),
        _cita(id: 'media', inicio: _ahora.add(const Duration(days: 5))),
      ]);

      final vm = await crear(citas);
      await vm.cargar();

      expect(
        vm.proximas.map((c) => c.id).toList(),
        <String>['cercana', 'media', 'lejana'],
      );
    });

    test('informa la fecha de la ultima sincronizacion', () async {
      final vm = await crear(_CitasStub(<Cita>[]));
      await vm.cargar();
      expect(vm.ultimaSincronizacion, _ahora);
    });
  });

  group('HU-07 y RN-06 — cancelar', () {
    test('con margen suficiente se puede cancelar', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      final citas = _CitasStub(<Cita>[cita]);
      final vm = await crear(citas);
      await vm.cargar();

      expect(vm.puedeCancelar(cita), isTrue);
      expect(await vm.cancelar(cita), isTrue);
      expect(citas.vecesCancelar, 1);
      expect(vm.pasadas.single.estado, EstadoCita.cancelada);
    });

    test('dentro del plazo de RN-06 no se puede, y no llega al repositorio',
        () async {
      final cita = _cita(inicio: _ahora.add(const Duration(hours: 2)));
      final citas = _CitasStub(<Cita>[cita]);
      final vm = await crear(citas);
      await vm.cargar();

      expect(vm.puedeCancelar(cita), isFalse);
      expect(await vm.cancelar(cita), isFalse);
      expect(
        citas.vecesCancelar,
        0,
        reason: 'RN-06 se comprueba antes de tocar el repositorio',
      );
      expect(vm.fallo, isA<FalloReglaNegocio>());
    });

    test('cancelar retira el recordatorio de esa cita (RN-07)', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      await recordatorios.programar(cita);
      expect(await recordatorios.programados(), hasLength(1));

      final vm = await crear(_CitasStub(<Cita>[cita]));
      await vm.cargar();
      await vm.cancelar(cita);

      expect(
        await recordatorios.programados(),
        isEmpty,
        reason: 'Una cita cancelada no debe seguir avisando',
      );
    });

    test('un fallo del repositorio deja la cita como estaba', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      final citas = _CitasStub(<Cita>[cita])
        ..falloAlCancelar = const FalloConexion();

      final vm = await crear(citas);
      await vm.cargar();

      expect(await vm.cancelar(cita), isFalse);
      expect(vm.proximas.single.estado, EstadoCita.confirmada);
      expect(vm.fallo, isA<FalloConexion>());
    });
  });

  group('RN-01 y RN-10 en la gestion', () {
    test('sin consentimiento vigente no se puede cancelar', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      final citas = _CitasStub(<Cita>[cita]);

      final vm = await crear(
        citas,
        paciente: _paciente.copyWith(consentimientoOtorgado: false),
      );
      await vm.cargar();

      expect(await vm.cancelar(cita), isFalse);
      expect(citas.vecesCancelar, 0);
    });

    test('sin sesion tampoco', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      final citas = _CitasStub(<Cita>[cita]);

      final vm = await crear(citas, paciente: null);
      await vm.cargar();

      expect(await vm.cancelar(cita), isFalse);
      expect(citas.vecesCancelar, 0);
    });
  });

  group('HU-07 — reprogramar', () {
    test('reprogramar reemplaza el recordatorio por el de la hora nueva',
        () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      await recordatorios.programar(cita);
      final original = (await recordatorios.programados()).single;

      final vm = await crear(_CitasStub(<Cita>[cita]));
      await vm.cargar();
      expect(
        await vm.reprogramar(cita: cita, nuevoCupoId: 'cupo-nuevo'),
        isTrue,
      );

      final vigentes = await recordatorios.programados();
      expect(vigentes, hasLength(1));
      expect(
        vigentes.single.momento,
        isNot(original.momento),
        reason: 'El recordatorio anterior apuntaba a una hora que ya no existe',
      );
    });

    test('dentro del plazo de RN-06 no se puede reprogramar', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(hours: 2)));
      final citas = _CitasStub(<Cita>[cita]);
      final vm = await crear(citas);
      await vm.cargar();

      expect(vm.puedeReprogramar(cita), isFalse);
      expect(
        await vm.reprogramar(cita: cita, nuevoCupoId: 'cupo-nuevo'),
        isFalse,
      );
      expect(citas.vecesReprogramar, 0);
    });
  });

  group('HU-08 — recordatorios', () {
    test('el permiso se pide una sola vez', () async {
      expect(await recordatorios.asegurarPermiso(), isTrue);
      expect(
        (await preferencias.obtenerPermisoNotificacionesSolicitado())
            .valorONull,
        isTrue,
      );

      // Segunda llamada: ya estaba concedido, no se vuelve a pedir.
      expect(await recordatorios.asegurarPermiso(), isTrue);
    });

    test('el recordatorio se programa M horas antes (RN-07)', () async {
      final cita = _cita(inicio: DateTime(2026, 9, 20, 9, 0));
      final programado = await recordatorios.programar(cita);

      expect(programado, isNotNull);
      expect(
        programado!.momento,
        DateTime(2026, 9, 20, 9, 0)
            .subtract(Duration(hours: AppConfig.horasAntelacionRecordatorio)),
      );
      expect(programado.cuerpo, contains('20/09/2026'));
    });

    test('una cita demasiado proxima no genera recordatorio', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(hours: 1)));
      expect(await recordatorios.programar(cita), isNull);
      expect(await recordatorios.programados(), isEmpty);
    });
  });

  group('Motivo del bloqueo', () {
    test('explica por que no se puede gestionar', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(hours: 2)));
      final vm = await crear(_CitasStub(<Cita>[cita]));
      await vm.cargar();

      final motivo = vm.motivoBloqueo(cita, AccionAutogestion.cancelar);
      expect(motivo, isNotNull);
      expect(motivo, contains('horas antes'));
    });

    test('devuelve null cuando si se puede', () async {
      final cita = _cita(inicio: _ahora.add(const Duration(days: 5)));
      final vm = await crear(_CitasStub(<Cita>[cita]));
      await vm.cargar();

      expect(vm.motivoBloqueo(cita, AccionAutogestion.cancelar), isNull);
    });
  });
}
