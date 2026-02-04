# 📋 MANUAL TEST CASES - Funcionalidad 5: WhatsApp Integration

**Versión:** 1.0.0
**Funcionalidad:** Integración completa de WhatsApp con comandos de voz y gestión de contactos favoritos
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 28 (20 P0 + 8 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Bridge Voice to WhatsApp](#-categoría-a-bridge-voice-to-whatsapp)
- [B. Contact Storage (Hive)](#-categoría-b-contact-storage-hive)
- [C. WhatsApp Screen UI](#-categoría-c-whatsapp-screen-ui)
- [D. Contact Configuration Screen](#-categoría-d-contact-configuration-screen)
- [E. Open Chat by Name (Voice)](#-categoría-e-open-chat-by-name-voice)
- [F. Deep Link Integration](#-categoría-f-deep-link-integration)
- [G. Accesibilidad (TalkBack)](#-categoría-g-accesibilidad-talkback)
- [Resumen de Cobertura](#-resumen-de-cobertura)

---

## 🔧 PREREQUISITOS GLOBALES

Estos prerequisitos aplican para **TODOS** los test cases a menos que se indique lo contrario:

### **Configuración del Entorno:**
- ✅ Dispositivo Android 7.0+ (API 24+) físico o emulador
- ✅ Conexión a internet activa (WiFi o datos móviles) para ElevenLabs API
- ✅ ElevenLabs API key válida configurada en `lib/config/secrets.dart`
- ✅ App compilada sin errores: `flutter run`
- ✅ Volumen multimedia del dispositivo > 50% (para escuchar TTS)
- ✅ Ambiente relativamente silencioso (sin ruido excesivo de fondo)
- ✅ **WhatsApp instalado** en el dispositivo (requerido para Feature 5)

### **Estado Inicial de la App:**
- ✅ App instalada y ejecutándose
- ✅ Usuario está en `VoiceCommandScreen`
- ✅ Sin contactos favoritos guardados (estado limpio)
- ✅ Cache limpio (opcional: desinstalar/reinstalar app para limpiar Hive)

### **Permisos del Sistema:**
- ✅ Permiso de micrófono otorgado (Settings → Apps → Lamb → Permissions → Microphone: Allow)
- ✅ Permiso de internet otorgado (automático)

### **Secrets Configurados:**
```dart
// lib/config/secrets.dart
class Secrets {
  static const String elevenLabsApiKey = 'sk-...'; // API key válida
  static const String elevenLabsVoiceId = 'voice_id_here'; // Opcional
}
```

---

## 🚀 SETUP DE PRUEBAS

### **Opción 1: Desarrollo Local**

```bash
# Terminal 1 - Ejecutar app en dispositivo/emulador
cd /path/to/lamb

# Obtener dependencias nuevas (uuid, hive_generator, build_runner)
flutter pub get

# Generar adaptador de Hive (si es necesario)
flutter pub run build_runner build

# Ejecutar app
flutter run

# Verificar que compila sin errores
# Verificar que VoiceCommandScreen se muestra
```

### **Opción 2: Build de Debug**

```bash
# Build APK debug
flutter build apk --debug

# Instalar en dispositivo
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### **Verificación de Setup:**

1. Abrir app
2. Verificar que `VoiceCommandScreen` se muestra
3. Verificar que en la sección "WHATSAPP" de comandos disponibles aparece:
   - "Abrir WhatsApp"
   - "Chat de [nombre]"
4. Verificar que WhatsApp está instalado en el dispositivo

### **Limpiar Datos de Prueba:**

```bash
# Limpiar base de datos Hive (desinstalar y reinstalar)
adb uninstall com.accessibilityapp.lamb
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Bridge Voice to WhatsApp | 4 | 3 | 1 | ~15 min |
| B. Contact Storage (Hive) | 5 | 4 | 1 | ~20 min |
| C. WhatsApp Screen UI | 5 | 4 | 1 | ~20 min |
| D. Contact Configuration Screen | 5 | 4 | 1 | ~20 min |
| E. Open Chat by Name (Voice) | 5 | 3 | 2 | ~20 min |
| F. Deep Link Integration | 2 | 1 | 1 | ~10 min |
| G. Accesibilidad (TalkBack) | 2 | 1 | 1 | ~15 min |
| **TOTAL** | **28** | **20** | **8** | **~120 min** |

---

## 📂 CATEGORÍA A: BRIDGE VOICE TO WHATSAPP

**Prerequisitos específicos:** Permiso de micrófono otorgado, WhatsApp instalado

---

### ✅ TC-WA-001: Comando "abrir whatsapp" abre la aplicación

**Prioridad:** P0
**Objetivo:** Verificar que el comando de voz "abrir whatsapp" abre WhatsApp correctamente

**Prerequisitos adicionales:**
- WhatsApp instalado en el dispositivo
- Usuario en `VoiceCommandScreen`

**Pasos:**
1. Abrir app en `VoiceCommandScreen`
2. Mantener presionado botón de micrófono >200ms
3. Decir claramente: "abrir whatsapp"
4. Soltar botón
5. Observar comportamiento

**Resultado Esperado:**
- ✅ Transcripción muestra "abrir whatsapp"
- ✅ TTS anuncia: "Abriendo WhatsApp"
- ✅ WhatsApp se abre automáticamente
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Executing command: CommandType.openWhatsApp
  [WhatsAppService] Opening WhatsApp
  [WhatsAppService] WhatsApp opened successfully
  ```
- ✅ Sin errores en consola

**Criterios de Aceptación:**
- WhatsApp se abre en < 2 segundos
- TTS completo antes de abrir WhatsApp
- Sin crasheos

---

### ✅ TC-WA-002: Variaciones del comando "abrir whatsapp"

**Prioridad:** P0
**Objetivo:** Verificar que múltiples variaciones del comando funcionan

**Pasos:**
1. **Intento 1:** Decir "abre whatsapp"
2. Volver a la app, repetir
3. **Intento 2:** Decir "abrime whatsapp"
4. Volver a la app, repetir
5. **Intento 3:** Decir "whatsapp" (solo keyword)

**Resultado Esperado:**
- ✅ 3/3 variaciones reconocidas como `CommandType.openWhatsApp`
- ✅ TTS anuncia "Abriendo WhatsApp" en cada caso
- ✅ WhatsApp se abre en cada caso
- ✅ **En logs:**
  ```
  [NLPParser] Parsing: "abre whatsapp"
  [VoiceCommandProvider] Parsed command: CommandType.openWhatsApp
  ```

**Criterios de Aceptación:**
- Reconocimiento exitoso de las 3 variaciones
- Feedback TTS claro en cada caso

---

### ✅ TC-WA-003: WhatsApp no instalado muestra error

**Prioridad:** P0
**Objetivo:** Verificar que se muestra error accesible cuando WhatsApp no está instalado

**Prerequisitos adicionales:**
- WhatsApp NO instalado en el dispositivo (desinstalar temporalmente)

**Pasos:**
1. Desinstalar WhatsApp del dispositivo
2. Abrir app en `VoiceCommandScreen`
3. Mantener presionado botón >200ms
4. Decir: "abrir whatsapp"
5. Observar comportamiento

**Resultado Esperado:**
- ✅ TTS anuncia primero: "Abriendo WhatsApp"
- ✅ Luego aparece diálogo de error modal
- ✅ TTS anuncia error: "WhatsApp no está instalado en este dispositivo"
- ✅ Diálogo tiene botón "Cerrar" (80dp, 24sp)
- ✅ **En logs:**
  ```
  [WhatsAppService] Failed to open WhatsApp
  [ErrorHandlerService] Handling error: NOT_FOUND
  ```
- ✅ App NO crashea

**Criterios de Aceptación:**
- Mensaje de error es user-friendly (español simple)
- Usuario puede cerrar diálogo y continuar usando app
- TTS lee mensaje de error completo

**Cleanup:**
- Reinstalar WhatsApp después de la prueba

---

### ✅ TC-WA-004: Comando con contacto sin favoritos guardados

**Prioridad:** P1
**Objetivo:** Verificar comportamiento cuando se pide chat con contacto pero no hay favoritos

**Prerequisitos adicionales:**
- Sin contactos favoritos guardados (estado limpio)

**Pasos:**
1. Asegurar que no hay contactos favoritos (app recién instalada o limpiada)
2. Mantener presionado botón >200ms
3. Decir: "chat de María"
4. Observar comportamiento

**Resultado Esperado:**
- ✅ TTS anuncia: "No encontré a María en tus contactos favoritos. Puedes agregarlo en la pantalla de WhatsApp."
- ✅ WhatsApp NO se abre
- ✅ Estado vuelve a idle
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Contact not found in favorites: maría
  ```

**Criterios de Aceptación:**
- Mensaje es útil y guía al usuario
- No se abre WhatsApp sin contacto válido

---

## 📂 CATEGORÍA B: CONTACT STORAGE (HIVE)

**Prerequisitos específicos:** App con estado limpio (sin contactos previos)

---

### ✅ TC-WA-005: Agregar primer contacto exitosamente

**Prioridad:** P0
**Objetivo:** Verificar que se puede agregar un contacto favorito

**Pasos:**
1. Navegar a WhatsAppScreen (implementar navegación manual si es necesario)
2. Verificar que muestra "No tienes contactos favoritos"
3. Tap en "Agregar Contacto"
4. En formulario:
   - Nombre: "María García"
   - Teléfono: "+52 55 1234 5678"
5. Tap en "Guardar"

**Resultado Esperado:**
- ✅ TTS anuncia: "Contacto guardado"
- ✅ Navegación automática de regreso a WhatsAppScreen
- ✅ ContactCard visible con:
   - Nombre: "María García"
   - Teléfono enmascarado: "+52 55 ** **78"
   - Icono de WhatsApp verde
- ✅ Contador actualizado: "1 de 8 contactos"
- ✅ **En logs:**
  ```
  [ContactsProvider] Adding contact: María García
  [ContactStorageService] Saved contact: María García (uuid)
  ```

**Criterios de Aceptación:**
- Contacto persiste después de cerrar y reabrir app
- Formato de teléfono sanitizado correctamente

---

### ✅ TC-WA-006: Contacto persiste después de reiniciar app

**Prioridad:** P0
**Objetivo:** Verificar que Hive persiste datos correctamente

**Prerequisitos adicionales:**
- Contacto "María García" agregado (TC-WA-005)

**Pasos:**
1. Con contacto guardado, cerrar app completamente (swipe up desde recents)
2. Esperar 3 segundos
3. Abrir app nuevamente
4. Navegar a WhatsAppScreen

**Resultado Esperado:**
- ✅ Contacto "María García" sigue visible
- ✅ Datos intactos (nombre, teléfono)
- ✅ **En logs al iniciar:**
  ```
  [Hive] Inicializado correctamente con adaptadores
  [ContactStorageService] Contacts box opened with 1 contacts
  ```

**Criterios de Aceptación:**
- Datos 100% persistidos sin pérdida
- Carga de contactos < 500ms

---

### ✅ TC-WA-007: Límite máximo de 8 contactos

**Prioridad:** P0
**Objetivo:** Verificar que no se pueden agregar más de 8 contactos

**Pasos:**
1. Agregar 8 contactos (usando TC-WA-005 repetidamente):
   - María García, Juan Pérez, Ana López, Carlos Ruiz
   - Laura Martínez, Pedro Sánchez, Sofía Hernández, Diego Torres
2. Verificar contador: "8 de 8 contactos"
3. Verificar que botón "Agregar Contacto" NO aparece
4. Verificar que aparece texto informativo sobre límite

**Resultado Esperado:**
- ✅ 8 contactos visibles en lista
- ✅ Botón "Agregar Contacto" NO visible (o deshabilitado)
- ✅ Texto visible: "Has alcanzado el máximo de 8 contactos"
- ✅ **En logs si se intenta agregar programáticamente:**
  ```
  [ContactStorageService] Cannot save contact: max limit of 8 reached
  ```

**Criterios de Aceptación:**
- Límite de 8 estrictamente enforced
- UI refleja estado correcto
- Mensaje informativo para usuario

---

### ✅ TC-WA-008: Eliminar contacto libera espacio

**Prioridad:** P0
**Objetivo:** Verificar que eliminar contacto actualiza contador y permite agregar nuevos

**Prerequisitos adicionales:**
- 8 contactos guardados (TC-WA-007)

**Pasos:**
1. Con 8 contactos, long-press en "Diego Torres"
2. En pantalla de edición, tap en "Eliminar"
3. Confirmar eliminación en diálogo
4. Verificar que vuelve a WhatsAppScreen
5. Verificar contador: "7 de 8 contactos"
6. Verificar que botón "Agregar Contacto" aparece nuevamente

**Resultado Esperado:**
- ✅ TTS anuncia: "Contacto eliminado"
- ✅ ContactCard de "Diego Torres" desaparece
- ✅ Contador actualizado a "7 de 8"
- ✅ Botón "Agregar Contacto" visible nuevamente
- ✅ **En logs:**
  ```
  [ContactStorageService] Deleted contact: Diego Torres (uuid)
  ```

**Criterios de Aceptación:**
- Eliminación es inmediata en UI
- Datos eliminados de Hive permanentemente
- Espacio liberado para nuevos contactos

---

### ✅ TC-WA-009: Editar contacto existente

**Prioridad:** P1
**Objetivo:** Verificar que se puede editar nombre y teléfono de contacto

**Pasos:**
1. Long-press en "María García"
2. En pantalla de edición:
   - Cambiar nombre a "María García López"
   - Cambiar teléfono a "+52 55 9876 5432"
3. Tap en "Guardar"
4. Verificar cambios en WhatsAppScreen

**Resultado Esperado:**
- ✅ TTS anuncia: "Contacto actualizado"
- ✅ ContactCard muestra nuevo nombre y teléfono
- ✅ Cambios persisten después de reiniciar app
- ✅ **En logs:**
  ```
  [ContactsProvider] Updating contact: (uuid)
  ```

**Criterios de Aceptación:**
- Edición no duplica contacto
- ID del contacto se mantiene igual

---

## 📂 CATEGORÍA C: WHATSAPP SCREEN UI

**Prerequisitos específicos:** Contactos de prueba agregados

---

### ✅ TC-WA-010: Pantalla inicial sin contactos

**Prioridad:** P0
**Objetivo:** Verificar estado vacío de WhatsAppScreen

**Prerequisitos adicionales:**
- Sin contactos favoritos (estado limpio)

**Pasos:**
1. Navegar a WhatsAppScreen
2. Observar UI

**Resultado Esperado:**
- ✅ TTS anuncia: "Pantalla de WhatsApp. Tus contactos favoritos."
- ✅ Título: "WhatsApp"
- ✅ Header: "Contactos Favoritos"
- ✅ Contador: "0 de 8 contactos"
- ✅ Icono grande de personas (people_outline)
- ✅ Texto: "No tienes contactos favoritos"
- ✅ Subtexto: "Agrega hasta 8 contactos para abrirlos por voz"
- ✅ Botón "Agregar Contacto" visible en footer

**Criterios de Aceptación:**
- Estado vacío es claro y no confuso
- Call-to-action visible

---

### ✅ TC-WA-011: Tap en contacto abre chat

**Prioridad:** P0
**Objetivo:** Verificar que tap en ContactCard abre chat de WhatsApp

**Prerequisitos adicionales:**
- Contacto "María García" con número válido guardado
- WhatsApp instalado

**Pasos:**
1. En WhatsAppScreen, tap en ContactCard de "María García"
2. Observar comportamiento

**Resultado Esperado:**
- ✅ TTS anuncia: "Abriendo chat de María García"
- ✅ WhatsApp se abre con chat de ese número
- ✅ **En logs:**
  ```
  [WhatsAppScreen] Opening chat for: María García
  [WhatsAppService] Opening WhatsApp chat for phone: 5255...
  ```

**Criterios de Aceptación:**
- WhatsApp abre chat correcto (número coincide)
- Latencia < 2 segundos

---

### ✅ TC-WA-012: Long-press abre edición

**Prioridad:** P0
**Objetivo:** Verificar que long-press en ContactCard abre pantalla de edición

**Pasos:**
1. En WhatsAppScreen, long-press (~500ms) en ContactCard de "María García"
2. Observar navegación

**Resultado Esperado:**
- ✅ Navegación a ContactConfigurationScreen
- ✅ TTS anuncia: "Editando contacto María García"
- ✅ Formulario pre-llenado con datos actuales
- ✅ Botón "Eliminar" visible (modo edición)
- ✅ **En logs:**
  ```
  [WhatsAppScreen] Editing contact: María García
  ```

**Criterios de Aceptación:**
- Long-press detectado correctamente
- Datos cargados sin delay

---

### ✅ TC-WA-013: Ordenamiento de contactos

**Prioridad:** P0
**Objetivo:** Verificar que contactos se ordenan por sortOrder/nombre

**Prerequisitos adicionales:**
- 3+ contactos guardados: Ana, María, Carlos

**Pasos:**
1. Agregar contactos en orden: María, Ana, Carlos
2. Observar orden en lista

**Resultado Esperado:**
- ✅ Contactos ordenados por sortOrder (orden de creación) si tienen sortOrder
- ✅ Si sortOrder igual o null, ordenados alfabéticamente por nombre
- ✅ Orden consistente después de reiniciar app

**Criterios de Aceptación:**
- Orden predecible y consistente
- Orden se mantiene después de ediciones

---

### ✅ TC-WA-014: Scroll con muchos contactos

**Prioridad:** P1
**Objetivo:** Verificar que la lista es scrollable con 8 contactos

**Prerequisitos adicionales:**
- 8 contactos guardados

**Pasos:**
1. Con 8 contactos, observar UI
2. Scroll hacia abajo para ver todos los contactos
3. Verificar que footer permanece visible

**Resultado Esperado:**
- ✅ Lista es scrollable
- ✅ Todos los 8 contactos accesibles
- ✅ Footer sticky permanece visible
- ✅ Sin problemas de performance al scrollear

**Criterios de Aceptación:**
- Scroll suave (60 fps)
- Footer siempre accesible

---

## 📂 CATEGORÍA D: CONTACT CONFIGURATION SCREEN

**Prerequisitos específicos:** WhatsAppScreen accesible

---

### ✅ TC-WA-015: Validación de nombre obligatorio

**Prioridad:** P0
**Objetivo:** Verificar que no se puede guardar sin nombre

**Pasos:**
1. Tap en "Agregar Contacto"
2. Dejar campo nombre vacío
3. Ingresar teléfono válido: "+52 55 1234 5678"
4. Tap en "Guardar"

**Resultado Esperado:**
- ✅ Error de validación: "El nombre es obligatorio"
- ✅ TTS anuncia: "Por favor, corrige los errores del formulario"
- ✅ Contacto NO se guarda
- ✅ Campo nombre resaltado con error

**Criterios de Aceptación:**
- Validación previene guardado
- Mensaje de error claro

---

### ✅ TC-WA-016: Validación de teléfono mínimo 10 dígitos

**Prioridad:** P0
**Objetivo:** Verificar validación de longitud mínima de teléfono

**Pasos:**
1. Tap en "Agregar Contacto"
2. Ingresar nombre: "Test"
3. Ingresar teléfono: "123456789" (9 dígitos)
4. Tap en "Guardar"

**Resultado Esperado:**
- ✅ Error de validación: "El número debe tener al menos 10 dígitos"
- ✅ TTS anuncia error
- ✅ Contacto NO se guarda

**Criterios de Aceptación:**
- Validación cuenta solo dígitos (ignora espacios, +, -)

---

### ✅ TC-WA-017: Sanitización de teléfono

**Prioridad:** P0
**Objetivo:** Verificar que teléfono se sanitiza correctamente

**Pasos:**
1. Agregar contacto con teléfono: "55 1234 5678" (sin código de país)
2. Guardar y verificar

**Resultado Esperado:**
- ✅ Contacto guardado exitosamente
- ✅ Teléfono sanitizado a: "+525512345678"
- ✅ **En logs:**
  ```
  [ContactsProvider] Phone sanitized: +525512345678
  ```

**Criterios de Aceptación:**
- Espacios y guiones removidos
- Código de país (+52 México) agregado si falta

---

### ✅ TC-WA-018: Confirmación antes de eliminar

**Prioridad:** P0
**Objetivo:** Verificar diálogo de confirmación de eliminación

**Pasos:**
1. Long-press en contacto existente
2. Tap en "Eliminar"
3. Observar diálogo de confirmación
4. **Caso 1:** Tap en "Cancelar"
5. **Caso 2:** Tap en "Eliminar"

**Resultado Esperado (Caso 1 - Cancelar):**
- ✅ Diálogo muestra: "¿Estás seguro de eliminar a [nombre]?"
- ✅ Botones: "Cancelar" y "Eliminar" (rojo)
- ✅ Al cancelar: TTS "Eliminación cancelada"
- ✅ Contacto NO eliminado

**Resultado Esperado (Caso 2 - Eliminar):**
- ✅ TTS: "Contacto eliminado"
- ✅ Navegación de regreso a WhatsAppScreen
- ✅ Contacto removido de lista

**Criterios de Aceptación:**
- No se puede eliminar accidentalmente
- Feedback claro en ambos casos

---

### ✅ TC-WA-019: Teclado numérico para teléfono

**Prioridad:** P1
**Objetivo:** Verificar que campo de teléfono usa teclado numérico

**Pasos:**
1. Tap en "Agregar Contacto"
2. Tap en campo de teléfono
3. Observar teclado

**Resultado Esperado:**
- ✅ Teclado numérico (phone) aparece
- ✅ Solo permite dígitos, +, espacios, guiones, paréntesis
- ✅ Input formatter previene caracteres inválidos

**Criterios de Aceptación:**
- Facilita entrada de números
- Previene errores de entrada

---

## 📂 CATEGORÍA E: OPEN CHAT BY NAME (VOICE)

**Prerequisitos específicos:** Contactos favoritos guardados, WhatsApp instalado

---

### ✅ TC-WA-020: "Chat de María" abre chat correcto

**Prioridad:** P0
**Objetivo:** Verificar comando de voz para abrir chat específico

**Prerequisitos adicionales:**
- Contacto "María García" guardado con número válido

**Pasos:**
1. En VoiceCommandScreen, mantener presionado botón >200ms
2. Decir: "chat de María"
3. Soltar botón
4. Observar comportamiento

**Resultado Esperado:**
- ✅ TTS anuncia: "Abriendo chat de María García"
- ✅ WhatsApp se abre con chat del número de María
- ✅ **En logs:**
  ```
  [NLPParser] Extracted contact: "maría" from pattern "chat de"
  [VoiceCommandProvider] Opening WhatsApp chat for contact: María García
  ```

**Criterios de Aceptación:**
- Nombre parcial "María" encuentra "María García"
- Chat correcto se abre

---

### ✅ TC-WA-021: Variaciones del comando de chat

**Prioridad:** P0
**Objetivo:** Verificar múltiples patrones de comando

**Prerequisitos adicionales:**
- Contacto "Juan Pérez" guardado

**Pasos:**
1. **Intento 1:** "hablar con Juan"
2. **Intento 2:** "mensaje a Juan"
3. **Intento 3:** "llamar a Juan por WhatsApp"
4. **Intento 4:** "enviar mensaje a Juan"

**Resultado Esperado:**
- ✅ 4/4 variaciones reconocidas
- ✅ Extracción de contacto "Juan" en cada caso
- ✅ Chat de Juan se abre en cada caso
- ✅ **En logs para cada patrón:**
  ```
  [NLPParser] Extracted contact: "juan" from pattern "[pattern]"
  ```

**Criterios de Aceptación:**
- Todos los patrones documentados funcionan
- Extracción de nombre es consistente

---

### ✅ TC-WA-022: Fuzzy matching con acentos

**Prioridad:** P0
**Objetivo:** Verificar que búsqueda ignora acentos

**Prerequisitos adicionales:**
- Contacto "María García" guardado (con tilde)

**Pasos:**
1. Decir: "chat de maria" (sin tilde, pronunciación natural)
2. Observar si encuentra "María García"

**Resultado Esperado:**
- ✅ "maria" encuentra "María García"
- ✅ TTS usa nombre correcto: "Abriendo chat de María García"
- ✅ **En logs:**
  ```
  [ContactStorageService] Exact match found: María García
  ```

**Criterios de Aceptación:**
- Normalización de acentos funciona
- Búsqueda case-insensitive

---

### ✅ TC-WA-023: Contacto no encontrado da feedback

**Prioridad:** P1
**Objetivo:** Verificar mensaje cuando contacto no existe

**Prerequisitos adicionales:**
- Contacto "Pedro" NO guardado

**Pasos:**
1. Decir: "chat de Pedro"
2. Observar comportamiento

**Resultado Esperado:**
- ✅ TTS anuncia: "No encontré a Pedro en tus contactos favoritos. Puedes agregarlo en la pantalla de WhatsApp."
- ✅ WhatsApp NO se abre
- ✅ Estado vuelve a idle
- ✅ **En logs:**
  ```
  [ContactStorageService] No match found for query: "pedro"
  ```

**Criterios de Aceptación:**
- Mensaje es útil (guía a agregar contacto)
- No abre WhatsApp sin contacto válido

---

### ✅ TC-WA-024: Búsqueda parcial encuentra contacto

**Prioridad:** P1
**Objetivo:** Verificar que búsqueda parcial funciona

**Prerequisitos adicionales:**
- Contacto "María García López" guardado

**Pasos:**
1. Decir: "chat de García"
2. Observar si encuentra el contacto

**Resultado Esperado:**
- ✅ "García" encuentra "María García López" (partial match)
- ✅ TTS anuncia nombre completo
- ✅ **En logs:**
  ```
  [ContactStorageService] Partial match found: María García López for query "garcía"
  ```

**Criterios de Aceptación:**
- Búsqueda por apellido funciona
- Prioriza exact match sobre partial match

---

## 📂 CATEGORÍA F: DEEP LINK INTEGRATION

**Prerequisitos específicos:** WhatsApp instalado, contactos guardados

---

### ✅ TC-WA-025: wa.me deep link funciona correctamente

**Prioridad:** P0
**Objetivo:** Verificar que el deep link wa.me abre el chat correcto

**Prerequisitos adicionales:**
- Contacto con número real de WhatsApp guardado
- WhatsApp con sesión activa

**Pasos:**
1. Agregar contacto con número de prueba conocido (ej: tu propio número)
2. Decir: "chat de [nombre del contacto]"
3. Verificar que WhatsApp abre chat con ese número

**Resultado Esperado:**
- ✅ WhatsApp abre directamente en chat con el número
- ✅ Si número no tiene WhatsApp, muestra mensaje de WhatsApp (no error de app)
- ✅ **En logs Kotlin:**
  ```
  D/MainActivity: Opening WhatsApp chat for phone: [número]
  D/MainActivity: WhatsApp chat opened successfully
  ```

**Criterios de Aceptación:**
- Deep link se ejecuta correctamente
- Sin errores de Android Intent

---

### ✅ TC-WA-026: Fallback si wa.me no funciona

**Prioridad:** P1
**Objetivo:** Verificar comportamiento fallback cuando wa.me falla

**Prerequisitos adicionales:**
- Escenario difícil de reproducir (wa.me generalmente funciona)

**Pasos:**
1. (Teórico) Si wa.me no puede resolverse, verificar logs
2. Observar si hay fallback a abrir WhatsApp simple

**Resultado Esperado:**
- ✅ Si wa.me falla, intenta abrir WhatsApp sin número específico
- ✅ **En logs Kotlin:**
  ```
  D/MainActivity: WhatsApp opened (fallback - no wa.me support)
  ```
- ✅ Usuario puede buscar contacto manualmente en WhatsApp

**Criterios de Aceptación:**
- App no crashea si wa.me falla
- Fallback graceful

---

## 📂 CATEGORÍA G: ACCESIBILIDAD (TALKBACK)

**Prerequisitos específicos:** TalkBack activado en dispositivo

---

### ✅ TC-WA-027: WhatsAppScreen navegable con TalkBack

**Prioridad:** P0
**Objetivo:** Verificar que WhatsAppScreen es 100% accesible

**Prerequisitos adicionales:**
- TalkBack activado
- 2+ contactos guardados

**Pasos:**
1. Con TalkBack activo, navegar a WhatsAppScreen
2. Swipe por todos los elementos
3. Verificar anuncios de TalkBack

**Resultado Esperado:**
- ✅ **Título:**
  - Label: "WhatsApp"
  - Header: true
- ✅ **Header "Contactos Favoritos":**
  - Label: "Contactos Favoritos"
  - Header: true
- ✅ **Contador:**
  - Label: "X de 8 contactos"
  - ReadOnly: true
- ✅ **ContactCard:**
  - Label: "Contacto [nombre]"
  - Hint: "Toca dos veces para abrir chat. Mantén presionado para editar."
  - Button: true
- ✅ **Botón "Agregar Contacto":**
  - Label: "Agregar Contacto"
  - Hint: "Toca dos veces para agregar un nuevo contacto favorito"
  - Button: true
- ✅ Navegación fluida entre elementos

**Criterios de Aceptación:**
- 100% navegable sin ver pantalla
- Todos los elementos tienen Semantics
- Hints son descriptivos y útiles

---

### ✅ TC-WA-028: ContactConfigurationScreen navegable con TalkBack

**Prioridad:** P1
**Objetivo:** Verificar que formulario de contacto es accesible

**Pasos:**
1. Con TalkBack activo, navegar a ContactConfigurationScreen
2. Swipe por todos los elementos
3. Ingresar datos usando TalkBack

**Resultado Esperado:**
- ✅ **Campo Nombre:**
  - Label: "Nombre del contacto"
  - Hint: "Escribe el nombre como quieres que aparezca"
  - TextField: true
- ✅ **Campo Teléfono:**
  - Label: "Número de teléfono con código de país"
  - Hint: "Incluye el código de país, por ejemplo más 52 para México"
  - TextField: true
- ✅ **Info box:**
  - ReadOnly: true
  - Contenido leído completamente
- ✅ **Botones:**
  - "Guardar" y "Eliminar" con Semantics completo
- ✅ Errores de validación anunciados por TTS

**Criterios de Aceptación:**
- Formulario completable sin ver pantalla
- Errores comunicados claramente

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Test Cases | Estado |
|---------------|------------|--------|
| Voice to WhatsApp bridge | TC-WA-001, TC-WA-002, TC-WA-003, TC-WA-004 | ✅ Cubierta |
| Contact Storage (Hive) | TC-WA-005, TC-WA-006, TC-WA-007, TC-WA-008, TC-WA-009 | ✅ Cubierta |
| WhatsApp Screen UI | TC-WA-010, TC-WA-011, TC-WA-012, TC-WA-013, TC-WA-014 | ✅ Cubierta |
| Contact Configuration | TC-WA-015, TC-WA-016, TC-WA-017, TC-WA-018, TC-WA-019 | ✅ Cubierta |
| Open Chat by Name (Voice) | TC-WA-020, TC-WA-021, TC-WA-022, TC-WA-023, TC-WA-024 | ✅ Cubierta |
| Deep Link Integration | TC-WA-025, TC-WA-026 | ✅ Cubierta |
| Accesibilidad (TalkBack) | TC-WA-027, TC-WA-028 | ✅ Cubierta |

### **Comandos de Voz Soportados**

| Comando | Variaciones | Test Case | Estado |
|---------|-------------|-----------|--------|
| **Abrir WhatsApp** | "abrir whatsapp", "abre whatsapp", "whatsapp" | TC-WA-001, TC-WA-002 | ✅ Completo |
| **Chat de [nombre]** | "chat de María", "hablar con Juan", "mensaje a Pedro" | TC-WA-020, TC-WA-021 | ✅ Completo |
| **Llamar por WhatsApp** | "llamar a mamá por whatsapp" | TC-WA-021 | ✅ Completo |
| **Enviar mensaje** | "enviar mensaje a [nombre]" | TC-WA-021 | ✅ Completo |

### **Patrones de Extracción de Contacto**

| Patrón | Ejemplo | Estado |
|--------|---------|--------|
| "chat de [nombre]" | "chat de María" | ✅ Implementado |
| "hablar con [nombre]" | "hablar con Juan" | ✅ Implementado |
| "mensaje a [nombre]" | "mensaje a Pedro" | ✅ Implementado |
| "mensaje para [nombre]" | "mensaje para Ana" | ✅ Implementado |
| "llamar a [nombre]" | "llamar a mamá" | ✅ Implementado |
| "enviar mensaje a [nombre]" | "enviar mensaje a Carlos" | ✅ Implementado |
| "contactar a [nombre]" | "contactar a Laura" | ✅ Implementado |
| "escribir a [nombre]" | "escribir a Diego" | ✅ Implementado |

### **Cobertura de Dispositivos**

Ejecutar TODOS los test cases en:
- ✅ **Pixel 4a** (Android 13) - Dispositivo de referencia
- ✅ **Samsung Galaxy** (Android 11+) - Validar compatibilidad One UI
- ✅ **Emulador Android** (API 30) - Testing rápido durante desarrollo
- ⚠️ **Dispositivos gama baja** (2GB RAM) - Verificar performance de Hive

### **Prioridades de Testing**

**P0 (Bloqueantes - Deben pasar antes de release):**
- TC-WA-001, TC-WA-002, TC-WA-003 (Voice to WhatsApp)
- TC-WA-005, TC-WA-006, TC-WA-007, TC-WA-008 (Contact Storage)
- TC-WA-010, TC-WA-011, TC-WA-012, TC-WA-013 (UI)
- TC-WA-015, TC-WA-016, TC-WA-017, TC-WA-018 (Validation)
- TC-WA-020, TC-WA-021, TC-WA-022 (Voice Chat)
- TC-WA-025 (Deep Link)
- TC-WA-027 (Accessibility)

**P1 (Importantes - Pueden ser hotfixed):**
- TC-WA-004 (Edge case - no favorites)
- TC-WA-009 (Edit contact)
- TC-WA-014 (Scroll)
- TC-WA-019 (Keyboard)
- TC-WA-023, TC-WA-024 (Fuzzy matching edge cases)
- TC-WA-026 (Fallback)
- TC-WA-028 (Form accessibility)

### **Métricas de Éxito**

Para considerar la Funcionalidad 5 **PRODUCTION READY**:
- ✅ 100% de test cases P0 pasan en dispositivos de referencia
- ✅ ≥ 80% de test cases P1 pasan
- ✅ Latencia de búsqueda de contacto < 100ms
- ✅ Latencia de apertura de WhatsApp < 2 segundos
- ✅ Tasa de éxito de fuzzy matching ≥ 95%
- ✅ Persistencia de Hive 100% confiable
- ✅ 100% accesible con TalkBack (TC-WA-027, TC-WA-028 pasan)
- ✅ Sin memory leaks después de 10+ operaciones CRUD

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Archivos Creados (Feature 5)**

| Archivo | Propósito |
|---------|-----------|
| `lib/models/contact.dart` | Modelo Hive para contactos |
| `lib/models/contact.g.dart` | Adaptador generado de Hive |
| `lib/services/contact_storage_service.dart` | CRUD operations para Hive |
| `lib/providers/contacts_provider.dart` | State management con ChangeNotifier |
| `lib/screens/whatsapp_screen.dart` | UI de lista de contactos |
| `lib/screens/contact_configuration_screen.dart` | Formulario add/edit |
| `lib/widgets/contact_card.dart` | Widget de contacto accesible |

### **Archivos Modificados (Feature 5)**

| Archivo | Cambios |
|---------|---------|
| `lib/main.dart` | Hive adapter, providers |
| `lib/providers/voice_command_provider.dart` | WhatsApp integration |
| `lib/services/whatsapp_service.dart` | `openChatByPhone()` |
| `lib/utils/nlp_parser.dart` | Contact extraction |
| `android/.../MainActivity.kt` | Deep link handler |
| `lib/screens/voice_command_screen.dart` | Help text, error context |
| `pubspec.yaml` | uuid, hive_generator, build_runner |

### **Limitaciones Conocidas**

1. **Navegación a WhatsAppScreen:**
   - Actualmente no hay botón en UI para navegar a WhatsAppScreen
   - Usuario debe usar navegación manual o futura implementación de menú
   - **Mejora:** Agregar botón en HomeScreen o drawer

2. **Número de WhatsApp no verificado:**
   - App no verifica si el número tiene cuenta de WhatsApp
   - wa.me mostrará error de WhatsApp si número no existe
   - **Mejora:** Futura validación opcional

3. **Sin sincronización con contactos del sistema:**
   - Contactos son manuales (no importados del sistema)
   - **Mejora:** Futuro selector de contactos del sistema

4. **Límite fijo de 8 contactos:**
   - Límite hardcodeado en `ContactStorageService.maxContacts`
   - **Mejora:** Hacer configurable si es necesario

### **Debugging Tips**

**Logs Flutter:**
```bash
# Ver logs de WhatsApp integration
flutter logs | grep -E "WhatsApp|Contact|Hive"

# Ver solo errores
flutter logs | grep "error"

# Ver parsing de contactos
flutter logs | grep "Extracted contact"
```

**Verificar Hive:**
```dart
// Debug: Ver contenido de Hive
final box = Hive.box<Contact>('contacts');
print('Contacts in Hive: ${box.length}');
for (var contact in box.values) {
  print('  - ${contact.name}: ${contact.phoneNumber}');
}
```

**Verificar Deep Link:**
```bash
# Test manual de deep link
adb shell am start -a android.intent.action.VIEW -d "https://wa.me/5255123456"
```

### **Errores Comunes y Soluciones**

| Error | Causa | Solución |
|-------|-------|----------|
| "Contact adapter not registered" | Hive no inicializado correctamente | Verificar `Hive.registerAdapter(ContactAdapter())` en main.dart |
| WhatsApp no abre | WhatsApp no instalado o Intent falla | Verificar instalación, revisar logs Kotlin |
| "No encontré a [nombre]" | Contacto no guardado o typo | Verificar lista de favoritos |
| Contactos no persisten | Hive box no se abre | Verificar `ContactStorageService.init()` |
| Fuzzy match no funciona | Normalización fallando | Verificar `Contact.normalizeString()` |

---

## 🚀 PRÓXIMOS PASOS (Post-Testing)

### **Si todos los P0 pasan:**
1. Agregar navegación a WhatsAppScreen desde UI
2. Implementar comando de voz "abrir contactos" o similar
3. Considerar importación de contactos del sistema
4. Agregar más comandos de WhatsApp (enviar mensaje predefinido, etc.)

### **Si hay fallos:**
1. Documentar fallos específicos en GitHub Issues
2. Priorizar según criticidad (P0 > P1)
3. Reproducir en ambiente controlado
4. Fix + re-test

---

**Versión:** 1.0.0
**Última actualización:** 04 feb 2026
**Autor:** Claude (Feature 5 Implementation)
**Stack:** Flutter + Hive + Provider + ElevenLabs STT + flutter_tts + wa.me Deep Links
**Dependencias nuevas:** uuid, hive_generator, build_runner
