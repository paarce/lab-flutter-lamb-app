# Platform Channels Skill - Comunicación Dart ↔ Kotlin

## Descripción
Guía para implementar Platform Channels que comunican Flutter (Dart) con 
código nativo Android (Kotlin).

## Cuándo Usar
- Al necesitar funcionalidades nativas de Android (MediaProjection, AccessibilityService)
- Cuando BACKLOG.md mencione "Platform Channel" o "código nativo"
- Al trabajar con permisos especiales de Android

## Estructura de un Platform Channel

### Lado Dart (Flutter)

**Ubicación:** `lib/services/[nombre]_service.dart`
```dart
import 'package:flutter/services.dart';

class MiService {
  static const platform = MethodChannel('com.accessibility.app/mi_canal');
  
  Future<String> llamarMetodoNativo(String parametro) async {
    try {
      final String result = await platform.invokeMethod(
        'nombreMetodo',
        {'parametro': parametro},
      );
      print('LOG [MiService.llamarMetodoNativo]: Resultado: $result');
      return result;
    } on PlatformException catch (e) {
      print('ERROR [MiService.llamarMetodoNativo]: ${e.message}');
      throw Exception('Error en Platform Channel: ${e.message}');
    }
  }
}
```

### Lado Kotlin (Android)

**Ubicación:** `android/app/src/main/kotlin/com/accessibility/app/MainActivity.kt`
```kotlin
package com.accessibility.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.accessibility.app/mi_canal"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "nombreMetodo" -> {
                        try {
                            val parametro = call.argument<String>("parametro")
                            val respuesta = miLogicaNativa(parametro)
                            result.success(respuesta)
                        } catch (e: Exception) {
                            result.error("ERROR_CODE", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun miLogicaNativa(parametro: String?): String {
        // Lógica nativa aquí
        return "Resultado desde Kotlin"
    }
}
```

## Convenciones de Nombres

**Channel name:** `com.accessibility.app/[nombre_descriptivo]`

Ejemplos:
- `com.accessibility.app/screen_capture`
- `com.accessibility.app/accessibility_control`
- `com.accessibility.app/whatsapp_automation`

**Method names:** `camelCase` en ambos lados

## Manejo de Errores

**Dart:**
```dart
try {
  await platform.invokeMethod('metodo');
} on PlatformException catch (e) {
  print('ERROR: ${e.code} - ${e.message}');
  // Manejar error
}
```

**Kotlin:**
```kotlin
try {
    // Lógica
    result.success(data)
} catch (e: Exception) {
    result.error("ERROR_CODE", e.message, null)
}
```

## Permisos de Android

Si el Platform Channel requiere permisos, agregar en:

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<manifest>
    <uses-permission android:name="android.permission.PERMISO_NECESARIO" />
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

Luego solicitar en Flutter con `permission_handler`:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> solicitarPermiso() async {
  final status = await Permission.camera.request(); // Ejemplo
  
  if (status.isGranted) {
    // Permiso otorgado
  } else {
    // Permiso denegado
  }
}
```

## Logging para Debugging

Agregar logs en ambos lados:

**Dart:**
```dart
print('LOG [NombreService.metodo]: Llamando a Platform Channel');
```

**Kotlin:**
```kotlin
Log.d("PlatformChannel", "Método nativo ejecutado")
```

## Checklist de Implementación

- [ ] Channel name sigue convención `com.accessibility.app/[nombre]`
- [ ] Método implementado en Dart (lib/services/)
- [ ] Método implementado en Kotlin (MainActivity.kt)
- [ ] Manejo de errores en ambos lados (try-catch)
- [ ] Permisos agregados en AndroidManifest.xml (si aplica)
- [ ] Logs agregados para debugging
- [ ] Probado en dispositivo físico

## Comandos Útiles
```bash
# Ver logs de Android en tiempo real
adb logcat | grep "PlatformChannel"

# Limpiar y reconstruir (necesario al cambiar código Kotlin)
flutter clean
flutter build apk
```

## Referencias
- Flutter Platform Channels: https://docs.flutter.dev/development/platform-integration/platform-channels