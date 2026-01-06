# ROADMAP DE DESARROLLO - App de Accesibilidad para Adultos Mayores

**Fecha de creación:** 24 dic 2025
**Próxima revisión:** Post testing de MVP (semana 6)
**Responsable:** Desarrollador en solitario + usuario final (padre) como tester

---

## ROADMAP DE DESARROLLO

### FASE 1: MVP (Semanas 1-6)

#### Objetivo
Validar la propuesta de valor principal con el usuario: **control remoto de pantalla para soporte familiar**, permitiendo que un familiar pueda ver y controlar el dispositivo del adulto mayor de forma remota, eliminando la necesidad de ayuda presencial.

#### Funcionalidades Incluidas

- [ ] **Setup del proyecto Flutter**
  - Configuración inicial con Provider, Hive, permisos básicos
  - Estructura de carpetas según CLAUDE.md
  - Proyecto Firebase configurado (Firestore para signaling)

- [ ] **WebRTC + Firebase para Control Remoto**
  - Signaling server con Firestore
  - Screen sharing desde Android (AccessibilityService)
  - Control remoto bidireccional (familiar puede ver e interactuar)
  - Códigos de sesión simples (4-6 dígitos) para emparejar
  - Timeout automático de seguridad

- [ ] **Interfaz accesible básica**
  - Home screen con botones grandes (80dp+, texto 24sp+)
  - Alto contraste configurable
  - Semantics en todos los widgets con TalkBack
  - Pantalla de "Solicitar ayuda" con código de sesión grande

- [ ] **Integración ElevenLabs STT/TTS básica**
  - Servicio de voz funcional (reconocimiento + síntesis)
  - Fallback a Android SpeechRecognizer
  - Anuncios de voz para estados de conexión remota

- [ ] **WhatsApp básico mediante Deep Links**
  - Abrir WhatsApp mediante comando de voz o botón
  - Deep link para abrir chat con número específico (si disponible)
  - Lista de contactos frecuentes con números guardados
  - NO requiere AccessibilityService (más estable)

- [ ] **Gestión de permisos**
  - Tutorial paso a paso para Accessibility (screen sharing)
  - Validación de permisos antes de iniciar sesión remota
  - Guías con capturas de pantalla

#### Criterios de Éxito

- Familiar puede conectarse remotamente en <30 segundos usando código de sesión
- Usuario puede solicitar ayuda con un botón grande sin asistencia
- Stream de video funciona con latencia <2 segundos en conexión WiFi
- Control remoto permite al familiar interactuar con el dispositivo efectivamente
- Usuario puede abrir WhatsApp (mediante deep link o con ayuda remota del familiar)
- App pasa Android Accessibility Scanner sin warnings críticos
- Navegación completa posible solo con TalkBack

#### Entregables

- APK funcional instalable en Android 7.0+
- Video demo de 2 minutos mostrando uso legítimo (para Google Play)
- Documento de privacidad inicial
- Sesión de testing con usuario real (padre) + registro de feedback
- Lista priorizada de ajustes para v1.0

---

### FASE 2: v1.0 (Semanas 7-12)

#### Objetivo
App lista para uso diario con control remoto funcional + **automatización avanzada de WhatsApp** (mediante AccessibilityService) y comandos de voz expandidos para mayor autonomía del usuario.

#### Funcionalidades Incluidas

- [ ] **Mejoras al Control Remoto**
  - Optimización de latencia y calidad de video
  - Indicadores visuales de estado de conexión
  - Reconexión automática ante pérdida de señal
  - Historial de sesiones recientes

- [ ] **AccessibilityService para WhatsApp Automation**
  - Automatización para abrir chat por nombre de contacto
  - Leer mensajes del chat actual
  - Enviar mensajes de texto mediante dictado
  - Logging detallado para debugging
  - Detección de versión de WhatsApp y compatibilidad

- [ ] **Comandos de voz expandidos**
  - "Abre WhatsApp de [nombre contacto]"
  - "Lee mis mensajes de [contacto]"
  - "Envía mensaje a [contacto] diciendo [texto]"
  - "¿Tengo mensajes nuevos?"
  - "Llama a [contacto]"
  - Parser NLP mejorado con contexto y sinónimos

