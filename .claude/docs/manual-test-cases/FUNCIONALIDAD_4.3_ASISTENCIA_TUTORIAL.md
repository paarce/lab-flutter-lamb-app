# 📋 MANUAL TEST CASES - Funcionalidad 4.3: Assistance Actions (Tutorial y Lista de Comandos)

**Versión:** 1.0.0
**Funcionalidad:** Comandos de voz para tutorial y lista de comandos disponibles
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 11 (8 P0 + 3 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Reconocimiento de Comandos](#-categoría-a-reconocimiento-de-comandos)
- [B. Ejecución de Tutorial](#-categoría-b-ejecución-de-tutorial)
- [C. Ejecución de Lista de Comandos](#-categoría-c-ejecución-de-lista-de-comandos)
- [D. Prioridades y Conflictos](#-categoría-d-prioridades-y-conflictos)
- [E. Accesibilidad (TalkBack)](#-categoría-e-accesibilidad-talkback)
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
- ✅ Feature 4.1 (Voice Command Infrastructure) funcionando correctamente
- ✅ Feature 4.2 (Control de Volumen) funcionando correctamente
- ✅ Sin sesiones de voz activas previas

### **Permisos del Sistema:**
- ✅ Permiso de micrófono otorgado (Settings → Apps → Lamb → Permissions → Microphone: Allow)
- ✅ Permiso de internet otorgado (automático)

### **Comandos Previos Implementados:**
```
✅ "Solicitar ayuda" (Feature 4.1)
✅ "Alto contraste" (Feature 4.1)
✅ "Subir volumen" / "Bajar volumen" (Feature 4.2)
✅ "Volumen al máximo" / "Silencio" (Feature 4.2)
✅ "Volumen al 50%" (Feature 4.2)
✅ "Cancelar" (Feature 4.1)
```

---

## 🚀 SETUP DE PRUEBAS

### **Navegación a VoiceCommandScreen:**

```bash
# Terminal 1 - Ejecutar app
cd /path/to/lamb
flutter run

# 1. En HomeScreen, tap en "Comandos de Voz"
# 2. Verificar que VoiceCommandScreen se abre
# 3. Verificar lista de comandos disponibles incluye:
#    - "Tutorial"
#    - "Comandos disponibles"
```

### **Verificación de Setup:**

1. Abrir app
2. Navegar a `VoiceCommandScreen`
3. Verificar que en la lista de comandos disponibles se ve:
   - ✅ "Tutorial" → "Escucha una guía de uso de la app"
   - ✅ "Comandos disponibles" → "Lista todos los comandos por voz"
4. Tap en botón "Mantén presionado para hablar"
5. Verificar que listening se inicia correctamente

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Reconocimiento de Comandos | 4 | 3 | 1 | ~15 min |
| B. Ejecución de Tutorial | 3 | 2 | 1 | ~10 min |
| C. Ejecución de Lista de Comandos | 2 | 2 | 0 | ~10 min |
| D. Prioridades y Conflictos | 1 | 1 | 0 | ~5 min |
| E. Accesibilidad (TalkBack) | 1 | 0 | 1 | ~10 min |
| **TOTAL** | **11** | **8** | **3** | **~50 min** |

---

## 📂 CATEGORÍA A: RECONOCIMIENTO DE COMANDOS

**Prerequisitos específicos:** Listening activo, Feature 4.1 funcionando

---

### ✅ TC-ASSIST-001: Reconocer comando "tutorial" (variación estándar)

**Prioridad:** P0
**Objetivo:** Verificar que el NLPParser reconoce correctamente la keyword "tutorial"

**Pasos:**
1. Iniciar listening (mantener presionado botón)
2. Hablar claramente: "tutorial"
3. Soltar botón
4. Observar transcripción y logs

**Resultado Esperado:**
- ✅ Transcripción muestra: "tutorial"
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.playTutorial
  [VoiceCommandProvider] Playing tutorial
  ```
- ✅ Estado cambia a "Procesando comando..."
- ✅ TTS comienza a reproducir el tutorial
- ✅ Sin errores en consola

**Criterios de Aceptación:**
- Reconocimiento exitoso en < 500ms
- Parsing correcto del comando
- TTS inicia reproducción

---

### ✅ TC-ASSIST-002: Reconocer variaciones de "tutorial"

**Prioridad:** P0
**Objetivo:** Verificar que todas las variaciones del comando tutorial se reconocen

**Pasos:**
1. **Intento 1:** Hablar "guía"
2. Esperar que termine el TTS
3. **Intento 2:** Hablar "instrucciones"
4. Esperar que termine el TTS
5. **Intento 3:** Hablar "cómo usar"
6. Esperar que termine el TTS
7. **Intento 4:** Hablar "explícame"

**Resultado Esperado (para cada intento):**
- ✅ Transcripción correcta del texto hablado
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.playTutorial
  ```
- ✅ TTS reproduce el tutorial completo
- ✅ 4/4 variaciones reconocidas correctamente

**Criterios de Aceptación:**
- 100% de variaciones reconocidas
- Parsing consistente
- Sin falsos positivos

---

### ✅ TC-ASSIST-003: Reconocer comando "comandos disponibles"

**Prioridad:** P0
**Objetivo:** Verificar que el comando "comandos disponibles" se reconoce correctamente

**Pasos:**
1. Iniciar listening
2. **Intento 1:** Hablar "comandos disponibles"
3. Esperar que termine el TTS
4. **Intento 2:** Hablar "qué puedo decir"
5. Esperar que termine el TTS
6. **Intento 3:** Hablar "qué comandos hay"
7. Esperar que termine el TTS
8. **Intento 4:** Hablar "lista de comandos"

**Resultado Esperado (para cada intento):**
- ✅ Transcripción correcta
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.listCommands
  [VoiceCommandProvider] Listing available commands
  ```
- ✅ TTS reproduce lista completa de comandos
- ✅ 4/4 variaciones reconocidas

**Criterios de Aceptación:**
- Reconocimiento exitoso de todas las variaciones
- Lista de comandos completa y correcta
- TTS claro y comprensible

---

### ✅ TC-ASSIST-004: Reconocer keyword "comandos" sola

**Prioridad:** P1
**Objetivo:** Verificar que la keyword corta "comandos" también activa el comando

**Pasos:**
1. Iniciar listening
2. Hablar solo: "comandos"
3. Observar comportamiento

**Resultado Esperado:**
- ✅ Reconoce como `CommandType.listCommands`
- ✅ TTS reproduce lista de comandos
- ✅ **En logs:** Parsed command: CommandType.listCommands

**Criterios de Aceptación:**
- Keyword corta funciona correctamente
- Sin confusión con otros comandos

---

## 📂 CATEGORÍA B: EJECUCIÓN DE TUTORIAL

**Prerequisitos específicos:** Comando "tutorial" reconocido exitosamente

---

### ✅ TC-ASSIST-005: Tutorial reproduce contenido completo

**Prioridad:** P0
**Objetivo:** Verificar que el tutorial reproduce TODO el contenido esperado

**Pasos:**
1. Iniciar listening
2. Hablar: "tutorial"
3. Escuchar COMPLETO el mensaje TTS (NO interrumpir)
4. Cronometrar duración
5. Anotar contenido escuchado

**Resultado Esperado:**
- ✅ TTS reproduce el siguiente contenido en orden:
  1. "Bienvenido al tutorial de la aplicación"
  2. "Esta app te ayuda a comunicarte con tu familia y recibir asistencia remota"
  3. "Los comandos principales son:"
  4. "Primero: Di solicitar ayuda para que un familiar se conecte a tu pantalla"
  5. "Segundo: Di abrir WhatsApp para abrir la aplicación de mensajes"
  6. "Tercero: Di alto contraste para cambiar los colores de la pantalla"
  7. "Cuarto: Di subir volumen o bajar volumen para ajustar el sonido"
  8. "Quinto: Di comandos disponibles para escuchar esta lista nuevamente"
  9. "Para cancelar, di cancelar en cualquier momento"
  10. "Fin del tutorial"

- ✅ Duración total: ~30-40 segundos
- ✅ Voz clara y comprensible (motor nativo flutter_tts)
- ✅ Velocidad normal (speed: 1.0)
- ✅ Sin cortes ni interrupciones
- ✅ Estado vuelve a idle al terminar

**Criterios de Aceptación:**
- 100% del contenido se reproduce
- Audio claro y comprensible
- Sin cortes técnicos
- Timing consistente

---

### ✅ TC-ASSIST-006: Tutorial usa configuración TTS correcta

**Prioridad:** P0
**Objetivo:** Verificar que el tutorial usa la configuración de TTS del usuario

**Prerequisitos adicionales:**
- Volumen TTS ajustado a 50% (usar comando "volumen al 50%")

**Pasos:**
1. Iniciar listening
2. Hablar: "volumen al cincuenta por ciento"
3. Esperar confirmación
4. Iniciar listening nuevamente
5. Hablar: "tutorial"
6. Escuchar el tutorial
7. Observar volumen de reproducción

**Resultado Esperado:**
- ✅ Tutorial se reproduce al volumen configurado (50%)
- ✅ NO se reproduce al volumen máximo por defecto
- ✅ Configuración de volumen persiste entre comandos
- ✅ Idioma: español (es-ES)
- ✅ Pitch: 1.0
- ✅ Speed: 1.0

**Criterios de Aceptación:**
- Respeta configuración de volumen del usuario
- Usa configuración global de TTSConfig
- Sin override de parámetros

---

### ✅ TC-ASSIST-007: Tutorial puede ejecutarse múltiples veces

**Prioridad:** P1
**Objetivo:** Verificar que el tutorial puede ejecutarse consecutivamente sin errores

**Pasos:**
1. Hablar: "tutorial"
2. Escuchar completo
3. Inmediatamente después que termina, hablar nuevamente: "tutorial"
4. Escuchar completo
5. Repetir una vez más (total 3 ejecuciones)

**Resultado Esperado:**
- ✅ 3/3 ejecuciones exitosas
- ✅ Contenido idéntico en cada ejecución
- ✅ Sin degradación de performance
- ✅ Sin memory leaks (verificar en Android Studio Profiler si disponible)
- ✅ Duración consistente (~30-40s cada vez)

**Criterios de Aceptación:**
- 100% de ejecuciones exitosas
- Performance estable
- Sin errores en logs

---

## 📂 CATEGORÍA C: EJECUCIÓN DE LISTA DE COMANDOS

**Prerequisitos específicos:** Comando "comandos disponibles" reconocido

---

### ✅ TC-ASSIST-008: Lista de comandos reproduce contenido completo

**Prioridad:** P0
**Objetivo:** Verificar que la lista de comandos incluye TODOS los comandos implementados

**Pasos:**
1. Iniciar listening
2. Hablar: "comandos disponibles"
3. Escuchar COMPLETO el mensaje TTS
4. Cronometrar duración
5. Anotar comandos mencionados

**Resultado Esperado:**
- ✅ TTS reproduce el siguiente contenido en orden:
  1. "Los comandos disponibles son:"
  2. "Solicitar ayuda: Genera un código para que tu familiar se conecte"
  3. "Abrir WhatsApp: Abre la aplicación de mensajes"
  4. "Alto contraste: Cambia el tema de colores"
  5. "Subir volumen o bajar volumen: Ajusta el sonido"
  6. "Volumen al máximo o silencio: Establece el volumen"
  7. "Volumen al cincuenta por ciento: Establece un nivel específico"
  8. "Tutorial: Escucha una guía sobre cómo usar la app"
  9. "Cancelar: Detiene el reconocimiento de voz"

- ✅ Duración total: ~20-25 segundos
- ✅ Todos los comandos implementados hasta Feature 4.3 están incluidos
- ✅ Descripciones claras y comprensibles
- ✅ Sin comandos duplicados
- ✅ Sin comandos faltantes

**Criterios de Aceptación:**
- 9/9 comandos mencionados
- Descripciones precisas
- Orden lógico
- Voz clara

---

### ✅ TC-ASSIST-009: Lista de comandos es consistente con UI

**Prioridad:** P0
**Objetivo:** Verificar que los comandos mencionados por TTS coinciden con la lista visible en UI

**Pasos:**
1. En `VoiceCommandScreen`, observar lista de comandos en pantalla
2. Contar comandos visibles
3. Iniciar listening
4. Hablar: "comandos disponibles"
5. Escuchar lista completa
6. Comparar comandos TTS vs UI

**Resultado Esperado:**
- ✅ Cantidad de comandos TTS = Cantidad de comandos UI
- ✅ Cada comando en TTS tiene correspondencia en UI:
  - UI: "Solicitar ayuda" ↔ TTS: "Solicitar ayuda: Genera un código..."
  - UI: "Abrir WhatsApp" ↔ TTS: "Abrir WhatsApp: Abre la aplicación..."
  - UI: "Cambiar contraste" ↔ TTS: "Alto contraste: Cambia el tema..."
  - UI: "Subir volumen" ↔ TTS: "Subir volumen o bajar volumen: Ajusta..."
  - UI: "Volumen al máximo" ↔ TTS: "Volumen al máximo o silencio: Establece..."
  - UI: "Volumen al 50%" ↔ TTS: "Volumen al cincuenta por ciento: Establece..."
  - UI: "Tutorial" ↔ TTS: "Tutorial: Escucha una guía..."
  - UI: "Comandos disponibles" ↔ TTS: (implícito - es el comando actual)
  - UI: "Cancelar" ↔ TTS: "Cancelar: Detiene..."

**Criterios de Aceptación:**
- 100% de consistencia TTS ↔ UI
- Sin comandos "ocultos" solo en TTS
- Sin comandos "ocultos" solo en UI

---

## 📂 CATEGORÍA D: PRIORIDADES Y CONFLICTOS

**Prerequisitos específicos:** Todos los comandos funcionando

---

### ✅ TC-ASSIST-010: No hay conflicto entre "ayuda" y "tutorial"

**Prioridad:** P0
**Objetivo:** Verificar que "ayuda" y "tutorial" son comandos distintos y no se confunden

**Pasos:**
1. **Test 1: Comando "ayuda" solo**
   - Iniciar listening
   - Hablar: "ayuda"
   - Observar resultado

2. **Test 2: Comando "solicitar ayuda"**
   - Iniciar listening
   - Hablar: "solicitar ayuda"
   - Observar resultado

3. **Test 3: Comando "tutorial"**
   - Iniciar listening
   - Hablar: "tutorial"
   - Observar resultado

4. **Test 4: Comando "ayuda tutorial" (mixto)**
   - Iniciar listening
   - Hablar: "ayuda tutorial"
   - Observar cuál tiene prioridad

**Resultado Esperado:**

**Test 1 - "ayuda":**
- ✅ Reconoce como `CommandType.requestHelp`
- ✅ TTS: "Generando código de sesión para ayuda remota"
- ✅ Navega a RemoteControlHostScreen

**Test 2 - "solicitar ayuda":**
- ✅ Reconoce como `CommandType.requestHelp`
- ✅ Mismo comportamiento que Test 1

**Test 3 - "tutorial":**
- ✅ Reconoce como `CommandType.playTutorial`
- ✅ TTS reproduce tutorial completo
- ✅ NO navega a RemoteControlHostScreen

**Test 4 - "ayuda tutorial" (mixto):**
- ✅ Prioridad: `playTutorial` (prioridad 4) > `requestHelp` (prioridad 6)
- ✅ Reconoce como `CommandType.playTutorial`
- ✅ **En logs:**
  ```
  [VoiceCommandProvider] Parsed command: CommandType.playTutorial
  ```

**Criterios de Aceptación:**
- No hay ambigüedad entre comandos
- Prioridades funcionan correctamente según `nlp_parser.dart`
- Comandos "ayuda" y "tutorial" son completamente distintos

---

## 📂 CATEGORÍA E: ACCESIBILIDAD (TALKBACK)

**Prerequisitos específicos:** TalkBack activado

---

### ✅ TC-ASSIST-011: Tutorial y Lista accesibles con TalkBack

**Prioridad:** P1
**Objetivo:** Verificar que los nuevos comandos son accesibles con TalkBack

**Prerequisitos adicionales:**
- TalkBack activado: Settings → Accessibility → TalkBack → ON
- Usuario familiarizado con gestos de TalkBack

**Pasos:**
1. Con TalkBack activo, navegar a `VoiceCommandScreen`
2. Swipe hasta encontrar "Tutorial" en lista de comandos
3. Verificar anuncio de TalkBack
4. Swipe hasta encontrar "Comandos disponibles" en lista
5. Verificar anuncio de TalkBack
6. Iniciar listening (doble tap en botón)
7. Hablar: "tutorial"
8. Escuchar feedback combinado TalkBack + TTS

**Resultado Esperado:**

**Elemento "Tutorial" en lista:**
- ✅ TalkBack anuncia: "Tutorial. Escucha una guía de uso de la app"
- ✅ Navegable con swipe derecha/izquierda

**Elemento "Comandos disponibles" en lista:**
- ✅ TalkBack anuncia: "Comandos disponibles. Lista todos los comandos por voz"
- ✅ Navegable con swipe derecha/izquierda

**Durante ejecución de tutorial:**
- ✅ TTS del tutorial se reproduce SIN interferencia de TalkBack
- ✅ TalkBack NO interrumpe el tutorial
- ✅ Usuario puede escuchar contenido completo

**Durante ejecución de lista:**
- ✅ TTS de lista se reproduce sin interferencia
- ✅ Contenido se escucha completo

**Criterios de Aceptación:**
- 100% navegable con TalkBack
- Nuevos elementos tienen Semantics correctos
- TTS de comandos NO interfiere con TalkBack
- Feedback combinado es comprensible

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Test Cases | Estado |
|---------------|------------|--------|
| Reconocimiento "tutorial" | TC-ASSIST-001, TC-ASSIST-002 | ✅ Cubierta |
| Reconocimiento "comandos disponibles" | TC-ASSIST-003, TC-ASSIST-004 | ✅ Cubierta |
| Ejecución de tutorial | TC-ASSIST-005, TC-ASSIST-006, TC-ASSIST-007 | ✅ Cubierta |
| Ejecución de lista de comandos | TC-ASSIST-008, TC-ASSIST-009 | ✅ Cubierta |
| Prioridades y conflictos | TC-ASSIST-010 | ✅ Cubierta |
| Accesibilidad (TalkBack) | TC-ASSIST-011 | ✅ Cubierta |

### **Comandos Nuevos (Feature 4.3)**

| Comando | Variaciones | Test Case | Estado |
|---------|-------------|-----------|--------|
| **Tutorial** | "tutorial", "guía", "instrucciones", "cómo usar", "explícame" | TC-ASSIST-001, TC-ASSIST-002 | ✅ Implementado |
| **Comandos disponibles** | "comandos disponibles", "qué puedo decir", "qué comandos hay", "lista de comandos", "comandos" | TC-ASSIST-003, TC-ASSIST-004 | ✅ Implementado |

### **Contenido del Tutorial (Verificación)**

**Secciones obligatorias:**
- ✅ Bienvenida
- ✅ Propósito de la app
- ✅ Lista de comandos principales (5 comandos)
- ✅ Instrucción de cancelación
- ✅ Cierre

**Duración esperada:** 30-40 segundos

### **Contenido de Lista de Comandos (Verificación)**

**Comandos mencionados (9 total):**
1. ✅ Solicitar ayuda
2. ✅ Abrir WhatsApp
3. ✅ Alto contraste
4. ✅ Subir/Bajar volumen
5. ✅ Volumen al máximo/silencio
6. ✅ Volumen al porcentaje
7. ✅ Tutorial
8. ✅ Cancelar

**Duración esperada:** 20-25 segundos

### **Prioridades de Testing**

**P0 (Bloqueantes - Deben pasar antes de release):**
- TC-ASSIST-001, TC-ASSIST-002 (Reconocimiento tutorial)
- TC-ASSIST-003 (Reconocimiento lista comandos)
- TC-ASSIST-005, TC-ASSIST-006 (Ejecución tutorial)
- TC-ASSIST-008, TC-ASSIST-009 (Ejecución lista comandos)
- TC-ASSIST-010 (Conflictos)

**P1 (Importantes - Pueden ser hotfixed):**
- TC-ASSIST-004 (Keyword corta "comandos")
- TC-ASSIST-007 (Ejecuciones múltiples)
- TC-ASSIST-011 (TalkBack)

### **Métricas de Éxito**

Para considerar Feature 4.3 **PRODUCTION READY**:
- ✅ 100% de test cases P0 pasan
- ✅ ≥ 80% de test cases P1 pasan
- ✅ Tutorial reproduce contenido completo sin cortes
- ✅ Lista de comandos incluye 100% de comandos implementados
- ✅ Sin conflicto entre "ayuda" y "tutorial"
- ✅ TTS usa configuración correcta (volumen, idioma, velocidad)
- ✅ Accesible con TalkBack (TC-ASSIST-011 pasa)
- ✅ Sin memory leaks en ejecuciones múltiples

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Decisiones de Diseño**

1. **TTS Dinámico vs Audio Assets:**
   - Implementado con TTS dinámico (flutter_tts)
   - Ventaja: Fácil de actualizar cuando se agregan comandos
   - Desventaja: Voz sintetizada (menos natural que voz humana)
   - **Mejora futura:** Audio assets pregrabados en v1.1

2. **Duración del Tutorial:**
   - Tutorial: ~30-40 segundos
   - Lista: ~20-25 segundos
   - Usuario NO puede cancelar por voz durante TTS (solo con botón UI)
   - **Mejora futura:** Permitir "cancelar" durante TTS en v1.1

3. **Actualización de Contenido:**
   - Contenido hardcoded en métodos `_playTutorial()` y `_listAvailableCommands()`
   - Debe actualizarse manualmente cuando se agregan nuevos comandos
   - **Mejora futura:** Generación dinámica basada en CommandTypes habilitados

### **Limitaciones Conocidas**

1. **No se puede cancelar durante TTS:**
   - Durante reproducción del tutorial o lista, "cancelar" no funciona
   - Usuario debe esperar a que termine o usar botón de UI
   - **Razón:** TTS no está en modo listening

2. **Contenido estático:**
   - Si se agrega un nuevo comando en Feature 5+, hay que actualizar manualmente:
     - `_listAvailableCommands()` en voice_command_provider.dart
     - `_buildCommandsHelp()` en voice_command_screen.dart

3. **Sin soporte multilingüe:**
   - Tutorial y lista solo en español
   - **Mejora futura:** Detección de idioma en v1.1

### **Debugging Tips**

**Logs para Tutorial:**
```bash
# Ver logs de tutorial
flutter logs | grep "Playing tutorial"

# Verificar que TTS se ejecuta
flutter logs | grep "TTSService"
```

**Logs para Lista de Comandos:**
```bash
# Ver logs de lista
flutter logs | grep "Listing available commands"
```

**Verificar contenido TTS:**
```dart
// En voice_command_provider.dart, agregar logs temporales
developer.log('Tutorial content: $tutorial', name: 'VoiceCommandProvider');
developer.log('Commands list: $commands', name: 'VoiceCommandProvider');
```

### **Errores Comunes y Soluciones**

| Error | Causa | Solución |
|-------|-------|----------|
| Tutorial no se escucha | Volumen TTS en 0% | Ajustar con "volumen al 50%" |
| Tutorial cortado | Interrupción prematura | Verificar que no hay timeout activo |
| Lista de comandos incompleta | Contenido desactualizado | Actualizar método `_listAvailableCommands()` |
| "ayuda" activa tutorial | Conflicto de keywords | Verificar prioridades en nlp_parser.dart |
| TalkBack interrumpe tutorial | Configuración incorrecta | Ajustar settings de TalkBack |

---

## 🚀 PRÓXIMOS PASOS (Post-Testing)

### **Si todos los P0 pasan:**
1. ✅ Feature 4.3 completada
2. Proceder con Feature 4.4 (LLM Integration) o Feature 5 (WhatsApp Integration)
3. Considerar mejoras de UX (audio assets pregrabados)

### **Si hay fallos:**
1. Documentar fallos específicos
2. Priorizar según criticidad (P0 > P1)
3. Fix + re-test
4. Actualizar este documento con notas

### **Mejoras Futuras (v1.1):**
- [ ] Audio assets pregrabados con voz humana
- [ ] Tutorial interactivo paso a paso (con pausas)
- [ ] Permitir "cancelar" durante TTS
- [ ] Generación dinámica de lista de comandos
- [ ] Comando "repetir" para escuchar último mensaje
- [ ] Soporte multilingüe (español/inglés)

---

## 📋 CHECKLIST DE RELEASE

Antes de considerar Feature 4.3 completa:

**Código:**
- [ ] `lib/models/command.dart` incluye `playTutorial` y `listCommands`
- [ ] `lib/utils/nlp_parser.dart` incluye keywords completas
- [ ] `lib/providers/voice_command_provider.dart` implementa `_playTutorial()` y `_listAvailableCommands()`
- [ ] `lib/screens/voice_command_screen.dart` muestra nuevos comandos en UI

**Testing:**
- [ ] 100% test cases P0 pasan
- [ ] ≥ 80% test cases P1 pasan
- [ ] Testing manual en dispositivo físico completado
- [ ] Testing con TalkBack completado

**Documentación:**
- [ ] Este archivo actualizado con resultados de testing
- [ ] Logs de testing guardados
- [ ] Screenshots de UI con nuevos comandos (opcional)

**Git:**
- [ ] Commit creado con mensaje descriptivo
- [ ] Branch actualizado
- [ ] Sin conflictos con main

---

**Versión:** 1.0.0
**Fecha de creación:** 23 ene 2026
**Última actualización:** 23 ene 2026
**Autor:** Claude (Feature 4.3 Implementation)
**Stack:** Flutter + ElevenLabs STT + flutter_tts + Provider + NLPParser
**Comandos totales:** 9 (después de Feature 4.3)
