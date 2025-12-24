# Reglas para Automatización de WhatsApp

## ⚠️ ADVERTENCIA LEGAL Y ÉTICA

**CUMPLIMIENTO ESTRICTO:**
1. **NO recopilar datos del usuario** - Solo automatizar acciones que el usuario solicita
2. **Declaración de privacidad clara** - Explicar exactamente qué hace la app
3. **Uso legítimo documentado** - Para Google Play review
4. **NO violar EULA de WhatsApp** - No reverse engineering, no modificación de la app

---

## Limitaciones Conocidas

### Fragilidad de la Solución

**AccessibilityService depende de la UI de WhatsApp:**
- ✅ Funciona mientras WhatsApp no cambie IDs de recursos o estructura
- ⚠️ Cada actualización de WhatsApp puede romper funcionalidad
- ❌ NO hay garantía de estabilidad a largo plazo

**Estrategia de mitigación:**
1. Logging detallado para debug rápido
2. Detección de versión de WhatsApp
3. Tests automatizados para detectar cambios
4. Plan B: Deep links de WhatsApp (limitado)

---

## Política de Google Play

### Requisitos para Publicación

**AccessibilityService solo puede usarse para:**
- Ayudar a usuarios con discapacidades
- Automatizar tareas para usuarios con necesidades especiales

**DOCUMENTAR en Google Play:**
- Video demostrativo del uso legítimo
- Descripción clara: "Esta app ayuda a adultos mayores con baja visión"
- Declaración de privacidad detallada

### Texto Ejemplo para Descripción

```
Esta aplicación utiliza el servicio de Accesibilidad de Android para ayudar
a personas con baja visión a interactuar con WhatsApp mediante comandos de voz.

Permisos utilizados:
- Accesibilidad: Para automatizar la apertura de chats y lectura de mensajes
- Notificaciones: Para leer mensajes entrantes en voz alta

Esta app NO recopila, almacena ni transmite ningún dato personal o conversaciones.
Todas las acciones son locales en el dispositivo del usuario.
```

---

## Estructura de AccessibilityService

### AssistantAccessibilityService.kt

