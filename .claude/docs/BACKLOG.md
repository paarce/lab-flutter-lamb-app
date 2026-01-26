# BACKLOG - App de Accesibilidad para Adultos Mayores

**Fecha de creación:** 24 dic 2025
**Versión:** 1.0
**Sprint objetivo:** MVP (Semanas 1-6)

---

## ESPECIFICACIÓN DE FUNCIONALIDADES MVP

### FUNCIONALIDAD 1: Setup del Proyecto Flutter

#### Historia de Usuario
```
Como desarrollador del proyecto
Quiero tener una estructura base de Flutter correctamente configurada con todas las dependencias necesarias
Para poder desarrollar las funcionalidades del MVP de forma eficiente y mantenible
```

#### Criterios de Aceptación Funcional
- [ ] El proyecto Flutter compila sin errores en Android 7.0+
- [ ] La estructura de carpetas sigue la convención definida en CLAUDE.md
- [ ] Firebase está configurado y conectado correctamente (Firestore + FCM)
- [ ] Todas las dependencias base están instaladas y funcionando
- [ ] La app puede ejecutarse en emulador y dispositivo físico
- [ ] El estado de la aplicación se gestiona correctamente con Provider

#### Criterios de Aceptación Técnico
- [ ] Flutter SDK versión 3.19 o superior instalado
- [ ] Dart versión 3.0 o superior
- [ ] minSdkVersion = 24 (Android 7.0) en build.gradle
- [ ] targetSdkVersion = 34 (Android 14)
- [ ] Dependencias instaladas según pubspec.yaml:
  - provider: ^6.1.1
  - flutter_webrtc: ^0.9.48
  - flutter_accessibility_service: ^3.0.0
  - http: ^1.1.0
  - dio: ^5.4.0
  - web_socket_channel: ^2.4.0
  - hive: ^2.2.3
  - permission_handler: ^11.1.0
- [ ] Firebase configurado con google-services.json (gitignored)
- [ ] Archivo secrets.dart creado desde secrets.example.dart (gitignored)
- [ ] .gitignore actualizado para proteger secrets y credenciales
- [ ] Hot reload funciona correctamente

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si Firebase no está configurado correctamente?
  - Mostrar error claro indicando configuración faltante
  - Proveer link a documentación de Firebase setup
- ¿Qué pasa si las dependencias tienen conflictos de versión?
  - Documentar versiones exactas que funcionan
  - Usar dependency_overrides si es necesario
- ¿Qué pasa si el dispositivo tiene Android <7.0?
  - Mostrar mensaje claro: "Requiere Android 7.0 o superior"
  - No permitir instalación en Play Store para versiones antiguas

#### Dependencias Técnicas
- **Permisos requeridos:** Ninguno (solo setup base)
- **APIs/SDKs necesarios:**
  - Flutter SDK 3.19+
  - Android SDK API 24+
  - Firebase SDK (Firestore, FCM)
- **Servicios de terceros:**
  - Firebase (cuenta configurada)
  - Cuenta Google para Firebase Console

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [x] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 2: WebRTC + Firebase para Control Remoto

#### Historia de Usuario
```
Como familiar de una persona con baja visión
Quiero conectarme remotamente al dispositivo de mi familiar usando un código simple de sesión
Para poder ver su pantalla y ayudarle a resolver problemas sin estar físicamente presente
```

#### Criterios de Aceptación Funcional
- [ ] El usuario (adulto mayor) puede generar un código de sesión de 4-6 dígitos desde la app
- [ ] El familiar puede ingresar el código desde su dispositivo y conectarse en <30 segundos
- [ ] La pantalla del adulto mayor se transmite en tiempo real con latencia <2 segundos en WiFi
- [ ] El familiar puede tocar elementos en la pantalla y estos toques se ejecutan en el dispositivo remoto
- [ ] El código de sesión es visible con texto grande (mínimo 48sp) y alto contraste
- [ ] La sesión se anuncia audiblemente: "Sesión remota iniciada. Código: [números]"
- [ ] Existe timeout automático de seguridad (15 minutos sin actividad)
- [ ] El usuario puede cancelar la sesión remota en cualquier momento con botón grande
- [ ] Indicadores visuales claros del estado de conexión (conectando, conectado, desconectado)

#### Criterios de Aceptación Técnico
- [ ] Implementado usando flutter_webrtc package versión 0.9.48+
- [ ] Signaling server implementado con Firebase Firestore
- [ ] STUN servers configurados (stun:stun.l.google.com:19302)
- [ ] Screen capture usando MediaProjection API (Android) vía Platform Channel
- [ ] Control remoto implementado con AccessibilityService.dispatchGesture()
- [ ] Códigos de sesión generados aleatoriamente (6 dígitos, sin ambigüedades: sin O/0, I/1)
- [ ] Sesiones almacenadas en Firestore con TTL de 15 minutos
- [ ] Transmisión de video en resolución adaptativa (360p-720p según ancho de banda)
- [ ] Encriptación DTLS-SRTP habilitada por defecto en WebRTC
- [ ] Manejo de reconexión automática ante pérdida temporal de red (<10 segundos)
- [ ] Logs estructurados para debugging de conexiones

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si no hay conexión a internet?
  - Mostrar error claro: "No hay conexión a internet. Conéctate a WiFi o datos móviles"
  - Anunciar error con TTS
  - Deshabilitar botón de iniciar sesión remota
- ¿Qué pasa si el usuario niega permiso de captura de pantalla?
  - Mostrar tutorial visual paso a paso
  - Explicar con TTS: "Para compartir tu pantalla, necesito permiso. Te llevaré a la configuración"
  - Proveer botón para abrir configuración nuevamente
- ¿Qué pasa si el código de sesión es inválido o expiró?
  - Mensaje claro: "El código no es válido o expiró. Solicita un nuevo código"
  - Permitir reintentar inmediatamente
- ¿Qué pasa si la conexión se cae durante la sesión?
  - Intentar reconectar automáticamente (máximo 3 intentos en 30 segundos)
  - Notificar al usuario: "Conexión perdida. Reintentando..."
  - Si falla: "Sesión terminada. Genera un nuevo código si necesitas ayuda"
- ¿Qué pasa si el dispositivo está en red 3G/4G con ancho de banda limitado?
  - Reducir calidad de video automáticamente
  - Mostrar advertencia: "Conexión lenta. La calidad de video puede ser baja"

#### Dependencias Técnicas
- **Permisos requeridos:**
  - android.permission.INTERNET
  - android.permission.RECORD_AUDIO (para futuro audio bidireccional)
  - android.permission.FOREGROUND_SERVICE
  - Permiso de captura de pantalla (MediaProjection)
  - Permiso de AccessibilityService (para control remoto)
- **APIs/SDKs necesarios:**
  - flutter_webrtc: ^0.9.48
  - Firebase Firestore SDK
  - MediaProjection API (Android)
  - AccessibilityService API (Android)
- **Servicios de terceros:**
  - Firebase Firestore (signaling)
  - STUN servers (Google públicos)

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 3: Interfaz Accesible Básica

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero una interfaz con botones grandes, texto legible y navegable solo con TalkBack
Para poder usar la aplicación de forma independiente sin necesidad de ver claramente la pantalla
```

#### Criterios de Aceptación Funcional
- [ ] Todos los botones tienen altura mínima de 80dp
- [ ] Todo el texto tiene tamaño mínimo de 24sp
- [ ] El contraste entre texto y fondo cumple WCAG 2.1 nivel AA (mínimo 4.5:1)
- [ ] Modo de alto contraste configurable desde la pantalla de inicio
- [ ] Navegación completa posible usando solo TalkBack (sin mirar pantalla)
- [ ] Cada elemento interactivo tiene Semantics con label y hint descriptivos
- [ ] Los botones se anuncian correctamente con TalkBack (rol de "botón")
- [ ] El espacio entre elementos táctiles es mínimo 16dp
- [ ] No hay dependencia de color únicamente para comunicar información
- [ ] Todos los íconos tienen etiquetas de texto descriptivas
- [ ] La app pasa Android Accessibility Scanner sin warnings críticos
- [ ] Timeouts de al menos 30 segundos para acciones que requieren confirmación

#### Criterios de Aceptación Técnico
- [ ] Implementado usando Material Design 3 con ColorScheme.highContrastLight()
- [ ] Todos los widgets interactivos envueltos en Semantics
- [ ] Tamaño de botones: minimumSize: Size(200, 80) en ElevatedButton.styleFrom()
- [ ] TextStyle con fontSize mínimo de 24.0
- [ ] Contraste configurado en ThemeData.colorScheme
- [ ] Orden de foco configurado con OrdinalSortKey donde sea necesario
- [ ] Animaciones respetan MediaQuery.disableAnimations
- [ ] Probado con `flutter run --analyze-accessibility`
- [ ] Compatible con gestos de TalkBack:
  - Swipe derecha/izquierda: navegación entre elementos
  - Doble tap: activar elemento
  - Dos dedos swipe up: scroll hacia arriba
- [ ] Pantallas principales:
  - home_screen.dart: Menú principal con botones grandes
  - remote_control_screen.dart: Código de sesión grande + botón cancelar
  - voice_command_screen.dart: Botón micrófono grande + feedback visual
  - whatsapp_screen.dart: Lista de contactos frecuentes

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si TalkBack no está activado?
  - Mostrar tutorial al primer inicio: "Para mejor experiencia, activa TalkBack"
  - Proveer botón directo a configuración de accesibilidad
- ¿Qué pasa si el usuario tiene configurado texto del sistema extra grande?
  - La UI debe adaptarse sin romper layout
  - Testar con scaling 2.0x en configuración Android
- ¿Qué pasa si el dispositivo tiene pantalla muy pequeña (<5 pulgadas)?
  - Permitir scroll vertical en todas las pantallas
  - Mantener tamaños mínimos (no reducir botones)
- ¿Qué pasa si el usuario toca accidentalmente botones adyacentes?
  - Espacio mínimo 16dp reduce probabilidad
  - Confirmación para acciones críticas (ej: cancelar sesión remota)

#### Dependencias Técnicas
- **Permisos requeridos:** Ninguno específico (UI base)
- **APIs/SDKs necesarios:**
  - Flutter Material Design 3
  - Flutter Semantics API
  - Android TalkBack (del sistema)
- **Servicios de terceros:**
  - Android Accessibility Scanner (para testing)

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 4: Sistema de Comandos de Voz (Voice Commands)

**Visión General:**
Sistema completo de interacción por voz que permite a usuarios con baja visión controlar la app mediante comandos naturales. Implementado en fases incrementales desde infraestructura básica hasta asistencia inteligente con LLM.

**Arquitectura de Comandos:**
```dart
enum CommandCategory {
  system,      // Acciones de sistema (contraste, volumen, navegación)
  assistance,  // Ayuda remota, tutoriales
  whatsapp,    // Operaciones de WhatsApp
  visual,      // Asistente visual (descripción de imágenes, OCR)
}

