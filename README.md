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

---

## 🖥️ Ejecutar en Emulador Android

### Paso 1: Verificar Instalación de Android SDK

```bash
# Verificar que Android SDK esté instalado
flutter doctor -v
```

**Esperado:**
```
[✓] Android toolchain - develop for Android devices (Android SDK version X.X.X)
```

**Si falta Android SDK:**
- Descarga [Android Studio](https://developer.android.com/studio)
- Durante la instalación, asegúrate de instalar Android SDK

### Paso 2: Crear un Emulador Android (si no tienes uno)

#### Opción A: Desde Android Studio (Recomendado)

1. Abre Android Studio
2. Ve a **Tools** → **Device Manager** (o **AVD Manager**)
3. Haz clic en **Create Device**
4. Selecciona un dispositivo:
   - **Recomendado:** Pixel 5 o Pixel 6
5. Selecciona una imagen del sistema:
   - **API Level 24+** (Android 7.0+) - Mínimo requerido
   - **API Level 34** (Android 14) - Recomendado para testing
   - Descarga la imagen si es necesario
6. Configura el AVD:
   - **Nombre:** `Pixel_5_API_34` (o el que prefieras)
   - **RAM:** 2048 MB mínimo (4096 MB recomendado)
   - **Storage:** 2048 MB mínimo
7. Haz clic en **Finish**

#### Opción B: Desde Terminal (Avanzado)

```bash
# Listar AVDs disponibles
flutter emulators

# Crear un nuevo emulador (si no tienes ninguno)
# Primero, listar system images disponibles
sdkmanager --list | grep system-images

# Descargar una system image (ejemplo: Android 14)
sdkmanager "system-images;android-34;google_apis;x86_64"

# Crear el AVD
avdmanager create avd -n Pixel_5_API_34 \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_5"
```

### Paso 3: Iniciar el Emulador

#### Opción A: Desde Android Studio

1. Abre **Device Manager**
2. Haz clic en el botón ▶️ junto al emulador que creaste

#### Opción B: Desde Terminal

```bash
# Listar emuladores disponibles
flutter emulators

# Iniciar un emulador específico
flutter emulators --launch Pixel_5_API_34

# O usar el comando de emulator directamente
emulator -avd Pixel_5_API_34
```

**Espera a que el emulador arranque completamente** (puede tomar 1-2 minutos la primera vez)

### Paso 4: Verificar que Flutter Detecta el Emulador

```bash
flutter devices
```

**Esperado:**
```
3 connected devices:

Pixel 5 API 34 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34) (emulator)
```

### Paso 5: Ejecutar la App en el Emulador

```bash
# Ejecutar en el emulador detectado
flutter run

# Si tienes múltiples dispositivos, especifica el emulador
flutter run -d emulator-5554

# Con hot reload habilitado (por defecto)
flutter run

# Con análisis de accesibilidad
flutter run --analyze-accessibility
```

**Salida esperada:**
```
Launching lib/main.dart on Pixel 5 API 34 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...
Waiting for Pixel 5 API 34 to report its views...
Debug service listening on ws://127.0.0.1:xxxxx
Synced 0.0MB
```

### Paso 6: Usar la App en el Emulador

Una vez que la app esté ejecutándose:

1. **Interactuar con la app:**
   - Usa el mouse para simular toques
   - Los botones tienen áreas táctiles grandes (80dp)

2. **Hot Reload (recarga en caliente):**
   - Haz cambios en el código
   - Presiona `r` en la terminal para recargar
   - O presiona `R` para reiniciar completamente

3. **Ver logs en tiempo real:**
   ```bash
   # En otra terminal
   flutter logs
   ```

4. **Probar TalkBack (lector de pantalla):**
   ```bash
   # Habilitar TalkBack desde el emulador:
   # Settings → Accessibility → TalkBack → On
   ```

### Paso 7: Detener la App

```bash
# Presiona 'q' en la terminal donde está corriendo flutter run
# O usa Ctrl+C
```

### 🔧 Troubleshooting

#### El emulador no aparece en `flutter devices`

```bash
# Verificar que el emulador esté corriendo
adb devices

# Si no aparece, reinicia adb
adb kill-server
adb start-server

# Verifica nuevamente
flutter devices
```

#### Error: "Unable to locate adb"

```bash
# Agrega Android SDK a tu PATH
# En ~/.zshrc o ~/.bashrc:
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Recarga el shell
source ~/.zshrc  # o source ~/.bashrc
```

#### El emulador es muy lento

**Soluciones:**
1. Asegúrate de tener **Intel HAXM** (o **Hypervisor Framework** en Mac M1/M2) instalado
2. Aumenta la RAM del emulador:
   - Device Manager → Edit AVD → Show Advanced Settings → RAM: 4096 MB
3. Habilita aceleración gráfica:
   - Graphics: **Hardware - GLES 2.0**

#### Error: "Gradle build failed"

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```

#### Error de Firebase: "google-services.json is missing"

```bash
# Verificar que el archivo esté en el lugar correcto
ls -la android/app/google-services.json

# Si falta, revisa la sección "Setup Inicial" del README
```

### 📱 Emuladores Recomendados para Testing

| Emulador | API Level | Uso |
|----------|-----------|-----|
| **Pixel 5 - API 34** | Android 14 | Testing de última versión |
| **Pixel 4 - API 24** | Android 7.0 | Testing de versión mínima |
| **Pixel Tablet - API 34** | Android 14 | Testing de pantallas grandes |

### 💡 Tips para Desarrollo

**Durante el desarrollo de features:**

```bash
# 1. Inicia el emulador
flutter emulators --launch Pixel_5_API_34

# 2. Ejecuta la app con hot reload
flutter run

# 3. En otra terminal, observa los logs
flutter logs

# 4. Haz cambios en el código
# 5. Presiona 'r' para hot reload o 'R' para hot restart
```

**Atajos de teclado en la terminal de Flutter:**

- `r` - Hot reload (recarga cambios de UI)
- `R` - Hot restart (reinicia la app completamente)
- `h` - Mostrar ayuda
- `q` - Salir
- `s` - Captura de pantalla
- `w` - Debug widget hierarchy

### 🔍 Gestión de Procesos de Flutter

#### Verificar si Flutter Run está ejecutándose

```bash
# Ver todos los procesos de Flutter
ps aux | grep "flutter run" | grep -v grep

# Solo ver el PID (Process ID)
pgrep -f "flutter run"

# Ver información detallada
ps aux | grep flutter | grep -v grep
```

**Salida si está corriendo:**
```
augustoc.p.  12345   0.5  1.2  ... flutter run -d emulator-5554
```

**Salida si NO está corriendo:** (sin salida)

#### Detener el Proceso de Flutter Run

**Opción 1: Desde la terminal donde está corriendo (Recomendado)**

```bash
# Presiona la tecla 'q' para salir limpiamente
q
```

**Opción 2: Matar el proceso desde otra terminal**

```bash
# Matar todos los procesos de "flutter run"
pkill -f "flutter run"

# Verificar que se detuvo
pgrep -f "flutter run"  # No debe mostrar nada
```

**Opción 3: Detener todo (Flutter + App en emulador)**

```bash
# Detener flutter run
pkill -f "flutter run"

# Detener la app en el emulador
adb shell am force-stop com.accessibilityapp.lamb

# Verificar que la app se cerró
adb shell "pm list packages | grep lamb"
```

#### Comandos Adicionales Útiles

```bash
# Ver logs de la app (aunque Flutter run no esté corriendo)
adb logcat -s flutter:I ActivityManager:I

# Filtrar solo logs de tu app
adb logcat | grep "com.accessibilityapp.lamb"

# Desinstalar la app del emulador
adb uninstall com.accessibilityapp.lamb

# Reiniciar el emulador
adb reboot

# Cerrar completamente el emulador
adb emu kill
```

---

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
