import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/remote_control_provider.dart';
import 'screens/home_screen.dart';
import 'services/elevenlabs_service.dart';
import 'services/firebase_signaling_service.dart';
import 'services/error_handler_service.dart';
import 'services/logger_service.dart';
import 'services/tts/tts_factory.dart';

/// Entry point de la aplicación
/// Inicializa Firebase, Hive y Provider antes de ejecutar la app
void main() async {
  // Asegurar que los bindings estén inicializados antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    debugPrint('[Firebase] Inicializado correctamente');
  } catch (e) {
    debugPrint('[Firebase] Error al inicializar: $e');
    debugPrint('[Firebase] La app continuará, pero funciones de Firebase no estarán disponibles');
    // NOTA: En producción, considera mostrar un error al usuario
  }

  try {
    // Inicializar Hive (base de datos local)
    await Hive.initFlutter();
    debugPrint('[Hive] Inicializado correctamente');
  } catch (e) {
    debugPrint('[Hive] Error al inicializar: $e');
  }

  // Ejecutar la app
  runApp(const MyApp());
}

/// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Logging service (Singleton)
        Provider<LoggerService>(
          create: (_) => LoggerService(),
        ),

        // Initialize services
        Provider<FirebaseSignalingService>(
          create: (_) => FirebaseSignalingService(),
        ),
        // TTS Service (Singleton) - Inyectar para acceso desde Providers/Screens
        Provider(
          create: (_) => TTSFactory.getInstance(),
        ),

        // Error handler service (Singleton)
        Provider<ErrorHandlerService>(
          create: (_) => ErrorHandlerService(),
        ),

        // Initialize providers with dependencies
        ChangeNotifierProvider<RemoteControlProvider>(
          create: (context) => RemoteControlProvider(
            signalingService: context.read<FirebaseSignalingService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Asistente de Accesibilidad',
        debugShowCheckedModeBanner: false,

        // Tema principal con configuración de accesibilidad
        theme: _buildAccessibleTheme(),

        // Pantalla inicial
        home: const HomeScreen(),

        // Builder para MediaQuery (necesario para accesibilidad)
        builder: (context, child) {
          return MediaQuery(
            // Respetar configuraciones de accesibilidad del sistema
            data: MediaQuery.of(context).copyWith(
              // Permitir escala de texto del usuario (1.0 a 3.0x)
              textScaler: MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 1.0,
                maxScaleFactor: 3.0,
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }

  /// Construye un tema accesible según las reglas de WCAG 2.1 AA
  ///
  /// Características:
  /// - Tamaños de texto grandes (mínimo 24sp base)
  /// - Alto contraste de colores
  /// - Áreas táctiles grandes (mínimo 80dp botones)
  /// - Iconografía clara
  ThemeData _buildAccessibleTheme() {
    // Colores con alto contraste
    const primaryColor = Color(0xFF1565C0); // Azul oscuro
    const accentColor = Color(0xFFFF6F00); // Naranja oscuro
    const backgroundColor = Colors.white;
    const textColor = Colors.black87;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Esquema de colores con alto contraste
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        error: Colors.red[700]!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),

      // Configuración de texto con tamaños grandes
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: textColor),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: textColor),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: textColor),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textColor),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: textColor),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
        titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: TextStyle(fontSize: 24, color: textColor), // MÍNIMO 24sp
        bodyMedium: TextStyle(fontSize: 24, color: textColor),
        bodySmall: TextStyle(fontSize: 20, color: textColor),
        labelLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColor),
        labelMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textColor),
        labelSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
      ),

      // Configuración de botones elevados (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 80), // MÍNIMO 80dp altura
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          textStyle: const TextStyle(
            fontSize: 24, // MÍNIMO 24sp
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Configuración de botones de texto (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(150, 80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Configuración de botones con ícono (IconButton)
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(80, 80), // Área táctil grande
          iconSize: 40, // Íconos grandes
        ),
      ),

      // Configuración de campos de texto
      inputDecorationTheme: InputDecorationTheme(
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
          borderSide: const BorderSide(color: primaryColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[700]!, width: 3),
        ),
        labelStyle: const TextStyle(fontSize: 20),
        hintStyle: TextStyle(fontSize: 20, color: Colors.grey[600]),
      ),

      // AppBar con accesibilidad
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          size: 32,
          color: Colors.white,
        ),
      ),

      // Card con espaciado generoso
      cardTheme: CardTheme(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Espaciado generoso en listas
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minVerticalPadding: 16,
      ),
    );
  }
}