class VoiceCommand {
  CommandCategory category;
  String action;           // ej: "toggle_contrast", "request_help", "open_chat"
  Map<String, dynamic> params;  // ej: {"contact": "María"}
}
```

**Parser Híbrido:**
1. Keywords locales (latencia <50ms, offline) → 80% casos
2. LLM local (si keywords fallan, latencia ~500ms) → 15% casos
3. LLM cloud (contexto complejo, latencia ~2s) → 5% casos

**UX Simplificada:**
- ✅ FAB (FloatingActionButton) push-to-talk en HomeScreen (siempre accesible)
- ✅ Overlay modal durante grabación (feedback visual)
- ❌ NO pantalla dedicada VoiceCommandScreen (sobrecarga cognitiva)

---

### FUNCIONALIDAD 4.1: Voice Command Infrastructure (Core)

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero presionar un botón de micrófono y dar comandos simples
Para interactuar con la aplicación sin necesidad de leer texto en pantalla
```

#### Criterios de Aceptación Funcional
- [x] FAB push-to-talk siempre visible en HomeScreen (esquina inferior derecha)
- [x] Overlay modal aparece al presionar FAB con indicador de grabación
- [x] Transcripción en tiempo real se muestra en overlay (texto grande, 28sp)
- [x] Feedback audible confirma cada acción (TTS con flutter_tts)
- [x] Parser híbrido: keywords locales primero, fallback a LLM después
- [ ] Fallback a Android SpeechRecognizer si ElevenLabs falla (4.1.1 - v1.1)
- [x] Usuario puede cancelar con botón X en overlay o diciendo "cancelar"
- [x] Timeout de 10 segundos con reset en cada palabra reconocida
- [x] Comandos básicos reconocidos e implementados:
  - Sistema: "alto contraste" ✅ (toggle de tema dinámico)
  - Asistencia: "solicitar ayuda" ✅ (navegación a RemoteControlHostScreen)
  - WhatsApp: "abrir whatsapp" ⏳ (reconocido, integración pendiente Feature 5)

#### Criterios de Aceptación Técnico
- [x] Implementado con ElevenLabs Scribe v2 (WebSocket API) como STT principal
- [x] flutter_tts (motor nativo) para síntesis de voz (cambio: no ElevenLabs TTS)
- [ ] Fallback a Android SpeechRecognizer cuando: (v1.1 - diseñado pero no implementado)
  - ElevenLabs API retorna error 429 (límite excedido)
  - No hay conexión a internet
  - API key inválida o expirada
- [x] API key almacenada en secrets.dart (gitignored)
- [x] WebSocket connection a wss://api.elevenlabs.io/v1/speech-to-text/realtime
- [x] Audio del micrófono capturado con permission RECORD_AUDIO
- [x] Parser NLP simple (utils/nlp_parser.dart) para extraer intención basado en keywords
- [x] Audio TTS reproducido con flutter_tts (motor nativo Android/iOS)
- [x] Timeout de escucha: 10 segundos, reseteado en cada palabra reconocida
- [x] Heurística de 3 palabras para procesar comando rápidamente
- [x] Logging estructurado con developer.log() en puntos clave
- [x] State management con VoiceCommandProvider (ChangeNotifier)

#### Edge Cases y Manejo de Errores
- ✅ ¿Qué pasa si no hay conexión a internet?
  - ErrorHandlerService muestra error accesible + TTS
  - Futuro (v1.1): Fallback a Android SpeechRecognizer
- ✅ ¿Qué pasa si el usuario niega permiso de micrófono?
  - Implementado: Check en initState() de VoiceCommandScreen
  - ErrorHandlerService muestra diálogo accesible
  - TTS anuncia error de permiso
- ✅ ¿Qué pasa si ElevenLabs retorna error?
  - ErrorHandlerService maneja error centralizado
  - Logging con developer.log()
  - Futuro (v1.1): Fallback automático a Android SpeechRecognizer
- ✅ ¿Qué pasa si el comando no se entiende?
  - TTS: "No entendí el comando. Intenta de nuevo."
  - Lista de comandos disponibles visible en pantalla cuando idle
  - NLPParser retorna CommandType.unknown
- ✅ ¿Qué pasa si el usuario dice "cancelar"?
  - Reconocido con prioridad alta en NLPParser
  - Detiene listening inmediatamente
  - TTS anuncia: "Cancelado"
- ✅ ¿Qué pasa si timeout de 10s se cumple?
  - Timer se resetea en cada palabra reconocida
  - Si 10s sin palabras: detiene listening automáticamente
  - TTS anuncia: "Tiempo agotado"

#### Dependencias Técnicas
- **Permisos requeridos:**
  - android.permission.RECORD_AUDIO ✅
  - android.permission.INTERNET ✅
- **APIs/SDKs necesarios:**
  - ElevenLabs Scribe v2 API (WebSocket) ✅
  - flutter_tts: ^0.0.45 (motor nativo para TTS) ✅
  - web_socket_channel: ^2.4.0 ✅
  - permission_handler: ^11.1.0 ✅
  - provider: ^6.1.1 (state management) ✅
  - Android SpeechRecognizer (fallback v1.1) ⏳
- **Servicios de terceros:**
  - ElevenLabs API (requiere API key válida en secrets.dart) ✅

#### Archivos Implementados (4.1 Core)
- ✅ `lib/models/command.dart` - Modelo base VoiceCommand con category + action + params
- ✅ `lib/utils/nlp_parser.dart` - Parser híbrido keywords → LLM
- ✅ `lib/providers/voice_command_provider.dart` - State management con timeout
- ✅ `lib/screens/voice_command_screen.dart` - **DEPRECADO** (reemplazar con FAB + overlay)
- ✅ `lib/services/elevenlabs_service.dart` - STT via WebSocket
- ✅ `lib/services/tts/` - TTS abstraction con flutter_tts
- ✅ `test/utils/nlp_parser_test.dart` - Unit tests del parser

#### Refactorización Pendiente (UX Simplificada)
- ⏳ Reemplazar VoiceCommandScreen con FAB en HomeScreen
- ⏳ Crear VoiceOverlay widget modal para feedback de grabación
- ⏳ Migrar lógica de VoiceCommandProvider a nueva UX

#### Estatus 4.1
- [x] Core implementado (18 ene 2026)
- [ ] Refactorización UX a FAB (pendiente)
- [ ] Testing con usuarios reales

---

### FUNCIONALIDAD 4.2: System Actions (Comandos de Sistema) ✅

**Completado en 4.1 (18 ene 2026) y 4.5 (25 ene 2026)**

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero controlar configuraciones de la app por voz
Para ajustar contraste, volumen y navegar sin tocar la pantalla
```

#### Criterios de Aceptación Funcional
- [x] "Alto contraste" / "Activar contraste" → Cambia tema a high contrast (4.1)
- [x] "Subir volumen" / "Bajar volumen" → Ajusta volumen TTS (4.1)
- [x] "Volumen al máximo" / "Silencio" → Ajusta volumen absoluto (4.1)
- [x] "Volumen al X por ciento" → Ajusta volumen específico (4.1)
- [x] Feedback TTS confirma cada acción de sistema (4.1)

#### Criterios de Aceptación Técnico
- [x] ThemeProvider para gestionar cambio de tema (4.1)
- [x] Integración con TTSService para ajuste de volumen (4.1)
- [x] Keywords en NLPParser con prioridades (4.1)

#### Archivos Creados
- [x] `lib/providers/theme_provider.dart` (4.1)
- [x] `lib/models/app_theme.dart` (4.1)
- [x] Actualizado `lib/utils/nlp_parser.dart` (4.1)

#### Estatus 4.2
- [x] **COMPLETADO** ✅ (funcionalidad integrada en 4.1 y 4.5)

---

### FUNCIONALIDAD 4.3: Assistance Actions (Comandos de Ayuda) ✅

**Completado en 4.1 (18 ene 2026)**

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero solicitar ayuda remota por voz
Para que mi familiar se conecte sin necesidad de navegar manualmente
```

#### Criterios de Aceptación Funcional
- [x] "Solicitar ayuda" / "Necesito ayuda" → Navega a RemoteControlHostScreen (4.1)
- [x] "Tutorial" / "Ayuda" → Reproduce tutorial de voz sobre cómo usar la app (4.1)
- [x] "¿Qué puedo decir?" / "Comandos disponibles" → Lista comandos disponibles por voz (4.1)
- [x] Tutorial de voz guiado con pausas entre instrucciones (4.1)
- [x] Lista de comandos actualizada con nuevas funcionalidades (4.5)

#### Criterios de Aceptación Técnico
- [x] CommandType.requestHelp → Reproduce tutorial (4.1)
- [x] CommandType.playTutorial → Reproduce tutorial (4.1)
- [x] CommandType.listCommands → Lista comandos (4.1)
- [x] CommandType.shareScreen → Navegación a RemoteControlHostScreen (4.1)
- [x] TTS dinámico para tutorial y lista de comandos (4.1)
- [x] Tutorial actualizado con comandos de sistema (4.5)
- [x] Lista actualizada con secciones Sistema y Social (4.5)

#### Archivos Modificados
- [x] `lib/providers/voice_command_provider.dart` - Tutorial y lista de comandos (4.1, 4.5)
- [x] `lib/utils/nlp_parser.dart` - Keywords de ayuda (4.1)

