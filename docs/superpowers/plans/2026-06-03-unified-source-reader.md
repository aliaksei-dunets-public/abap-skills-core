# Unified Source Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared `source-reader.md` detection chain so every skill that fetches ABAP source uses the same config-driven logic (MCP → abap-vs-reader → ask) instead of hard-coding a specific reader.

**Architecture:** A new `source-reader.md` is placed in each consumer skill's `references/` folder (master copy in `abap-skills-core/references/`). Skills reference it locally. The `source_reader` field in `project-config.md` is the single config point. `abap-skill-manager` learns to populate, validate, and document this field.

**Tech Stack:** Markdown skill files only — no code, no scripts.

---

## File Map

| File | Action | What changes |
|---|---|---|
| `references/source-reader.md` | **Create** (master) | New detection chain reference |
| `skills/abap-code-review/references/source-reader.md` | **Create** (copy) | Per-skill copy |
| `skills/abap-unit-test-creator/references/source-reader.md` | **Create** (copy) | Per-skill copy |
| `skills/abap-code-review/SKILL.md` | **Modify** | Phase 1 B/C: replace `Invoke abap-vs-reader` |
| `skills/abap-unit-test-creator/SKILL.md` | **Modify** | Step 1: replace `source_retrieval_tool` |
| `skills/abap-unit-test-creator/CONFIG_TEMPLATE.md` | **Modify** | Remove `source_retrieval_tool` line |
| `skills/abap-skill-manager/SKILL.md` | **Modify** | init template, validate check, instruction docs |

---

## Task 1: Create the master `source-reader.md`

**Files:**
- Create: `references/source-reader.md`

- [ ] **Step 1: Create the master file**

Create `references/source-reader.md` with this exact content:

```markdown
# Source Reader

Use this reference whenever you need to fetch ABAP source for an object name.
Follow the detection chain below exactly. Stop at the first step that succeeds.

---

## Detection Chain

### Step 1 — Check project config

Read `project-config.md`. Look for the `source_reader` field under
`## Source Reader`.

- `source_reader: abap-vs-reader` → skip to Step 3
- `source_reader: mcp`            → skip to Step 2
- `source_reader: ask`            → skip to Step 4
- field absent or `source_reader: auto` → continue to Step 2

### Step 2 — Probe for MCP read tool

Check whether an MCP tool is available whose name or description contains
`read` AND one of: `source`, `object`, `abap`.

- Tool found → invoke it with the object name → **done**
- No tool found → continue to Step 3

### Step 3 — Probe for abap-vs-reader skill

Determine `SKILLS_PATH`:
- If `.claude/skills/` exists → `SKILLS_PATH = .claude/skills`
- If `.agents/skills/` exists → `SKILLS_PATH = .agents/skills`
- Otherwise → `SKILLS_PATH = .claude/skills` (default)

Check whether `$SKILLS_PATH/abap-vs-reader/SKILL.md` exists.

- File exists → invoke the `abap-vs-reader` skill with the object name → **done**
- File missing → continue to Step 4

### Step 4 — Ask the user

Inform the user:

> "I could not find a configured source reader for `<object-name>`.
> Please paste the source code directly, or provide a local file path."

Use whatever the user provides as the source. If the user provides nothing,
note `[SOURCE NOT FOUND]` and continue without source.
```

- [ ] **Step 2: Verify file exists**

```bash
ls "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/references/source-reader.md"
```

Expected: file listed, no error.

- [ ] **Step 3: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add references/source-reader.md
git commit -m "feat: add master source-reader.md detection chain"
```

---

## Task 2: Copy `source-reader.md` into consumer skill reference folders

**Files:**
- Create: `skills/abap-code-review/references/source-reader.md`
- Create: `skills/abap-unit-test-creator/references/source-reader.md`

- [ ] **Step 1: Copy to abap-code-review**

```bash
cp "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/references/source-reader.md" \
   "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-code-review/references/source-reader.md"
```

- [ ] **Step 2: Copy to abap-unit-test-creator**

```bash
cp "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/references/source-reader.md" \
   "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-unit-test-creator/references/source-reader.md"
```

- [ ] **Step 3: Verify both copies**

```bash
ls "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-code-review/references/source-reader.md"
ls "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-unit-test-creator/references/source-reader.md"
```

Expected: both files listed.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-code-review/references/source-reader.md \
        skills/abap-unit-test-creator/references/source-reader.md