- [ ] **Notificaciones inteligentes**
  - Listener de notificaciones de WhatsApp
  - Anuncio automático de mensajes nuevos en voz alta
  - Configuración de contactos VIP (solo anunciar estos)
  - Control de frecuencia de anuncios

- [ ] **Personalización de accesibilidad**
  - Configuración de velocidad de voz TTS
  - Modo ultra alto contraste
  - Tamaño de botones ajustable (80dp a 120dp)
  - Guardar contactos favoritos para acceso rápido
  - Temas de color predefinidos

- [ ] **Estabilidad y error handling**
  - Recuperación automática de fallos
  - Logs estructurados para debugging remoto
  - Sistema de reportes de errores simplificado
  - Modo degradado cuando WhatsApp automation falla (fallback a deep links)

#### Criterios de Éxito

- Control remoto estable con reconexión automática ante cortes
- Usuario puede usar WhatsApp mediante comandos de voz (cuando AccessibilityService funciona)
- Fallback a deep links funciona cuando AccessibilityService falla
- 95%+ tasa de reconocimiento de comandos de voz (ambiente con ruido moderado)
- Detección y manejo correcto de 5+ casos de error comunes
- Uso continuo de 1+ semana sin intervención técnica
- AccessibilityService detecta incompatibilidades de versión de WhatsApp y notifica al usuario

#### Entregables

- APK release firmado para distribución
- Documentación de usuario (texto + audios de ElevenLabs)
- Material para Google Play (descripción, capturas, video demo)
- Política de privacidad completa
- Suite de testing con 20+ casos de uso documentados
- Plan de mantenimiento ante actualizaciones de WhatsApp

---

### FASE 3: Escalabilidad Futura (Post-lanzamiento)

#### Mejoras Propuestas

##### **Corto Plazo (1-3 meses post v1.0)**

- **Expansión de plataformas de mensajería**
  - Telegram (API oficial más estable que AccessibilityService)
  - SMS nativos (más simple, sin fragilidad de WhatsApp)

- **Comandos de sistema**
  - "Llama a [contacto]"
  - "Abre YouTube/Spotify"
  - "¿Qué hora es?" / "¿Qué día es hoy?"

- **Mejoras UX**
  - Modo manos libres (activación por palabra clave)
  - Tutoriales en video con TTS
  - Temas de color predefinidos (no solo alto contraste)

- **Analíticas locales (sin tracking)**
  - Comandos más usados
  - Tasa de error por tipo de acción
  - Métricas para optimización interna

##### **Mediano Plazo (3-6 meses)**

- **Soporte iOS básico (v2.0)**
  - UI simplificada + comandos de voz
  - ReplayKit para screen sharing (solo lectura)
  - Sin automatización de WhatsApp (limitación de plataforma)

- **Integraciones de accesibilidad nativa**
  - Integración con Google Assistant/Bixby
  - Acciones rápidas en widgets de pantalla principal
  - Notificaciones inteligentes con Quick Replies

- **Modo offline mejorado**
  - Comandos básicos sin internet (llamadas, SMS)
  - Caché de contactos frecuentes
  - Sincronización cuando hay conexión

- **Comunidad y soporte**
  - Portal de soporte con FAQs en audio
  - Sistema de feedback dentro de la app (comando de voz)
  - Grupo de beta testers con usuarios reales

##### **Largo Plazo (6+ meses)**

- **IA conversacional local**
  - Modelo on-device para NLP (reducir dependencia de ElevenLabs)
  - Conversación natural vs comandos rígidos
  - Aprendizaje de patrones del usuario

- **Ecosistema familiar**
  - App companion para familiares (monitoreo opcional con consentimiento)
  - Alertas configurables (ej: "no ha usado la app en 24h")
  - Tutorial remoto guiado

- **Internacionalización**
  - Soporte multi-idioma (español, portugués, inglés)
  - Voces regionales de ElevenLabs
  - Adaptar comandos a variantes lingüísticas

- **Integraciones avanzadas**
  - Recordatorios de medicamentos con alarmas de voz
  - Lectura de noticias/clima/calendario
  - Integración con servicios de salud (telemedicina)

---

## CRONOGRAMA VISUAL

