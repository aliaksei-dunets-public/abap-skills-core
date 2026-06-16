# Source Reader

Use this reference whenever you need to fetch ABAP source for an object name.
Follow the detection chain below exactly. Stop at the first step that succeeds.

---

## Detection Chain

### Step 1 — Check project config

Look for the `source_reader` field under `## Source Reader` in the project
config already loaded into context (the wrapper reads `project-config.md`
before invoking this skill — do not read `project-config.md` here). If the
field is not in context, treat it as `source_reader: auto`.

- `source_reader: abap-vs-reader` → skip to Step 3
- `source_reader: mcp`            → skip to Step 2
- `source_reader: ask`            → skip to Step 4
- `source_reader: auto` or absent → continue to Step 2

### Step 2 — Probe for MCP read tool

Check whether an MCP tool is available whose name or description contains
`read` AND one of: `source`, `object`, `abap`.

- Tool found → invoke it with the object name
  - Source returned → **done**
  - Tool errors or returns no source → continue to Step 3
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
