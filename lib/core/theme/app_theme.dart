import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF0F766E);
    const scaffoldBg = Color(0xFFF3F6FA);
    final textTheme = GoogleFonts.manropeTextTheme();
    final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      surface: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFE7EEF6),
      outlineVariant: const Color(0xFFD2DCE8),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD2DCE8)),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: seed, width: 1.4),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        isDense: true,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        indicatorColor: const Color(0x1A0F766E),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: seed,
        brightness: Brightness.light,
        labelStyle: textTheme.bodySmall ?? const TextStyle(),
      ),
    );
  }
}
