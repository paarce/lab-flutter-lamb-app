# 📋 MANUAL TEST CASES - Funcionalidad 4.1: Voice Command Infrastructure (Core)

**Versión:** 1.2.0
**Funcionalidad:** Sistema de comandos de voz con ElevenLabs STT + flutter_tts
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 20 (15 P0 + 5 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Permisos y Configuración](#-categoría-a-permisos-y-configuración)
- [B. Reconocimiento de Voz (STT)](#-categoría-b-reconocimiento-de-voz-stt)
- [C. Parsing de Comandos](#-categoría-c-parsing-de-comandos)
- [D. Ejecución de Comandos](#-categoría-d-ejecución-de-comandos)
- [E. Timeout y Cancelación](#-categoría-e-timeout-y-cancelación)
- [F. Feedback TTS](#-categoría-f-feedback-tts)
- [G. Accesibilidad (TalkBack)](#-categoría-g-accesibilidad-talkback)
- [H. Mejoras UX del Botón de Voz](#-categoría-h-mejoras-ux-del-botón-de-voz)
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

### **Estado Inicial de la App:**
- ✅ App instalada y ejecutándose
- ✅ Usuario está en `HomeScreen`
- ✅ Botón "Comandos de Voz" visible y habilitado
- ✅ Sin sesiones de voz activas previas
- ✅ Cache limpio (opcional: desinstalar/reinstalar app)

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
flutter run

# Verificar que compila sin errores
# Verificar que HomeScreen se muestra
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
2. Tap en botón "Comandos de Voz"
3. Verificar que `VoiceCommandScreen` se abre sin errores
4. Verificar que se ve:
   - Ícono de micrófono (gris, apagado)
   - Texto "Listo para escuchar"
   - Lista de comandos disponibles
   - Botón "Iniciar Comandos de Voz"

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|--------------------|
| A. Permisos y Configuración | 2 | 2 | 0 | ~10 min |
| B. Reconocimiento de Voz (STT) | 3 | 2 | 1 | ~15 min |
| C. Parsing de Comandos | 4 | 3 | 1 | ~15 min |
| D. Ejecución de Comandos | 3 | 3 | 0 | ~15 min |
| E. Timeout y Cancelación | 2 | 1 | 1 | ~10 min |
| F. Feedback TTS | 1 | 1 | 0 | ~5 min |
| G. Accesibilidad (TalkBack) | 1 | 0 | 1 | ~10 min |
| H. Mejoras UX del Botón de Voz | 4 | 3 | 1 | ~15 min |
| **TOTAL** | **20** | **15** | **5** | **~95 min** |

---

## 📂 CATEGORÍA A: PERMISOS Y CONFIGURACIÓN

**Prerequisitos específicos:** Ninguno adicional

---

### ✅ TC-VOICE-001: Inicio con permiso de micrófono otorgado

**Prioridad:** P0
**Objetivo:** Verificar que la app puede iniciar reconocimiento de voz con permiso ya otorgado

**Prerequisitos adicionales:**
- Permiso de micrófono previamente otorgado
- ElevenLabs API key válida en secrets.dart

**Pasos:**
1. Abrir app en `HomeScreen`
2. Tap en botón "Comandos de Voz"
3. Verificar que se navega a `VoiceCommandScreen`
4. Observar UI inicial:
   - Ícono de micrófono apagado (gris)
   - Texto "Listo para escuchar" (28sp)
   - Lista de comandos disponibles visible
5. Tap en botón "Iniciar Comandos de Voz"

**Resultado Esperado:**
- ✅ Navegación a `VoiceCommandScreen` sin errores
- ✅ Ícono de micrófono cambia a encendido (rojo)
- ✅ Fondo del ícono cambia a rojo semitransparente (animación de 300ms)
- ✅ Texto cambia a "Escuchando..." (en tiempo real)
- ✅ Botones en footer cambian a: "Detener" y "Cancelar" (rojo)
- ✅ **En logs Flutter:**
  ```
  [VoiceCommandProvider] Starting voice command listening
  [ElevenLabsService] Iniciando reconocimiento de voz con ElevenLabs Scribe
  ```
- ✅ Sin errores en consola

**Criterios de Aceptación:**
- Tiempo desde tap hasta inicio de listening < 2 segundos
- Animación del ícono es suave (no glitchy)
- TTS se escucha claramente

---

### ✅ TC-VOICE-002: Permiso de micrófono denegado

**Prioridad:** P0
**Objetivo:** Verificar que la app maneja correctamente cuando el permiso de micrófono está denegado

**Prerequisitos adicionales:**
- Permiso de micrófono NO otorgado (Settings → Apps → Lamb → Permissions → Microphone: Deny)

**Pasos:**
1. Abrir app en `HomeScreen`
2. Tap en botón "Comandos de Voz"
3. Verificar que se navega a `VoiceCommandScreen`
4. Observar si aparece diálogo de solicitud de permiso del sistema
5. **Caso 1:** Denegar permiso en diálogo
6. **Caso 2:** Ya denegado permanentemente

**Resultado Esperado (Caso 1 - Denegar):**
- ✅ Aparece diálogo del sistema: "Allow Lamb to record audio?"
- ✅ Al tocar "Deny", aparece card de error rojo en pantalla
- ✅ Mensaje de error accesible: "Se requiere permiso de micrófono para usar comandos de voz"
- ✅ TTS anuncia: "Permiso de micrófono denegado"
- ✅ Botón "Iniciar Comandos de Voz" permanece habilitado (permite retry)

**Resultado Esperado (Caso 2 - Permanentemente denegado):**
- ✅ NO aparece diálogo del sistema
- ✅ Aparece card de error rojo inmediatamente
- ✅ Botón "Configuración" visible para abrir settings del sistema
- ✅ TTS anuncia error

**Criterios de Aceptación:**
- Error es user-friendly (español simple)
- Usuario puede abrir Settings fácilmente
- No crashea la app

---

## 📂 CATEGORÍA B: RECONOCIMIENTO DE VOZ (STT)

**Prerequisitos específicos:** Permiso de micrófono otorgado, listening iniciado (TC-VOICE-001)

---

### ✅ TC-VOICE-003: Transcripción en tiempo real

**Prioridad:** P0
**Objetivo:** Verificar que el servicio STT de ElevenLabs transcribe correctamente en tiempo real

**Prerequisitos adicionales:**
- Ambiente silencioso
- Hablar claramente al micrófono del dispositivo

**Pasos:**
1. Completar TC-VOICE-001 (iniciar listening)
2. Hablar lentamente: "Solicitar ayuda"
3. Observar transcripción en pantalla en tiempo real
4. Esperar procesamiento del comando

**Resultado Esperado:**
- ✅ Aparece card azul con "Reconociendo:" mientras se habla
- ✅ Transcripción se actualiza en tiempo real palabra por palabra:
  - "Solicitar" → "Solicitar ayuda"
- ✅ Texto de transcripción es grande (28sp) y legible
- ✅ Latencia < 500ms entre hablar y ver transcripción
- ✅ **En logs:**
  ```
  [ElevenLabsService] STT reconocido: Solicitar
  [ElevenLabsService] STT reconocido: Solicitar ayuda
  [VoiceCommandProvider] Transcript received: Solicitar ayuda
  [VoiceCommandProvider] Transcript has 2 words, processing command
  ```
- ✅ Después de 3 palabras ("Solicitar ayuda"), se procesa automáticamente (heurística)

**Criterios de Aceptación:**
- Reconocimiento preciso (palabras correctas)
- Latencia de transcripción < 500ms
- Procesa comando al detectar 3+ palabras

---

### ✅ TC-VOICE-004: Reconocimiento con ruido ambiental moderado

**Prioridad:** P1
**Objetivo:** Verificar que el STT funciona con ruido de fondo moderado

**Prerequisitos adicionales:**
- Ruido ambiental moderado (conversación de fondo, TV bajo volumen)

**Pasos:**
1. Completar TC-VOICE-001
2. Con ruido de fondo presente, hablar claramente: "Abrir WhatsApp"
3. Observar transcripción

**Resultado Esperado:**
- ✅ Transcripción reconoce comando a pesar del ruido
- ✅ Puede haber palabras extra transcitas del ruido de fondo
- ✅ Si se reconoce correctamente: comando se ejecuta
- ✅ Si no se reconoce: TTS anuncia "No entendí el comando"

**Criterios de Aceptación:**
- Tasa de éxito ≥ 70% con ruido moderado
- Feedback claro si falla (no silencio)

---

### ✅ TC-VOICE-005: Múltiples sesiones consecutivas de listening

**Prioridad:** P1
**Objetivo:** Verificar que se pueden iniciar múltiples sesiones de listening consecutivas sin memory leaks

**Pasos:**
1. Completar TC-VOICE-001
2. Hablar comando: "Alto contraste"
3. Esperar ejecución y que vuelva a estado idle
4. Tap en "Iniciar Comandos de Voz" nuevamente
5. Hablar comando: "Abrir WhatsApp"
6. Repetir 3 veces más (total 5 sesiones)

**Resultado Esperado:**
- ✅ Todas las sesiones se inician correctamente
- ✅ No hay degradación de performance
- ✅ Memoria de la app se mantiene estable (verificar en Android Studio Profiler)
- ✅ Cada sesión limpia recursos correctamente

**Criterios de Aceptación:**
- 5/5 sesiones exitosas
- Uso de RAM estable (sin crecimiento progresivo)

---

## 📂 CATEGORÍA C: PARSING DE COMANDOS

**Prerequisitos específicos:** Listening activo, transcripción funcionando

---

### ✅ TC-VOICE-006: Reconocer comando "solicitar ayuda"

**Prioridad:** P0
**Objetivo:** Verificar que el NLPParser reconoce correctamente variaciones del comando de ayuda

**Pasos:**
1. Completar TC-VOICE-001
2. **Intento 1:** Hablar "solicitar ayuda"
3. Observar parsing y ejecución
4. Reiniciar listening (TC-VOICE-001)
5. **Intento 2:** Hablar "necesito ayuda"
6. Reiniciar listening
7. **Intento 3:** Hablar "ayúdame"

**Resultado Esperado (para cada intento):**
- ✅ Transcripción correcta del texto hablado
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.requestHelp
  [VoiceCommandProvider] Executing command: CommandType.requestHelp
  [VoiceCommandProvider] Navigating to RemoteControlHostScreen
  ```
- ✅ TTS anuncia: "Generando código de sesión para ayuda remota"
- ✅ App navega automáticamente a `RemoteControlHostScreen`
- ✅ Se muestra pantalla de control remoto con código de sesión

**Criterios de Aceptación:**
- 3/3 variaciones reconocidas correctamente
- Parsing < 50ms (keywords locales)

---

### ✅ TC-VOICE-007: Reconocer comando "abrir whatsapp"

**Prioridad:** P0
**Objetivo:** Verificar que el NLPParser reconoce comando de WhatsApp

**Prerequisitos adicionales:**
- WhatsApp instalado en el dispositivo (opcional, pero recomendado)

**Pasos:**
1. Completar TC-VOICE-001
2. **Intento 1:** Hablar "abrir whatsapp"
3. Observar parsing
4. Reiniciar listening
5. **Intento 2:** Hablar "abre whatsapp"
6. Reiniciar listening
7. **Intento 3:** Hablar "whatsapp" (solo keyword)

**Resultado Esperado:**
- ✅ 3/3 variaciones reconocidas como `CommandType.openWhatsApp`
- ✅ TTS anuncia: "Abriendo WhatsApp"
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] TODO: Call platform channel to open WhatsApp
  ```
- ✅ (Nota: Platform channel está implementado pero no integrado en provider aún - v1.1)

**Criterios de Aceptación:**
- Reconocimiento exitoso de las 3 variaciones
- Feedback TTS claro

---

### ✅ TC-VOICE-008: Reconocer comando "cancelar"

**Prioridad:** P0
**Objetivo:** Verificar que "cancelar" tiene prioridad alta y detiene listening

**Pasos:**
1. Completar TC-VOICE-001
2. Hablar: "cancelar ayuda" (combinación de 2 comandos)
3. Observar comportamiento

**Resultado Esperado:**
- ✅ NLPParser detecta "cancelar" con prioridad (ignora "ayuda")
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.cancel
  [VoiceCommandProvider] User cancelled listening
  ```
- ✅ Listening se detiene inmediatamente
- ✅ TTS anuncia: "Cancelado"
- ✅ Estado vuelve a idle (ícono apagado, texto "Listo para escuchar")

**Criterios de Aceptación:**
- "Cancelar" siempre tiene prioridad sobre otros keywords
- Listening se detiene en < 500ms

---

### ✅ TC-VOICE-009: Comando no reconocido (unknown)

**Prioridad:** P1
**Objetivo:** Verificar que comandos no reconocidos se manejan correctamente

**Pasos:**
1. Completar TC-VOICE-001
2. Hablar: "xyz random palabras sin sentido"
3. Observar comportamiento

**Resultado Esperado:**
- ✅ Transcripción muestra el texto exacto hablado
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.unknown
  [VoiceCommandProvider] Unknown command: xyz random palabras sin sentido
  ```
- ✅ TTS anuncia: "No entendí el comando. Intenta de nuevo."
- ✅ Estado vuelve a idle
- ✅ Lista de comandos disponibles sigue visible en pantalla

**Criterios de Aceptación:**
- Mensaje de error es user-friendly
- Usuario puede reintentar inmediatamente

---

## 📂 CATEGORÍA D: EJECUCIÓN DE COMANDOS

**Prerequisitos específicos:** Comandos reconocidos exitosamente

---

### ✅ TC-VOICE-010: Comando "solicitar ayuda" ejecuta navegación

**Prioridad:** P0
**Objetivo:** Verificar que el comando "solicitar ayuda" navega correctamente a RemoteControlHostScreen

**Pasos:**
1. Completar TC-VOICE-006 (reconocer "solicitar ayuda")
2. Escuchar mensaje TTS
3. Verificar navegación a RemoteControlHostScreen
4. Verificar logs

**Resultado Esperado:**
- ✅ TTS anuncia claramente: "Generando código de sesión para ayuda remota"
- ✅ Mensaje se escucha completo (no cortado)
- ✅ App navega automáticamente a `RemoteControlHostScreen`
- ✅ Se muestra código de sesión de 6 dígitos
- ✅ Usuario puede volver con botón de back
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Navigating to RemoteControlHostScreen
  [RemoteControlProvider] Creating new session
  ```

**Criterios de Aceptación:**
- TTS claro y comprensible
- Navegación fluida (< 500ms)
- Código de sesión se genera correctamente
- Sin errors en logs

---

### ✅ TC-VOICE-011: Comando "alto contraste" cambia tema

**Prioridad:** P0
**Objetivo:** Verificar que el comando "alto contraste" cambia el tema correctamente

**Pasos:**
1. Completar TC-VOICE-001
2. Observar colores actuales (azul/naranja estándar)
3. Hablar: "alto contraste"
4. Observar cambio de colores
5. Hablar nuevamente: "alto contraste" (toggle)
6. Verificar que vuelve a tema estándar

**Resultado Esperado (primer toggle):**
- ✅ TTS anuncia: "Cambiando a alto contraste"
- ✅ Colores cambian inmediatamente:
  - Botones: Negro sólido (antes azul)
  - Acentos: Amarillo oro (antes naranja)
  - Fondo: Blanco
  - Contraste máximo visible
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Theme toggled to: AppThemeMode.highContrast
  ```

**Resultado Esperado (segundo toggle):**
- ✅ TTS anuncia: "Cambiando a contraste normal"
- ✅ Colores vuelven a tema estándar (azul/naranja)
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Theme toggled to: AppThemeMode.standard
  ```

**Criterios de Aceptación:**
- Cambio de tema instantáneo (sin delay)
- Todos los elementos de UI se actualizan (botones, textos, íconos)
- Toggle funciona en ambas direcciones
- TTS anuncia estado correcto
- Sin errors en logs

---

### ✅ TC-VOICE-012: Platform channel WhatsApp configurado

**Prioridad:** P1
**Objetivo:** Verificar que el platform channel de WhatsApp está configurado (aunque no integrado)

**Prerequisitos adicionales:**
- WhatsApp instalado en dispositivo

**Pasos:**
1. Verificar que `WhatsAppService` existe en código
2. Verificar que `MainActivity.kt` tiene método `openWhatsApp`
3. (Opcional) Ejecutar test unitario si existe

**Resultado Esperado:**
- ✅ Archivo `lib/services/whatsapp_service.dart` existe
- ✅ Método `openWhatsApp()` implementado
- ✅ `MainActivity.kt` tiene handler para `openWhatsApp`
- ✅ **En logs Kotlin (si se ejecuta manualmente):**
  ```
  D/MainActivity: Opening WhatsApp
  D/MainActivity: WhatsApp opened successfully
  ```

**Criterios de Aceptación:**
- Platform channel compilando sin errores
- Método callable (aunque no integrado en provider)

---

## 📂 CATEGORÍA E: TIMEOUT Y CANCELACIÓN

**Prerequisitos específicos:** Listening activo

---

### ✅ TC-VOICE-013: Timeout de 10 segundos sin hablar

**Prioridad:** P0
**Objetivo:** Verificar que el sistema cancela automáticamente si no se habla durante 10 segundos

**Pasos:**
1. Completar TC-VOICE-001 (iniciar listening)
2. NO hablar nada
3. Esperar 10 segundos completos
4. Observar comportamiento

**Resultado Esperado:**
- ✅ A los ~10 segundos, listening se detiene automáticamente
- ✅ TTS anuncia: "Tiempo agotado"
- ✅ Ícono vuelve a estado apagado (gris)
- ✅ Estado cambia a idle
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Voice command timeout
  [VoiceCommandProvider] Handling timeout
  ```

**Criterios de Aceptación:**
- Timeout ocurre en 10 ± 1 segundos
- Cleanup completo (no memory leaks)

---

### ✅ TC-VOICE-014: Timeout se resetea al hablar

**Prioridad:** P1
**Objetivo:** Verificar que el timeout se resetea cada vez que se reconoce una palabra

**Pasos:**
1. Completar TC-VOICE-001
2. Hablar palabra "hola" (no es comando válido)
3. Esperar 5 segundos
4. Hablar palabra "mundo"
5. Esperar 5 segundos
6. Hablar palabra "test"
7. Repetir durante 25 segundos total (con pausas de 5s entre palabras)

**Resultado Esperado:**
- ✅ Listening NO se detiene mientras se habla periódicamente
- ✅ Timer se resetea en cada palabra reconocida
- ✅ Solo se detiene si pasan 10s SIN palabras
- ✅ **En logs:** Se observan múltiples resets del timer

**Criterios de Aceptación:**
- Listening se mantiene activo mientras hay actividad
- Timeout solo ocurre tras 10s de silencio completo

---

## 📂 CATEGORÍA F: FEEDBACK TTS

**Prerequisitos específicos:** TTS service funcionando

---

### ✅ TC-VOICE-015: Feedback TTS para todas las acciones

**Prioridad:** P0
**Objetivo:** Verificar que TODAS las acciones tienen feedback audible via TTS

**Pasos:**
2. **Acción 1:** Comando "solicitar ayuda"
   - Verificar TTS: "Generando código de sesión para ayuda remota"
3. **Acción 2:** Comando "abrir whatsapp"
   - Verificar TTS: "Abriendo WhatsApp"
4. **Acción 3:** Comando "Cambiar contraste" (primera vez)
   - Verificar TTS: "Cambiando a alto contraste"
5. **Acción 3b:** Comando "alto contraste" (segunda vez - toggle)
   - Verificar TTS: "Cambiando a contraste normal"
6. **Acción 4:** Comando "cancelar"
   - Verificar TTS: "Cancelado"
7. **Acción 5:** Comando desconocido
   - Verificar TTS: "No entendí el comando. Intenta de nuevo."
8. **Acción 6:** Timeout
   - Verificar TTS: "Tiempo agotado"

**Resultado Esperado:**
- ✅ 8/8 acciones tienen mensaje TTS correspondiente (incluyendo toggle de alto contraste)
- ✅ Mensajes se escuchan claramente (volumen multimedia > 50%)
- ✅ TTS usa motor nativo (flutter_tts)
- ✅ Idioma: Español (configurado en `TTSConfig.language = 'es-ES'`)
- ✅ Velocidad normal (pitch: 1.0, speed: 1.0)
- ✅ Mensaje de "alto contraste" es dinámico según estado actual del tema

**Criterios de Aceptación:**
- 100% de acciones con feedback TTS
- Audio claro y comprensible
- Latencia TTS < 200ms
- Mensajes dinámicos reflejan estado correcto

---

## 📂 CATEGORÍA G: ACCESIBILIDAD (TALKBACK)

**Prerequisitos específicos:** TalkBack activado en dispositivo

---

### ✅ TC-VOICE-016: Navegación completa con TalkBack

**Prioridad:** P1
**Objetivo:** Verificar que toda la funcionalidad es accesible solo con TalkBack

**Prerequisitos adicionales:**
- TalkBack activado: Settings → Accessibility → TalkBack → ON
- Usuario familiarizado con gestos de TalkBack:
  - Swipe derecha: Siguiente elemento
  - Swipe izquierda: Elemento anterior
  - Doble tap: Activar elemento

**Pasos:**
1. Con TalkBack activo, abrir app
2. En `HomeScreen`, swipe hasta botón "Comandos de Voz"
3. Verificar que TalkBack anuncia: "Comandos de voz, Botón, Toca dos veces para usar comandos de voz"
4. Doble tap para activar
5. En `VoiceCommandScreen`:
   - Swipe por todos los elementos
   - Verificar anuncios de TalkBack
6. Llegar a botón "Iniciar Comandos de Voz"
7. Doble tap para iniciar
8. Hablar comando "solicitar ayuda"
9. Verificar feedback combinado (TalkBack + TTS)

**Resultado Esperado:**
- ✅ **Botón "Comandos de Voz":**
  - Label: "Comandos de voz"
  - Hint: "Toca dos veces para usar comandos de voz"
  - Rol: Botón
- ✅ **Ícono de micrófono:**
  - Label dinámico: "Micrófono apagado" / "Escuchando"
- ✅ **Estado:**
  - Live region: Cambios de estado se anuncian automáticamente
  - "Listo para escuchar" → "Escuchando..." → "Procesando comando..."
- ✅ **Transcripción:**
  - Live region: Texto reconocido se anuncia en tiempo real
- ✅ **Lista de comandos:**
  - Container con label: "Comandos disponibles"
  - Cada comando navegable individualmente
- ✅ **Botones footer:**
  - "Iniciar Comandos de Voz": Semantics completo
  - "Detener" / "Cancelar": Semantics dinámico según estado

**Criterios de Aceptación:**
- 100% navegable sin ver pantalla
- Todos los elementos tienen Semantics
- Live regions funcionan (anuncios automáticos de cambios)
- Feedback TTS no interfiere con TalkBack (se combinan bien)

---

## 📂 CATEGORÍA H: MEJORAS UX DEL BOTÓN DE VOZ

**Prerequisitos específicos:** Botón de comandos de voz funcionando correctamente

---

### ✅ TC-VOICE-017: Ignorar toques mientras TTS habla

**Prioridad:** P0
**Objetivo:** Verificar que el botón ignora toques mientras el TTS está reproduciendo audio

**Prerequisitos adicionales:**
- TTS service funcionando
- Volumen multimedia > 50%

**Pasos:**
1. Abrir `VoiceCommandScreen`
2. Mantener presionado botón de micrófono
3. Decir: "tutorial" (genera TTS largo de ~30 segundos)
4. Mientras el TTS está hablando, intentar presionar el botón de micrófono nuevamente
5. Observar comportamiento

**Resultado Esperado:**
- ✅ Botón permanece visualmente habilitado (NO cambia a gris)
- ✅ Al presionar durante TTS: NO hay feedback háptico
- ✅ Al presionar durante TTS: NO se inicia nueva sesión de escucha
- ✅ TTS continúa reproduciendo sin interrupción
- ✅ **En logs:**
  ```
  [VoiceCommandScreen] Ignoring touch - TTS is speaking
  ```
- ✅ Después de que TTS termina, botón vuelve a funcionar normalmente

**Criterios de Aceptación:**
- 0 interrupciones del TTS por toques accidentales
- Botón NO se ve "deshabilitado" para TalkBack
- Usuario puede tocar múltiples veces sin efectos

---

### ✅ TC-VOICE-018: Duración mínima de presión (200ms)

**Prioridad:** P0
**Objetivo:** Verificar que se requieren 200ms de presión antes de iniciar escucha

**Pasos:**
1. Abrir `VoiceCommandScreen`
2. **Intento 1:** Tocar y soltar rápidamente (<100ms) - "tap accidental"
3. Observar comportamiento
4. **Intento 2:** Mantener presionado exactamente 150ms y soltar
5. Observar comportamiento
6. **Intento 3:** Mantener presionado 250ms (>200ms)
7. Observar que inicia escucha
8. Soltar después de 1 segundo

**Resultado Esperado:**

**Intento 1 y 2 (< 200ms):**
- ✅ Feedback háptico medio (`Haptics.vibrate(HapticsType.medium)`) al presionar
- ✅ NO se inicia escucha (ícono NO cambia a rojo)
- ✅ NO hay consumo de API de ElevenLabs
- ✅ Estado permanece en `idle`
- ✅ NO hay mensaje de error (comportamiento esperado)

**Intento 3 (≥ 200ms):**
- ✅ Feedback háptico medio al presionar (inicial)
- ✅ A los ~200ms: Feedback háptico fuerte (`Haptics.vibrate(HapticsType.heavy)`) - indica "ahora escuchando"
- ✅ Ícono cambia a rojo
- ✅ Transcripción se activa
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Starting voice command listening
  ```
- ✅ Al soltar: Feedback háptico fuerte nuevamente
- ✅ Se procesa el comando
- ✅ **Nota:** Usa paquete `haptic_feedback` para compatibilidad con Samsung

**Criterios de Aceptación:**
- Toques < 200ms NO inician escucha (ahorro de API)
- Feedback háptico es claro y diferenciado
- Timer se cancela correctamente al soltar antes de 200ms

---

### ✅ TC-VOICE-019: Feedback háptico diferenciado

**Prioridad:** P1
**Objetivo:** Verificar que el feedback háptico es adecuado para personas con baja visión

**Prerequisitos adicionales:**
- Dispositivo con motor de vibración funcional

**Pasos:**
1. Abrir `VoiceCommandScreen`
2. Mantener presionado botón >200ms
3. **Momento 1:** Al presionar inicialmente
4. **Momento 2:** A los 200ms (cuando inicia escucha)
5. **Momento 3:** Al soltar botón
6. Repetir 3 veces para validar consistencia

**Resultado Esperado:**
- ✅ **Momento 1 (presionar):**
  - Vibración media (`Haptics.vibrate(HapticsType.medium)`)
  - Indica: "Registré tu toque"
- ✅ **Momento 2 (200ms):**
  - Vibración fuerte (`Haptics.vibrate(HapticsType.heavy)`)
  - Indica: "AHORA estoy escuchando"
- ✅ **Momento 3 (soltar):**
  - Vibración fuerte (`Haptics.vibrate(HapticsType.heavy)`)
  - Indica: "Detuve la escucha"
- ✅ Feedback es consistente en las 3 repeticiones
- ✅ Vibraciones son claramente perceptibles en Samsung y otros dispositivos
- ✅ **Nota:** Usa paquete `haptic_feedback` para mejor compatibilidad con Samsung/OneUI

**Criterios de Aceptación:**
- 3/3 repeticiones con feedback consistente
- Usuario puede distinguir claramente los 3 momentos
- Feedback háptico no interfiere con TalkBack

---

### ✅ TC-VOICE-020: Pantalla permanece activa durante TTS

**Prioridad:** P0
**Objetivo:** Verificar que la pantalla no se apaga durante TTS largo

**Prerequisitos adicionales:**
- Screen timeout del dispositivo configurado en 15 segundos (Settings → Display → Screen timeout → 15 seconds)

**Pasos:**
1. Configurar screen timeout a 15 segundos
2. Abrir `VoiceCommandScreen`
3. Mantener presionado botón >200ms
4. Decir: "comandos disponibles" (genera TTS de ~60 segundos - lista completa)
5. NO tocar el dispositivo durante el TTS
6. Observar si la pantalla se apaga o permanece activa
7. Esperar a que TTS termine completamente
8. Esperar 20 segundos adicionales SIN TTS
9. Observar si ahora sí se apaga

**Resultado Esperado:**
- ✅ Durante TTS (60 segundos):
  - Pantalla permanece encendida TODO el tiempo
  - NO se atenúa ni apaga a los 15 segundos
  - **En logs:**
    ```
    [FlutterTtsService] TTS started - wakelock enabled
    ```
- ✅ Al terminar TTS:
  - **En logs:**
    ```
    [FlutterTtsService] TTS completed - wakelock disabled
    ```
- ✅ Después de terminar TTS (20s adicionales):
  - Pantalla se apaga normalmente según configuración del sistema (15s)
  - Wakelock se desactivó correctamente

**Criterios de Aceptación:**
- Pantalla NUNCA se apaga durante TTS activo
- Wakelock se desactiva automáticamente al terminar TTS
- Wakelock se desactiva también si hay error o cancelación
- Sin memory leaks (wakelock limpiado correctamente)

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Test Cases | Estado |
|---------------|------------|--------|
| Permisos de micrófono | TC-VOICE-001, TC-VOICE-002 | ✅ Cubierta |
| STT (Speech-to-Text) | TC-VOICE-003, TC-VOICE-004, TC-VOICE-005 | ✅ Cubierta |
| Parsing de comandos (NLPParser) | TC-VOICE-006, TC-VOICE-007, TC-VOICE-008, TC-VOICE-009 | ✅ Cubierta |
| Ejecución de comandos (stubs) | TC-VOICE-010, TC-VOICE-011, TC-VOICE-012 | ✅ Cubierta |
| Timeout y cancelación | TC-VOICE-013, TC-VOICE-014 | ✅ Cubierta |
| Feedback TTS | TC-VOICE-015 | ✅ Cubierta |
| Accesibilidad (TalkBack) | TC-VOICE-016 | ✅ Cubierta |
| Mejoras UX del botón de voz | TC-VOICE-017, TC-VOICE-018, TC-VOICE-019, TC-VOICE-020 | ✅ Cubierta |

### **Comandos MVP Soportados**

| Comando | Variaciones | Test Case | Integrado |
|---------|-------------|-----------|-----------|
| **Solicitar ayuda** | "solicitar ayuda", "necesito ayuda", "ayúdame" | TC-VOICE-006, TC-VOICE-010 | ✅ Completo - Navega a RemoteControlHostScreen |
| **Abrir WhatsApp** | "abrir whatsapp", "abre whatsapp", "whatsapp" | TC-VOICE-007 | ⏳ Platform channel listo, integración pendiente (Feature 5) |
| **Alto contraste** | "alto contraste", "activar contraste", "contraste" | TC-VOICE-011 | ✅ Completo - Toggle de tema dinámico |
| **Cancelar** | "cancelar", "detener", "para" | TC-VOICE-008 | ✅ Completo |

### **Cobertura de Dispositivos**

Ejecutar TODOS los test cases en:
- ✅ **Pixel 4a** (Android 13) - Dispositivo de referencia
- ✅ **Samsung Galaxy** (Android 11+) - Validar compatibilidad One UI
- ✅ **Emulador Android** (API 30) - Testing rápido durante desarrollo
- ⚠️ **Dispositivos gama baja** (2GB RAM) - Verificar performance

### **Prioridades de Testing**

**P0 (Bloqueantes - Deben pasar antes de release):**
- TC-VOICE-001, TC-VOICE-002 (Permisos)
- TC-VOICE-003 (STT básico)
- TC-VOICE-006, TC-VOICE-007, TC-VOICE-008 (Parsing core)
- TC-VOICE-010, TC-VOICE-011 (Ejecución de comandos implementados)
- TC-VOICE-013 (Timeout)
- TC-VOICE-015 (Feedback TTS)
- TC-VOICE-017, TC-VOICE-018, TC-VOICE-020 (UX del botón: ignorar toques, 200ms delay, wakelock)

**P1 (Importantes - Pueden ser hotfixed):**
- TC-VOICE-004, TC-VOICE-005 (STT avanzado)
- TC-VOICE-009 (Unknown commands)
- TC-VOICE-012 (Platform channel WhatsApp - pendiente integración)
- TC-VOICE-014 (Timeout reset)
- TC-VOICE-016 (TalkBack)
- TC-VOICE-019 (Feedback háptico diferenciado)

### **Métricas de Éxito**

Para considerar la Funcionalidad 4.1 **PRODUCTION READY**:
- ✅ 100% de test cases P0 pasan en dispositivos de referencia
- ✅ ≥ 80% de test cases P1 pasan
- ✅ Latencia STT < 500ms (transcripción)
- ✅ Latencia TTS < 200ms (feedback)
- ✅ Tasa de éxito parsing ≥ 90% en ambiente silencioso
- ✅ Tasa de éxito parsing ≥ 70% con ruido moderado
- ✅ 100% accesible con TalkBack (TC-VOICE-016 pasa)
- ✅ Sin memory leaks en 5+ sesiones consecutivas

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Limitaciones Conocidas (MVP 4.1)**

1. **Comando "Abrir WhatsApp" pendiente:**
   - Platform channel está implementado en Flutter + Kotlin
   - NO integrado en `VoiceCommandProvider` (pendiente Feature 5)
   - Solo anuncia "Abriendo WhatsApp" sin ejecutar acción
   - **Mejora:** Integrar en Feature 5 (WhatsApp Integration) junto con comandos avanzados

2. **Parser solo usa keywords locales:**
   - No hay fallback a LLM para comandos complejos
   - Ejemplo: "Quiero hablar con María" NO funciona (requiere LLM)
   - **Mejora:** Integrar LLM en 4.4 (v1.1)

3. **UX actual usa pantalla dedicada:**
   - Implementado con `VoiceCommandScreen`
   - Plan: Migrar a FAB + overlay modal (mejor UX)
   - **Mejora:** Refactorización UX pendiente

4. **Sin fallback a Android SpeechRecognizer:**
   - Si ElevenLabs API falla → error, no fallback
   - **Mejora:** Implementar fallback en v1.1

5. **Heurística de 3 palabras puede ser prematura:**
   - Usuario dice "abrir whats..." → puede procesar antes de "app"
   - Mitigación: Transcripción visible + botón cancelar
   - **Mejora:** Detección de fin de frase (1s silencio) en v1.1

### **Debugging Tips**

**Logs Flutter:**
```bash
# Ver todos los logs de comandos de voz
flutter logs | grep -E "VoiceCommand|ElevenLabs|NLPParser|TTSService"

# Ver solo errores
flutter logs | grep "error"

# Ver solo eventos de parsing
flutter logs | grep "Parsed command"
```

**Verificar API Key:**
```dart
// lib/config/secrets.dart
print(Secrets.elevenLabsApiKey); // Verificar que no esté vacía
```

**Verificar TTS:**
```dart
// En VoiceCommandProvider, agregar log temporal
await _ttsService.speak('Test TTS');
print('TTS should be speaking now');
```

**Verificar permiso de micrófono:**
```bash
# En terminal
adb shell pm list permissions -g | grep RECORD_AUDIO
adb shell dumpsys package com.accessibilityapp.lamb | grep RECORD_AUDIO
```

### **Errores Comunes y Soluciones**

| Error | Causa | Solución |
|-------|-------|----------|
| "ElevenLabs API error 401" | API key inválida o expirada | Verificar `secrets.dart`, regenerar key |
| TTS no se escucha | Volumen multimedia en 0 | Subir volumen del dispositivo |
| Transcripción no aparece | ElevenLabs API falla | Verificar conexión a internet, logs |
| "Permiso denegado permanentemente" | Usuario negó 2+ veces | Abrir Settings manualmente |
| Timeout muy rápido | Timer no se resetea | Bug en código, verificar `_resetTimeout()` |

---

## 🚀 PRÓXIMOS PASOS (Post-Testing)

### **Si todos los P0 pasan:**
1. Integrar comandos reales (4.2, 4.3)
2. Refactorizar UX a FAB + overlay
3. Agregar LLM fallback (4.4)
4. Implementar Analytics (4.5)

### **Si hay fallos:**
1. Documentar fallos específicos en GitHub Issues
2. Priorizar según criticidad (P0 > P1)
3. Reproducir en ambiente controlado
4. Fix + re-test

---

**Versión:** 1.2.0
**Última actualización:** 26 ene 2026
**Autor:** Claude (Funcionalidad 4.1 Implementation + TODOs completados + Mejoras UX)
**Stack:** Flutter + ElevenLabs STT + flutter_tts + Provider + ThemeProvider + wakelock_plus + haptic_feedback
**Nueva Categoría:** H. Mejoras UX del Botón de Voz (4 test cases: TC-VOICE-017 a TC-VOICE-020)
