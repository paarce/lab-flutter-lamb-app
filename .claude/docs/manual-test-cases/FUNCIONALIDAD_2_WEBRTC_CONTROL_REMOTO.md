# 📋 MANUAL TEST CASES - Funcionalidad 2: WebRTC Control Remoto (Servidor/Host)

**Versión:** 1.0.0
**Funcionalidad:** Control remoto vía WebRTC + Firebase (Solo servidor/adulto mayor)
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 43 (15 P0 + 28 P1)

---

## 📖 TABLA DE CONTENIDOS

- [Prerequisitos Globales](#-prerequisitos-globales)
- [Categorías de Test Cases](#-categorías-de-test-cases)
- [A. Happy Path](#-categoría-a-happy-path-flujo-normal)
- [B. Permisos y Configuración](#-categoría-b-permisos-y-configuración)
- [C. Estados de Conexión](#-categoría-c-estados-de-conexión)
- [D. Accesibilidad (TalkBack)](#-categoría-d-accesibilidad-talkback)
- [E. Manejo de Errores](#-categoría-e-manejo-de-errores)
- [F. Edge Cases](#-categoría-f-edge-cases)
- [G. Performance](#-categoría-g-performance)
- [H. Seguridad y Timeout](#-categoría-h-seguridad-y-timeout)
- [Resumen de Cobertura](#-resumen-de-cobertura)

---

## 🔧 PREREQUISITOS GLOBALES

Estos prerequisitos aplican para **TODOS** los test cases a menos que se indique lo contrario:

### **Configuración del Entorno:**
- ✅ Android device/emulator con Android 7.0+ (API 24+)
- ✅ App instalada desde `flutter run` o APK debug (ver [README - Ejecutar la App](../../../README.md#4-ejecutar-la-app))
- ✅ Conexión a internet activa (WiFi o datos móviles)
- ✅ Firebase configurado correctamente (google-services.json en su lugar)
- ✅ API key de ElevenLabs válida en `lib/config/secrets.dart`
- ✅ Espacio en storage > 100MB libre
- ✅ Batería > 20%

### **Estado Inicial de la App:**
- ✅ App recién abierta (estado limpio)
- ✅ No hay sesiones remotas activas previas
- ✅ Usuario está en la pantalla `HomeScreen`
- ✅ TalkBack **desactivado** (excepto en test cases de accesibilidad que lo indiquen)

### **Datos de Prueba:**
- Usuario ficticio: "Adulto Mayor de Prueba"
- Device ID: Generado automáticamente por la app

---

## 🎯 CATEGORÍAS DE TEST CASES

| Categoría | Total | P0 | P1 | Tiempo Estimado |
|-----------|-------|----|----|-----------------|
| A. Happy Path (Flujo Normal) | 8 | 3 | 5 | ~30 min |
| B. Permisos y Configuración | 4 | 2 | 2 | ~15 min |
| C. Estados de Conexión | 5 | 2 | 3 | ~20 min |
| D. Accesibilidad (TalkBack) | 10 | 3 | 7 | ~45 min |
| E. Manejo de Errores | 6 | 2 | 4 | ~25 min |
| F. Edge Cases | 4 | 1 | 3 | ~30 min |
| G. Performance | 4 | 0 | 4 | ~20 min |
| H. Seguridad y Timeout | 2 | 2 | 0 | ~20 min |
| **TOTAL** | **43** | **15** | **28** | **~3 horas** |

---

## 📂 CATEGORÍA A: HAPPY PATH (Flujo Normal)

**Prerequisitos específicos:** Ninguno adicional

---

### ✅ TC-HP-001: Iniciar sesión remota exitosamente
**Prioridad:** P0
**Objetivo:** Verificar que el usuario puede generar un código de sesión sin errores

**Pasos:**
1. En `HomeScreen`, tocar botón "Control Remoto"
2. En `RemoteControlHostScreen`, verificar que el estado inicial es "Sin sesión activa"
3. Tocar botón "Iniciar Sesión Remota"
4. Observar diálogo de carga "Iniciando sesión..."
5. Esperar respuesta del sistema

**Resultado Esperado:**
- ✅ Aparece dialog de permiso de captura de pantalla del sistema Android
- ✅ Al aceptar permiso, dialog de carga desaparece
- ✅ Aparece código de sesión de 6 dígitos en pantalla
- ✅ Estado cambia a "Esperando conexión..."
- ✅ Snackbar verde muestra "Sesión iniciada: [código]"
- ✅ Botón cambia de "Iniciar Sesión Remota" a "Terminar Sesión"
- ✅ Notificación persistente "Sesión Remota Activa" aparece en barra de estado

---

### ✅ TC-HP-002: Visualizar código de sesión de 6 dígitos
**Prioridad:** P0
**Objetivo:** Verificar que el código se muestra correctamente con formato accesible

**Pasos:**
1. Completar TC-HP-001 (tener sesión activa)
2. Observar el widget `SessionCodeDisplay` en pantalla

**Resultado Esperado:**
- ✅ Código tiene exactamente 6 dígitos numéricos
- ✅ Formato visual: "XXX XXX" (con espacio en el medio)
- ✅ Texto es extra grande (visible desde 1 metro de distancia)
- ✅ Card tiene borde azul de 3px
- ✅ Título "Código de Sesión" aparece arriba del código
- ✅ Botón "Copiar código" con ícono está debajo del código
- ✅ Card instrucciones "Comparte este código con tu familiar..." está visible

---

### ✅ TC-HP-003: Copiar código de sesión al portapapeles
**Prioridad:** P1
**Objetivo:** Verificar funcionalidad de copiar código

**Pasos:**
1. Completar TC-HP-002 (código visible en pantalla)
2. Anotar el código mostrado (ej: "234 567")
3. Tocar botón "Copiar código"
4. Abrir cualquier app de texto (notas, WhatsApp, etc.)
5. Realizar "Pegar" desde el portapapeles

**Resultado Esperado:**
- ✅ Snackbar verde aparece: "Código copiado: 234567"
- ✅ Al pegar, el texto es "234567" (sin espacios)
- ✅ Snackbar desaparece automáticamente después de 2 segundos

---

### ✅ TC-HP-004: Escuchar anuncio de código con TTS
**Prioridad:** P0
**Objetivo:** Verificar que ElevenLabs TTS anuncia el código correctamente

**Prerequisito adicional:** Volumen del dispositivo > 50%

**Pasos:**
1. Asegurar volumen multimedia > 50%
2. Completar TC-HP-001 (iniciar sesión)
3. Escuchar el audio que reproduce la app automáticamente

**Resultado Esperado:**
- ✅ Voz femenina/masculina en español reproduce: "Sesión remota iniciada. Código: 2, 3, 4, 5, 6, 7. Comparte este código con tu familiar para que se conecte."
- ✅ Cada dígito se pronuncia individualmente con pausa de ~0.5 segundos
- ✅ Audio es claro y sin distorsión
- ✅ Si hay error de TTS, la app NO crashea (solo no reproduce audio)

---

### ✅ TC-HP-005: Ver cambios de estado en tiempo real
**Prioridad:** P1
**Objetivo:** Verificar que el indicador de estado actualiza correctamente

**Pasos:**
1. En `HomeScreen`, tocar "Control Remoto"
2. Observar indicador de estado inicial
3. Tocar "Iniciar Sesión Remota"
4. Observar cambios de estado durante el proceso

**Resultado Esperado:**
- **Estado 1 (inicial):**
  - Ícono: ⚙️ "Sin sesión activa"
  - Color: Gris claro
- **Estado 2 (solicitando permiso):**
  - Ícono: 🔒 "Solicitando permisos..."
  - Color: Naranja claro
  - Loading indicator visible
- **Estado 3 (creando sesión):**
  - Ícono: ⚙️ "Creando sesión..."
  - Color: Azul claro
  - Loading indicator visible
- **Estado 4 (esperando cliente):**
  - Ícono: ⏳ "Esperando conexión..."
  - Color: Amarillo/ámbar claro
  - Loading indicator visible
- ✅ Cada cambio de estado tiene animación suave
- ✅ Texto e ícono cambian simultáneamente

---

### ✅ TC-HP-006: Terminar sesión remota manualmente
**Prioridad:** P0
**Objetivo:** Verificar que el usuario puede cancelar la sesión en cualquier momento

**Pasos:**
1. Completar TC-HP-001 (tener sesión activa)
2. Tocar botón rojo "Terminar Sesión"
3. Observar diálogo de confirmación
4. Tocar "Terminar" en el diálogo

**Resultado Esperado:**
- ✅ Dialog aparece con título "¿Terminar sesión?"
- ✅ Mensaje: "Se cerrará la conexión con tu familiar y dejarás de compartir tu pantalla."
- ✅ Dos botones: "Cancelar" (gris) y "Terminar" (rojo)
- ✅ Al tocar "Terminar":
  - Dialog se cierra
  - Código de sesión desaparece
  - Estado cambia a "Sesión terminada"
  - Snackbar gris: "Sesión terminada"
  - Botón vuelve a "Iniciar Sesión Remota"
  - Notificación de foreground desaparece

---

### ✅ TC-HP-007: Confirmar diálogo de terminación de sesión
**Prioridad:** P1
**Objetivo:** Verificar que el botón "Cancelar" funciona correctamente

**Pasos:**
1. Completar TC-HP-001 (tener sesión activa)
2. Tocar botón "Terminar Sesión"
3. En el diálogo, tocar "Cancelar"

**Resultado Esperado:**
- ✅ Dialog se cierra
- ✅ Sesión sigue activa (código visible)
- ✅ Estado sigue siendo "Esperando conexión..."
- ✅ Botón sigue mostrando "Terminar Sesión"
- ✅ No aparece ningún snackbar

---

### ✅ TC-HP-008: Navegar desde home a Control Remoto
**Prioridad:** P1
**Objetivo:** Verificar navegación básica

**Pasos:**
1. Estar en `HomeScreen`
2. Observar los tres botones disponibles
3. Tocar botón "Control Remoto" (tercero, con ícono 📺)

**Resultado Esperado:**
- ✅ Navegación a `RemoteControlHostScreen` exitosa
- ✅ AppBar muestra título "Control Remoto"
- ✅ Botón "Back" (←) visible en AppBar
- ✅ Al tocar "Back", regresa a `HomeScreen`

---

## 📂 CATEGORÍA B: PERMISOS Y CONFIGURACIÓN

**Prerequisitos específicos:**
- Para tests de denegación de permisos: Resetear permisos de la app desde Settings antes de cada test

---

### ✅ TC-PERM-002: Aceptar permiso de captura de pantalla
**Prioridad:** P0
**Objetivo:** Verificar flujo cuando el usuario acepta el permiso

**Pasos:**
1. En `RemoteControlHostScreen`, tocar "Iniciar Sesión Remota"
2. Observar dialog del sistema Android
3. Leer el mensaje del dialog (debería mencionar "screen casting" o "captura de pantalla")
4. Tocar botón "Start now" / "Iniciar ahora"

**Resultado Esperado:**
- ✅ Dialog del sistema tiene título "Screen recording permission" o similar
- ✅ Ícono de la app aparece en el dialog
- ✅ Al aceptar, dialog se cierra inmediatamente
- ✅ App continúa con creación de sesión
- ✅ Código de sesión aparece en <5 segundos
- ✅ No aparece ningún mensaje de error

---

### ✅ TC-PERM-003: Denegar permiso de captura de pantalla
**Prioridad:** P0
**Objetivo:** Verificar manejo de error cuando se niega el permiso

**Pasos:**
1. En `RemoteControlHostScreen`, tocar "Iniciar Sesión Remota"
2. En dialog del sistema, tocar "Cancel" / "Cancelar"

**Resultado Esperado:**
- ✅ Dialog se cierra
- ✅ Card rojo de error aparece con ícono ⚠️
- ✅ Mensaje de error: "Permiso de captura de pantalla denegado"
- ✅ Estado cambia a "Error de conexión"
- ✅ TTS anuncia: "Ocurrió un error. Permiso de captura de pantalla denegado"
- ✅ Botón sigue siendo "Iniciar Sesión Remota" (permite reintentar)
- ✅ No hay código de sesión visible

---

### ✅ TC-PERM-004: Verificar notificación de foreground service activa
**Prioridad:** P1
**Objetivo:** Verificar que la notificación persistente aparece

**Pasos:**
1. Completar TC-HP-001 (iniciar sesión exitosamente)
2. Deslizar barra de notificaciones hacia abajo
3. Buscar notificación de la app

**Resultado Esperado:**
- ✅ Notificación con título "Sesión Remota Activa"
- ✅ Texto: "Tu familiar puede ver tu pantalla"
- ✅ Ícono de la app (o ícono genérico de información)
- ✅ Notificación NO es dismissible (no se puede deslizar para eliminar)
- ✅ Al terminar sesión, notificación desaparece automáticamente

---

### ✅ TC-PERM-005: Reintentar después de denegar permiso
**Prioridad:** P1
**Objetivo:** Verificar que el usuario puede reintentar

**Pasos:**
1. Completar TC-PERM-003 (denegar permiso)
2. Esperar 2 segundos
3. Tocar nuevamente "Iniciar Sesión Remota"
4. Esta vez, aceptar el permiso

**Resultado Esperado:**
- ✅ Dialog del sistema aparece nuevamente
- ✅ Al aceptar, sesión se crea exitosamente
- ✅ Error anterior desaparece
- ✅ Código de sesión aparece normalmente

---

## 📂 CATEGORÍA C: ESTADOS DE CONEXIÓN

**Prerequisitos específicos:** Ninguno adicional

---

### ✅ TC-CONN-001: Estado "Esperando conexión" después de generar código
**Prioridad:** P0
**Objetivo:** Verificar estado inicial de sesión activa

**Pasos:**
1. Completar TC-HP-001 (iniciar sesión)
2. Observar indicador de estado

**Resultado Esperado:**
- ✅ Indicador muestra ícono ⏳
- ✅ Texto: "Esperando conexión..."
- ✅ Color de fondo: Amarillo/ámbar claro (#FFF8E1)
- ✅ Borde: Amarillo oscuro (#FFA000)
- ✅ Loading indicator (spinner) visible rotando
- ✅ TTS anuncia: "Sesión remota iniciada. Código: [dígitos]. Comparte este código con tu familiar para que se conecte."

---

### ✅ TC-CONN-002: Estado "Conectando" cuando cliente se une
**Prioridad:** P1
**Objetivo:** Verificar transición de estado cuando cliente inicia conexión

**Prerequisito adicional:** Cliente (app del familiar) debe conectarse con el código

**Nota:** Este test requiere implementación del cliente, por ahora solo verificar preparación

**Pasos:**
1. Tener sesión activa (TC-HP-001)
2. Simular evento de cliente conectándose (verificar en logs de Firebase)

**Resultado Esperado (cuando cliente esté implementado):**
- ✅ Indicador muestra ícono 🔄
- ✅ Texto: "Conectando..."
- ✅ Color: Azul claro (#E3F2FD)
- ✅ Loading indicator visible
- ✅ TTS anuncia: "Tu familiar se está conectando"

---

### ✅ TC-CONN-003: Estado "Conectado" cuando WebRTC se establece
**Prioridad:** P1
**Objetivo:** Verificar estado de conexión exitosa

**Prerequisito adicional:** Requiere cliente conectado

**Nota:** Este test requiere implementación del cliente

**Resultado Esperado (cuando cliente esté implementado):**
- ✅ Indicador muestra ícono ✅
- ✅ Texto: "Conectado - Compartiendo pantalla"
- ✅ Color: Verde claro (#E8F5E9)
- ✅ Loading indicator NO visible
- ✅ TTS anuncia: "Conectado. Tu familiar ahora puede ver tu pantalla y ayudarte."

---

### ✅ TC-CONN-004: Estado "Terminado" después de cancelar
**Prioridad:** P0
**Objetivo:** Verificar estado final

**Pasos:**
1. Completar TC-HP-006 (terminar sesión)
2. Observar indicador de estado

**Resultado Esperado:**
- ✅ Indicador muestra ícono ✓
- ✅ Texto: "Sesión terminada"
- ✅ Color: Gris claro (#F5F5F5)
- ✅ Loading indicator NO visible
- ✅ TTS anuncia: "Sesión remota terminada. Gracias por usar el servicio."
- ✅ Código de sesión NO visible

---

### ✅ TC-CONN-005: Estado "Error" cuando conexión falla
**Prioridad:** P1
**Objetivo:** Verificar manejo de errores de conexión

**Pasos:**
1. Desactivar WiFi y datos móviles
2. Intentar iniciar sesión remota

**Resultado Esperado:**
- ✅ Indicador muestra ícono ⚠️
- ✅ Texto: "Error de conexión"
- ✅ Color: Rojo claro (#FFEBEE)
- ✅ Card de error visible con mensaje específico
- ✅ TTS anuncia: "Ocurrió un error. [mensaje específico]"

---

## 📂 CATEGORÍA D: ACCESIBILIDAD (TalkBack)

**Prerequisitos específicos:**
- ✅ TalkBack activado: Settings → Accessibility → TalkBack → ON
- ✅ Velocidad de TalkBack en configuración normal (no acelerada)
- ✅ Audífonos conectados (para testing más preciso)

**Nota:** Para estos tests, la navegación se hace SOLO con gestos de TalkBack (sin mirar pantalla idealmente)

---

### ✅ TC-ACC-001: Navegar con TalkBack desde home a Control Remoto
**Prioridad:** P0
**Objetivo:** Verificar navegación completa con TalkBack

**Pasos:**
1. Activar TalkBack
2. En `HomeScreen`, colocar dedo en cualquier parte de la pantalla
3. Deslizar hacia la derecha repetidamente hasta llegar al botón "Control Remoto"
4. Esperar anuncio de TalkBack
5. Hacer doble tap para activar

**Resultado Esperado:**
- ✅ TalkBack anuncia elementos en orden:
  1. "Bienvenido, Encabezado"
  2. "Selecciona una opción para comenzar"
  3. "Comandos de voz, Botón, Deshabilitado, Toca dos veces para usar comandos de voz"
  4. "WhatsApp, Botón, Deshabilitado, Toca dos veces para abrir asistente de WhatsApp"
  5. **"Control remoto, Botón, Toca dos veces para iniciar control remoto con tu familiar"**
- ✅ Al hacer doble tap en "Control remoto", navega correctamente
- ✅ TalkBack anuncia "Control Remoto" (título de nueva pantalla)

---

### ✅ TC-ACC-002: Botón "Iniciar Sesión" tiene semantic label correcto
**Prioridad:** P1
**Objetivo:** Verificar accesibilidad del botón principal

**Pasos:**
1. Con TalkBack activado, estar en `RemoteControlHostScreen`
2. Navegar con swipe derecha hasta el botón
3. Escuchar anuncio completo

**Resultado Esperado:**
- ✅ TalkBack anuncia: "Iniciar Sesión Remota, Botón, Toca dos veces para generar un código y permitir que tu familiar se conecte"
- ✅ Anuncio es claro y completo
- ✅ Se identifica como "Botón"
- ✅ Hint es informativo

---

### ✅ TC-ACC-003: Código de sesión es anunciado dígito por dígito
**Prioridad:** P0
**Objetivo:** Verificar que el código es comprensible auditivamente

**Pasos:**
1. Con TalkBack activado, iniciar sesión remota
2. Esperar anuncio del código por TTS de ElevenLabs
3. Navegar con TalkBack al widget del código
4. Escuchar anuncio de TalkBack

**Resultado Esperado:**
- ✅ **ElevenLabs TTS** anuncia: "Sesión remota iniciada. Código: 2, 3, 4, 5, 6, 7. Comparte este código..."
- ✅ **TalkBack** al navegar al código anuncia: "Código de sesión: 2, 3, 4, 5, 6, 7, Comparte este código con tu familiar para que se conecte"
- ✅ Cada dígito se pronuncia por separado con pausas claras
- ✅ No se confunden números (ej: "cincuenta y seis" vs "cinco, seis")

---

### ✅ TC-ACC-004: Botón "Terminar Sesión" tiene semantic label correcto
**Prioridad:** P1
**Objetivo:** Verificar accesibilidad del botón de cancelar

**Pasos:**
1. Con TalkBack activado, tener sesión activa
2. Navegar hasta botón rojo
3. Escuchar anuncio

**Resultado Esperado:**
- ✅ TalkBack anuncia: "Terminar Sesión, Botón, Toca dos veces para terminar la sesión remota y dejar de compartir tu pantalla"
- ✅ Tono de voz indica que es acción destructiva (TalkBack puede cambiar tono)

---

### ✅ TC-ACC-005: Indicador de estado es anunciado automáticamente (liveRegion)
**Prioridad:** P0
**Objetivo:** Verificar anuncios automáticos de cambios de estado

**Pasos:**
1. Activar TalkBack
2. En `RemoteControlHostScreen`, NO tocar nada
3. Tocar (fuera de TalkBack) botón "Iniciar Sesión"
4. Escuchar anuncios automáticos mientras cambian los estados

**Resultado Esperado:**
- ✅ TalkBack anuncia automáticamente cada cambio sin necesidad de navegar:
  - "Estado de conexión: Solicitando permiso de captura de pantalla"
  - "Estado de conexión: Creando sesión remota"
  - "Estado de conexión: Esperando conexión..."
- ✅ Anuncios interrumpen cualquier lectura anterior
- ✅ No es necesario estar navegando el widget para escuchar los cambios

---

### ✅ TC-ACC-006: Botón "Copiar código" es navegable con TalkBack
**Prioridad:** P1
**Objetivo:** Verificar accesibilidad de funcionalidad secundaria

**Pasos:**
1. Con TalkBack activado, tener sesión activa
2. Navegar hasta encontrar botón "Copiar código"
3. Hacer doble tap

**Resultado Esperado:**
- ✅ TalkBack anuncia: "Copiar código de sesión, Botón, Toca dos veces para copiar el código al portapapeles"
- ✅ Al hacer doble tap:
  - Código se copia
  - TalkBack anuncia el snackbar: "Código copiado: 234567"

---

### ✅ TC-ACC-007: Diálogo de confirmación es accesible con TalkBack
**Prioridad:** P1
**Objetivo:** Verificar navegación en diálogos

**Pasos:**
1. Con TalkBack activado, tener sesión activa
2. Tocar "Terminar Sesión"
3. Navegar por el diálogo con swipes

**Resultado Esperado:**
- ✅ TalkBack cambia foco automáticamente al diálogo
- ✅ Anuncia en orden:
  1. "Confirmar terminar sesión" (título del diálogo)
  2. "¿Terminar sesión?" (título dentro)
  3. "Se cerrará la conexión con tu familiar..." (mensaje)
  4. "Cancelar, Botón"
  5. "Terminar, Botón"
- ✅ Ambos botones son activables con doble tap
- ✅ Foco vuelve a pantalla principal al cerrar diálogo

---

### ✅ TC-ACC-008: Mensajes de error son anunciados por TalkBack
**Prioridad:** P1
**Objetivo:** Verificar accesibilidad de errores

**Pasos:**
1. Con TalkBack activado, desconectar internet
2. Intentar iniciar sesión
3. Esperar error

**Resultado Esperado:**
- ✅ TalkBack anuncia automáticamente (liveRegion): "Error: [mensaje específico]"
- ✅ Al navegar al card de error, lee completo: "Error: [mensaje]. [Descripción adicional]"
- ✅ **ElevenLabs TTS** también anuncia: "Ocurrió un error. [mensaje]"
- ✅ Usuario recibe feedback tanto de TalkBack como de TTS

---

### ✅ TC-ACC-009: Tamaño de botones cumple mínimo 80dp altura
**Prioridad:** P1
**Objetivo:** Verificar cumplimiento de estándares de accesibilidad

**Pasos:**
1. En `RemoteControlHostScreen`, medir visualmente botones principales
2. Comparar con referencia (un dedo promedio = ~48dp)

**Resultado Esperado:**
- ✅ Botón "Iniciar Sesión Remota": Altura ≥ 80dp (aproximadamente 1.5 dedos)
- ✅ Botón "Terminar Sesión": Altura ≥ 80dp
- ✅ Botones en diálogo de confirmación: Altura ≥ 80dp
- ✅ Botón "Copiar código": Altura suficiente para tap cómodo
- ✅ Área táctil no se superpone con otros elementos

---

### ✅ TC-ACC-010: Texto del código cumple mínimo 48sp
**Prioridad:** P1
**Objetivo:** Verificar legibilidad del código

**Pasos:**
1. Tener sesión activa con código visible
2. Sostener dispositivo a 40-50cm de distancia
3. Verificar legibilidad

**Resultado Esperado:**
- ✅ Código es legible desde 50cm sin esfuerzo
- ✅ Texto es significativamente más grande que texto de instrucciones
- ✅ Dígitos están bien espaciados (no se tocan entre sí)
- ✅ Contraste suficiente (azul oscuro sobre blanco)
- ✅ Fuente monoespaciada (todos los dígitos ocupan mismo ancho)

---

## 📂 CATEGORÍA E: MANEJO DE ERRORES

**Prerequisitos específicos:** Varían por test case

---

### ✅ TC-ERR-001: Sin conexión a internet al iniciar sesión
**Prioridad:** P0
**Objetivo:** Verificar manejo cuando no hay conexión

**Prerequisito adicional:**
- Desactivar WiFi y datos móviles antes de empezar

**Pasos:**
1. Asegurar que NO hay conexión a internet (modo avión ON)
2. Abrir app
3. Navegar a Control Remoto
4. Tocar "Iniciar Sesión Remota"

**Resultado Esperado:**
- ✅ No aparece dialog de permiso (no llega a esa etapa)
- ✅ Card rojo de error aparece
- ✅ Ícono: ⚠️
- ✅ Mensaje: "No se pudo crear la sesión remota" o "No hay conexión a internet"
- ✅ Estado: "Error de conexión"
- ✅ TTS anuncia: "Ocurrió un error. No se pudo crear la sesión remota"
- ✅ App NO crashea
- ✅ Botón permite reintentar

---

### ✅ TC-ERR-002: Firebase Firestore no disponible
**Prioridad:** P1
**Objetivo:** Verificar comportamiento cuando Firestore falla

**Prerequisito adicional:**
- Desactivar Firebase temporalmente (cambiar reglas para denegar todo)

**Pasos:**
1. En Firebase Console, cambiar reglas de Firestore a `allow read, write: if false;`
2. Intentar iniciar sesión

**Resultado Esperado:**
- ✅ Error capturado gracefully
- ✅ Mensaje: "Failed to create remote session: [error de Firebase]"
- ✅ No se genera código de sesión
- ✅ Estado: "Error de conexión"
- ✅ App no crashea

**Cleanup:** Restaurar reglas de Firestore después del test

---

### ✅ TC-ERR-003: ElevenLabs API falla (TTS)
**Prioridad:** P1
**Objetivo:** Verificar que la app funciona sin TTS

**Prerequisito adicional:**
- Invalidar API key en `secrets.dart` temporalmente (poner "invalid_key")

**Pasos:**
1. Cambiar API key a un valor inválido
2. Reiniciar app (`flutter run`)
3. Intentar iniciar sesión remota

**Resultado Esperado:**
- ✅ Sesión se crea exitosamente (TTS no es bloqueante)
- ✅ Código aparece normalmente
- ✅ No se escucha anuncio de voz (silencio)
- ✅ Logs muestran error de ElevenLabs (revisar en `flutter logs`)
- ✅ Funcionalidad visual sigue funcionando al 100%
- ✅ App NO crashea

**Cleanup:** Restaurar API key válida

---

### ✅ TC-ERR-004: Error al crear sesión en Firestore
**Prioridad:** P1
**Objetivo:** Verificar manejo de errores de Firestore

**Prerequisito adicional:**
- Modificar reglas de Firestore para rechazar creación de sesiones (ej: requerir campo inexistente)

**Pasos:**
1. Modificar reglas para causar error
2. Intentar iniciar sesión

**Resultado Esperado:**
- ✅ Error capturado
- ✅ Card de error visible
- ✅ Mensaje descriptivo del error
- ✅ No se muestra código
- ✅ Usuario puede reintentar después de corregir configuración

**Cleanup:** Restaurar reglas

---

### ✅ TC-ERR-007: Mostrar mensaje de error en Card rojo
**Prioridad:** P0
**Objetivo:** Verificar UI de errores

**Pasos:**
1. Provocar cualquier error (ej: sin internet, TC-ERR-001)
2. Observar la UI de error

**Resultado Esperado:**
- ✅ Card con fondo rojo claro (#FFEBEE) aparece
- ✅ Borde rojo oscuro (#C62828)
- ✅ Ícono ⚠️ de color rojo (#B71C1C)
- ✅ Texto del error en rojo oscuro (#B71C1C)
- ✅ Tamaño de texto: 20sp (legible)
- ✅ Card aparece ARRIBA del botón de acción
- ✅ Card tiene padding adecuado (16dp)

---

### ✅ TC-ERR-008: Anunciar errores con TTS
**Prioridad:** P1
**Objetivo:** Verificar feedback audible de errores

**Pasos:**
1. Asegurar volumen > 50%
2. Provocar error (ej: denegar permiso, TC-PERM-003)
3. Escuchar anuncio

**Resultado Esperado:**
- ✅ TTS anuncia: "Ocurrió un error. [mensaje específico del error]"
- ✅ Voz es clara
- ✅ Si ElevenLabs falla, TalkBack sigue anunciando el error (redundancia)

---

## 📂 CATEGORÍA F: EDGE CASES

**Prerequisitos específicos:** Varían por test case

---

### ✅ TC-EDGE-001: Sesión expira después de 15 minutos
**Prioridad:** P1
**Objetivo:** Verificar timeout automático

**Nota:** Este test toma 15+ minutos. Considerar ejecutar en horario de menor carga.

**Pasos:**
1. Iniciar sesión remota exitosamente
2. No hacer nada (dejar app en foreground)
3. Esperar 15 minutos y 10 segundos
4. Observar cambios

**Resultado Esperado:**
- ✅ Después de exactamente 15 minutos:
  - Sesión se marca como expirada en Firestore
  - Código desaparece de pantalla
  - Estado cambia a "Sesión terminada" o "Idle"
  - TTS anuncia: "Sesión remota terminada"
  - Notificación de foreground desaparece
- ✅ Usuario puede iniciar nueva sesión sin problemas

---

### ✅ TC-EDGE-003: App va a background durante sesión
**Prioridad:** P1
**Objetivo:** Verificar comportamiento al minimizar app

**Pasos:**
1. Iniciar sesión remota exitosamente
2. Presionar botón Home del dispositivo (minimizar app)
3. Esperar 10 segundos
4. Reabrir app desde Recent Apps

**Resultado Esperado:**
- ✅ Notificación de foreground sigue visible mientras app está en background
- ✅ Al reabrir app:
  - Sesión sigue activa
  - Código sigue visible
  - Estado NO cambió
  - Timer de 15 minutos continúa corriendo (no se resetea)

---

### ✅ TC-EDGE-004: Reiniciar app con sesión activa
**Prioridad:** P1
**Objetivo:** Verificar comportamiento al cerrar completamente la app

**Pasos:**
1. Iniciar sesión remota exitosamente
2. Cerrar app completamente (Recent Apps → Swipe up para matar proceso)
3. Esperar 5 segundos
4. Reabrir app desde launcher

**Resultado Esperado:**
- ✅ App abre en `HomeScreen` (estado limpio)
- ✅ Sesión anterior NO está activa
- ✅ No hay código visible
- ✅ Estado es "Sin sesión activa"
- ✅ Notificación de foreground desapareció
- ✅ Sesión en Firestore se limpió automáticamente o expirará en su tiempo

---

### ✅ TC-EDGE-006: Código de sesión no contiene caracteres ambiguos
**Prioridad:** P0
**Objetivo:** Verificar que el código es fácil de comunicar por voz

**Pasos:**
1. Iniciar 20 sesiones remotas consecutivas (terminar cada una antes de iniciar la siguiente)
2. Anotar cada código generado

**Resultado Esperado:**
- ✅ **Ningún código contiene:** 0 (cero), O (letra o), I (letra i mayúscula), 1 (uno)
- ✅ **Solo contienen dígitos:** 2, 3, 4, 5, 6, 7, 8, 9
- ✅ Todos los códigos tienen exactamente 6 dígitos
- ✅ Los 20 códigos son únicos (no se repiten)
- ✅ Ejemplos válidos: "234567", "987654", "345678"
- ✅ Ejemplos inválidos (NO deben ocurrir): "012345", "1OI234"

---

## 📂 CATEGORÍA G: PERFORMANCE

**Prerequisitos específicos:**
- Device/emulator con performance monitoring habilitado
- Herramientas: Flutter DevTools, Android Profiler

---

### ✅ TC-PERF-001: Tiempo de generación de código < 3 segundos
**Prioridad:** P1
**Objetivo:** Verificar que la creación de sesión es rápida

**Pasos:**
1. Estar en `RemoteControlHostScreen`
2. Cronometrar desde que se toca "Iniciar Sesión Remota" hasta que aparece el código
3. Repetir 5 veces y promediar

**Resultado Esperado:**
- ✅ Tiempo promedio: < 3 segundos
- ✅ Tiempo máximo en el peor caso: < 5 segundos
- ✅ Desglose aproximado:
  - Permiso de pantalla: 0-1 seg (según usuario)
  - Creación en Firestore: 0.5-1 seg
  - Inicialización WebRTC: 0.5-1 seg
  - Render UI: < 0.5 seg

---

### ✅ TC-PERF-002: UI responde sin lag al presionar botones
**Prioridad:** P1
**Objetivo:** Verificar fluidez de la UI

**Pasos:**
1. Tocar botón "Iniciar Sesión Remota" repetidamente (5 veces rápido)
2. Observar respuesta visual
3. Durante sesión activa, tocar "Terminar Sesión" y "Cancelar" en diálogo repetidamente

**Resultado Esperado:**
- ✅ Cada tap tiene feedback visual inmediato (< 100ms)
- ✅ Animaciones son fluidas (60 fps)
- ✅ No hay janks visibles (stuttering)
- ✅ Botones responden al primer tap (no requieren múltiples taps)

---

### ✅ TC-PERF-003: TTS reproduce sin delay > 2 segundos
**Prioridad:** P1
**Objetivo:** Verificar latencia de TTS

**Pasos:**
1. Cronometrar desde que se genera el código hasta que se escucha la primera palabra del TTS
2. Repetir 3 veces

**Resultado Esperado:**
- ✅ Delay promedio: < 2 segundos
- ✅ En el peor caso: < 3 segundos
- ✅ Audio no se corta ni tiene distorsión
- ✅ Velocidad de reproducción es natural (no acelerada ni lenta)

---

### ✅ TC-PERF-004: Memoria de app no excede 150MB durante sesión
**Prioridad:** P1
**Objetivo:** Verificar que no hay memory leaks

**Prerequisito adicional:**
- Android Profiler o Flutter DevTools abierto

**Pasos:**
1. Abrir Flutter DevTools → Memory tab
2. Tomar snapshot inicial de memoria
3. Iniciar sesión remota
4. Esperar 2 minutos
5. Terminar sesión
6. Tomar snapshot final

**Resultado Esperado:**
- ✅ Memoria inicial: ~50-80MB
- ✅ Memoria durante sesión: ~100-150MB
- ✅ Memoria después de terminar sesión: Vuelve a ~50-80MB (GC recoge recursos)
- ✅ No hay crecimiento sostenido de memoria (memory leak)
- ✅ Gráfica de memoria muestra patrón estable (diente de sierra normal)

---

## 📂 CATEGORÍA H: SEGURIDAD Y TIMEOUT

**Prerequisitos específicos:** Ninguno adicional

---

### ✅ TC-SEC-001: Código de sesión es único (no se repite)
**Prioridad:** P0
**Objetivo:** Verificar unicidad de códigos

**Pasos:**
1. Iniciar 50 sesiones remotas consecutivas
2. Anotar cada código
3. Verificar duplicados

**Resultado Esperado:**
- ✅ Los 50 códigos son únicos (no hay duplicados)
- ✅ Probabilidad de colisión es mínima (con 8 dígitos disponibles: 2-9, hay 8^6 = 262,144 combinaciones)
- ✅ Distribución parece aleatoria (no hay patrones obvios como "234567", "345678" secuenciales)

---

### ✅ TC-SEC-003: Timeout automático de 15 minutos funciona correctamente
**Prioridad:** P0
**Objetivo:** Verificar que sesiones no persisten indefinidamente

**Pasos:**
1. Iniciar sesión remota
2. Anotar timestamp exacto de creación
3. Esperar 15 minutos y 30 segundos
4. Intentar usar el código en Firestore (verificar en Firebase Console)

**Resultado Esperado:**
- ✅ En Firebase Console, el documento de sesión tiene campo `expiresAt`
- ✅ Valor de `expiresAt` = `createdAt` + 15 minutos
- ✅ Después de 15 minutos:
  - Documento se marca como expirado (o se elimina)
  - Intentar leer la sesión retorna null o error
- ✅ App limpia sesión automáticamente
- ✅ Usuario no puede "reactivar" una sesión expirada

---

## 📊 RESUMEN DE COBERTURA

### **Por Prioridad:**
| Prioridad | Cantidad | Tiempo Estimado |
|-----------|----------|-----------------|
| P0 (Crítica) | 15 | ~45 minutos |
| P1 (Alta) | 28 | ~2 horas |
| **TOTAL** | **43** | **~3 horas** |

### **Por Categoría:**
| Categoría | P0 | P1 | Total | % Cobertura |
|-----------|----|----|-------|-------------|
| Happy Path | 3 | 5 | 8 | 18.6% |
| Permisos | 2 | 2 | 4 | 9.3% |
| Conexión | 2 | 3 | 5 | 11.6% |
| Accesibilidad | 3 | 7 | 10 | 23.3% |
| Errores | 2 | 4 | 6 | 14.0% |
| Edge Cases | 1 | 3 | 4 | 9.3% |
| Performance | 0 | 4 | 4 | 9.3% |
| Seguridad | 2 | 0 | 2 | 4.7% |
| **TOTAL** | **15** | **28** | **43** | **100%** |

### **Notas Importantes:**
- ✅ Tests de conexión **TC-CONN-002** y **TC-CONN-003** requieren implementación del cliente (app del familiar)
- ⚠️ **TC-EDGE-001** y **TC-SEC-003** requieren 15+ minutos cada uno
- 📱 Tests de categoría **D (Accesibilidad)** requieren TalkBack activado
- 🔧 Tests de categoría **G (Performance)** requieren herramientas de profiling

---

## 🎯 ORDEN SUGERIDO DE EJECUCIÓN

### **Fase 1: Smoke Tests (P0 Críticos)** - 45 minutos
Ejecutar primero para validar funcionalidad core:
- TC-HP-001, TC-HP-002, TC-HP-004, TC-HP-006
- TC-PERM-002, TC-PERM-003
- TC-CONN-001, TC-CONN-004
- TC-ACC-001, TC-ACC-003, TC-ACC-005
- TC-ERR-001, TC-ERR-007
- TC-EDGE-006
- TC-SEC-001, TC-SEC-003

### **Fase 2: Feature Tests (P1)** - 2 horas
Ejecutar después de validar P0:
- Completar categoría A (Happy Path)
- Completar categoría D (Accesibilidad)
- Completar categoría E (Errores)
- Categoría G (Performance)

### **Fase 3: Long-Running Tests** - Ejecutar en paralelo o separado
- TC-EDGE-001 (15 minutos)
- TC-SEC-003 (15 minutos)

---

## 📝 REGISTRO DE BUGS

Al encontrar bugs durante el testing, registrar en el siguiente formato:

```markdown
**Bug ID:** BUG-F2-XXX
**Test Case:** TC-XXX-XXX
**Prioridad:** Critical / High / Medium / Low
**Descripción:** [Descripción breve]
**Pasos para reproducir:**
1. [Paso 1]
2. [Paso 2]
**Resultado esperado:** [...]
**Resultado actual:** [...]
**Logs relevantes:** [Adjuntar si aplica]
**Screenshots:** [Adjuntar si aplica]
```

---

## ✅ CRITERIOS DE ACEPTACIÓN PARA RELEASE

Para considerar la Funcionalidad 2 lista para release, se deben cumplir:

- ✅ **100% de tests P0 (15)** pasan exitosamente
- ✅ **≥ 90% de tests P1 (28)** pasan (máximo 3 fallos permitidos en P1)
- ✅ **0 bugs críticos** pendientes
- ✅ **Tests de accesibilidad con TalkBack** pasan al 100%
- ✅ **No memory leaks** detectados
- ✅ **Performance cumple estándares** (todos los TC-PERF-XXX pasan)

---

**Documento creado:** 07 Enero 2026
**Autor:** Claude Code (Anthropic)
**Próxima revisión:** Después de implementar app del cliente (Funcionalidad 2.1)
