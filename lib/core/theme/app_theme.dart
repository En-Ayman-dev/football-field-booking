import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // --- لوحة الألوان الأساسية ---
  static const Color primary = Color(0xFF2E7D32); // الأخضر الأساسي
  static const Color secondary = Color(0xFFFFA000); // البرتقالي الثانوي

  // --- الألوان الوظيفية ---
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFD32F2F);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF2C2C2C);

  // --- الخلفيات ---
  static const Color _backgroundLight = Color(0xFFF5F7FA);
  static const Color _backgroundDark = Color(0xFF121212);

  // --- إعدادات الخطوط ---
  static const String _fontFamily = 'Cairo';

  static TextTheme _buildTextTheme(TextTheme base, Color primaryColor) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: primaryColor,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        )
        .apply(fontFamily: _fontFamily);
  }

  static final BorderRadius _defaultRadius = BorderRadius.circular(16);
  static final BorderRadius _buttonRadius = BorderRadius.circular(12);

  // --- 1. الثيم النهاري (Light Theme) ---
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: lightCard,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: _backgroundLight,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),

      // ✅ تم التصحيح: استخدام CardThemeData
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: _defaultRadius,
          // ✅ تم التصحيح: استخدام withValues(alpha: ...)
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: _defaultRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _defaultRadius,
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _defaultRadius,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _defaultRadius,
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: _fontFamily,
        ),
        hintStyle: const TextStyle(color: Colors.grey, fontFamily: _fontFamily),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          // ✅ تم التصحيح: withValues
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ✅ تم التصحيح: استخدام DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black87,
        ),
      ),

      textTheme: _buildTextTheme(ThemeData.light().textTheme, primary),
    );
  }

  // --- 2. الثيم الليلي (Dark Theme) ---
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white, // ✅ التأكيد على أن النصوص على السطح بيضاء
      error: Color(0xFFEF9A9A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: _backgroundDark,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: Colors.white, // ✅ نص أبيض
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // ✅ تم التصحيح: CardThemeData
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: _defaultRadius,
          // ✅ تم التصحيح: withValues
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: _defaultRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _defaultRadius,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: _fontFamily,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ✅ تم التصحيح: DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white, // ✅ عنوان الديالوج أبيض
        ),
      ),

      // ✅ تعديل هام: فرض اللون الأبيض على جميع النصوص في الوضع الليلي
      textTheme: _buildTextTheme(
        ThemeData.dark().textTheme,
        Colors.white,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }
}
