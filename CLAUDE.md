# App de Accesibilidad para Adultos Mayores

## Información del Proyecto

**Propósito:** App Flutter para adultos mayores (60+) con baja visión
**Usuarios:** Personas con experiencia técnica limitada que usan TalkBack/VoiceOver
**Plazo:** 3 meses
**Plataformas:** Android (prioridad), iOS v2.0 (funcionalidad limitada)

### Estado Actual del Proyecto

**Versión:** 1.0.0 - Setup inicial completado ✅

El proyecto está en su fase inicial con la infraestructura base configurada y lista para el desarrollo de funcionalidades del MVP. La app compila correctamente, Firebase está integrado, y el tema accesible cumple con estándares WCAG 2.1 AA.

**Historial de cambios:** Ver [CHANGELOG.md](./CHANGELOG.md) para detalles de implementación.
**Próximas funcionalidades:** Ver [BACKLOG.md](./.claude/docs/BACKLOG.md)

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
# State Management
provider: ^6.1.1

# Firebase
firebase_core: ^2.24.2
cloud_firestore: ^4.13.6
firebase_messaging: ^14.7.9

# Features
flutter_webrtc: ^0.9.48
flutter_accessibility_service: ^1.0.0  # Nota: v3.0.0 no existe en pub.dev
permission_handler: ^11.1.0

# Networking
http: ^1.1.0
dio: ^5.4.0
web_socket_channel: ^2.4.0

# Storage
hive: ^2.2.3
hive_flutter: ^1.1.0
```

---

## Estructura del Proyecto

**Nota:** Esta estructura incluye archivos implementados (✅) y plantillas futuras (🔜).

```
lib/
├── main.dart                             ✅ Implementado
├── config/
│   ├── secrets.dart                      ✅ Implementado (gitignored)
│   └── secrets.example.dart              ✅ Implementado
├── errors/                               ✅ GESTIÓN CENTRALIZADA DE ERRORES
│   ├── app_error.dart                    ✅ Modelo base unificado
│   ├── error_category.dart               ✅ Enums de categorías
│   └── error_codes.dart                  ✅ Códigos de error normalizados
├── screens/
│   ├── home_screen.dart                  ✅ Implementado
│   ├── voice_command_screen.dart         🔜 Próxima funcionalidad
│   ├── whatsapp_screen.dart              🔜 Próxima funcionalidad
│   └── remote_control_screen.dart        🔜 Próxima funcionalidad
├── services/
│   ├── elevenlabs_service.dart           ✅ STT/TTS
│   ├── firebase_signaling_service.dart   ✅ Firebase Signaling
│   ├── webrtc_client_service.dart        ✅ WebRTC Client
│   ├── webrtc_service.dart               ✅ WebRTC Base
│   ├── foreground_service.dart           ✅ Servicio en primer plano
│   ├── error_handler_service.dart        ✅ PUNTO CENTRAL DE ERRORES
│   ├── logger_service.dart               ✅ Logging en memoria
│   ├── ERROR_HANDLER_GUIDE.dart          ✅ Guía de uso (ejemplos)
│   ├── whatsapp_service.dart             🔜 Platform Channel → Kotlin
│   └── preferences_service.dart          🔜 Preferencias
├── providers/
│   ├── remote_control_provider.dart      ✅ State management control remoto
│   ├── remote_viewer_provider.dart       ✅ State management viewer
│   ├── voice_command_provider.dart       🔜 State management comandos
│   └── whatsapp_provider.dart            🔜 State management WhatsApp
├── models/
│   ├── remote_session.dart               ✅ Modelo de sesiones remotas
│   ├── webrtc_signaling_message.dart     ✅ Mensajes WebRTC
│   ├── command.dart                      🔜 Modelo de comandos
│   └── whatsapp_action.dart              🔜 Modelo de acciones WhatsApp
└── utils/
    ├── error_messages.dart               ✅ Mensajes accesibles para usuario
    ├── nlp_parser.dart                   🔜 Parser de lenguaje natural
    └── constants.dart                    🔜 Constantes globales

