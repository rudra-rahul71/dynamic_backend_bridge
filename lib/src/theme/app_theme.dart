import 'package:flutter/material.dart';

/// Ecosystem theme builder for applications and backend bridge components.
///
/// Ensures both the host application and bridge UI screens pull from the exact same
/// unified [ColorScheme] and background tokens.
class AppTheme {
  AppTheme._();

  /// Build a unified [ThemeData] using seed colors and specific palette overrides.
  static ThemeData build({
    required Color primarySeed,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? surface,
    Color? onSurface,
    Color? scaffoldBackgroundColor,
    Brightness brightness = Brightness.dark,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final Color defaultSurface = surface ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final Color defaultScaffold = scaffoldBackgroundColor ?? (isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA));

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: brightness,
      primary: primary ?? primarySeed,
      onPrimary: onPrimary ?? (isDark ? Colors.black : Colors.white),
      secondary: secondary,
      surface: defaultSurface,
      onSurface: onSurface ?? (isDark ? Colors.white : Colors.black87),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: defaultScaffold,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF0F0F0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
    );
  }
}