#### Estatus 4.3
- [x] **COMPLETADO** ✅ (funcionalidad integrada en 4.1)

---

### FUNCIONALIDAD 4.4: LLM Remote Enhancement (Mejora con LLM Cloud) ✅

**Prioridad: P2 (Post-MVP - v1.1)** → **COMPLETADO 24 ene 2026**

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero dar comandos más naturales y conversacionales
Para no tener que memorizar palabras clave exactas
```

#### Criterios de Aceptación Funcional
- [x] Parser híbrido usa LLM cloud cuando keywords locales fallan
- [x] LLM extrae intención + parámetros de frases complejas
  - Ejemplo: "Quiero hablar con mi hija María" → {type: open_chat, params: {contact: "maría"}}
  - Ejemplo: "necesito que alguien me ayude" → {type: request_help, params: null}
- [ ] LLM mantiene contexto de sesión (conversación multi-turno) → **Deferred to v1.2**
- [x] Latencia objetivo: <3 segundos para comandos complejos
- [x] Fallback a keywords si LLM falla o timeout

#### Criterios de Aceptación Técnico
- [x] Integración con Claude API (Anthropic) - Claude 3 Haiku
- [x] Prompt engineering para extraer structured commands
- [x] Cache de respuestas LLM para comandos frecuentes (TTL 5 min, max 100 entradas)
- [x] Rate limiting y manejo de cuotas de API (timeout 3s, manejo 429)
- [x] Logging de comandos no resueltos para mejorar prompts

#### Archivos Creados
- [x] `lib/services/llm_parser_service.dart` - Cliente Claude API (~180 líneas)
- [x] `lib/services/llm_command_cache.dart` - Cache en memoria (~85 líneas)
- [x] Actualizado `lib/providers/voice_command_provider.dart` con flujo híbrido
- [x] `.claude/docs/manual-test-cases/FUNCIONALIDAD_4.4_LLM_PARSER.md` - 18 test cases

#### Archivos Modificados
- [x] `lib/config/secrets.example.dart` - Claude API key
- [x] `lib/main.dart` - LLMParserService provider injection
- [x] `lib/errors/error_codes.dart` - Códigos LLM
- [x] `lib/errors/error_category.dart` - Categoría LLM
- [x] `lib/utils/error_messages.dart` - Mensajes LLM

#### Estatus 4.4
- [x] Por hacer (Post-MVP)
- [x] Diseño de prompts
- [x] Implementación
- [x] Testing (18 test cases documentados)
- [x] **COMPLETADO** ✅

#### Notas de Implementación
- **Modelo:** Claude 3 Haiku (rápido y económico)
- **Costo:** ~$0.0001 por comando (~$6/mes para 1000 usuarios)
- **Latencia promedio:** 300-1500ms (depende de internet)
- **Cache hit:** <50ms (10-30x más rápido)
- **Variaciones reconocidas:**
  - Request Help: "necesito ayuda", "ayúdenme", "requiero asistencia"
  - Toggle Contrast: "ponme los colores más fuertes", "aumenta el contraste"
  - Volume: "sube el sonido", "baja un poco", "ponlo al máximo"
  - Open WhatsApp: "hablar con María", "llama a Juan", "escríbele a Pedro"

---

### FUNCIONALIDAD 4.5: Comandos de Sistema + Respuestas Sociales + System Prompt Externalizado ✅

**Prioridad: P1 (Alta - MVP)** → **COMPLETADO 25 ene 2026**

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero obtener información del sistema (hora, fecha, batería) y dar comandos sociales básicos por voz
Para usar la app de forma más completa sin necesidad de acceder a configuraciones
```

#### Criterios de Aceptación Funcional
- [x] **Comandos de Sistema:**
  - [x] "Qué hora es" → Anuncia hora en formato accesible ("2:30 de la tarde")
  - [x] "Qué día es hoy" → Anuncia fecha completa ("25 de enero de 2026")
  - [x] "Cuánta batería tengo" → Anuncia nivel de batería ("75 por ciento")
- [x] **Respuestas Sociales (LIMITADO - solo 2):**
  - [x] "Gracias" → Responde "De nada, para eso estoy"
  - [x] "Adiós" → Responde "Hasta luego"
- [x] **Rechazo de Conversaciones:**
  - [x] Saludos sin objetivo ("hola", "buenos días") → Rechaza amablemente y sugiere comandos
  - [x] No mantiene conversaciones casuales
- [x] **Contador de Comandos Unknown:**
  - [x] 3 comandos unknown consecutivos → Ayuda proactiva (reproduce lista de comandos)
  - [x] Contador se resetea con cualquier comando válido
- [x] **System Prompt Externalizado:**
  - [x] Prompt movido a `/lib/prompts/llm_system_prompt.dart`
  - [x] Lazy loading + cache en memoria
  - [x] Incluye todos los comandos nuevos en el prompt

#### Criterios de Aceptación Técnico
- [x] **Platform Channel Kotlin → Flutter:**
  - [x] `SystemInfoService` con 3 métodos: getTime(), getDate(), getBatteryLevel()
  - [x] Channel: `"com.accessibilityapp/system_info"`
  - [x] Formatos accesibles implementados en Kotlin
- [x] **6 Nuevos CommandType:**
  - [x] Sistema: getTime, getDate, getBatteryLevel
  - [x] Social: thankYou, goodbye
  - [x] Rechazo: conversationRejected
- [x] **Parser Local (NLPParser):**
  - [x] Keywords para sistema, social y saludos
  - [x] Prioridades actualizadas (1-12)
  - [x] Detección de saludos sin objetivo
- [x] **VoiceCommandProvider:**
  - [x] Contador `_consecutiveUnknownCommands` con threshold de 3
  - [x] Métodos helper: `_incrementUnknownCounter()`, `_resetUnknownCounter()`
  - [x] Ejecución de 7 nuevos casos de comando
  - [x] Reset en TODOS los comandos exitosos
- [x] **Tutorial y Lista Actualizados:**
  - [x] Tutorial menciona comandos de sistema
  - [x] Lista de comandos incluye secciones de Sistema y Social
- [x] **LLM Parser:**
  - [x] System prompt externalizado
  - [x] Mapeo de 6 nuevos tipos de comando
  - [x] Reglas explícitas para rechazar conversaciones

#### Archivos Creados (4)
- [x] `lib/prompts/llm_system_prompt.dart` - Loader de prompt con cache
- [x] `lib/services/system_info_service.dart` - Platform channel Flutter
- [x] `.claude/docs/manual-test-cases/FUNCIONALIDAD_4.5_SISTEMA_SOCIAL.md` - 24 test cases

#### Archivos Modificados (6)
- [x] `lib/models/command.dart` - +6 CommandType enums
- [x] `lib/utils/nlp_parser.dart` - +6 keywords + prioridades
- [x] `lib/services/llm_parser_service.dart` - Usa prompt externo + mapeo nuevos tipos
- [x] `lib/providers/voice_command_provider.dart` - Contador + ejecución + reseteos
- [x] `android/app/src/main/kotlin/com/accessibilityapp/lamb/MainActivity.kt` - +1 channel + 3 métodos
- [x] `lib/main.dart` - SystemInfoService injection

#### Estatus 4.5
- [x] Diseño completado (25 ene 2026)
- [x] Implementación (25 ene 2026)
- [x] Testing (24 test cases documentados)
- [x] **COMPLETADO** ✅

#### Notas de Implementación
- **Formatos accesibles:** "2:30 de la tarde" no "14:30", "25 de enero" no "25/01"
- **Respuestas sociales limitadas:** Solo gracias y adiós (no conversaciones)
- **Rechazo amable:** Redirige a comandos disponibles
- **Ayuda proactiva:** Después de 3 fallos, reproduce lista automáticamente
- **System prompt:** Fácilmente editable, versionable en git
- **Compatibilidad:** Android 7.0+ (API 21+)
- **Tiempo real:** 2 horas vs 4-5 días estimados ✅

---

### FUNCIONALIDAD 4.6: Firebase Analytics (Tracking de Comandos)

**Prioridad: P2 (Post-MVP - v1.2)** *(Renumerado desde 4.5)*

#### Historia de Usuario
```
Como desarrollador del proyecto
Quiero analizar qué comandos usan más los usuarios
Para mejorar el parser y priorizar nuevas funcionalidades
```

#### Criterios de Aceptación Funcional
- [ ] Todos los comandos reconocidos se loggean en Firebase Analytics
- [ ] Comandos no reconocidos se reportan con transcripción completa
- [ ] Dashboard en Firebase muestra:
  - Top 10 comandos más usados
  - Tasa de éxito del parser (keywords vs LLM vs unknown)
  - Latencia promedio por tipo de parser
- [ ] Privacy-compliant: NO loggear contenido sensible (nombres, mensajes)

#### Criterios de Aceptación Técnico
- [ ] Firebase Analytics SDK integrado
- [ ] Eventos custom: command_recognized, command_failed, parser_fallback
- [ ] Parámetros: category, action, parser_type, latency_ms
- [ ] Consent management para GDPR/CCPA
- [ ] Agregación semanal de métricas

#### Archivos a Crear
- `lib/services/analytics_service.dart` - Wrapper de Firebase Analytics
- `lib/models/command_analytics.dart` - Modelo para eventos

#### Estatus 4.6
- [ ] Por hacer (Post-MVP v1.2)
- [ ] Firebase Analytics setup
- [ ] Implementación
- [ ] Dashboard configurado

---

