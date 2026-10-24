# 📋 MANUAL TEST CASES - Funcionalidad 6.4: Lector de Fotos de la Galería

**Versión:** 1.0.0
**Funcionalidad:** Fotos a pantalla completa + lectura automática con IA de visión
**Plataforma:** Android 7.0+ (API 24+)
**Total Test Cases:** 22 (15 P0 + 7 P1)

---

## 🔧 Prerequisitos

- Dispositivo físico Android (idealmente uno con Android 13+ y otro con Android ≤12)
- `claudeApiKey` configurada en `lib/config/secrets.dart` (o `vision.env.json`, ver doc principal)
- Conexión a internet
- En la galería, al menos:
  - 1 captura de pantalla de un chat de WhatsApp
  - 1 foto de personas / paisaje
  - 1 foto o captura de resultados de análisis clínicos (con rangos de referencia)
  - 1 foto de un informe médico o documento con texto
- TalkBack: probar los casos marcados con 🦻 con TalkBack **activado**

---

## A. Acceso y permisos

| ID | Prioridad | Caso | Pasos | Resultado esperado |
|---|---|---|---|---|
| A1 | P0 | Abrir desde botón | En la pantalla principal toca **"Leer mis fotos"** | Se abre "Mis fotos". Primera vez: aparece el diálogo de permiso del sistema |
| A2 | P0 | Abrir por voz | Mantén el micrófono y di *"leer mis fotos"* | Dice *"Abriendo tus fotos..."* y abre la pantalla |
| A3 | P0 | Permiso concedido | Acepta el permiso | Se muestra la foto más reciente a pantalla completa y *"Foto 1 de N"* |
| A4 | P0 | Permiso denegado | Deniega el permiso | Diálogo accesible + voz *"Necesito permiso para ver tus fotos..."*. Tras cerrar: botones **Abrir configuración** y **Ya lo activé** |
| A5 | P1 | Recuperar permiso | Desde A4: **Abrir configuración** → activar Fotos → volver → **Ya lo activé** | Se cargan las fotos |
| A6 | P1 | Galería vacía | Dispositivo/emulador sin fotos | Mensaje *"No hay fotos en tu galería."* |

## B. Lectura automática

| ID | Prioridad | Caso | Pasos | Resultado esperado |
|---|---|---|---|---|
| B1 | P0 | Captura de chat | Quédate 2 s en una captura de WhatsApp | Dice *"Leyendo la foto..."* y luego *"Es una captura de un chat de WhatsApp con..."* leyendo quién dice cada mensaje. Panel: **Captura de chat** |
| B2 | P0 | Foto | Quédate 2 s en una foto de personas/paisaje | Descripción breve (2-3 frases). Panel: **Fotografía**. No inventa nombres |
| B3 | P0 | Resultados médicos | Quédate 2 s en unos análisis | Dice el tipo de análisis, lee cada valor con su unidad hablada, señala valores fuera de rango y recomienda consultar al médico. Sin diagnósticos |
| B4 | P0 | Informe/documento | Quédate 2 s en un informe médico | Lee todo el texto relevante (diagnóstico, indicaciones, dosis, fechas) |
| B5 | P0 | Deslizar rápido | Pasa 5 fotos rápido (<2 s cada una) | No se lee ninguna foto ni aparece "Leyendo..." hasta detenerse |
| B6 | P0 | Cambiar mientras lee | Mientras lee una foto, pasa a la siguiente | La voz se detiene de inmediato; la nueva foto se lee tras 2 s |
| B7 | P1 | Caché | Lee una foto, pasa a otra y vuelve | La primera se repite **al instante** (sin "Leyendo...") |
| B8 | P1 | Texto sin markdown | Revisa el panel y la voz en B1-B4 | No se leen asteriscos, almohadillas ni "JSON" |

## C. Controles y accesibilidad 🦻

| ID | Prioridad | Caso | Pasos | Resultado esperado |
|---|---|---|---|---|
| C1 | P0 | Botones | Usa **Anterior / Siguiente** | Cambian de foto; *Anterior* deshabilitado en la primera foto |
| C2 | P0 | Botón central | Observa el botón en cada estado | **Leer foto** → **Leyendo** (deshabilitado) → **Detener** (mientras habla) → **Repetir** |
| C3 | P0 | TalkBack | Con TalkBack, navega por la pantalla deslizando un dedo | Anuncia: Volver, Ocultar texto, la foto ("Foto 1 de N" + descripción), panel, Anterior, botón central, Siguiente — todos con su sugerencia |
| C4 | P1 | Ocultar texto | Toca **Ocultar texto** o toca la foto | Desaparece el panel; la foto ocupa más pantalla. Botón cambia a **Mostrar texto** |
| C5 | P1 | Texto grande | Ajustes → Tamaño de fuente al máximo | Los botones siguen legibles (el texto se ajusta, no se corta) |

## D. Errores (sin reintentos automáticos)

| ID | Prioridad | Caso | Pasos | Resultado esperado |
|---|---|---|---|---|
| D1 | P0 | Sin internet | Modo avión → quédate en una foto | Diálogo accesible + voz *"No tienes conexión a internet..."* con **Reintentar**. Volver a la foto NO reintenta solo |
| D2 | P0 | API key inválida | Pon una key inválida en `secrets.dart` | Un solo diálogo *"Error de configuración..."*. Las siguientes fotos muestran *"Lectura automática pausada"* sin más diálogos |
| D3 | P1 | Reintentar | Desde D1, desactiva modo avión → **Reintentar** | La foto se lee correctamente |

---

## ✅ Resumen de cobertura

| Categoría | P0 | P1 |
|---|---|---|
| A. Acceso y permisos | 4 | 2 |
| B. Lectura automática | 6 | 2 |
| C. Controles y accesibilidad | 3 | 2 |
| D. Errores | 2 | 1 |
| **Total** | **15** | **7** |
