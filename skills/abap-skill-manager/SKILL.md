---
name: abap-skill-manager
description: >
  Manage the ABAP skills lifecycle. Use when the user says "init skills",
  "update skills", "skill status", "validate config", "push skills", or
  "explain the skills architecture". Commands: init, update, status, validate,
  push, instruction.
---

# abap-skill-manager — Core Skill

Manages the lifecycle of ABAP AI skills in any project that uses the
abap-skills-core submodule pattern.

---

## Phase 0 — Detect Platform Paths

Before executing any command, detect the AI platform by checking which folder
exists:

```bash
ls .claude/skills-core 2>/dev/null && echo "claude" || echo "not-claude"
ls .agents/skills-core 2>/dev/null && echo "copilot" || echo "not-copilot"
```

| Platform | `CORE_PATH` | `SKILLS_PATH` |
|---|---|---|
| Claude Code | `.claude/skills-core` | `.claude/skills` |
| GitHub Copilot Chat | `.agents/skills-core` | `.agents/skills` |

If neither folder exists, stop and tell the user to add the submodule first.
Show them the `instruction` command output as the setup guide.

Use `CORE_PATH` and `SKILLS_PATH` as shorthand throughout this skill.

---

## Command Dispatch

Parse $ARGUMENTS. If no argument or an unrecognised argument is provided,
output the **Help Menu** (at the end of this file) and stop.

Known commands: `init`, `update`, `status`, `validate`, `push`, `instruction`.

---

## Command: `init`

Bootstrap the skills folder structure for a new project. Creates wrapper
SKILL.md and configs/config.md stubs for every skill found in the core.

**Steps:**

1. Ensure `$SKILLS_PATH/` exists (create if missing).

2. Scan `$CORE_PATH/skills/` — collect every subdirectory that contains a
   `SKILL.md`. This is the **core skill list**.

3. Check if `$SKILLS_PATH/project-config.md` exists. If missing, create it:

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

4. For each skill in the core skill list:

   **a. Check if wrapper already exists:**
   If `$SKILLS_PATH/<skill-name>/SKILL.md` already exists → skip, mark as
   "already present".

   **b. If wrapper is missing, create `$SKILLS_PATH/<skill-name>/SKILL.md`:**

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

   **c. If the core skill has a `CONFIG_TEMPLATE.md` AND
   `$SKILLS_PATH/<skill-name>/configs/config.md` does not yet exist, create it:**

   ```markdown
   # <skill-name> — Project Config

   TODO — Fill in required fields.
   See $CORE_PATH/skills/<skill-name>/CONFIG_TEMPLATE.md for required fields.
   ```

   Skills without a CONFIG_TEMPLATE.md (e.g. `abap-skill-manager` itself) do
   not get a configs/ folder.

5. Print a summary table:

   | Skill | Wrapper | Config | Action |
   |---|---|---|---|
   | abap-code-review | ✓ | ✓ | skipped (already present) |
   | abap-vs-reader | created | created | ✓ |

   Then: "Fill in `$SKILLS_PATH/project-config.md` and each `configs/config.md`.
   Run `abap-skill-manager validate` to check for missing required fields."

---

## Command: `update`

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

3. If new skills are found, run the `init` logic (steps 4–5 from `init`) for
   those skills only. Report each new wrapper created.

4. Stage the updated submodule pointer in the parent repo:
   ```bash
   git add $CORE_PATH
   git status --short $CORE_PATH
   ```
   Report whether the pointer changed (new SHA) or was already current.

5. Print summary: skills updated, new wrappers created (if any), submodule
   pointer status.

---

## Command: `status`

Report the current state of the skills installation at a glance.

**Steps:**

1. Get current submodule SHA:
   ```bash
   cd $CORE_PATH && git rev-parse --short HEAD
   ```

2. Get remote HEAD SHA:
   ```bash
   cd $CORE_PATH && git fetch origin main --quiet 2>/dev/null && git rev-parse --short origin/main
   ```

3. Scan `$CORE_PATH/skills/` for all skill folders.

4. For each skill, collect:
   - Wrapper exists? (`$SKILLS_PATH/<skill>/SKILL.md`)
   - Config exists? (`$SKILLS_PATH/<skill>/configs/config.md`)
   - TODO count in all files under `$SKILLS_PATH/<skill>/configs/`

5. Count TODOs in `$SKILLS_PATH/project-config.md`.