### FUNCIONALIDAD 5: Integración WhatsApp (Deep Links + Voice Commands)

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero abrir WhatsApp y mis chats frecuentes por voz o botón grande
Para comunicarme con mis contactos sin necesidad de buscar manualmente
```

#### Criterios de Aceptación Funcional
- [x] "Abrir WhatsApp" por voz → Abre la app (platform channel implementado)
- [ ] "Abrir chat de [nombre]" por voz → Abre chat específico si tiene número guardado
- [ ] Lista de contactos frecuentes (máximo 6-8) con botones grandes 80dp
- [ ] Al presionar contacto, abre WhatsApp en el chat específico
- [ ] Si WhatsApp no instalado: mensaje claro + TTS "WhatsApp no está instalado"
- [ ] Feedback audible confirma: "Abriendo WhatsApp de María"
- [ ] Familiar puede ayudar remotamente a configurar contactos frecuentes
- [ ] Comandos de voz integrados con CommandCategory.whatsapp

#### Criterios de Aceptación Técnico
- [ ] Implementado usando deep links de WhatsApp: whatsapp:// y wa.me/
- [ ] NO requiere AccessibilityService (reservado para v1.0)
- [ ] Lista de contactos almacenada localmente en Hive
- [ ] Estructura de datos: Map<String, String> → {"María": "+521234567890"}
- [ ] Intent de Android para abrir WhatsApp:
  - General: Intent(Intent.ACTION_VIEW, Uri.parse("whatsapp://"))
  - Chat específico: Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$phoneNumber"))
- [ ] Validación de formato de número telefónico (incluye código de país)
- [ ] Platform Channel: whatsAppService.openApp() y openChat(phoneNumber)
- [ ] Detección de instalación de WhatsApp vía PackageManager
- [ ] UI de configuración de contactos con formulario accesible:
  - Campo nombre (Semantics label)
  - Campo número con teclado numérico
  - Validación en tiempo real
- [ ] Parser NLP extrae nombre de contacto del comando de voz

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si WhatsApp no está instalado?
  - Verificar con PackageManager antes de intentar abrir
  - Mensaje claro: "WhatsApp no está instalado. ¿Quieres instalarlo?"
  - Botón directo a Google Play Store
  - TTS: "WhatsApp no encontrado en tu dispositivo"
- ¿Qué pasa si el número telefónico no tiene código de país?
  - Agregar código de país por defecto (configurable: ej. +52 para México)
  - Mostrar advertencia si el formato parece incorrecto
- ¿Qué pasa si el contacto dice un nombre que no está en la lista?
  - TTS: "No encontré contacto llamado [nombre]. ¿Quieres agregarlo?"
  - Mostrar lista de contactos disponibles
- ¿Qué pasa si el usuario no tiene contactos configurados?
  - Tutorial inicial: "Configura tus contactos frecuentes para acceso rápido"
  - Permitir que el familiar configure remotamente via control remoto
  - Botón grande "Agregar contacto" en pantalla WhatsApp
- ¿Qué pasa si WhatsApp está bloqueado o crashea?
  - Error manejado por Android (fuera de nuestro control)
  - Si Intent falla: "No se pudo abrir WhatsApp. Intenta de nuevo"

#### Dependencias Técnicas
- **Permisos requeridos:** Ninguno específico (solo Intents)
- **APIs/SDKs necesarios:**
  - Android Intent API
  - Android PackageManager
  - Hive (base de datos local): ^2.2.3
  - WhatsApp deep links (documentación: https://faq.whatsapp.com/general/chats/how-to-use-click-to-chat)
- **Servicios de terceros:**
  - WhatsApp instalado en el dispositivo (validación requerida)

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 6: Asistente Visual (Visual Assistant)

**Prioridad: P3 (Post-MVP - v2.0)**

#### Visión General
Asistente visual basado en ML/AI que ayuda a usuarios con baja visión a "ver" mediante descripciones de voz. Utiliza la cámara del dispositivo + modelos de IA para describir escenas, leer texto y detectar objetos.

**Stack Tecnológico:**
- **ML Kit (Google):** OCR, object detection, image labeling (on-device, gratis)
- **Claude Vision API (Anthropic):** Descripción detallada de imágenes (cloud, más preciso)
- **Gemini Vision (Google):** Alternativa a Claude Vision

---

### FUNCIONALIDAD 6.1: Image Description (Descripción de Imágenes)

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero que la app me describa lo que ve la cámara
Para entender mi entorno sin necesidad de ver claramente
```

#### Criterios de Aceptación Funcional
- [ ] Comando de voz: "¿Qué ves?" o "Describe lo que ves"
- [ ] App captura foto con cámara trasera automáticamente
- [ ] Envía imagen a Claude Vision API o Gemini Vision
- [ ] TTS lee descripción detallada: "Veo una mesa con dos tazas de café, un celular y un periódico"
- [ ] Usuario puede pedir más detalles: "¿De qué color es la taza?"
- [ ] Funciona en interiores y exteriores
- [ ] Feedback audible mientras procesa: "Analizando imagen..."

#### Criterios de Aceptación Técnico
- [ ] CommandCategory.visual con action: describe_image
- [ ] Integración con camera plugin para captura de foto
- [ ] Cliente HTTP para Claude Vision API o Gemini Vision API
- [ ] Compresión de imagen antes de enviar (reducir costos)
- [ ] Cache de descripciones para misma escena (evitar llamadas repetidas)
- [ ] Timeout de 10 segundos, fallback a "No pude analizar la imagen"

#### Archivos a Crear
- `lib/services/vision_service.dart` - Cliente para Vision API
- `lib/utils/image_processor.dart` - Compresión y preprocessing
- `lib/screens/visual_assistant_screen.dart` - UI con preview de cámara

#### Estatus 6.1
- [ ] Por hacer (v2.0)
- [ ] Implementación
- [ ] Testing

---

### FUNCIONALIDAD 6.2: OCR & Text Reading (Lectura de Texto)

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero que la app lea texto de documentos, etiquetas o pantallas
Para acceder a información escrita sin necesidad de lentes especiales
```

#### Criterios de Aceptación Funcional
- [ ] Comando de voz: "Lee esto" o "¿Qué dice aquí?"
- [ ] App captura foto enfocada en texto
- [ ] Extrae texto usando ML Kit OCR (on-device, instantáneo)
- [ ] TTS lee el texto extraído en voz alta
- [ ] Soporta texto impreso y digital (pantallas)
- [ ] Idioma: Español e inglés
- [ ] Feedback si no detecta texto: "No encuentro texto legible"

#### Criterios de Aceptación Técnico
- [ ] CommandCategory.visual con action: read_text
- [ ] Integración con ML Kit Text Recognition v2
- [ ] On-device processing (sin enviar a cloud, más rápido)
- [ ] Detección automática de idioma
- [ ] Highlight de texto detectado en preview (opcional)

#### Archivos a Crear
- `lib/services/ocr_service.dart` - ML Kit OCR wrapper
- Actualizar `lib/services/vision_service.dart`

#### Estatus 6.2
- [ ] Por hacer (v2.0)
- [ ] Implementación
- [ ] Testing

---

### FUNCIONALIDAD 6.3: Object Detection (Detección de Objetos)

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero identificar objetos comunes en mi entorno
Para encontrar cosas como mis llaves, medicamentos o control remoto
```

#### Criterios de Aceptación Funcional
- [ ] Comando de voz: "¿Dónde están mis llaves?" o "Busca mi celular"
- [ ] App usa cámara para detectar objetos en tiempo real
- [ ] ML Kit Image Labeling identifica objetos visibles
- [ ] TTS anuncia: "Veo un celular a la izquierda, unas llaves en el centro"
- [ ] Feedback de dirección relativa (izquierda/derecha/centro)
- [ ] Soporta 400+ categorías de objetos comunes

#### Criterios de Aceptación Técnico
- [ ] CommandCategory.visual con action: detect_object
- [ ] Integración con ML Kit Object Detection & Tracking
- [ ] Procesamiento on-device en tiempo real (30fps ideal)
- [ ] Mapeo de coordenadas a direcciones relativas
- [ ] Filtrado de objetos por relevancia (priorizar objetivo de búsqueda)

#### Archivos a Crear
- `lib/services/object_detection_service.dart` - ML Kit wrapper
- Actualizar `lib/providers/voice_command_provider.dart` con visual commands

#### Estatus 6.3
- [ ] Por hacer (v2.0)
- [ ] Implementación
- [ ] Testing

---

### FUNCIONALIDAD 7: Gestión de Permisos

#### Historia de Usuario
```
Como adulto mayor con poca experiencia técnica
Quiero un tutorial visual paso a paso que me guíe para otorgar los permisos necesarios
Para poder usar todas las funcionalidades sin sentirme perdido en configuraciones complicadas
```

#### Criterios de Aceptación Funcional
- [ ] Al primer inicio, tutorial muestra permisos necesarios uno por uno (no todos juntos)
- [ ] Cada pantalla del tutorial tiene:
  - Explicación simple de POR QUÉ se necesita el permiso (máximo 2 oraciones)
  - Captura de pantalla mostrando DÓNDE tocar
  - Botón grande "Continuar" para ir al siguiente paso
  - Explicación audible con TTS
- [ ] Permisos solicitados en orden:
  1. Micrófono (para comandos de voz)
  2. Accesibilidad (para control remoto y screen sharing)
  3. Captura de pantalla (para sesión remota)
- [ ] La app detecta si el permiso ya fue otorgado y lo salta
- [ ] Si el usuario rechaza un permiso, explica las limitaciones:
  - "Sin micrófono: No podrás usar comandos de voz, pero botones sí funcionan"
- [ ] Botón "Reconfigurar permisos" disponible en pantalla de configuración
- [ ] Tutorial puede saltarse (checkbox "No mostrar de nuevo"), pero con advertencia clara
- [ ] Validación antes de features críticas:
  - Antes de iniciar sesión remota: verificar permiso de Accessibility + Screen Capture
  - Antes de usar comandos de voz: verificar permiso de micrófono

#### Criterios de Aceptación Técnico
- [ ] Implementado usando permission_handler: ^11.1.0
- [ ] Permisos declarados en AndroidManifest.xml:
  - android.permission.RECORD_AUDIO
  - android.permission.INTERNET
  - android.permission.FOREGROUND_SERVICE
  - android.permission.BIND_ACCESSIBILITY_SERVICE
- [ ] Lógica de validación:
  ```dart
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }
  ```
- [ ] Para AccessibilityService (no manejable por permission_handler):
  - Detectar con AccessibilityService.isAccessibilityPermissionEnabled()
  - Abrir configuración con openAccessibilitySettings()
  - Polling cada 2 segundos para detectar cuando se otorgue
