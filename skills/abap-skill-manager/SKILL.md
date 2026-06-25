---
name: abap-skill-manager
description: >
  Manage the ABAP skills lifecycle in a project (bootstrap wrappers and
  config files, pull core updates, audit state, validate required fields).
  Use when the user invokes any of: "init skills", "update skills",
  "skill status", "validate config", "explain the skills architecture",
  or asks to add/audit/sync ABAP skills.
  Commands: init | update | status | validate | instruction.
---

# abap-skill-manager

Two install modes: **submodule** (shared core via git submodule) and
**manual** (skill files copied directly into the project).

Reference files (read on demand):

- `references/architecture.md` — install modes, paths, setup guides.
- `references/templates.md` — wrapper SKILL.md and `project-config.md` templates.
- `references/config-generation.md` — algorithm for generating `configs/config.md`.
- `references/output-examples.md` — canonical output for `init` / `status` / `validate`.
- `references/registry-maintenance.md` — what to update when a skill is added or its config contract changes.

---

## Phase 0 — Detect install mode

Run before any command. Sets: `SKILLS_PATH = .agents/skills`, `INSTALL_MODE`, `CORE_PATH`.

Probe `.agents/skills-core/`:

| Condition | `INSTALL_MODE` | `CORE_PATH` |
|---|---|---|
| `skills-core/` exists | `submodule` | `.agents/skills-core` |
| `skills-core/` absent | `manual` | *(unused)* |

**Stop conditions:**
- Submodule + `$CORE_PATH/skills/` missing → tell user: `git submodule update --init`.
- Manual + `$SKILLS_PATH/` missing or empty → run `instruction`.

---

## Config Safety Rule

Applies to `init`, `update`, `validate`. Never delete or replace content in
any config file (`project-config.md`, `configs/config.md`, linked files).
Append only. After any append, report what was added and where.

---

## Command dispatch

Parse `$ARGUMENTS`. Known: `init`, `update`, `status`, `validate`, `instruction`.
Unknown or empty → print **Help Menu** and stop.

---

## Command: `init`

**Skill list source:**
- Submodule → `$CORE_PATH/skills/` subdirs with `SKILL.md`.
- Manual → `$SKILLS_PATH/` subdirs with `SKILL.md`.

**Steps:**

1. Ensure `$SKILLS_PATH/` exists (create if missing).
2. If `$SKILLS_PATH/project-config.md` missing → create from template in `references/templates.md`.
3. For each skill:

   a. **Submodule only — wrapper:** if `$SKILLS_PATH/<skill>/SKILL.md` missing → create from
      wrapper template in `references/templates.md` (copy `name`/`description` from core
      frontmatter; use documented fallback if missing). If already exists → mark "already present", skip.

   b. **Both modes — config:** if skill has `CONFIG_TEMPLATE.md` AND
      `$SKILLS_PATH/<skill>/configs/config.md` missing → generate it per
      `references/config-generation.md`. Skills without `CONFIG_TEMPLATE.md` get no `configs/` folder.

4. Print summary table from `references/output-examples.md` and next-steps line.

---

## Command: `update`

### Submodule mode

1. Pull latest core:
   ```bash
   cd $CORE_PATH && git pull origin main
   ```
   Report commits pulled or "already up to date".
2. Diff `$CORE_PATH/skills/` vs `$SKILLS_PATH/`. Run init step 3a for skills with no wrapper. Report new wrappers.
3. **Config enrichment:** for each skill with existing `configs/config.md`, compare against
   `CONFIG_TEMPLATE.md`. Append any Required/Recommended field not yet present, using
   `references/config-generation.md` (comment + `TODO` value). Report appended fields or "config up to date".
4. Stage submodule pointer:
   ```bash
   git add $CORE_PATH && git status --short $CORE_PATH
   ```
   Report whether pointer SHA changed.
5. Print summary: skills updated, new wrappers, config fields added, submodule pointer status.

### Manual mode

> Manual install detected — automatic update not available. See
> `references/architecture.md` § "Manual update procedure". Run `abap-skill-manager validate` afterwards.

---

## Command: `status`

1. **Submodule only** — collect version info:
   ```bash
   cd $CORE_PATH && git rev-parse --short HEAD
   cd $CORE_PATH && git fetch origin main --quiet 2>/dev/null && git rev-parse --short origin/main
   ```
2. Build skill list: submodule → scan `$CORE_PATH/skills/`; manual → scan `$SKILLS_PATH/` for subdirs with `SKILL.md`.
3. Per skill: wrapper exists, config exists, TODO count in `$SKILLS_PATH/<skill>/configs/**`.
4. Count TODOs in `$SKILLS_PATH/project-config.md`.
5. Render table from `references/output-examples.md`. Skills without `CONFIG_TEMPLATE.md` use `—` for Config/TODOs.

---

## Command: `validate`

1. **`project-config.md`:** flag any field with value `TODO` or absent.
   Submodule only: if any wrapper `description` contains `TODO` → WARNING: regenerate with `init` or fill manually.

2. **CONFIG_TEMPLATE source:**
   - Submodule → `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md`.
   - Manual → `$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md`.
   - Missing → "template not found — cannot validate", skip.

3. **Required-field check:** extract field names from every `## Required` heading:
   - `## Required in \`project-config.md\`` → check `$SKILLS_PATH/project-config.md`.
   - `## Required in \`configs/<file>.md\`` → check `$SKILLS_PATH/<skill>/configs/<file>.md`.
   - `## Required Fields` (no path) → check `$SKILLS_PATH/<skill>/configs/config.md` + lazy-linked files.

   Ignore optional examples, category lists, and explanatory text outside `## Required` headings.
   Field passes if present and value does not contain `TODO`.

4. Render report from `references/output-examples.md`. If all pass: "✅ All required fields are filled
   in and all skill self-tests pass. Ready to use." If tests fail: report non-zero result and name failing tests.

---

## Command: `instruction`

Read `references/architecture.md` and print its full contents.

---

## Help Menu

```
abap-skill-manager <command>

Commands:
  init         Bootstrap skill wrappers and config files for a new project
  update       Pull latest core, init new wrappers, append missing config fields
               (submodule only — manual mode prints manual procedure)
  status       Install mode, submodule SHA, wrapper/config presence, TODO counts
  validate     Check required config fields + run skill self-tests
  instruction  Show architecture overview and setup guide
```
