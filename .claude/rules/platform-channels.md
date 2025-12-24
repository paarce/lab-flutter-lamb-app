# Reglas para Platform Channels

## Principios

1. **Comunicación Flutter ↔ Kotlin debe ser robusta** - Manejo de errores en ambos lados
2. **Documentar CADA método del channel** - Otro desarrollador debe entender sin contexto
3. **Logging detallado** - Debugging de Platform Channels es complejo

---

## Estructura de Platform Channels

### Nomenclatura

```dart
// Flutter side - SIEMPRE usar identificador único inverso de dominio
static const platform = MethodChannel('com.accessibilityapp/whatsapp');
static const eventChannel = EventChannel('com.accessibilityapp/whatsapp_events');
```

```kotlin
// Android side - DEBE coincidir exactamente
private val CHANNEL = "com.accessibilityapp/whatsapp"
private val EVENT_CHANNEL = "com.accessibilityapp/whatsapp_events"
```

### Convención de Nombres de Métodos

| Categoría | Prefijo | Ejemplo |
|-----------|---------|---------|
| Acciones | `do`, `execute`, `perform` | `openChat`, `sendMessage` |
| Queries | `get`, `read`, `fetch` | `getLastMessages`, `readContacts` |
| Validaciones | `is`, `has`, `check` | `isWhatsAppInstalled`, `hasPermission` |

---

## Flutter Side (Dart)

### Estructura de Service

```dart
import 'package:flutter/services.dart';

class WhatsAppService {
  static const _platform = MethodChannel('com.accessibilityapp/whatsapp');
  static const _events = EventChannel('com.accessibilityapp/whatsapp_events');

  /// Abre un chat de WhatsApp por nombre de contacto
  ///
  /// [contactName] Nombre exacto del contacto en WhatsApp
  ///
  /// Throws [PlatformException] si:
  /// - WhatsApp no está instalado (code: 'WHATSAPP_NOT_FOUND')
  /// - Contacto no existe (code: 'CONTACT_NOT_FOUND')
  /// - Permiso de Accessibility no otorgado (code: 'PERMISSION_DENIED')
  Future<void> openChat(String contactName) async {
    try {
      await _platform.invokeMethod('openChat', {
        'name': contactName,
        'timeout': 10000, // ms para esperar carga de UI
      });
    } on PlatformException catch (e) {
      // Logging para debugging
      print('[WhatsAppService] openChat failed: ${e.code} - ${e.message}');

      // Re-throw con contexto adicional si es necesario
      if (e.code == 'PERMISSION_DENIED') {
        throw Exception(
          'Se requiere permiso de Accesibilidad. '
          'Por favor, actívalo en Configuración.'
        );
      }
      rethrow;
    }
  }

  /// Stream de mensajes nuevos de WhatsApp
  ///
  /// Emite [Map<String, dynamic>] con estructura:
  /// {
  ///   'sender': String,
  ///   'message': String,
  ///   'timestamp': int (Unix timestamp),
  /// }
  Stream<Map<String, dynamic>> get newMessages {
    return _events.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }

  /// Verifica si WhatsApp está instalado
  ///
  /// Returns [true] si está instalado, [false] si no
  Future<bool> isInstalled() async {
    try {
      final result = await _platform.invokeMethod<bool>('isWhatsAppInstalled');
      return result ?? false;
    } catch (e) {
      print('[WhatsAppService] isInstalled failed: $e');
      return false;
    }
  }
}
```

### Manejo de Errores

```dart
// ✅ SIEMPRE capturar PlatformException
try {
  await service.openChat('María');
} on PlatformException catch (e) {
  // Manejar errores específicos por código
  switch (e.code) {
    case 'WHATSAPP_NOT_FOUND':
      showError('WhatsApp no está instalado');
      break;
    case 'CONTACT_NOT_FOUND':
      showError('No se encontró el contacto María');
      break;
    case 'PERMISSION_DENIED':
      navigateToPermissionSettings();
      break;
    default:
      showError('Error inesperado: ${e.message}');
  }
} catch (e) {
  // Errores genéricos
  showError('Error desconocido');
  print('[ERROR] $e');
}
```

