# 📋 MANUAL TEST CASES - Funcionalidad 4.2: Control de Volumen TTS

**Versión:** 1.0.0
**Funcionalidad:** Sistema de control de volumen mediante comandos de voz
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 11 (8 P0 + 3 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Reconocimiento de Comandos](#-categoría-a-reconocimiento-de-comandos)
- [B. Ajuste de Volumen](#-categoría-b-ajuste-de-volumen)
- [C. Límites de Volumen](#-categoría-c-límites-de-volumen)
- [D. Feedback TTS](#-categoría-d-feedback-tts)
- [E. Integración con Sistema Existente](#-categoría-e-integración-con-sistema-existente)
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
- ✅ Usuario está en `VoiceCommandScreen`
- ✅ Botón "Mantén presionado para hablar" visible y habilitado
- ✅ Sin sesiones de voz activas previas
- ✅ Volumen TTS inicial en 100% (valor por defecto)

### **Funcionalidad 4.1 Completa:**
- ✅ **PREREQUISITO CRÍTICO:** Todos los test cases P0 de Funcionalidad 4.1 deben pasar
- ✅ Reconocimiento de voz funcionando (TC-VOICE-003)
- ✅ Parsing de comandos operativo (TC-VOICE-006, TC-VOICE-007, TC-VOICE-008)
- ✅ TTS funcionando correctamente (TC-VOICE-015)

### **Permisos del Sistema:**
- ✅ Permiso de micrófono otorgado (Settings → Apps → Lamb → Permissions → Microphone: Allow)

---

## 🚀 SETUP DE PRUEBAS

### **Opción 1: Desarrollo Local**

```bash
# Terminal 1 - Ejecutar app en dispositivo/emulador
cd /path/to/lamb
flutter run

# Verificar que compila sin errores
# Navegar a VoiceCommandScreen
```

### **Verificación de Setup:**

1. Abrir app
2. Tap en botón "Comandos de Voz"
3. Verificar que `VoiceCommandScreen` se abre sin errores
4. Verificar que en la lista de comandos disponibles se ve:
   - "Solicitar ayuda"
   - "Abrir WhatsApp"
   - "Cambiar contraste"
   - **"Subir volumen"** (NUEVO)
   - **"Bajar volumen"** (NUEVO)
   - "Cancelar"

### **Verificar Implementación:**

```bash
# Verificar que los nuevos CommandTypes existen
grep -r "adjustVolumeUp\|adjustVolumeDown" lib/models/command.dart

# Verificar métodos de volumen en TTSService
grep -r "increaseVolume\|decreaseVolume" lib/services/tts/

# Verificar keywords en NLPParser
grep -r "_volumeUpKeywords\|_volumeDownKeywords" lib/utils/nlp_parser.dart
```

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Reconocimiento de Comandos | 3 | 2 | 1 | ~10 min |
| B. Ajuste de Volumen | 2 | 2 | 0 | ~10 min |
| C. Límites de Volumen | 3 | 2 | 1 | ~15 min |
| D. Feedback TTS | 2 | 1 | 1 | ~10 min |
| E. Integración con Sistema Existente | 1 | 1 | 0 | ~5 min |
| **TOTAL** | **11** | **8** | **3** | **~50 min** |

---

## 📂 CATEGORÍA A: RECONOCIMIENTO DE COMANDOS

**Prerequisitos específicos:** Funcionalidad 4.1 operativa, listening activo

---

### ✅ TC-VOL-001: Reconocer comando "subir volumen"

**Prioridad:** P0
**Objetivo:** Verificar que el NLPParser reconoce correctamente variaciones del comando "subir volumen"

**Pasos:**
1. Abrir app y navegar a `VoiceCommandScreen`
2. Mantener presionado el botón "Mantén presionado para hablar"
3. **Intento 1:** Hablar "subir volumen"
4. Soltar el botón y observar parsing
5. Reiniciar listening
6. **Intento 2:** Hablar "sube el volumen"
7. Reiniciar listening
8. **Intento 3:** Hablar "aumentar volumen"
9. Reiniciar listening
10. **Intento 4:** Hablar "más volumen"

**Resultado Esperado (para cada intento):**
- ✅ Transcripción correcta del texto hablado
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.adjustVolumeUp
  [VoiceCommandProvider] Executing command: CommandType.adjustVolumeUp
  [VoiceCommandProvider] Volume increased to: [nuevo_valor]
  ```
- ✅ TTS anuncia el nuevo porcentaje de volumen
- ✅ Estado vuelve a idle

**Criterios de Aceptación:**
- 4/4 variaciones reconocidas correctamente como `CommandType.adjustVolumeUp`
- Parsing < 50ms (keywords locales)
- Sin errores en logs

---

### ✅ TC-VOL-002: Reconocer comando "bajar volumen"

**Prioridad:** P0
**Objetivo:** Verificar que el NLPParser reconoce correctamente variaciones del comando "bajar volumen"

**Pasos:**
1. Abrir app y navegar a `VoiceCommandScreen`
2. Mantener presionado el botón y hablar: "bajar volumen"
3. Soltar y observar parsing
4. Repetir con variaciones:
   - **Intento 2:** "baja el volumen"
   - **Intento 3:** "disminuir volumen"
   - **Intento 4:** "menos volumen"
   - **Intento 5:** "volumen abajo"

**Resultado Esperado:**
- ✅ 5/5 variaciones reconocidas como `CommandType.adjustVolumeDown`
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.adjustVolumeDown
  [VoiceCommandProvider] Volume decreased to: [nuevo_valor]
  ```
- ✅ TTS anuncia el nuevo porcentaje

**Criterios de Aceptación:**
- Todas las variaciones funcionan
- Comportamiento consistente con "subir volumen"

---

### ✅ TC-VOL-003: Prioridad de parsing vs otros comandos

**Prioridad:** P1
**Objetivo:** Verificar que los comandos de volumen tienen la prioridad correcta en el parser

**Prerequisitos adicionales:**
- Conocer orden de prioridad: Cancel > Contrast > **Volume** > Help > WhatsApp

**Pasos:**
1. Hablar: "cancelar volumen" (combina 2 comandos)
2. Observar qué comando se ejecuta
3. Hablar: "alto contraste volumen"
4. Observar resultado
5. Hablar: "subir volumen ayuda"
6. Observar resultado

**Resultado Esperado:**
- ✅ **Test 1:** "cancelar" tiene prioridad → ejecuta `CommandType.cancel`
- ✅ **Test 2:** "alto contraste" tiene prioridad → ejecuta `CommandType.toggleContrast`
- ✅ **Test 3:** "subir volumen" tiene prioridad → ejecuta `CommandType.adjustVolumeUp` (ignora "ayuda")
- ✅ **En logs:** Se observa parsing del comando con prioridad más alta

**Criterios de Aceptación:**
- Prioridad respeta orden definido en NLPParser
- Solo se ejecuta UN comando por sesión (el de mayor prioridad)

---

## 📂 CATEGORÍA B: AJUSTE DE VOLUMEN

**Prerequisitos específicos:** Comandos reconocidos correctamente

---

### ✅ TC-VOL-004: Incremento de volumen en pasos de 10%

**Prioridad:** P0
**Objetivo:** Verificar que "subir volumen" incrementa el volumen TTS en exactamente 10% (0.1)

**Prerequisitos adicionales:**
- Volumen inicial conocido (puede usar logs para verificar)

**Pasos:**
1. Navegar a `VoiceCommandScreen`
2. **Nota inicial:** Si no se conoce el volumen actual, ejecutar "subir volumen" una vez para ver el porcentaje anunciado
3. Anotar volumen actual (ej: 100%)
4. Hablar: "subir volumen"
5. Anotar nuevo volumen anunciado
6. Calcular diferencia: nuevo_volumen - volumen_anterior
7. Repetir 2 veces más (total 3 incrementos)

**Resultado Esperado:**
- ✅ Cada incremento es exactamente 10%
  - Ejemplo: 60% → 70% → 80% → 90%
- ✅ **En logs (cada incremento):**
  ```
  [FlutterTtsService] TTS volume set to: [0.7, 0.8, 0.9]
  [VoiceCommandProvider] Volume increased to: [0.7, 0.8, 0.9]
  ```
- ✅ TTS anuncia correctamente: "Volumen al 70 por ciento", "Volumen al 80 por ciento", etc.
- ✅ Volumen TTS audible aumenta perceptiblemente

**Criterios de Aceptación:**
- Incremento consistente de 10% en cada ejecución
- Valor calculado es correcto (round al entero más cercano)
- Volumen audible coincide con porcentaje anunciado

---

### ✅ TC-VOL-005: Decremento de volumen en pasos de 10%

**Prioridad:** P0
**Objetivo:** Verificar que "bajar volumen" decrementa el volumen TTS en exactamente 10%

**Pasos:**
1. Asegurar que volumen inicial está en un valor medio (ej: 50-80%)
   - Si está en 100%, ejecutar "bajar volumen" varias veces hasta llegar a ~70%
2. Anotar volumen actual
3. Hablar: "bajar volumen"
4. Anotar nuevo volumen
5. Calcular diferencia: volumen_anterior - nuevo_volumen
6. Repetir 2 veces más (total 3 decrementos)

**Resultado Esperado:**
- ✅ Cada decremento es exactamente 10%
  - Ejemplo: 70% → 60% → 50% → 40%
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Volume decreased to: [0.6, 0.5, 0.4]
  ```
- ✅ TTS anuncia: "Volumen al 60 por ciento", "Volumen al 50 por ciento", etc.
- ✅ Volumen audible disminuye perceptiblemente

**Criterios de Aceptación:**
- Decremento consistente de 10%
- Simétrico con incremento (TC-VOL-004)
- Volumen audible refleja cambio

---

## 📂 CATEGORÍA C: LÍMITES DE VOLUMEN

**Prerequisitos específicos:** Comandos de volumen funcionando

---

### ✅ TC-VOL-006: Límite superior (100%)

**Prioridad:** P0
**Objetivo:** Verificar que el volumen no puede exceder 100% (1.0)

**Pasos:**
1. Navegar a `VoiceCommandScreen`
2. Ejecutar "subir volumen" repetidamente hasta alcanzar 100%
   - **Tip:** Si volumen inicial es 60%, necesitas ~4 ejecuciones
3. Cuando TTS anuncia "Volumen al 100 por ciento":
   - Anotar volumen actual: 100%
4. Ejecutar "subir volumen" **3 veces más**
5. Observar anuncio TTS en cada ejecución
6. Verificar logs

**Resultado Esperado:**
- ✅ Al llegar a 100%, ejecuciones adicionales NO incrementan más
- ✅ TTS siempre anuncia: "Volumen al 100 por ciento" (no "110", "120", etc.)
- ✅ **En logs:**
  ```
  [FlutterTtsService] TTS volume set to: 1.0
  [VoiceCommandProvider] Volume increased to: 1.0
  ```
  (valor NO excede 1.0)
- ✅ Método `setVolume()` aplica clamp: `volume.clamp(0.0, 1.0)`
- ✅ Volumen audible se mantiene en máximo (sin distorsión)

**Criterios de Aceptación:**
- Valor interno nunca excede 1.0
- TTS no anuncia porcentajes > 100%
- Sin errores o crashes

---

### ✅ TC-VOL-007: Límite inferior (0%)

**Prioridad:** P0
**Objetivo:** Verificar que el volumen no puede ser menor a 0% (0.0)

**Pasos:**
1. Asegurar volumen inicial en valor bajo (ej: 30%)
2. Ejecutar "bajar volumen" repetidamente hasta alcanzar 0%
3. Cuando TTS anuncia "Volumen al 0 por ciento":
   - **Nota:** A 0% el TTS será inaudible (esto es esperado)
   - Verificar logs para confirmar valor
4. Ejecutar "bajar volumen" **3 veces más**
5. Verificar logs (no se puede escuchar TTS a 0%)

**Resultado Esperado:**
- ✅ Al llegar a 0%, ejecuciones adicionales NO decrementan más
- ✅ **En logs:**
  ```
  [FlutterTtsService] TTS volume set to: 0.0
  [VoiceCommandProvider] Volume decreased to: 0.0
  ```
  (valor NO es negativo)
- ✅ TTS intenta anunciar "Volumen al 0 por ciento" pero es inaudible (comportamiento esperado)
- ✅ Método `setVolume()` aplica clamp: `volume.clamp(0.0, 1.0)`
- ✅ **IMPORTANTE:** La app NO crashea a volumen 0

**Criterios de Aceptación:**
- Valor interno nunca es negativo
- App estable a volumen 0 (sin crashes)
- Logs muestran valor correcto (0.0)

**Nota de UX:**
- A 0%, el usuario no escuchará feedback TTS
- Esto es una limitación conocida (no es un bug)
- Mitigación: Usuario puede aumentar volumen multimedia del dispositivo para escuchar mejor

---

### ✅ TC-VOL-008: Recuperación desde volumen 0%

**Prioridad:** P1
**Objetivo:** Verificar que se puede subir volumen después de llegar a 0%

**Prerequisitos adicionales:**
- Volumen TTS en 0% (completar TC-VOL-007 primero)

**Pasos:**
1. Con volumen TTS en 0%, ejecutar "subir volumen"
2. Verificar logs (TTS inaudible)
3. Ejecutar "subir volumen" 2 veces más (total 3 incrementos → 30%)
4. Verificar que ahora el TTS se escucha
5. Continuar subiendo hasta 50%

**Resultado Esperado:**
- ✅ Desde 0%, cada "subir volumen" incrementa 10%: 0% → 10% → 20% → 30%
- ✅ A partir de ~20-30%, TTS vuelve a ser audible
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Volume increased to: 0.1, 0.2, 0.3
  ```
- ✅ No hay pérdida de funcionalidad (estado interno correcto)

**Criterios de Aceptación:**
- Incrementos funcionan correctamente desde 0%
- TTS recupera audibilidad gradualmente
- Sin errores en transición 0% → valores positivos

---

## 📂 CATEGORÍA D: FEEDBACK TTS

**Prerequisitos específicos:** TTS service funcionando

---

### ✅ TC-VOL-009: Anuncio de porcentaje correcto

**Prioridad:** P0
**Objetivo:** Verificar que el TTS anuncia el porcentaje exacto después de cada ajuste

**Pasos:**
1. Establecer volumen en 50% (ejecutar comandos necesarios)
2. Ejecutar "subir volumen"
3. Escuchar anuncio TTS
4. Verificar que anuncia: "Volumen al 60 por ciento" (no "Volumen al 0.6")
5. Ejecutar "bajar volumen"
6. Verificar anuncio: "Volumen al 50 por ciento"
7. Probar con diferentes valores:
   - Desde 5% → "subir volumen" → debe anunciar "15 por ciento"
   - Desde 95% → "subir volumen" → debe anunciar "100 por ciento" (límite)

**Resultado Esperado:**
- ✅ TTS siempre anuncia porcentaje redondeado (entero, no decimal)
  - Correcto: "Volumen al 60 por ciento"
  - Incorrecto: "Volumen al 0.6" o "Volumen al 60%"
- ✅ Fórmula: `(volume * 100).round()` → convierte 0.6 a 60
- ✅ Anuncio es claro y comprensible para usuarios 60+
- ✅ **En código:**
  ```dart
  final percentage = (_ttsService.volume * 100).round();
  await _ttsService.speak('Volumen al $percentage por ciento');
  ```

**Criterios de Aceptación:**
- 100% de anuncios usan formato correcto
- Sin decimales en mensajes de voz
- Lenguaje natural ("por ciento", no "%")

---

### ✅ TC-VOL-010: Feedback audible a diferentes niveles

**Prioridad:** P1
**Objetivo:** Verificar que el cambio de volumen TTS es perceptible auditivamente

**Prerequisitos adicionales:**
- Ambiente silencioso
- Volumen multimedia del dispositivo en 100%

**Pasos:**
1. Establecer volumen TTS en 100%
2. Ejecutar "solicitar ayuda" → escuchar TTS: "Generando código..."
3. Anotar percepción del volumen audible
4. Ejecutar "bajar volumen" 5 veces (100% → 50%)
5. Ejecutar "solicitar ayuda" nuevamente
6. Comparar volumen audible con paso 2
7. Ejecutar "bajar volumen" 5 veces más (50% → 0%)
8. Intentar ejecutar "solicitar ayuda"
9. Verificar que TTS es inaudible

**Resultado Esperado:**
- ✅ A 100%: TTS se escucha fuerte y claro
- ✅ A 50%: TTS se escucha notablemente más bajo (pero comprensible)
- ✅ A 0%: TTS es completamente inaudible
- ✅ Cambios graduales son perceptibles (cada 10% hace diferencia)
- ✅ No hay distorsión de audio en ningún nivel

**Criterios de Aceptación:**
- Volumen TTS corresponde al porcentaje configurado
- Diferencias de 10% son perceptibles auditivamente
- Audio es claro en todos los niveles > 0%

---

## 📂 CATEGORÍA E: INTEGRACIÓN CON SISTEMA EXISTENTE

**Prerequisitos específicos:** Funcionalidad 4.1 completa

---

### ✅ TC-VOL-011: Comandos de volumen no interfieren con comandos existentes

**Prioridad:** P0
**Objetivo:** Verificar que los comandos de volumen coexisten correctamente con comandos de 4.1

**Pasos:**
1. **Secuencia de comandos mixtos:**
   - Ejecutar: "subir volumen"
   - Ejecutar: "alto contraste" (toggle tema)
   - Ejecutar: "bajar volumen"
   - Ejecutar: "solicitar ayuda" (navegación)
   - Volver a VoiceCommandScreen
   - Ejecutar: "subir volumen"
   - Ejecutar: "cancelar"
2. Verificar que cada comando se ejecuta correctamente en secuencia

**Resultado Esperado:**
- ✅ Todos los comandos se ejecutan sin conflictos
- ✅ Volumen TTS afecta TODOS los anuncios:
  - "Cambiando a alto contraste" se escucha al volumen actual
  - "Generando código de sesión..." se escucha al volumen actual
  - "Cancelado" se escucha al volumen actual
- ✅ Cambios de volumen persisten durante toda la sesión de la app
- ✅ **En logs:** Secuencia completa sin errores
  ```
  [VoiceCommandProvider] Volume increased to: 1.0
  [VoiceCommandProvider] Theme toggled to: AppThemeMode.highContrast
  [VoiceCommandProvider] Volume decreased to: 0.9
  [VoiceCommandProvider] Navigating to RemoteControlHostScreen
  [VoiceCommandProvider] Volume increased to: 1.0
  [VoiceCommandProvider] User cancelled listening
  ```

**Criterios de Aceptación:**
- 6/6 comandos ejecutados exitosamente
- Volumen afecta todos los mensajes TTS
- Sin errores de estado o memory leaks
- Persistencia de volumen durante sesión

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Test Cases | Estado |
|---------------|------------|--------|
| Reconocimiento de comandos | TC-VOL-001, TC-VOL-002, TC-VOL-003 | ✅ Cubierta |
| Ajuste de volumen (incremento/decremento) | TC-VOL-004, TC-VOL-005 | ✅ Cubierta |
| Límites de volumen (0-100%) | TC-VOL-006, TC-VOL-007, TC-VOL-008 | ✅ Cubierta |
| Feedback TTS | TC-VOL-009, TC-VOL-010 | ✅ Cubierta |
| Integración con 4.1 | TC-VOL-011 | ✅ Cubierta |

### **Comandos Implementados en 4.2**

| Comando | Variaciones | Test Case | Efecto |
|---------|-------------|-----------|--------|
| **Subir volumen** | "subir volumen", "sube el volumen", "aumentar volumen", "más volumen", "volumen arriba" | TC-VOL-001, TC-VOL-004 | ✅ Incrementa volumen TTS +10% |
| **Bajar volumen** | "bajar volumen", "baja el volumen", "disminuir volumen", "menos volumen", "volumen abajo" | TC-VOL-002, TC-VOL-005 | ✅ Decrementa volumen TTS -10% |

### **Cobertura de Edge Cases**

| Edge Case | Test Case | Estado |
|-----------|-----------|--------|
| Volumen máximo (100%) | TC-VOL-006 | ✅ Cubierta |
| Volumen mínimo (0%) | TC-VOL-007 | ✅ Cubierta |
| Recuperación desde 0% | TC-VOL-008 | ✅ Cubierta |
| Integración con comandos 4.1 | TC-VOL-011 | ✅ Cubierta |

### **Comandos Totales Post-4.2**

| Comando | Funcionalidad | Integrado |
|---------|---------------|-----------|
| "Solicitar ayuda" | 4.1 | ✅ |
| "Alto contraste" | 4.1 | ✅ |
| **"Subir volumen"** | **4.2** | ✅ |
| **"Bajar volumen"** | **4.2** | ✅ |
| "Abrir WhatsApp" | 4.1 (stub) | ⏳ Feature 5 |
| "Cancelar" | 4.1 | ✅ |

### **Prioridades de Testing**

**P0 (Bloqueantes - Deben pasar antes de release):**
- TC-VOL-001, TC-VOL-002 (Reconocimiento de comandos)
- TC-VOL-004, TC-VOL-005 (Ajuste de volumen)
- TC-VOL-006, TC-VOL-007 (Límites)
- TC-VOL-009 (Feedback correcto)
- TC-VOL-011 (Integración)

**P1 (Importantes - Pueden ser hotfixed):**
- TC-VOL-003 (Prioridad de parsing)
- TC-VOL-008 (Recuperación desde 0%)
- TC-VOL-010 (Percepción audible)

### **Métricas de Éxito**

Para considerar la Funcionalidad 4.2 **PRODUCTION READY**:
- ✅ 100% de test cases P0 pasan en dispositivos de referencia
- ✅ ≥ 80% de test cases P1 pasan
- ✅ Volumen TTS audible refleja porcentaje configurado
- ✅ Límites (0-100%) funcionan correctamente sin crashes
- ✅ Feedback TTS claro y comprensible para usuarios 60+
- ✅ Integración con comandos 4.1 sin conflictos
- ✅ Sin memory leaks en 10+ ajustes consecutivos

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Arquitectura de la Feature**

```
User Voice → ElevenLabs STT → NLPParser → VoiceCommandProvider → TTSService
                                    ↓
                            CommandType.adjustVolumeUp/Down
                                    ↓
                            FlutterTtsService.increaseVolume()
                                    ↓
                            setVolume(currentVolume + 0.1)
                                    ↓
                            FlutterTts.setVolume(clamped_value)
```

### **Archivos Modificados**

| Archivo | Cambios |
|---------|---------|
| `lib/models/command.dart` | Agregados `adjustVolumeUp`, `adjustVolumeDown` |
| `lib/services/tts/tts_service.dart` | Agregados métodos `volume`, `setVolume()`, `increaseVolume()`, `decreaseVolume()` |
| `lib/services/tts/implementations/flutter_tts_service.dart` | Implementación de control de volumen + tracking `_currentVolume` |
| `lib/utils/nlp_parser.dart` | Agregadas keywords `_volumeUpKeywords`, `_volumeDownKeywords` + parsing logic |
| `lib/providers/voice_command_provider.dart` | Agregados cases `adjustVolumeUp`, `adjustVolumeDown` en `_executeCommand()` |
| `lib/screens/voice_command_screen.dart` | Agregados items "Subir volumen", "Bajar volumen" en lista de comandos |

### **Limitaciones Conocidas (MVP 4.2)**

1. **Volumen NO persiste entre sesiones:**
   - Al reiniciar la app, volumen vuelve a 100% (valor por defecto)
   - **Mejora:** Persistir en Hive (v1.1)

2. **A volumen 0%, feedback TTS inaudible:**
   - Usuario no escucha confirmación "Volumen al 0 por ciento"
   - **Mitigación:** Subir volumen multimedia del dispositivo
   - **Mejora:** Añadir feedback visual (v1.1)

3. **Solo ajustes de 10%:**
   - No hay comando para valores específicos (ej: "volumen al 50%")
   - **Mejora:** Parsing avanzado con LLM (4.4)

4. **No hay comando "silenciar":**
   - Usuario debe ejecutar "bajar volumen" múltiples veces para llegar a 0%
   - **Mejora:** Agregar comando "silenciar" / "activar sonido" (v1.1)

### **Debugging Tips**

**Verificar volumen actual:**
```dart
// En VoiceCommandProvider._executeCommand()
print('Current TTS volume: ${_ttsService.volume}');
```

**Logs relevantes:**
```bash
# Ver solo logs de volumen
flutter logs | grep -E "Volume|volume|TTS volume"

# Ver ejecución de comandos de volumen
flutter logs | grep "adjustVolume"

# Ver setVolume calls
flutter logs | grep "TTS volume set to"
```

**Verificar implementación:**
```bash
# Verificar que _currentVolume se actualiza
grep -A 5 "setVolume" lib/services/tts/implementations/flutter_tts_service.dart

# Verificar clamp
grep "clamp" lib/services/tts/implementations/flutter_tts_service.dart
```

### **Errores Comunes y Soluciones**

| Error | Causa | Solución |
|-------|-------|----------|
| TTS no cambia volumen audible | Volumen multimedia del dispositivo en 0 | Subir volumen del dispositivo |
| "Volumen al 0.6 por ciento" | Falta `.round()` en porcentaje | Verificar código en `voice_command_provider.dart` |
| Volumen > 100% en logs | Falta `clamp()` en `setVolume()` | Verificar implementación en `flutter_tts_service.dart` |
| Crash a volumen 0 | Bug en TTS engine | Envolver `speak()` en try-catch |
| Volumen resetea después de comando | Estado no persiste | Verificar que `_currentVolume` se mantiene en memoria |

---

## 🚀 PRÓXIMOS PASOS (Post-Testing)

### **Si todos los P0 pasan:**
1. ✅ Feature 4.2 lista para producción
2. Documentar en CHANGELOG.md
3. Continuar con Feature 4.3 (si planificada)
4. Considerar mejoras v1.1:
   - Persistencia de volumen en Hive
   - Comando "volumen al X por ciento" (valor específico)
   - Feedback visual además de auditivo

### **Si hay fallos:**
1. Documentar fallos específicos en GitHub Issues
2. Priorizar según criticidad (P0 > P1)
3. Reproducir en ambiente controlado
4. Fix + re-test con este documento

---

## 🔄 INTEGRATION TESTING

### **Ejecutar Test Suite Completo (4.1 + 4.2)**

Para asegurar regresiones NO introducidas:

1. **Ejecutar todos los P0 de 4.1:**
   - TC-VOICE-001 (Permisos)
   - TC-VOICE-003 (STT)
   - TC-VOICE-006, TC-VOICE-007, TC-VOICE-008 (Parsing)
   - TC-VOICE-010, TC-VOICE-011 (Ejecución)
   - TC-VOICE-013 (Timeout)
   - TC-VOICE-015 (Feedback TTS)

2. **Ejecutar todos los P0 de 4.2:**
   - TC-VOL-001 a TC-VOL-011

3. **Verificar coexistencia:**
   - Ejecutar secuencia mixta (TC-VOL-011)
   - Verificar que volumen afecta todos los comandos

**Criterio de Aprobación:**
- 100% de P0 de 4.1 siguen pasando (NO regresiones)
- 100% de P0 de 4.2 pasan

---

**Versión:** 1.0.0
**Última actualización:** 23 ene 2026
**Autor:** Claude (Feature 4.2 - Volume Control)
**Stack:** Flutter + ElevenLabs STT + flutter_tts + Provider
**Dependencias:** Funcionalidad 4.1 (Voice Command Infrastructure)
