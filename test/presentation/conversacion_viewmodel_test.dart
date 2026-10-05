import 'package:citas_medicas_app/core/config/app_config.dart';
import 'package:citas_medicas_app/core/error/resultado.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_asistente_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_catalogo_datasource.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_cita_datasource.dart';
import 'package:citas_medicas_app/data/repositories/asistente_repository_impl.dart';
import 'package:citas_medicas_app/data/repositories/catalogo_repository_impl.dart';
import 'package:citas_medicas_app/data/repositories/cita_repository_impl.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/domain/entities/mensaje_conversacion.dart';
import 'package:citas_medicas_app/domain/entities/paciente.dart';
import 'package:citas_medicas_app/domain/repositories/asistente_repository.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/viewmodels/conversacion_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/reserva_viewmodel.dart';
import 'package:citas_medicas_app/presentation/viewmodels/sesion_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dobles_sesion.dart';

/// Asistente que siempre devuelve la misma respuesta, para probar el
/// comportamiento del ViewModel con independencia del reconocedor.
class _AsistenteFijo implements AsistenteRepository {
  _AsistenteFijo(this.respuesta);

  RespuestaAsistente respuesta;
  int llamadas = 0;
  String? ultimoTexto;

  @override
  Future<Resultado<RespuestaAsistente>> analizarMensaje({
    required String texto,
    required String idConversacion,
  }) async {
    llamadas++;
    ultimoTexto = texto;
    return Resultado<RespuestaAsistente>.exito(respuesta);
  }
}

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

