---
name: abap-skill-manager
description: >
  Manage the ABAP skills lifecycle. Use when the user says "init skills",
  "update skills", "skill status", "validate config", "push skills", or
  "explain the skills architecture". Commands: init, update, status, validate,
  push, instruction.
---

# abap-skill-manager — Core Skill

Manages the lifecycle of ABAP AI skills in any project. Supports two install
modes: **submodule** (shared core via git submodule) and **manual** (skill
files copied directly into the project).

---

## Phase 0 — Detect Platform and Install Mode

Before executing any command, run the following checks to set four variables
used throughout this skill: `PLATFORM`, `SKILLS_PATH`, `INSTALL_MODE`,
`CORE_PATH`.

### Step 1 — Detect platform

```bash
ls .claude/ 2>/dev/null && echo "claude"
ls .agents/ 2>/dev/null && echo "copilot"
```

| Detected folder | `PLATFORM` | `SKILLS_PATH` |
|---|---|---|
| `.claude/` | `claude` | `.claude/skills` |
| `.agents/` | `copilot` | `.agents/skills` |

If both exist, prefer `claude`. If neither exists, use `claude` as the default.

### Step 2 — Detect install mode

```bash
# Claude Code
ls .claude/skills-core 2>/dev/null && echo "submodule" || echo "manual"

# Copilot
ls .agents/skills-core 2>/dev/null && echo "submodule" || echo "manual"
```

| Condition | `INSTALL_MODE` | `CORE_PATH` |
|---|---|---|
| `$SKILLS_PATH/../skills-core/` exists | `submodule` | `.claude/skills-core` or `.agents/skills-core` |
| `$SKILLS_PATH/../skills-core/` absent | `manual` | *(not used — each skill folder is its own core)* |

### Step 3 — Validate minimum state

- **Submodule mode:** If `$CORE_PATH/skills/` does not exist, stop and tell
  the user to run `git submodule update --init`.
- **Manual mode:** If `$SKILLS_PATH/` does not exist or is empty, stop and
  show the `instruction` output.

Use `SKILLS_PATH`, `INSTALL_MODE`, and `CORE_PATH` as shorthand throughout.

---

## Command Dispatch

Parse $ARGUMENTS. If no argument or an unrecognised argument is provided,
output the **Help Menu** (at the end of this file) and stop.

Known commands: `init`, `update`, `status`, `validate`, `push`, `instruction`.

---

## Command: `init`

Bootstrap configs for a new project. Behaviour differs by install mode.

---

### `init` — Submodule mode

Creates wrapper SKILL.md and `configs/config.md` stubs for every skill found
in the core that is not yet present in the project.

**Steps:**

1. Ensure `$SKILLS_PATH/` exists (create if missing).

2. Scan `$CORE_PATH/skills/` — collect every subdirectory that contains a
   `SKILL.md`. This is the **core skill list**.

3. Check if `$SKILLS_PATH/project-config.md` exists. If missing, create it
   with the standard template (see template at end of this section).

4. For each skill in the core skill list:

   **a.** If `$SKILLS_PATH/<skill-name>/SKILL.md` already exists → skip,
   mark as "already present".

   **b.** If wrapper is missing, create `$SKILLS_PATH/<skill-name>/SKILL.md`:

   ```markdown
   ---
   name: <skill-name>
   description: >
     TODO — fill in trigger description for <skill-name>
   ---

   Read `$SKILLS_PATH/project-config.md` for project-wide context.
   Read `$CORE_PATH/skills/<skill-name>/SKILL.md` for core instructions.
   Read `$SKILLS_PATH/<skill-name>/configs/config.md` for project-specific rules.
   If config.md references additional files, read those too before proceeding.

   Apply core instructions using the project context and all loaded config files.
   ```

   **c.** If the core skill has a `CONFIG_TEMPLATE.md` AND
   `$SKILLS_PATH/<skill-name>/configs/config.md` does not yet exist, create it:

   ```markdown
   # <skill-name> — Project Config

   TODO — Fill in required fields.
   See $CORE_PATH/skills/<skill-name>/CONFIG_TEMPLATE.md for required fields.
   ```

   Skills without a `CONFIG_TEMPLATE.md` (e.g. `abap-skill-manager` itself)
   do not get a `configs/` folder.

5. Print summary table and next steps (see below).

---

### `init` — Manual mode

Skill SKILL.md files are already present in `$SKILLS_PATH/<skill>/` (copied
by the user). Only create missing config stubs and `project-config.md`.

**Steps:**

