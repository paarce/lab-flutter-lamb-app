/// Códigos de error normalizados por categoría
///
/// Permite consistencia en debugging y traducción de errores
abstract class ErrorCodes {
  // PLATFORM CHANNEL
  static const String pcPermissionDenied = 'PERMISSION_DENIED';
  static const String pcAccessibilityServiceInactive =
      'ACCESSIBILITY_SERVICE_INACTIVE';
  static const String pcNativeException = 'NATIVE_EXCEPTION';
  static const String pcMethodNotImplemented = 'METHOD_NOT_IMPLEMENTED';

  // FIREBASE
  static const String fbNetworkError = 'NETWORK_ERROR';
  static const String fbAuthExpired = 'AUTH_EXPIRED';
  static const String fbFirestoreFailed = 'FIRESTORE_FAILED';
  static const String fbNotConnected = 'NOT_CONNECTED';

  // ELEVENLABS
  static const String elApiKeyInvalid = 'API_KEY_INVALID';
  static const String elRateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String elInvalidAudio = 'INVALID_AUDIO';
  static const String elVoiceNotFound = 'VOICE_NOT_FOUND';
  static const String elNetworkFailed = 'NETWORK_FAILED';

  // WEBRTC
  static const String wrtcConnectionFailed = 'CONNECTION_FAILED';
  static const String wrtcPeerNotFound = 'PEER_NOT_FOUND';
  static const String wrtcIceTimeout = 'ICE_TIMEOUT';
  static const String wrtcMediaPermissionDenied = 'MEDIA_PERMISSION_DENIED';
  static const String wrtcSessionExpired = 'SESSION_EXPIRED';

  // NETWORK
  static const String netNoInternet = 'NO_INTERNET';
  static const String netTimeout = 'TIMEOUT';
  static const String netConnectionUnstable = 'CONNECTION_UNSTABLE';

  // UNKNOWN
  static const String unknownError = 'UNKNOWN_ERROR';
}