```
Semana 1-2:  [██░░░░░░░░░░░░] Setup + Firebase + WebRTC básico
Semana 3-4:  [█████░░░░░░░░░] Control remoto funcional + Screen sharing
Semana 5-6:  [████████░░░░░░] UI accesible + WhatsApp deep links + Testing MVP
════════════════════════════════════════════════════════════════
Semana 7-8:  [██████████░░░░] AccessibilityService + WhatsApp automation
Semana 9-10: [████████████░░] Comandos de voz expandidos + Notificaciones
Semana 11-12:[██████████████] Personalización + Pulido + Testing final v1.0
```

---

## DEPENDENCIAS Y RIESGOS POR FASE

### FASE 1: MVP

**Dependencias:**
- ✅ Proyecto Firebase configurado (Firestore para signaling)
- ✅ Dispositivo Android físico para testing con TalkBack
- ⚠️ Disponibilidad del padre para testing real (crucial para validación)
- ⚠️ Disponibilidad de familiar para testing de control remoto

**Riesgos:**
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| WebRTC complejo de implementar | Media | Alto | Estudiar flutter_webrtc examples + RustDesk como referencia |
| Latencia alta en control remoto | Media | Medio | Optimización de parámetros WebRTC + testing con WiFi/datos |
| AccessibilityService para screen sharing rechazado | Baja | Crítico | Documentación clara de uso legítimo desde día 1 |
| Usuario no entiende cómo solicitar ayuda | Media | Alto | Botón grande simple + tutorial con capturas |
| Deep links de WhatsApp no funcionan como esperado | Media | Bajo | Fallback a solo abrir WhatsApp (el familiar ayuda desde remoto) |

**Bloqueos críticos:**
- Sin acceso a dispositivo Android 7.0+ con TalkBack → **Imposible continuar**
- Sin usuario real + familiar para testing → **MVP inválido** (no se valida UX de control remoto)

---

### FASE 2: v1.0

**Dependencias:**
- ✅ Feedback de MVP integrado (control remoto funcionando)
- ✅ Control remoto estable desde MVP
- ⚠️ Usuario disponible para testing de comandos de voz

**Riesgos:**
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| AccessibilityService rechazado por WhatsApp UI | Media | Medio | Ya hay fallback a deep links desde MVP |
| WhatsApp actualiza UI entre semanas 6-12 | Media | Alto | Versionado de compatibilidad + tests automatizados + deep links como fallback |
| Curva de aprendizaje de AccessibilityService | Alta | Medio | Estudiar RustDesk como referencia + tiempo extra (buffer semana 7-8) |
| ElevenLabs STT no reconoce acento/ruido | Media | Medio | Fallback a Android SpeechRecognizer |
| Performance baja en dispositivos gama baja | Media | Medio | Testing en dispositivo Android 7.0 de gama baja desde semana 7 |

**Bloqueos críticos:**
- WhatsApp cambia radicalmente su UI → **Mantener deep links como única opción** (funcionalidad reducida pero aceptable)
- ElevenLabs discontinúa API → **Migrar a alternativa** (costo: 1-2 semanas)

---

### FASE 3: Escalabilidad

**Dependencias:**
- ✅ Base de usuarios reales (al menos 5-10 para feedback)
- ⚠️ Budget para Mac + cuenta Apple Developer (iOS)
- ⚠️ Aprobación de Google Play (para publicar)

**Riesgos:**
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Rechazo de Google Play por AccessibilityService | Media | Crítico | Video demo + declaración clara desde v1.0 |
| Falta de adopción por usuarios | Alta | Medio | Marketing boca a boca + comunidades de adultos mayores |
| Costos recurrentes de ElevenLabs | Media | Bajo | Plan de monetización o migración a TTS local |
| iOS demasiado restrictivo | Alta | Bajo | Versión iOS es opcional (prioridad 2) |

**Bloqueos no críticos:**
- Sin Mac para desarrollo iOS → **Postponer iOS indefinidamente** (Android es suficiente)
- Sin aprobación de Google Play → **Distribución directa APK** (menor alcance)

---

## NOTAS ADICIONALES

### Tiempo de Aprendizaje Considerado

