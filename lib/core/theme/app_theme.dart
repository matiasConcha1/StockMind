import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color brand = Color(0xFF2563EB);
  static const Color brandViolet = Color(0xFF7C3AED);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color ink = Color(0xFF0F172A);
  static const Color paper = Color(0xFFF4F7FB);
  static const Color night = Color(0xFF09111F);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: Colors.white,
      secondary: const Color(0xFF0EA5E9),
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: isDark ? const Color(0xFF121B2B) : Colors.white,
      onSurface: isDark ? Colors.white : ink,
      primaryContainer: isDark ? const Color(0xFF10213F) : const Color(0xFFDCEAFE),
      onPrimaryContainer: isDark ? Colors.white : ink,
      secondaryContainer: isDark ? const Color(0xFF0C2432) : const Color(0xFFE0F2FE),
      onSecondaryContainer: isDark ? Colors.white : ink,
      tertiary: success,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF0C2921) : const Color(0xFFDDF8EC),
      onTertiaryContainer: isDark ? Colors.white : ink,
      outline: isDark ? const Color(0xFF314158) : const Color(0xFFD7E1EE),
      outlineVariant: isDark ? const Color(0xFF1B2940) : const Color(0xFFE8EEF7),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark ? Colors.white : ink,
      onInverseSurface: isDark ? ink : Colors.white,
      inversePrimary: const Color(0xFF7AB3FF),
      surfaceTint: brand,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? night : paper,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: baseText.bodyMedium?.copyWith(height: 1.45),
        labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF121B2B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        indicatorColor: brand.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? brand
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF101A2D) : Colors.white,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF92A0B5) : const Color(0xFF64748B),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: brand, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: isDark ? const Color(0xFF101A2D) : Colors.white,
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF121B2B) : ink,
        contentTextStyle: TextStyle(color: isDark ? Colors.white : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