git commit -m "feat: copy source-reader.md into consumer skill references"
```

---

## Task 3: Update `abap-code-review` SKILL.md

**Files:**
- Modify: `skills/abap-code-review/SKILL.md` — Phase 1, Input Mode, Modes B and C

The current text in Mode B (line ~42):
```
Invoke `abap-vs-reader` with the object name to fetch the source.
```

The current text in Mode C (line ~49):
```
For a transport or object list: invoke `abap-vs-reader` sequentially for each object.
For a package: invoke `abap-vs-reader` for each reviewable object in the package.
```

- [ ] **Step 1: Update Mode B**

Replace the Mode B fetch instruction:

Old:
```
**Mode B — Single ADT Object:** `$ARGUMENTS` contains a single token that is **not** a transport request number (see format below) and **not** a package name. Invoke `abap-vs-reader` with the object name to fetch the source. If not found, note `[SOURCE NOT FOUND]` in the report and continue.
```

New:
```
**Mode B — Single ADT Object:** `$ARGUMENTS` contains a single token that is **not** a transport request number (see format below) and **not** a package name. Read `references/source-reader.md` and follow the detection chain to fetch the source. If no source is obtained, note `[SOURCE NOT FOUND]` in the report and continue.
```

- [ ] **Step 2: Update Mode C**

Replace the Mode C fetch instruction:

Old:
```
For a transport or object list: invoke `abap-vs-reader` sequentially for each object. For a package: invoke `abap-vs-reader` for each reviewable object in the package. Collect all sources before proceeding to Phase 3. For any object not found, note `[SOURCE NOT FOUND]` in its section. Produce one consolidated report.
```

New:
```
For a transport or object list: read `references/source-reader.md` and follow the detection chain for each object sequentially. For a package: do the same for each reviewable object in the package. Collect all sources before proceeding to Phase 2. For any object not found, note `[SOURCE NOT FOUND]` in its section. Produce one consolidated report.
```

- [ ] **Step 3: Verify the word `abap-vs-reader` no longer appears in Phase 1 Input Mode section**

```bash
grep -n "abap-vs-reader" "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-code-review/SKILL.md"
```

Expected: no matches inside the Input Mode section (lines ~36–51). Any remaining references should only be in comments or the References section if present.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-code-review/SKILL.md
git commit -m "feat: abap-code-review uses source-reader detection chain"
```

---

## Task 4: Update `abap-unit-test-creator` SKILL.md and CONFIG_TEMPLATE.md

**Files:**
- Modify: `skills/abap-unit-test-creator/SKILL.md` — Step 1 (Obtain the source)
- Modify: `skills/abap-unit-test-creator/CONFIG_TEMPLATE.md` — remove `source_retrieval_tool`

- [ ] **Step 1: Update Step 1 in SKILL.md**

Replace the current Step 1 block:

Old:
```
### Step 1 — Obtain the source

If the user provides an object name rather than pasted code, check the project
config for a `source_retrieval_tool` setting and invoke it. If no tool is
configured, ask the user to paste the source.

Do not proceed without reading the actual implementation source.
```

New:
```
### Step 1 — Obtain the source

If the user provides pasted source code, use it directly.

If the user provides an object name, read `references/source-reader.md` and
follow the detection chain to fetch the source.

Do not proceed without reading the actual implementation source.
```

- [ ] **Step 2: Update CONFIG_TEMPLATE.md**

In `skills/abap-unit-test-creator/CONFIG_TEMPLATE.md`, remove the line:

```
- Source retrieval tool to use when user provides an object name (e.g. `abap-reader`)
```

The `## Required in 'configs/config.md'` section should become:

```
## Required in `configs/config.md`

- Test class prefix (default: `ltc_`)
- Fake/double class prefix (default: `ltd_`)
```

- [ ] **Step 3: Verify `source_retrieval_tool` no longer appears**

```bash
grep -rn "source_retrieval_tool" "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-unit-test-creator/"
```

Expected: no matches.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-unit-test-creator/SKILL.md \
        skills/abap-unit-test-creator/CONFIG_TEMPLATE.md
git commit -m "feat: abap-unit-test-creator uses source-reader detection chain"
```

---

## Task 5: Update `abap-skill-manager` — `init` command

**Files:**
- Modify: `skills/abap-skill-manager/SKILL.md` — `project-config.md` standard template (around line 200)

- [ ] **Step 1: Add `## Source Reader` section to the project-config.md template**

Locate the standard template block inside the `### project-config.md standard template` section. Add the new section after `## Service Binding`:

Old end of template:
```
## Service Binding
Pattern: UI_*_O2 / UI_*_O4 / API_*_O4
```

