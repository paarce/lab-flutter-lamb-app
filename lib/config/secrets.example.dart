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

  // ========================================
  // Firebase Configuration
  // ========================================
  /// Obtener en: Firebase Console → Project Settings → General

  /// Firebase Web API Key
  static const String firebaseWebApiKey = 'YOUR_FIREBASE_WEB_API_KEY';

  /// Firebase Web App ID
  static const String firebaseWebAppId = 'YOUR_FIREBASE_WEB_APP_ID';

  /// Firebase Android App ID
  static const String firebaseAndroidAppId = 'YOUR_FIREBASE_ANDROID_APP_ID';

  /// Firebase Project ID
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';

  /// Firebase Messaging Sender ID
  static const String firebaseMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID';

  /// Firebase Auth Domain
  static const String firebaseAuthDomain = 'YOUR_PROJECT_ID.firebaseapp.com';

  /// Firebase Storage Bucket
  static const String firebaseStorageBucket = 'YOUR_PROJECT_ID.firebasestorage.app';

  // ========================================
  // Claude API Configuration (Feature 4.4)
  // ========================================
  /// API key de Claude para parsing LLM de comandos de voz
  /// Obtener en: https://console.anthropic.com/settings/keys
  /// Nota: Solo se usa como fallback cuando el parser local falla
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY_HERE';
}
