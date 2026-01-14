---
description: Debugging workflow optimizado con mínimo consumo de tokens
triggers:
  - "hay un error"
  - "no funciona"
  - "falla"
  - "exception"
  - "crash"
---

# Efficient Debug

Workflow de debugging que minimiza lecturas de archivos y ejecución de comandos innecesarios.

## Principios

1. **Usuario valida, Claude arregla** - Usuario ejecuta comandos de validación
2. **Confía en el contexto** - No releer archivos ya conocidos
3. **Fixes dirigidos** - Cambios pequeños y verificables
4. **Iteración rápida** - Máximo 2-3 iteraciones por error

## Uso

Cuando el usuario reporta un error, este skill activa automáticamente el workflow eficiente descrito en `instructions.md`.
