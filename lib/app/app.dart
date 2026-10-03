import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../l10n/cadenas.dart';
import '../presentation/viewmodels/tema_viewmodel.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Raiz de la aplicacion: tema, localizacion y tabla de rutas.
class CitasMedicasApp extends StatelessWidget {
  const CitasMedicasApp({super.key});

  /// Restriccion 7: la interfaz es en espanol de Peru.
  static const Locale localePrincipal = Locale(
    AppConfig.codigoIdioma,
    AppConfig.codigoPais,
  );

  @override
  Widget build(BuildContext context) {
    // RNF-03: `select` acotado — la aplicacion se reconstruye solo cuando
    // cambia el modo de tema, no ante cualquier cambio del ViewModel.
    final modo = context.select<TemaViewModel, ThemeMode>((vm) => vm.modo);

    return MaterialApp(
      title: Cadenas.nombreApp,
      debugShowCheckedModeBanner: false,

      // ODS 12 (decision 5): tema oscuro disponible; `ThemeMode.system` es el
      // valor por defecto, de modo que se respeta la preferencia del sistema
      // mientras el paciente no elija otra cosa.
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      themeMode: modo,

      locale: localePrincipal,
      // Con `material_ui` los delegados de localizacion ya no vienen de
      // `flutter_localizations`: se toman del propio paquete.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const <Locale>[
        localePrincipal,
        Locale(AppConfig.codigoIdioma),
      ],

      // La raiz no es la pantalla de inicio sino la puerta de entrada, que
      // decide entre inicio de sesion e inicio segun RN-01.
      initialRoute: Rutas.raiz,
      routes: AppRouter.rutas,
      onUnknownRoute: AppRouter.rutaDesconocida,

      builder: (context, child) {
        // RNF-04: la interfaz debe soportar el escalado de fuente del sistema
        // sin romperse. Se acepta hasta el doble del tamano base; por encima
        // de ahi los textos largos desbordan las tarjetas, asi que se acota
        // en lugar de ignorar la preferencia del usuario.
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 2.0,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