1. Scan `$SKILLS_PATH/` — collect every subdirectory that contains a
   `SKILL.md`. This is the **installed skill list**.

2. Check if `$SKILLS_PATH/project-config.md` exists. If missing, create it
   with the standard template.

3. For each installed skill:

   **a.** Check if a `CONFIG_TEMPLATE.md` exists in
   `$SKILLS_PATH/<skill-name>/CONFIG_TEMPLATE.md`.

   **b.** If yes and `$SKILLS_PATH/<skill-name>/configs/config.md` does not
   yet exist, create it:

   ```markdown
   # <skill-name> — Project Config

   TODO — Fill in required fields.
   See $SKILLS_PATH/<skill-name>/CONFIG_TEMPLATE.md for required fields.
   ```

   Skills without a `CONFIG_TEMPLATE.md` do not get a `configs/` folder.

4. Print summary table and next steps.

---

### `init` — Summary table (both modes)

| Skill | Wrapper | Config | Action |
|---|---|---|---|
| abap-code-review | ✓ | ✓ | skipped (already present) |
| abap-vs-reader | created | created | ✓ |

Then: "Fill in `$SKILLS_PATH/project-config.md` and each `configs/config.md`.
Run `abap-skill-manager validate` to check for missing required fields."

---

### project-config.md standard template

```markdown
# Project Configuration

## Project
Name: TODO — fill in project name
System: TODO — SAP system ID (e.g. DEMO_001_EN)
Platform: S/4HANA On-Premise
Primary namespace: TODO — e.g. /DEMO/

## DDIC Naming
- Domain: TODO — e.g. /demo/do_*
- Data Element: TODO — e.g. /demo/de_*
- Structure: TODO — e.g. /demo/s_*
- Table Type: TODO — e.g. /demo/t_*
- DB Table: TODO — e.g. /demo/a_*
- Draft Table: TODO — e.g. /demo/d_*

## CDS Naming
- Interface View: TODO — e.g. /demo/I_*
- Projection View: TODO — e.g. /demo/C_*
- Base View: TODO — e.g. /demo/R_*

## RAP
- Behavior Implementation Class: TODO — e.g. /demo/bp_<RootCDSViewEntityName>
- Auth check class: TODO — e.g. /demo/cl_auth_check_*
- Obsolete package: TODO — e.g. /DEMO/OBSOLETE

## Service Binding
Pattern: UI_*_O2 / UI_*_O4 / API_*_O4
```

---

## Command: `update`

### `update` — Submodule mode

Pull the latest core skills, then initialise wrappers for any new skills that
exist in the core but not yet in the project.

**Steps:**

1. Pull latest core:
   ```bash
   cd $CORE_PATH && git pull origin main
   ```
   Report the git output (commits pulled, or "already up to date").

2. Scan `$CORE_PATH/skills/` for all skill folders. Compare against
   `$SKILLS_PATH/` — collect skills that have no wrapper yet.

3. If new skills are found, run the `init` logic (steps 4–5 of submodule
   `init`) for those skills only. Report each new wrapper created.

4. Stage the updated submodule pointer:
   ```bash
   git add $CORE_PATH
   git status --short $CORE_PATH
   ```
   Report whether the pointer changed (new SHA) or was already current.

5. Print summary: skills updated, new wrappers created (if any), submodule
   pointer status.

---

### `update` — Manual mode

Automatic update is not available in manual mode.

Tell the user:

> **Manual install detected — automatic update not available.**
>
> To update skills to the latest version:
> 1. Download or clone the latest core from
>    `https://github.com/aliaksei-dunets-public/abap-skills-core`
> 2. For each skill you use, replace:
>    - `$SKILLS_PATH/<skill>/SKILL.md`
>    - `$SKILLS_PATH/<skill>/references/` (if present)
>    - `$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md` (if present)
>    - `$SKILLS_PATH/<skill>/scripts/` (if present)
> 3. Do **not** overwrite your `configs/` folder — that is your project config.
> 4. After replacing files, run `abap-skill-manager validate` to check for
>    new required fields introduced by the update.
>
> To switch to submodule mode and gain automatic updates, see
> `abap-skill-manager instruction`.

---

## Command: `status`

Report the current state of the skills installation at a glance.

**Steps:**

1. Determine install mode (from Phase 0).

2. **Submodule mode only:** collect version info:
   ```bash
   cd $CORE_PATH && git rev-parse --short HEAD
   cd $CORE_PATH && git fetch origin main --quiet 2>/dev/null && git rev-parse --short origin/main
   ```