- **WebRTC (nuevo):** 3-4 días investigación + setup + debugging (semanas 1-3)
- **AccessibilityService para screen sharing (nuevo):** 2-3 días investigación (semanas 2-3)
- **Platform Channels Flutter↔Kotlin:** 2 días (semana 2)
- **AccessibilityService para WhatsApp automation (nuevo):** 3-4 días investigación + pruebas (semanas 7-8)

**Total estimado de aprendizaje:** ~10-13 días distribuidos en el cronograma.

### Priorización de Impacto

**Decisión clave: MVP prioriza Control Remoto sobre Automatización de WhatsApp**

**Justificación:**
1. Control remoto desbloquea ayuda familiar remota → **Elimina dependencia de ayuda presencial**
2. Más estable técnicamente (WebRTC vs AccessibilityService frágil) → **Menor riesgo**
3. Resuelve TODOS los problemas del usuario indirectamente → **Máximo valor**
4. WhatsApp puede usarse mediante deep links básicos mientras tanto → **Funcionalidad mínima disponible**
5. Familiar puede controlar WhatsApp remotamente si deep links fallan → **Fallback natural**

**Ventaja adicional:** Si AccessibilityService para WhatsApp automation resulta muy complejo o inestable en v1.0, la app sigue siendo valiosa con control remoto + deep links.

---

## DECISIÓN DE PRIORIZACIÓN: Control Remoto vs WhatsApp Automation

### Análisis de Impacto

#### Control Remoto (Elegido para MVP)
**Pros:**
- Desbloquea ayuda remota de familiares → **Elimina dependencia de ayuda presencial**
- Tecnología más estable (WebRTC) → **Menor riesgo técnico**
- Resuelve TODOS los problemas indirectamente (familiar puede ayudar con cualquier cosa)
- Casos de uso críticos cuando el usuario está bloqueado

**Contras:**
- Requiere coordinación con familiar
- Necesita buena conexión a internet
- No aumenta autonomía directamente

**Valor para usuario:** ⭐⭐⭐⭐⭐ (desbloquea ayuda en cualquier situación)

#### WhatsApp Automation (Pospuesto a v1.0)
**Pros:**
- Uso diario múltiple (mensajes, audios)
- Aumenta autonomía del usuario
- Feedback directo del reconocimiento de voz

**Contras:**
- Técnicamente muy complejo (AccessibilityService)
- Frágil ante actualizaciones de WhatsApp
- Riesgo de rechazo en Google Play
- Deep links pueden cubrir necesidad básica mientras tanto

**Valor para usuario:** ⭐⭐⭐⭐ (importante pero cubierto parcialmente por deep links + control remoto)

### Estrategia de Implementación de WhatsApp

**MVP (Semanas 1-6):**
- WhatsApp mediante deep links únicamente
- Abrir app con botón grande o comando de voz
- Abrir chat con número específico (si posible)
- Familiar puede ayudar remotamente si es necesario

**v1.0 (Semanas 7-12):**
- AccessibilityService para automatización completa
- Comandos de voz para abrir chats, leer mensajes, enviar textos
- Fallback automático a deep links si automation falla
- Detección de versión de WhatsApp para compatibilidad

**Ventaja de este enfoque:**
- Reduce riesgo técnico del MVP
- MVP sigue siendo valioso incluso si WhatsApp automation nunca funciona perfectamente
- Valida el valor del control remoto temprano

---

## HISTORIAL DE REVISIONES

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 24 dic 2025 | Roadmap inicial creado |
| 1.1 | 24 dic 2025 | **CAMBIO CRÍTICO:** Priorización invertida - Control remoto pasa a MVP, WhatsApp automation pasa a v1.0. WhatsApp en MVP usa deep links únicamente. Cronograma visual corregido para mostrar progreso incremental. |

---

**Próximos pasos:**
1. Revisar y aprobar este roadmap actualizado
2. Crear proyecto Firebase y configurar Firestore (signaling para WebRTC)
3. Validar disponibilidad de padre + familiar para testing (semana 5-6)
4. Crear cuenta ElevenLabs y obtener API key (para TTS básico en MVP)
5. Preparar dispositivo Android físico para desarrollo
6. Estudiar ejemplos de flutter_webrtc y RustDesk como referencia
