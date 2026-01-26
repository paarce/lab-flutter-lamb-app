# Test Cases: Funcionalidad 4.5 - Comandos de Sistema + Respuestas Sociales

**Fecha:** 2026-01-25
**Feature:** Comandos de información del sistema, respuestas sociales limitadas, y rechazo de conversaciones
**Implementador:** Claude Sonnet 4.5

---

## Resumen de Implementación

### Nuevos Comandos (6 tipos)

**Sistema (3):**
- `getTime` - "qué hora es"
- `getDate` - "qué día es hoy"
- `getBatteryLevel` - "cuánta batería tengo"

**Social (2 - LIMITADO):**
- `thankYou` - "gracias"
- `goodbye` - "adiós"

**Rechazo de Conversaciones (1):**
- `conversationRejected` - saludos sin objetivo claro

### Funcionalidades Implementadas

1. ✅ Platform Channel Kotlin → Flutter para info del sistema
2. ✅ Formatos accesibles ("2:30 de la tarde" no "14:30")
3. ✅ Respuestas sociales limitadas (solo gracias/adiós)
4. ✅ Rechazo amable de conversaciones
5. ✅ Contador de comandos unknown (3 fallos → ayuda proactiva)
6. ✅ System prompt externalizado en `/lib/prompts/`

---

## Test Cases - Comandos de Sistema

### TC-SISTEMA-001: Obtener Hora Actual

**Objetivo:** Verificar que el comando "qué hora es" obtiene y anuncia la hora correctamente.

**Precondiciones:**
- App corriendo en Android
- TTS funcionando

**Pasos:**
1. Abrir VoiceCommandScreen
2. Mantener presionado botón de micrófono
3. Decir: "qué hora es"
4. Soltar botón

**Resultado Esperado:**
- TTS anuncia: "Son las [hora]:[minutos] de la [mañana/tarde/noche]"
- Ejemplo: "Son las 2:30 de la tarde"
- Formato accesible (12 horas, no 24 horas)
- Log muestra: `Time announced: 2:30 de la tarde`

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-SISTEMA-002: Obtener Fecha Actual

**Objetivo:** Verificar que el comando "qué día es hoy" obtiene y anuncia la fecha correctamente.

**Precondiciones:**
- App corriendo en Android
- TTS funcionando

**Pasos:**
1. Abrir VoiceCommandScreen
2. Mantener presionado botón de micrófono
3. Decir: "qué día es hoy"
4. Soltar botón

**Resultado Esperado:**
- TTS anuncia: "Hoy es [día] de [mes] de [año]"
- Ejemplo: "Hoy es 25 de enero de 2026"
- Mes en español completo
- Log muestra: `Date announced: 25 de enero de 2026`

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-SISTEMA-003: Obtener Nivel de Batería

**Objetivo:** Verificar que el comando "cuánta batería tengo" obtiene y anuncia el nivel correctamente.

**Precondiciones:**
- App corriendo en Android
- TTS funcionando

**Pasos:**
1. Abrir VoiceCommandScreen
2. Mantener presionado botón de micrófono
3. Decir: "cuánta batería tengo"
4. Soltar botón

**Resultado Esperado:**
- TTS anuncia: "Tienes [número] por ciento de batería"
- Ejemplo: "Tienes 75 por ciento de batería"
- Número corresponde al nivel real del dispositivo
- Log muestra: `Battery level: 75%`

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-SISTEMA-004: Variantes de Comandos de Sistema

**Objetivo:** Verificar que el parser reconoce variantes naturales de los comandos.

**Pasos:**
1. Probar variantes de hora:
   - "dime la hora"
   - "hora"
   - "qué hora"

2. Probar variantes de fecha:
   - "fecha de hoy"
   - "día de hoy"
   - "fecha"

3. Probar variantes de batería:
   - "nivel de batería"
   - "batería"
   - "pila"
   - "cuánta pila"

**Resultado Esperado:**
- Todas las variantes activan el comando correcto
- TTS anuncia la información correspondiente

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar variantes que fallaron)

---

## Test Cases - Respuestas Sociales

### TC-SOCIAL-001: Respuesta a Agradecimiento

**Objetivo:** Verificar que "gracias" recibe respuesta apropiada.

