import 'package:flutter/material.dart';

/// Modos de tema disponibles en la app
enum AppThemeMode {
  /// Tema estandar con colores accesibles
  standard,

  /// Tema con alto contraste para baja vision
  highContrast,
}

/// Configuracion de temas accesibles
class AppTheme {
  /// Construye el tema estandar
  static ThemeData buildStandardTheme() {
    // Colores con buen contraste
    const primaryColor = Color(0xFF1565C0); // Azul oscuro
    const accentColor = Color(0xFFFF6F00); // Naranja oscuro
    const backgroundColor = Colors.white;
    const textColor = Colors.black87;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        error: Colors.red[700]!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),
      textTheme: _buildAccessibleTextTheme(textColor),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      iconButtonTheme: _buildIconButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(primaryColor),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      listTileTheme: _buildListTileTheme(),
    );
  }

  /// Construye el tema de alto contraste (Modo Oscuro Invertido)
  static ThemeData buildHighContrastTheme() {
    // Colores con contraste maximo - Fondo negro + elementos brillantes
    const primaryColor = Color(0xFFFFFF00); // Amarillo brillante
    const accentColor = Color(0xFFFFFFFF); // Blanco puro
    const backgroundColor = Color(0xFF000000); // Negro puro
    const textColor = Color(0xFFFFFFFF); // Blanco puro
    const surfaceColor = Color(0xFF1A1A1A); // Gris muy oscuro para cards

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Fondo general de la app
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.highContrastDark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: Color(0xFFFF0000), // Rojo puro
        onPrimary: Colors.black, // Texto negro sobre amarillo
        onSecondary: Colors.black,
        onSurface: textColor,
        onBackground: textColor,
        onError: Colors.white,
      ),
      textTheme: _buildAccessibleTextTheme(textColor),
      elevatedButtonTheme: _buildHighContrastElevatedButtonTheme(),
      textButtonTheme: _buildHighContrastTextButtonTheme(),
      iconButtonTheme: _buildHighContrastIconButtonTheme(),
      inputDecorationTheme: _buildHighContrastInputDecorationTheme(),
      appBarTheme: _buildHighContrastAppBarTheme(),
      cardTheme: _buildHighContrastCardTheme(),
      listTileTheme: _buildHighContrastListTileTheme(),
    );
  }

  static TextTheme _buildAccessibleTextTheme(Color textColor) {
    return TextTheme(
      displayLarge:
          TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: textColor),
      displayMedium:
          TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: textColor),
      displaySmall:
          TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge:
          TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: textColor),
      headlineMedium:
          TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall:
          TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      titleLarge:
          TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: textColor),
      titleMedium:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
      titleSmall:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
      bodyLarge: TextStyle(fontSize: 24, color: textColor),
      bodyMedium: TextStyle(fontSize: 24, color: textColor),
      bodySmall: TextStyle(fontSize: 20, color: textColor),
      labelLarge:
          TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColor),
      labelMedium:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
      labelSmall:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 80),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(150, 80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }

  static IconButtonThemeData _buildIconButtonTheme() {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(80, 80),
        iconSize: 40,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Color primaryColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[700]!, width: 3),
      ),
      labelStyle: const TextStyle(fontSize: 20),
      hintStyle: TextStyle(fontSize: 20, color: Colors.grey[600]),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(size: 32, color: Colors.white),
    );
  }

  static CardTheme _buildCardTheme() {
    return CardTheme(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static ListTileThemeData _buildListTileTheme() {
    return const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      minVerticalPadding: 16,
    );
  }

  // === MÉTODOS ESPECÍFICOS PARA ALTO CONTRASTE ===

  static ElevatedButtonThemeData _buildHighContrastElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 80),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        backgroundColor: const Color(0xFFFFFF00), // Amarillo brillante
        foregroundColor: Colors.black, // Texto negro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 3),
        ),
      ),
    );
  }

  static TextButtonThemeData _buildHighContrastTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(150, 80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        foregroundColor: const Color(0xFFFFFF00), // Texto amarillo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  static IconButtonThemeData _buildHighContrastIconButtonTheme() {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(80, 80),
        iconSize: 40,
        foregroundColor: const Color(0xFFFFFF00), // Íconos amarillos
      ),
    );
  }

  static InputDecorationTheme _buildHighContrastInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A), // Gris muy oscuro
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFFF00), width: 4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF0000), width: 4),
      ),
      labelStyle: const TextStyle(fontSize: 20, color: Colors.white),
      hintStyle: const TextStyle(fontSize: 20, color: Color(0xFFAAAAAA)),
    );
  }

  static AppBarTheme _buildHighContrastAppBarTheme() {
    return const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xFF000000), // Negro puro
      foregroundColor: Color(0xFFFFFF00), // Amarillo
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFFF00),
      ),
      iconTheme: IconThemeData(size: 32, color: Color(0xFFFFFF00)),
    );
  }

  static CardTheme _buildHighContrastCardTheme() {
    return CardTheme(
      elevation: 0, // Sin sombra, usamos bordes
      color: const Color(0xFF1A1A1A), // Gris muy oscuro
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white, width: 3),
      ),
    );
  }

  static ListTileThemeData _buildHighContrastListTileTheme() {
    return const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      minVerticalPadding: 16,
      textColor: Colors.white,
      iconColor: Color(0xFFFFFF00),
    );
  }
}
