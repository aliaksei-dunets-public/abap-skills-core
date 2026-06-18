---
name: abap-skill-manager
description: >
  Manage the ABAP skills lifecycle in a project (bootstrap wrappers and
  config stubs, pull core updates, audit state, validate required fields,
  commit/push). Use when the user invokes any of: "init skills",
  "update skills", "skill status", "validate config", "push skills",
  "explain the skills architecture", or asks to add/audit/sync ABAP skills.
  Commands: init | update | status | validate | push | instruction.
---

# abap-skill-manager — Core Skill

Manages the lifecycle of ABAP AI skills. Two install modes:
**submodule** (shared core via git submodule) and **manual** (skill files
copied directly into the project).

Reference files (read on demand, not eagerly):

- `references/architecture.md` — full architecture overview, install modes, setup guides, platform paths.
- `references/templates.md` — wrapper SKILL.md, config stub, and `project-config.md` templates.
- `references/output-examples.md` — canonical output for `init` / `status` / `validate`.
- `references/registry-maintenance.md` — what to update when a skill is added or its config contract changes.

---

## Phase 0 — Detect platform and install mode

Run before any command. Sets four shorthands: `PLATFORM`, `SKILLS_PATH`,
`INSTALL_MODE`, `CORE_PATH`.

**Platform detection** (probe `.claude/` and `.agents/`; if both exist,
prefer `agents`; if neither, default to `agents`):

| Detected folder | `PLATFORM` | `SKILLS_PATH` |
|---|---|---|
| `.claude/` | `claude` | `.claude/skills` |
| `.agents/` | `copilot` | `.agents/skills` |

**Install-mode detection** (probe `$SKILLS_PATH/../skills-core/`):

| Condition | `INSTALL_MODE` | `CORE_PATH` |
|---|---|---|
| `skills-core/` exists | `submodule` | `.claude/skills-core` or `.agents/skills-core` |
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
`push`, `instruction`. Unknown or empty → print **Help Menu** and stop.

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

   b. **Both modes — config stub:** if the skill has a `CONFIG_TEMPLATE.md`
      AND `$SKILLS_PATH/<skill-name>/configs/config.md` is missing, create
      the stub from `references/templates.md`. Skills without a
      `CONFIG_TEMPLATE.md` (e.g. `abap-skill-manager` itself) get no
      `configs/` folder.

4. Print the summary table from `references/output-examples.md` (one row per
   skill, columns: Skill | Wrapper | Config | Action) and the next-steps
   line shown there.

---

## Command: `update`

### Submodule mode

1. Pull latest core:
   ```bash
   cd $CORE_PATH && git pull origin main
   ```
   Report git output (commits pulled or "already up to date").
2. Diff `$CORE_PATH/skills/` against `$SKILLS_PATH/`. Run `init` step 3 for
   skills that have no wrapper yet. Report each new wrapper.
3. Stage the submodule pointer:
   ```bash
   git add $CORE_PATH
   git status --short $CORE_PATH
   ```
   Report whether the pointer SHA changed.
4. Print summary: skills updated, new wrappers (if any), submodule pointer
   status.

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
   - `## Source Reader` → `source_reader`:
     - Absent → WARNING: "source_reader not set; defaulting to auto. Add
       `source_reader: auto` under `## Source Reader` to suppress."
     - Value not in `{auto, abap-vs-reader, mcp, ask}` → ERROR:
       "source_reader has unknown value '<value>'. Allowed: auto |
       abap-vs-reader | mcp | ask."

2. **CONFIG_TEMPLATE list:**
   - Submodule → `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md`.
   - Manual → `$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md`.
   - If missing → note "template not found — cannot validate" and skip.

3. **Required-field check:** for each skill with a `CONFIG_TEMPLATE.md`,
   extract field names from every heading that starts with `## Required`
   (covers both `## Required Fields ...` and `## Required in <path>` —
   templates use either form). Group fields by their target file:
   - `## Required in `project-config.md`` → check `$SKILLS_PATH/project-config.md`.
   - `## Required in `configs/<file>.md`` → check `$SKILLS_PATH/<skill>/configs/<file>.md`.
   - `## Required Fields ...` (no path) → check `$SKILLS_PATH/<skill>/configs/config.md`
     and any `→ Read configs/*.md` linked files.

    Ignore optional examples, category lists, allowed-value notes, and other explanatory text outside `## Required ...` headings. They document behavior, but they do not change validation unless a required field was added, removed, or renamed.

   A field passes if present and its value does not contain `TODO`.

4. **Skill self-tests:** for each skill (under `$CORE_PATH/skills/<skill>`
   in submodule mode, `$SKILLS_PATH/<skill>` in manual mode), if
   `<skill_root>/scripts/tests/Invoke-Tests.ps1` exists, run:
   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass `
     -File "<skill_root>/scripts/tests/Invoke-Tests.ps1"
   ```

   | Exit code | Reporting |
   |---|---|
   | `0` | `✓ tests passed (N)` — N from runner's summary line |
   | `1` | `✗ tests failed` — surface failure messages from runner output |
   | `2` | `⚠ test runner error` — surface runner stderr |

   `scripts/` exists but no `tests/` → record `— no tests` (not an error).
   No `scripts/` directory → omit the row silently.

5. Render the report from `references/output-examples.md` (sections:
   `project-config.md`, each skill's `configs/`, "Skill self-tests",
   summary line). If everything passes (config + tests), replace the body
   with: "✅ All required fields are filled in and all skill self-tests
   pass. Ready to use." If config is OK but tests fail, the overall result
   is non-zero — name the failing tests so the user can investigate.

---

## Command: `push`

Stage, commit, and push pending skills changes.

1. Show changes:
   - Submodule → `git status --short $SKILLS_PATH $CORE_PATH`.
   - Manual → `git status --short $SKILLS_PATH`.
2. Nothing changed → "Nothing to commit." and stop.
3. List the files to be committed and ask for explicit confirmation.
4. Stage + commit:
   - Submodule → `git add $SKILLS_PATH/ $CORE_PATH`
   - Manual → `git add $SKILLS_PATH/`
   - Then: `git commit -m "chore: update ABAP skills config"`
5. `git push` and report commit SHA + push output.

---

## Command: `instruction`

Read `references/architecture.md` and print its full contents to the user.

---

## Help Menu

```
abap-skill-manager <command>

Commands:
  init         Bootstrap skill wrappers and config stubs for a new project
  update       Pull latest core + init wrappers for any new skills
               (submodule mode only — manual mode prints a manual procedure)
  status       Install mode, submodule SHA, wrapper/config presence, TODO counts
  validate     Check required config fields + run skill self-tests
  push         Stage, commit, and push skills changes
  instruction  Show architecture overview and setup guide (both install modes)
```
