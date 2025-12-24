# Documento de Decisiones de Arquitectura
## App Móvil de Accesibilidad para Adultos Mayores

**Fecha:** 24 de diciembre de 2025
**Versión:** 2.0 - Actualizado con Flutter + Platform Channels
**Autor:** Arquitectura técnica para desarrollo individual

---

## 1. Decisión: Multiplataforma vs Nativo

### 1.1 Evaluación de Control Remoto de Pantalla

#### iOS
- **Limitación crítica**: iOS **NO permite** control remoto de pantalla mediante apps de terceros por razones de seguridad y privacidad
- Únicas excepciones:
  - Apps MDM (Mobile Device Management) empresariales con perfiles aprobados
  - Screen sharing de solo lectura (AirPlay, ReplayKit) sin control
  - Guided Access (modo kiosco) que NO es control remoto
- **Veredicto iOS**: **Inviable** para control remoto real

#### Android
- **Viable mediante Accessibility Services**:
  - `AccessibilityService` permite captura de pantalla y eventos táctiles
  - Requiere permisos explícitos del usuario
  - APIs clave: `dispatchGesture()`, `performGlobalAction()`, `takeScreenshot()`
- **Limitaciones**:
  - Pantallas de sistema (configuración, instalación) tienen restricciones
  - Google puede rechazar apps que abusen de estos permisos
  - Requiere Android 7.0+ (API 24) para funcionalidades completas
- **Soluciones de terceros**:
  - TeamViewer SDK (comercial, ~$1000/año)
  - AnyDesk SDK (comercial)
  - WebRTC + Accessibility Services (DIY, complejo)
- **Veredicto Android**: **Viable** pero complejo, mejor con SDK comercial

### 1.2 Evaluación de Integración con WhatsApp

#### API Oficial
- **WhatsApp NO tiene API pública** para leer/enviar mensajes desde apps de terceros
- WhatsApp Business API existe pero:
  - Solo para cuentas Business (no personales)
  - Requiere aprobación de Meta
  - Orientada a chatbots empresariales, no control de usuario final

#### Alternativas Técnicas

**Android:**
1. **Accessibility Services** (más viable):
   - Leer notificaciones de WhatsApp
   - Simular toques en UI de WhatsApp
   - Extraer texto de mensajes visibles
   - **Riesgo**: Frágil ante cambios de UI de WhatsApp

2. **Notification Listener Service**:
   - Capturar contenido de notificaciones de WhatsApp
   - Solo mensajes recientes (no historial completo)
   - No requiere root

**iOS:**
- **Shortcuts de Siri**: Limitados, no permiten leer mensajes
- **Intents de terceros**: WhatsApp no expone intents para apps externas
- **Veredicto iOS**: **Inviable** sin colaboración de WhatsApp

### 1.3 Recomendación Final

**DECISIÓN: Desarrollo FLUTTER (Híbrido) con enfoque Android-first + Platform Channels**

**Justificación:**
1. **Control remoto**: Solo viable en Android, pero implementable vía Platform Channels
2. **Integración WhatsApp**: Solo funcional en Android vía AccessibilityService (Platform Channels)
3. **Reutilización de código**: 70-80% del código (UI, lógica, ElevenLabs) compartible
4. **Camino a iOS preparado**: Aunque con funcionalidad limitada, la infraestructura estará lista
5. **Velocidad de desarrollo**: Hot Reload y ecosistema maduro aceleran desarrollo UI

**Estrategia de plataformas:**
- **Android (prioridad 1 - Mes 1-3)**: App completa con todas las funcionalidades
  - Control remoto completo ✅
  - Automatización WhatsApp ✅
  - Interfaz accesible ✅

- **iOS (opcional/futuro - v2.0)**: Versión con funcionalidad reducida pero útil
  - Interfaz simplificada ✅
  - Comandos de voz (ElevenLabs) ✅
  - Screen sharing solo lectura (ReplayKit) ⚠️
  - Sin control remoto ni automatización WhatsApp ❌

---

## 2. Stack Tecnológico Recomendado

### 2.1 Frontend - Flutter (Híbrido)

**Framework:** Flutter 3.19+

**Lenguaje:** Dart 3.0+

**Justificación:**
- **70-80% código reutilizable** entre Android/iOS (UI, lógica de negocio, integración ElevenLabs)
- **Hot Reload** acelera desarrollo de UI 2-3x vs nativo
- **Accesibilidad madura**: Flutter 3.3+ con TalkBack/VoiceOver bien integrados
- **Platform Channels** permiten acceso a AccessibilityService en Android
- **Camino preparado para iOS** sin costo adicional significativo
- Claude Code puede asistir efectivamente en Dart/Flutter