```kotlin
package com.accessibilityapp

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class AssistantAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AccessibilityService"
        private const val WHATSAPP_PACKAGE = "com.whatsapp"

        // Singleton para acceder desde MainActivity
        private var instance: AssistantAccessibilityService? = null

        fun getInstance(): AssistantAccessibilityService? = instance
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Logging detallado para debugging
        Log.d(TAG, """
            Event: ${event.eventType}
            Package: ${event.packageName}
            Class: ${event.className}
            Text: ${event.text}
        """.trimIndent())

        // Solo procesar eventos de WhatsApp
        if (event.packageName != WHATSAPP_PACKAGE) return

        // Detectar cuando WhatsApp está listo
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                onWhatsAppWindowChanged(event)
            }
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                onWhatsAppNotification(event)
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility Service destroyed")
    }

    // === Métodos Públicos para Platform Channel ===

    /**
     * Abre un chat de WhatsApp por nombre de contacto
     *
     * @param contactName Nombre exacto del contacto
     * @param timeoutMs Tiempo máximo de espera (ms)
     * @throws WhatsAppNotInstalledException
     * @throws ContactNotFoundException
     * @throws AccessibilityPermissionException
     */
    @Throws(Exception::class)
    fun openWhatsAppChat(contactName: String, timeoutMs: Int = 10000) {
        Log.d(TAG, "Opening WhatsApp chat: $contactName")

        // 1. Verificar que WhatsApp esté instalado
        if (!isWhatsAppInstalled()) {
            throw WhatsAppNotInstalledException()
        }

        // 2. Abrir WhatsApp
        val intent = packageManager.getLaunchIntentForPackage(WHATSAPP_PACKAGE)
            ?: throw WhatsAppNotInstalledException()

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)

        // 3. Esperar a que la UI cargue
        Thread.sleep(2000) // TODO: Mejorar con callback de evento

        // 4. Buscar contacto en la UI
        val contactNode = findContactInUI(contactName, timeoutMs)
            ?: throw ContactNotFoundException(contactName)

        // 5. Simular tap en el contacto
        clickNode(contactNode)

        Log.d(TAG, "Chat opened successfully")
    }

    /**
     * Lee los últimos N mensajes de un chat
     *
     * @param contactName Nombre del contacto
     * @param limit Número máximo de mensajes
     * @return Lista de mensajes (más reciente primero)
     */
    fun getLastMessages(contactName: String, limit: Int = 10): List<WhatsAppMessage> {
        // Implementación depende de abrir el chat primero
        openWhatsAppChat(contactName)
        Thread.sleep(1000) // Esperar carga de mensajes

        val messages = mutableListOf<WhatsAppMessage>()
        val rootNode = rootInActiveWindow ?: return messages

        // Buscar nodos con texto (mensajes)
        findMessageNodes(rootNode, messages, limit)

        return messages.take(limit)
    }

    // === Métodos Privados de Búsqueda en UI ===

    /**
     * Busca un contacto en la UI de WhatsApp
     *
     * Estrategia:
     * 1. Buscar por resource-id (más estable)
     * 2. Fallback: Buscar por texto
     * 3. Timeout si no se encuentra
     */
    private fun findContactInUI(
        contactName: String,
        timeoutMs: Int
    ): AccessibilityNodeInfo? {
        val startTime = System.currentTimeMillis()

        while (System.currentTimeMillis() - startTime < timeoutMs) {
            val rootNode = rootInActiveWindow ?: continue

            // Estrategia 1: Buscar por resource-id (si existe)
            var nodes = rootNode.findAccessibilityNodeInfosByViewId(
                "com.whatsapp:id/conversations_row_contact_name"
            )

            val nodeById = nodes.firstOrNull { node ->
                node.text?.toString()?.equals(contactName, ignoreCase = true) == true
            }
            if (nodeById != null) {
                Log.d(TAG, "Contact found by resource-id")
                return nodeById
            }

            // Estrategia 2: Buscar por texto (fallback)
            nodes = rootNode.findAccessibilityNodeInfosByText(contactName)
            val nodeByText = nodes.firstOrNull { node ->
                node.text?.toString()?.equals(contactName, ignoreCase = true) == true
            }
            if (nodeByText != null) {
                Log.d(TAG, "Contact found by text")
                return nodeByText
            }

            // Esperar un poco antes de reintentar
            Thread.sleep(500)
        }

        Log.e(TAG, "Contact not found after ${timeoutMs}ms")
        return null
    }

    /**
     * Simula un tap en un nodo de Accessibility
     */
    private fun clickNode(node: AccessibilityNodeInfo) {
        // Primero intentar acción de click nativa
        if (node.isClickable && node.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
            Log.d(TAG, "Node clicked via ACTION_CLICK")
            return
        }

        // Si falla, usar dispatchGesture en las coordenadas
        val rect = android.graphics.Rect()
        node.getBoundsInScreen(rect)

        val x = rect.centerX().toFloat()
        val y = rect.centerY().toFloat()

        simulateTap(x, y)
    }

    /**
     * Simula un tap en coordenadas específicas
     */
    fun simulateTap(x: Float, y: Float) {
        val path = Path().apply {
            moveTo(x, y)
        }

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()

        val result = dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription) {
                Log.d(TAG, "Gesture completed at ($x, $y)")
            }

            override fun onCancelled(gestureDescription: GestureDescription) {
                Log.w(TAG, "Gesture cancelled")
            }
        }, null)

        if (!result) {
            Log.e(TAG, "Failed to dispatch gesture")
        }
    }

    /**
     * Busca nodos de mensajes en la UI de WhatsApp
     *
     * NOTA: Esto es MUY frágil y depende de la estructura de WhatsApp
     */
    private fun findMessageNodes(
        node: AccessibilityNodeInfo,
        messages: MutableList<WhatsAppMessage>,
        limit: Int
    ) {
        // Buscar nodos que parezcan mensajes
        // Ejemplo: resource-id "com.whatsapp:id/message_text"

        if (node.viewIdResourceName == "com.whatsapp:id/message_text") {
            val text = node.text?.toString()
            if (!text.isNullOrBlank()) {
                messages.add(WhatsAppMessage(
                    sender = "Unknown", // Difícil determinar sin contexto
                    text = text,
                    timestamp = System.currentTimeMillis()
                ))
            }
        }

        // Recursivamente buscar en hijos
        for (i in 0 until node.childCount) {
            if (messages.size >= limit) break

            val child = node.getChild(i) ?: continue
            findMessageNodes(child, messages, limit)
            child.recycle()
        }
    }

    // === Utilidades ===

    private fun isWhatsAppInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo(WHATSAPP_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun onWhatsAppWindowChanged(event: AccessibilityEvent) {
        // Detectar cuando WhatsApp cambia de pantalla
        Log.d(TAG, "WhatsApp window changed: ${event.className}")
    }

    private fun onWhatsAppNotification(event: AccessibilityEvent) {
        // Capturar notificaciones de WhatsApp
        val notification = event.text.joinToString(" ")
        Log.d(TAG, "WhatsApp notification: $notification")
    }
}

// === Excepciones Custom ===

class WhatsAppNotInstalledException : Exception("WhatsApp is not installed")
class ContactNotFoundException(contactName: String) : Exception("Contact '$contactName' not found")
class AccessibilityPermissionException : Exception("Accessibility permission not granted")

// === Data Classes ===

data class WhatsAppMessage(
    val sender: String,
    val text: String,
    val timestamp: Long
)
```

