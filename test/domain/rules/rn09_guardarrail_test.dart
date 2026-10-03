import 'package:citas_medicas_app/domain/rules/rn09_guardarrail_clinico.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RN-09 — deriva ante sintomas', () {
    const mensajesConSintomas = <String>[
      'me duele la cabeza',
      'tengo dolor de estomago',
      'tengo fiebre desde ayer',
      'me siento mal',
      'tengo tos y gripe',
      'estoy mareado',
      'me salio una roncha en el brazo',
      'tengo mucha ansiedad',
      'me arde al orinar',
      'siento un ahogo al caminar',
      'Tengo DOLOR de espalda',
      'tengo dolór de muela',
    ];

    for (final mensaje in mensajesConSintomas) {
      test('deriva: "$mensaje"', () {
        expect(
          Rn09GuardarrailClinico.requiereDerivacion(mensaje),
          isTrue,
          reason: 'RN-09 exige derivar ante la descripcion de un sintoma',
        );
      });
    }
  });

  group('RN-09 — deriva ante peticiones de orientacion clinica', () {
    const peticiones = <String>[
      'que tengo doctor',
      'que especialista necesito',
      'a que especialista debo ir',
      'que me recomiendas',
      'sera grave lo mio',
      'que medicamento debo tomar',
      'necesito un diagnostico',
    ];

    for (final mensaje in peticiones) {
      test('deriva: "$mensaje"', () {
        expect(Rn09GuardarrailClinico.requiereDerivacion(mensaje), isTrue);
      });
    }
  });

  group('RN-09 — no deriva ante gestiones normales', () {
    const gestiones = <String>[
      'quiero reservar una cita',
      'necesito una cita para manana',
      'quiero cancelar mi cita del jueves',
      'reprogramar mi cita para la proxima semana',
      'cuando es mi proxima cita',
      'quiero una cita de Medicina General',
      'todos los horarios me sirven',
      'agendar para el lunes por la tarde',
    ];

    for (final mensaje in gestiones) {
      test('no deriva: "$mensaje"', () {
        expect(
          Rn09GuardarrailClinico.requiereDerivacion(mensaje),
          isFalse,
          reason: 'Una gestion normal no debe derivarse al canal de atencion',
        );
      });
    }
  });

  group('RN-09 — deteccion por palabra completa', () {
    test('"todos" no dispara por contener "tos"', () {
      expect(
        Rn09GuardarrailClinico.requiereDerivacion('todos los dias me sirven'),
        isFalse,
      );
    });

    test('"tos" suelta si dispara', () {
      expect(Rn09GuardarrailClinico.requiereDerivacion('tengo tos'), isTrue);
    });
  });

  test('normalizar quita tildes y pasa a minusculas', () {
    expect(Rn09GuardarrailClinico.normalizar('DOLÓR de Cabéza'),
        'dolor de cabeza');
  });
}
