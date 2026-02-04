# 📋 MANUAL TEST CASES - Funcionalidad 4.4: LLM Remote Enhancement

**Versión:** 1.1.0
**Funcionalidad:** Parser híbrido de comandos de voz con fallback a Claude API
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 20 (13 P0 + 7 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Parsing de Lenguaje Natural](#-categoría-a-parsing-de-lenguaje-natural)
- [B. Extracción de Contactos](#-categoría-b-extracción-de-contactos)
- [C. Comportamiento del Cache](#-categoría-c-comportamiento-del-cache)
- [D. Manejo de Errores](#-categoría-d-manejo-de-errores)
- [E. Flujo Híbrido Local → LLM](#-categoría-e-flujo-híbrido-local--llm)
- [F. Performance y Timeout](#-categoría-f-performance-y-timeout)
- [Resumen de Cobertura](#-resumen-de-cobertura)

---

## 🔧 PREREQUISITOS GLOBALES

Estos prerequisitos aplican para **TODOS** los test cases a menos que se indique lo contrario:

### **Configuración del Entorno:**
- ✅ Dispositivo Android 7.0+ (API 24+) físico o emulador
- ✅ Conexión a internet activa (WiFi o datos móviles) - **CRÍTICO para LLM API**
- ✅ ElevenLabs API key válida configurada en `lib/config/secrets.dart`
- ✅ **Claude API key válida configurada en `lib/config/secrets.dart`** (NUEVO)
- ✅ App compilada sin errores: `flutter run`
- ✅ Volumen multimedia del dispositivo > 50%
- ✅ Ambiente silencioso para testing de voz

### **Estado Inicial de la App:**
- ✅ App instalada y ejecutándose
- ✅ Usuario está en `VoiceCommandScreen`
- ✅ Features 4.1, 4.2, 4.3 funcionando correctamente
- ✅ Sin sesiones de voz activas previas
- ✅ Cache LLM vacío (reiniciar app si es necesario)

### **Permisos del Sistema:**
- ✅ Permiso de micrófono otorgado
- ✅ Permiso de internet otorgado (automático)

### **Configuración de API Keys:**

```dart
// lib/config/secrets.dart (DEBE existir)
class Secrets {
  static const String elevenLabsApiKey = 'sk-...'; // Tu key de ElevenLabs
  static const String claudeApiKey = 'sk-ant-...'; // Tu key de Claude
  // ... otros secrets
}
```

**IMPORTANTE:** Si `claudeApiKey` no está configurado o es `'YOUR_CLAUDE_API_KEY_HERE'`, el LLM fallback se deshabilitará gracefully.

### **Comandos Previos Implementados:**
```
✅ Features 4.1-4.3: Todos los comandos de keywords
✅ Parser local funciona correctamente (NLPParser)
✅ TTS configurado y funcionando
```

---

## 🚀 SETUP DE PRUEBAS

### **Configuración de Claude API Key:**

```bash
# 1. Obtener API key de Claude
# Visitar: https://console.anthropic.com/settings/keys
# Crear nueva key o copiar existente

# 2. Configurar en secrets.dart
cd /path/to/lamb
cp lib/config/secrets.example.dart lib/config/secrets.dart
# Editar secrets.dart y pegar tu Claude API key

# 3. Verificar configuración
flutter run
# En logs, buscar:
# [LLMParserService] llamadas (NO debe decir "API key not configured")
```

### **Verificación de Setup:**

1. Abrir app
2. Navegar a `VoiceCommandScreen`
3. Iniciar listening
4. Decir un comando que el parser local NO reconoce: "necesito que alguien me ayude"
5. Verificar en logs:
   ```
   [VoiceCommandProvider] Local parser returned unknown, trying LLM fallback
   [LLMParserService] Calling Claude API for: "necesito que alguien me ayude"
   [LLMParserService] Claude response: {"type": "request_help", "params": null}
   [VoiceCommandProvider] LLM parsed command: CommandType.requestHelp
   ```
6. Si ves estos logs → Setup correcto ✅
7. Si ves "API key not configured" → Revisar secrets.dart ❌

### **Herramientas de Debugging:**

```bash
# Terminal 1 - App
flutter run

# Terminal 2 - Logs filtrados
flutter logs | grep -E "LLMParserService|LLMCommandCache|VoiceCommandProvider"

# Ver solo llamadas LLM
flutter logs | grep "LLMParserService"

# Ver solo cache hits/misses
flutter logs | grep "LLMCommandCache"
```

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Parsing de Lenguaje Natural | 7 | 5 | 2 | ~25 min |
| B. Extracción de Contactos | 3 | 3 | 0 | ~15 min |
| C. Comportamiento del Cache | 3 | 1 | 2 | ~15 min |
| D. Manejo de Errores | 3 | 2 | 1 | ~15 min |
| E. Flujo Híbrido Local → LLM | 2 | 1 | 1 | ~10 min |
| F. Performance y Timeout | 1 | 1 | 0 | ~5 min |
| G. Compartir Pantalla (Screen Sharing) | 1 | 1 | 0 | ~5 min |
| **TOTAL** | **20** | **14** | **6** | **~90 min** |

---

## 📂 CATEGORÍA A: PARSING DE LENGUAJE NATURAL

**Prerequisitos específicos:** Claude API key configurada, internet activo

---

### ✅ TC-LLM-001: Reconocer frase natural "necesito ayuda"

**Prioridad:** P0
**Objetivo:** Verificar que el LLM puede parsear frases naturales a comandos estructurados

**Pasos:**
1. Iniciar listening
2. Hablar claramente: "necesito que alguien me ayude"
3. Soltar botón
4. Observar logs y comportamiento

**Resultado Esperado:**
- ✅ Parser local retorna `unknown`
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Local parser returned unknown, trying LLM fallback
  [LLMCommandCache] Cache MISS: "necesito que alguien me ayude"
  [LLMParserService] Calling Claude API for: "necesito que alguien me ayude"
  [LLMParserService] Claude response: {"type": "request_help", "params": null}
  [LLMParserService] Parsed LLM command: CommandType.requestHelp with params: null
  [LLMCommandCache] Cache PUT: "necesito que alguien me ayude" -> CommandType.requestHelp
  [VoiceCommandProvider] LLM parsed command: CommandType.requestHelp
  ```
- ✅ TTS: Reproduce el tutorial completo de la app
- ✅ Permanece en `VoiceCommandScreen`
- ✅ Tiempo de respuesta < 3 segundos

**Criterios de Aceptación:**
- LLM reconoce frase natural correctamente
- Comando se ejecuta como si fuera reconocido por parser local
- Respuesta en < 3s

---

### ✅ TC-LLM-002: Reconocer variaciones de "ayuda"

**Prioridad:** P0
**Objetivo:** Verificar que el LLM maneja múltiples variaciones de la misma intención

**Pasos:**
1. **Intento 1:** "necesito ayuda urgente"
2. Esperar navegación, volver a VoiceCommandScreen
3. **Intento 2:** "ayúdenme por favor"
4. Volver a VoiceCommandScreen
5. **Intento 3:** "quiero que alguien me asista"
6. Volver a VoiceCommandScreen
7. **Intento 4:** "requiero asistencia"

**Resultado Esperado (cada intento):**
- ✅ LLM reconoce como `CommandType.requestHelp`
- ✅ Comportamiento idéntico: reproduce el tutorial
- ✅ Cache se llena con cada variación única
- ✅ 4/4 variaciones reconocidas correctamente

**Criterios de Aceptación:**
- 100% de variaciones reconocidas como `requestHelp`
- Sin falsos positivos (ej: no reconoce "ayuda" en "ayuda tutorial")
- Cada frase única se cachea

---

### ✅ TC-LLM-003: Reconocer frase natural para contraste

**Prioridad:** P0
**Objetivo:** Verificar parsing de comandos de configuración en lenguaje natural

**Pasos:**
1. Iniciar listening
2. **Intento 1:** "ponme los colores más fuertes"
3. Observar resultado
4. **Intento 2:** "quiero ver mejor los colores"
5. **Intento 3:** "aumenta el contraste de la pantalla"

**Resultado Esperado (cada intento):**
- ✅ LLM reconoce como `CommandType.toggleContrast`
- ✅ **En logs:**
  ```
  [LLMParserService] Claude response: {"type": "toggle_contrast", "params": null}
  [VoiceCommandProvider] LLM parsed command: CommandType.toggleContrast
  ```
- ✅ TTS: "Cambiando a alto contraste" o "Cambiando a contraste normal"
- ✅ Tema de la app cambia visualmente
- ✅ 3/3 variaciones reconocidas

**Criterios de Aceptación:**
- Reconocimiento correcto de intenciones de contraste
- Toggle funciona igual que con parser local
- Sin ambigüedad con otros comandos

---

### ✅ TC-LLM-004: Reconocer frases de volumen natural

**Prioridad:** P0
**Objetivo:** Verificar parsing de comandos de volumen en lenguaje natural

**Pasos:**
1. **Intento 1:** "sube el sonido"
2. **Intento 2:** "baja un poco el volumen"
3. **Intento 3:** "ponlo al máximo"
4. **Intento 4:** "silencia todo"

**Resultado Esperado:**

**Intento 1 - "sube el sonido":**
- ✅ LLM reconoce como `CommandType.adjustVolumeUp`
- ✅ Volumen incrementa
- ✅ TTS: "Volumen al XX por ciento"

**Intento 2 - "baja un poco el volumen":**
- ✅ LLM reconoce como `CommandType.adjustVolumeDown`

**Intento 3 - "ponlo al máximo":**
- ✅ LLM reconoce como `CommandType.setVolumeMax`

**Intento 4 - "silencia todo":**
- ✅ LLM reconoce como `CommandType.setVolumeMin`

**Criterios de Aceptación:**
- 4/4 variaciones reconocidas correctamente
- Volumen se ajusta como esperado
- LLM mapea correctamente cada intención a su CommandType

---

### ✅ TC-LLM-005: Rechazar comandos fuera de scope

**Prioridad:** P1
**Objetivo:** Verificar que el LLM retorna `unknown` para comandos no relacionados con la app

**NOTA:** Desde Feature 4.5, comandos de sistema como "qué hora es", "qué día es hoy", y "cuánta batería tengo" SON comandos válidos y NO deben ser rechazados.

**Pasos:**
1. **Intento 1:** "cuánto es dos más dos"
2. **Intento 2:** "cuéntame un chiste"
3. **Intento 3:** "cómo está el clima"
4. **Intento 4:** "qué hora es en París"

**Resultado Esperado (cada intento):**
- ✅ Parser local retorna `unknown`
- ✅ LLM también retorna `unknown` (o `null`)
- ✅ **En logs:**
  ```
  [LLMParserService] Claude response: {"type": "unknown", "params": null}
  [VoiceCommandProvider] LLM also returned unknown or null
  ```
- ✅ TTS: "No entendí el comando. Intenta de nuevo."
- ✅ NO se cachea (comandos unknown no se cachean)

**Criterios de Aceptación:**
- LLM no inventa comandos que no existen
- Responde `unknown` apropiadamente
- Degradación graceful a mensaje de error
- "qué hora es" SIMPLE se reconoce como getTime (NO rechazado)
- "qué hora es en París" se rechaza (fuera de scope)

---

### ✅ TC-LLM-006: Manejar frases ambiguas

**Prioridad:** P1
**Objetivo:** Verificar comportamiento con frases que podrían interpretarse de múltiples formas

**Pasos:**
1. **Test 1:** "ayuda tutorial" (mixto - dos comandos)
2. **Test 2:** "alto" (incompleto)
3. **Test 3:** "sube" (incompleto)

**Resultado Esperado:**

**Test 1 - "ayuda tutorial":**
- ✅ Parser local puede reconocer por prioridad (playTutorial > requestHelp)
- ✅ Si llega a LLM, debe elegir el más específico (tutorial)
- ✅ Comportamiento consistente con parser local

**Test 2 - "alto":**
- ✅ Parser local puede reconocer "alto" (cancelar)
- ✅ Si llega a LLM, retorna `cancel` o `unknown`

**Test 3 - "sube":**
- ✅ Parser local puede reconocer (volumen)
- ✅ Si llega a LLM, retorna `adjustVolumeUp`

**Criterios de Aceptación:**
- LLM hace elecciones razonables en ambigüedad
- Consistente con prioridades del parser local
- Sin crashes por inputs incompletos

---

### ✅ TC-LLM-006-B: Reconocer "compartir pantalla" en lenguaje natural

**Prioridad:** P0
**Objetivo:** Verificar que el LLM reconoce variaciones de "compartir pantalla" y navega a Remote Control

**Pasos:**
1. **Intento 1:** "quiero compartir mi pantalla"
2. **Intento 2:** "enseñar pantalla"
3. **Intento 3:** "necesito que vean mi pantalla"
4. **Intento 4:** "share screen"

**Resultado Esperado (cada intento):**
- ✅ LLM reconoce como `CommandType.shareScreen`
- ✅ **En logs:**
  ```
  [LLMParserService] Claude response: {"type": "share_screen", "params": null}
  [VoiceCommandProvider] LLM parsed command: CommandType.shareScreen
  ```
- ✅ TTS: "Abriendo control remoto para compartir pantalla"
- ✅ Navega a `RemoteControlHostScreen`
- ✅ 4/4 variaciones reconocidas correctamente

**Criterios de Aceptación:**
- Reconocimiento correcto de intenciones de compartir pantalla
- Diferencia clara con `requestHelp` (tutorial) vs `shareScreen` (control remoto)
- Sin ambigüedad con otros comandos

---

## 📂 CATEGORÍA B: EXTRACCIÓN DE CONTACTOS

**Prerequisitos específicos:** ✅ Feature 5 (WhatsApp Integration) completamente implementada

---

### ✅ TC-LLM-007: Extraer nombre de contacto simple

**Prioridad:** P0
**Objetivo:** Verificar que el LLM extrae correctamente nombres de contactos

**Pasos:**
1. Iniciar listening
2. Hablar: "quiero hablar con María"
3. Observar logs y respuesta

**Resultado Esperado:**
- ✅ Parser local retorna `unknown` (no tiene lógica de contactos)
- ✅ LLM fallback se activa
- ✅ **En logs:**
  ```
  [LLMParserService] Claude response: {"type": "open_chat", "params": {"contact": "maría"}}
  [VoiceCommandProvider] LLM parsed command: CommandType.openWhatsApp with params: {contact: maría}
  ```
- ✅ TTS: "Abriendo chat de María"
- ✅ En logs: "Opening WhatsApp chat for contact: maría"
- ✅ Parámetro `contact` extraído correctamente

**Criterios de Aceptación:**
- Nombre extraído en lowercase normalizado
- Parámetro `contact` presente en `command.parameters`
- TTS anuncia el contacto correcto

---

### ✅ TC-LLM-008: Extraer nombres compuestos y con relaciones

**Prioridad:** P0
**Objetivo:** Verificar extracción de nombres compuestos y contexto familiar

**Pasos:**
1. **Intento 1:** "quiero hablar con mi hija María"
2. **Intento 2:** "llama a mi nieto Juan Carlos"
3. **Intento 3:** "abre el chat de Pedro García"
4. **Intento 4:** "escríbele a la doctora Rodríguez"

**Resultado Esperado:**

**Intento 1 - "mi hija María":**
- ✅ Extrae: `{"contact": "maría"}`
- ✅ TTS: "Abriendo chat de maría"

**Intento 2 - "mi nieto Juan Carlos":**
- ✅ Extrae: `{"contact": "juan carlos"}`
- ✅ TTS: "Abriendo chat de juan carlos"

**Intento 3 - "Pedro García":**
- ✅ Extrae: `{"contact": "pedro garcía"}`

**Intento 4 - "doctora Rodríguez":**
- ✅ Extrae: `{"contact": "rodríguez"}` o `{"contact": "doctora rodríguez"}`
- ✅ Acepta cualquiera (LLM elige razonablemente)

**Criterios de Aceptación:**
- 4/4 nombres extraídos
- LLM filtra palabras de contexto ("mi hija", "mi nieto")
- Nombres compuestos preservados
- Normalización a lowercase consistente

---

### ✅ TC-LLM-009: Manejar comandos de comunicación sin nombre

**Prioridad:** P0
**Objetivo:** Verificar comportamiento cuando se menciona "hablar" pero sin contacto específico

**Pasos:**
1. **Intento 1:** "quiero hablar con alguien"
2. **Intento 2:** "necesito llamar"
3. **Intento 3:** "abre WhatsApp"

**Resultado Esperado:**

**Intento 1 - "hablar con alguien":**
- ✅ LLM podría reconocer como:
  - `open_chat` sin params (aceptable)
  - `unknown` (también aceptable - no es específico)

**Intento 2 - "necesito llamar":**
- ✅ Similar a Intento 1

**Intento 3 - "abre WhatsApp":**
- ✅ **Parser local** debe reconocer esto (keyword "whatsapp")
- ✅ NO debe llegar a LLM
- ✅ `CommandType.openWhatsApp` sin parámetro contact

**Criterios de Aceptación:**
- LLM hace elecciones razonables
- Si no hay contacto específico, `params` puede ser null
- Parser local tiene prioridad cuando puede reconocer

---

## 📂 CATEGORÍA C: COMPORTAMIENTO DEL CACHE

**Prerequisitos específicos:** App recién iniciada (cache vacío)

---

### ✅ TC-LLM-010: Cache hit en segunda ejecución

**Prioridad:** P0
**Objetivo:** Verificar que comandos exitosos se cachean y retornan instantáneamente

**Pasos:**
1. **Primera ejecución:**
   - Hablar: "necesito que alguien me ayude"
   - Cronometrar tiempo de respuesta
   - Anotar tiempo (T1)

2. **Segunda ejecución (inmediata):**
   - Hablar EXACTAMENTE lo mismo: "necesito que alguien me ayude"
   - Cronometrar tiempo de respuesta
   - Anotar tiempo (T2)

3. Comparar T1 vs T2

**Resultado Esperado:**

**Primera ejecución:**
- ✅ **En logs:**
  ```
  [LLMCommandCache] Cache MISS: "necesito que alguien me ayude"
  [LLMParserService] Calling Claude API for: "necesito que alguien me ayude"
  [LLMCommandCache] Cache PUT: "necesito que alguien me ayude" -> CommandType.requestHelp
  ```
- ✅ T1 ≈ 300-3000ms (depende de latencia API)

**Segunda ejecución:**
- ✅ **En logs:**
  ```
  [LLMCommandCache] Cache HIT: "necesito que alguien me ayude" -> CommandType.requestHelp
  ```
- ✅ NO hay llamada a Claude API
- ✅ T2 < 50ms (instantáneo desde cache)
- ✅ T2 << T1 (al menos 10x más rápido)

**Criterios de Aceptación:**
- Cache hit funciona correctamente
- Reducción dramática de latencia en cache hit
- No hay llamada redundante a API

---

### ✅ TC-LLM-011: Cache normaliza keys (mayúsculas/espacios)

**Prioridad:** P1
**Objetivo:** Verificar que el cache normaliza transcripts antes de comparar

**Pasos:**
1. **Ejecución 1:** "necesito ayuda"
2. **Ejecución 2:** "NECESITO AYUDA" (todo mayúsculas)
3. **Ejecución 3:** "  necesito   ayuda  " (espacios extra)

**Resultado Esperado:**

**Ejecución 1:**
- ✅ Cache MISS
- ✅ Llamada a LLM
- ✅ Cache PUT con key normalizada: "necesito ayuda"

**Ejecución 2:**
- ✅ Cache HIT (normaliza a lowercase)
- ✅ **En logs:** Cache HIT: "necesito ayuda"
- ✅ NO llamada a LLM

**Ejecución 3:**
- ✅ Cache HIT (normaliza espacios)
- ✅ **En logs:** Cache HIT: "necesito ayuda"
- ✅ NO llamada a LLM

**Criterios de Aceptación:**
- Cache normaliza lowercase
- Cache normaliza espacios múltiples a uno solo
- 3 transcripts diferentes → 1 cache entry

---

### ✅ TC-LLM-012: Cache expira después de TTL (5 minutos)

**Prioridad:** P1
**Objetivo:** Verificar que entradas de cache expiran después de 5 minutos

**Pasos:**
1. Hablar: "necesito ayuda"
2. Verificar cache PUT en logs
3. Anotar hora exacta (T_start)
4. Esperar 5 minutos y 10 segundos
5. Hablar exactamente lo mismo: "necesito ayuda"
6. Observar logs

**Resultado Esperado:**

**Después de 5+ minutos:**
- ✅ **En logs:**
  ```
  [LLMCommandCache] Cache EXPIRED: "necesito ayuda"
  [LLMCommandCache] Cache MISS: "necesito ayuda"
  [LLMParserService] Calling Claude API...
  ```
- ✅ Nueva llamada a LLM (cache expirado)
- ✅ Nuevo cache PUT

**Criterios de Aceptación:**
- Cache expira después de TTL (5 minutos)
- Entrada expirada se elimina automáticamente
- Nueva llamada se hace correctamente

**Nota:** Este test case toma 5+ minutos. Considerar reducir TTL temporalmente para testing:

```dart
// Para testing rápido (modificar temporalmente)
static const Duration _defaultTTL = Duration(seconds: 30);
```

---

## 📂 CATEGORÍA D: MANEJO DE ERRORES

**Prerequisitos específicos:** Capacidad de simular errores (desconectar internet, API key inválida)

---

### ✅ TC-LLM-013: Manejo de timeout (3 segundos)

**Prioridad:** P0
**Objetivo:** Verificar que llamadas LLM tienen timeout y degradan gracefully

**Setup:**
- Simular conexión lenta usando proxy o throttling de red
- Android: Developer Options → Simulate slow network
- O desactivar WiFi temporalmente después de enviar request

**Pasos:**
1. Configurar red lenta (ej: 2G mode)
2. Hablar: "necesito ayuda urgente"
3. Esperar y observar comportamiento
4. Cronometrar tiempo total

**Resultado Esperado:**
- ✅ LLM intenta llamada
- ✅ Después de 3 segundos, timeout automático
- ✅ **En logs:**
  ```
  [LLMParserService] Claude API timeout after 3s
  [VoiceCommandProvider] LLM also returned unknown or null
  ```
- ✅ TTS: "No entendí el comando. Intenta de nuevo."
- ✅ Estado vuelve a idle
- ✅ Tiempo total ≤ 3.5 segundos (timeout + overhead)
- ✅ App NO se congela

**Criterios de Aceptación:**
- Timeout funciona correctamente (3s exactos)
- Degradación graceful a "unknown"
- No crashes ni UI freezing
- Usuario recibe feedback comprensible

---

### ✅ TC-LLM-014: Manejo de API key inválida

**Prioridad:** P0
**Objetivo:** Verificar que API key inválida se maneja gracefully

**Setup:**
```dart
// Temporalmente en secrets.dart
static const String claudeApiKey = 'sk-ant-INVALID_KEY_123';
```

**Pasos:**
1. Modificar `claudeApiKey` a valor inválido
2. Hot restart app
3. Hablar: "necesito ayuda"
4. Observar logs y comportamiento

**Resultado Esperado:**
- ✅ LLM intenta llamada
- ✅ **En logs:**
  ```
  [LLMParserService] Claude API error: 401 - Invalid API key
  ```
- ✅ Retorna `null` (no lanza excepción)
- ✅ Cae a parser local result (`unknown`)
- ✅ TTS: "No entendí el comando. Intenta de nuevo."
- ✅ App continúa funcionando normalmente

**Criterios de Aceptación:**
- Error 401 manejado gracefully
- No crashes
- Usuario no ve error técnico
- Degradación a parser local

**Post-test:** Restaurar API key válida

---

### ✅ TC-LLM-015: Manejo de rate limiting (429)

**Prioridad:** P1
**Objetivo:** Verificar comportamiento cuando se excede rate limit de Claude API

**Setup:**
- Difícil de simular sin hacer muchas llamadas reales
- Alternativa: Modificar temporalmente código para simular 429

**Pasos:**
1. Si se puede simular: Hacer ~20 llamadas consecutivas rápidas
2. O modificar código temporalmente para retornar 429
3. Observar logs

**Resultado Esperado:**
- ✅ **En logs:**
  ```
  [LLMParserService] Claude API rate limit exceeded
  ```
- ✅ Retorna `null` gracefully
- ✅ TTS: "No entendí el comando. Intenta de nuevo."
- ✅ No hay retry automático (degradación inmediata)

**Criterios de Aceptación:**
- Rate limit detectado correctamente
- Sin retry loops infinitos
- Degradación graceful

**Nota:** Este test puede omitirse si es difícil de simular

---

## 📂 CATEGORÍA E: FLUJO HÍBRIDO LOCAL → LLM

**Prerequisitos específicos:** Parser local funcionando, LLM configurado

---

### ✅ TC-LLM-016: Parser local tiene prioridad

**Prioridad:** P0
**Objetivo:** Verificar que comandos reconocidos por parser local NO van a LLM

**Pasos:**
1. Limpiar logs
2. Hablar: "solicitar ayuda" (keyword exacta del parser local)
3. Observar logs cuidadosamente

**Resultado Esperado:**
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Local parser result: CommandType.requestHelp
  ```
- ✅ **NO debe aparecer en logs:**
  - "trying LLM fallback"
  - "Calling Claude API"
  - "Cache MISS" o "Cache HIT"
- ✅ Comando se ejecuta inmediatamente (<100ms)
- ✅ TTS: "Generando código de sesión para ayuda remota"
- ✅ Navega a RemoteControlHostScreen

**Criterios de Aceptación:**
- Parser local tiene prioridad absoluta
- LLM NO se llama cuando parser local reconoce
- Latencia mínima (sin overhead de LLM)
- Costo de API: $0.00 (no hay llamada)

---

### ✅ TC-LLM-017: Fallback solo en unknown

**Prioridad:** P1
**Objetivo:** Verificar que LLM solo se activa cuando parser local retorna `unknown`

**Pasos:**
1. **Test A - Comando reconocido:** "alto contraste"
2. **Test B - Comando NO reconocido:** "ponme los colores fuertes"

**Resultado Esperado:**

**Test A - Reconocido localmente:**
- ✅ Parser local reconoce
- ✅ NO llama LLM
- ✅ Ejecución inmediata

**Test B - NO reconocido localmente:**
- ✅ Parser local retorna `unknown`
- ✅ **En logs:** "trying LLM fallback"
- ✅ LLM se llama
- ✅ LLM reconoce como `toggleContrast`

**Criterios de Aceptación:**
- LLM solo para unknown
- Optimización de costos (no llamar LLM innecesariamente)
- Comportamiento consistente

---

## 📂 CATEGORÍA F: PERFORMANCE Y TIMEOUT

**Prerequisitos específicos:** Conexión internet estable

---

### ✅ TC-LLM-018: Latencia LLM < 3 segundos

**Prioridad:** P0
**Objetivo:** Verificar que llamadas LLM son suficientemente rápidas para UX aceptable

**Pasos:**
1. Limpiar cache (reiniciar app)
2. Cronometrar 5 comandos diferentes:
   - "necesito ayuda"
   - "quiero hablar con María"
   - "ponme los colores más fuertes"
   - "sube el sonido"
   - "ayúdenme por favor"
3. Anotar tiempo desde "soltar botón" hasta inicio de TTS feedback
4. Calcular promedio

**Resultado Esperado:**
- ✅ Latencia promedio: 300-1500ms (depende de red)
- ✅ Latencia máxima: < 3000ms (timeout)
- ✅ 5/5 comandos reconocidos exitosamente
- ✅ **En logs:** Timestamp entre "Calling Claude API" y "Parsed LLM command"

**Criterios de Aceptación:**
- Latencia promedio < 1.5s (buena experiencia)
- Ningún timeout (todos bajo 3s)
- UX aceptable para usuarios 60+

**Nota:** Latencia real depende de:
- Velocidad de internet del usuario
- Latencia a servidores de Claude API
- Carga de la API de Anthropic

---

## 📂 CATEGORÍA G: COMPARTIR PANTALLA (SCREEN SHARING)

**Prerequisitos específicos:** Feature de Remote Control implementada (Features 2.x)

---

### ✅ TC-LLM-019: Diferenciar "ayuda" vs "compartir pantalla"

**Prioridad:** P0
**Objetivo:** Verificar que el LLM distingue correctamente entre solicitar ayuda genérica (tutorial) y compartir pantalla (control remoto)

**Pasos:**
1. **Test A - Ayuda genérica:**
   - Hablar: "necesito ayuda"
   - Observar resultado

2. **Test B - Compartir pantalla:**
   - Hablar: "quiero compartir mi pantalla"
   - Observar resultado

3. **Test C - Control remoto:**
   - Hablar: "necesito control remoto"
   - Observar resultado

4. **Test D - Mostrar pantalla:**
   - Hablar: "mostrar pantalla"
   - Observar resultado

**Resultado Esperado:**

**Test A - "necesito ayuda":**
- ✅ LLM reconoce como `CommandType.requestHelp`
- ✅ TTS: Reproduce el tutorial completo
- ✅ Permanece en `VoiceCommandScreen`

**Test B - "quiero compartir mi pantalla":**
- ✅ LLM reconoce como `CommandType.shareScreen`
- ✅ TTS: "Abriendo control remoto para compartir pantalla"
- ✅ Navega a `RemoteControlHostScreen`

**Test C - "necesito control remoto":**
- ✅ LLM reconoce como `CommandType.shareScreen`
- ✅ Comportamiento idéntico a Test B

**Test D - "mostrar pantalla":**
- ✅ LLM reconoce como `CommandType.shareScreen`
- ✅ Comportamiento idéntico a Test B

**Criterios de Aceptación:**
- LLM diferencia claramente entre los dos comandos
- "ayuda" genérica → tutorial (no navegación)
- "compartir/mostrar/enseñar pantalla" → navegación a Remote Control
- Sin confusión entre ambos conceptos
- 4/4 tests reconocidos correctamente

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Test Cases | Estado |
|---------------|------------|--------|
| Parsing de lenguaje natural | TC-LLM-001 a TC-LLM-006 | ✅ Cubierta |
| Extracción de contactos | TC-LLM-007 a TC-LLM-009 | ✅ Cubierta |
| Comportamiento del cache | TC-LLM-010 a TC-LLM-012 | ✅ Cubierta |
| Manejo de errores | TC-LLM-013 a TC-LLM-015 | ✅ Cubierta |
| Flujo híbrido local → LLM | TC-LLM-016, TC-LLM-017 | ✅ Cubierta |
| Performance y timeout | TC-LLM-018 | ✅ Cubierta |

### **Variaciones de Comandos Testeadas**

| Comando | Variaciones Naturales | Test Case | Estado |
|---------|----------------------|-----------|--------|
| **Request Help** | "necesito ayuda", "ayúdenme", "requiero asistencia" | TC-LLM-001, TC-LLM-002 | ✅ Implementado |
| **Share Screen** | "compartir pantalla", "mostrar pantalla", "share screen" | TC-LLM-006-B, TC-LLM-019 | ✅ Implementado |
| **Toggle Contrast** | "ponme colores fuertes", "aumenta contraste" | TC-LLM-003 | ✅ Implementado |
| **Volume** | "sube el sonido", "baja un poco", "máximo", "silencia" | TC-LLM-004 | ✅ Implementado |
| **Open WhatsApp** | "hablar con María", "llama a Juan", "escríbele a Pedro" | TC-LLM-007, TC-LLM-008 | ✅ Implementado |
| **Get Time** (4.5) | "qué hora es", "dime la hora", "qué hora" | Ver FUNCIONALIDAD_4.5 | ✅ Implementado |
| **Get Date** (4.5) | "qué día es hoy", "fecha de hoy", "fecha" | Ver FUNCIONALIDAD_4.5 | ✅ Implementado |
| **Get Battery** (4.5) | "cuánta batería", "nivel de batería", "pila" | Ver FUNCIONALIDAD_4.5 | ✅ Implementado |
| **Thank You** (4.5) | "gracias", "muchas gracias", "te agradezco" | Ver FUNCIONALIDAD_4.5 | ✅ Implementado |
| **Goodbye** (4.5) | "adiós", "chau", "hasta luego" | Ver FUNCIONALIDAD_4.5 | ✅ Implementado |

### **Casos Edge Testeados**

- ✅ Comandos fuera de scope (TC-LLM-005)
- ✅ Frases ambiguas (TC-LLM-006)
- ✅ Comandos sin contacto específico (TC-LLM-009)
- ✅ Normalización de cache (TC-LLM-011)
- ✅ API key inválida (TC-LLM-014)
- ✅ Timeout de red (TC-LLM-013)

### **Métricas de Performance**

| Métrica | Objetivo | Test Case |
|---------|----------|-----------|
| **Latencia LLM promedio** | < 1.5s | TC-LLM-018 |
| **Latencia cache hit** | < 50ms | TC-LLM-010 |
| **Timeout máximo** | 3s exactos | TC-LLM-013 |
| **Cache hit rate** | > 30% (uso real) | TC-LLM-010 |
| **Tasa de éxito parsing** | > 90% | TC-LLM-001 a TC-LLM-009 |

### **Costos Estimados (Claude API)**

**Modelo:** Claude 3 Haiku
**Pricing:**
- Input: ~$0.25 / 1M tokens
- Output: ~$1.25 / 1M tokens

**Por request promedio:**
- Input: ~200 tokens (system prompt + user message)
- Output: ~50 tokens (JSON response)
- **Costo:** ~$0.0001 (0.01 centavos USD)

**Estimación mensual (1000 usuarios activos):**
- 20% de comandos van a LLM (parser local cubre 80%)
- Promedio 10 comandos/usuario/día
- 1000 usuarios × 10 comandos/día × 0.2 × 30 días = 60,000 llamadas/mes
- **Costo mensual:** ~$6.00 USD

**Nota:** Cache reduce costos significativamente (50-70% menos llamadas)

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Decisiones de Diseño**

1. **Claude 3 Haiku vs Sonnet:**
   - Implementado con **Haiku** (más rápido y económico)
   - Latencia: ~300-500ms promedio
   - Precisión: Suficiente para extracción estructurada
   - **Alternativa futura:** Sonnet para mejor precisión en edge cases

2. **Cache TTL de 5 minutos:**
   - Balance entre freshness y performance
   - Usuario típico repite comandos en sesión corta
   - Evita memory leaks con evicción FIFO
   - **Mejora futura:** Persistir cache en Hive para sesiones

3. **Timeout de 3 segundos:**
   - Balance entre esperar respuesta y UX
   - Usuario 60+ puede perder paciencia después de 3s
   - Degradación graceful a "No entendí"
   - **Alternativa:** Feedback progresivo ("Procesando...")

4. **System Prompt en español:**
   - Optimizado para público objetivo español-hablante
   - Ejemplos específicos de la app
   - Instrucciones claras de formato JSON
   - **Mejora futura:** Multilingüe con detección automática

### **Limitaciones Conocidas**

1. **Dependencia de internet:**
   - LLM fallback NO funciona offline
   - Parser local continúa funcionando offline
   - **Solución:** Educación de usuario sobre comandos locales

2. **Latencia variable:**
   - Depende de velocidad de internet del usuario
   - Puede variar entre 300ms y 3s
   - **Mitigación:** Cache reduce latencia en repeticiones

3. **Costos escalables:**
   - Cada llamada LLM tiene costo (pequeño pero acumulativo)
   - Sin cache, 1M usuarios → ~$6000/mes
   - **Mitigación:** Cache agresivo, parser local prioritario

4. **Privacidad de transcripts:**
   - Transcripts se envían a Claude API
   - Política de privacidad de Anthropic aplica
   - **Solución:** Declarar en política de privacidad de la app

5. **Nombres de contactos:**
   - LLM normaliza a lowercase
   - Puede perder capitalización original
   - **Workaround:** WhatsApp busca case-insensitive

### **Debugging Tips**

**Ver flujo completo de un comando:**
```bash
# Terminal con logs filtrados
flutter logs | grep -E "VoiceCommandProvider|LLMParserService|LLMCommandCache"

# Ejemplo de output esperado:
# [VoiceCommandProvider] Processing transcript: necesito ayuda
# [VoiceCommandProvider] Local parser result: CommandType.unknown
# [VoiceCommandProvider] Local parser returned unknown, trying LLM fallback
# [LLMCommandCache] Cache MISS: "necesito ayuda"
# [LLMParserService] Calling Claude API for: "necesito ayuda"
# [LLMParserService] Claude response: {"type": "request_help", "params": null}
# [LLMParserService] Parsed LLM command: CommandType.requestHelp with params: null
# [LLMCommandCache] Cache PUT: "necesito ayuda" -> CommandType.requestHelp
# [VoiceCommandProvider] LLM parsed command: CommandType.requestHelp
```

**Ver solo cache activity:**
```bash
flutter logs | grep "LLMCommandCache"
```

**Verificar API calls:**
```bash
flutter logs | grep "Calling Claude API"
```

**Medir latencia manualmente:**
```bash
# En logs, buscar timestamps:
# [timestamp1] Calling Claude API
# [timestamp2] Parsed LLM command
# Latencia = timestamp2 - timestamp1
```

### **Errores Comunes y Soluciones**

| Error | Causa | Solución |
|-------|-------|----------|
| "API key not configured" | Claude API key faltante o inválida | Verificar `secrets.dart` |
| "Claude API timeout" | Internet lento o servidor sobrecargado | Esperar o verificar conexión |
| "Claude API error: 401" | API key inválida | Regenerar key en console.anthropic.com |
| "Claude API error: 429" | Rate limit excedido | Esperar 1 minuto, reduce frecuencia |
| Cache no funciona | Cache se limpia en cada restart | Normal, cache es en memoria (no persistente) |
| LLM siempre retorna unknown | System prompt no llegó correctamente | Verificar código de LLMParserService |
| Latencia muy alta (>5s) | Internet muy lento | Reducir timeout o advertir al usuario |

---

## 🚀 PRÓXIMOS PASOS (Post-Testing)

### **Si todos los P0 pasan:**
1. ✅ Feature 4.4 completada
2. Documentar costos reales de API en producción
3. Considerar mejoras:
   - Persistencia de cache en Hive
   - Feedback progresivo durante llamada LLM
   - A/B testing Haiku vs Sonnet

### **Si hay fallos:**
1. Documentar fallos específicos
2. Priorizar según criticidad (P0 > P1)
3. Fix + re-test
4. Considerar degradación:
   - ¿Funciona sin LLM? (parser local solo)
   - ¿Alternativas al timeout?

### **Mejoras Futuras (v1.1+):**
- [ ] Persistencia de cache entre sesiones (Hive)
- [ ] Feedback progresivo: "Procesando tu comando..." durante llamada LLM
- [ ] Analytics de precisión: ¿Qué tan bien reconoce el LLM?
- [ ] Logs de comandos no reconocidos para mejorar parser local
- [ ] Fallback a Sonnet si Haiku falla repetidamente
- [ ] Compresión de system prompt para reducir tokens
- [ ] Multilingüe: Detección automática de idioma

---

## 📋 CHECKLIST DE RELEASE

Antes de considerar Feature 4.4 completa:

**Código:**
- [ ] `lib/services/llm_command_cache.dart` implementado con TTL 5 min
- [ ] `lib/services/llm_parser_service.dart` implementado con Claude 3 Haiku
- [ ] `lib/providers/voice_command_provider.dart` integra flujo híbrido
- [ ] `lib/config/secrets.example.dart` incluye `claudeApiKey`
- [ ] `lib/errors/error_codes.dart` incluye códigos LLM
- [ ] `lib/errors/error_category.dart` incluye categoría `llm`
- [ ] `lib/utils/error_messages.dart` incluye mensajes LLM

**Testing:**
- [ ] 100% test cases P0 pasan (12/12)
- [ ] ≥ 80% test cases P1 pasan (≥5/6)
- [ ] Testing manual con frases naturales completado
- [ ] Testing de extracción de contactos completado
- [ ] Testing de performance (latencia < 3s) completado

**Documentación:**
- [ ] Este archivo actualizado con resultados de testing
- [ ] Logs de testing guardados
- [ ] Costos estimados de API documentados
- [ ] Política de privacidad actualizada (transcripts a Claude API)

**Configuración:**
- [ ] Claude API key válida en `secrets.dart` (no commitear)
- [ ] Firebase y ElevenLabs funcionando (features previas)

**Git:**
- [ ] Commit creado con mensaje descriptivo
- [ ] Branch actualizado
- [ ] Sin conflictos con main

---

## 🔒 SEGURIDAD Y PRIVACIDAD

### **Datos Enviados a Claude API**

**Qué se envía:**
- Transcripción de voz del usuario (texto)
- System prompt (estático, sin datos personales)

**Qué NO se envía:**
- Audio crudo
- Datos de contactos reales
- Información del dispositivo
- Logs de la app

**Ejemplo de request:**
```json
{
  "model": "claude-3-haiku-20240307",
  "system": "Eres un asistente...",
  "messages": [
    {"role": "user", "content": "quiero hablar con maría"}
  ]
}
```

### **Política de Privacidad de Anthropic**

- Transcripts pueden ser retenidos temporalmente para mejorar el modelo
- No se venden datos a terceros
- Datos encriptados en tránsito (HTTPS)
- Ver: https://www.anthropic.com/privacy

### **Recomendaciones para Producción**

1. **Declaración en Privacy Policy de la app:**
   ```
   Esta aplicación utiliza Claude API (Anthropic) para mejorar
   el reconocimiento de comandos de voz. Los comandos de voz
   que no reconocemos localmente se envían a Claude para procesamiento.

   No enviamos información personal identificable, solo el texto
   de tu comando de voz. Ver política de privacidad de Anthropic:
   https://www.anthropic.com/privacy
   ```

2. **Opt-out opcional:**
   - Permitir al usuario deshabilitar LLM fallback
   - Setting: "Usar solo reconocimiento local"
   - Degradación: Solo keywords funcionan

3. **Rate limiting del cliente:**
   - Máximo X llamadas por usuario/día
   - Protección contra abuse

---

**Versión:** 1.2.0
**Fecha de creación:** 23 ene 2026
**Última actualización:** 26 ene 2026
**Autor:** Claude (Feature 4.4 Implementation + Screen Sharing + Feature 4.5 alignment)
**Stack:** Flutter + Claude 3 Haiku + ElevenLabs STT + flutter_tts + Provider + NLPParser
**Comandos totales:** 16 (Feature 4.3 + shareScreen + 6 comandos Feature 4.5)
**Costo estimado:** ~$0.0001 por comando LLM (~$6/mes para 1000 usuarios activos)

**Nota:** Los comandos de Feature 4.5 (sistema, social, conversación rechazada) son parseados localmente por NLPParser. El LLM fallback los reconoce cuando se expresan en lenguaje más natural.
