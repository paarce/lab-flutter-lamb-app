/// Archivo de ejemplo para secrets.dart
///
/// INSTRUCCIONES:
/// 1. Copiar este archivo como 'secrets.dart' en el mismo directorio
/// 2. Reemplazar los valores con tus API keys reales
/// 3. NUNCA commitear secrets.dart a git (ya está en .gitignore)

class Secrets {
  /// API key de ElevenLabs para STT/TTS
  /// Obtener en: https://elevenlabs.io/app/settings/api-keys
  static const String elevenLabsApiKey = 'YOUR_ELEVENLABS_API_KEY_HERE';

  /// Voice ID para Text-to-Speech (voz en español)
  /// Obtener en: https://elevenlabs.io/app/voice-library
  static const String elevenLabsVoiceId = 'YOUR_VOICE_ID_HERE';

  /// Firebase Project ID (opcional si usas FlutterFire CLI)
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';

  /// Otros secrets que necesites
  // static const String otherApiKey = 'VALUE';
}
