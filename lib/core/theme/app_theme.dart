import 'package:flutter/material.dart';
// google_fonts removed to prevent runtime network fetching of fonts

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF00695C); // Deep Emerald Green
  static const Color secondary = Color(0xFFFFC107); // Golden Amber
  static const Color success = Color(0xFF2E7D32); // Green success
  static const Color warning = Color(0xFFFFC107); // Amber warning
  static const Color darkSurface = Color(0xFF102027); // Gunmetal Blue
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White
  static const Color darkCard = Color(0xFF263238); // Charcoal

  /// Common text theme using Cairo font (Arabic friendly)
  static TextTheme _textTheme(TextTheme base) {
    // Use local/system font family 'Cairo' if available; otherwise fallback to system fonts
    const String family = 'Cairo';
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: family, fontSize: 28, fontWeight: FontWeight.bold),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: family, fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: base.labelLarge?.copyWith(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static final OutlineInputBorder _outlineBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide.none,
  );

  static final OutlineInputBorder _focusedOutlineBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: primary, width: 2),
  );

  static InputDecorationTheme _inputDecorationTheme(Color fillColor) => InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: _outlineBorder,
        enabledBorder: _outlineBorder,
        disabledBorder: _outlineBorder,
        focusedBorder: _focusedOutlineBorder,
        errorBorder: _outlineBorder.copyWith(borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: _focusedOutlineBorder.copyWith(borderSide: const BorderSide(color: Colors.red)),
        labelStyle: const TextStyle(height: 1.2),
      );

  static final CardThemeData _cardTheme = CardThemeData(
    elevation: 4,
    color: lightCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
  );

  static final CardThemeData _cardThemeDark = CardThemeData(
    elevation: 4,
    color: darkCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ButtonStyle(
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(54)),
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 18)),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      elevation: MaterialStateProperty.all(8),
      shadowColor: MaterialStateProperty.all(primary.withOpacity(0.24)),
      backgroundColor: MaterialStateProperty.resolveWith((states) => primary),
      foregroundColor: MaterialStateProperty.all(Colors.white),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
    style: ButtonStyle(
      minimumSize: MaterialStateProperty.all(const Size.fromHeight(54)),
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 18)),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    ),
  );

  static final FloatingActionButtonThemeData _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: primary,
    elevation: 6,
  );

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      background: const Color(0xFFF6F9F7),
      onBackground: Colors.black,
      surface: lightCard,
      onSurface: Colors.black,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme(Colors.grey[100]!),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textTheme: _textTheme(base.textTheme),
      iconTheme: const IconThemeData(color: primary),
      floatingActionButtonTheme: _fabTheme,
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black,
      error: Colors.red.shade400,
      onError: Colors.white,
      background: darkSurface,
      onBackground: Colors.white,
      surface: darkCard,
      onSurface: Colors.white,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: _cardThemeDark,
      inputDecorationTheme: _inputDecorationTheme(Colors.grey[800]!),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textTheme: _textTheme(base.textTheme),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      floatingActionButtonTheme: _fabTheme,
    );
  }
}
