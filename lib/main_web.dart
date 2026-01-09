import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/remote_viewer_provider.dart';
import 'screens/client_connect_screen.dart';
import 'services/firebase_signaling_service.dart';

/// Entry point para el cliente web
/// Versión simplificada del main.dart para uso en navegador
void main() async {
  // Asegurar que los bindings estén inicializados antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase (usa la configuración de web/firebase-config.js)
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: 'AIzaSyAjBcvvyq2PZfrvvbSfDV9GVNcavGuOVlY',
      appId: '1:384054654746:web:58e8f8fd1da6d621175ea3',
      messagingSenderId: '384054654746',
      authDomain: "lamb-dev-36c91.firebaseapp.com",
      storageBucket: "lamb-dev-36c91.firebasestorage.app",
      projectId: 'lamb-dev-36c91',
    ));
    debugPrint('[Firebase Web] Inicializado correctamente');
  } catch (e) {
    debugPrint('[Firebase Web] Error al inicializar: $e');
    debugPrint('[Firebase Web] La app continuará, pero funciones de Firebase no estarán disponibles');
  }

  // Ejecutar la app web
  runApp(const WebClientApp());
}

/// Widget raíz de la aplicación web
class WebClientApp extends StatelessWidget {
  const WebClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Initialize services
        Provider<FirebaseSignalingService>(
          create: (_) => FirebaseSignalingService(),
        ),

        // Initialize viewer provider with dependencies
        ChangeNotifierProvider<RemoteViewerProvider>(
          create: (context) => RemoteViewerProvider(
            signalingService: context.read<FirebaseSignalingService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Control Remoto - Cliente Web',
        debugShowCheckedModeBanner: false,

        // Tema principal con configuración de accesibilidad
        theme: _buildAccessibleTheme(),

        // Pantalla inicial: Conectar con código
        home: const ClientConnectScreen(),

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
  /// - Áreas táctiles grandes (mínimo 60dp botones en web)
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
          minimumSize: const Size(200, 60), // 60dp altura para web
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
          minimumSize: const Size(150, 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
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
    );
  }
}
