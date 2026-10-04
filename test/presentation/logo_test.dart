import 'package:citas_medicas_app/app/theme/app_theme.dart';
import 'package:citas_medicas_app/l10n/cadenas.dart';
import 'package:citas_medicas_app/presentation/widgets/logo_clinica.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _envolver(Widget hijo) => MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(body: hijo),
    );

void main() {
  group('LogoClinica', () {
    testWidgets('ocupa el alto pedido', (tester) async {
      await tester.pumpWidget(_envolver(const LogoClinica(alto: 120)));
      await tester.pumpAndSettle();

      final tamano = tester.getSize(find.byType(LogoClinica));
      expect(tamano.height, 120);
    });

    testWidgets('el logo es decorativo y no anade ruido al lector de pantalla',
        (tester) async {
      // `dispose` va dentro del test: el propio framework verifica que no
      // queden handles abiertos antes de ejecutar los tearDown.
      final semantica = tester.ensureSemantics();

      await tester.pumpWidget(_envolver(const LogoClinica()));
      await tester.pumpAndSettle();

      // Si el logo fuese anunciable, produciria algun nodo con etiqueta.
      expect(
        find.bySemanticsLabel(RegExp('.+')),
        findsNothing,
        reason: 'Un logo decorativo no debe anunciarse antes del formulario',
      );

      semantica.dispose();
    });

    testWidgets('no crece con el escalado de fuente del sistema',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: _envolver(const LogoClinica(alto: 96)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(LogoClinica)).height, 96);
    });
  });

  group('CabeceraConLogo', () {
    testWidgets('muestra logo, titulo y subtitulo', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const CabeceraConLogo(
            titulo: 'Iniciar sesion',
            subtitulo: 'Ingresa con tu documento.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LogoClinica), findsOneWidget);
      expect(find.text('Iniciar sesion'), findsOneWidget);
      expect(find.text('Ingresa con tu documento.'), findsOneWidget);
    });

    testWidgets('el alto del logo es configurable por pantalla',
        (tester) async {
      await tester.pumpWidget(
        _envolver(
          const CabeceraConLogo(
            titulo: 'Crear cuenta',
            subtitulo: 'Datos para reservar.',
            altoLogo: 64,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(LogoClinica)).height, 64);
    });
  });

  testWidgets('PieDemostracion avisa de que los datos son ficticios',
      (tester) async {
    await tester.pumpWidget(_envolver(const PieDemostracion()));
    await tester.pumpAndSettle();

    expect(find.text(Cadenas.avisoDatosFicticios), findsOneWidget);
  });
}