**Paquetes Flutter clave:**
```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI y Material Design
  material: ^3.0.0

  # Platform Channels para código nativo
  flutter_accessibility_service: ^3.0.0  # AccessibilityService wrapper

  # WebRTC para control remoto
  flutter_webrtc: ^0.9.48

  # Reconocimiento de voz (backup si ElevenLabs falla)
  speech_to_text: ^6.5.1

  # HTTP para ElevenLabs API
  http: ^1.1.0
  dio: ^5.4.0

  # WebSocket para ElevenLabs Realtime STT
  web_socket_channel: ^2.4.0

  # Persistencia local
  shared_preferences: ^2.2.2
  hive: ^2.2.3

  # State management
  provider: ^6.1.1  # o riverpod

  # Permisos
  permission_handler: ^11.1.0
```

**Código nativo requerido (Platform Channels):**
- **Android (Kotlin)**: AccessibilityService implementation
- **iOS (Swift)**: ReplayKit screen sharing (v2.0)

### 2.2 Backend/Servicios para Control Remoto

**DECISIÓN FINAL: Solución Custom con WebRTC (Inspirada en RustDesk)**

**Arquitectura:**
```
Cliente Flutter (Dart)
  ↓ flutter_webrtc
Signaling: Firebase Firestore (gratis tier Spark)
  ↓ WebRTC P2P
Streaming: Video/Screen + Control táctil
  ↓ Platform Channel
Android AccessibilityService (Kotlin)
```

**Componentes:**
- **Flutter WebRTC**: `flutter_webrtc` package para streaming
- **Señalización**: Firebase Firestore (gratis hasta 10K usuarios)
- **Captura de pantalla**: MediaProjection API (Android) vía Platform Channel
- **Control remoto**: AccessibilityService.dispatchGesture() (Kotlin nativo)

**Ventajas vs TeamViewer SDK:**
- ✅ **Costo: $0** (vs $500-1000/año)
- ✅ Control total sobre funcionalidad
- ✅ Sin dependencia de terceros
- ✅ Código open source para aprender de RustDesk

**Desventajas:**
- ⚠️ Mayor complejidad inicial (2-3 semanas vs 1 semana)
- ⚠️ Mantenimiento propio