New end of template:
```
## Service Binding
Pattern: UI_*_O2 / UI_*_O4 / API_*_O4

## Source Reader
source_reader: auto
```

- [ ] **Step 2: Verify template contains the new section**

```bash
grep -n "source_reader" "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-skill-manager/SKILL.md"
```

Expected: at least one match inside the template block.

- [ ] **Step 3: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-skill-manager/SKILL.md
git commit -m "feat: abap-skill-manager init adds source_reader to project-config template"
```

---

## Task 6: Update `abap-skill-manager` — `validate` command

**Files:**
- Modify: `skills/abap-skill-manager/SKILL.md` — `validate` command section

- [ ] **Step 1: Add source_reader validation to the validate command**

Find the `## Command: validate` section. After step 1 (which validates `project-config.md` TODO fields), add a new check:

After the existing "Flag any field whose value is `TODO` or is absent" sentence, add:

```
Also check the `source_reader` field under `## Source Reader`:
- If absent: report as WARNING — "source_reader not set; defaulting to auto. Add
  `source_reader: auto` to project-config.md to suppress this warning."
- If present but not one of `auto`, `abap-vs-reader`, `mcp`, `ask`: report as
  ERROR — "source_reader has unknown value '<value>'. Allowed: auto | abap-vs-reader | mcp | ask."
```

- [ ] **Step 2: Add source_reader to the validation report example**

Find the example output block inside `## Command: validate`. Add a line to the `### project-config.md` section:

```
✓ source_reader: auto
```

or for the warning case:

```
⚠ source_reader — not set (defaulting to auto)
```

- [ ] **Step 3: Verify**

```bash
grep -n "source_reader" "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-skill-manager/SKILL.md"
```

Expected: matches in both the template (Task 5) and the validate section.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-skill-manager/SKILL.md
git commit -m "feat: abap-skill-manager validate checks source_reader field"
```

---

## Task 7: Update `abap-skill-manager` — `instruction` command

**Files:**
- Modify: `skills/abap-skill-manager/SKILL.md` — `## ABAP Skills Architecture` section

- [ ] **Step 1: Document `source_reader` in the architecture overview**

Find the `### Install Mode A — Submodule (recommended)` section. In the **Layers** description, after the Config layer bullet, add:

```
- **`source_reader`** (`project-config.md` → `## Source Reader`): controls how
  skills fetch ABAP source. Values: `auto` (default) | `abap-vs-reader` |
  `mcp` | `ask`. With `auto`, skills probe for an MCP read tool first, then
  fall back to `abap-vs-reader`, then ask the user.
  Skills that use this field: `abap-code-review`, `abap-unit-test-creator`.
```

- [ ] **Step 2: Document `source-reader.md` copy behaviour in the update section**

Find the `update` command description (submodule mode). After the existing steps, add a note:

```
Note: `references/source-reader.md` inside each consumer skill is a copy of
the master in `abap-skills-core/references/`. A `git pull` on the submodule
updates all copies at once. In manual mode, replace the file in each skill's
`references/` folder manually, matching the steps in the manual update
instructions.
```

- [ ] **Step 3: Verify the instruction section has source_reader documented**

```bash
grep -n "source.reader" "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-skill-manager/SKILL.md"
```

Expected: matches in the architecture section.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-skill-manager/SKILL.md
git commit -m "feat: abap-skill-manager instruction documents source_reader and source-reader.md"
```

---

## Task 8: Final consistency check

- [ ] **Step 1: Confirm no skill still hard-codes abap-vs-reader as the only source fetch path**

```bash
grep -rn "invoke.*abap-vs-reader\|abap-vs-reader.*fetch\|abap-vs-reader.*source\|source_retrieval_tool" \
  "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-code-review/SKILL.md" \
  "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-unit-test-creator/SKILL.md"
```

Expected: no matches.

- [ ] **Step 2: Confirm source-reader.md copies match master**

```bash
diff "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/references/source-reader.md" \
     "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-code-review/references/source-reader.md"
diff "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/references/source-reader.md" \
     "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-unit-test-creator/references/source-reader.md"
```

Expected: no output (files identical).

- [ ] **Step 3: Confirm project-config.md template has source_reader**

```bash
grep -n "source_reader" "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-skill-manager/SKILL.md"
```

Expected: ≥ 2 matches (template + validate section).

- [ ] **Step 4: Final commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git status
```

If clean: done. If any uncommitted changes remain, stage and commit with:

```bash
git add -A
git commit -m "chore: unified source reader — final cleanup"
```