- [ ] Tutorial implementado como PageView con 3-4 pantallas
- [ ] Capturas de pantalla incluidas en assets/:
  - assets/tutorials/accessibility_step1.png
  - assets/tutorials/accessibility_step2.png
  - assets/tutorials/screen_capture.png
- [ ] Estado del tutorial almacenado en Hive (no mostrar de nuevo si completado)
- [ ] Deeplinks a configuraciones Android:
  - Settings.ACTION_ACCESSIBILITY_SETTINGS
  - Settings.ACTION_APPLICATION_DETAILS_SETTINGS

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si el usuario rechaza permanentemente un permiso?
  - Detectar con status.isPermanentlyDenied
  - Botón directo a configuración de la app en Android
  - TTS: "Ve a configuración de la app y activa el permiso manualmente"
- ¿Qué pasa si el fabricante (Xiaomi, Huawei) tiene configuraciones extra?
  - Documentar pasos específicos por fabricante en tutorial
  - Detectar fabricante con Build.MANUFACTURER
  - Mostrar instrucciones adicionales: "En Xiaomi, también activa 'Inicio automático'"
- ¿Qué pasa si el usuario sale del tutorial a mitad?
  - Guardar progreso (qué permisos ya se configuraron)
  - Al volver, reanudar desde último paso pendiente
- ¿Qué pasa si Android niega el permiso (política del sistema)?
  - Mostrar mensaje técnico: "El sistema no permite este permiso"
  - Ofrecer alternativas (ej: usar solo botones sin voz)
- ¿Qué pasa si el usuario no entiende las instrucciones?
  - Botón "Ayuda remota" que genera código para que familiar ayude

#### Dependencias Técnicas
- **Permisos requeridos:**
  - android.permission.RECORD_AUDIO
  - android.permission.INTERNET
  - android.permission.FOREGROUND_SERVICE
  - android.permission.BIND_ACCESSIBILITY_SERVICE (especial)
  - Permiso de captura de pantalla (MediaProjection, solicitado en runtime)
- **APIs/SDKs necesarios:**
  - permission_handler: ^11.1.0
  - Android Settings API (para abrir configuraciones)
  - flutter_accessibility_service (para validar AccessibilityService)
- **Servicios de terceros:** Ninguno

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

## MATRIZ DE PRIORIDADES

| Funcionalidad | Impacto Usuario | Complejidad Técnica | Prioridad | Estatus | Tiempo Estimado |
|--------------|-----------------|---------------------|-----------|---------|-----------------|
| **1. Setup del Proyecto** | Crítico (base) | Media | **P0** | ✅ Listo | 1 semana |
| **2. WebRTC Control Remoto** | **Crítico (MVP core)** | **Muy Alta** | **P0** | ✅ Listo | 2-3 semanas |
| **3. Interfaz Accesible Básica** | Muy Alto (usabilidad) | Baja-Media | **P0** | ✅ Listo | 1-2 semanas |
| **4.1 Voice Commands (Core)** | Alto (accesibilidad) | Media | **P1** | ✅ Listo | 1 semana |
| **4.2 System Actions** | Medio (conveniencia) | Baja | **P1** | 🔜 Pendiente | 0.5 semana |
| **4.3 Assistance Actions** | Alto (UX crítica) | Media | **P1** | ✅ Listo | 1 semana |
| **4.4 LLM Enhancement** | Medio (mejora) | Alta | **P2** | ✅ Listo | 1-2 semanas |
| **4.5 System + Social + Prompt** | Medio (mejora) | Media | **P1** | ✅ Listo (25 ene) | 2 horas |
| **4.6 Analytics** | Bajo (monitoreo) | Baja | **P2** | Post-MVP v1.2 | 0.5 semana |
| **5. WhatsApp Integration** | Medio (funcionalidad) | Baja-Media | **P1** | 🔜 Pendiente | 1 semana |
| **6.1 Image Description** | Alto (innovación) | Alta | **P3** | v2.0 | 2 semanas |
| **6.2 OCR Text Reading** | Alto (innovación) | Media | **P3** | v2.0 | 1 semana |
| **6.3 Object Detection** | Medio (innovación) | Alta | **P3** | v2.0 | 2 semanas |
| **7. Gestión de Permisos** | Muy Alto (bloqueante) | Media | **P0** | 🔜 Pendiente | 1 semana |

### Notas de Priorización

**P0 (Críticas - Semanas 1-4):**
1. **Setup del Proyecto** (Semana 1): Sin esto, nada funciona
2. **Interfaz Accesible** (Semana 1-2): Define UX de toda la app
3. **Gestión de Permisos** (Semana 2): Bloquea control remoto si no se configura bien
4. **WebRTC Control Remoto** (Semana 3-4): **Valor principal del MVP** - Desbloquea ayuda familiar remota

**P1 (Importantes - Semanas 4-6):**
5. **ElevenLabs STT/TTS** (Semana 5): Mejora accesibilidad significativamente
6. **WhatsApp Deep Links** (Semana 5-6): Complemento útil, puede ser ayudado remotamente

### Dependencias entre Funcionalidades

```
Setup del Proyecto (S1)
    ↓
    ├─→ Interfaz Accesible (S1-2)
    │       ↓
    │   Gestión de Permisos (S2)
    │       ↓
    │   WebRTC Control Remoto (S3-4) ← VALOR CORE MVP
    │
    └─→ ElevenLabs STT/TTS (S5)
            ↓
        WhatsApp Deep Links (S5-6)
```

---

## CRITERIOS DE ÉXITO DEL MVP

### Técnicos
- [ ] 100% funcionalidades P0 completadas y testeadas
- [ ] App compila sin errores ni warnings críticos
- [ ] `flutter analyze` pasa sin issues
- [ ] Android Accessibility Scanner: 0 warnings críticos
- [ ] Latencia control remoto <2 segundos en WiFi
- [ ] 95%+ comandos de voz reconocidos (ambiente con ruido moderado)

### UX / Accesibilidad
- [ ] Navegación completa posible solo con TalkBack (usuario no necesita ver pantalla)
- [ ] Usuario puede generar código de sesión remota en <10 segundos sin ayuda
- [ ] Familiar puede conectarse remotamente en <30 segundos
- [ ] Tutorial de permisos completable por adulto mayor con experiencia técnica limitada
- [ ] Todos los mensajes de error son comprensibles (lenguaje simple, sin jerga técnica)

### Testing con Usuario Real
- [ ] Sesión de testing con usuario objetivo (60+ años, baja visión)
- [ ] Usuario puede solicitar ayuda remota sin asistencia
- [ ] Familiar puede resolver problema real mediante control remoto
- [ ] Feedback documentado y priorizado para v1.0

---

## DEFINICIÓN DE "LISTO" (Definition of Done)

Para que una funcionalidad se considere **LISTO**, debe cumplir:

### Código
- [ ] Código implementado según convenciones de CLAUDE.md
- [ ] Indentación correcta (2 espacios Dart, 4 espacios Kotlin)
- [ ] Nombres de variables/funciones siguen convenciones (camelCase, PascalCase)
- [ ] Sin código comentado ni TODOs sin resolver
- [ ] Logs agregados en puntos clave (Platform Channels, APIs externas)

### Testing
- [ ] Testeado manualmente en dispositivo físico (no solo emulador)
- [ ] Probado con TalkBack activado
- [ ] `flutter run --analyze-accessibility` ejecutado sin warnings críticos
- [ ] Casos de error principales validados (sin conexión, permisos denegados, etc.)

### Accesibilidad
- [ ] Todos los widgets interactivos tienen `Semantics`
- [ ] Botones tienen altura mínima 80dp
- [ ] Texto tiene tamaño mínimo 24sp
- [ ] Contraste cumple WCAG 2.1 nivel AA
- [ ] Navegable completamente con TalkBack

### Documentación
- [ ] Comentarios en código complejo (especialmente Platform Channels)
- [ ] README actualizado si se agregaron dependencias nuevas
- [ ] Secrets documentados en secrets.example.dart

### Integración
- [ ] `git commit` incluye mensaje descriptivo
- [ ] Branch fusionado a main sin conflictos
- [ ] Build APK funciona: `flutter build apk --release`
- [ ] No se commitaron secrets (verificar .gitignore)

---

### FUNCIONALIDAD 7: Configuración de Release para Producción

#### Historia de Usuario
```
Como desarrollador del proyecto
Quiero tener configurada la firma de releases de Android
Para poder publicar la aplicación en Google Play Store de forma segura
```

#### Criterios de Aceptación Funcional
- [ ] Keystore generado y almacenado de forma segura
- [ ] Build de release firmado correctamente funciona
- [ ] APK release puede instalarse en dispositivos de producción
- [ ] Verificación de firma funciona correctamente
- [ ] Documentación completa del proceso de release

#### Criterios de Aceptación Técnico
- [ ] Keystore generado con `keytool` usando parámetros seguros:
  - Algoritmo: RSA
  - Tamaño de clave: 2048 bits
  - Validez: 10000 días (requerido por Google Play)
- [ ] `build.gradle` configurado con `signingConfigs.release`
- [ ] Variables de entorno configuradas en `.env`:
  - `LAMB_KEY_ALIAS`
  - `LAMB_KEY_PASSWORD`
  - `LAMB_KEYSTORE_PATH`
  - `LAMB_STORE_PASSWORD`
- [ ] `.gitignore` actualizado para proteger:
  - `*.jks`
  - `*.keystore`
  - `.env`
- [ ] Archivo `.env.example` creado con template
- [ ] README actualizado con proceso de release
- [ ] Build de release funciona: `flutter build apk --release`
- [ ] Verificación de firma: `jarsigner -verify -verbose -certs app-release.apk`

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si las variables de entorno no están configuradas?
  - Build falla con mensaje claro indicando variables faltantes
  - Mensaje apunta a README con instrucciones
- ¿Qué pasa si el keystore no existe o la ruta es incorrecta?
  - Build falla indicando que el keystore no se encuentra
  - Verificar que la ruta en `.env` es absoluta y correcta
- ¿Qué pasa si las contraseñas son incorrectas?
  - Build falla con error de autenticación
  - No revelar información de seguridad en logs