---

## Android Side (Kotlin)

### MainActivity.kt - Channel Handler

```kotlin
package com.accessibilityapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.accessibilityapp/whatsapp"
    private val EVENT_CHANNEL = "com.accessibilityapp/whatsapp_events"
    private val TAG = "MainActivity"

    private lateinit var whatsappAutomation: WhatsAppAutomation

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializar servicios
        whatsappAutomation = WhatsAppAutomation(context)

        // MethodChannel para llamadas request-response
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openChat" -> {
                    handleOpenChat(call, result)
                }
                "isWhatsAppInstalled" -> {
                    result.success(whatsappAutomation.isInstalled())
                }
                "getLastMessages" -> {
                    handleGetLastMessages(call, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // EventChannel para streams
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(WhatsAppEventStreamHandler(whatsappAutomation))
    }

    private fun handleOpenChat(call: MethodCall, result: MethodChannel.Result) {
        // Validar parámetros
        val contactName = call.argument<String>("name")
        if (contactName.isNullOrBlank()) {
            result.error(
                "INVALID_ARGUMENT",
                "Contact name cannot be empty",
                null
            )
            return
        }

        val timeout = call.argument<Int>("timeout") ?: 10000

        try {
            Log.d(TAG, "Opening chat for contact: $contactName")

            whatsappAutomation.openChat(contactName, timeout)

            Log.d(TAG, "Chat opened successfully")
            result.success(null)

        } catch (e: WhatsAppNotInstalledException) {
            Log.e(TAG, "WhatsApp not installed", e)
            result.error(
                "WHATSAPP_NOT_FOUND",
                "WhatsApp is not installed on this device",
                null
            )
        } catch (e: ContactNotFoundException) {
            Log.e(TAG, "Contact not found: $contactName", e)
            result.error(
                "CONTACT_NOT_FOUND",
                "Contact '$contactName' not found in WhatsApp",
                null
            )
        } catch (e: AccessibilityPermissionException) {
            Log.e(TAG, "Accessibility permission not granted", e)
            result.error(
                "PERMISSION_DENIED",
                "Accessibility service permission is required",
                null
            )
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error opening chat", e)
            result.error(
                "UNKNOWN_ERROR",
                "An unexpected error occurred: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleGetLastMessages(call: MethodCall, result: MethodChannel.Result) {
        val contactName = call.argument<String>("name")
        val limit = call.argument<Int>("limit") ?: 10

        if (contactName.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "Contact name required", null)
            return
        }

        try {
            val messages = whatsappAutomation.getLastMessages(contactName, limit)

            // Convertir a formato que Flutter entiende
            val messagesList = messages.map { msg ->
                mapOf(
                    "sender" to msg.sender,
                    "message" to msg.text,
                    "timestamp" to msg.timestamp
                )
            }

            result.success(messagesList)

        } catch (e: Exception) {
            Log.e(TAG, "Error getting messages", e)
            result.error("ERROR", e.message, null)
        }
    }
}
```

### EventChannel para Streams

```kotlin
class WhatsAppEventStreamHandler(
    private val automation: WhatsAppAutomation
) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        // Iniciar listener de notificaciones
        automation.startListeningForMessages { message ->
            // Enviar evento a Flutter
            eventSink?.success(mapOf(
                "sender" to message.sender,
                "message" to message.text,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }

    override fun onCancel(arguments: Any?) {
        automation.stopListeningForMessages()
        eventSink = null
    }
}
```

---

## Códigos de Error Estándar

### Usar códigos consistentes

| Código | Significado | Cuándo Usar |
|--------|-------------|-------------|
| `INVALID_ARGUMENT` | Parámetro faltante o inválido | Validación de inputs |
| `PERMISSION_DENIED` | Permiso no otorgado | Accessibility, notificaciones |
| `NOT_FOUND` | Recurso no existe | App, contacto, archivo no encontrado |
| `TIMEOUT` | Operación excedió tiempo límite | UI de WhatsApp no cargó a tiempo |
| `UNKNOWN_ERROR` | Error inesperado | Catch-all para excepciones no manejadas |
| `NOT_IMPLEMENTED` | Método no implementado | Features en desarrollo |

