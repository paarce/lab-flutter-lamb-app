# App de Accesibilidad para Adultos Mayores

## Información del Proyecto

**Propósito:** App Flutter para adultos mayores (60+) con baja visión
**Usuarios:** Personas con experiencia técnica limitada que usan TalkBack/VoiceOver
**Plazo:** 3 meses
**Plataformas:** Android (prioridad), iOS v2.0 (funcionalidad limitada)

### Funcionalidades Core
1. Control remoto de pantalla (soporte familiar vía WebRTC)
2. Comandos de voz para automatización de WhatsApp
3. Interfaz con botones grandes y alto contraste
4. Leer mensajes de WhatsApp en voz alta

---

## Stack Tecnológico

### Frontend
- **Flutter:** 3.19+
- **Dart:** 3.0+
- **State Management:** Provider

### Servicios
- **STT/TTS:** ElevenLabs Scribe v2 (principal), Android SpeechRecognizer (fallback)
- **Control Remoto:** WebRTC custom + Firebase Firestore (signaling)
- **Base de datos local:** Hive

### Código Nativo
- **Android:** Kotlin (AccessibilityService, WhatsApp automation)
- **iOS:** Swift (ReplayKit screen sharing - v2.0)

### Dependencias Flutter
```yaml
flutter_accessibility_service: ^3.0.0
flutter_webrtc: ^0.9.48
provider: ^6.1.1
http: ^1.1.0
dio: ^5.4.0
web_socket_channel: ^2.4.0
hive: ^2.2.3
permission_handler: ^11.1.0
```

---

## Estructura del Proyecto

```
lib/
├── main.dart
├── config/
│   └── secrets.dart                  # API keys (gitignored)
├── screens/
│   ├── home_screen.dart
│   ├── voice_command_screen.dart
│   ├── whatsapp_screen.dart
│   └── remote_control_screen.dart
├── services/
│   ├── elevenlabs_service.dart       # STT/TTS
│   ├── whatsapp_service.dart         # Platform Channel → Kotlin
│   ├── webrtc_service.dart           # Control remoto
│   └── preferences_service.dart
├── providers/
│   ├── voice_command_provider.dart
│   ├── whatsapp_provider.dart
│   └── remote_control_provider.dart
├── models/
│   ├── command.dart
│   ├── whatsapp_action.dart
│   └── remote_session.dart
└── utils/
    ├── nlp_parser.dart
    └── constants.dart

android/app/src/main/kotlin/
├── MainActivity.kt
├── AssistantAccessibilityService.kt
├── WhatsAppAutomation.kt
└── NotificationListener.kt
```

---

## Convenciones de Código

### Dart/Flutter
| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Classes | PascalCase | `ElevenLabsService` |
| Variables/funciones | camelCase | `startListening()` |
| Constantes | lowerCamelCase | `apiKey` |
| Archivos | snake_case | `elevenlabs_service.dart` |

**Reglas:**
- Indentación: 2 espacios
- Async: usar `async/await` (evitar `.then()`)
- State management: Provider

### Kotlin
| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Classes | PascalCase | `MainActivity` |
| Funciones/variables | camelCase | `openChat()` |
| Constantes | UPPER_SNAKE_CASE | `WHATSAPP_PACKAGE` |

**Reglas:**
- Indentación: 4 espacios
- Null safety: usar `?` y `!!` correctamente

### Accesibilidad (Obligatorio)
- ✅ `Semantics` en TODOS los widgets interactivos
- ✅ Botones: mínimo **80dp altura**
- ✅ Texto: mínimo **24sp**
- ✅ Testar con TalkBack antes de commit

---

## Comandos Frecuentes

```bash
# Desarrollo
flutter run                              # Ejecutar app
flutter run --analyze-accessibility      # Con análisis accesibilidad
flutter logs                             # Ver logs

# Testing
flutter test                             # Unit tests
flutter analyze                          # Análisis estático

# Build
flutter build apk --release              # APK release
flutter build appbundle --release        # App Bundle (Google Play)

# Firebase
flutterfire configure                    # Configurar proyecto

# Git (antes de commit)
flutter analyze && flutter test
```

