# RAP Patterns

Use when the unit is a RAP behavior pool, handler, validation, determination,
action, saver, draft flow, or EML scenario.

Use only verified BDEF, entity, field, key, and response names. Never invent
local handler names like `lhc_handler` — derive them from the behavior
implementation.

## Pattern selection

| Logic kind | Approach |
|---|---|
| Pure helper inside a behavior pool, accessible | Direct method invocation. Avoid EML. Isolate dependencies via local fakes or project seams. |
| Validation / determination depending on RAP transactional state | EML test with `MODIFY/READ ENTITIES … IN LOCAL MODE`. |
| Direct handler method call | Only when handler class is known, the test class can legally access it, importing/changing parameters can be constructed correctly, and no unavailable runtime semantics are needed. Otherwise switch to EML. |
| Saver / finalize / check_before_save | Assert collected messages, failed/reported, validation results, dependency calls, buffer effects. Never cause productive persistence. Report a blocker if isolation is impossible. |
| Draft-enabled behavior | Determine the exact target first: active, draft, draft action, activate, edit, discard, prepare, validation during draft. Confirm BDEF, aliases, key fields, entity fields before generating EML. |
| Instance action | `MODIFY ENTITIES … CREATE` first, then `MODIFY ENTITIES … ACTION … FIELDS ( ) WITH`. |
| Static / factory action | Trigger directly per BDEF signature, no prior instance. |
| Unmanaged behavior | Inspect custom implementation — do not assume managed persistence. Test explicit handlers, injected repositories, or EML-visible behavior. |

## EML rules

- `%tky` is the default key reference. Use `%key` only when the entity has no
  draft behavior and `%tky` does not apply. Never mix `%tky` and `%key` in
  one EML block.
- Assert `failed`, `reported`, `mapped` where relevant.
- `ROLLBACK ENTITIES` in teardown when the test mutates transactional state.
- No `COMMIT ENTITIES` unless the user requests an integration scenario and
  the environment supports it safely.
- Keep test data minimal. Never depend on productive DB content.

## Dependency isolation in RAP tests

- SQL/CDS reads: use the matching test environment if allowed.
- Services, repositories, message helpers, auth helpers, number ranges,
  locks, external APIs: existing seam → local fake → blocker.

## Action-test assertions

- Result structure (if any).
- `failed` and `reported` for error paths.
- Buffer values via `READ ENTITIES … IN LOCAL MODE`.
- Action not invoked / no result when preconditions fail.

## Output assertions

Prefer observable RAP outcomes:
- `failed` keys and causes;
- `reported` messages and severities;
- `mapped` content after CREATE;
- read-back values from the transactional buffer;
- absence of failed/reported on success paths;
- captured dependency interactions when a fake records calls.
