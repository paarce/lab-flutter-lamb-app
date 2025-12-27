# Lamb - App de Accesibilidad para Adultos Mayores

App Flutter para adultos mayores (60+) con baja visión. Proporciona control remoto y asistencia para WhatsApp mediante comandos de voz.

## 🎯 Características

- **Control remoto de pantalla** - Soporte familiar vía WebRTC
- **Comandos de voz** - Automatización de WhatsApp
- **Interfaz accesible** - Botones grandes y alto contraste
- **TalkBack optimizado** - Navegación completa con lector de pantalla

## 📋 Requisitos

- Flutter 3.19+ (Actual: 3.26.0)
- Dart 3.0+ (Actual: 3.6.0)
- Android SDK 24+ (Android 7.0 Nougat)
- Cuenta Firebase configurada ✅

## 🚀 Setup Inicial

### 1. Instalar Dependencias

```bash
flutter pub get
```

### 2. Configurar Secrets

```bash
# Editar lib/config/secrets.dart con tus API keys
# - ElevenLabs API Key (para STT/TTS)
# - ElevenLabs Voice ID
```

### 3. Firebase

✅ **Ya configurado** - El archivo `google-services.json` está en su lugar.

### 4. Ejecutar la App

```bash
# En emulador o dispositivo conectado
flutter run

# Para build de release
flutter build apk --release
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Entry point, Provider, tema accesible
├── config/
│   ├── secrets.dart             # API keys (gitignored)
│   └── secrets.example.dart     # Template para secrets
├── screens/
│   └── home_screen.dart         # Pantalla principal
├── widgets/                     # Componentes reutilizables
├── services/                    # Lógica de negocio
├── models/                      # Modelos de datos
├── utils/                       # Utilidades y helpers
└── providers/                   # State management
```

## 🎨 Convenciones de Accesibilidad

- ✅ Texto mínimo: **24sp**
- ✅ Altura de botones: **80dp**
- ✅ Contraste: **WCAG 2.1 AA**
- ✅ Semantics en todos los widgets interactivos
- ✅ Compatible con TalkBack

## 🛠️ Comandos Útiles

```bash
# Análisis de código
flutter analyze

# Tests
flutter test

# Limpiar build
flutter clean

# Verificar accesibilidad
flutter run --analyze-accessibility

# Ver logs
flutter logs
```

## 📦 Dependencias Principales

- **provider** - State management
- **firebase_core** - Firebase core
- **cloud_firestore** - Base de datos Firestore
- **firebase_messaging** - Notificaciones push
- **flutter_webrtc** - Control remoto
- **flutter_accessibility_service** - Automatización WhatsApp
- **hive** - Base de datos local
- **dio** / **http** - HTTP clients
- **web_socket_channel** - WebSocket (ElevenLabs STT)
- **permission_handler** - Gestión de permisos

## 📝 Documentación

- [CLAUDE.md](./CLAUDE.md) - Guía de referencia del proyecto
- [ARQUITECTURA_APP_ACCESIBILIDAD.md](./ARQUITECTURA_APP_ACCESIBILIDAD.md) - Análisis técnico
- [.claude/rules/](./.claude/rules/) - Reglas de desarrollo

## ⚙️ Configuración Android

- **minSdkVersion**: 24 (Android 7.0)
- **targetSdkVersion**: 34 (Android 14)
- **Package**: `com.accessibilityapp.lamb`

## 🔐 Archivos Sensibles (gitignored)

- `lib/config/secrets.dart` - API keys
- `android/app/google-services.json` - Configuración Firebase
- `*.keystore` - Certificados de firma

## 🚧 Estado del Proyecto

**Versión actual**: 1.0.0

### ✅ Completado

- [x] Setup del proyecto Flutter
- [x] Estructura de carpetas
- [x] Configuración Firebase
- [x] Tema accesible con WCAG AA
- [x] Pantalla Home con Semantics
- [x] Provider configurado

### 🔜 Próximas Funcionalidades

- [ ] Comandos de voz (ElevenLabs STT)
- [ ] Automatización WhatsApp (AccessibilityService)
- [ ] Control remoto (WebRTC)
- [ ] Configuración de usuario

## 👨‍💻 Desarrollo

Este proyecto sigue las convenciones definidas en [CLAUDE.md](./CLAUDE.md).

**Reglas importantes:**
- Accesibilidad primero en cada feature
- Testing con TalkBack antes de commit
- Código completo y funcional (no pseudocódigo)
- Logging en Platform Channels

## 📄 Licencia

Proyecto privado - No publicado en pub.dev

---

**Stack**: Flutter + Firebase + WebRTC + ElevenLabs
**Plataforma**: Android (iOS v2.0 planeado)
**Target**: Adultos mayores con baja visión