- ¿Qué pasa si se commitea el keystore accidentalmente?
  - Pre-commit hook debe prevenir commit de archivos sensibles
  - Documentar proceso de rotación de claves si ocurre

#### Dependencias Técnicas
- **Herramientas requeridas:**
  - `keytool` (incluido en JDK)
  - Android SDK Build Tools
- **Servicios de terceros:**
  - Google Play Console (para upload de APK)
- **Seguridad:**
  - Gestor de contraseñas para almacenar passwords del keystore
  - Backup seguro del keystore (si se pierde, no se puede actualizar la app en Play Store)

#### Documentación del Proceso

**Paso 1: Generar Keystore**
```bash
keytool -genkey -v \
  -keystore ~/lamb-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias lamb-key
```

**Paso 2: Crear archivo .env**
```bash
cp .env.example .env
# Editar .env con valores reales
```

**Paso 3: Configurar build.gradle**
```gradle
android {
    signingConfigs {
        release {
            keyAlias System.getenv("LAMB_KEY_ALIAS")
            keyPassword System.getenv("LAMB_KEY_PASSWORD")
            storeFile file(System.getenv("LAMB_KEYSTORE_PATH"))
            storePassword System.getenv("LAMB_STORE_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Paso 4: Build de Release**
```bash
# Cargar variables de entorno
export $(cat .env | xargs)

# Build APK de release
flutter build apk --release

# Verificar firma
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

#### Checklist de Seguridad
- [ ] Keystore almacenado fuera del repositorio git
- [ ] Keystore respaldado en ubicación segura (cloud encriptado, USB, etc.)
- [ ] Contraseñas almacenadas en gestor de contraseñas
- [ ] Variables de entorno nunca commiteadas
- [ ] `.gitignore` previene commit de archivos sensibles
- [ ] Documentación no contiene contraseñas reales
- [ ] Proceso de rotación de claves documentado

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

#### Prioridad
**P1 (Alta - Pre-Producción):** Debe completarse antes del lanzamiento en Google Play Store, pero no es bloqueante para desarrollo del MVP.

---

## BACKLOG FUTURO (Post-MVP - v1.0)

Estas funcionalidades están fuera del MVP pero documentadas para v1.0 (Semanas 7-12):

### FUNCIONALIDAD 8: AccessibilityService para WhatsApp Automation
- Automatización avanzada: abrir chat por nombre (no número), leer mensajes, enviar mensajes
- **Riesgo:** Muy frágil ante actualizaciones de WhatsApp
- **Prioridad v1.0:** P1 (importante pero no crítica, deep links cubren necesidad básica)

### FUNCIONALIDAD 9: Comandos de Voz Expandidos
- "Lee mis mensajes de [contacto]"
- "Envía mensaje a [contacto] diciendo [texto]"
- "¿Tengo mensajes nuevos?"
- "Llama a [contacto]"
- Parser NLP mejorado con contexto y sinónimos

### FUNCIONALIDAD 10: Notificaciones Inteligentes
- Listener de notificaciones de WhatsApp
- Anuncio automático de mensajes nuevos en voz alta
- Configuración de contactos VIP
- Control de frecuencia de anuncios

### FUNCIONALIDAD 11: Personalización de Accesibilidad
- Velocidad de voz TTS ajustable
- Modo ultra alto contraste
- Tamaño de botones ajustable (80-120dp)
- Temas de color predefinidos

---

## RIESGOS Y MITIGACIONES

### Riesgo 1: WebRTC más complejo de lo estimado (Probabilidad: Media, Impacto: Crítico)
**Señales de alerta:**
- No se logra establecer conexión P2P después de 1 semana de desarrollo
- Latencia >5 segundos consistentemente
- Errores de signaling no resueltos

**Mitigación:**
- Estudiar código de RustDesk como referencia (repositorio clonado)
- Semana 3 dedicada exclusivamente a WebRTC (sin multitasking)
- Plan B: Integrar RustDesk como app separada si desarrollo custom falla
- Buffer de 1 semana en cronograma (semana 6)

### Riesgo 2: Usuario no puede completar tutorial de permisos (Probabilidad: Alta, Impacto: Alto)
**Señales de alerta:**
- En testing, usuario se confunde en pantallas de configuración Android
- Usuario rechaza permisos por miedo/desconfianza

**Mitigación:**
- Tutorial con capturas de pantalla reales (no genéricas)
- Botón "Ayuda remota" en cada paso del tutorial
- Familiar puede configurar permisos mediante control remoto
- Video tutorial corto (TikTok/YouTube) como material complementario

### Riesgo 3: Límites de ElevenLabs excedidos (Probabilidad: Media, Impacto: Medio)
**Señales de alerta:**
- Errores 429 frecuentes en logs
- Usuario reporta que comandos de voz dejaron de funcionar

**Mitigación:**
- Fallback automático a Android SpeechRecognizer (ya implementado en diseño)
- Monitorear dashboard de ElevenLabs semanalmente
- Optimizar uso: solo comandos críticos usan ElevenLabs, resto usa SpeechRecognizer

### Riesgo 4: Rechazo en Google Play por AccessibilityService (Probabilidad: Baja, Impacto: Crítico)
**Señales de alerta:**
- App rechazada en primera submission
- Google solicita evidencia de uso legítimo

**Mitigación:**
- Video demo profesional mostrando uso real (adulto mayor + familiar)
- Declaración de privacidad detallada desde día 1
- Seguir exactamente políticas de Google Play (documentación leída)
- Plan B: Distribución directa de APK vía web (menor alcance)

---

## FUNCIONALIDAD 2.1: Cliente WebRTC para Control Remoto (App del Familiar)

### Fecha de planeación: 08 Enero 2026
### Prioridad: **P0 (Crítica - Requerida para completar MVP)**
### Estatus: Por iniciar

---

### Contexto

Durante las pruebas de la Funcionalidad 2 (TC-HP-001 a TC-HP-008), se validó exitosamente el lado del **host/servidor** (adulto mayor). Sin embargo, **no es posible probar la conexión WebRTC completa** sin el lado del **cliente** (familiar que se conecta).

La Funcionalidad 2.1 es **fundamental para el MVP** porque:
- ✅ Sin cliente, no podemos validar que WebRTC funciona end-to-end
- ✅ No podemos probar estados críticos: `connecting`, `connected`
- ✅ No podemos validar la transmisión de pantalla real
- ✅ No podemos probar el control táctil remoto
- ✅ No hay forma de hacer pruebas completas con usuarios reales

**Decisión:** Priorizar desarrollo del cliente inmediatamente después de validar el host.

---

### Historia de Usuario

```
Como familiar de una persona con baja visión
Quiero conectarme al dispositivo de mi familiar ingresando un código de 6 dígitos
Para poder ver su pantalla en tiempo real y ayudarle tocando elementos que él necesita activar
```

---

### Alcance del Cliente MVP

#### **Plataforma Inicial: Web App (PWA)**
**Justificación:**
- ✅ Desarrollo más rápido que app nativa (1 semana vs 2-3 semanas)
- ✅ No requiere instalación (el familiar solo abre un link)
- ✅ Funciona en cualquier dispositivo (Android, iOS, PC, Mac)
- ✅ Usa `flutter_webrtc` que ya soporta web
- ✅ Permite testing inmediato sin compilaciones

**Plan futuro:** App nativa Android/iOS en v2.2 (post-MVP)

---

### Criterios de Aceptación Funcional

#### **Pantalla 1: Ingresar Código de Sesión**
- [ ] Input numérico para código de 6 dígitos
- [ ] Botón "Conectar" grande y visible
- [ ] Validación: solo acepta 6 dígitos numéricos (2-9, sin 0/1)
- [ ] Mensaje de error claro si código inválido
- [ ] Loading indicator mientras se conecta

#### **Pantalla 2: Visualización de Pantalla Remota**
- [ ] Stream de video de la pantalla del adulto mayor se muestra en tiempo real
- [ ] Video ocupa toda la pantalla (fullscreen) o es maximizable
- [ ] Latencia < 2 segundos en WiFi
- [ ] Controles de sesión visibles: "Desconectar", "Pantalla completa"
- [ ] Indicador de estado de conexión: "Conectando...", "Conectado", "Desconectado"

#### **Funcionalidad de Control Táctil (MVP Básico)**
- [ ] Al tocar en la pantalla del cliente, se simula un tap en el dispositivo del host
- [ ] Coordenadas se escalan correctamente (resolución cliente → resolución host)
- [ ] Feedback visual: círculo temporal donde se tocó
- [ ] **Limitación MVP:** Solo taps simples (no gestos complejos, no scroll, no pinch-to-zoom)

#### **Manejo de Desconexión**
- [ ] Si host termina la sesión, cliente recibe notificación y vuelve a pantalla inicial
- [ ] Si conexión se pierde, muestra mensaje: "Conexión perdida. Reconectando..."
- [ ] Intenta reconectar automáticamente 3 veces antes de fallar
- [ ] Botón "Volver a intentar" si reconexión falla

---

### Criterios de Aceptación Técnico

#### **Stack Técnico**
- [ ] **Frontend:** Flutter Web (compile con `flutter build web`)
- [ ] **WebRTC:** `flutter_webrtc` v0.9.48+ (mismo que host)
- [ ] **Signaling:** Firebase Firestore (mismo backend que host)
- [ ] **Hosting:** Firebase Hosting (deploy con `firebase deploy`)
- [ ] **URL:** `https://lamb-remote.web.app` o similar

#### **Arquitectura**
```
lib/
├── main_web.dart                    # Entry point para web
├── screens/
│   ├── client_connect_screen.dart   # Pantalla 1: Ingresar código
│   └── client_viewer_screen.dart    # Pantalla 2: Ver pantalla remota
├── services/
│   └── webrtc_client_service.dart   # Cliente WebRTC
└── providers/
    └── remote_viewer_provider.dart  # State management del cliente
```

#### **Flujo de Conexión WebRTC**

