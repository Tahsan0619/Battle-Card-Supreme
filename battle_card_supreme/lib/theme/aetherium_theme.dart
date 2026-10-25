import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design Prefer / Aetherium Rift tokens.
class AetheriumColors {
  static const surface = Color(0xFF10131C);
  static const surfaceLowest = Color(0xFF0B0E17);
  static const surfaceLow = Color(0xFF181B25);
  static const surfaceContainer = Color(0xFF1C1F29);
  static const surfaceHigh = Color(0xFF272A34);
  static const surfaceHighest = Color(0xFF32343F);
  static const onSurface = Color(0xFFE0E2EF);
  static const onSurfaceVariant = Color(0xFFCBC3D7);
  static const outline = Color(0xFF958EA0);
  static const outlineVariant = Color(0xFF494454);
  static const primary = Color(0xFFD0BCFF);
  static const primaryContainer = Color(0xFFA078FF);
  static const onPrimary = Color(0xFF3C0091);
  static const inversePrimary = Color(0xFF6D3BD7);
  static const secondary = Color(0xFF4CD7F6);
  static const secondaryContainer = Color(0xFF03B5D3);
  static const tertiary = Color(0xFFFFB95F);
  static const tertiaryContainer = Color(0xFFCA8100);
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const hp = Color(0xFFEF4444);
  static const shield = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
}

ThemeData buildAetheriumTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AetheriumColors.surface,
    colorScheme: const ColorScheme.dark(
      surface: AetheriumColors.surface,
      primary: AetheriumColors.primary,
      onPrimary: AetheriumColors.onPrimary,
      secondary: AetheriumColors.secondary,
      tertiary: AetheriumColors.tertiary,
      error: AetheriumColors.error,
      onSurface: AetheriumColors.onSurface,
      outline: AetheriumColors.outline,
    ),
  );

  final display = GoogleFonts.spaceGroteskTextTheme(base.textTheme);
  final body = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: display.copyWith(
      bodyLarge: body.bodyLarge?.copyWith(color: AetheriumColors.onSurface),
      bodyMedium: body.bodyMedium?.copyWith(color: AetheriumColors.onSurfaceVariant),
      bodySmall: body.bodySmall?.copyWith(color: AetheriumColors.onSurfaceVariant),
      labelLarge: display.labelLarge?.copyWith(
        letterSpacing: 0.06,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AetheriumColors.surfaceLowest.withValues(alpha: 0.85),
      foregroundColor: AetheriumColors.onSurface,
      elevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AetheriumColors.onSurface,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: AetheriumColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AetheriumColors.inversePrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AetheriumColors.secondary,
        side: const BorderSide(color: AetheriumColors.secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AetheriumColors.surfaceLowest,
      indicatorColor: AetheriumColors.primaryContainer.withValues(alpha: 0.35),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