3. Build the skill list:
   - Submodule mode: scan `$CORE_PATH/skills/`
   - Manual mode: scan `$SKILLS_PATH/` for subdirectories with a `SKILL.md`

4. For each skill, collect:
   - Wrapper exists? (`$SKILLS_PATH/<skill>/SKILL.md`)
   - Config exists? (`$SKILLS_PATH/<skill>/configs/config.md`)
   - TODO count in all files under `$SKILLS_PATH/<skill>/configs/`

5. Count TODOs in `$SKILLS_PATH/project-config.md`.

6. Output:

   **Submodule mode:**
   ```
   ## Skills Status

   Install mode: submodule
   Core: <current-SHA>  Remote: <remote-SHA>  [UP TO DATE | BEHIND N commits — run: abap-skill-manager update]

   | Skill                 | Wrapper | Config | TODOs | Notes                         |
   |-----------------------|---------|--------|-------|-------------------------------|
   | abap-code-review      | ✓       | ✓      | 0     |                               |
   | abap-run-unit-tests   | ✓       | ✓      | 2     | configs/config.md has 2 TODOs |
   | abap-skill-manager    | ✓       | —      | —     | no config required            |
   | abap-unit-test-creator| ✓       | ✓      | 0     |                               |
   | abap-vs-reader        | ✓       | ✓      | 0     |                               |

   project-config.md: ✓  (TODOs: 0)
   ```

   **Manual mode:**
   ```
   ## Skills Status

   Install mode: manual (no submodule — update via abap-skill-manager update)

   | Skill                 | SKILL.md | Config | TODOs | Notes                         |
   |-----------------------|----------|--------|-------|-------------------------------|
   | abap-code-review      | ✓        | ✓      | 0     |                               |
   | abap-vs-reader        | ✓        | ✓      | 0     |                               |

   project-config.md: ✓  (TODOs: 0)
   ```

---

## Command: `validate`

Check that all required config fields (from CONFIG_TEMPLATE.md) are filled in
for every skill.

**Steps:**

1. Read `$SKILLS_PATH/project-config.md`. Flag any field whose value is `TODO`
   or is absent.

2. Build CONFIG_TEMPLATE list:
   - Submodule mode: read `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md`
   - Manual mode: read `$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md`
   - If CONFIG_TEMPLATE.md is missing for a skill, note "template not found —
     cannot validate" and skip that skill.

3. For each skill with a CONFIG_TEMPLATE.md, extract field names listed under
   `## Required Fields`. For each required field, check
   `$SKILLS_PATH/<skill>/configs/config.md` and any `→ Read configs/*.md`
   linked files. A field passes if it is present and its value does not
   contain `TODO`.

4. Output a validation report:

   ```
   ## Validation Report

   ### project-config.md
   ✓ primary_namespace: /DEMO/
   ✗ system — still contains TODO

   ### abap-code-review/configs/
   ✓ primary_namespace
   ✓ ddic_naming_rules  (configs/naming.md)
   ✗ auth_check_class_pattern — field missing or TODO

   ### abap-vs-reader/configs/
   ✓ system_id
   ✓ cache_base
   ✓ repotree_package_path

   ---
   Summary: 2 validation error(s).
   Fix the flagged fields, then run `abap-skill-manager validate` again.
   ```

   If all checks pass: "✅ All required fields are filled in. Ready to use."

---

## Command: `push`

Stage, commit, and push all pending skills changes.

**Steps:**

1. Check what has changed:
   - Submodule mode: `git status --short $SKILLS_PATH $CORE_PATH`
   - Manual mode: `git status --short $SKILLS_PATH`

2. If nothing changed: "Nothing to commit." and stop.

3. Show the user the list of files to be committed and ask for explicit
   confirmation before proceeding.

4. Stage and commit:
   - Submodule mode:
     ```bash
     git add $SKILLS_PATH/ $CORE_PATH
     git commit -m "chore: update ABAP skills config"
     ```
   - Manual mode:
     ```bash
     git add $SKILLS_PATH/
     git commit -m "chore: update ABAP skills config"
     ```

5. Push:
   ```bash
   git push
   ```

6. Report the result (commit SHA + push output).

---

## Command: `instruction`

Output the architecture overview and setup guide below verbatim.

---

## ABAP Skills Architecture

### Overview

Three-layer architecture separating platform-independent skill logic from
project-specific configuration. Two install modes are supported.

---

### Install Mode A — Submodule (recommended)

