# Unified Source Reader — Design Spec

**Date:** 2026-06-03  
**Status:** Approved  
**Scope:** abap-skills-core — all skills that require ABAP source code

---

## Problem

`abap-code-review` hard-codes `abap-vs-reader` as the only way to fetch source.  
`abap-unit-test-creator` uses a per-skill config field (`source_retrieval_tool`).  
No skill supports MCP-based source reading.  
There is no consistent behaviour across environments (VS Code ADT, MCP, paste).

---

## Goal

A single, reusable detection chain that any skill can invoke to obtain ABAP source.  
The chain is config-driven with a sensible auto-detect fallback.  
Project config is the single place to set it. No per-skill duplication.

---

## Architecture

### New file: `abap-skills-core/references/source-reader.md`

Shared reference at the core root level (not inside any individual skill).  
All skills that need source read this file and follow its instructions.

In submodule install mode, one copy serves all projects — consistent with the
existing core/wrapper architecture. In manual install mode, the file is copied
alongside the skill files.

### Config field: `source_reader` in `project-config.md`

`project-config.md` is already shared across all skills and read by every
wrapper. Adding `source_reader` here avoids per-skill config duplication.

```markdown
## Source Reader
source_reader: auto   # auto | abap-vs-reader | mcp | ask
```

| Value | Behaviour |
|---|---|
| `auto` (default, also when field absent) | Run detection chain |
| `abap-vs-reader` | Skip detection, go directly to abap-vs-reader |
| `mcp` | Skip detection, go directly to MCP tool |
| `ask` | Skip detection, ask the user to paste or provide a path |

`abap-skill-manager init` writes `source_reader: auto` into the generated
`project-config.md` template. `abap-skill-manager validate` checks that the
field holds one of the four allowed values.

---

## Detection Chain

Defined in `references/source-reader.md`. Executed by any skill that needs source.

```
Input: object name (from $ARGUMENTS or conversation)

Step 1 — Read project-config.md → field source_reader
  "abap-vs-reader" → go to Step 3
  "mcp"            → go to Step 2
  "ask"            → go to Step 4
  "auto" or absent → continue to Step 2

Step 2 — MCP probe
  Is an MCP tool available whose name or description contains "read" and
  ("source" or "object" or "abap")?
  Yes → invoke that tool with the object name → done
  No  → continue to Step 3

Step 3 — abap-vs-reader probe
  Does <SKILLS_PATH>/abap-vs-reader/SKILL.md exist?
  Yes → invoke abap-vs-reader skill with the object name → done
  No  → continue to Step 4

Step 4 — Fallback: ask user
  "I could not find a source reader. Please paste the source for <object>
   or provide a file path."
  → use the pasted/provided source → done
```

`SKILLS_PATH` is resolved the same way `abap-skill-manager` does it:
`.claude/skills` (Claude Code) or `.agents/skills` (Copilot).

---

## Changes Per Skill

### abap-code-review

**Phase 1 — Input Mode**, Modes B and C:  
Replace `Invoke abap-vs-reader` with:
> For each object name, read `../../references/source-reader.md` and follow
> the detection chain to obtain the source.

The path `../../references/` is relative to the skill's location in core
(`skills/abap-code-review/` → up two levels → `references/`).

The `[SOURCE NOT FOUND]` fallback behaviour is unchanged — it applies when
Step 4 of the detection chain produces no source.

### abap-unit-test-creator

**Step 1 — Obtain the source**:  
Replace the `source_retrieval_tool` config field reference with:
> Read `../../references/source-reader.md` and follow the detection chain
> to obtain the source.

Remove `source_retrieval_tool` from `CONFIG_TEMPLATE.md` for this skill.

### abap-run-unit-tests

Currently a placeholder. When implemented, use the same pattern from the start.  
No changes needed now.

### abap-vs-reader

No changes. It remains the underlying implementation for the `abap-vs-reader`
path in the detection chain.

### abap-skill-manager

Three updates:

1. **`init` command** — `project-config.md` template gains:
   ```markdown
   ## Source Reader
   source_reader: auto
   ```

2. **`validate` command** — add check:
   - Field `source_reader` present in `project-config.md`
   - Value is one of: `auto`, `abap-vs-reader`, `mcp`, `ask`
   - Report as WARNING (not error) if absent — defaults to `auto`

3. **`instruction` command** — add to architecture overview:
   - Document `source_reader` field and its four values
   - Explain that `abap-vs-reader` still requires its own `configs/config.md`
     when selected explicitly or picked by auto-detect

---

## File Structure After Implementation

```
abap-skills-core/
├── references/
│   └── source-reader.md            ← NEW
├── skills/
│   ├── abap-code-review/
│   │   └── SKILL.md                ← update Phase 1 B/C
│   ├── abap-unit-test-creator/
│   │   ├── SKILL.md                ← update Step 1
│   │   └── CONFIG_TEMPLATE.md      ← remove source_retrieval_tool
│   ├── abap-skill-manager/
│   │   └── SKILL.md                ← update init/validate/instruction
│   └── abap-vs-reader/             ← no changes
└── docs/superpowers/specs/
    └── 2026-06-03-unified-source-reader-design.md
```

---

## Path Conventions

Skills reference `source-reader.md` as `../../references/source-reader.md`
(relative from `skills/<skill-name>/`).

In submodule install mode the actual resolved path is:
`.claude/skills-core/references/source-reader.md`

In manual install mode the file is at:
`.claude/skills/<skill-name>/../../references/source-reader.md`
which means it must be copied to `.claude/skills/../references/` — i.e. one
level above the skills folder. `abap-skill-manager` handles this copy during
`init` (manual mode) and `update`.

> **Note:** if the relative path proves fragile across environments, an
> alternative is to place `source-reader.md` inside each skill's own
> `references/` folder and have `abap-skill-manager update` keep them in sync.
> This is the fallback if path resolution causes problems in practice.

---

## Out of Scope

- Adding a read-source tool to the ABAP MCP server (separate concern).
- Implementing `abap-run-unit-tests` (placeholder, separate effort).
- Changes to `abap-vs-reader` internals.
