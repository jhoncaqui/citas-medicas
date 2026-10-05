import 'package:citas_medicas_app/core/voz/servicio_dictado.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/widgets/boton_dictado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Doble de prueba del dictado: no toca ningun motor de voz real.
class _DictadoFake implements ServicioDictado {
  _DictadoFake({this.disponibleTrasInit = true});

  final bool disponibleTrasInit;
  bool _disp = false;
  bool _esc = false;
  int vecesEscuchar = 0;

  void Function(String, bool)? _alTranscribir;
  void Function()? _alTerminar;

  @override
  bool get disponible => _disp;

  @override
  bool get escuchando => _esc;

  @override
  Future<bool> inicializar() async {
    _disp = disponibleTrasInit;
    return _disp;
  }

  @override
  Future<void> escuchar({
    required String localeId,
    required void Function(String texto, bool definitivo) alTranscribir,
    void Function()? alTerminar,
    void Function(String mensaje)? alFallar,
  }) async {
    vecesEscuchar++;
    _esc = true;
    _alTranscribir = alTranscribir;
    _alTerminar = alTerminar;
  }

  @override
  Future<void> detener() async {
    _esc = false;
    _alTerminar?.call();
  }

  @override
  Future<void> cancelar() async => _esc = false;

  // Ayudas para el test:
  void emitir(String texto, {bool definitivo = false}) =>
      _alTranscribir?.call(texto, definitivo);
  void terminar() => _alTerminar?.call();
}

Widget _montar(ServicioDictado servicio, {required ValueChanged<String> onTexto}) =>
    MaterialApp(
      home: Scaffold(
        body: Provider<ServicioDictado>.value(
          value: servicio,
          child: BotonDictado(onTexto: onTexto),
        ),
      ),
    );

void main() {
  testWidgets('muestra el microfono y dicta el texto reconocido en el campo',
      (tester) async {
    final fake = _DictadoFake();
    String? capturado;

    await tester.pumpWidget(_montar(fake, onTexto: (t) => capturado = t));

    expect(find.byIcon(Icons.mic), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(fake.vecesEscuchar, 1);
    // Mientras escucha, el icono cambia a detener.
    expect(find.byIcon(Icons.stop), findsOneWidget);

    fake.emitir('quiero una cita');
    await tester.pump();
    expect(capturado, 'quiero una cita');

    // Al terminar por si solo, vuelve al microfono.
    fake.terminar();
    await tester.pump();
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('si el dictado no esta disponible, avisa y no escucha',
      (tester) async {
    final fake = _DictadoFake(disponibleTrasInit: false);

    await tester.pumpWidget(_montar(fake, onTexto: (_) {}));

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(fake.vecesEscuchar, 0);
    expect(find.text(Cadenas.dictadoNoDisponible), findsOneWidget);
  });

  testWidgets('tocar de nuevo mientras escucha detiene el dictado',
      (tester) async {
    final fake = _DictadoFake();

    await tester.pumpWidget(_montar(fake, onTexto: (_) {}));

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(fake.escuchando, isTrue);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(fake.escuchando, isFalse);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