```
abap-skills-core/          ← git submodule, shared across all projects
  skills/
    <skill-name>/
      SKILL.md             ← core logic, no project names, /DEMO/ examples only
      CONFIG_TEMPLATE.md   ← documents required/recommended config fields
      references/          ← supporting reference files
      scripts/             ← helper scripts (e.g. open-abap.ps1)

.claude/skills/            ← project layer, committed to the project repo
  project-config.md        ← shared context: namespace, naming, system ID
  <skill-name>/
    SKILL.md               ← wrapper: reads core + project-config + config
    configs/
      config.md            ← required entry point (lazy-links other files)
```

**Layers:**

- **Core** (`abap-skills-core`): platform-independent, `/DEMO/` in all examples.
  Updated across all projects via `abap-skill-manager update`.
- **Wrapper** (`skills/<skill>/SKILL.md`): thin file instructing the agent
  to read `project-config.md` → core SKILL.md → `configs/config.md`.
- **Config** (`skills/<skill>/configs/`): project-specific values.
  `config.md` is always the entry point; lazy-links to additional files:
  ```
  → Read configs/naming.md for naming convention rules.
  → Read configs/system.md for ADT connection details.
  ```

**Setup:**

```bash
# Step 1 — Add submodule (Claude Code)
git submodule add https://github.com/aliaksei-dunets-public/abap-skills-core.git .claude/skills-core
git submodule update --init
```

> If git rejects due to `.gitignore`, use `-f` and add these exclusions:
> ```
> !.claude/skills-core/
> !.claude/skills-core/**
> !.claude/skills/
> !.claude/skills/**
> ```

```
# Step 2 — Bootstrap wrappers and config stubs
abap-skill-manager init

# Step 3 — Fill in project-config.md and each configs/config.md
# See each skill's CONFIG_TEMPLATE.md for required fields
abap-skill-manager validate

# Step 4 — Commit
abap-skill-manager push
```

**Updating core skills:**
```
abap-skill-manager update
```
Pulls the latest core, creates wrappers for any newly added skills, and
updates the submodule pointer.

---

### Install Mode B — Manual copy

Use when git submodules are not practical or when you want to use a single
skill without the full submodule setup.

```
.claude/skills/            ← project layer, committed to the project repo
  project-config.md        ← shared context
  <skill-name>/
    SKILL.md               ← core logic copied directly (no wrapper)
    CONFIG_TEMPLATE.md     ← copied from abap-skills-core
    references/            ← copied from abap-skills-core
    scripts/               ← copied from abap-skills-core
    configs/
      config.md            ← project-specific entry point
```

**Setup:**

1. Download or clone `https://github.com/aliaksei-dunets-public/abap-skills-core`
2. Copy the desired skill folder(s) from `skills/<skill-name>/` into
   `$SKILLS_PATH/<skill-name>/`
3. Create config stubs:
   ```
   abap-skill-manager init
   ```
4. Fill in `project-config.md` and each `configs/config.md`.
5. Commit with `abap-skill-manager push`.

**Important — abap-vs-reader script path:**

In submodule mode, `abap-vs-reader/SKILL.md` references the script as:
```
.claude/skills-core/skills/abap-vs-reader/scripts/open-abap.ps1
```
In manual mode, the script is copied into the skill folder, so the path
becomes:
```
.claude/skills/abap-vs-reader/scripts/open-abap.ps1
```
After copying, update the path in `$SKILLS_PATH/abap-vs-reader/SKILL.md`
accordingly (search for `skills-core/skills/abap-vs-reader/scripts` and
replace with `skills/abap-vs-reader/scripts`).

**Trade-off vs submodule:**

| | Submodule | Manual |
|---|---|---|
| Automatic updates | ✓ via `abap-skill-manager update` | ✗ manual file replacement |
| New skill detection | ✓ automatic | ✗ manual copy |
| No git submodule required | ✗ | ✓ |
| Works offline / restricted envs | depends | ✓ |

---

### Supported Platforms

| Platform | skills-core path | skills path |
|---|---|---|
| Claude Code | `.claude/skills-core` | `.claude/skills` |
| GitHub Copilot Chat | `.agents/skills-core` | `.agents/skills` |

---

## Help Menu

```
abap-skill-manager <command>

Commands:
  init         Bootstrap skill wrappers and config stubs for a new project
  update       Pull latest core + init wrappers for any new skills
               (submodule mode only — see instruction for manual mode)
  status       Install mode, submodule SHA, wrapper/config presence, TODO counts
  validate     Check all required config fields are filled in
  push         Stage, commit, and push skills changes
  instruction  Show architecture overview and setup guide (both install modes)
```
