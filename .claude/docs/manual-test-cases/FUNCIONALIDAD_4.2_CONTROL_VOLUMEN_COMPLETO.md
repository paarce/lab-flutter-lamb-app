# 📋 MANUAL TEST CASES - Funcionalidad 4.2: Control de Volumen TTS (Completo)

**Versión:** 2.0.0 (Features 4.2.1 + 4.2.2 + 4.2.3)
**Funcionalidad:** Sistema de control de volumen mediante comandos de voz
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 18 (13 P0 + 5 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Features Implementadas](#-features-implementadas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Reconocimiento de Comandos](#-categoría-a-reconocimiento-de-comandos)
- [B. Ajuste de Volumen Incremental](#-categoría-b-ajuste-de-volumen-incremental)
- [C. Comandos Absolutos](#-categoría-c-comandos-absolutos)
- [D. Porcentajes Específicos](#-categoría-d-porcentajes-específicos)
- [E. Límites de Volumen](#-categoría-e-límites-de-volumen)
- [F. Feedback TTS](#-categoría-f-feedback-tts)
- [G. Integración con Sistema Existente](#-categoría-g-integración-con-sistema-existente)
- [Resumen de Cobertura](#-resumen-de-cobertura)

---

## 🔧 PREREQUISITOS GLOBALES

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

---

## 🚀 SETUP DE PRUEBAS

### **Verificación de Setup:**

1. Abrir app y navegar a `VoiceCommandScreen`
2. Verificar que en la lista de comandos disponibles se ven:
   - "Solicitar ayuda"
   - "Abrir WhatsApp"
   - "Cambiar contraste"
   - **"Subir volumen"** ✅
   - **"Bajar volumen"** ✅
   - **"Volumen al máximo"** ✅ NUEVO
   - **"Silencio"** ✅ NUEVO
   - **"Volumen al 50%"** ✅ NUEVO
   - "Cancelar"

### **Verificar Implementación:**

```bash
# Verificar CommandTypes
grep -E "adjustVolume|setVolume" lib/models/command.dart

# Verificar keywords
grep -E "_volumeMaxKeywords|_volumeMinKeywords|_parseVolumePercentage" lib/utils/nlp_parser.dart

# Verificar ejecución
grep -E "setVolumeMax|setVolumeMin|setVolumePercentage" lib/providers/voice_command_provider.dart
```

---

## 🎯 FEATURES IMPLEMENTADAS

### **Feature 4.2.1: Keywords Adicionales**
- ✅ Soporte para artículos: "aumentar **el** volumen", "baja **el** volumen"
- ✅ Más variaciones: "aumenta volumen", "disminuye volumen", "sube más el volumen"

### **Feature 4.2.2: Comandos Absolutos**
- ✅ `setVolumeMax`: "volumen al máximo", "máximo volumen"
- ✅ `setVolumeMin`: "volumen al mínimo", "silencio", "volumen cero"

### **Feature 4.2.3: Porcentajes Específicos**
- ✅ `setVolumePercentage`: "volumen al 50%", "pon el volumen al 30"
- ✅ Parsing con regex (4 patrones diferentes)
- ✅ Validación 0-100%

---

## 📊 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Reconocimiento de Comandos | 5 | 4 | 1 | ~15 min |
| B. Ajuste de Volumen Incremental | 2 | 2 | 0 | ~10 min |
| C. Comandos Absolutos | 3 | 2 | 1 | ~10 min |
| D. Porcentajes Específicos | 3 | 2 | 1 | ~15 min |
| E. Límites de Volumen | 2 | 1 | 1 | ~10 min |
| F. Feedback TTS | 2 | 1 | 1 | ~10 min |
| G. Integración con Sistema Existente | 1 | 1 | 0 | ~5 min |
| **TOTAL** | **18** | **13** | **5** | **~75 min** |

---

## 📂 CATEGORÍA A: RECONOCIMIENTO DE COMANDOS

---

### ✅ TC-VOL-001: Reconocer comando "subir volumen" (con artículos)

**Prioridad:** P0
**Objetivo:** Verificar Feature 4.2.1 - Keywords adicionales con artículos

**Pasos:**
1. Mantener presionado botón y hablar: **"aumentar el volumen"** (con artículo)
2. Soltar y observar
3. Repetir con: **"aumenta el volumen"**
4. Repetir con: **"sube más el volumen"**

**Resultado Esperado:**
- ✅ 3/3 variaciones reconocidas como `CommandType.adjustVolumeUp`
- ✅ TTS anuncia nuevo porcentaje
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.adjustVolumeUp
  [VoiceCommandProvider] Volume increased to: [valor]
  ```

**Criterios de Aceptación:**
- Feature 4.2.1 funciona correctamente
- Artículos "el/la" NO rompen reconocimiento

---

### ✅ TC-VOL-002: Reconocer comando "bajar volumen" (con artículos)

**Prioridad:** P0
**Objetivo:** Verificar Feature 4.2.1 - Keywords adicionales con artículos

**Pasos:**
1. Hablar: **"disminuir el volumen"**
2. Hablar: **"disminuye el volumen"**
3. Hablar: **"baja más el volumen"**

**Resultado Esperado:**
- ✅ 3/3 variaciones reconocidas como `CommandType.adjustVolumeDown`
- ✅ TTS anuncia nuevo porcentaje

---

### ✅ TC-VOL-003: Reconocer comando "volumen al máximo"

**Prioridad:** P0
**Objetivo:** Verificar Feature 4.2.2 - Comandos absolutos

**Pasos:**
1. Hablar: **"volumen al máximo"**
2. Hablar: **"pon el volumen al máximo"**
3. Hablar: **"máximo volumen"**
4. Hablar: **"volumen alto"**

**Resultado Esperado:**
- ✅ 4/4 variaciones reconocidas como `CommandType.setVolumeMax`
- ✅ TTS anuncia: **"Volumen al máximo"**
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.setVolumeMax
  [VoiceCommandProvider] Volume set to maximum: 1.0
  ```

---

### ✅ TC-VOL-004: Reconocer comando "silencio"

**Prioridad:** P0
**Objetivo:** Verificar Feature 4.2.2 - Comandos absolutos (mínimo)

**Pasos:**
1. Hablar: **"silencio"**
2. Hablar: **"silenciar"**
3. Hablar: **"pon en silencio"**
4. Hablar: **"volumen al mínimo"**
5. Hablar: **"volumen cero"**

**Resultado Esperado:**
- ✅ 5/5 variaciones reconocidas como `CommandType.setVolumeMin`
- ✅ TTS intenta anunciar: **"Volumen en silencio"** (inaudible a 0%)
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Volume set to minimum: 0.0
  ```

---

### ✅ TC-VOL-005: Reconocer porcentaje específico

**Prioridad:** P1
**Objetivo:** Verificar Feature 4.2.3 - Parsing con regex

**Pasos:**
1. Hablar: **"pon el volumen al 50"**
2. Hablar: **"volumen al 30 por ciento"**
3. Hablar: **"volumen en 70"**
4. Hablar: **"50 por ciento"**

**Resultado Esperado:**
- ✅ 4/4 variaciones reconocidas como `CommandType.setVolumePercentage`
- ✅ Parámetro `percentage` extraído correctamente: 50, 30, 70, 50
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.setVolumePercentage
  [VoiceCommandProvider] Volume set to percentage: 50% (0.5)
  ```
- ✅ TTS anuncia: "Volumen al 50 por ciento", "Volumen al 30 por ciento", etc.

---

## 📂 CATEGORÍA B: AJUSTE DE VOLUMEN INCREMENTAL

---

### ✅ TC-VOL-006: Incremento de volumen en pasos de 10%

**Prioridad:** P0
**Objetivo:** Verificar que "subir volumen" incrementa exactamente 10%

**Pasos:**
1. Establecer volumen en 60% (usando "volumen al 60")
2. Hablar: "subir volumen"
3. Verificar anuncio: debe ser 70%
4. Repetir 2 veces más

**Resultado Esperado:**
- ✅ 60% → 70% → 80% → 90%
- ✅ Cada incremento exactamente 10%

---

### ✅ TC-VOL-007: Decremento de volumen en pasos de 10%

**Prioridad:** P0
**Objetivo:** Verificar que "bajar volumen" decrementa exactamente 10%

**Pasos:**
1. Establecer volumen en 70%
2. Hablar: "bajar volumen" (3 veces)
3. Verificar: 70% → 60% → 50% → 40%

**Resultado Esperado:**
- ✅ Cada decremento exactamente 10%

---

## 📂 CATEGORÍA C: COMANDOS ABSOLUTOS

---

### ✅ TC-VOL-008: Comando "máximo" establece volumen a 100%

**Prioridad:** P0
**Objetivo:** Verificar que comandos absolutos establecen valor exacto

**Pasos:**
1. Establecer volumen en 50% (usando "volumen al 50")
2. Verificar anuncio: "Volumen al 50 por ciento"
3. Hablar: **"volumen al máximo"**
4. Verificar logs y anuncio

**Resultado Esperado:**
- ✅ Volumen salta directamente de 50% a 100% (no incremental)
- ✅ TTS anuncia: "Volumen al máximo"
- ✅ **En logs:** `Volume set to maximum: 1.0`

---

### ✅ TC-VOL-009: Comando "silencio" establece volumen a 0%

**Prioridad:** P0
**Objetivo:** Verificar que "silencio" establece volumen a 0%

**Pasos:**
1. Establecer volumen en 80%
2. Hablar: **"silencio"**
3. Verificar logs (TTS inaudible)
4. Subir volumen para recuperar: "volumen al 50"

**Resultado Esperado:**
- ✅ Volumen salta directamente de 80% a 0%
- ✅ TTS intenta anunciar pero es inaudible (esperado)
- ✅ **En logs:** `Volume set to minimum: 0.0`
- ✅ Recuperación funciona: "volumen al 50" → audible nuevamente

---

### ✅ TC-VOL-010: Prioridad absolutos > incrementales

**Prioridad:** P1
**Objetivo:** Verificar que comandos absolutos tienen prioridad sobre incrementales

**Pasos:**
1. Hablar: **"subir volumen al máximo"**
   - Contiene "subir volumen" (incremental) + "al máximo" (absoluto)
2. Observar qué comando se ejecuta

**Resultado Esperado:**
- ✅ Comando absoluto tiene prioridad
- ✅ Se ejecuta `setVolumeMax` (no `adjustVolumeUp`)
- ✅ Volumen se establece a 100% (no incremento de 10%)

---

## 📂 CATEGORÍA D: PORCENTAJES ESPECÍFICOS

---

### ✅ TC-VOL-011: Establecer porcentaje específico

**Prioridad:** P0
**Objetivo:** Verificar Feature 4.2.3 - Porcentajes con regex

**Pasos:**
1. Hablar: **"volumen al 50"**
2. Verificar anuncio: "Volumen al 50 por ciento"
3. Hablar: **"pon el volumen al 30"**
4. Verificar anuncio: "Volumen al 30 por ciento"
5. Hablar: **"volumen 80 por ciento"**
6. Verificar anuncio: "Volumen al 80 por ciento"

**Resultado Esperado:**
- ✅ 3/3 comandos ejecutados correctamente
- ✅ Volumen se establece en valor exacto (50%, 30%, 80%)
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Volume set to percentage: 50% (0.5)
  [VoiceCommandProvider] Volume set to percentage: 30% (0.3)
  [VoiceCommandProvider] Volume set to percentage: 80% (0.8)
  ```

---

### ✅ TC-VOL-012: Validación de rango (0-100)

**Prioridad:** P0
**Objetivo:** Verificar que valores fuera de rango se rechazan

**Pasos:**
1. Hablar: **"volumen al 150"** (fuera de rango)
2. Observar comportamiento
3. Hablar: **"volumen al -20"** (negativo)
4. Observar comportamiento

**Resultado Esperado:**
- ✅ Valores > 100 o < 0 NO son reconocidos como `setVolumePercentage`
- ✅ Se parsea como `CommandType.unknown`
- ✅ TTS anuncia: "No entendí el comando. Intenta de nuevo."
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.unknown
  ```

**Nota:** Regex `_parseVolumePercentage()` valida `value >= 0 && value <= 100`

---

### ✅ TC-VOL-013: Prioridad porcentaje > incremental

**Prioridad:** P1
**Objetivo:** Verificar que porcentajes tienen prioridad sobre incrementales

**Pasos:**
1. Hablar: **"subir volumen al 60"**
   - Contiene "subir volumen" (incremental) + "al 60" (porcentaje)
2. Observar qué se ejecuta

**Resultado Esperado:**
- ✅ Porcentaje específico tiene prioridad
- ✅ Se ejecuta `setVolumePercentage` con 60%
- ✅ Volumen se establece a 60% (no incremento)

---

## 📂 CATEGORÍA E: LÍMITES DE VOLUMEN

---

### ✅ TC-VOL-014: Límites con comandos incrementales

**Prioridad:** P0
**Objetivo:** Verificar que límites (0-100%) funcionan con comandos incrementales

**Pasos:**
1. Establecer volumen en 95%
2. Hablar: "subir volumen" (debería llegar a 100%, no 105%)
3. Hablar: "subir volumen" nuevamente (debería mantenerse en 100%)
4. Establecer volumen en 5%
5. Hablar: "bajar volumen" (debería llegar a 0%, no -5%)

**Resultado Esperado:**
- ✅ Volumen se clampea correctamente: `volume.clamp(0.0, 1.0)`
- ✅ TTS anuncia: "Volumen al 100 por ciento" (no "105")
- ✅ TTS anuncia: "Volumen al 0 por ciento" (inaudible)

---

### ✅ TC-VOL-015: Límites con porcentajes específicos

**Prioridad:** P1
**Objetivo:** Verificar que setVolume() clampea valores correctamente

**Pasos:**
1. Mediante código o debugging, intentar establecer volumen > 1.0
2. Verificar que `setVolume()` clampea a 1.0

**Resultado Esperado:**
- ✅ `setVolume(1.5)` → volumen queda en 1.0
- ✅ `setVolume(-0.2)` → volumen queda en 0.0

**Nota:** Este test requiere modificación temporal del código o unit test

---

## 📂 CATEGORÍA F: FEEDBACK TTS

---

### ✅ TC-VOL-016: Anuncio de porcentaje correcto

**Prioridad:** P0
**Objetivo:** Verificar que TTS anuncia el porcentaje exacto en todos los comandos

**Pasos:**
1. Ejecutar cada tipo de comando:
   - "subir volumen" → "Volumen al X por ciento"
   - "bajar volumen" → "Volumen al X por ciento"
   - "volumen al máximo" → "Volumen al máximo"
   - "silencio" → "Volumen en silencio"
   - "volumen al 50" → "Volumen al 50 por ciento"
2. Verificar formato del anuncio

**Resultado Esperado:**
- ✅ Incrementales: Usan `(volume * 100).round()` → porcentaje entero
- ✅ Absolutos: Mensajes específicos ("al máximo", "en silencio")
- ✅ Porcentajes: Usan parámetro `percentage` directamente
- ✅ NO hay decimales: "60 por ciento" (no "0.6" ni "60%")

---

### ✅ TC-VOL-017: Feedback audible a diferentes niveles

**Prioridad:** P1
**Objetivo:** Verificar que cambio de volumen es perceptible

**Pasos:**
1. Establecer volumen en 100%
2. Ejecutar comando de ayuda: "solicitar ayuda"
3. Escuchar volumen de TTS
4. Establecer volumen en 50%
5. Ejecutar comando de ayuda nuevamente
6. Comparar volumen audible

**Resultado Esperado:**
- ✅ A 100%: TTS fuerte y claro
- ✅ A 50%: TTS notablemente más bajo pero comprensible
- ✅ Diferencia es perceptible auditivamente

---

## 📂 CATEGORÍA G: INTEGRACIÓN CON SISTEMA EXISTENTE

---

### ✅ TC-VOL-018: Comandos de volumen no interfieren con comandos existentes

**Prioridad:** P0
**Objetivo:** Verificar que todas las features coexisten correctamente

**Pasos:**
1. Secuencia de comandos mixtos:
   - "volumen al 50"
   - "alto contraste"
   - "volumen al máximo"
   - "solicitar ayuda"
   - (volver a VoiceCommandScreen)
   - "silencio"
   - "volumen al 80"
   - "subir volumen"
   - "cancelar"
2. Verificar que cada comando se ejecuta correctamente

**Resultado Esperado:**
- ✅ 8/8 comandos ejecutados sin conflictos
- ✅ Volumen afecta TODOS los anuncios TTS (incluidos comandos 4.1)
- ✅ Cambios de volumen persisten durante sesión
- ✅ **En logs:** Secuencia completa sin errores

**Criterios de Aceptación:**
- Sin regresiones en comandos 4.1
- Volumen es global para todo el TTS service

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Features | Test Cases | Estado |
|---------------|----------|------------|--------|
| Keywords adicionales (4.2.1) | Artículos "el/la" | TC-VOL-001, TC-VOL-002 | ✅ Cubierta |
| Comandos absolutos (4.2.2) | Máximo, mínimo, silencio | TC-VOL-003, TC-VOL-004, TC-VOL-008, TC-VOL-009, TC-VOL-010 | ✅ Cubierta |
| Porcentajes específicos (4.2.3) | Regex parsing | TC-VOL-005, TC-VOL-011, TC-VOL-012, TC-VOL-013 | ✅ Cubierta |
| Ajuste incremental (4.2 base) | +10%, -10% | TC-VOL-006, TC-VOL-007 | ✅ Cubierta |
| Límites (0-100%) | Clamping | TC-VOL-014, TC-VOL-015 | ✅ Cubierta |
| Feedback TTS | Anuncios | TC-VOL-016, TC-VOL-017 | ✅ Cubierta |
| Integración | Coexistencia | TC-VOL-018 | ✅ Cubierta |

### **Comandos Implementados (Completo)**

| Comando | Variaciones | CommandType | Efecto |
|---------|-------------|-------------|--------|
| **Subir volumen** | "subir volumen", "aumentar el volumen", "más volumen", "sube el volumen" | `adjustVolumeUp` | +10% |
| **Bajar volumen** | "bajar volumen", "disminuir el volumen", "menos volumen", "baja el volumen" | `adjustVolumeDown` | -10% |
| **Volumen máximo** | "volumen al máximo", "máximo volumen", "volumen alto" | `setVolumeMax` | 100% |
| **Silencio** | "silencio", "silenciar", "volumen al mínimo", "volumen cero" | `setVolumeMin` | 0% |
| **Porcentaje específico** | "volumen al 50", "pon el volumen al 30", "volumen 70 por ciento" | `setVolumePercentage` | X% |

### **Patrones de Regex (Feature 4.2.3)**

```dart
// Patrón 1: "volumen al 50", "volumen en 50"
RegExp(r'volumen\s+(?:al|en)\s+(\d+)')

// Patrón 2: "pon el volumen al 50", "pon volumen en 30"
RegExp(r'pon\s+(?:el\s+)?volumen\s+(?:al|en)\s+(\d+)')

// Patrón 3: "volumen 50", "volumen 30 por ciento"
RegExp(r'volumen\s+(\d+)\s*(?:por\s*ciento)?')

// Patrón 4: "50 por ciento"
RegExp(r'(\d+)\s*por\s*ciento')
```

### **Prioridades de Testing**

**P0 (Bloqueantes - 13 test cases):**
- TC-VOL-001, TC-VOL-002 (Keywords 4.2.1)
- TC-VOL-003, TC-VOL-004 (Reconocimiento absolutos)
- TC-VOL-006, TC-VOL-007 (Incrementales)
- TC-VOL-008, TC-VOL-009 (Ejecución absolutos)
- TC-VOL-011, TC-VOL-012 (Porcentajes)
- TC-VOL-014 (Límites)
- TC-VOL-016 (Feedback)
- TC-VOL-018 (Integración)

**P1 (Importantes - 5 test cases):**
- TC-VOL-005 (Reconocimiento porcentajes - variaciones)
- TC-VOL-010 (Prioridad absolutos)
- TC-VOL-013 (Prioridad porcentajes)
- TC-VOL-015 (Límites edge case)
- TC-VOL-017 (Percepción audible)

### **Métricas de Éxito**

Para considerar Features 4.2.1 + 4.2.2 + 4.2.3 **PRODUCTION READY**:
- ✅ 100% de test cases P0 pasan (13/13)
- ✅ ≥ 80% de test cases P1 pasan (≥4/5)
- ✅ Comandos con artículos funcionan (4.2.1)
- ✅ Comandos absolutos establecen valor exacto (4.2.2)
- ✅ Regex extrae porcentajes correctamente 0-100% (4.2.3)
- ✅ Prioridad de parsing es correcta: Absolutos > Porcentajes > Incrementales
- ✅ Límites (0-100%) sin crashes
- ✅ Integración con comandos 4.1 sin conflictos
- ✅ Sin memory leaks en 10+ comandos consecutivos

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Arquitectura Completa**

```
User Voice Input
    ↓
ElevenLabs STT (transcripción)
    ↓
NLPParser.parse()
    ├─ Keywords matching (4.2.1)
    ├─ Absolute commands (4.2.2)
    ├─ Regex percentage (4.2.3)
    └─ Incremental commands
    ↓
VoiceCommandProvider._executeCommand()
    ├─ adjustVolumeUp/Down → increaseVolume()/decreaseVolume()
    ├─ setVolumeMax → setVolume(1.0)
    ├─ setVolumeMin → setVolume(0.0)
    └─ setVolumePercentage → setVolume(percentage / 100.0)
    ↓
TTSService.setVolume(volume.clamp(0.0, 1.0))
    ↓
FlutterTts.setVolume(_currentVolume)
```

### **Orden de Prioridad de Parsing**

```dart
// 1. Cancel (prioridad máxima)
// 2. Contrast
// 3. Volume:
//    3a. Absolute (máximo/mínimo)
//    3b. Percentage (regex)
//    3c. Incremental (subir/bajar)
// 4. Help
// 5. WhatsApp
// 6. Unknown
```

### **Archivos Modificados**

| Archivo | Feature | Cambios |
|---------|---------|---------|
| `lib/models/command.dart` | 4.2.2, 4.2.3 | Agregados `setVolumeMax`, `setVolumeMin`, `setVolumePercentage` |
| `lib/utils/nlp_parser.dart` | 4.2.1, 4.2.2, 4.2.3 | Keywords adicionales + absolutos + método `_parseVolumePercentage()` |
| `lib/providers/voice_command_provider.dart` | 4.2.2, 4.2.3 | Cases para comandos absolutos + porcentajes |
| `lib/screens/voice_command_screen.dart` | UI | 3 items nuevos en lista de comandos |

### **Limitaciones Conocidas**

1. **Volumen NO persiste entre sesiones** (como antes)
2. **A volumen 0%, feedback TTS inaudible** (esperado)
3. **Regex puede fallar con números escritos en texto:**
   - ❌ "volumen al cincuenta" NO funciona (requiere LLM)
   - ✅ "volumen al 50" funciona
4. **Porcentajes solo en español:**
   - ✅ "cincuenta por ciento" NO (text-to-number parsing)
   - ✅ "50 por ciento" SÍ

### **Preparación para LLM (Feature 4.4)**

Cuando se integre LLM:

**LLM reemplazará:**
- Keywords matching → LLM intent detection
- Regex parsing → LLM entity extraction

**LLM emitirá:**
```dart
// Ejemplo output de LLM:
{
  "intent": "setVolumePercentage",
  "entities": {
    "percentage": 50
  }
}
```

**Código actual se reutiliza:**
```dart
// Este código NO CAMBIA:
case CommandType.setVolumePercentage:
  final percentage = command.parameters?['percentage'] as int?;
  await _ttsService.setVolume(percentage / 100.0);
  await _ttsService.speak('Volumen al $percentage por ciento');
  break;
```

✅ **Transición limpia:** Solo cambia el parser, lógica de ejecución intacta.

---

## 🚀 PRÓXIMOS PASOS

### **Si todos los P0 pasan:**
1. ✅ Features 4.2.1 + 4.2.2 + 4.2.3 listas para producción
2. Documentar en CHANGELOG.md
3. Crear PR con resumen de features
4. Planificar Feature 4.4 (LLM Integration)

### **Si hay fallos:**
1. Documentar fallos específicos
2. Priorizar según criticidad
3. Fix + re-test

---

**Versión:** 2.0.0 (Completo)
**Última actualización:** 23 ene 2026
**Features:** 4.2.1 (Keywords) + 4.2.2 (Absolutos) + 4.2.3 (Porcentajes)
**Stack:** Flutter + ElevenLabs STT + flutter_tts + Provider
**Regex:** 4 patrones para extracción de porcentajes
