# 📋 MANUAL TEST CASES - Funcionalidad 2.1: Cliente WebRTC (Flutter Web)

**Versión:** 1.0.0
**Funcionalidad:** Cliente web para visualización remota y control táctil
**Plataforma:** Web (Chrome, Firefox, Safari, Edge)
**Total Test Cases:** 12 (8 P0 + 4 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Setup de Pruebas](#-setup-de-pruebas)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Conexión y Signaling](#-categoría-a-conexión-y-signaling)
- [B. Video Streaming](#-categoría-b-video-streaming)
- [C. Control Táctil](#-categoría-c-control-táctil)
- [D. Manejo de Errores](#-categoría-d-manejo-de-errores)
- [E. Desconexión y Cleanup](#-categoría-e-desconexión-y-cleanup)
- [Resumen de Cobertura](#-resumen-de-cobertura)

---

## 🔧 PREREQUISITOS GLOBALES

Estos prerequisitos aplican para **TODOS** los test cases a menos que se indique lo contrario:

### **Configuración del Entorno:**
- ✅ Navegador web moderno (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+)
- ✅ Conexión a internet activa (WiFi o ethernet)
- ✅ Firebase configurado correctamente en `web/firebase-config.js` con credenciales válidas
- ✅ Host Android con sesión remota activa (ver [Setup de Pruebas](#-setup-de-pruebas))
- ✅ Dispositivo Android y computadora en misma red (preferible para mejor latencia)
- ✅ JavaScript habilitado en el navegador
- ✅ Permisos del navegador: No se requieren permisos especiales (cliente solo recibe video)

### **Estado Inicial del Cliente Web:**
- ✅ Cliente web ejecutándose localmente o desde hosting
- ✅ Usuario está en `ClientConnectScreen` (pantalla de ingreso de código)
- ✅ Sin conexiones WebRTC activas previas
- ✅ Cache del navegador limpio (recomendado)

### **Estado del Host (Android):**
- ✅ App Android con sesión remota activa (ver TC-HP-001 en FUNCIONALIDAD_2_WEBRTC_CONTROL_REMOTO.md)
- ✅ Código de sesión de 6 dígitos generado
- ✅ Estado: "Esperando conexión..."
- ✅ Pantalla del dispositivo visible (no bloqueada)

---

## 🚀 SETUP DE PRUEBAS

### **Opción 1: Desarrollo Local**

#### Terminal 1 - Host Android
```bash
cd /path/to/lamb
flutter run
# Seguir pasos de TC-HP-001 para iniciar sesión remota
# Anotar el código de 6 dígitos generado
```

#### Terminal 2 - Cliente Web
```bash
cd /path/to/lamb
flutter run -d chrome --web-renderer html
# O para otros navegadores:
# flutter run -d edge
# flutter run -d firefox
```

**Nota:** El flag `--web-renderer html` es importante para compatibilidad con WebRTC en algunos navegadores.

### **Opción 2: Build de Producción**

```bash
# Build del cliente web
flutter build web --release

# Servir localmente con servidor simple
cd build/web
python3 -m http.server 8080

# Abrir en navegador: http://localhost:8080
```

### **Opción 3: Firebase Hosting (Post-Deploy)**

```bash
# Acceder a URL de producción
https://lamb-remote.web.app
```

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Conexión y Signaling | 3 | 3 | 0 | ~15 min |
| B. Video Streaming | 3 | 2 | 1 | ~10 min |
| C. Control Táctil | 2 | 1 | 1 | ~10 min |
| D. Manejo de Errores | 2 | 1 | 1 | ~10 min |
| E. Desconexión y Cleanup | 2 | 1 | 1 | ~10 min |
| **TOTAL** | **12** | **8** | **4** | **~55 min** |

---

## 📂 CATEGORÍA A: CONEXIÓN Y SIGNALING

**Prerequisitos específicos:** Host Android con sesión activa

---

### ✅ TC-CLIENT-001: Conectar con código válido

**Prioridad:** P0
**Objetivo:** Verificar que el cliente puede conectarse al host usando un código de 6 dígitos válido

**Prerequisitos adicionales:**
- Host Android ejecutando con sesión remota activa
- Código de sesión válido anotado (ej: "234567")

**Pasos:**
1. Abrir cliente web en navegador
2. Verificar que se muestra pantalla `ClientConnectScreen` con título "Control Remoto - Cliente"
3. Observar campo de entrada de código vacío con placeholder "234567"
4. Ingresar código válido de 6 dígitos (ej: "234567")
5. Observar que botón "Conectar" se habilita
6. Tocar botón "Conectar"
7. Observar indicador de carga (spinner)

**Resultado Esperado:**
- ✅ Campo de entrada solo acepta dígitos del 2 al 9
- ✅ Código se muestra en formato grande (56sp) con espaciado
- ✅ Botón "Conectar" está deshabilitado hasta ingresar 6 dígitos
- ✅ Al tocar "Conectar", aparece spinner blanco en el botón
- ✅ Navegación automática a `ClientViewerScreen` después de 2-5 segundos
- ✅ Badge de estado en pantalla muestra "Conectando..." → "Conectado"
- ✅ **En host:** Estado cambia de "Esperando conexión..." a "Sesión activa"
- ✅ **En logs Flutter:** Se observan mensajes de WebRTC:
  ```
  🔵 [RemoteViewer] connectToSession: Starting connection to 234567
  🔵 [WebRTCClient] joinSession: Fetching session...
  🔵 [WebRTCClient] joinSession: Creating peer connection...
  ✅ [WebRTCClient] Connection state: connected
  ```

**Criterios de Aceptación:**
- Tiempo de conexión < 10 segundos desde que se toca "Conectar"
- Sin errores en consola del navegador
- Conexión WebRTC exitosa (RTCPeerConnectionState.connected)

---

### ✅ TC-CLIENT-002: Validación de formato de código

**Prioridad:** P0
**Objetivo:** Verificar que el campo de código solo acepta formato válido (6 dígitos, 2-9)

**Pasos:**
1. Abrir cliente web en navegador
2. En `ClientConnectScreen`, intentar ingresar diferentes valores en el campo de código:
   - Intentar ingresar letra "a" → **Bloqueado**
   - Intentar ingresar dígito "0" → **Bloqueado**
   - Intentar ingresar dígito "1" → **Bloqueado**
   - Ingresar dígitos válidos "234" → **Permitido**
   - Intentar ingresar más de 6 dígitos "2345678" → **Bloqueado en 6to dígito**
3. Ingresar solo 5 dígitos "23456"
4. Observar estado del botón "Conectar"

**Resultado Esperado:**
- ✅ Solo se permiten dígitos del 2 al 9
- ✅ Máximo 6 caracteres permitidos
- ✅ Botón "Conectar" permanece deshabilitado con menos de 6 dígitos
- ✅ Texto del botón es legible (28sp, alto contraste)
- ✅ Campo tiene foco automático al cargar la pantalla

**Criterios de Aceptación:**
- Validación funciona en todos los navegadores soportados
- Accesibilidad: Campo tiene label "Código de sesión" para screen readers

---

### ✅ TC-CLIENT-003: Reconexión automática tras pérdida temporal de red

**Prioridad:** P0
**Objetivo:** Verificar que el cliente intenta reconectar si la red se interrumpe brevemente

**Prerequisitos adicionales:**
- Cliente conectado exitosamente (completar TC-CLIENT-001)
- Acceso a configuración de red del dispositivo

**Pasos:**
1. Completar TC-CLIENT-001 (conectar exitosamente)
2. Observar video streaming activo
3. Deshabilitar WiFi/ethernet del dispositivo durante 5 segundos
4. Observar badge de estado en `ClientViewerScreen`
5. Rehabilitar WiFi/ethernet
6. Esperar 10 segundos

**Resultado Esperado:**
- ✅ Al perder red, badge cambia a "Reconectando..." (color naranja)
- ✅ Video se congela pero no crashea la app
- ✅ Al recuperar red, conexión se restablece automáticamente
- ✅ Badge vuelve a "Conectado" (color verde)
- ✅ Video streaming se reanuda
- ✅ **En logs:** Se observan mensajes de ICE reconnection

**Criterios de Aceptación:**
- Tiempo de reconexión < 15 segundos tras recuperar red
- No se requiere reingresar código
- No hay memory leaks (verificar en DevTools)

---

## 📂 CATEGORÍA B: VIDEO STREAMING

**Prerequisitos específicos:** Cliente conectado exitosamente al host

---

### ✅ TC-CLIENT-004: Visualización de video en tiempo real

**Prioridad:** P0
**Objetivo:** Verificar que el video del host se muestra correctamente en el cliente

**Prerequisitos adicionales:**
- Cliente conectado exitosamente (TC-CLIENT-001 completado)
- Host Android mostrando pantalla con contenido reconocible (ej: home screen con íconos)

**Pasos:**
1. Completar TC-CLIENT-001 (conectar exitosamente)
2. En `ClientViewerScreen`, observar el área de video (RTCVideoRenderer)
3. En host Android, mover elementos en pantalla (abrir app drawer, abrir WhatsApp, etc.)
4. Observar video en cliente web

**Resultado Esperado:**
- ✅ Video se muestra en fullscreen (ocupa toda la pantalla del navegador)
- ✅ Aspecto ratio correcto (sin distorsión, video mantiene proporciones originales)
- ✅ Latencia visual < 2 segundos (mover elemento en host → visible en cliente)
- ✅ Video no está pixelado excesivamente (calidad razonable)
- ✅ Framerate estable (~15-30 FPS, sin congelamiento)
- ✅ Si host tiene aspecto 19.5:9 y cliente 16:9, se muestra letterbox (barras negras arriba/abajo o lados)

**Criterios de Aceptación:**
- Video es reconocible y útil para asistencia remota
- No hay tearing ni artifacts severos
- Colores son representativos (no invertidos, no escala de grises involuntaria)

---

### ✅ TC-CLIENT-005: Adaptación a diferentes tamaños de ventana

**Prioridad:** P1
**Objetivo:** Verificar que el video se adapta correctamente al redimensionar la ventana del navegador

**Prerequisitos adicionales:**
- Cliente conectado con video streaming activo

**Pasos:**
1. Completar TC-CLIENT-004 (video visible)
2. Redimensionar ventana del navegador a diferentes tamaños:
   - Pantalla completa (F11)
   - Ventana maximizada
   - Ventana de 1280x720
   - Ventana de 800x600
   - Ventana muy estrecha (400px ancho)
3. Observar cómo se adapta el video en cada tamaño

**Resultado Esperado:**
- ✅ Video siempre mantiene aspecto ratio correcto
- ✅ RTCVideoRenderer se ajusta al tamaño disponible
- ✅ Letterbox aparece cuando es necesario
- ✅ Botones de UI (Disconnect, Status badge) siguen visibles y accesibles
- ✅ No hay overflow horizontal ni vertical (sin scrollbars)

**Criterios de Aceptación:**
- Funciona en tamaños de ventana desde 400px hasta 4K
- Responsive en todos los breakpoints

---

### ✅ TC-CLIENT-006: Calidad de video estable durante 5 minutos

**Prioridad:** P1
**Objetivo:** Verificar que el streaming de video es estable durante uso prolongado

**Prerequisitos adicionales:**
- Cliente conectado con video streaming activo
- Timer para medir 5 minutos

**Pasos:**
1. Completar TC-CLIENT-001 (conectar exitosamente)
2. Dejar cliente web abierto con video visible
3. En host, realizar actividades normales (navegar apps, abrir WhatsApp, escribir mensaje)
4. Observar video durante 5 minutos continuos

**Resultado Esperado:**
- ✅ Video se mantiene estable sin congelamiento
- ✅ No hay degradación progresiva de calidad
- ✅ Latencia se mantiene constante (< 2 segundos)
- ✅ No hay memory leaks (uso de RAM estable en DevTools → Performance Monitor)
- ✅ CPU del cliente < 50% (verificar en DevTools o Task Manager)
- ✅ Badge de estado permanece en "Conectado"

**Criterios de Aceptación:**
- 5 minutos continuos sin desconexión
- Uso de RAM < 500MB en navegador
- No warnings ni errors en consola del navegador

---

## 📂 CATEGORÍA C: CONTROL TÁCTIL

**Prerequisitos específicos:** Cliente conectado con video activo

---

### ✅ TC-CLIENT-007: Enviar tap simple en video

**Prioridad:** P0
**Objetivo:** Verificar que el cliente puede enviar eventos de tap al host y que se ejecutan correctamente

**Prerequisitos adicionales:**
- Cliente conectado con video activo
- Host Android mostrando pantalla home con íconos reconocibles
- Coordenadas del ícono de WhatsApp visibles en video del cliente

**Pasos:**
1. Completar TC-CLIENT-004 (video visible)
2. En video del cliente, identificar la ubicación del ícono de WhatsApp en el host
3. Dar tap en el video exactamente sobre el ícono de WhatsApp
4. Observar respuesta en host Android

**Resultado Esperado:**
- ✅ **En cliente:** No hay feedback visual inmediato (solo cursor normal)
- ✅ **En host:** WhatsApp se abre (simula tap real) en < 500ms
- ✅ **En logs Flutter (webrtc_service.dart):**
  ```
  🟢 [WebRTCService] _onDataChannelMessage: Received message
  🟢 [WebRTCService] _onDataChannelMessage: Touch at (0.5, 0.3)
  🟢 [WebRTCService] _handleRemoteTap: Pixel coordinates: (540, 702)
  ✅ [WebRTCService] _simulateTap: Platform channel call successful
  ```
- ✅ **En logs Kotlin (MainActivity.kt):**
  ```
  D/MainActivity: Simulate tap requested at: (540.0, 702.0)
  ```
- ✅ Tap se ejecuta en la posición correcta del host (no desplazado)

**Criterios de Aceptación:**
- Precisión del tap: margen de error < 50px en pantalla del host
- Latencia tap → ejecución < 500ms
- Coordenadas normalizadas correctas (0.0-1.0 range)

**Nota:** Si el tap no funciona, verificar que:
- Data channel está abierto (logs de WebRTCClient)
- Platform channel está configurado correctamente en MainActivity.kt
- AccessibilityService está habilitado (para implementación futura de tap real)

---

### ✅ TC-CLIENT-008: Múltiples taps consecutivos

**Prioridad:** P1
**Objetivo:** Verificar que el cliente puede enviar múltiples taps consecutivos sin perder precisión

**Prerequisitos adicionales:**
- TC-CLIENT-007 completado exitosamente

**Pasos:**
1. Completar TC-CLIENT-007
2. En video del cliente, dar tap en 5 ubicaciones diferentes rápidamente:
   - Tap 1: Esquina superior izquierda
   - Tap 2: Esquina superior derecha
   - Tap 3: Centro de la pantalla
   - Tap 4: Esquina inferior izquierda
   - Tap 5: Esquina inferior derecha
3. Observar logs en ambos lados

**Resultado Esperado:**
- ✅ Todos los taps se registran en el host (5/5 exitosos)
- ✅ Orden de taps se mantiene correcto
- ✅ Coordenadas de cada tap son precisas (< 50px error)
- ✅ No hay throttling excesivo (todos los taps se procesan)
- ✅ Data channel no se satura (queue no crece indefinidamente)
- ✅ **En logs:** 5 mensajes de `_onDataChannelMessage` consecutivos

**Criterios de Aceptación:**
- 100% de taps exitosos (5/5)
- Latencia promedio < 500ms por tap
- Sin congelamiento del video durante taps

---

## 📂 CATEGORÍA D: MANEJO DE ERRORES

**Prerequisitos específicos:** Ninguno adicional

---

### ✅ TC-CLIENT-009: Código de sesión inválido

**Prioridad:** P0
**Objetivo:** Verificar que el cliente maneja correctamente códigos inválidos o inexistentes

**Pasos:**
1. Abrir cliente web en navegador
2. En `ClientConnectScreen`, ingresar código inexistente: "999999"
3. Tocar botón "Conectar"
4. Observar respuesta del sistema

**Resultado Esperado:**
- ✅ Botón muestra spinner durante 2-5 segundos
- ✅ Aparece card de error rojo en pantalla con ícono de warning
- ✅ Mensaje de error: "No se encontró la sesión. Verifica el código." (user-friendly)
- ✅ Cliente permanece en `ClientConnectScreen` (no navega)
- ✅ Campo de código se limpia automáticamente (opcional) o se mantiene para re-intentar
- ✅ Botón "Conectar" vuelve a habilitarse para retry
- ✅ **En logs:**
  ```
  🔴 [RemoteViewer] connectToSession: Exception caught: No se encontró la sesión
  🔴 [RemoteViewer] connectToSession: Running cleanup...
  ```

**Criterios de Aceptación:**
- Error es user-friendly (no "Exception: null" ni stack traces)
- Usuario puede reintentar inmediatamente
- No hay memory leaks tras error (cleanup correcto)

---

### ✅ TC-CLIENT-010: Sesión expirada durante conexión

**Prioridad:** P1
**Objetivo:** Verificar que el cliente maneja correctamente cuando el host termina la sesión mientras el cliente está conectado

**Prerequisitos adicionales:**
- Cliente conectado exitosamente (TC-CLIENT-001 completado)
- Acceso al dispositivo Android del host

**Pasos:**
1. Completar TC-CLIENT-001 (conectar exitosamente)
2. Observar video streaming activo en `ClientViewerScreen`
3. **En host Android:** Tocar botón "Terminar Sesión" en `RemoteControlHostScreen`
4. Observar comportamiento del cliente web

**Resultado Esperado:**
- ✅ Video se detiene (última frame visible o pantalla negra)
- ✅ Badge de estado cambia a "Desconectado" (color gris)
- ✅ Aparece card de error en la parte inferior: "El host terminó la sesión"
- ✅ Después de 2 segundos, navegación automática a `ClientConnectScreen`
- ✅ Campo de código en `ClientConnectScreen` está vacío (listo para nueva sesión)
- ✅ **En logs:**
  ```
  🔴 [RemoteViewer] Session ended or expired
  🔵 [RemoteViewer] Status changed: disconnected
  ✅ [RemoteViewer] _cleanup: Resources cleaned up
  ```

**Criterios de Aceptación:**
- Cleanup completo (no memory leaks, peer connection cerrada)
- Navegación automática sin intervención del usuario
- Cliente listo para nueva conexión inmediatamente

---

## 📂 CATEGORÍA E: DESCONEXIÓN Y CLEANUP

**Prerequisitos específicos:** Cliente conectado exitosamente

---

### ✅ TC-CLIENT-011: Desconexión manual del cliente

**Prioridad:** P0
**Objetivo:** Verificar que el cliente puede desconectarse manualmente y liberar recursos correctamente

**Prerequisitos adicionales:**
- Cliente conectado con video activo

**Pasos:**
1. Completar TC-CLIENT-001 (conectar exitosamente)
2. Observar video streaming activo
3. En `ClientViewerScreen`, tocar botón rojo "Desconectar" (X) en la esquina superior derecha
4. Observar diálogo de confirmación
5. Tocar "Desconectar" en el diálogo

**Resultado Esperado:**
- ✅ Aparece diálogo modal: "¿Terminar sesión? ¿Estás seguro de que quieres desconectar?"
- ✅ Diálogo tiene 2 botones: "Cancelar" y "Desconectar" (rojo)
- ✅ Al tocar "Desconectar", video se detiene
- ✅ Navegación inmediata a `ClientConnectScreen`
- ✅ **En host:** Estado vuelve a "Esperando conexión..." (sesión sigue activa)
- ✅ **En logs del cliente:**
  ```
  🔵 [RemoteViewer] disconnect: Disconnecting from session...
  🔵 [RemoteViewer] _cleanup: Cleaning up resources...
  ✅ [RemoteViewer] disconnect: Disconnected successfully
  ```
- ✅ **En logs del host:** No cambia (sesión sigue activa para otros clientes)

**Criterios de Aceptación:**
- Cleanup completo (peer connection cerrada, streams liberados)
- Host puede aceptar nueva conexión inmediatamente
- Cliente puede reconectar con el mismo código si es válido

---

### ✅ TC-CLIENT-012: Cerrar pestaña del navegador durante sesión activa

**Prioridad:** P1
**Objetivo:** Verificar que cerrar la pestaña/navegador libera recursos correctamente

**Prerequisitos adicionales:**
- Cliente conectado con video activo

**Pasos:**
1. Completar TC-CLIENT-001 (conectar exitosamente)
2. Observar video streaming activo
3. Cerrar pestaña del navegador (Ctrl+W o botón X)
4. Esperar 5 segundos
5. **En host:** Observar estado de la sesión

**Resultado Esperado:**
- ✅ Navegador cierra pestaña sin warnings
- ✅ **En host:** Después de ~10-30 segundos, estado vuelve a "Esperando conexión..." (timeout de ICE)
- ✅ **En logs del host:** Se detecta desconexión del peer:
  ```
  🔵 [WebRTCService] Connection state changed: failed/closed
  ```
- ✅ Host puede aceptar nueva conexión sin reiniciar sesión

**Criterios de Aceptación:**
- No hay memory leaks en el navegador (verificar con DevTools antes de cerrar)
- Host detecta desconexión en tiempo razonable (< 60 segundos)
- Sesión del host sigue activa (no se termina automáticamente)

---

## 📊 RESUMEN DE COBERTURA

### **Cobertura de Funcionalidades**

| Funcionalidad | Test Cases | Estado |
|---------------|------------|--------|
| Conexión WebRTC vía código | TC-CLIENT-001, TC-CLIENT-002, TC-CLIENT-003 | ✅ Cubierta |
| Video streaming en tiempo real | TC-CLIENT-004, TC-CLIENT-005, TC-CLIENT-006 | ✅ Cubierta |
| Control táctil remoto | TC-CLIENT-007, TC-CLIENT-008 | ✅ Cubierta |
| Manejo de errores | TC-CLIENT-009, TC-CLIENT-010 | ✅ Cubierta |
| Desconexión y cleanup | TC-CLIENT-011, TC-CLIENT-012 | ✅ Cubierta |

### **Cobertura de Navegadores**

Ejecutar TODOS los test cases en:
- ✅ **Chrome** (90+) - Navegador principal recomendado
- ✅ **Firefox** (88+) - Soporte completo de WebRTC
- ✅ **Edge** (90+) - Basado en Chromium
- ⚠️ **Safari** (14+) - Verificar especialmente, puede tener limitaciones en WebRTC

### **Prioridades de Testing**

**P0 (Bloqueantes - Deben pasar antes de release):**
- TC-CLIENT-001, TC-CLIENT-002, TC-CLIENT-003 (Conexión)
- TC-CLIENT-004 (Video)
- TC-CLIENT-007 (Touch control)
- TC-CLIENT-009 (Error handling)
- TC-CLIENT-011 (Desconexión)

**P1 (Importantes - Pueden ser hotfixed):**
- TC-CLIENT-005, TC-CLIENT-006 (Video avanzado)
- TC-CLIENT-008 (Touch avanzado)
- TC-CLIENT-010 (Error avanzado)
- TC-CLIENT-012 (Edge case)

### **Métricas de Éxito**

Para considerar el cliente web **PRODUCTION READY**:
- ✅ 100% de test cases P0 pasan en Chrome, Firefox, Edge
- ✅ ≥ 80% de test cases P1 pasan en Chrome, Firefox, Edge
- ✅ ≥ 60% de test cases pasan en Safari (conocido por limitaciones WebRTC)
- ✅ Latencia promedio video < 2 segundos
- ✅ Latencia promedio touch < 500ms
- ✅ Tiempo de conexión < 10 segundos
- ✅ Sin memory leaks en sesiones de 5+ minutos

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### **Limitaciones Conocidas (MVP)**

1. **Touch control limitado:**
   - Solo tap simple implementado
   - No soporta: scroll, long press, multi-touch, gestures complejos
   - Mejora futura: Ver plan post-MVP en documento principal

2. **Resolución hardcodeada:**
   - Host usa resolución fija 1080x2340 para conversión de coordenadas
   - Mejora futura: Obtener resolución real desde MediaProjection

3. **AccessibilityService no implementado:**
   - Platform Channel configurado pero tap simulation pendiente
   - Actualmente solo logea el tap, no ejecuta acción real
   - Implementación completa requiere AccessibilityService (fase futura)

4. **Sin TURN servers:**
   - Solo P2P con STUN servers de Google
   - Puede fallar en redes corporativas con firewalls estrictos
   - Mejora futura: Agregar TURN servers para NAT traversal completo

### **Debugging Tips**

**Cliente Web (Navegador):**
```javascript
// Abrir DevTools (F12) y ejecutar en consola:
// Ver estado de conexión WebRTC
console.log(peerConnection.connectionState);

// Ver ICE candidates
peerConnection.onicecandidate = (e) => console.log('ICE:', e.candidate);

// Ver tracks de video
peerConnection.ontrack = (e) => console.log('Track:', e.track, e.streams);
```

**Host Android (Flutter):**
```bash
# Filtrar logs relevantes
flutter logs | grep -E "\[WebRTC\]|\[RemoteControl\]|\[Firebase\]"

# Ver solo errores
flutter logs | grep "🔴"
```

**Firestore (Firebase Console):**
- Ir a Firestore → Collections → `remote_sessions/{sessionCode}`
- Verificar campos: `offerSdp`, `answerSdp`, `hostIceCandidates`, `clientIceCandidates`
- Estado debe ser: `waiting` → `connecting` → `connected`

---

**Versión:** 1.0.0
**Última actualización:** 9 ene 2026
**Autor:** Claude (Implementation Phase 5)
**Stack:** Flutter Web + WebRTC + Firebase Firestore