**Pasos:**
1. Abrir VoiceCommandScreen
2. Mantener presionado botón de micrófono
3. Decir: "gracias"
4. Soltar botón

**Resultado Esperado:**
- TTS anuncia: "De nada, para eso estoy"
- Log muestra: `User said thanks`
- Contador de unknown se resetea a 0

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-SOCIAL-002: Respuesta a Despedida

**Objetivo:** Verificar que "adiós" recibe respuesta apropiada.

**Pasos:**
1. Abrir VoiceCommandScreen
2. Mantener presionado botón de micrófono
3. Decir: "adiós"
4. Soltar botón

**Resultado Esperado:**
- TTS anuncia: "Hasta luego"
- Log muestra: `User said goodbye`
- Contador de unknown se resetea a 0

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-SOCIAL-003: Variantes de Respuestas Sociales

**Objetivo:** Verificar que el parser reconoce variantes naturales.

**Pasos:**
1. Probar variantes de agradecimiento:
   - "muchas gracias"
   - "te agradezco"

2. Probar variantes de despedida:
   - "chau"
   - "chao"
   - "hasta luego"
   - "nos vemos"

**Resultado Esperado:**
- Todas las variantes activan el comando correcto
- TTS anuncia la respuesta correspondiente

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar variantes que fallaron)

---

## Test Cases - Rechazo de Conversaciones

### TC-CONV-001: Rechazo de Saludo Sin Objetivo

**Objetivo:** Verificar que saludos sin comando claro son rechazados amablemente.

**Pasos:**
1. Abrir VoiceCommandScreen
2. Mantener presionado botón de micrófono
3. Decir: "hola"
4. Soltar botón

**Resultado Esperado:**
- TTS anuncia: "Hola. No puedo mantener conversaciones, pero puedo ayudarte con comandos. Di 'comandos disponibles' para escuchar qué puedo hacer."
- Log muestra: `Conversation attempt rejected`
- Contador de unknown incrementa (cuenta como fallo)

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-CONV-002: Variantes de Saludos Rechazados

**Objetivo:** Verificar que diferentes saludos son rechazados.

**Pasos:**
1. Probar variantes:
   - "buenos días"
   - "buenas tardes"
   - "buenas noches"
   - "buen día"
   - "hola cómo estás"

**Resultado Esperado:**
- Todas las variantes reciben el mensaje de rechazo
- Mensaje es amable pero firme
- No inicia conversación

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar variantes que fallaron)

---

## Test Cases - Contador de Comandos Unknown

### TC-COUNTER-001: Ayuda Proactiva Después de 3 Fallos

**Objetivo:** Verificar que después de 3 comandos unknown consecutivos, la app ofrece ayuda.

**Pasos:**
1. Abrir VoiceCommandScreen
2. Decir 3 comandos inválidos consecutivos:
   - "qué hora es en París"
   - "cuéntame un chiste"
   - "asdfjkl"
3. Observar respuesta después del 3er comando

**Resultado Esperado:**
- Después del 1er fallo: "No entendí el comando. Intenta de nuevo."
- Después del 2do fallo: "No entendí el comando. Intenta de nuevo."
- Después del 3er fallo:
  - TTS anuncia: "No he podido entender tus últimos comandos. Voy a reproducir la lista de comandos disponibles."
  - Luego reproduce automáticamente la lista completa de comandos
- Log muestra: `Unknown counter: 1/3`, `2/3`, `3/3`
- Contador se resetea a 0 después de la ayuda

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-COUNTER-002: Reset del Contador con Comando Exitoso

**Objetivo:** Verificar que el contador se resetea cuando un comando válido se ejecuta exitosamente.

**Pasos:**
1. Abrir VoiceCommandScreen
2. Decir 2 comandos unknown: "blabla", "xyz"
3. Verificar log muestra: `Unknown counter: 2/3`
4. Decir comando válido: "qué hora es"
5. Verificar que TTS anuncia la hora
6. Verificar log muestra: `Resetting unknown counter from 2 to 0`
7. Decir otro comando unknown: "abc"
8. Verificar que contador vuelve a 1

**Resultado Esperado:**
- Comandos válidos resetean el contador
- Después del reset, el contador vuelve a contar desde 1
- Log muestra claramente el reset

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Test Cases - LLM Fallback

