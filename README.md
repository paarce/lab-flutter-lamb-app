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

**IMPORTANTE:** El archivo `secrets.dart` contiene credenciales y NO debe ser commiteado.

```bash
# 1. Crear secrets.dart desde el template
cd lib/config
cp secrets.example.dart secrets.dart

# 2. Editar secrets.dart con tus credenciales reales
nano secrets.dart
# O usar tu editor preferido: code secrets.dart, vim secrets.dart, etc.
```

**Credenciales necesarias:**
- **ElevenLabs:** API Key (para Speech-to-Text)
- **Firebase:** Web API Key, App IDs (web y Android), Project ID, Messaging Sender ID, Auth Domain, Storage Bucket

**Obtener credenciales:**
- ElevenLabs: [https://elevenlabs.io/app/settings/api-keys](https://elevenlabs.io/app/settings/api-keys)
- Firebase: Console → Project Settings → General → Your apps

### 3. Firebase

✅ **Configuración centralizada** - Las credenciales se gestionan desde `lib/config/secrets.dart` (gitignored).

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

## 📱 Ejecutar en Dispositivo Físico Android

### Requisitos del Dispositivo

- **Android 7.0 (API 24) o superior** - Versión mínima requerida
- Cable USB con **transferencia de datos** (no solo carga)
- Conexión estable entre dispositivo y computadora

### Paso 1: Habilitar Modo Desarrollador en el Dispositivo

El modo desarrollador permite la depuración USB, necesaria para ejecutar la app desde Flutter.

**Activar Opciones de Desarrollador:**

1. Abre **Configuración** (Settings) en tu dispositivo Android
2. Ve a **Acerca del teléfono** (About phone)
3. Busca **Número de compilación** (Build number)
4. **Toca 7 veces** sobre "Número de compilación"
5. Verás un mensaje: "Ahora eres un desarrollador" o similar

**Ubicación en diferentes marcas:**
- **Samsung:** Settings → About phone → Software information → Build number
- **Xiaomi:** Settings → About phone → MIUI version (tocar 7 veces)
- **Google Pixel:** Settings → About phone → Build number
- **Huawei:** Settings → About phone → Build number

### Paso 2: Habilitar Depuración USB

Una vez activado el modo desarrollador:

1. Regresa a **Configuración** (Settings)
2. Busca **Opciones de desarrollador** (Developer options)
   - Puede estar en: Settings → System → Advanced → Developer options
   - O directamente en: Settings → Developer options
3. Activa el switch de **Opciones de desarrollador** (si está desactivado)
4. Busca **Depuración USB** (USB debugging)
5. **Activa** el switch de Depuración USB
6. Aparecerá un diálogo de confirmación → Toca **Aceptar** o **OK**

### Paso 3: Conectar el Dispositivo a la Computadora

1. **Conecta el dispositivo** a tu Mac/PC usando un cable USB
2. **En el dispositivo:** Aparecerá una notificación sobre el modo USB
   - Toca la notificación
   - Selecciona **Transferencia de archivos** o **PTP** (NO "Solo carga")
3. **Autorizar la computadora:**
   - Aparecerá un diálogo: "¿Permitir depuración USB?"
   - Marca "**Permitir siempre desde este equipo**"
   - Toca **Aceptar**

### Paso 4: Verificar Detección del Dispositivo

**Verificar a nivel de sistema (macOS):**

```bash
# Ver dispositivos USB conectados
system_profiler SPUSBDataType | grep -i android
```

**Verificar con ADB:**

```bash
# Ver dispositivos Android detectados
adb devices
```

**Salida esperada:**
```
List of devices attached
F3NKCY004517    device
```

Si aparece `unauthorized` en lugar de `device`, repite el Paso 3 (autorizar computadora).

**Si `adb` no se encuentra:**

```bash
# Instalar Android platform tools (macOS)
brew install android-platform-tools

# Verificar instalación
adb --version
```

**Verificar con Flutter:**

```bash
# Ver todos los dispositivos detectados por Flutter
flutter devices
```

**Salida esperada:**
```
2 connected devices:

K013 (mobile) • F3NKCY004517 • android-arm64 • Android 9 (API 28)
Chrome (web)  • chrome       • web-javascript • Google Chrome 120.0.6099.109
```

### Paso 5: Ejecutar la App en el Dispositivo

Una vez que el dispositivo aparece en `flutter devices`:

```bash
# Ejecutar en el dispositivo conectado
flutter run

# Si tienes múltiples dispositivos, especifica el ID
flutter run -d F3NKCY004517

# Con análisis de accesibilidad (recomendado)
flutter run --analyze-accessibility
```

**Salida esperada:**
```
Launching lib/main.dart on K013 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...
Waiting for K013 to report its views...
Debug service listening on ws://127.0.0.1:xxxxx
Synced 0.0MB

🔥 App corriendo en el dispositivo
```

### Paso 6: Usar la App en el Dispositivo

Una vez que la app esté ejecutándose:

1. **Interactuar con la app:**
   - Usa el dispositivo normalmente
   - Los botones tienen áreas táctiles grandes (80dp) para accesibilidad

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
   - Settings → Accessibility → TalkBack → Activar
   - Verifica que todos los elementos se anuncian correctamente

### Paso 7: Detener la App

```bash
# Presiona 'q' en la terminal donde está corriendo flutter run
# O usa Ctrl+C
```

### 🔧 Troubleshooting - Dispositivo Físico

#### El dispositivo no aparece en `adb devices`

**Solución 1: Reiniciar servidor ADB**
```bash
adb kill-server
adb start-server
adb devices
```

**Solución 2: Verificar cable USB**
- Usa un cable **con transferencia de datos** (no solo carga)
- Prueba otro cable o puerto USB

**Solución 3: Verificar modo USB**
- Cambia el modo USB en el dispositivo a "Transferencia de archivos" o "PTP"

**Solución 4: Revocar autorizaciones USB**
- En el dispositivo: Developer options → Revoke USB debugging authorizations
- Desconecta y vuelve a conectar el dispositivo
- Vuelve a autorizar la computadora

#### El dispositivo aparece como `unauthorized`

```bash
# En el dispositivo:
# 1. Ve a Developer options → Revoke USB debugging authorizations
# 2. Desconecta el cable USB
# 3. Vuelve a conectar el cable
# 4. Aparecerá el diálogo "¿Permitir depuración USB?" nuevamente
# 5. Marca "Permitir siempre" y toca Aceptar

# Verificar nuevamente
adb devices
```

#### Error: `INSTALL_FAILED_OLDER_SDK`

Este error significa que tu dispositivo tiene una versión de Android **anterior a 7.0** (API 24).

```bash
# Verificar versión de Android del dispositivo
adb shell getprop ro.build.version.sdk
```

**Solución:**
- Usa un dispositivo con **Android 7.0 o superior**
- O usa un emulador con API 24+

#### El dispositivo se desconecta durante la ejecución

**Causas comunes:**
- **Ahorro de energía:** Desactiva "Optimización de batería" para la depuración USB
- **Cable defectuoso:** Usa un cable de mejor calidad
- **Puerto USB inestable:** Prueba otro puerto USB en tu computadora

**Solución:**
```bash
# En el dispositivo:
# Settings → Battery → Battery optimization → All apps
# Busca "USB debugging" o tu app → Don't optimize
```

#### La app se instala pero no se abre

```bash
# Verificar que la app se instaló
adb shell pm list packages | grep lamb

# Forzar apertura de la app
adb shell am start -n com.accessibilityapp.lamb/.MainActivity

# Ver logs para errores
adb logcat | grep flutter
```

### 📱 Dispositivos Recomendados para Testing

| Característica | Recomendación |
|----------------|---------------|
| **Android Version** | 7.0+ (API 24+) |
| **RAM** | 2GB+ |
| **Almacenamiento** | 16GB+ |
| **Pantalla** | 5.5" o más grande (para accesibilidad) |

**Dispositivos comunes compatibles (2017+):**
- Samsung Galaxy S7 o superior
- Google Pixel (cualquier generación)
- Xiaomi Redmi Note 5 o superior
- Motorola Moto G5 o superior

### 💡 Tips para Testing en Dispositivo Físico

**Ventajas vs Emulador:**
- ✅ Performance real del hardware
- ✅ Testing de TalkBack/accesibilidad más preciso
- ✅ Prueba de gestos táctiles reales
- ✅ Testing de sensores (cámara, micrófono para STT)

**Durante el desarrollo:**
```bash
# 1. Conecta el dispositivo
adb devices

# 2. Ejecuta la app
flutter run -d <device-id>

# 3. Observa los logs
flutter logs

# 4. Haz cambios en el código y presiona 'r' para hot reload
```

**Atajos de teclado en la terminal de Flutter:**
- `r` - Hot reload (recarga cambios de UI)
- `R` - Hot restart (reinicia la app completamente)
- `h` - Mostrar ayuda
- `q` - Salir
- `s` - Captura de pantalla

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
