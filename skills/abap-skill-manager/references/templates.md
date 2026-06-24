# Templates

Templates used by `init` (and other commands) when creating files.

---

## Wrapper `SKILL.md` (submodule mode only)

Created at `$SKILLS_PATH/<skill-name>/SKILL.md`. Copy `name` and `description`
from the core skill's frontmatter; if missing, fall back to
`name: <skill-name>` and `description: TODO — fill in trigger description for <skill-name>`.

```markdown
---
name: <name from core SKILL.md>
description: >
  <description from core SKILL.md>
---

Read `$SKILLS_PATH/project-config.md` for project-wide context.
Read `$CORE_PATH/skills/<skill-name>/SKILL.md` for core instructions.
Read `$SKILLS_PATH/<skill-name>/configs/config.md` for project-specific rules.
If config.md references additional files, read those too before proceeding.

Apply core instructions using the project context and all loaded config files.
```

---

## `project-config.md` standard template

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
