/// Archivo de ejemplo para secrets.dart
///
/// INSTRUCCIONES:
/// 1. Copiar este archivo como 'secrets.dart' en el mismo directorio
/// 2. Reemplazar los valores con tus API keys reales
/// 3. NUNCA commitear secrets.dart a git (ya está en .gitignore)
library;

class Secrets {
  /// Proveedor de Text-to-Speech a usar
  /// Opciones: 'flutter_tts' (recomendado, gratis), 'google_cloud', 'azure'
  /// Nota: Solo flutter_tts está implementado actualmente
  static const String ttsProvider = 'flutter_tts';

  /// API key de ElevenLabs para STT (Speech-to-Text)
  /// Obtener en: https://elevenlabs.io/app/settings/api-keys
  static const String elevenLabsApiKey = 'YOUR_ELEVENLABS_API_KEY_HERE';

  /// Firebase Project ID (opcional si usas FlutterFire CLI)
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';

  /// Otros secrets que necesites
  // static const String otherApiKey = 'VALUE';
}