**Referencia de implementación:**
- Estudiar código de [RustDesk](https://github.com/rustdesk/rustdesk) como guía
- NO fork directo, sino inspiración arquitectónica

**Infraestructura:**
- Firebase Firestore (gratis tier Spark)
- Firebase Cloud Messaging para notificaciones
- Sin servidor backend custom (todo P2P)

### 2.3 Servicios de Voz: ElevenLabs

**DECISIÓN: ElevenLabs Scribe v2 como STT/TTS principal**

**Speech-to-Text (Scribe v2):**
- **Latencia ultra-baja**: 150ms (ideal para comandos de voz)
- **Soporte**: 90+ idiomas incluido español
- **Modo realtime**: WebSocket API para streaming
- **Precisión superior**: Mejor que Android SpeechRecognizer para adultos mayores

**Text-to-Speech:**
- Voces naturales en español
- Feedback audible para confirmación de acciones
- Personalizable por preferencias de usuario

**Integración Flutter:**
```dart
// Ejemplo de integración
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class ElevenLabsService {
  final String apiKey;

  // STT Realtime
  Future<Stream<String>> startRealtimeSTT() async {
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://api.elevenlabs.io/v1/speech-to-text/realtime')
    );
    // Stream audio → recibir texto
  }

  // TTS
  Future<Uint8List> textToSpeech(String text) async {
    final response = await http.post(
      Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/...'),
      headers: {'xi-api-key': apiKey},
      body: json.encode({'text': text})
    );
    return response.bodyBytes;
  }
}
```

**Costo:**
- Según tu suscripción actual de ElevenLabs
- Verificar límites de minutos/requests incluidos
- Fallback a Android SpeechRecognizer si se exceden límites

### 2.4 Herramientas de Accesibilidad

**Testing:**
- Android Accessibility Scanner (Google)
- TalkBack en emulador Flutter (Android Studio)
- Dispositivo físico real (obligatorio para testing final)
- Flutter's built-in accessibility tools (`flutter run --analyze-accessibility`)

**Desarrollo Flutter:**
```dart
// Configuración de accesibilidad en Flutter
Semantics(
  label: 'Botón para abrir WhatsApp',
  button: true,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(200, 80), // Botones grandes
      textStyle: TextStyle(fontSize: 24), // Texto grande
    ),
    onPressed: () => openWhatsApp(),
    child: Text('Abrir WhatsApp'),
  ),
)

// Alto contraste
MaterialApp(
  theme: ThemeData(
    colorScheme: highContrast
      ? ColorScheme.highContrastLight()
      : ColorScheme.light(),
  ),
)
```

### 2.5 Servicios de Terceros Necesarios

| Servicio | Propósito | Costo Estimado | Alternativa |
|----------|-----------|----------------|-------------|
| **Firebase** | Firestore (signaling WebRTC), FCM | **Gratis** (tier Spark) | Supabase (open-source) |
| **ElevenLabs** | STT (Scribe v2) + TTS | **Según tu plan actual** | Android SpeechRecognizer (gratis, menos preciso) |
| **Control Remoto** | WebRTC DIY | **$0** | TeamViewer SDK ($500-1000/año) |

**Total estimado Año 1:**
- **$0 en infraestructura** (Firebase tier gratis suficiente)
- **Costo ElevenLabs**: Depende de tu suscripción actual
  - Revisar límites de minutos STT/TTS incluidos
  - Estimar uso: ~30 comandos/día × 3 seg/comando × 30 días = ~45 min/mes

**Costo total significativamente menor que estimado original ($500-1000 ahorrados al no usar TeamViewer SDK)**

---

## 3. Arquitectura de Alto Nivel

### 3.1 Diagrama Conceptual

```
┌─────────────────────────────────────────────────────────────────┐
│               APP FLUTTER (Dart - Multiplataforma)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         UI Layer (Flutter Widgets)                        │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Home         │  │ Remote       │  │ WhatsApp     │   │  │
│  │  │ Screen       │  │ Control      │  │ Screen       │   │  │
│  │  │ (Semantic    │  │ Screen       │  │              │   │  │
│  │  │  Widgets)    │  │              │  │              │   │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │  │
│  └─────────┼──────────────────┼──────────────────┼───────────┘  │
│            │                  │                  │              │
│  ┌─────────▼──────────────────▼──────────────────▼───────────┐ │
│  │     State Management (Provider/Riverpod)                  │ │
│  │   - VoiceCommandProvider                                  │ │
│  │   - WhatsAppProvider                                      │ │
│  │   - RemoteControlProvider                                 │ │
│  └─────────┬──────────────────┬──────────────────┬───────────┘ │
│            │                  │                  │              │
│  ┌─────────▼──────────────────▼──────────────────▼───────────┐ │
│  │              Services Layer (Dart)                        │ │
│  │   - ElevenLabsService (STT/TTS)                           │ │
│  │   - WhatsAppService (Platform Channel)                    │ │
│  │   - WebRTCService (flutter_webrtc)                        │ │
│  │   - PreferencesService (Hive)                             │ │
│  └─────────┬──────────────────┬──────────────────┬───────────┘ │
│            │                  │                  │              │
│            │      ┌───────────▼──────────┐       │              │
│            │      │  PLATFORM CHANNELS   │       │              │
│            │      │  (MethodChannel)     │       │              │
│            │      └───────────┬──────────┘       │              │
└────────────┼──────────────────┼──────────────────┼──────────────┘
             │                  │                  │
    ┌────────▼─────┐   ┌────────▼────────┐   ┌────▼───────────┐
    │ ElevenLabs   │   │ ANDROID NATIVE  │   │ Firebase       │
    │ API          │   │ (Kotlin/Java)   │   │ (Firestore/    │
    │              │   │                 │   │  FCM)          │
    │ - Scribe STT │   │ - Accessibility │   │                │
    │ - TTS        │   │   Service       │   │ - WebRTC       │
    │ (WebSocket/  │   │ - WhatsApp      │   │   Signaling    │
    │  REST)       │   │   Automation    │   │ - Session      │
    │              │   │ - Screen        │   │   Management   │
    │              │   │   Capture       │   │                │
    │              │   │ - Gesture       │   │                │
    │              │   │   Dispatch      │   │                │
    └──────────────┘   └─────────────────┘   └────────────────┘
                              │
                       ┌──────▼──────┐
                       │ WhatsApp    │
                       │ (App nativa)│
                       └─────────────┘

    [70-80% código compartido Flutter]
            ▼
    ┌─────────────────┐
    │  iOS (v2.0)     │  → Funcionalidad limitada:
    │  (Swift Native) │     - UI simplificada ✅
    │  - ReplayKit    │     - ElevenLabs STT/TTS ✅
    │    (Screen      │     - Screen sharing read-only ⚠️
    │     Share)      │     - NO control remoto ❌
    └─────────────────┘     - NO WhatsApp automation ❌
```

### 3.2 Componentes Principales

#### 3.2.1 Flutter Services (Dart)

**ElevenLabsService:**
```dart
class ElevenLabsService {
  final String apiKey;
  WebSocketChannel? _sttChannel;

  // Speech-to-Text Realtime
  Stream<String> startListening() async* {
    _sttChannel = WebSocketChannel.connect(
      Uri.parse('wss://api.elevenlabs.io/v1/speech-to-text/realtime'),
    );

    // Stream audio del micrófono → recibir transcripción
    yield* _sttChannel!.stream.map((data) =>
      json.decode(data)['text'] as String
    );
  }

  // Text-to-Speech
  Future<Uint8List> speak(String text) async {
    final response = await http.post(
      Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
      headers: {'xi-api-key': apiKey},
      body: json.encode({'text': text}),
    );
    return response.bodyBytes; // Reproducir con audioplayers package
  }
}
```

**WhatsAppService (Platform Channel):**
```dart
class WhatsAppService {
  static const platform = MethodChannel('com.tuapp/whatsapp');

  Future<void> openChat(String contactName) async {
    try {
      await platform.invokeMethod('openChat', {'name': contactName});
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  Future<List<String>> readLastMessages(String contactName) async {
    final result = await platform.invokeMethod('readMessages', {'name': contactName});
    return List<String>.from(result);
  }
}
```

#### 3.2.2 Android Native Code (Kotlin - Platform Channels)

**AccessibilityService Implementation:**
```kotlin
// android/app/src/main/kotlin/AssistantAccessibilityService.kt
class AssistantAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.packageName == "com.whatsapp") {
            // Detectar eventos de WhatsApp
            // Extraer texto de UI
            // Enviar a Flutter vía EventChannel
        }
    }

    fun openWhatsAppChat(contactName: String) {
        // 1. Abrir WhatsApp
        val intent = packageManager.getLaunchIntentForPackage("com.whatsapp")
        startActivity(intent)

        // 2. Buscar chat en UI usando AccessibilityNodeInfo
        // 3. Simular tap con dispatchGesture()
    }

    fun simulateTouch(x: Float, y: Float) {
        val path = Path().apply { moveTo(x, y) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()
        dispatchGesture(gesture, null, null)
    }
}
```

**Platform Channel Handler:**
```kotlin
// android/app/src/main/kotlin/MainActivity.kt
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tuapp/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openChat" -> {
                        val name = call.argument<String>("name")
                        // Llamar a AccessibilityService
                        accessibilityService?.openWhatsAppChat(name!!)
                        result.success(null)
                    }
                    "readMessages" -> {
                        // Leer últimos mensajes
                        val messages = accessibilityService?.readLastMessages()
                        result.success(messages)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

#### 3.2.3 WebRTC Remote Control (Flutter + Native)

**Flutter WebRTC Service:**
```dart
import 'package:flutter_webrtc/flutter_webrtc.dart';

class RemoteControlService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Future<void> startRemoteSession(String sessionId) async {
    // 1. Capturar pantalla (via Platform Channel)
    _localStream = await navigator.mediaDevices.getDisplayMedia({
      'video': true,
    });

    // 2. Crear PeerConnection
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // 3. Señalización via Firebase
    // Intercambiar SDP offers/answers
  }

  void handleRemoteTouch(double x, double y) {
    // Enviar a Platform Channel para ejecutar gesto
    WhatsAppService.platform.invokeMethod('simulateTouch', {
      'x': x,
      'y': y,
    });
  }
}
```

### 3.3 Flujo de Datos - Ejemplo: "Abrir WhatsApp de María"

```
1. Usuario presiona botón de micrófono (Flutter UI)
   ↓
