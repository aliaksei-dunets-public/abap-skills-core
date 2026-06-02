# abap-skills-core

Core ABAP skills for AI agentic development.

Used as a git submodule in ABAP project repositories.

## Skills

- `abap-code-review` — ABAP code review (PERF, CLEAN, RAP, CDS, TEST, DOC)
- `abap-reader` — Fetch ABAP artifact source from ADT cache
- `abap-unit-test-creator` — Generate isolated ABAP Unit tests
- `abap-run-unit-tests` — Run ABAP Unit Tests via ADT MCP server
- `abap-skill-manager` — Manage skill lifecycle (init, update, status, validate, push)

## Usage

Add as a submodule in your project:

```bash
git submodule add https://github.com/<your-user>/abap-skills-core .<AI_TOOL_SKILL_NAME_FOLDER>/skills-core (claude/agent/codex)
git submodule update --init
```

Then create `.claude/skills/<skill-name>/SKILL.md` wrappers pointing to files in this repo.
See each skill's `CONFIG_TEMPLATE.md` for required project configuration.
