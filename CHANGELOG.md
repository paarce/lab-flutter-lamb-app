# Changelog

Todos los cambios notables del proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

---

## [1.2.0] - 2026-01-24

### 🤖 Feature 4.4: LLM Remote Enhancement ✅

#### Agregado
- **LLMParserService** - Parser híbrido con Claude API fallback
  - Usa Claude 3 Haiku para parsing de lenguaje natural
  - Timeout de 3 segundos máximo
  - Extrae comandos estructurados de frases naturales
  - Soporta extracción de parámetros (ej: nombres de contactos)
  - Retorna `null` gracefully en errores (no lanza excepciones)

- **LLMCommandCache** - Cache en memoria para optimización
  - TTL de 5 minutos por defecto
  - Máximo 100 entradas (evita memory leaks)
  - Normalización de keys (lowercase, espacios colapsados)
  - Evicción FIFO cuando está lleno
  - Reduce latencia de comandos repetidos a <50ms

- **Flujo híbrido de parsing:**
  1. Parser local de keywords (NLPParser) - <50ms, sin costo
  2. Si `unknown` → LLM fallback - 300-3000ms, $0.0001 por comando
  3. Cache para comandos exitosos

- **Integración en VoiceCommandProvider:**
  - Inyección opcional de `LLMParserService`
  - Fallback solo cuando parser local retorna `unknown`
  - Extracción de contactos para comando `openWhatsApp`
  - Logging detallado del flujo híbrido

- **Configuración:**
  - `claudeApiKey` agregado a `secrets.example.dart`
  - Error codes específicos para LLM (rate limit, timeout, parse error)
  - Categoría de error `ErrorCategory.llm`
  - Mensajes de error accesibles en español

- **Documentación:**
  - Manual test cases completo (18 test cases: 12 P0, 6 P1)
  - Ejemplos de frases naturales reconocidas
  - Estimación de costos de API ($6/mes para 1000 usuarios)
  - Guía de privacidad y seguridad

#### Características Clave
✅ **Lenguaje natural:** Reconoce frases como "necesito que alguien me ayude"
✅ **Extracción de contactos:** "quiero hablar con mi hija María" → extrae "maría"
✅ **Cache inteligente:** Reduce latencia y costos en comandos repetidos
✅ **Degradación graceful:** Si LLM falla, cae a "No entendí el comando"
✅ **Opcional:** App funciona sin Claude API key (solo parser local)
✅ **Económico:** ~$0.0001 por comando LLM (~$6/mes para 1000 usuarios)

#### Variaciones de Comandos Reconocidas
- **Request Help:** "necesito ayuda", "ayúdenme", "requiero asistencia"
- **Toggle Contrast:** "ponme los colores más fuertes", "aumenta el contraste"
- **Volume:** "sube el sonido", "baja un poco", "ponlo al máximo", "silencia"
- **Open WhatsApp:** "hablar con María", "llama a Juan", "escríbele a Pedro"

#### Archivos Agregados
- `lib/services/llm_parser_service.dart` (~180 líneas)
- `lib/services/llm_command_cache.dart` (~85 líneas)
- `.claude/docs/manual-test-cases/FUNCIONALIDAD_4.4_LLM_PARSER.md` (documentación completa)

#### Archivos Modificados
- `lib/providers/voice_command_provider.dart` - Integración flujo híbrido
- `lib/config/secrets.example.dart` - Claude API key
- `lib/main.dart` - Provider injection
- `lib/errors/error_codes.dart` - Códigos LLM
- `lib/errors/error_category.dart` - Categoría LLM
- `lib/utils/error_messages.dart` - Mensajes LLM

#### Performance
- Latencia promedio LLM: 300-1500ms (depende de internet)
- Latencia cache hit: <50ms (10-30x más rápido)
- Timeout máximo: 3s (UX aceptable para adultos mayores)

#### Costos Estimados
- Por comando LLM: ~$0.0001 USD
- Mensual (1000 usuarios, 10 comandos/día, 20% LLM): ~$6 USD
- Cache reduce costos 50-70%

---

## [1.1.0] - 2026-01-10

### 🚨 Gestión Centralizada de Errores ✅

#### Agregado
- **ErrorHandlerService** - Servicio central único para manejo de errores
  - Normaliza ANY tipo de error (AppError, PlatformException, FirebaseException, SocketException, etc)
  - Genera mensajes accesibles automáticamente en español
  - Reproduce errores con TTS (ElevenLabsService)
  - Muestra diálogos modales (80dp botones, 24sp texto, Semantics)
  - Botón "Cerrar" + "Reintentar" (condicional)
  - Logging centralizado en memoria (máx 100 logs)

