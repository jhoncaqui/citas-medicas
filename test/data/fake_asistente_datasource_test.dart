import 'package:citas_medicas_app/core/config/app_config.dart';
import 'package:citas_medicas_app/data/datasources/fake/fake_asistente_datasource.dart';
import 'package:citas_medicas_app/domain/entities/intencion_asistente.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Miercoles 16 de setiembre de 2026.
  final ahora = DateTime(2026, 9, 16, 10, 0);

  group('Clasificacion de intenciones', () {
    test('reconoce reservar', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero reservar una cita de Medicina General para manana',
        ahora: ahora,
      );
      expect(r.intencion, IntencionAsistente.reservar.clave);
    });

    test('reconoce consultar', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero ver mis citas',
        ahora: ahora,
      );
      expect(r.intencion, IntencionAsistente.consultar.clave);
    });

    test('reconoce reprogramar', () {
      final r = FakeAsistenteDataSource.analizar(
        'necesito reprogramar mi cita',
        ahora: ahora,
      );
      expect(r.intencion, IntencionAsistente.reprogramar.clave);
    });

    test('reconoce cancelar', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero cancelar mi cita',
        ahora: ahora,
      );
      expect(r.intencion, IntencionAsistente.cancelar.clave);
    });

    test('un texto sin relacion no se reconoce y la confianza es cero', () {
      final r = FakeAsistenteDataSource.analizar(
        'el clima esta muy bonito hoy',
        ahora: ahora,
      );
      expect(r.intencion, IntencionAsistente.noReconocida.clave);
      expect(r.confianza, 0.0);
      expect(r.respuesta, Cadenas.asistenteNoEntendi);
    });
  });

  group('Umbral de confianza', () {
    test('una sola senal no alcanza el umbral y no ejecuta accion', () {
      final r = FakeAsistenteDataSource.analizar('reservar', ahora: ahora);
      expect(r.intencion, IntencionAsistente.reservar.clave);
      expect(
        r.confianza,
        lessThan(AppConfig.umbralConfianza),
        reason: 'Sin entidades, «reservar» a secas debe pedir precision',
      );
    });

    test('con especialidad y fecha se supera el umbral', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero reservar una cita de Medicina General para manana',
        ahora: ahora,
      );
      expect(r.confianza, greaterThanOrEqualTo(AppConfig.umbralConfianza));
    });
  });

  group('Extraccion de entidades', () {
    test('extrae especialidad, fecha y turno', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero una cita de Medicina General el viernes por la tarde',
        ahora: ahora,
      );
      expect(r.entidades['especialidad'], 'esp-demo-01');
      expect(r.entidades['fecha'], DateTime(2026, 9, 18).toIso8601String());
      expect(r.entidades['turno'], TurnoDia.tarde.clave);
    });

    test('conserva la expresion original de la fecha', () {
      final r = FakeAsistenteDataSource.analizar(
        'reservar cita Medicina General pasado manana',
        ahora: ahora,
      );
      expect(r.entidades['fecha_expresion'], 'pasado manana');
      expect(r.entidades['fecha'], DateTime(2026, 9, 18).toIso8601String());
    });

    test('no extrae especialidades inactivas', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero cita de Dermatologia manana',
        ahora: ahora,
      );
      expect(r.entidades.containsKey('especialidad'), isFalse);
    });

    test('extrae la hora cuando se indica', () {
      final r = FakeAsistenteDataSource.analizar(
        'reservar Medicina General manana a las 10:30',
        ahora: ahora,
      );
      expect(r.entidades['hora'], '10:30');
    });
  });

  group('RN-09 — guardarrail clinico', () {
    test('un mensaje con sintomas se deriva al canal de atencion', () {
      final r = FakeAsistenteDataSource.analizar(
        'me duele mucho la cabeza, quiero una cita',
        ahora: ahora,
      );
      expect(r.derivadoACanalAtencion, isTrue);
      expect(r.respuesta, Cadenas.derivacionCanalAtencion);
    });

    test('la derivacion NO sugiere ninguna especialidad', () {
      final r = FakeAsistenteDataSource.analizar(
        'tengo dolor de estomago, que especialista necesito',
        ahora: ahora,
      );
      expect(r.derivadoACanalAtencion, isTrue);
      expect(
        r.entidades.containsKey('especialidad'),
        isFalse,
        reason: 'RN-09 prohibe recomendar especialidad con criterio clinico',
      );
      expect(r.intencion, IntencionAsistente.noReconocida.clave);
    });

    test('el guardarrail gana sobre la intencion de reservar', () {
      final r = FakeAsistenteDataSource.analizar(
        'quiero reservar una cita de Medicina General porque tengo fiebre',
        ahora: ahora,
      );
      expect(r.derivadoACanalAtencion, isTrue);
    });
  });

  test('la fuente falsa devuelve la misma forma que el contrato remoto',
      () async {
    const fuente = FakeAsistenteDataSource(latencia: Duration.zero);
    final dto = await fuente.analizarMensaje(
      texto: 'quiero reservar una cita',
      idConversacion: 'conv-1',
    );
    // El mapeo a dominio debe funcionar sin conocer el origen.
    final dominio = dto.aDominio();
    expect(dominio.intencion, isA<IntencionAsistente>());
    expect(dominio.confianza, isA<double>());
  });
}
