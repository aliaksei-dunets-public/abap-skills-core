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

# abap-skill-manager — Core Skill

Manages the lifecycle of ABAP AI skills. Two install modes:
**submodule** (shared core via git submodule) and **manual** (skill files
copied directly into the project).

Reference files (read on demand, not eagerly):

- `references/architecture.md` — full architecture overview, install modes, setup guides.
- `references/templates.md` — wrapper SKILL.md and `project-config.md` templates.
- `references/output-examples.md` — canonical output for `init` / `status` / `validate`.
- `references/registry-maintenance.md` — what to update when a skill is added or its config contract changes.

---

## Phase 0 — Detect install mode

Run before any command. Sets three shorthands: `SKILLS_PATH`, `INSTALL_MODE`, `CORE_PATH`.

- `SKILLS_PATH = .agents/skills`

Probe `$SKILLS_PATH/../skills-core/` (i.e. `.agents/skills-core/`):

| Condition | `INSTALL_MODE` | `CORE_PATH` |
|---|---|---|
| `skills-core/` exists | `submodule` | `.agents/skills-core` |
| `skills-core/` absent | `manual` | *(unused — each skill folder is its own core)* |

**Minimum-state check:**

- Submodule + `$CORE_PATH/skills/` missing → stop, tell user to run
  `git submodule update --init`.
- Manual + `$SKILLS_PATH/` missing or empty → stop, run `instruction`.

---

## Config Safety Rule

Applies to `init`, `update`, `validate`. Never delete or replace content in
any config file (`project-config.md`, `configs/config.md`, linked files).

- Append new content at the end of the file.
- Never modify or remove existing lines.
- After any append, tell the user exactly what was added and where.

---

## Command dispatch

Parse `$ARGUMENTS`. Known commands: `init`, `update`, `status`, `validate`,
`instruction`. Unknown or empty → print **Help Menu** and stop.

---

## Command: `init`

Bootstrap configs (and wrappers in submodule mode) for a new project.

**Skill list source:**

- Submodule → scan `$CORE_PATH/skills/` for subdirs containing `SKILL.md`.
- Manual → scan `$SKILLS_PATH/` for subdirs containing `SKILL.md` (already copied by user).

**Steps:**

1. Ensure `$SKILLS_PATH/` exists (create if missing).
2. If `$SKILLS_PATH/project-config.md` is missing, create it from the
   standard template in `references/templates.md`.
3. For each skill in the source list:

   a. **Submodule mode only — wrapper:** if
      `$SKILLS_PATH/<skill-name>/SKILL.md` is missing, create it from the
      wrapper template in `references/templates.md` (copy `name` and
      `description` from the core skill's frontmatter; use the documented
      fallback if either field cannot be read). If the wrapper already
      exists → mark "already present" and skip.

   b. **Both modes — config file:** if the skill has a `CONFIG_TEMPLATE.md`
      AND `$SKILLS_PATH/<skill-name>/configs/config.md` is missing, generate
      `config.md` using the **Config generation algorithm** below. Skills
      without a `CONFIG_TEMPLATE.md` (e.g. `abap-skill-manager` itself) get
      no `configs/` folder.

4. Print the summary table from `references/output-examples.md` (one row per
   skill, columns: Skill | Wrapper | Config | Action) and the next-steps
   line shown there.

### Config generation algorithm

Used by `init` (create) and `update` (append missing fields). Produces
human-friendly, pre-filled config files clearly marked invalid until the
user reviews and fills them in.

**Source:** read `CONFIG_TEMPLATE.md` for the skill (submodule:
`$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md`; manual:
`$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md`).

**Steps:**

1. Write the file header:
   ```
   # <skill-name> — Project Config
   # ⚠ NOT VALID — review all TODO values before using this skill.
   ```

2. For each `## Required in \`configs/config.md\`` or `## Required Fields` section:
   - Write a `## Required Fields` heading.
   - For each listed field: write a comment line (`# <description from template>`)
     and a value line (`<field>: TODO — <hint from template example, or "fill in">`).

3. For each `## Recommended Fields` section (if present):
   - Write a `## Recommended Fields` heading.
   - For each field: same pattern — comment + `<field>: TODO — <hint>`.

4. If the template contains a fenced ` ```yaml ` block with concrete default
   values, copy it verbatim under a `## Defaults` heading (these fields are
   valid as-is; no TODO needed).

5. For all other sections (e.g. Category Control, Rule Suppression, Output
   Mode): write the section heading and a one-line reference comment pointing
   to the template, but do **not** duplicate the full content.

