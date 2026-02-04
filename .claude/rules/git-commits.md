# Reglas para Commits de Git

## Principio Fundamental

**NUNCA ejecutar `git commit` automáticamente.**

El desarrollador siempre debe tener control total sobre cuándo y cómo se crean los commits.

---

## Workflow de Commits

### Cuando el Código Está Listo

1. **Preparar archivos:**
   ```bash
   git add [archivos específicos]
   # o
   git add .
   ```

2. **Presentar commit message:**
   - Claude DEBE presentar un mensaje de commit bien formado
   - Claude NO DEBE ejecutar el comando git commit
   - El mensaje debe seguir el estilo del repositorio

3. **Desarrollador ejecuta manualmente:**
   ```bash
   git commit -m "mensaje"
   ```

### Formato del Mensaje de Commit

Claude debe presentar el mensaje en un bloque de código copiable:

```
Aquí está el mensaje de commit propuesto:

```bash
git commit -m "$(cat <<'EOF'
Título del commit

Descripción:
  - Cambio 1
  - Cambio 2
  - Cambio 3

Technical Details:
  - Detalle técnico 1
  - Detalle técnico 2

Testing:
  ✅ flutter analyze
  ✅ Compiles sin errores

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

Ejecuta este comando cuando estés listo para commitear.
```

---

## Excepciones

**NO HAY EXCEPCIONES.**

Incluso en estos casos, NO ejecutar commit automáticamente:
- ❌ Después de implementar un plan completo
- ❌ Después de fix crítico
- ❌ Cuando el usuario dice "commit esto"
- ❌ Al finalizar una feature

**Siempre:** Presentar el mensaje, dejar que el desarrollador ejecute.

---

## Comandos Git Permitidos

Claude PUEDE ejecutar estos comandos git:

| Comando | Propósito | Permitido |
|---------|-----------|-----------|
| `git status` | Ver estado | ✅ SÍ |
| `git diff` | Ver cambios | ✅ SÍ |
| `git log` | Ver historial | ✅ SÍ |
| `git add` | Stage archivos | ✅ SÍ |
| `git commit` | Crear commit | ❌ **NUNCA** |
| `git push` | Push a remote | ❌ **NUNCA** |
| `git pull` | Pull cambios | ❌ **NUNCA** |
| `git rebase` | Rebase | ❌ **NUNCA** |
| `git reset` | Reset | ❌ **NUNCA** |
| `git checkout` | Cambiar branch | ❌ **NUNCA** |

---

## Workflow Después de Implementación

### ✅ CORRECTO

```
Claude: He completado la implementación de Feature 4.5.

Archivos modificados:
- lib/services/system_info_service.dart (nuevo)
- lib/providers/voice_command_provider.dart (modificado)
- android/.../MainActivity.kt (modificado)

Cambios staged y listos para commit.

Aquí está el mensaje de commit propuesto:

```bash
git commit -m "$(cat <<'EOF'
Implement Feature 4.5: System Commands

New Features:
  - System info commands (hora, fecha, batería)

Technical Implementation:
  - Platform Channel Flutter ↔ Kotlin
  - Accessible formats for TTS

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

Ejecuta este comando cuando estés listo.
```

### ❌ INCORRECTO

```
Claude: He completado la implementación.

[ejecuta git commit automáticamente]

Commit creado: abc1234
```

---

## Razones para Esta Regla

1. **Control del desarrollador:** El desarrollador debe revisar cambios antes de commit
2. **Flexibilidad:** Permite ajustar el mensaje o agregar más cambios
3. **Seguridad:** Evita commits accidentales con errores
4. **Buenas prácticas:** El desarrollador es responsable del historial de git

---

## Si el Usuario Dice "Commitea"

**Incluso si el usuario dice explícitamente "commitea" o "haz commit":**

1. Stage los archivos (`git add`)
2. Presenta el mensaje de commit
3. Recuerda al usuario que debe ejecutar el comando manualmente

**Respuesta sugerida:**
```
He staged los cambios. Aquí está el commit message:

[mensaje de commit]

Ejecuta el comando cuando estés listo. Esta es una buena práctica
para mantener control sobre tu historial de git.
```

---

## Checklist Pre-Commit (para Claude)

Antes de presentar un mensaje de commit, verificar:

- [ ] Todos los archivos están staged (`git add`)
- [ ] El mensaje sigue el estilo del repositorio (revisar `git log`)
- [ ] Incluye Co-Authored-By cuando corresponda
- [ ] NO ejecutar `git commit` bajo ninguna circunstancia
- [ ] Presentar el comando completo para que el usuario lo copie

---

## Resumen

**UNA REGLA SIMPLE:**

Claude prepara, el desarrollador ejecuta.

**NUNCA `git commit`.**
**SIEMPRE presentar el mensaje.**
