import 'package:material_ui/material_ui.dart';

/// Paleta de la aplicacion.
///
/// RNF-04 — WCAG 2.1 nivel AA. Los ratios de contraste indicados se
/// calcularon con la formula de luminancia relativa de la WCAG
/// (https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio). El minimo exigido para
/// texto normal es 4.5:1; ninguna combinacion usada en la interfaz baja de
/// ese valor.
class AppColors {
  const AppColors._();

  // -------------------------------------------------------------------
  // Tema claro
  // -------------------------------------------------------------------

  /// Azul institucional. Blanco sobre este color da 6.49:1.
  static const Color primarioClaro = Color(0xFF00629E);
  static const Color sobrePrimarioClaro = Color(0xFFFFFFFF);

  static const Color contenedorPrimarioClaro = Color(0xFFCFE5FF);
  static const Color sobreContenedorPrimarioClaro = Color(0xFF001D33);

  static const Color secundarioClaro = Color(0xFF00696D);
  static const Color sobreSecundarioClaro = Color(0xFFFFFFFF);

  static const Color superficieClara = Color(0xFFFCFCFF);

  /// 16.1:1 sobre [superficieClara].
  static const Color sobreSuperficieClara = Color(0xFF1A1C1E);

  static const Color superficieVarianteClara = Color(0xFFDEE3EB);

  /// Texto secundario: 9.33:1 sobre [superficieClara].
  static const Color sobreSuperficieVarianteClara = Color(0xFF43474E);

  /// 6.46:1 sobre [superficieClara].
  static const Color errorClaro = Color(0xFFBA1A1A);
  static const Color sobreErrorClaro = Color(0xFFFFFFFF);

  static const Color bordeClaro = Color(0xFF73777F);

  // -------------------------------------------------------------------
  // Tema oscuro (ODS 12: menor consumo en pantallas OLED)
  // -------------------------------------------------------------------

  /// 10.8:1 sobre [superficieOscura].
  static const Color primarioOscuro = Color(0xFF9CCAFF);

  /// 7.7:1 respecto de [primarioOscuro].
  static const Color sobrePrimarioOscuro = Color(0xFF003258);

  static const Color contenedorPrimarioOscuro = Color(0xFF004A78);
  static const Color sobreContenedorPrimarioOscuro = Color(0xFFCFE5FF);

  static const Color secundarioOscuro = Color(0xFF4CDADE);
  static const Color sobreSecundarioOscuro = Color(0xFF003738);

  static const Color superficieOscura = Color(0xFF121417);

  /// 14.3:1 sobre [superficieOscura].
  static const Color sobreSuperficieOscura = Color(0xFFE2E2E5);

  static const Color superficieVarianteOscura = Color(0xFF42474E);

  /// 8.9:1 sobre [superficieOscura].
  static const Color sobreSuperficieVarianteOscura = Color(0xFFC2C7CF);

  /// 6.9:1 sobre [superficieOscura].
  static const Color errorOscuro = Color(0xFFFFB4AB);
  static const Color sobreErrorOscuro = Color(0xFF690005);

  static const Color bordeOscuro = Color(0xFF8C9199);

  // -------------------------------------------------------------------
  // Colores de estado de una cita. Se usan siempre acompanados de texto,
  // nunca como unico portador de informacion (WCAG 1.4.1).
  // -------------------------------------------------------------------

  static const Color confirmadaClaro = Color(0xFF1B5E20);
  static const Color confirmadaOscuro = Color(0xFF7ADE86);
  static const Color pendienteClaro = Color(0xFF8A5100);
  static const Color pendienteOscuro = Color(0xFFFFB95C);
}