**Cliente:**
1. Usuario ingresa código de 6 dígitos
2. Cliente busca sesión en Firestore: `remote_sessions/{sessionCode}`
3. Si existe y `status == 'waiting'`, obtiene el `offer` SDP del host
4. Cliente crea `RTCPeerConnection`
5. Cliente setea el `offer` como remote description
6. Cliente crea `answer` SDP
7. Cliente guarda `answer` en Firestore: `remote_sessions/{sessionCode}/answer`
8. Cliente escucha ICE candidates del host y los agrega
9. WebRTC establece conexión P2P
10. Cliente recibe el stream de video y lo renderiza

**Signaling (Firestore):**
```
remote_sessions/{sessionCode}/
  ├── offer: String (SDP del host)
  ├── answer: String (SDP del cliente)
  ├── status: 'waiting' | 'connecting' | 'connected' | 'ended'
  ├── hostIceCandidates: Array<IceCandidate>
  ├── clientIceCandidates: Array<IceCandidate>
  └── lastActivity: Timestamp
```

#### **Comunicación de Control Táctil**

**Canal de datos WebRTC:**
```dart
// Host crea data channel
RTCDataChannel dataChannel = await peerConnection.createDataChannel(
  'control',
  RTCDataChannelInit(),
);

// Cliente envía eventos táctiles
dataChannel.send(json.encode({
  'type': 'tap',
  'x': normalizedX,  // 0.0 - 1.0
  'y': normalizedY,  // 0.0 - 1.0
  'timestamp': DateTime.now().millisecondsSinceEpoch,
}));
```

**Host recibe y ejecuta:**
- Escala coordenadas normalizadas a píxeles de pantalla del host
- Usa `AccessibilityService.simulateTap()` (Kotlin) para simular el tap

---

### Casos de Uso Críticos (Testing)

#### **TC-CLIENT-001: Conectar con código válido (P0)**
**Pasos:**
1. Host inicia sesión remota (código: 234567)
2. Cliente abre web app
3. Cliente ingresa: 234567
4. Cliente presiona "Conectar"

**Resultado esperado:**
- ✅ Cliente muestra "Conectando..."
- ✅ En 5-10 segundos, aparece pantalla del host
- ✅ Host ve estado cambiar a "Conectado"
- ✅ Cliente puede ver la pantalla en tiempo real

#### **TC-CLIENT-002: Código inválido (P0)**
**Pasos:**
1. Cliente ingresa código que no existe: 999999
2. Cliente presiona "Conectar"

**Resultado esperado:**
- ✅ Mensaje de error: "Código de sesión no encontrado o expirado"
- ✅ Vuelve a pantalla de ingreso de código

#### **TC-CLIENT-003: Control táctil básico (P0)**
**Pasos:**
1. Cliente conectado exitosamente
2. Cliente toca en el botón "WhatsApp" visible en la pantalla del host
3. Observar dispositivo del host

**Resultado esperado:**
- ✅ En el host, el botón "WhatsApp" se presiona (animación de tap)
- ✅ Acción correspondiente se ejecuta (ej: abre WhatsApp)
- ✅ Feedback visual en cliente: círculo breve donde se tocó

#### **TC-CLIENT-004: Desconexión del host (P1)**
**Pasos:**
1. Cliente conectado
2. Host presiona "Terminar Sesión"

**Resultado esperado:**
- ✅ Video desaparece en cliente
- ✅ Mensaje: "El host terminó la sesión"
- ✅ Botón "Volver" para regresar a pantalla inicial

---

### Estimación de Esfuerzo

| Tarea | Esfuerzo | Prioridad |
|-------|----------|-----------|
| Setup Flutter Web + Firebase Hosting | 2-3 horas | P0 |
| Pantalla de ingreso de código | 3-4 horas | P0 |
| WebRTC Client Service (conexión) | 6-8 horas | P0 |
| Pantalla de visualización de stream | 4-5 horas | P0 |
| Data channel para control táctil | 5-6 horas | P0 |
| Host: Recibir y ejecutar taps remotos | 4-5 horas | P0 |
| Manejo de errores y reconexión | 3-4 horas | P0 |
| Testing end-to-end | 4-5 horas | P0 |
| **TOTAL** | **31-40 horas** | **~1 semana** |

---

### Dependencias

**Ya completado:**
- ✅ Host (servidor) implementado y funcionando
- ✅ Firebase Firestore configurado
- ✅ Signaling con `offer` ya funciona

**Pendiente:**
- [ ] `AccessibilityService` en host debe soportar taps remotos
- [ ] Firebase Hosting configurado para web app
- [ ] Permisos de Firestore ajustados para permitir escritura de cliente

---

### Estatus

- [x] Identificado como bloqueante para MVP (08 ene 2026)
- [x] Especificación técnica completada
- [x] Aprobado para desarrollo
- [x] En desarrollo
- [x] En testing (TC-CLIENT-001 a TC-CLIENT-004)
- [x] Listo para MVP

---

### FUNCIONALIDAD 2.2: BaseScreenLayout - Widget de Layout Consistente

#### Fecha de planeación: 14 Enero 2026
#### Prioridad: **Media (P1 - Mejora UX)**
#### Estatus: Por iniciar

---

#### Contexto

La app está orientada a adultos mayores que necesitan una experiencia **predecible y consistente** en todas las pantallas. Actualmente, cada pantalla tiene su propia estructura, lo que puede generar confusión sobre dónde están los botones principales.

**Problema identificado:**
- Botones principales (CTAs) en diferentes ubicaciones entre pantallas
- Contenido sin scroll cuando crece (problemas en dispositivos pequeños)
- Falta de consistencia dificulta aprendizaje para adultos mayores

**Solución:**
Crear un widget base reutilizable (`BaseScreenLayout`) que estandarice el layout con:
- ✅ Contenido scrollable (adapta a cualquier tamaño de pantalla)
- ✅ Footer sticky con botones principales (siempre en la misma posición)
- ✅ Soporte para múltiples botones en footer
- ✅ Semántica completa para TalkBack

---

#### Historia de Usuario

```
Como adulto mayor con baja visión
Quiero que todos los botones principales estén siempre en el mismo lugar en cada pantalla
Para poder predecir dónde están y usarlos sin confusión
```

---

#### Criterios de Aceptación Funcional

**Layout Estándar:**
- [ ] Todas las pantallas usan el mismo widget base
- [ ] Contenido es scrollable automáticamente si excede el tamaño de pantalla
- [ ] Footer con botones principales siempre visible (sticky)
- [ ] Footer soporta 1-3 botones (ej: secundario + principal)
- [ ] AppBar con título y botón "Atrás" opcional
- [ ] Espaciado consistente en todas las pantallas (24dp padding)

**Accesibilidad:**
- [ ] Semántica completa para TalkBack
- [ ] Botones en footer tienen mínimo 80dp altura
- [ ] Footer se anuncia como región landmark
- [ ] Navegación con TalkBack es predecible

**Aplicación Inmediata:**
- [ ] `RemoteControlHostScreen` refactorizado para usar `BaseScreenLayout`
- [ ] Botón "Terminar Sesión" siempre visible en footer
- [ ] Código de sesión + instrucciones scrollable

---

#### Criterios de Aceptación Técnico

**Archivo nuevo:**
- [ ] `lib/widgets/base_screen_layout.dart` creado

**API del Widget:**
```dart
BaseScreenLayout(
  title: 'Control Remoto',           // Título del AppBar
  showBackButton: true,               // Mostrar botón "Atrás" (opcional)
  content: [                          // Lista de widgets scrollable
    ConnectionStatusIndicator(...),
    SessionCodeDisplay(...),
    // ... más widgets
  ],
  footerActions: [                    // 1-3 botones en footer sticky
    AccessibleButton(
      label: 'Terminar Sesión',
      icon: Icons.stop,
      onPressed: () => ...,
      isDestructive: true,
    ),
  ],
)
```

**Estructura Interna:**
```dart
Scaffold(
  appBar: AppBar(
    title: Text(title),
    leading: showBackButton ? BackButton() : null,
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: content,
      ),
    ),
  ),
  persistentFooterButtons: footerActions,  // Sticky footer
)
```

**Características Técnicas:**
- [ ] Usa `Scaffold` + `persistentFooterButtons` para footer sticky
- [ ] Usa `SingleChildScrollView` para contenido scrollable
- [ ] `SafeArea` automático para evitar notches/bordes
- [ ] Padding consistente: 24dp en contenido, 16dp entre elementos del footer
- [ ] Semántica con `ExcludeSemantics` en decoraciones visuales
- [ ] Footer con `Semantics(label: 'Acciones principales', container: true)`

---

#### Aplicaciones por Pantalla

| Pantalla | Footer Actions | Content | Prioridad |
|----------|----------------|---------|-----------|
| **RemoteControlHostScreen** | "Terminar Sesión" | Status + Código + Instrucciones | P0 (Inmediato) |
| **WhatsAppScreen** | "Enviar" o "Volver" | Lista de contactos o chat | P1 (Futuro) |
| **VoiceCommandScreen** | "Detener" o "Cancelar" | Comandos + Feedback | P1 (Futuro) |
| **SettingsScreen** | "Guardar Cambios" | Opciones de configuración | P1 (Futuro) |

---

#### Diseño Visual

