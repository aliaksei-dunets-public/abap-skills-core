---
name: abap-vs-writer
description: >
  Use this skill whenever the user wants to create, edit, activate, run unit tests on,
  manage transports for, or generate RAP services for ABAP objects via the ADT MCP
  server. Trigger on: "create class", "create interface", "create CDS", "create BDEF",
  "create service", "edit", "write code", "implement method", "add method", "activate",
  "run tests", "unit tests", "transport", "TR", "RAP generator", "OData service",
  "ATC check", "code check", or equivalent in any language. Also trigger when the user
  provides an object name and asks to create, edit, activate, or test it.
---

# abap-vs-writer — Core Skill

Executes write-side ABAP ADT operations via the MCP server: creating objects,
editing source code, activating, running unit tests, managing transport requests,
and generating full RAP services.

All object schemas and URI patterns are pre-loaded in reference files — no runtime
discovery calls needed.

---

## Phase 0 — Resolve Config

Read `configs/system.md` (loaded via the project config chain).

Extract:
- `destination` — ABAP system connection ID (e.g. `DEMO_001_EN`)

If the field is missing or `configs/system.md` does not exist: stop, tell the user
which field is absent, and refer them to `CONFIG_TEMPLATE.md`.

Use `destination` in every subsequent MCP call.

---

## Phase 1 — Dispatch

Load only the reference files that match the current task. Do not load all files.

| Signal in user request | Reference files to load |
|------------------------|------------------------|
| create / новый / class / interface / CDS / BDEF / service binding / service definition | `references/ops/create-object.md` + `references/object-types.md` |
| edit / редактировать / implement / write code / add method / изменить / написать | `references/ops/edit-object.md` |
| activate / активировать / активация | `references/ops/activate.md` + `references/uri-patterns.md` |
| unit test / run tests / тесты / запустить тесты | `references/ops/run-unit-tests.md` + `references/uri-patterns.md` |
| transport / TR / транспорт / задание переноса | `references/ops/transport.md` |
| RAP / generator / генератор / OData service / x-ui-service / webapi-service | `references/ops/rap-generator.md` |
| ATC / code check / статический анализ / ABAP Test Cockpit | `references/ops/atc-check.md` |

When the task combines operations (e.g. "create and activate"), load all matching
reference files.

---

## Phase 2 — Execute

Follow the instructions in the loaded reference file(s). Use `destination` from
Phase 0 in every MCP tool call. Do not call `abap_creation-get_object_type_details`
at runtime — all schemas are in `references/object-types.md`.
