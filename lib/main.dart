import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/app_theme.dart';
import 'providers/remote_control_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/voice_command_provider.dart';
import 'screens/voice_command_screen.dart';
import 'services/elevenlabs_service.dart';
import 'firebase_options.dart';
import 'services/firebase_signaling_service.dart';
import 'services/error_handler_service.dart';
import 'services/logger_service.dart';
import 'services/tts/tts_factory.dart';
import 'services/tts/tts_service.dart';

/// Entry point de la aplicación
/// Inicializa Firebase, Hive y Provider antes de ejecutar la app
void main() async {
  // Asegurar que los bindings estén inicializados antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase usando configuración desde secrets
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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

        // STT Service (Speech-to-Text) - ElevenLabs
        Provider<ElevenLabsService>(
          create: (_) => ElevenLabsService(),
        ),

        // TTS Service (Singleton) - Inyectar para acceso desde Providers/Screens
        Provider<TTSService>(
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

        // Theme provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

        // Voice command provider
        ChangeNotifierProvider<VoiceCommandProvider>(
          create: (context) => VoiceCommandProvider(
            sttService: context.read<ElevenLabsService>(),
            ttsService: context.read<TTSService>(),
            themeProvider: context.read<ThemeProvider>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Asistente de Accesibilidad',
            debugShowCheckedModeBanner: false,

            // Usar tema dinámico desde provider
            theme: themeProvider.currentTheme,

            // Pantalla inicial
            home: const VoiceCommandScreen(),

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
          );
        },
      ),
    );
  }
}