- **LoggerService** - Logging en memoria (singleton)
  - Soporta levels: DEBUG, INFO, ERROR
  - Buffer en memoria (FIFO, máx 100 entries)
  - Integración con dart:developer

- **Estructura de errores:**
  - `AppError` - Modelo base unificado
  - `ErrorCategory` - Enums: PlatformChannel, Firebase, ElevenLabs, WebRTC, Network, Unknown
  - `ErrorCodes` - Códigos normalizados por categoría (40+ códigos)
  - `ErrorMessages` - Mensajes accesibles para usuario (español, TTS-ready)

- **Guía de uso:**
  - `ERROR_HANDLER_GUIDE.dart` - 4 casos de uso reales con ejemplos
  - Documentación completa en CLAUDE.md

- **Actualización de Providers:**
  - `ErrorHandlerService` registrado como Provider
  - `LoggerService` registrado como Singleton

#### Características Clave
✅ **Centralizado:** Un único punto de entrada para TODOS los errores
✅ **Accesible:** Diálogos modales + TTS obligatorio para adultos mayores
✅ **Consistente:** Misma experiencia de error en toda la app
✅ **Sin reintentos automáticos:** Usuario controla reintentos
✅ **Debuggable:** Códigos normalizados + logging centralizado
✅ **Flexible:** Soporta 5 categorías + custom AppError

#### Requisitos Cumplidos
- ✅ Diálogos modales (más visibles para baja visión)
- ✅ Botones grandes (80dp) + texto grande (24sp)
- ✅ TTS integrado
- ✅ Botón "Cerrar" + "Reintentar" (condicional)
- ✅ Mensajes básicos (sin jerga técnica)
- ✅ Logging en memoria (no en disco)
- ✅ Sin WhatsAppService (feature futuro)

---

## [1.0.0] - 2025-12-27

### Setup Inicial ✅

#### Agregado
- Proyecto Flutter configurado con estructura base
- Tema accesible implementado (WCAG 2.1 AA)
  - Texto mínimo: 24sp
  - Botones mínimo: 80dp altura
  - Alto contraste de colores
  - Semantics completos en todos los widgets
- Pantalla Home con navegación básica
- Inicialización de Firebase (Firestore + FCM)
- Inicialización de Hive (base de datos local)
- 13 dependencias principales instaladas:
  - State management: `provider`
  - Firebase: `firebase_core`, `cloud_firestore`, `firebase_messaging`
  - Networking: `http`, `dio`, `web_socket_channel`
  - Storage: `hive`, `hive_flutter`
  - Features: `flutter_webrtc`, `flutter_accessibility_service`, `permission_handler`

#### Configurado
- Android minSdkVersion: 24 (Android 7.0)
- Android targetSdkVersion: 34 (Android 14)
- Package name: `com.accessibilityapp.lamb`
- Firebase integrado con `google-services.json`
- Sistema de secrets gitignored (`lib/config/secrets.dart`)
- README.md con guías completas de desarrollo

#### Documentación
- README.md actualizado con:
  - Guía de ejecución en emulador Android
  - Gestión de procesos de Flutter
  - Comandos útiles para desarrollo
- CLAUDE.md - Guía de referencia del proyecto
- ARQUITECTURA_APP_ACCESIBILIDAD.md - Análisis técnico
- Reglas de desarrollo en `.claude/rules/`

---

## [Unreleased]

### Próximas Funcionalidades

#### FUNCIONALIDAD 2: Comandos de Voz
- [ ] Integración ElevenLabs STT (WebSocket)
- [ ] Provider para estado de comandos
- [ ] UI de reconocimiento de voz
- [ ] Parser de comandos en lenguaje natural

#### FUNCIONALIDAD 3: Automatización WhatsApp
- [ ] Platform Channels (Dart ↔ Kotlin)
- [ ] AssistantAccessibilityService (Kotlin)
- [ ] WhatsAppAutomation (Kotlin)
- [ ] Lógica de automatización de chats

#### FUNCIONALIDAD 4: Control Remoto
- [ ] WebRTC setup
- [ ] Firebase Firestore signaling
- [ ] Pantalla de control remoto
- [ ] Gestión de permisos (CAPTURE, FOREGROUND_SERVICE)

---

## Tipos de Cambios

- **Agregado** - Para funcionalidades nuevas
- **Cambiado** - Para cambios en funcionalidades existentes
- **Obsoleto** - Para funcionalidades que serán removidas
- **Removido** - Para funcionalidades removidas
- **Corregido** - Para corrección de bugs
- **Seguridad** - Para vulnerabilidades de seguridad

---

**Stack**: Flutter + Firebase + WebRTC + ElevenLabs
**Target**: Adultos mayores (60+) con baja visión
**Plataforma**: Android (iOS v2.0 planeado)
