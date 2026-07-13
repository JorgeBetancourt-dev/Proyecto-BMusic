import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores tomada directamente del mockup HTML.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1B1420);
  static const surface = Color(0xFF251A2B);
  static const surface2 = Color(0xFF2E2033);
  static const amber = Color(0xFFE8A33D);
  static const terracotta = Color(0xFFC1443C);
  static const cream = Color(0xFFF5EDE4);
  static const mauve = Color(0xFF9C8FA0);
  static const background = Color(0xFF0E0912);
  static const line = Color(0x1AF5EDE4); // rgba(245,237,228,0.10)
}

/// Radios y constantes de layout reutilizables.
class AppRadius {
  AppRadius._();

  static const card = 18.0;
  static const pill = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );
    final frauncesTheme = GoogleFonts.frauncesTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amber,
        secondary: AppColors.terracotta,
        surface: AppColors.surface,
        onSurface: AppColors.cream,
        onPrimary: AppColors.ink,
      ),
      dividerColor: AppColors.line,
      textTheme: baseTextTheme.copyWith(
        // Fraunces (serif) para títulos, igual que en el mockup.
        headlineMedium: frauncesTheme.headlineMedium?.copyWith(
          color: AppColors.cream,
          fontWeight: FontWeight.w600,
          fontSize: 30,
        ),
        titleLarge: frauncesTheme.titleLarge?.copyWith(
          color: AppColors.cream,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          letterSpacing: -0.2,
        ),
        titleMedium: frauncesTheme.titleMedium?.copyWith(
          color: AppColors.cream,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        // Inter para el resto del texto.
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.cream),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.mauve),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: AppColors.cream,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: AppColors.mauve),
      ),
    );
  }

  /// Gradientes "placeholder" de portada (g1..g8 en el mockup), usados
  /// cuando la canción todavía no tiene portada embebida ni descargada.
  static const List<List<Color>> coverGradients = [
    [Color(0xFFE8A33D), Color(0xFFC1443C)], // g1
    [Color(0xFF6E6A8C), Color(0xFF2E2033)], // g2
    [Color(0xFF5C8B7A), Color(0xFF1B1420)], // g3
    [Color(0xFFC1443C), Color(0xFF4A2740)], // g4
    [Color(0xFFD9B65E), Color(0xFF7A4B32)], // g5
    [Color(0xFF7A6BAE), Color(0xFF2A1F2E)], // g6
    [Color(0xFF3E7C89), Color(0xFF1B1420)], // g7
    [Color(0xFFB25EA8), Color(0xFF2A1F2E)], // g8
  ];

  /// Gradiente determinístico según [seed] (normalmente el título de la
  /// canción), para que cada canción sin portada siempre muestre el
  /// mismo color en vez de uno aleatorio cada vez que se reconstruye.
  static LinearGradient coverGradientFor(String seed) {
    final index = seed.hashCode.abs() % coverGradients.length;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: coverGradients[index],
    );
  }

  /// JetBrains Mono: para duraciones, rutas de carpeta, números de pista, etc.
  static TextStyle mono({
    double fontSize = 11.5,
    Color color = AppColors.mauve,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