---

## Testing de Platform Channels

### Unit Tests (Dart)

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.accessibilityapp/whatsapp');

  setUp(() {
    // Mock del channel
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'isWhatsAppInstalled') {
        return true;
      }
      if (methodCall.method == 'openChat') {
        final name = methodCall.arguments['name'];
        if (name == 'María') {
          return null; // success
        } else {
          throw PlatformException(
            code: 'CONTACT_NOT_FOUND',
            message: 'Contact not found',
          );
        }
      }
      return null;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('isWhatsAppInstalled returns true', () async {
    final service = WhatsAppService();
    final result = await service.isInstalled();
    expect(result, true);
  });

  test('openChat with existing contact succeeds', () async {
    final service = WhatsAppService();
    await expectLater(
      service.openChat('María'),
      completes,
    );
  });

  test('openChat with non-existing contact throws', () async {
    final service = WhatsAppService();
    await expectLater(
      service.openChat('NoExiste'),
      throwsA(isA<PlatformException>()),
    );
  });
}
```

### Integration Tests (Android)

```kotlin
@RunWith(AndroidJUnit4::class)
class WhatsAppAutomationTest {

    @Test
    fun openChat_withValidContact_succeeds() {
        val automation = WhatsAppAutomation(context)

        // Assuming WhatsApp is installed and contact exists
        assertDoesNotThrow {
            automation.openChat("Test Contact", 10000)
        }
    }

    @Test
    fun openChat_withInvalidContact_throwsException() {
        val automation = WhatsAppAutomation(context)

        assertThrows<ContactNotFoundException> {
            automation.openChat("NonExistentContact123", 5000)
        }
    }
}
```

---

## Debugging

### Logs Estructurados

```dart
// Flutter
import 'dart:developer' as developer;

developer.log(
  'Opening WhatsApp chat',
  name: 'WhatsAppService',
  error: exception,
  stackTrace: stackTrace,
);
```

```kotlin
// Android
import android.util.Log

Log.d(TAG, "Method: openChat, Contact: $contactName")
Log.e(TAG, "Error occurred", exception)
```

### Ver logs en tiempo real

```bash
# Flutter logs
flutter logs

# Android specific (filtrado)
adb logcat -s MainActivity:D WhatsAppAutomation:D AccessibilityService:D
```

---

## Performance

### Evitar Llamadas Frecuentes

```dart
// ❌ MAL - Llamar platform channel en cada frame
StreamBuilder(
  stream: Stream.periodic(Duration(milliseconds: 16)),
  builder: (context, snapshot) {
    whatsAppService.isInstalled(); // 60 veces por segundo!
    // ...
  },
)

// ✅ BIEN - Cachear resultado
class WhatsAppProvider extends ChangeNotifier {
  bool? _isInstalled;

  Future<bool> checkInstalled() async {
    if (_isInstalled != null) return _isInstalled!;

    _isInstalled = await whatsAppService.isInstalled();
    return _isInstalled!;
  }
}
```

### Operaciones Asíncronas en Background

```kotlin
// ✅ Operaciones largas en background thread
import kotlinx.coroutines.*

suspend fun openChat(contactName: String, timeout: Int) = withContext(Dispatchers.IO) {
    // Operación larga (buscar UI, simular gestos)
    // ...
}
```

---

## Checklist Antes de Commit

- [ ] Documentación completa de cada método (Dart y Kotlin)
- [ ] Manejo de errores con códigos específicos
- [ ] Logs en puntos clave
- [ ] Unit tests para casos success y error
- [ ] Validación de parámetros antes de usar
- [ ] Operaciones largas en background (Kotlin)
- [ ] No hay llamadas frecuentes innecesarias (Flutter)

---

## Referencias

- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [MethodChannel Documentation](https://api.flutter.dev/flutter/services/MethodChannel-class.html)
- [EventChannel Documentation](https://api.flutter.dev/flutter/services/EventChannel-class.html)