void main() {
  final ahora = DateTime(2026, 9, 16, 10, 0);
  DateTime reloj() => ahora;

  setUpAll(() => initializeDateFormatting(AppConfig.localeCompleto));

  ReservaViewModel crearReserva() => ReservaViewModel(
        const CatalogoRepositoryImpl(
          FakeCatalogoDataSource(latencia: Duration.zero),
        ),
        CitaRepositoryImpl(
          FakeCitaDataSource(latencia: Duration.zero, reloj: reloj),
          reloj: reloj,
        ),
        SesionViewModel(
          PacienteRepositoryStub(paciente: _paciente),
          PreferenciasStub(),
        )..restaurar(),
        reloj: reloj,
      );

  group('Umbral de confianza', () {
    test('por debajo del umbral pide reformulacion y NO ejecuta accion',
        () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: 0.50,
          respuesta: '',
          entidades: <String, String>{'especialidad': 'esp-demo-01'},
        ),
      );
      final reserva = crearReserva();
      final vm = ConversacionViewModel(asistente, reserva, reloj: reloj);

      await vm.enviar('reservar');

      expect(vm.mensajes.last.texto, Cadenas.asistenteConfianzaBaja);
      expect(vm.intentosFallidos, 1);
      expect(
        reserva.especialidad,
        isNull,
        reason: 'Por debajo del umbral no se debe aplicar ninguna entidad',
      );
    });

    test('justo en el umbral si se actua', () async {
      final asistente = _AsistenteFijo(
        RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: AppConfig.umbralConfianza,
          respuesta: '',
          entidades: <String, String>{
            'especialidad': 'esp-demo-01',
            'fecha': DateTime(2026, 9, 18).toIso8601String(),
          },
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('quiero una cita');

      expect(vm.intentosFallidos, 0);
      expect(vm.fechaPorConfirmar, DateTime(2026, 9, 18));
    });
  });

  group('Fallback obligatorio (HU-04)', () {
    test('tras dos intentos fallidos se ofrece el flujo guiado', () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.noReconocida,
          confianza: 0.0,
          respuesta: '',
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('askjdhaksjd');
      expect(vm.debeOfrecerFlujoGuiado, isFalse);

      await vm.enviar('qwertyuiop');
      expect(
        vm.debeOfrecerFlujoGuiado,
        isTrue,
        reason: 'La seccion 8 exige ofrecer el menu tras '
            '${AppConfig.intentosAntesDeFlujoGuiado} intentos fallidos',
      );
      expect(
        vm.mensajes.last.texto,
        Cadenas.asistenteOfrecerFlujoGuiado,
      );
    });

    test('un acierto reinicia el contador de fallos', () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.noReconocida,
          confianza: 0.0,
          respuesta: '',
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('askjdhaksjd');
      expect(vm.intentosFallidos, 1);

      asistente.respuesta = const RespuestaAsistente(
        intencion: IntencionAsistente.reservar,
        confianza: 0.95,
        respuesta: '',
        entidades: <String, String>{},
      );
      await vm.enviar('quiero reservar una cita');

      expect(vm.intentosFallidos, 0);
      expect(vm.debeOfrecerFlujoGuiado, isFalse);
    });

    test('el ofrecimiento no se repite en la misma racha', () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.noReconocida,
          confianza: 0.0,
          respuesta: '',
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('aaa');
      await vm.enviar('bbb');
      final conDosFallos = vm.mensajes
          .where((m) => m.texto == Cadenas.asistenteOfrecerFlujoGuiado)
          .length;

      await vm.enviar('ccc');
      final conTresFallos = vm.mensajes
          .where((m) => m.texto == Cadenas.asistenteOfrecerFlujoGuiado)
          .length;

      expect(conDosFallos, 1);
      expect(conTresFallos, 1);
    });
  });

  group('RN-09 desde la conversacion', () {
    test('la derivacion no cuenta como intento fallido', () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.noReconocida,
          confianza: 1.0,
          respuesta: Cadenas.derivacionCanalAtencion,
          derivadoACanalAtencion: true,
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('me duele la cabeza');

      expect(vm.mensajes.last.texto, Cadenas.derivacionCanalAtencion);
      expect(
        vm.intentosFallidos,
        0,
        reason: 'El asistente entendio: simplemente no le corresponde responder',
      );
    });

    test('el texto con sintomas no sale del dispositivo', () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: 0.9,
          respuesta: '',
        ),
      );
      final repositorio = AsistenteRepositoryImpl(
        const FakeAsistenteDataSource(latencia: Duration.zero),
      );
      final vm = ConversacionViewModel(repositorio, crearReserva(), reloj: reloj);

      await vm.enviar('tengo fiebre y dolor de cabeza');

      expect(
        asistente.llamadas,
        0,
        reason: 'RN-09 se resuelve antes de enviar nada al motor',
      );
      expect(vm.mensajes.last.texto, Cadenas.derivacionCanalAtencion);
    });
  });

  group('Confirmacion de la fecha interpretada', () {
    test('siempre se muestra la fecha resuelta antes de actuar', () async {
      final asistente = _AsistenteFijo(
        RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: 0.9,
          respuesta: '',
          entidades: <String, String>{
            'especialidad': 'esp-demo-01',
            'fecha': DateTime(2026, 9, 18).toIso8601String(),
            'fecha_expresion': 'el viernes',
          },
        ),
      );
      final reserva = crearReserva();
      await reserva.iniciar();
      final vm = ConversacionViewModel(asistente, reserva, reloj: reloj);

      await vm.enviar('cita Medicina General el viernes');

      expect(vm.fechaPorConfirmar, DateTime(2026, 9, 18));
      expect(vm.mensajes.last.texto, contains(Cadenas.asistenteConfirmaFecha));
      expect(
        reserva.fecha,
        isNull,
        reason: 'La fecha no se aplica hasta que el paciente la confirma',
      );

      await vm.confirmarFecha();
      expect(reserva.fecha, DateTime(2026, 9, 18));
      expect(vm.listoParaHorarios, isTrue);
    });

    test('rechazar la fecha vuelve a preguntar y no la aplica', () async {
      final asistente = _AsistenteFijo(
        RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: 0.9,
          respuesta: '',
          entidades: <String, String>{
            'especialidad': 'esp-demo-01',
            'fecha': DateTime(2026, 9, 18).toIso8601String(),
          },
        ),
      );
      final reserva = crearReserva();
      final vm = ConversacionViewModel(asistente, reserva, reloj: reloj);

      await vm.enviar('cita el viernes');
      vm.rechazarFecha();

      expect(vm.fechaPorConfirmar, isNull);
      expect(vm.mensajes.last.texto, Cadenas.asistenteFaltaFecha);
      expect(reserva.fecha, isNull);
    });
  });

  group('Datos incompletos', () {
    test('sin especialidad, el asistente la pide', () async {
      final asistente = _AsistenteFijo(
        RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: 0.9,
          respuesta: '',
          entidades: <String, String>{
            'fecha': DateTime(2026, 9, 18).toIso8601String(),
          },
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('quiero una cita manana');
      expect(vm.mensajes.last.texto, Cadenas.asistenteFaltaEspecialidad);
    });

    test('sin fecha, el asistente la pide', () async {
      final asistente = _AsistenteFijo(
        const RespuestaAsistente(
          intencion: IntencionAsistente.reservar,
          confianza: 0.9,
          respuesta: '',
          entidades: <String, String>{'especialidad': 'esp-demo-01'},
        ),
      );
      final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

      await vm.enviar('quiero cita de Medicina General');
      expect(vm.mensajes.last.texto, Cadenas.asistenteFaltaFecha);
    });
  });

  group('Relleno con contexto (memoria de la conversacion)', () {
    // Se usa el reconocedor real para ejercitar la extraccion desde el texto.
    ConversacionViewModel crearConReal(ReservaViewModel reserva) =>
        ConversacionViewModel(
          AsistenteRepositoryImpl(
            // El reloj se inyecta para que «manana» sea determinista.
            FakeAsistenteDataSource(latencia: Duration.zero, ahora: reloj),
          ),
          reserva,
          reloj: reloj,
        );

    test('el escenario del paciente: "quiero una cita" -> especialidad -> dia',
        () async {
      final reserva = crearReserva();
      await reserva.iniciar();
      final vm = crearConReal(reserva);

      await vm.enviar('quiero una cita');
      expect(
        vm.mensajes.last.texto,
        Cadenas.asistenteFaltaEspecialidad,
        reason: 'Una peticion clara debe avanzar a preguntar la especialidad',
      );
      expect(vm.espera, EsperaAsistente.especialidad);

      await vm.enviar('medicina general');
      expect(
        vm.mensajes.last.texto,
        Cadenas.asistenteFaltaFecha,
        reason: 'La respuesta se interpreta como especialidad, sin reclasificar',
      );
      expect(vm.espera, EsperaAsistente.fecha);

      await vm.enviar('manana');
      expect(vm.fechaPorConfirmar, DateTime(2026, 9, 17));
      expect(vm.espera, EsperaAsistente.nada);
    });

    test('tolera un sinonimo como respuesta de especialidad', () async {
      final reserva = crearReserva();
      await reserva.iniciar();
      final vm = crearConReal(reserva);

      await vm.enviar('quiero una cita');
      await vm.enviar('pediatra');

      expect(vm.mensajes.last.texto, Cadenas.asistenteFaltaFecha);
    });

    test('si no reconoce el dato, repregunta y cuenta como intento fallido',
        () async {
      final reserva = crearReserva();
      await reserva.iniciar();
      final vm = crearConReal(reserva);

      await vm.enviar('quiero una cita');
      expect(vm.intentosFallidos, 0);

      await vm.enviar('aaaaa');
      expect(vm.mensajes.last.texto, Cadenas.asistenteNoReconociEspecialidad);
      expect(vm.intentosFallidos, 1);

      await vm.enviar('bbbbb');
      expect(
        vm.debeOfrecerFlujoGuiado,
        isTrue,
        reason: 'El fallback al flujo guiado sigue vivo durante el relleno',
      );
    });

    test('RN-09 gana aunque se este rellenando', () async {
      final reserva = crearReserva();
      await reserva.iniciar();
      final vm = crearConReal(reserva);

      await vm.enviar('quiero una cita');
      expect(vm.espera, EsperaAsistente.especialidad);

      await vm.enviar('me duele la cabeza');

      expect(vm.mensajes.last.texto, Cadenas.derivacionCanalAtencion);
      expect(
        vm.espera,
        EsperaAsistente.nada,
        reason: 'La derivacion corta el relleno; no se mezclan sintomas',
      );
    });
  });

  test('RNF-10: al motor no se le envia identificador de paciente', () async {
    final asistente = _AsistenteFijo(
      const RespuestaAsistente(
        intencion: IntencionAsistente.reservar,
        confianza: 0.9,
        respuesta: '',
      ),
    );
    final vm = ConversacionViewModel(asistente, crearReserva(), reloj: reloj);

    await vm.enviar('quiero reservar una cita');

    expect(asistente.ultimoTexto, 'quiero reservar una cita');
    expect(asistente.ultimoTexto, isNot(contains(_paciente.numeroDocumento)));
    expect(asistente.ultimoTexto, isNot(contains(_paciente.id)));
  });
}