android/app/src/main/kotlin/
├── MainActivity.kt                       ✅ Implementado (básico)
├── AssistantAccessibilityService.kt      🔜 Servicio de accesibilidad
├── WhatsAppAutomation.kt                 🔜 Automatización WhatsApp
└── NotificationListener.kt               🔜 Listener de notificaciones
```

---

## Documentación del Proyecto

### Archivos de Referencia

- **[CLAUDE.md](./CLAUDE.md)** (este archivo) - Guía de referencia técnica del proyecto
- **[README.md](./README.md)** - Guía de desarrollo y setup
  - Setup inicial completo
  - Ejecución en emulador Android
  - Gestión de procesos Flutter
  - Troubleshooting común
- **[CHANGELOG.md](./CHANGELOG.md)** - Historial de cambios del proyecto
- **[ARQUITECTURA_APP_ACCESIBILIDAD.md](./ARQUITECTURA_APP_ACCESIBILIDAD.md)** - Análisis técnico de decisiones de arquitectura

### Documentación Interna (.claude/docs/)

- **BACKLOG.md** - Tareas pendientes del proyecto
- **ROADMAP.md** - Hoja de ruta del desarrollo
- **SETUP_COMPLETADO.md** - Confirmación de setup inicial (gitignored, solo local)

### Reglas de Desarrollo (.claude/rules/)

- **accessibility.md** - Reglas de accesibilidad (WCAG 2.1 AA)
- **platform-channels.md** - Guía de Platform Channels Flutter ↔ Kotlin
- **whatsapp-automation.md** - Reglas para automatización WhatsApp

### Skills de Claude Code (.claude/skills/)

- **accessibility/** - Guía de TalkBack y diseño inclusivo
- **platform-channels/** - Guía de implementación de platform channels
- **debugging/** - Debugging específico de Flutter/Android
- **development/** - Workflow de desarrollo general

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

## 🚨 Gestión Centralizada de Errores (NUEVO)

### Arquitectura

La app usa un **servicio central único** (`ErrorHandlerService`) para manejar TODOS los errores. Esto garantiza:

✅ **Consistencia:** Mismo flujo para todos los errores
✅ **Accesibilidad:** Diálogos modales + TTS obligatorio
✅ **Debugging:** Logging centralizado + códigos normalizados
✅ **Sin confusión:** Sin reintentos automáticos

### Archivos Relacionados

- **`lib/errors/app_error.dart`** - Modelo base unificado para todos los errores
- **`lib/errors/error_category.dart`** - Categorías: PlatformChannel, Firebase, ElevenLabs, WebRTC, Network
- **`lib/errors/error_codes.dart`** - Códigos normalizados por categoría
- **`lib/services/error_handler_service.dart`** - ⭐️ **PUNTO CENTRAL** - Usa SIEMPRE este servicio
- **`lib/services/logger_service.dart`** - Logging en memoria (máximo 100 logs)
- **`lib/utils/error_messages.dart`** - Mensajes accesibles en español para usuario + TTS
- **`lib/services/ERROR_HANDLER_GUIDE.dart`** - Ejemplos y mejores prácticas

### Uso Simple

```dart
// EN CUALQUIER SERVICE, PROVIDER O SCREEN:
try {
  await miServicio.hacerAlgo();
} catch (e) {
  if (context.mounted) {
    await ErrorHandlerService.handleError(
      context: context,
      error: e,
      service: 'MiService',
      canRetry: true,  // Mostrar botón "Reintentar"
      onRetry: () => miServicio.hacerAlgo(),
      ttsService: context.read<ElevenLabsService>(),
    );
  }
}
```

### Características Automáticas

1. **Normaliza cualquier error:**
   - `AppError` → se usa directamente
   - `PlatformException` → convierte a AppError
   - `FirebaseException` → categoriza como firebase
   - `SocketException` → detecta como error de red
   - Otros → marca como unknown

2. **Genera mensaje accesible:**
   - Automáticamente en español
   - Lenguaje simple (para personas 60+)
   - Optimizado para TTS

3. **Reproduce con TTS:**
   - Si `ttsService` disponible, reproduce el mensaje
   - Si TTS falla, continúa sin romper

4. **Muestra diálogo modal:**
   - Modal (visible para baja visión)
   - Botones 80dp + texto 24sp
   - Semantics para TalkBack
   - Siempre: botón "Cerrar"
   - Condicionalmente: botón "Reintentar"

5. **Registra logs:**
   - Todos los errores en memoria
   - Máximo 100 logs (FIFO)
   - Timestamps + tags + stack traces

### Categorías de Errores (en orden de criticidad)

```
1. PLATFORM_CHANNEL   → Errores de Kotlin/Android
2. FIREBASE           → Firestore, Authentication
3. ELEVENLABS         → STT/TTS API
4. WEBRTC             → Control remoto
5. NETWORK            → Internet connectivity
6. UNKNOWN            → No clasificado
```

### Cuándo Usar `canRetry`

**`canRetry=true`** (mostrar botón "Reintentar"):
- Error transitorio (sin internet, timeout)
- Reintentar tiene sentido
- No es configuración faltante

**`canRetry=false`** (solo botón "Cerrar"):
- Error permanente (permiso denegado)
- Necesita acción manual (Configuración)
- Reintentar sin cambios no ayuda

### Mejores Prácticas

✅ **HACER:**
- Pasar `ttsService: context.read<ElevenLabsService>()`
- Ofrecer `onRetry` solo si tiene sentido
- Usar nombres de service descriptivos
- Capturar errors en try-catch

❌ **NO HACER:**
- Mostrar diálogos de error manuales (usa ErrorHandlerService)
- Reintentos automáticos
- Mensajes técnicos al usuario
- Ignorar errores en Platform Channel

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

**Versión:** 1.0.0
**Última actualización:** 27 dic 2025
**Stack:** Flutter + Firebase + WebRTC + ElevenLabs