2. VoiceCommandProvider inicia ElevenLabsService.startListening()
   ↓
3. ElevenLabs Scribe (WebSocket) → Stream: "Abrir WhatsApp de María"
   ↓
4. SimpleNLPParser (Dart) parsea →
   Command {
     action: "openChat",
     app: "whatsapp",
     contactName: "María"
   }
   ↓
5. WhatsAppProvider ejecuta WhatsAppService.openChat("María")
   ↓
6. Platform Channel (MethodChannel) → Android Native (Kotlin)
   ↓
7. AssistantAccessibilityService (Kotlin):
   a) Verifica que WhatsApp esté instalado
   b) Lanza WhatsApp con Intent
   c) Espera a que cargue UI (~500ms)
   d) Busca AccessibilityNodeInfo con texto "María"
   e) Obtiene coordenadas del elemento
   f) Ejecuta dispatchGesture() para simular tap
   ↓
8. Resultado → Platform Channel → Flutter
   ↓
9. ElevenLabsService.speak("Abriendo chat de María")
   ↓
10. TalkBack (Android) también anuncia la acción
```

### 3.4 Integraciones Externas

| Sistema Externo | Método Integración | Datos Intercambiados | Seguridad |
|----------------|--------------------|-----------------------|-----------|
| **ElevenLabs** | WebSocket (STT) / REST (TTS) | Audio ↔ Texto | API key, WSS/HTTPS |
| **WhatsApp** | AccessibilityService (Platform Channel) | Eventos UI, texto mensajes | Sin credenciales, solo UI automation |
| **TalkBack** | Flutter Semantics | Descripciones, roles | Estándar Android |
| **Firebase** | Firebase SDK (Flutter) | Tokens sesión, señales WebRTC | TLS, Firebase Auth |
| **WebRTC** | flutter_webrtc package | Video stream, gestos táctiles | DTLS-SRTP encryption |

---

## 4. Análisis de Riesgos Técnicos

### Riesgo 1: Cambios en UI de WhatsApp Rompen Funcionalidad
- **Impacto**: ALTO - La app deja de funcionar con WhatsApp
- **Probabilidad**: MEDIA - WhatsApp actualiza UI cada 2-3 meses
- **Mitigación**:
  - Usar IDs de recursos estables cuando sea posible
  - Implementar detección de versión de WhatsApp
  - Logs detallados para debug rápido
  - Tests automatizados con AccessibilityNodeInfo
  - Plan B: Accesos directos a intents de compartir de WhatsApp

### Riesgo 2: Rechazo en Google Play por Uso de Accessibility Services
- **Impacto**: CRÍTICO - No poder publicar la app
- **Probabilidad**: MEDIA-BAJA - Si se documenta correctamente el uso
- **Mitigación**:
  - Seguir exactamente las políticas de Google ([Accesibilidad en Play](https://support.google.com/googleplay/android-developer/answer/10964491))
  - Crear video demostrativo del uso legítimo
  - Declaración de privacidad clara: "No recopilamos datos, solo automatizamos acciones del usuario"
  - Considerar publicación directa (APK) como fallback

### Riesgo 3: Complejidad del Control Remoto Custom Excede 3 Meses
- **Impacto**: ALTO - Funcionalidad clave sin entregar
- **Probabilidad**: MEDIA - WebRTC + Accessibility es complejo, pero con referencia de RustDesk
- **Mitigación**:
  - **Usar código de RustDesk como referencia** (arquitectura probada)
  - Implementación simplificada: solo funciones core (no todas las features de RustDesk)
  - Priorizar features de accesibilidad local primero (Mes 1-2)
  - Control remoto en Mes 3 con tiempo buffer
  - Si falla: Plan B es usar RustDesk como app separada

### Riesgo 4: Permisos Peligrosos Confunden al Usuario Mayor
- **Impacto**: MEDIO - Usuario cancela instalación o no otorga permisos
- **Probabilidad**: ALTA - Avisos de Android son intimidantes
- **Mitigación**:
  - Tutorial inicial con capturas de pantalla paso a paso
  - Video tutorial (TikTok/YouTube corto)
  - Soporte remoto por familiar en primera configuración
  - Textos súper claros: "Tu familiar podrá ayudarte a distancia"

### Riesgo 5: Dispositivos de Gama Baja con Android 6-7
- **Impacto**: MEDIO - App lenta o incompatible
- **Probabilidad**: MEDIA - Público objetivo usa dispositivos antiguos
- **Mitigación**:
  - minSdkVersion = 24 (Android 7.0, 2016) cubre 95% dispositivos
  - Testing en emulador con RAM limitada (2GB)
  - Evitar animaciones complejas
  - Lazy loading de recursos

### Riesgo 6: Límites de ElevenLabs API Excedidos
- **Impacto**: MEDIO - STT/TTS deja de funcionar temporalmente
- **Probabilidad**: MEDIA - Depende de uso real y plan de suscripción
- **Mitigación**:
  - **Implementar fallback a Android SpeechRecognizer** cuando se exceden límites
  - Monitorear uso mensual proactivamente
  - Configurar alertas en dashboard de ElevenLabs
  - Optimizar: solo usar ElevenLabs para comandos críticos, SpeechRecognizer para otros

### Riesgo 7: Curva de Aprendizaje de Dart/Flutter
- **Impacto**: MEDIO - Retraso en desarrollo inicial
- **Probabilidad**: BAJA-MEDIA - Si vienes de JavaScript/TypeScript, Dart es similar
- **Mitigación**:
  - Claude Code puede asistir efectivamente con Dart
  - Sintaxis similar a lenguajes modernos (Kotlin, TypeScript)
  - Documentación oficial de Flutter es excelente
  - Semana 1 dedicada a setup + tutorial básico

---

## 5. Alternativas Evaluadas

### 5.1 Para Control Remoto de Pantalla

| Alternativa | Ventajas | Desventajas | Veredicto |
|-------------|----------|-------------|-----------|
| **WebRTC Custom (inspirado en RustDesk)** | - **$0 costo**<br>- Control total<br>- Código de referencia disponible<br>- Aprendizaje valioso | - 2-3 semanas desarrollo<br>- Mantenimiento propio<br>- Debugging de red complejo | ✅ **ELEGIDO** |
| **TeamViewer SDK** | - Implementación rápida (1 sem)<br>- Probado y seguro<br>- Soporte técnico | - **Costo NO público** (contacto ventas)<br>- Dependencia tercero<br>- Menor control | ❌ Rechazado por costo |
| **AnyDesk SDK** | - Similar a TeamViewer | - **NO existe SDK público**<br>- Solo REST API (no sirve para control) | ❌ No aplicable |
| **RustDesk como app separada** | - Gratis<br>- Ya funciona<br>- Cero desarrollo | - UX fragmentada (2 apps)<br>- Confusión para usuario mayor | ⚠️ **Plan B** si WebRTC falla |

**Decisión Final:**
1. **Implementar WebRTC custom** usando arquitectura de RustDesk como referencia
2. **No fork directo** de RustDesk, sino aprender de su código
3. **Plan B**: Integrar RustDesk como app separada si desarrollo custom excede tiempo

---

### 5.2 Para Integración con WhatsApp

| Alternativa | Viabilidad Técnica | UX | Complejidad | Veredicto |
|-------------|--------------------|----|-------------|-----------|
| **Accessibility Service UI Automation** | ✅ Funcional en Android<br>❌ Imposible en iOS | Buena (automatización real) | Media (2 semanas con Flutter Platform Channels) | ✅ **ELEGIDO** |
| **Notification Listener** | ✅ Funcional<br>Solo mensajes recientes | Limitada (no abre chats) | Baja (3 días) | ⚠️ Complemento |
| **WhatsApp Business API** | ❌ Solo cuentas business<br>❌ Requiere aprobación Meta | N/A | Alta | ❌ No aplicable |
| **Reverse engineering WhatsApp** | ❌ Ilegal (EULA WhatsApp)<br>❌ Ban de cuenta | N/A | Muy alta | ❌ Prohibido |
| **Atajos de Siri/Bixby** | ⚠️ Limitado a acciones preconfiguradas | Básica | Baja | ⚠️ Solo iOS v2.0 (reducido) |

**Decisión:** Accessibility Service (Kotlin nativo) + Platform Channel (Flutter) como método principal, complementado con Notification Listener para leer mensajes sin abrir WhatsApp.

### 5.4 Para Speech-to-Text / Text-to-Speech

| Alternativa | Precisión | Latencia | Idiomas | Costo | Veredicto |
|-------------|-----------|----------|---------|-------|-----------|
| **ElevenLabs Scribe v2** | Excelente | 150ms | 90+ (incl. español) | Según suscripción actual | ✅ **ELEGIDO (Principal)** |
| **Android SpeechRecognizer** | Buena | 200-500ms | Muchos | Gratis | ✅ **Fallback** |
| **Google Cloud Speech-to-Text** | Excelente | 100-300ms | 120+ | $0.006/15seg | ⚠️ Backup si ElevenLabs falla |
| **Whisper (OpenAI)** | Excelente | 1-3 seg | 99 | API o self-hosted | ❌ Latencia muy alta |

**Decisión:**
1. **ElevenLabs Scribe v2** como STT principal (ya tienes suscripción)
2. **ElevenLabs TTS** para feedback de voz
3. **Android SpeechRecognizer** como fallback si se exceden límites

---

### 5.3 Framework de Desarrollo

| Framework | Acceso a Accessibility | Curva Aprendizaje | Comunidad | Rendimiento | Código Compartido | Veredicto |
|-----------|----------------------|-------------------|-----------|-------------|-------------------|-----------|
| **Flutter** | ✅ Vía Platform Channels<br>(paquete `flutter_accessibility_service`) | Media | Muy buena | Muy bueno | **70-80%** Android/iOS | ✅ **ELEGIDO** |
| **Android Nativo (Kotlin + Compose)** | ✅ Directo, sin intermediarios | Media (con Claude Code) | Excelente | Excelente | **0%** (solo Android) | ❌ Descartado (no reutilizable) |
| **React Native** | ⚠️ Módulos nativos complejos<br>Mal soporte Accessibility | Media | Buena | Bueno | 60-70% | ❌ Limitaciones accesibilidad |
| **Ionic/Capacitor** | ❌ Muy limitado para Accessibility | Baja | Media | Regular | 80% | ❌ No soporta features críticas |

**Decisión Final:**
**Flutter con Platform Channels** porque:
1. ✅ **70-80% código reutilizable** entre Android/iOS
2. ✅ **Hot Reload** acelera desarrollo UI significativamente
3. ✅ **TalkBack bien integrado** desde Flutter 3.3+
4. ✅ **`flutter_accessibility_service` package** ya existe y funciona
5. ✅ **Camino preparado para iOS** (aunque funcionalidad limitada)
6. ✅ **Claude Code asiste efectivamente** con Dart
7. ⚠️ Solo AccessibilityService requiere código Kotlin (inevitable en cualquier framework)

---

## 6. Plan de Implementación Sugerido (3 Meses)

### Mes 1: Fundamentos Flutter + Platform Channels Básicos

**Semana 1: Setup y Fundamentos**
- Crear proyecto Flutter (Android-first)
- Configurar estructura de carpetas (lib/screens, lib/services, lib/providers)
- Implementar UI básica con Material 3
  - Botones grandes (mínimo 80dp altura)
  - Alto contraste configurable
  - Textos grandes (24sp mínimo)
- Integrar Flutter Semantics para TalkBack
- Setup Firebase (Firestore, FCM)

**Semana 2: ElevenLabs Integration**
- Implementar `ElevenLabsService`:
  - STT realtime (WebSocket)
  - TTS (REST API)
- Crear UI de comandos de voz
- Testing de precisión con adultos mayores (si posible)
- Fallback a Android SpeechRecognizer

**Semana 3-4: Platform Channels Android**
- Setup código Kotlin nativo
- Implementar `MethodChannel` básico
- AccessibilityService skeleton:
  - Detectar eventos del sistema
  - Permisos y configuración
- Testing de comunicación Flutter ↔ Kotlin

### Mes 2: Integración WhatsApp + Notification Listener

**Semana 5-6: WhatsApp Automation**
- Implementar AccessibilityService para WhatsApp:
  - Abrir app
  - Buscar contacto por nombre en UI
  - Simular tap con `dispatchGesture()`
- Platform Channel: `openChat(contactName)`
- Comandos de voz: "Abrir WhatsApp de [contacto]"
- Manejo de errores (app no instalada, contacto no existe)

**Semana 7-8: Leer Mensajes + Testing**
- Notification Listener Service (Kotlin):
  - Capturar notificaciones de WhatsApp
  - Extraer remitente y texto
  - Enviar a Flutter vía EventChannel
- Comando: "Leer mensajes de [contacto]"
- ElevenLabs TTS para leer mensajes en voz alta
- Testing exhaustivo:
  - Dispositivo físico real
  - Múltiples versiones de WhatsApp
  - Casos de error

### Mes 3: Control Remoto WebRTC + Refinamiento

**Semana 9: WebRTC Screen Sharing**
- Implementar `flutter_webrtc`:
  - MediaProjection API (Kotlin) para captura de pantalla
  - PeerConnection setup
  - Streaming a cliente remoto
- Firebase signaling (intercambio SDP)
- UI de sesión remota en Flutter

**Semana 10: Control Remoto Bidireccional**
- Recibir coordenadas táctiles desde cliente remoto
- Platform Channel: `simulateTouch(x, y)`
- AccessibilityService: `dispatchGesture()` para toques remotos
- Testing de latencia y UX

**Semana 11: Refinamiento y Onboarding**
- Tutorial paso a paso para permisos (Accessibility, Screen Capture)
- Video demostrativo para Google Play
- Optimización de rendimiento
- Accesibilidad 100% (Android Accessibility Scanner)

**Semana 12: Google Play + Buffer**
- Preparación de assets (capturas, descripción, video)
- Declaración de privacidad detallada (uso de AccessibilityService)
- Testing final en múltiples dispositivos
- **Buffer para imprevistos y correcciones**

### Estructura del Proyecto Flutter

```
lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   ├── voice_command_screen.dart
│   ├── whatsapp_screen.dart
│   └── remote_control_screen.dart
├── services/
│   ├── elevenlabs_service.dart
│   ├── whatsapp_service.dart (Platform Channel)
│   ├── webrtc_service.dart
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

