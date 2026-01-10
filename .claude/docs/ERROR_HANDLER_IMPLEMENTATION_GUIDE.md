# 📖 Guía Completa - Sistema de Gestión de Errores

**Versión:** 1.1.0 | **Fecha:** 10 Enero 2026 | **Proyecto:** Lamb

> 📌 **DOCUMENTO ÚNICO** - Contiene todo lo necesario para implementar ErrorHandlerService en el proyecto. Uso como documentación base para prompts adicionales.

---

## 📋 Tabla de Contenidos

1. [Estado Actual](#-estado-actual)
2. [Introducción](#introducción)
3. [Dónde Integrar (Roadmap)](#-dónde-integrar-roadmap)
4. [Pasos de Integración](#-pasos-de-integración)
5. [4 Casos de Uso Reales](#4-casos-de-uso-reales)
6. [Mejores Prácticas](#mejores-prácticas)
7. [Cuándo Usar canRetry](#cuándo-usar-canretry)
8. [Patrones por Componente](#patrones-por-componente)
9. [Testing con TalkBack](#testing-con-talkback)
10. [FAQ](#faq)
11. [Checklist de Integración](#checklist-de-integración)

---

## ✅ Estado Actual

El sistema de gestión de errores está **completamente implementado y listo para usar**:

- [x] `ErrorHandlerService` - Servicio central creado
- [x] `LoggerService` - Logging en memoria creado
- [x] Estructura de errores (AppError, ErrorCategory, ErrorCodes)
- [x] Mensajes accesibles en español
- [x] Registrado en Providers (main.dart)
- [x] Documentación completa

**No hay que crear nada más.** Solo integrarlo en los servicios, providers y screens existentes.

---

## Introducción

El `ErrorHandlerService` es el **punto centralizado** para manejar TODOS los errores en la app.

**Ventajas:**
- ✅ Consistencia en toda la app
- ✅ Accesibilidad automática (TTS, diálogos modales)
- ✅ Sin duplicación de código
- ✅ Debugging fácil (logs centralizados)

---

## 🗺️ Dónde Integrar (Roadmap)

### Orden Recomendado de Integración

#### 1️⃣ **Servicios (HIGH Priority)**

Estos son los "pilares" de la app. Integra aquí PRIMERO:

- [ ] **lib/services/firebase_signaling_service.dart**
  - Método: Cualquiera que acceda a Firestore
  - Ejemplo: `conectarFirestore()`, `sincronizarDatos()`
  
- [ ] **lib/services/elevenlabs_service.dart**
  - Método: `speak(text)` - TTS principal
  - Método: Cualquier método que acceda a API
  
- [ ] **lib/services/webrtc_service.dart**
  - Método: Cualquiera que se conecte remotamente
  
- [ ] **lib/services/webrtc_client_service.dart**
  - Método: Similar a webrtc_service
  
- [ ] **lib/services/foreground_service.dart**
  - Método: Cualquiera que pueda fallar

#### 2️⃣ **Providers (MEDIUM Priority)**

State management - Guarda errores en estado:

- [ ] **lib/providers/remote_control_provider.dart**
  - Método: `startSession()`, métodos principales
  
- [ ] **lib/providers/remote_viewer_provider.dart**
  - Método: Similar a remote_control

#### 3️⃣ **Screens (LOW Priority)**

UI - Botones que llaman servicios:

- [ ] **lib/screens/home_screen.dart**
  - En botones que inicien procesos
  
- [ ] **lib/screens/client_connect_screen.dart**
  - En lógica de conexión
  
- [ ] **lib/screens/client_viewer_screen.dart**
  - En lógica de visualización

---

## 🔌 Pasos de Integración

### Paso 1: Importar lo necesario

```dart
import 'package:flutter/material.dart';  // Para BuildContext
import 'package:provider/provider.dart';  // Para context.read()

import '../services/error_handler_service.dart';
import '../services/elevenlabs_service.dart';  // Para TTS
```

### Paso 2: En cada método que pueda fallar, agregar try-catch

**ANTES (sin error handling):**
```dart
Future<void> conectarFirebase() async {
  await Firestore.instance.collection('users').get();
}
```

**DESPUÉS (con error handling):**
```dart
Future<void> conectarFirebase(BuildContext context) async {
  try {
    await Firestore.instance.collection('users').get();
  } catch (e) {
    if (context.mounted) {
      await ErrorHandlerService.handleError(
        context: context,
        error: e,
        service: 'FirebaseSignalingService',
        canRetry: true,
        onRetry: () => conectarFirebase(context),
        ttsService: context.read<ElevenLabsService>(),
      );
    }
  }
}
```

---

## 4 Casos de Uso Reales

### Caso 1: Error en un Service (Firebase)

**Archivo:** `lib/services/firebase_signaling_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/error_handler_service.dart';
import '../services/elevenlabs_service.dart';

class FirebaseSignalingService {
  /// Conectar a Firestore
  /// 
  /// Nota: Agregar BuildContext como parámetro para manejo de errores
  Future<void> conectarFirestore(BuildContext context) async {
    try {
      // Lógica original de conexión
      final doc = await Firestore.instance
          .collection('users')
          .doc('userId')
          .get();
      
      debugPrint('[Firebase] Conectado correctamente');
    } catch (e, stackTrace) {
      // Manejo automático del error
      if (context.mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: e,
          service: 'FirebaseSignalingService',
          canRetry: true,  // Conexión a BD → se puede reintentar
          onRetry: () => conectarFirestore(context),
          ttsService: context.read<ElevenLabsService>(),
        );
      }
      // Opcional: propagar error si necesitas logging adicional
      rethrow;
    }
  }
}
```

**¿Qué pasa automáticamente?**
- ✅ Detecta que es error de Firebase
- ✅ Genera mensaje: "No pudimos conectar con el servidor..."
- ✅ Reproduce con TTS
- ✅ Muestra diálogo modal con botones "Cerrar" y "Reintentar"
- ✅ Registra en logs

---

### Caso 2: Error en un Provider (State Management)

**Archivo:** `lib/providers/remote_control_provider.dart`

En Providers es diferente: **guardas el error en estado** para que el UI lo maneje.

```dart
import 'package:flutter/material.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';

class RemoteControlProvider extends ChangeNotifier {
  // Guardar último error
  AppError? _lastError;
  AppError? get lastError => _lastError;

  /// Iniciar sesión remota
  Future<void> startRemoteSession() async {
    try {
      // Lógica de sesión...
      _lastError = null;  // Limpiar error previo
      notifyListeners();
    } catch (e, stackTrace) {
      // Guardar error en estado
      _lastError = e is AppError
          ? e
          : AppError(
              category: ErrorCategory.unknown,
              code: 'SESSION_ERROR',
              userMessage: 'No pudimos iniciar la sesión remota.',
              technicalMessage: e.toString(),
              stackTrace: stackTrace,
              canRetry: true,
            );
      notifyListeners();  // Notificar UI
    }
  }

  /// Limpiar error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
```

**Ahora en el Screen/Widget:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/remote_control_provider.dart';
import '../services/error_handler_service.dart';
import '../services/elevenlabs_service.dart';

class RemoteControlScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteControlProvider>(
      builder: (context, provider, child) {
        // Mostrar error si existe (próximo frame, no en build)
        if (provider.lastError != null) {
          Future.microtask(() {
            if (context.mounted) {
              ErrorHandlerService.handleError(
                context: context,
                error: provider.lastError!,
                service: 'RemoteControlProvider',
                canRetry: true,
                onRetry: () {
                  provider.startRemoteSession();
                },
                ttsService: context.read<ElevenLabsService>(),
              );
              provider.clearError();  // Limpiar después de mostrar
            }
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Control Remoto')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => provider.startRemoteSession(),
              child: const Text('Iniciar Sesión Remota'),
            ),
          ),
        );
      },
    );
  }
}
```

**¿Por qué es diferente?**
- Providers no tienen acceso directo a `context` en el método
- Guardas el error en estado
- El Widget lo muestra usando ErrorHandlerService

---

### Caso 3: AppError Personalizado

Si necesitas un error con **mensaje muy específico** (no el genérico):

```dart
import '../errors/app_error.dart';
import '../errors/error_category.dart';

// En tu servicio:
Future<void> inicializarAudio() async {
  // Verificar si API key existe
  if (Secrets.elevenLabsApiKey.isEmpty) {
    throw AppError(
      category: ErrorCategory.elevenLabs,
      code: 'API_KEY_NOT_CONFIGURED',
      technicalMessage: 'elevenLabsApiKey vacío en secrets.dart',
      userMessage: 'La configuración de audio no está completa. '
          'Por favor, contacta con soporte.',
      canRetry: false,  // No tiene sentido reintentar
    );
  }
  
  // Resto de la lógica...
}
```

**Cuándo usar:**
- Necesitas mensaje más específico
- La categoría/código estándar no cubre tu caso
- Requiere instrucciones especiales para el usuario

---

### Caso 4: Error en Platform Channel (Kotlin)

**Archivo:** `lib/services/whatsapp_service.dart` (futuro)

```dart
import 'package:flutter/services.dart';

import '../errors/error_codes.dart';
import '../errors/error_category.dart';
import 'error_handler_service.dart';

class WhatsAppService {
  static const platform = MethodChannel(
    'com.accessibility.app/whatsapp'
  );

  /// Abrir chat de WhatsApp
  Future<void> openChat(
    String contactName,
    BuildContext context,
  ) async {
    try {
      await platform.invokeMethod('openChat', {'name': contactName});
    } on PlatformException catch (e) {
      // ErrorHandlerService detecta automáticamente que es PlatformException
      if (context.mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: e,  // PlatformException → se convierte a AppError
          service: 'WhatsAppService',
          // NO reintentar si Accessibility Service no está activo
          canRetry: e.code != ErrorCodes.pcAccessibilityServiceInactive,
          onRetry: () => openChat(contactName, context),
          ttsService: context.read<ElevenLabsService>(),
        );
      }
    }
  }

  /// Leer últimos mensajes
  Future<List<String>> readMessages(String contactName) async {
    try {
      final result = await platform.invokeMethod<List>(
        'readMessages',
        {'name': contactName},
      );
      return List<String>.from(result ?? []);
    } on PlatformException catch (e) {
      print('ERROR [WhatsAppService]: ${e.code} - ${e.message}');
      throw AppError(
        category: ErrorCategory.platformChannel,
        code: e.code,
        technicalMessage: e.message,
        userMessage: 'No pudimos leer los mensajes.',
        canRetry: true,
      );
    }
  }
}
```

**Nota:** ErrorHandlerService normaliza automáticamente `PlatformException`

---

## Patrones por Componente

### Patrón A: En un Service

**Estructura básica:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/error_handler_service.dart';
import '../services/elevenlabs_service.dart';

class MiService {
  // Agregar BuildContext como parámetro
  Future<void> hacerAlgo(BuildContext context) async {
    try {
      // Lógica original aquí
      print('Haciendo algo...');
    } catch (e, stackTrace) {
      // Manejo de error
      if (context.mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: e,
          service: 'MiService',        // Nombre del servicio
          canRetry: true,              // ¿Se puede reintentar?
          onRetry: () => hacerAlgo(context),  // Callback
          ttsService: context.read<ElevenLabsService>(),
        );
      }
    }
  }
}
```

**Cuándo usar este patrón:**
- Métodos llamados desde UI (tienen acceso a BuildContext)
- Métodos que necesitan TTS inmediatamente
- Operaciones críticas (conexión, sincronización)

### Patrón B: En un Provider

**Estructura básica:**

```dart
class MiProvider extends ChangeNotifier {
  AppError? _lastError;
  
  Future<void> doSomething() async {
    try {
      // Lógica original
      _lastError = null;
      notifyListeners();
    } catch (e, stackTrace) {
      // Guardar error en estado
      _lastError = e is AppError ? e : AppError(
        category: ErrorCategory.unknown,
        code: 'UNKNOWN',
        userMessage: 'Error desconocido',
        technicalMessage: e.toString(),
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }
  
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}

// EN EL WIDGET:
if (provider.lastError != null) {
  Future.microtask(() {
    if (context.mounted) {
      ErrorHandlerService.handleError(
        context: context,
        error: provider.lastError!,
        service: 'MiProvider',
        canRetry: true,
        onRetry: () => provider.doSomething(),
        ttsService: context.read<ElevenLabsService>(),
      );
      provider.clearError();
    }
  });
}
```

**Cuándo usar este patrón:**
- Métodos del Provider (sin acceso directo a BuildContext)
- Estado que cambia dinámicamente
- Errores que necesitan persistir en el estado

---

## Mejores Prácticas

### ✅ HACER

```dart
// ✅ BIEN: Usar ErrorHandlerService
await ErrorHandlerService.handleError(
  context: context,
  error: e,
  service: 'MiService',
  canRetry: true,
  onRetry: () => reintentar(),
  ttsService: context.read<ElevenLabsService>(),
);

// ✅ BIEN: Verificar context.mounted
if (context.mounted) {
  await ErrorHandlerService.handleError(...);
}

// ✅ BIEN: Nombres de service descriptivos
service: 'FirebaseSignalingService'
service: 'RemoteControlProvider'
service: 'WhatsAppService'

// ✅ BIEN: Capturar errores específicos
} catch (e, stackTrace) {
  // Tienes acceso a stack trace
}
```

### ❌ NO HACER

```dart
// ❌ MALO: Mostrar diálogo manualmente
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Error: ${e.toString()}'),  // Mensaje técnico
    content: Text('Algo salió mal'),
  ),
);

// ❌ MALO: Sin TTS para accesibilidad
await ErrorHandlerService.handleError(
  context: context,
  error: e,
  service: 'MyService',
  // SIN ttsService ❌
);

// ❌ MALO: Sin verificar context.mounted
await ErrorHandlerService.handleError(
  context: context,  // Puede no estar montado
  error: e,
  service: 'MyService',
);

// ❌ MALO: Reintentos infinitos
while (true) {
  try {
    await hacerAlgo();
    break;
  } catch (e) {
    // Reintentar sin fin
  }
}

// ❌ MALO: Mostrar errores técnicos al usuario
userMessage: 'Exception: SocketException: Os error: Connection refused'
```

---

## Cuándo Usar `canRetry`

### `canRetry: true` - Mostrar botón "Reintentar"

Usar cuando el error es **transitorio** y reintentar **tiene sentido**:

| Error | Ejemplo | ¿Reintentar? |
|-------|---------|-------------|
| **Sin internet** | `SocketException` | ✅ Sí |
| **Timeout** | Servidor no responde | ✅ Sí |
| **Rate limit** | API límite excedido | ✅ Sí |
| **Conexión Firebase** | Firestore no conecta | ✅ Sí |
| **WebRTC ICE** | No encuentra conexión peer | ✅ Sí |

```dart
canRetry: true,
onRetry: () => miServicio.hacerAlgo(),
```

### `canRetry: false` - Solo "Cerrar"

Usar cuando el error es **permanente** y necesita acción manual:

| Error | Ejemplo | ¿Reintentar? |
|-------|---------|-------------|
| **Permiso denegado** | `PERMISSION_DENIED` | ❌ No |
| **Accessibility Service inactivo** | `ACCESSIBILITY_SERVICE_INACTIVE` | ❌ No |
| **API key faltante** | Secrets no configurados | ❌ No |
| **Configuración faltante** | Parámetro requerido | ❌ No |
| **Feature no disponible** | Método no existe en plataforma | ❌ No |

```dart
canRetry: false,
// onRetry: null,  // Omitir
```

---

## 💡 Decisiones Clave

### ¿Cuándo poner `canRetry: true` vs `false`?

**`true` (mostrar "Reintentar"):**
- Error transitorio: Sin internet, timeout, servidor no responde
- Error de API: Rate limit, conexión temporal
- Error de red: SocketException, TimeoutException

**`false` (solo "Cerrar"):**
- Configuración faltante: API key, secretos no configurados
- Permiso denegado: PERMISSION_DENIED, ACCESSIBILITY_SERVICE_INACTIVE
- Error permanente: Método no existe en plataforma

### ¿Siempre pasar `ttsService`?

**SÍ,** siempre que sea posible:
```dart
ttsService: context.read<ElevenLabsService>(),
```

Si no está disponible en cierto contexto, es opcional:
```dart
// OK sin TTS (ej: en background service)
await ErrorHandlerService.handleError(
  context: context,
  error: e,
  service: 'MyService',
  // ttsService: null,  // Omitir si no disponible
);
```

### Verificar `context.mounted`

**SIEMPRE verificar antes de usar context:**
```dart
if (context.mounted) {
  await ErrorHandlerService.handleError(...);
}
```

Esto previene errores si el widget fue unmounted mientras se procesaba el error.

---

## Testing con TalkBack

Para verificar que la accesibilidad funciona correctamente:

### 1. Activar TalkBack

```bash
# Opción A: Por Settings
Android → Settings → Accessibility → TalkBack → ON

# Opción B: Por terminal
adb shell settings put secure enabled_accessibility_services \
  com.google.android.marvin.talkback/.TalkBackService
```

### 2. Ejecutar app

```bash
flutter run
```

### 3. Provocar un error

Ejecutar código que lance excepción:
```dart
throw Exception('Error de prueba');
```

### 4. Verificar

- [ ] Diálogo aparece
- [ ] TalkBack **lee el título** ("Ha ocurrido un problema")
- [ ] TalkBack **lee el mensaje** de error
- [ ] TalkBack **anuncia los botones** ("Botón Cerrar", "Botón Reintentar")
- [ ] **Al tocar botón**, se ejecuta la acción
- [ ] **TTS reproduce** el mensaje de error

---

## FAQ

### P: ¿Dónde debo integrar ErrorHandlerService?

**R:** En orden de prioridad:

1. **HIGH:** Services (firebase_signaling, elevenlabs, webrtc)
2. **MEDIUM:** Providers (remote_control, remote_viewer)
3. **LOW:** Screens (home, client_connect, client_viewer)

### P: ¿Qué pasa si no paso `ttsService`?

**R:** El error se muestra igual, pero sin reproducción de audio. No es recomendado para usuarios con baja visión.

```dart
// Funciona, pero sin TTS
await ErrorHandlerService.handleError(
  context: context,
  error: e,
  service: 'MyService',
  canRetry: true,
  // ttsService: null,  // Sin audio
);
```

### P: ¿Puedo personalizar el diálogo?

**R:** No en ErrorHandlerService. Si necesitas diálogo muy diferente, crea uno manual. Pero para consistencia, usa ErrorHandlerService.

### P: ¿Cómo accedo a los logs?

**R:** Los logs se guardan en memoria (máximo 100):

```dart
final logger = LoggerService();
final logs = logger.getLogs();
logs.forEach(print);

// Limpiar
logger.clearLogs();
```

### P: ¿ErrorHandlerService reintentar automáticamente?

**R:** **NO.** Solo muestra botón si `canRetry: true`. Usuario decide si reintentar.

### P: ¿Qué categorías de error existen?

**R:** 6 categorías principales:

1. `PLATFORM_CHANNEL` - Errores de Kotlin/Android
2. `FIREBASE` - Firestore, Authentication
3. `ELEVENLABS` - STT/TTS API
4. `WEBRTC` - Control remoto
5. `NETWORK` - Conectividad general
6. `UNKNOWN` - No clasificados

---

## Checklist de Integración

Para cada servicio/provider que integres:

- [ ] Importados: `ErrorHandlerService`, `elevenlabs_service`
- [ ] Try-catch agregado
- [ ] `ErrorHandlerService.handleError()` llamado con parámetros correctos
- [ ] `service:` con nombre descriptivo
- [ ] `canRetry:` apropiado (true/false)
- [ ] `onRetry:` callback si aplica
- [ ] `ttsService:` para reproducción de TTS
- [ ] `context.mounted` verificado antes de usar context
- [ ] Testeado manualmente
- [ ] **Testeado con TalkBack activado** (si es screen)
- [ ] Mensajes son claros y accesibles

---

## Recursos

**Implementación:**
- [lib/services/error_handler_service.dart](./lib/services/error_handler_service.dart) - Servicio central
- [lib/services/logger_service.dart](./lib/services/logger_service.dart) - Logging
- [lib/utils/error_messages.dart](./lib/utils/error_messages.dart) - Mensajes

**Documentación del Proyecto:**
- [CLAUDE.md](./CLAUDE.md) - Referencia general del proyecto
- [CHANGELOG.md](./CHANGELOG.md) - Versión 1.1.0

**Modelos de Error:**
- [lib/errors/app_error.dart](./lib/errors/app_error.dart)
- [lib/errors/error_category.dart](./lib/errors/error_category.dart)
- [lib/errors/error_codes.dart](./lib/errors/error_codes.dart)

---

**¡Listo para implementar!** 🚀
