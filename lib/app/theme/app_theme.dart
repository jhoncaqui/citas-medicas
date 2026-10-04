import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Temas claro y oscuro.
///
/// - ODS 12 (decision 5): el tema oscuro existe y respeta la preferencia del
///   sistema.
/// - RNF-04: area tactil minima de 48 dp en todo control interactivo y
///   tipografia que escala con la preferencia del sistema.
class AppTheme {
  const AppTheme._();

  /// RNF-04 — area tactil minima exigida por WCAG 2.1 AA.
  static const double areaTactilMinima = 48.0;

  static const Size _tamanoMinimoBoton = Size(64, areaTactilMinima);

  static ThemeData get claro => _construir(_esquemaClaro);
  static ThemeData get oscuro => _construir(_esquemaOscuro);

  static const ColorScheme _esquemaClaro = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primarioClaro,
    onPrimary: AppColors.sobrePrimarioClaro,
    primaryContainer: AppColors.contenedorPrimarioClaro,
    onPrimaryContainer: AppColors.sobreContenedorPrimarioClaro,
    secondary: AppColors.secundarioClaro,
    onSecondary: AppColors.sobreSecundarioClaro,
    error: AppColors.errorClaro,
    onError: AppColors.sobreErrorClaro,
    surface: AppColors.superficieClara,
    onSurface: AppColors.sobreSuperficieClara,
    surfaceContainerHighest: AppColors.superficieVarianteClara,
    onSurfaceVariant: AppColors.sobreSuperficieVarianteClara,
    outline: AppColors.bordeClaro,
  );

  static const ColorScheme _esquemaOscuro = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primarioOscuro,
    onPrimary: AppColors.sobrePrimarioOscuro,
    primaryContainer: AppColors.contenedorPrimarioOscuro,
    onPrimaryContainer: AppColors.sobreContenedorPrimarioOscuro,
    secondary: AppColors.secundarioOscuro,
    onSecondary: AppColors.sobreSecundarioOscuro,
    error: AppColors.errorOscuro,
    onError: AppColors.sobreErrorOscuro,
    surface: AppColors.superficieOscura,
    onSurface: AppColors.sobreSuperficieOscura,
    surfaceContainerHighest: AppColors.superficieVarianteOscura,
    onSurfaceVariant: AppColors.sobreSuperficieVarianteOscura,
    outline: AppColors.bordeOscuro,
  );

  static ThemeData _construir(ColorScheme esquema) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: esquema.surface,

      // RNF-04: ningun control interactivo por debajo de 48 dp.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _tamanoMinimoBoton,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _tamanoMinimoBoton,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
          side: BorderSide(color: esquema.outline),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: _tamanoMinimoBoton),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(areaTactilMinima),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: esquema.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: esquema.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: esquema.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
      ),

      dividerTheme: DividerThemeData(color: esquema.outline, thickness: 0.5),
    );
  }
}