android/
├── app/src/main/kotlin/
│   ├── MainActivity.kt
│   ├── AssistantAccessibilityService.kt
│   ├── WhatsAppAutomation.kt
│   └── NotificationListener.kt
└── app/src/main/AndroidManifest.xml
```

---

## 7. Consideraciones Finales

### 7.1 Limitaciones Conocidas a Comunicar al Usuario Final
1. **iOS no soportará control remoto ni automatización de WhatsApp** (limitaciones de Apple)
2. **Cambios en WhatsApp pueden requerir actualizaciones** de la app
3. **Algunos fabricantes (Xiaomi, Huawei)** tienen restricciones extra en Accessibility que requieren pasos manuales

### 7.2 Próximos Pasos Inmediatos
1. **Validar con 2-3 usuarios reales** del público objetivo el concepto
2. **Revisar plan de ElevenLabs**: Confirmar límites de minutos STT/TTS incluidos
3. **Setup proyecto Flutter**:
   ```bash
   flutter create --org com.tuapp accessibility_app
   cd accessibility_app
   flutter pub add flutter_accessibility_service flutter_webrtc provider
   ```
4. **Configurar Firebase** proyecto (Firestore + FCM)
5. **Estudiar código de RustDesk** (específicamente `/flutter/lib/models/native_model.dart` y `/android/app/src/main/kotlin/`)
6. **Iniciar desarrollo** con Claude Code siguiendo arquitectura propuesta

### 7.3 KPIs de Éxito
- **Técnico**: 95% comandos de voz reconocidos correctamente
- **UX**: Usuario puede abrir WhatsApp de contacto en <10 segundos
- **Control remoto**: Latencia <2 segundos en conexión 4G
- **Accesibilidad**: 100% conformidad con Android Accessibility Scanner

---

## Referencias Técnicas

### Documentación Oficial
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Android Accessibility Services](https://developer.android.com/guide/topics/ui/accessibility/service)
- [Google Play Policy: Accessibility](https://support.google.com/googleplay/android-developer/answer/10964491)

### Packages y SDKs
- [flutter_accessibility_service](https://pub.dev/packages/flutter_accessibility_service)
- [flutter_webrtc](https://pub.dev/packages/flutter_webrtc)
- [ElevenLabs Speech-to-Text](https://elevenlabs.io/docs/capabilities/speech-to-text)
- [ElevenLabs Realtime STT](https://elevenlabs.io/docs/api-reference/speech-to-text/v-1-speech-to-text-realtime)

### Referencias de Código
- [RustDesk GitHub Repository](https://github.com/rustdesk/rustdesk)
- [RustDesk Flutter-Rust Architecture](https://deepwiki.com/rustdesk/rustdesk/4-user-interface)
- [WebRTC Android Implementation](https://webrtc.github.io/webrtc-org/native-code/android/)

### Artículos y Comparativas
- [Flutter vs React Native: Accessibility Performance](https://dev.to/gabrielrovesti/react-native-vs-flutter-the-hidden-accessibility-performance-gap-1hi9)
- [Building Platform Channels in Flutter](https://dev.to/anurag_dev/building-custom-platform-channels-in-flutter-a-complete-guide-to-native-integration-2m5g)

---

## 8. RustDesk como Referencia (No Dependencia)

### Cómo Usar RustDesk en Este Proyecto

**RustDesk NO será:**
- ❌ Una dependencia directa
- ❌ Un fork que mantenemos
- ❌ Un SDK que integramos

**RustDesk SÍ será:**
- ✅ **Referencia arquitectónica**: Estudiar cómo implementaron AccessibilityService + WebRTC
- ✅ **Guía de implementación**: Ver ejemplos de `dispatchGesture()`, MediaProjection, etc.
- ✅ **Prueba de concepto**: Instalar RustDesk para validar UX de control remoto
- ✅ **Plan B**: Si nuestra implementación falla, integrar como app separada

### Archivos Clave de RustDesk para Estudiar

```
rustdesk/
├── flutter/
│   ├── lib/
│   │   ├── models/
│   │   │   └── native_model.dart    ← Platform FFI bridge (cómo comunican Flutter-Rust)
│   │   └── desktop/
│   └── android/
│       └── app/src/main/
│           ├── kotlin/
│           │   └── MainActivity.kt   ← Platform Channels
│           └── AndroidManifest.xml  ← Permisos AccessibilityService
└── src/
    └── platform/android/
        └── accessibility.rs         ← Lógica de AccessibilityService (Rust)
```

**Enfoque recomendado:**
1. Clonar repositorio localmente: `git clone https://github.com/rustdesk/rustdesk.git`
2. Estudiar solo los archivos relevantes (no intentar compilar todo)
3. Adaptar conceptos a nuestra arquitectura Flutter más simple
4. NO copiar código directamente, sino entender patrones

---

**Conclusión:** Proyecto viable en 3 meses con enfoque **Flutter híbrido**, usando **WebRTC custom** (inspirado en RustDesk) para control remoto, **ElevenLabs** para STT/TTS, y **AccessibilityService** (Platform Channels) para WhatsApp.

**Ventajas vs versión anterior:**
- **Ahorro de $500-1000/año** (sin TeamViewer SDK)
- **70-80% código reutilizable** para futuro iOS
- **Control total** sobre funcionalidades
- **Costos operativos: ~$0** (solo ElevenLabs según plan actual)

Requiere gestión cuidadosa de riesgos relacionados con políticas de Google Play y mantenimiento ante cambios de WhatsApp.
