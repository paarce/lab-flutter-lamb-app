# Reglas de Optimización de Tokens

## Comandos que el usuario ejecutará manualmente

**NUNCA ejecutar automáticamente:**
- `flutter analyze` - Usuario lo ejecuta y reporta errores
- `flutter test` - Usuario lo ejecuta si hay tests
- `flutter build` - Usuario lo ejecuta para compilar
- `flutter run` - Usuario lo ejecuta para correr la app
- `flutter logs` - Usuario lo ejecuta para ver logs

**Excepción:** Solo si el usuario EXPLÍCITAMENTE dice "ejecuta flutter analyze" o similar.

## Lectura de archivos

**ANTES de usar Read:**
1. ¿Ya leíste este archivo en los últimos 3 mensajes? → NO leas de nuevo
2. ¿El usuario te dio el contenido/error exacto? → Usa esa info, NO leas
3. ¿Necesitas TODO el archivo o solo una sección? → Usa offset/limit
4. ¿Puedes inferir del contexto existente? → NO leas

**Usa Grep en vez de Read cuando:**
- Buscas una función/clase específica
- Solo necesitas ver dónde se usa algo
- Quieres confirmar que algo existe

## Debugging

**Cuando hay un error:**
1. Pide al usuario logs/errores específicos (NO ejecutes comandos)
2. Analiza el error con el contexto que ya tienes
3. Solo lee archivos si el error no da suficiente info
4. Prioriza fixes pequeños y dirigidos vs leer todo el código

**Para debugging:**
- Agrega logs en puntos clave (1-3 líneas max por método)
- Pide al usuario que ejecute y comparta los logs
- Analiza logs del usuario, NO ejecutes comandos para obtenerlos

## Cambios de código

**Workflow eficiente:**
1. Analiza el problema
2. Propón solución (sin leer archivos si ya los conoces)
3. Haz 1-3 ediciones dirigidas
4. Usuario valida con `flutter analyze` y reporta
5. Si hay error, usuario comparte el mensaje exacto
6. Iteras basado en feedback, NO en leer todo de nuevo

## TODOs y tracking

- Usa TodoWrite solo para tareas multi-paso (>3 pasos)
- NO uses TodoWrite para cambios simples (1-2 archivos)
- Limpia TODOs completados frecuentemente

## Git commits

**Ejecuta comandos git normalmente:**
- `git status`
- `git diff`
- `git log`
- `git add`
- `git commit`

Estos son rápidos y necesarios para el workflow.

## Resumen

**Principio básico:** Confía en el contexto que ya tienes. El usuario es tus ojos y oídos para validación.
