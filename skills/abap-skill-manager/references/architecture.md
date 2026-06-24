# ABAP Skills Architecture

Three-layer architecture separating platform-independent skill logic from
project-specific configuration. Two install modes are supported.

---

## Install Mode A — Submodule (recommended)

```
abap-skills-core/          ← git submodule, shared across all projects
  skills/
    <skill-name>/
      SKILL.md             ← core logic, no project names, /DEMO/ examples only
      CONFIG_TEMPLATE.md   ← documents required/recommended config fields
      references/          ← supporting reference files

.agents/skills/            ← project layer, committed to the project repo
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

**Source evidence:**

Skills may require ABAP source and related context, but they should not
prescribe retrieval chains. The agent runtime resolves source acquisition.

**Setup:**

```bash
# Step 1 — Add submodule
git submodule add https://github.com/aliaksei-dunets-public/abap-skills-core.git .agents/skills-core
git submodule update --init
```

> If git rejects due to `.gitignore`, use `-f` and add these exclusions:
> ```
> !.agents/skills-core/
> !.agents/skills-core/**
> !.agents/skills/
> !.agents/skills/**
> ```

```
# Step 2 — Bootstrap wrappers and config files
abap-skill-manager init

# Step 3 — Fill in project-config.md and each configs/config.md
# (config.md files are pre-generated with TODO markers — edit them)
# See each skill's CONFIG_TEMPLATE.md for field descriptions
abap-skill-manager validate
```

**Updating core skills:**
```
abap-skill-manager update
```
Pulls the latest core, creates wrappers for any newly added skills, appends
missing config fields to existing `config.md` files, and updates the
submodule pointer.

---

## Install Mode B — Manual copy

Use when git submodules are not practical or when you want a single skill
without the full submodule setup.

```
.agents/skills/            ← project layer, committed to the project repo
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
   `.agents/skills/<skill-name>/`
3. Create config files: `abap-skill-manager init`
4. Fill in `project-config.md` and each `configs/config.md`
   (the files are pre-generated with TODO markers — edit them).
5. Run `abap-skill-manager validate` to check nothing was missed.

**Manual update procedure** (no automation):

1. Re-download the latest core.
2. For each skill, replace `SKILL.md`, `references/`, and `CONFIG_TEMPLATE.md` (if present).
3. Do **not** overwrite `configs/` — that is project state.
4. Run `abap-skill-manager validate` afterwards.

**Trade-off vs submodule:**

| | Submodule | Manual |
|---|---|---|
| Automatic updates | ✓ via `abap-skill-manager update` | ✗ manual file replacement |
| New skill detection | ✓ automatic | ✗ manual copy |
| No git submodule required | ✗ | ✓ |
| Works offline / restricted envs | depends | ✓ |

---

## Supported Platform

| Platform | skills-core path | skills path |
|---|---|---|
| GitHub Copilot (Agents) | `.agents/skills-core` | `.agents/skills` |