```
┌─────────────────────────────────────┐
│  ← Título de Pantalla            ⚙ │  ← AppBar (opcional back button)
├─────────────────────────────────────┤
│                                     │
│  [Contenido Scrollable]             │  ← SingleChildScrollView
│  • ConnectionStatusIndicator        │
│  • SessionCodeDisplay               │
│  • Instrucciones                    │
│  • Tarjetas informativas            │
│  • ...                              │
│  ↕ (scroll si crece)                │
│                                     │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐ │  ← Footer Sticky
│  │  [Btn Secundario] [Btn CTA]  │ │     (persistentFooterButtons)
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

#### Edge Cases y Manejo de Errores

**¿Qué pasa si el contenido es muy corto?**
- El footer permanece en la parte inferior (no flota en el medio)
- `SingleChildScrollView` con `Column` natural mantiene el footer abajo

**¿Qué pasa si hay 3+ botones en footer?**
- Advertir en documentación: máximo 3 botones recomendado
- Si se excede, los botones se envuelven (wrap) automáticamente

**¿Qué pasa en dispositivos muy pequeños?**
- Contenido siempre scrollable (no overflow)
- Footer se mantiene visible y accesible
- Botones mantienen tamaño mínimo (no se reducen)

**¿Qué pasa si no hay footerActions?**
- Footer no se muestra (comportamiento de `persistentFooterButtons`)
- Widget funciona como `Scaffold` normal

---

#### Refactorización de RemoteControlHostScreen

**Antes:**
```dart
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          ConnectionStatusIndicator(...),
          SessionCodeDisplay(...),
          // ... más contenido
          _buildActionButtons(provider),  // Botones dentro del scroll
        ],
      ),
    ),
  ),
)
```

**Después:**
```dart
BaseScreenLayout(
  title: 'Control Remoto',
  content: [
    ConnectionStatusIndicator(status: provider.status),
    SizedBox(height: 32),
    if (provider.sessionCode != null) ...[
      SessionCodeDisplay(sessionCode: provider.sessionCode!),
      // ... más contenido
    ],
  ],
  footerActions: [
    AccessibleButton(
      label: 'Terminar Sesión',
      icon: Icons.stop,
      onPressed: () => _endSession(provider),
      isDestructive: true,
    ),
  ],
)
```

---

#### Estimación de Esfuerzo

| Tarea | Esfuerzo | Prioridad |
|-------|----------|-----------|
| Diseñar API del widget | 1 hora | P0 |
| Implementar `BaseScreenLayout` | 3-4 horas | P0 |
| Refactorizar `RemoteControlHostScreen` | 2-3 horas | P0 |
| Documentar uso en CLAUDE.md | 1 hora | P0 |
| Testing con TalkBack | 2 horas | P0 |
| **TOTAL** | **9-11 horas** | **~1-1.5 días** |

---

#### Dependencias

**Ya completado:**
- ✅ `AccessibleButton` widget existente
- ✅ `RemoteControlHostScreen` estructura actual

**Requerido:**
- [ ] Ninguna dependencia externa nueva

---

#### Testing

**Casos de prueba:**
- [ ] TC-BASE-001: Contenido largo scrollable sin overflow
- [ ] TC-BASE-002: Footer sticky visible al hacer scroll
- [ ] TC-BASE-003: Múltiples botones en footer (1, 2, 3 botones)
- [ ] TC-BASE-004: Navegación con TalkBack predecible
- [ ] TC-BASE-005: Botón "Atrás" funciona correctamente
- [ ] TC-BASE-006: Layout responsive en diferentes tamaños de pantalla

---

#### Documentación

**Agregar a CLAUDE.md:**
```markdown
### BaseScreenLayout - Widget Base para Pantallas

Widget estándar para crear pantallas consistentes en toda la app.

**Uso:**
```dart
BaseScreenLayout(
  title: 'Título de Pantalla',
  showBackButton: true,
  content: [
    // Lista de widgets scrollable
  ],
  footerActions: [
    // 1-3 botones sticky
  ],
)
```

**Características:**
- Contenido automáticamente scrollable
- Footer sticky con botones principales
- Semántica completa para TalkBack
- Espaciado consistente (24dp)
```

---

#### Impacto en el Proyecto

**Beneficios:**
- ✅ **Consistencia:** Experiencia predecible para adultos mayores
- ✅ **Accesibilidad:** Footer siempre en misma posición para TalkBack
- ✅ **Escalabilidad:** Fácil crear nuevas pantallas
- ✅ **Mantenibilidad:** Cambios de diseño en un solo lugar
- ✅ **Responsive:** Funciona en cualquier tamaño de pantalla

**Pantallas afectadas:**
- RemoteControlHostScreen (refactorización inmediata)
- Futuras pantallas: WhatsApp, Voice Commands, Settings

---

#### Estatus

- [x] Especificación completada (14 ene 2026)
- [x] Aprobado para desarrollo
- [x] En desarrollo
- [x] En testing
- [x] Listo para producción
- [x] Documentado en CLAUDE.md

---

## MEJORAS POST-MVP (Funcionalidad 2.3 - Enhancements)

### Prioridad: P1-P2 (Alta, pero no bloqueante para MVP)

---

### MEJORA 2.2.1: Botón para Repetir Código de Sesión en Altavoz

#### Historia de Usuario
```
Como adulto mayor usando la app
Quiero poder repetir el código de sesión en altavoz cuando lo necesite
Para poder compartirlo con mi familiar sin tener que leerlo visualmente en la pantalla
```

#### Contexto
Durante las pruebas del TC-HP-004, se identificó que aunque el código se anuncia automáticamente al inicio, sería útil poder repetirlo bajo demanda, especialmente en casos donde:
- El usuario no escuchó el código la primera vez
- El familiar llegó tarde y no estaba presente cuando se anunció
- El usuario necesita confirmar el código nuevamente

#### Criterios de Aceptación Funcional
- [ ] Existe un botón "Repetir código" visible en la pantalla de sesión activa
- [ ] El botón tiene un ícono de altavoz/volumen para identificación rápida
- [ ] Al presionar el botón, el TTS anuncia: "Código de sesión: X, X, X, X, X, X" (cada dígito separado)
- [ ] El botón tiene tamaño mínimo de 80dp de altura (estándar de accesibilidad)
- [ ] El botón funciona con TalkBack activado
- [ ] Semantic label: "Repetir código de sesión en altavoz, Botón, Toca dos veces para escuchar el código nuevamente"

#### Criterios de Aceptación Técnico
- [ ] Botón implementado usando `AccessibleButton` widget existente
- [ ] Usa `ElevenLabsService.speak()` para reproducir el código
- [ ] El mensaje del TTS es el mismo que el anuncio inicial (consistencia)
- [ ] El botón se deshabilita temporalmente mientras reproduce el audio (evita spam)
- [ ] Se agrega a `RemoteControlHostScreen` debajo del widget `SessionCodeDisplay`

#### UI/UX
**Ubicación:** Entre el `SessionCodeDisplay` y las instrucciones "Comparte este código..."

**Diseño:**
```
┌─────────────────────────────────────┐
│   SessionCodeDisplay (código)       │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  🔊 Repetir código en altavoz       │  ← NUEVO BOTÓN
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Card: "Comparte este código..."   │
└─────────────────────────────────────┘
```

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si el usuario presiona el botón mientras ya está reproduciendo?
  - Botón se deshabilita visualmente y no hace nada
  - TalkBack anuncia: "Esperando que termine el audio actual"
- ¿Qué pasa si ElevenLabs falla?
  - Botón sigue funcionando, pero no reproduce audio (fallo silencioso)
  - Se loggea el error en consola
  - NO se muestra error al usuario (no es crítico)
- ¿Qué pasa si el usuario tiene el volumen multimedia en 0?
  - Se reproduce de todas formas (responsabilidad del usuario ajustar volumen)
  - Considerar agregar indicador visual de "reproduciendo..." para feedback

#### Estimación de Esfuerzo
- **Desarrollo:** 2-3 horas
- **Testing:** 1 hora (TC-ACC-006 y casos nuevos)
- **Total:** 3-4 horas

#### Dependencias
- ✅ ElevenLabsService ya implementado y funcionando
- ✅ AccessibleButton widget existente
- ✅ RemoteControlHostScreen estructura ya definida

#### Estatus
- [x] Identificado durante testing (TC-HP-004)
- [x] Diseñado (especificación completa)
- [x] En desarrollo
- [x] En pruebas
- [x] Listo para producción

---

### Otras Mejoras Planeadas para 2.1

#### MEJORA 2.1.2: Ajuste de Volumen de TTS (Prioridad: P2)
- Agregar slider de volumen específico para TTS en settings
- Permitir probar el volumen con audio de ejemplo

#### MEJORA 2.1.3: Selección de Voz (Prioridad: P2)
- Permitir elegir entre voz masculina/femenina
- Agregar opción de velocidad de habla (lenta/normal/rápida)

#### MEJORA 2.1.4: Historial de Sesiones (Prioridad: P3)
- Mostrar últimas 5 sesiones remotas con fecha/hora
- Útil para auditoría y confianza del usuario

---

## REGISTRO DE CAMBIOS

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 25 ene 2026 | 2.1 | **FUNCIONALIDAD 4.5 completada:** Comandos de Sistema + Respuestas Sociales + System Prompt Externalizado. Incluye: getTime/getDate/getBatteryLevel (Kotlin), thankYou/goodbye, conversationRejected, contador unknown con ayuda proactiva, prompt externalizado en `/lib/prompts/`, 6 nuevos CommandType, 24 test cases. Analytics renumerado a 4.6. |
| 18 ene 2026 | 2.0 | **REORGANIZACIÓN MAYOR:** Funcionalidad 4 dividida en subfuncionalidades granulares (4.1-4.5). Nueva Funcionalidad 6 (Visual Assistant) con ML/AI agregada. Arquitectura de comandos actualizada con CommandCategory + Parser Híbrido. UX simplificada con FAB push-to-talk. Gestión de Permisos renumerada como Funcionalidad 7. |
| 18 ene 2026 | 1.3 | **FUNCIONALIDAD 4.1 completada:** Voice Command Infrastructure (Core) implementado con ElevenLabs STT + flutter_tts. Incluye: VoiceCommand model, NLPParser, VoiceCommandProvider, VoiceCommandScreen, WhatsAppService platform channel, unit tests. Estatus: En desarrollo. |
| 11 ene 2026 | 1.2 | Agregada FUNCIONALIDAD 7: Configuración de Release para Producción. Renumeradas funcionalidades post-MVP (8-11) |
| 08 ene 2026 | 1.1 | Agregada sección "Mejoras Post-MVP" con mejora 2.1.1 (Repetir código en altavoz) |
| 24 dic 2025 | 1.0 | Backlog inicial creado basado en ROADMAP v1.1 y ARQUITECTURA v2.0 |

---

**Próximos pasos:**
1. Revisar y aprobar este backlog
2. Iniciar desarrollo siguiendo prioridades P0
3. Actualizar estatus de cada funcionalidad conforme avanza el desarrollo
4. Sesión de planning semanal para ajustar estimaciones según progreso real
