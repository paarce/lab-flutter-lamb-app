# Efficient Debug Skill

Workflow optimizado para debugging con mínimo consumo de tokens.

## Cuando el usuario reporta un error

### 1. NO ejecutes comandos automáticamente
- ❌ NO ejecutes `flutter analyze`
- ❌ NO ejecutes `flutter logs`
- ❌ NO ejecutes `flutter run`
- ✅ Pide al usuario que ejecute y comparta resultado

### 2. NO leas archivos innecesariamente
- ❌ NO releas archivos ya vistos en los últimos 3 mensajes
- ❌ NO leas archivo completo si solo necesitas una sección
- ✅ Usa contexto de conversación existente
- ✅ Usa Grep para búsquedas específicas

### 3. Analiza con contexto existente
- Revisa mensajes anteriores de la conversación
- Usa conocimiento de arquitectura del proyecto (CLAUDE.md)
- Infiere del error compartido por el usuario

### 4. Propón fix dirigido
- 1-3 ediciones máximo por iteración
- Cambios pequeños y verificables
- Explica qué hace cada cambio

### 5. Usuario valida
- Usuario ejecuta `flutter analyze`
- Usuario reporta errores específicos (solo líneas con "error •")
- Usuario ejecuta app y comparte logs filtrados

## Formato de respuesta

```markdown
**Análisis del error:**
[Explicación breve del problema]

**Fix propuesto:**
[Descripción de cambios a realizar]

**Validación:**
Por favor ejecuta:
- `flutter analyze` y comparte líneas con "error •"
- O `flutter logs | grep <filtro>` y comparte últimas 20 líneas
```

## Ejemplo eficiente

❌ **INEFICIENTE:**
```
Claude: [Lee archivo X]
Claude: [Ejecuta flutter analyze]
Claude: [Lee logs]
Claude: [Hace cambio]
Claude: [Ejecuta flutter analyze de nuevo]
```

✅ **EFICIENTE:**
```
Usuario: "Error: [pega mensaje]"
Claude: "El error indica [análisis]. Voy a [propuesta fix]."
Claude: [Hace cambio]
Claude: "Ejecuta `flutter analyze` y comparte errores si los hay"
Usuario: "No hay errores" o "Hay error: [pega]"
Claude: [Itera si necesario]
```

## Comandos que SÍ puedes ejecutar

✅ `git status`
✅ `git diff`
✅ `git add`
✅ `git commit`
✅ File operations (Write, Edit, Read cuando necesario)

## Métricas de éxito

- Menos de 3 lecturas de archivo por fix
- Menos de 2 iteraciones por error
- Usuario ejecuta validaciones, no Claude
- Solución en <5 mensajes