### AndroidManifest.xml

```xml
<service
    android:name=".AssistantAccessibilityService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config" />
</service>
```

### res/xml/accessibility_service_config.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeNotificationStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows"
    android:canRetrieveWindowContent="true"
    android:canPerformGestures="true"
    android:description="@string/accessibility_service_description"
    android:packageNames="com.whatsapp"
    android:settingsActivity=".SettingsActivity" />
```

### res/values/strings.xml

```xml
<string name="accessibility_service_description">
    Este servicio permite a la aplicación ayudar a personas con baja visión
    a interactuar con WhatsApp mediante comandos de voz.\n\n
    La aplicación puede:\n
    - Abrir chats específicos\n
    - Leer mensajes en voz alta\n\n
    NO recopila ni envía ningún dato. Todas las acciones son locales.
</string>
```

---

## Testing y Mantenimiento

### Detección de Cambios en WhatsApp

```kotlin
/**
 * Versión de WhatsApp que sabemos que funciona
 */
private const val TESTED_WHATSAPP_VERSION = "2.23.25.15"

fun checkWhatsAppVersion(): WhatsAppCompatibility {
    val packageInfo = packageManager.getPackageInfo(WHATSAPP_PACKAGE, 0)
    val currentVersion = packageInfo.versionName

    return when {
        currentVersion == TESTED_WHATSAPP_VERSION -> WhatsAppCompatibility.VERIFIED
        currentVersion > TESTED_WHATSAPP_VERSION -> WhatsAppCompatibility.UNKNOWN
        else -> WhatsAppCompatibility.OUTDATED
    }
}

enum class WhatsAppCompatibility {
    VERIFIED,   // Testeado y funcionando
    UNKNOWN,    // Versión más nueva, puede o no funcionar
    OUTDATED    // Versión vieja
}
```

### Logging para Debugging

```kotlin
fun logUIStructure() {
    val rootNode = rootInActiveWindow ?: return

    fun traverse(node: AccessibilityNodeInfo, depth: Int = 0) {
        val indent = "  ".repeat(depth)
        Log.d("UI_STRUCTURE", """
            $indent├─ ${node.className}
            $indent│  id: ${node.viewIdResourceName}
            $indent│  text: ${node.text}
            $indent│  clickable: ${node.isClickable}
        """.trimIndent())

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            traverse(child, depth + 1)
            child.recycle()
        }
    }

    traverse(rootNode)
}
```

---

## Plan B: Deep Links de WhatsApp

Si AccessibilityService falla, usar deep links limitados:

```kotlin
/**
 * Abre WhatsApp usando deep link (limitado, no puede seleccionar chat)
 */
fun openWhatsAppViaDeepLink(phoneNumber: String? = null) {
    val uri = if (phoneNumber != null) {
        // Abre chat con número específico (requiere código de país)
        Uri.parse("https://wa.me/$phoneNumber")
    } else {
        // Solo abre WhatsApp
        Uri.parse("whatsapp://")
    }

    val intent = Intent(Intent.ACTION_VIEW, uri).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    startActivity(intent)
}
```

**Limitaciones:**
- Requiere número de teléfono (no nombre de contacto)
- No puede leer mensajes
- Solo abre, no automatiza

---

## Checklist Pre-Commit

- [ ] Logging detallado en puntos clave
- [ ] Manejo de timeouts apropiados
- [ ] Validación de versión de WhatsApp
- [ ] Excepciones con mensajes claros
- [ ] Testing en dispositivo real con TalkBack
- [ ] Declaración de privacidad actualizada

---

## Referencias

- [Android AccessibilityService Guide](https://developer.android.com/guide/topics/ui/accessibility/service)
- [AccessibilityNodeInfo API](https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo)
- [Google Play Accessibility Policy](https://support.google.com/googleplay/android-developer/answer/10964491)
- [WhatsApp Deep Links](https://faq.whatsapp.com/general/chats/how-to-use-click-to-chat)