All Required and Recommended field values must start with `TODO` — the file
is intentionally non-functional until the user fills in real values.

---

## Command: `update`

### Submodule mode

1. Pull latest core:
   ```bash
   cd $CORE_PATH && git pull origin main
   ```
   Report git output (commits pulled or "already up to date").
2. Diff `$CORE_PATH/skills/` against `$SKILLS_PATH/`. Run `init` step 3a for
   skills that have no wrapper yet. Report each new wrapper.
3. **Config enrichment:** for each skill that already has a
   `$SKILLS_PATH/<skill>/configs/config.md`, compare it against
   `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md`. For every Required or
   Recommended field that is not yet present in `config.md`, append it at
   the end of the file using the Config generation algorithm (comment +
   `TODO` value). Report appended fields per skill; if nothing is missing,
   report "config up to date".
4. Stage the submodule pointer:
   ```bash
   git add $CORE_PATH
   git status --short $CORE_PATH
   ```
   Report whether the pointer SHA changed.
5. Print summary: skills updated, new wrappers (if any), config fields added
   (if any), submodule pointer status.

### Manual mode

Automation is not available. Tell the user:

> Manual install detected — automatic update not available. See
> `references/architecture.md` § "Manual update procedure" for the file-replace
> steps. Run `abap-skill-manager validate` afterwards.

---

## Command: `status`

Report the current state at a glance.

1. Resolve install mode (Phase 0).
2. **Submodule only** — collect version info:
   ```bash
   cd $CORE_PATH && git rev-parse --short HEAD
   cd $CORE_PATH && git fetch origin main --quiet 2>/dev/null && git rev-parse --short origin/main
   ```
3. Build skill list:
   - Submodule → scan `$CORE_PATH/skills/`.
   - Manual → scan `$SKILLS_PATH/` for subdirs with a `SKILL.md`.
4. For each skill, collect: wrapper exists, config exists, TODO count in
   `$SKILLS_PATH/<skill>/configs/**`.
5. Count TODOs in `$SKILLS_PATH/project-config.md`.
6. Render the matching table from `references/output-examples.md`
   (submodule or manual variant). Skills with no `CONFIG_TEMPLATE.md` use
   `—` for Config/TODOs and note "no config required".

---

## Command: `validate`

Verify required config fields and run skill self-tests.

1. **`project-config.md` checks:**
   - Read `$SKILLS_PATH/project-config.md`. Flag any field whose value is
     `TODO` or absent.
   - **Submodule only** — for each wrapper, if its `description` still
     contains `TODO`, report WARNING: "description in wrapper
     `<skill-name>/SKILL.md` was not copied from core. Run
     `abap-skill-manager init` to regenerate or fill it in manually."

2. **CONFIG_TEMPLATE list:**
   - Submodule → `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md`.
   - Manual → `$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md`.
   - If missing → note "template not found — cannot validate" and skip.

3. **Required-field check:** for each skill with a `CONFIG_TEMPLATE.md`,
   extract field names from every heading that starts with `## Required`
   (covers both `## Required Fields ...` and `## Required in <path>` —
   templates use either form). Group fields by their target file:
   - `## Required in \`project-config.md\`` → check `$SKILLS_PATH/project-config.md`.
   - `## Required in \`configs/<file>.md\`` → check `$SKILLS_PATH/<skill>/configs/<file>.md`.
   - `## Required Fields ...` (no path) → check `$SKILLS_PATH/<skill>/configs/config.md`
     and any `→ Read configs/*.md` linked files.

   Ignore optional examples, category lists, allowed-value notes, and other
   explanatory text outside `## Required ...` headings. They document
   behavior, but they do not change validation unless a required field was
   added, removed, or renamed.

   A field passes if present and its value does not contain `TODO`.

4. Render the report from `references/output-examples.md` (sections:
   `project-config.md`, each skill's `configs/`, "Skill self-tests",
   summary line). If everything passes (config + tests), replace the body
   with: "✅ All required fields are filled in and all skill self-tests
   pass. Ready to use." If config is OK but tests fail, the overall result
   is non-zero — name the failing tests so the user can investigate.

---

## Command: `instruction`

Read `references/architecture.md` and print its full contents to the user.

---

## Help Menu

```
abap-skill-manager <command>

Commands:
  init         Bootstrap skill wrappers and config files for a new project
  update       Pull latest core + init wrappers for any new skills, append missing config fields
               (submodule mode only — manual mode prints a manual procedure)
  status       Install mode, submodule SHA, wrapper/config presence, TODO counts
  validate     Check required config fields + run skill self-tests
  instruction  Show architecture overview and setup guide (both install modes)
```
