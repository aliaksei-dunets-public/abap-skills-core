# abap-vs-writer — Design Spec

**Date:** 2026-06-06
**Status:** Approved

---

## Overview

`abap-vs-writer` is a skill for the ABAP ADT MCP server that covers all write-side
operations: creating ABAP objects, activating them, running unit tests, managing
transport requests, and generating full RAP services. It is the write-side counterpart
to `abap-vs-reader`.

The skill is optimised to minimise token usage and eliminate runtime discovery: all
object type schemas, URI patterns, and workflow steps are baked into reference files
loaded on demand.

---

## Goals

- Cover all MCP write operations: create, activate, unit test, transport, RAP generator, ATC
- Zero discovery overhead — no `get_object_type_details` calls at runtime
- Dispatch only the reference file(s) needed for the current task
- Follow the exact file structure and patterns of existing skills in `abap-skills-core`

---

## File Structure

```
abap-skills-core/skills/abap-vs-writer/
├── SKILL.md
├── CONFIG_TEMPLATE.md
└── references/
    ├── object-types.md
    ├── uri-patterns.md
    └── ops/
        ├── create-object.md
        ├── activate.md
        ├── run-unit-tests.md
        ├── transport.md
        ├── rap-generator.md
        └── atc-check.md
```

No scripts directory — all MCP calls are made directly by the agent. Scripts are
added only if complex data transformation is required in the future.

---

## SKILL.md Design

### Phase 0 — Resolve Config

Read `configs/system.md` (loaded via project config chain). Extract:
- `destination` — ABAP system connection ID (e.g. `ISD_001_C5227045_EN`)

If missing: stop and tell the user which field is absent, reference `CONFIG_TEMPLATE.md`.

### Phase 1 — Dispatch

Load reference files based on signals in the user request. Load only what is needed.

| Signal | Reference files to load |
|--------|------------------------|
| create / новый объект / class / interface / CDS / BDEF / service | `ops/create-object.md` + `object-types.md` |
| activate / активировать | `ops/activate.md` + `uri-patterns.md` |
| unit test / run tests / тесты запустить | `ops/run-unit-tests.md` + `uri-patterns.md` |
| transport / TR / транспорт | `ops/transport.md` |
| RAP / generator / OData service / x-ui-service / webapi | `ops/rap-generator.md` |
| ATC / code check / статический анализ | `ops/atc-check.md` |

Multiple files loaded when task combines operations (e.g. create + activate).

### Phase 2 — Execute

Follow instructions from loaded reference file(s). Make MCP calls directly.
Use `destination` from config in every MCP call.

---

## Reference Files Design

### `references/object-types.md`

Single lookup table for all 14 creatable object types. For each type:
- `objectType` value (e.g. `CLAS/OC`)
- Required `objectContent` fields
- Optional `objectContent` fields with allowed enum values where applicable
- Name max length (default 30, exceptions: DDLX/EX=40, CHDO/CHD=15, NROB/NRO=10)

Object types covered:
`CLAS/OC`, `INTF/OI`, `BDEF/BDO`, `DCLS/DL`, `DDLS/DF`, `DDLX/EX`,
`DRAS/RAS`, `DRTY/STY`, `SRVB/SVB`, `SRVD/SRV`, `CHDO/CHD`,
`NONT/NOT`, `NROB/NRO`, `RONT/ROT`

### `references/uri-patterns.md`

URI templates with placeholders `{DEST}`, `{USER}`, `{NAME_UPPER}`, `{name_lower}`,
`{PKG}` for every object type. Covers:
- `$TMP` local objects (path includes `Local%20Objects%20%28%24TMP%29/{USER}`)
- Package-based objects (path includes `System%20Library/...`)
- All source file extensions per type (`.clas.abap`, `.intf.abap`, `.ddls.asddls`, etc.)

### `references/ops/create-object.md`

Strict 3-step workflow — no discovery calls:

1. **`abap_creation-run_validation`**
   - `destination`, `objectType`, `objectContent` (JSON string)
   - On failure: show error, stop
2. **`abap_creation-create_object`**
   - Same params + `transportRequestNumber` (`""` for `$TMP`)
   - Save `filePath` from response
3. **Report** the `filePath` to the user so they can open it in VS Code

Key rule: `objectContent` must be a JSON-encoded string, not a raw object.
Object names passed as uppercase.

For non-`$TMP` packages: load `ops/transport.md` first, get TR from user before step 1.

### `references/ops/activate.md`

- Call `abap_activate_objects` with `uris` array
- URI source priority: (1) `filePath` from create response, (2) build from `uri-patterns.md`
- Max 15 URIs per call
- Report `objectDiagnostics` on failure

### `references/ops/run-unit-tests.md`

- Call `abap_run_unit_tests` with `uris` pointing to `.clas.abap` main file
- Tool auto-discovers test class include — no need to point to testclass file
- Report results verbatim

### `references/ops/transport.md`

- Always call `abap_transport-get` first — never call `create` directly
- Display all returned TRs to the user, wait for explicit selection
- Never auto-select a TR
- `abap_transport-create`: only if user explicitly asks to create a new TR
- `$TMP` package: transport tools can be skipped entirely (`transportRequestNumber = ""`)

### `references/ops/rap-generator.md`

3-step workflow:

1. **`abap_generators-list_generators`** — show available generators
   - Known on `ISD_001_C5227045_EN`: `x-ui-service`, `webapi-service`
   - Known limitation: `ui-service` (with TABL reference) returns "Generator does not exist" on this system
2. **`abap_generators-get_schema`** — get schema + `referenceContent`
   - `referenceContent.sessionId` must be passed as `sessionId` in content
3. **`abap_generators-generate_objects`** — generate with filled content JSON
   - Report `generatedObjects[]` list on success
   - Report `validationMessages[]` on error

For non-`$TMP`: call `abap_transport-get` with `objectType='DEVC/K'` before step 3.

### `references/ops/atc-check.md`

Documents ATC check operations available via MCP (if exposed by the ADT server).
If not available, instructs the agent to inform the user that ATC checks must be
triggered manually in VS Code.

---

## CONFIG_TEMPLATE.md Design

One required field:

| Field | Format | Description |
|-------|--------|-------------|
| `destination` | string | ABAP system connection ID, e.g. `ISD_001_C5227045_EN`. Must match the value returned by `abap_list_destinations`. |

---

## Key Design Decisions

1. **No discovery at runtime.** `abap_creation-get_object_type_details` is never
   called during normal operation. All schemas are in `object-types.md`.

2. **`objectContent` is always a JSON string.** Passing individual fields fails
   with "Enter valid object properties." This is documented prominently in
   `create-object.md`.

3. **Transport safety.** `transport-create` is never called without user confirmation.
   `$TMP` always uses `transportRequestNumber = ""`.

4. **URI reuse.** The `filePath` returned by `create_object` is the canonical URI
   for subsequent `activate_objects` and `run_unit_tests` calls in the same session.

5. **Lazy loading.** Each `ops/*.md` file is self-contained. The agent loads only
   the file(s) matching the current task.

---

## Out of Scope

- Reading/browsing ABAP source — covered by `abap-vs-reader`
- Writing source code content — done via VS Code editor after object creation
- `abap_business_services-*` tools — read-only metadata fetch, no write operations