### TC-LLM-001: LLM Reconoce Nuevos Comandos

**Objetivo:** Verificar que el LLM reconoce comandos de sistema en lenguaje natural.

**Precondiciones:**
- Claude API key configurada en `lib/config/secrets.dart`
- Internet disponible

**Pasos:**
1. Decir frases naturales que el parser local no reconoce:
   - "dime qué hora es por favor"
   - "necesito saber la fecha de hoy"
   - "cuál es el nivel de mi batería"

**Resultado Esperado:**
- LLM parsea correctamente a los comandos correspondientes
- Comandos se ejecutan exitosamente
- Log muestra: `Parsed LLM command: getTime/getDate/getBatteryLevel`

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-LLM-002: LLM Rechaza Conversaciones

**Objetivo:** Verificar que el LLM también rechaza intentos de conversación.

**Pasos:**
1. Decir frases conversacionales:
   - "hola cómo te va hoy"
   - "buenos días qué tal estás"

**Resultado Esperado:**
- LLM responde con `conversation_rejected`
- TTS anuncia mensaje de rechazo
- Log muestra: `Conversation attempt rejected`

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Test Cases - System Prompt Externalizado

### TC-PROMPT-001: Prompt Carga Correctamente

**Objetivo:** Verificar que el system prompt externalizado se carga sin errores.

**Pasos:**
1. Iniciar app
2. Decir comando que active LLM (ej: "necesito ayuda por favor")
3. Verificar logs de LLMParserService

**Resultado Esperado:**
- No hay errores al cargar el prompt
- LLM funciona normalmente
- Log NO muestra errores de carga

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-PROMPT-002: Cache de Prompt Funciona

**Objetivo:** Verificar que el prompt se cachea en memoria.

**Pasos:**
1. Iniciar app
2. Hacer 2 comandos que activen LLM
3. Verificar que no se recarga el prompt cada vez

**Resultado Esperado:**
- Prompt se carga solo 1 vez
- Llamadas subsecuentes usan versión cacheada
- Performance es buena

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Test Cases - Tutorial y Lista de Comandos Actualizada

### TC-TUTORIAL-001: Tutorial Incluye Nuevos Comandos

**Objetivo:** Verificar que el tutorial menciona los nuevos comandos.

**Pasos:**
1. Decir: "tutorial"
2. Escuchar el tutorial completo

**Resultado Esperado:**
- Tutorial menciona: "Quinto: Di 'qué hora es' o 'cuánta batería tengo' para información del sistema"
- Tutorial menciona: "Sexto: Di 'comandos disponibles' para escuchar la lista completa"

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-LISTA-001: Lista de Comandos Incluye Nuevos

**Objetivo:** Verificar que "comandos disponibles" lista los nuevos comandos.

**Pasos:**
1. Decir: "comandos disponibles"
2. Escuchar la lista completa

**Resultado Esperado:**
- Lista menciona sección "Información del sistema" con:
  - "Qué hora es" para saber la hora actual
  - "Qué día es hoy" para saber la fecha
  - "Cuánta batería tengo" para conocer el nivel de batería
- Lista menciona sección "Comandos sociales" con:
  - "Gracias" cuando quieras agradecer
  - "Adiós" cuando termines de usar la aplicación

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Test Cases - Integración End-to-End

### TC-E2E-001: Flujo Completo de Uso

**Objetivo:** Simular un uso real de la app con los nuevos comandos.

**Pasos:**
1. Usuario inicia app
2. Dice: "qué hora es"
   - Escucha: "Son las X:XX de la tarde"
3. Dice: "cuánta batería tengo"
   - Escucha: "Tienes XX por ciento de batería"
4. Dice: "gracias"
   - Escucha: "De nada, para eso estoy"
5. Dice: "compartir pantalla"
   - Navega a RemoteControlHostScreen
6. Dice: "adiós"
   - Escucha: "Hasta luego"

**Resultado Esperado:**
- Todos los comandos funcionan en secuencia
- No hay errores
- Contador se resetea después de cada comando exitoso
- TTS anuncia todo correctamente

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-E2E-002: Flujo con Fallos y Recuperación

