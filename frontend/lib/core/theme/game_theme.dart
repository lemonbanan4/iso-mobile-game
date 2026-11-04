import 'package:flutter/material.dart';

/// Design tokens for Iso Syndicate (dark sci-fi / cyberpunk underground).
class GameTheme {
  GameTheme._();

  // Void city / neon underworld palette
  static const Color backgroundDark = Color(0xFF070A12);
  static const Color surfaceDark = Color(0xFF10182A);
  static const Color surfaceGlass = Color(0x33141E33);

  // Syndicate resources
  static const Color credits = Color(0xFFFFD166);
  static const Color contraband = Color(0xFFF72585);
  static const Color loyalty = Color(0xFF4CC9F0);
  static const Color heat = Color(0xFFFF6B35);

  // Legacy aliases (backend field mapping)
  static const Color gold = credits;
  static const Color science = loyalty;
  static const Color production = contraband;
  static const Color food = heat;
  static const Color culture = Color(0xFFB5179E);

  // UI Accents
  static const Color accentNeon = Color(0xFF00F5D4);
  static const Color accentMagenta = Color(0xFFFF2E97);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Claymorphism Base
  static const Color claySurface = Color(0xFF1A2238);
  static const Color claySurfaceLight = Color(0xFF24304A);
  static const Color clayBorder = Color(0x40FFFFFF);

  /// Double-shadow for 3D Claymorphic effect
  static List<BoxShadow> get clayShadows => [
        const BoxShadow(
          color: Color(0x66000000),
          offset: Offset(4, 6),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        const BoxShadow(
          color: Color(0x1FFFFFFF),
          offset: Offset(-2, -3),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];

  /// Liquid Glass specular border gradient
  static const LinearGradient glassBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x80FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
      Color(0x4D00F5D4),
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  /// Clay Button gradient
  static const LinearGradient clayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C3B59),
      Color(0xFF1A2337),
    ],
  );

  /// Accent Neon Button gradient
  static const LinearGradient accentNeonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00F5D4),
      Color(0xFF00BBF9),
    ],
  );

  /// Subtle cyberpunk backdrop wash for HUD chrome
  static const LinearGradient voidGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x3300F5D4),
      Color(0x00070A12),
      Color(0x33FF2E97),
    ],
  );
}