---

## Secrets y Variables de Entorno

**Archivo:** `lib/config/secrets.dart` (gitignored)

```dart
class Secrets {
  static const String elevenLabsApiKey = 'sk-...';
  static const String elevenLabsVoiceId = 'voice_id_here';
}
```

**Crear desde template:**
```bash
cp lib/config/secrets.example.dart lib/config/secrets.dart
# Editar con API keys reales
```

**NUNCA commitear:**
- `lib/config/secrets.dart`
- `android/app/google-services.json`
- `*.keystore`, `.env`

---

## Limitaciones de Plataforma

### Android (Prioridad 1)
- ✅ Control remoto completo
- ✅ Automatización WhatsApp
- ⚠️ Frágil ante actualizaciones de WhatsApp
- ⚠️ Xiaomi/Huawei requieren pasos extra para Accessibility

### iOS (v2.0)
- ✅ UI simplificada + comandos de voz
- ⚠️ Screen sharing solo lectura
- ❌ NO control remoto
- ❌ NO automatización WhatsApp

---

## RustDesk como Referencia

**Propósito:** Estudiar arquitectura WebRTC + AccessibilityService (NO fork)

```bash
git clone https://github.com/rustdesk/rustdesk.git
```

**Archivos para estudiar:**
- `flutter/lib/models/native_model.dart` - Platform channels Flutter↔Rust
- `android/app/src/main/kotlin/MainActivity.kt` - Platform channels
- `android/app/src/main/AndroidManifest.xml` - Permisos Accessibility

**Regla:** NO copiar código, solo entender patrones

---

## Integración ElevenLabs

### STT (WebSocket)
```dart
final channel = WebSocketChannel.connect(
  Uri.parse('wss://api.elevenlabs.io/v1/speech-to-text/realtime')
);
```

### TTS (REST)
```dart
await http.post(
  Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
  headers: {'xi-api-key': Secrets.elevenLabsApiKey},
  body: json.encode({'text': text})
);
```

---

## Prioridades de Desarrollo

1. **Accesibilidad primero** - TalkBack en cada feature
2. **Errores robustos** - Usuarios no técnicos
3. **Performance** - Dispositivos Android 7.0+ gama baja
4. **Testing real** - Dispositivo físico con TalkBack

### Checklist Pre-Commit
- [ ] `flutter analyze` pasa
- [ ] `flutter test` pasa
- [ ] Testeado con TalkBack activado
- [ ] `Semantics` en widgets interactivos nuevos
- [ ] Logs agregados en código Platform Channel

---

## Google Play - AccessibilityService

**Declaración obligatoria:**
```
Esta app ayuda a adultos mayores con baja visión a usar WhatsApp
mediante comandos de voz.

Permisos:
- Accesibilidad: Automatizar apertura de chats
- Notificaciones: Leer mensajes en voz alta

NO recopilamos datos. Todo es local.
```

**Incluir:**
- Video demo de uso legítimo
- Política de privacidad detallada

---

## Documentación

### APIs Oficiales
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Android AccessibilityService](https://developer.android.com/guide/topics/ui/accessibility/service)
- [ElevenLabs STT API](https://elevenlabs.io/docs/capabilities/speech-to-text)

### Packages
- [flutter_accessibility_service](https://pub.dev/packages/flutter_accessibility_service)
- [flutter_webrtc](https://pub.dev/packages/flutter_webrtc)
- [provider](https://pub.dev/packages/provider)

### Políticas
- [Google Play Accessibility Policy](https://support.google.com/googleplay/android-developer/answer/10964491)

---

**Versión:** 2.0
**Última actualización:** 24 dic 2025
**Stack:** Flutter + WebRTC + ElevenLabs
