# Changelog

Todos los cambios notables del proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

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