**Objetivo:** Verificar que el sistema se recupera de errores.

**Pasos:**
1. Dice: "blabla" (fallo 1)
2. Dice: "xyz" (fallo 2)
3. Dice: "qué hora es" (éxito → reset)
4. Dice: "abc" (fallo 1 nuevamente)
5. Dice: "def" (fallo 2)
6. Dice: "ghi" (fallo 3 → ayuda proactiva)
7. Escucha lista de comandos
8. Dice: "cuánta batería" (éxito)

**Resultado Esperado:**
- Contador funciona correctamente
- Ayuda proactiva se activa en el 3er fallo
- Sistema se recupera y permite seguir usando

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Test Cases - Accesibilidad

### TC-ACC-001: Mensajes TTS Son Accesibles

**Objetivo:** Verificar que todos los mensajes TTS son claros para adultos mayores.

**Criterios:**
- Lenguaje simple (sin tecnicismos)
- Frases cortas (máximo 2 oraciones)
- Formatos accesibles ("2:30 de la tarde" no "14:30")
- Ritmo pausado

**Verificar mensajes de:**
- Hora: "Son las X:XX de la tarde"
- Fecha: "Hoy es DD de MMMM de AAAA"
- Batería: "Tienes XX por ciento de batería"
- Gracias: "De nada, para eso estoy"
- Adiós: "Hasta luego"
- Rechazo: "Hola. No puedo mantener conversaciones..."

**Resultado Esperado:**
- Todos los mensajes cumplen criterios de accesibilidad
- Son comprensibles para personas 60+
- TTS los pronuncia claramente

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Test Cases - Platform Channel (Kotlin)

### TC-KOTLIN-001: getCurrentTimeFormatted

**Objetivo:** Verificar que el método Kotlin devuelve hora en formato correcto.

**Método de prueba:** Log inspection

**Resultado Esperado:**
- Log muestra: `Current time: X:XX de la [mañana/tarde/noche]`
- Formato correcto:
  - 0-11am → "de la mañana"
  - 12-19 (12-7pm) → "de la tarde"
  - 20-23 (8-11pm) → "de la noche"
- Hora en formato 12h, no 24h

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-KOTLIN-002: getCurrentDateFormatted

**Objetivo:** Verificar que el método Kotlin devuelve fecha en formato correcto.

**Método de prueba:** Log inspection

**Resultado Esperado:**
- Log muestra: `Current date: DD de MMMM de AAAA`
- Mes en español completo (enero, febrero, etc.)
- Día sin 0 adelante (25 no 025)

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

### TC-KOTLIN-003: getBatteryLevelInternal

**Objetivo:** Verificar que el método Kotlin devuelve nivel de batería correcto.

**Método de prueba:** Comparar con nivel mostrado en sistema Android

**Resultado Esperado:**
- Valor devuelto coincide con nivel real
- Rango: 0-100
- Log muestra: `Battery level: XX%`

**Resultado Real:**
- [ ] PASS
- [ ] FAIL (detallar)

---

## Resumen de Validación

### Checklist Pre-Release

- [ ] Todos los test cases de sistema (TC-SISTEMA-*) pasan
- [ ] Todos los test cases de social (TC-SOCIAL-*) pasan
- [ ] Todos los test cases de conversación (TC-CONV-*) pasan
- [ ] Todos los test cases de contador (TC-COUNTER-*) pasan
- [ ] Todos los test cases de LLM (TC-LLM-*) pasan
- [ ] Todos los test cases de accesibilidad (TC-ACC-*) pasan
- [ ] `flutter analyze` pasa sin errores
- [ ] App compila en Android sin errores
- [ ] No hay crashes en uso normal
- [ ] TTS funciona correctamente para todos los comandos nuevos
- [ ] Logs muestran información útil sin spam

### Métricas de Éxito

- **Precisión de parser local:** ≥95% comandos reconocidos
- **Latencia de comandos de sistema:** <500ms desde comando hasta TTS
- **Tasa de ayuda proactiva:** Usuario recibe ayuda antes de frustrarse
- **Comprensión TTS:** 100% de mensajes comprensibles para 60+

---

**Estado:** ⏳ Pendiente de testing
**Siguiente paso:** Ejecutar test cases en dispositivo Android real