6. Output:

   ```
   ## Skills Status

   Core: <current-SHA>  Remote: <remote-SHA>  [UP TO DATE | BEHIND N commits — run: abap-skill-manager update]

   | Skill                 | Wrapper | Config | TODOs | Notes                            |
   |-----------------------|---------|--------|-------|----------------------------------|
   | abap-code-review      | ✓       | ✓      | 0     |                                  |
   | abap-run-unit-tests   | ✓       | ✓      | 2     | configs/config.md has 2 TODOs    |
   | abap-skill-manager    | ✓       | —      | —     | no config required               |
   | abap-unit-test-creator| ✓       | ✓      | 0     |                                  |
   | abap-vs-reader        | ✓       | ✓      | 0     |                                  |

   project-config.md: ✓  (TODOs: 0)
   ```

---

## Command: `validate`

Check that all required config fields (from CONFIG_TEMPLATE.md) are filled in
for every skill.

**Steps:**

1. Read `$SKILLS_PATH/project-config.md`. Flag any field whose value is `TODO`
   or is absent.

2. For each skill in `$CORE_PATH/skills/` that has a `CONFIG_TEMPLATE.md`:

   a. Read the CONFIG_TEMPLATE.md — extract field names listed under
      `## Required Fields`.

   b. For each required field, check `$SKILLS_PATH/<skill>/configs/config.md`
      and any `→ Read configs/*.md` linked files. A field passes if it is
      present and its value does not contain `TODO`.

3. Output a validation report:

   ```
   ## Validation Report

   ### project-config.md
   ✓ primary_namespace: /HEC4/
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

Stage, commit, and push all pending skills changes (wrappers, configs, and
submodule pointer).

**Steps:**

1. Check what has changed:
   ```bash
   git status --short $SKILLS_PATH $CORE_PATH
   ```

2. If nothing changed: "Nothing to commit." and stop.

3. Show the user the list of files to be committed and ask for explicit
   confirmation before proceeding.

4. Stage and commit:
   ```bash
   git add $SKILLS_PATH/ $CORE_PATH
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
project-specific configuration:

```
abap-skills-core/          ← git submodule, shared across all projects
  skills/
    <skill-name>/
      SKILL.md             ← core logic, no project names, /DEMO/ examples only
      CONFIG_TEMPLATE.md   ← documents required/recommended config fields
      references/          ← supporting reference files

.claude/skills/            ← project layer, committed to the project repo
  project-config.md        ← shared context: namespace, naming, system ID
  <skill-name>/
    SKILL.md               ← wrapper: reads core + project-config + config
    configs/
      config.md            ← required entry point (lazy-links other files)
      naming.md            ← optional: linked from config.md as needed
      system.md            ← optional: linked from config.md as needed
```

### Three Layers

**Layer 1 — Core skill (`abap-skills-core`):**
Platform-independent. Updated via submodule. `/DEMO/` in examples only.

**Layer 2 — Project wrapper (`skills/<skill>/SKILL.md`):**
Thin file telling the AI agent which files to read:
`project-config.md` → core `SKILL.md` → `configs/config.md`.

**Layer 3 — Project config (`skills/<skill>/configs/`):**
`config.md` is always the entry point. Lazy-links to additional files:
```
→ Read configs/naming.md for naming convention rules.
→ Read configs/system.md for ADT connection details.
```

### Supported Platforms

| Platform | skills-core path | skills path |
|---|---|---|
| Claude Code | `.claude/skills-core` | `.claude/skills` |
| GitHub Copilot Chat | `.agents/skills-core` | `.agents/skills` |

### Setup — New Project

**Step 1 — Add submodule:**
```bash
# Claude Code
git submodule add https://github.com/aliaksei-dunets-public/abap-skills-core.git .claude/skills-core
git submodule update --init
```

> If git rejects due to `.gitignore`, use `-f` and add exclusions to
> `.gitignore`:
> ```
> !.claude/skills-core/
> !.claude/skills-core/**
> !.claude/skills/
> !.claude/skills/**
> ```

**Step 2 — Bootstrap wrappers:**
```
abap-skill-manager init
```
Creates all wrapper SKILL.md files and config stubs.

**Step 3 — Fill in configs:**
Edit `project-config.md` and each `configs/config.md`.
See each skill's `CONFIG_TEMPLATE.md` for required fields.
Run `abap-skill-manager validate` to check nothing was missed.

**Step 4 — Commit:**
```
abap-skill-manager push
```

### Updating Core Skills

```
abap-skill-manager update
```

Pulls the latest core, creates wrappers for any newly added skills, and
updates the submodule pointer.

---

## Help Menu

```
abap-skill-manager <command>

Commands:
  init         Bootstrap skill wrappers and config stubs for a new project
  update       Pull latest core + init wrappers for any new skills
  status       Submodule SHA, wrapper/config presence, TODO counts per skill
  validate     Check all required config fields are filled in
  push         Stage, commit, and push skills changes
  instruction  Show architecture overview and setup guide
```
