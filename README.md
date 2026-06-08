# abap-skills-core

Core ABAP skills for AI agentic development.

Used as a git submodule in ABAP project repositories.

## Skills

- `abap-code-review` — ABAP code review (PERF, CLEAN, RAP, CDS, TEST, DOC)
- `abap-vs-reader` — Fetch ABAP artifact source from ADT VSCode extension cache
- `abap-unit-test-creator` — Generate isolated ABAP Unit tests
- `abap-skill-manager` — Manage skill lifecycle (init, update, status, validate, push, instruction)

## Setup Instructions

### Step 1 — Add submodule

Add this repo as a git submodule in your project. The target folder depends on your AI tool:

| AI Tool | Target folder |
|---|---|
| Claude Code | `.claude/skills-core` |
| GitHub Copilot Chat | `.agents/skills-core` |

```bash
# Claude Code
git submodule add https://github.com/aliaksei-dunets-public/abap-skills-core.git .claude/skills-core

# GitHub Copilot Chat
git submodule add https://github.com/aliaksei-dunets-public/abap-skills-core.git .agents/skills-core
```

> **Note for Claude Code:** If git complains about `.gitignore`, use the `-f` flag:
> ```bash
> git submodule add -f https://github.com/aliaksei-dunets-public/abap-skills-core.git .claude/skills-core
> ```
> Then add exclusions to `.gitignore`:
> ```
> !.claude/skills-core/
> !.claude/skills-core/**
> !.claude/skills/
> !.claude/skills/**
> ```

```bash
git submodule update --init
```

### Step 2 — Create skill wrappers

Create a `skills/` folder next to `skills-core/` and add one subfolder per skill:

```
.claude/                          (or .agents/ for Copilot)
  skills-core/                   ← this submodule
  skills/
    project-config.md            ← shared project context
    abap-code-review/
      SKILL.md                   ← wrapper
      configs/
        config.md                ← required entry point
    abap-vs-reader/
      SKILL.md
      configs/
        config.md
    abap-unit-test-creator/
      SKILL.md
      configs/
        config.md
    abap-skill-manager/
      SKILL.md
```

Each `SKILL.md` wrapper tells the agent to read the core skill + project config:

```markdown
Read `.claude/skills/project-config.md` for project-wide context.
Read `.claude/skills-core/skills/<skill-name>/SKILL.md` for core instructions.
Read `.claude/skills/<skill-name>/configs/config.md` for project-specific rules.
If config.md references additional files, read those too before proceeding.

Apply core instructions using the project context and all loaded config files.
```

> **Tip:** Run `abap-skill-manager init` to generate all wrappers and config stubs automatically.

See each skill's `CONFIG_TEMPLATE.md` for required fields in `project-config.md` and `configs/config.md`.

### Step 3 — Fill in project-config.md

Copy the template below into `.claude/skills/project-config.md` and fill in your project details:

```markdown
## Project
Name: <project name>
System: <SAP system ID>
Platform: S/4HANA On-Premise
Primary namespace: <e.g. /DEMO/>

## DDIC Naming
- Domain: <e.g. /demo/do_*>
- Data Element: <e.g. /demo/de_*>
- Structure: <e.g. /demo/s_*>
- Table Type: <e.g. /demo/t_*>
- DB Table: <e.g. /demo/a_*>
- Draft Table: <e.g. /demo/d_*>

## CDS Naming
- Interface View: <e.g. /demo/I_*>
- Projection View: <e.g. /demo/C_*>
- Base View: <e.g. /demo/R_*>

## RAP
- Behavior Implementation Class: <e.g. /demo/bp_<RootCDSViewEntityName>>
- Auth check class: <e.g. /demo/cl_auth_check_*>
- Obsolete package: <e.g. /DEMO/OBSOLETE>

## Service Binding
Pattern: UI_*_O2 / UI_*_O4 / API_*_O4
```

### Step 4 — Update submodule (when core skills change)

```bash
cd .claude/skills-core   # or .agents/skills-core
git pull origin main
cd ../..
git add .claude/skills-core
git commit -m "chore: update abap-skills-core submodule"
```
