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
- `references/config-generation.md` — inventory and generation of all declared config files.
- `references/output-examples.md` — canonical output for `init` / `status` / `validate`.
- `references/registry-maintenance.md` — what to update when a skill is added or its config contract changes.

---

## Phase 0 — Detect install mode

Run before any command. Resolve `SKILLS_PATH` and `CORE_PATH` from explicit
project configuration/wrapper paths first. Otherwise use the active platform's
existing layout: `.agents/skills` + `.agents/skills-core` or `.claude/skills` +
`.claude/skills-core`. Do not choose between conflicting installations silently.
Verify submodule registration before choosing `INSTALL_MODE = submodule`;
copied core directories are manual installations. Without a core, use manual
mode. Do not move files or create a competing platform layer during discovery.

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

   b. **Both modes — config:** if the skill has `CONFIG_TEMPLATE.md`, inventory
      every declared path/field per `references/config-generation.md`. Create
      missing required files and append absent fields in their declared owners
      even when config.md exists. Skills without a template get no configs folder.

4. Print summary table from `references/output-examples.md` and next-steps line.

---

## Command: `update`

### Submodule mode

1. Verify the registered core path/remote; record the old SHA and parent index
   pointer. Inspect staged/unstaged/untracked core and affected config/wrapper
   changes. Stop conflicting writes on local edits; never stash/reset them.
   Resolve the requested ref/version or configured upstream, not an assumed
   main. Fetch for this update and resolve the target to a SHA. Use fast-forward
   only on an attached matching branch; for clean detached HEAD, move to the
   resolved SHA without pulling/merging an arbitrary branch. On divergence,
   leave local commits intact and report old/target SHAs.
2. Diff `$CORE_PATH/skills/` vs `$SKILLS_PATH/`. Run init step 3a for skills with no wrapper. Report new wrappers.
3. **Config enrichment:** inventory every declared owner including shared context
   and linked files. Create missing required files and append absent fields per
   `references/config-generation.md`, preserving existing values.
4. Verify generated changes/core SHA. Stage only the core pointer if the
   request/project policy includes staging; otherwise report it as unstaged.
   Do not commit/push implicitly. On failure, report applied operations. Restore
   the old core SHA only with a verified clean tree and unchanged ownership;
   otherwise provide recovery instructions without overwriting local work.
5. Print summary: skills updated, new wrappers, config fields added, submodule pointer status.

### Manual mode

> Manual install detected — automatic update not available. See
> `references/architecture.md` § "Manual update procedure". Run `abap-skill-manager validate` afterwards.

---

## Command: `status`

1. **Submodule only** — collect local HEAD and configured upstream SHA without
   fetching. Label upstream freshness unknown if not refreshed; disclose an
   unavailable lookup rather than claiming up to date.
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

3. **Required-field check:** use the same inventory as generation in
   `references/config-generation.md`, including path headings with a Required
   column. Missing/unreadable owners, empty values, TODO and conflicting
   duplicates fail. Validate is read-only; do not append missing fields.
4. Report config checks separately from self-tests. Execute only documented,
   runnable, trusted/authorized tests. Otherwise report not available or not
   executed with the reason; examples are not observed test results. Preserve
   actual failures and unmet required test gates.
5. Render the factual report from `references/output-examples.md`.

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
  validate     Check config fields; report available self-tests separately
  instruction  Show architecture overview and setup guide
```
