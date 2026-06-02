# RAP Patterns for ABAP Unit Test Authoring

Use this reference when the unit under test is a RAP behavior pool, handler,
validation, determination, action, saver, draft flow, or EML scenario.

## RAP Testing Decision Tree

Before generating RAP tests, identify the kind of RAP logic being tested.

### 1. Pure helper logic inside a behavior pool

If the logic is isolated and accessible:

- prefer direct method invocation;
- avoid unnecessary EML;
- use local test setup and assertions;
- isolate dependencies through local fakes or existing project seams.

### 2. Validation or determination depending on RAP transactional state

Prefer EML-based tests when behavior must be triggered by RAP runtime semantics.

Use where applicable and supported:

```abap
MODIFY ENTITIES ... IN LOCAL MODE
READ ENTITIES ... IN LOCAL MODE
```

Assert against:

- `failed`;
- `reported`;
- `mapped`;
- read results;
- messages;
- changed buffered values.

### 3. Direct handler method testing

Use direct handler invocation only when:

- the handler class name is known from the source;
- the local test class can legally access it;
- required importing/changing parameters can be constructed correctly;
- the test does not depend on unavailable RAP runtime semantics.

Never invent handler names such as `lhc_handler`. Derive the actual local handler
class name from the behavior implementation.

If the handler is not safely accessible, switch to EML-based testing.

### 4. Saver, finalize, and check_before_save logic

Do not cause productive persistence.

Prefer asserting:

- collected messages;
- failed/reported structures;
- validation results;
- calls to injected dependencies;
- transactional buffer effects where accessible.

If saver logic cannot be isolated, report a testability blocker.

### 5. Draft-enabled behavior

Before generating code, determine whether the test targets:

- active instance behavior;
- draft instance behavior;
- draft actions;
- activation;
- edit;
- discard;
- prepare;
- validation during draft flow.

Do not generate generic draft EML without confirming the behavior definition,
behavior aliases, key fields, and entity fields.

### 6. Instance and Static Actions

Before generating tests for a RAP action, identify:

- whether the action is an instance action, a static action, or a factory action;
- the action's importing and result parameters from the behavior definition;
- whether the action affects the transactional buffer, raises messages, or returns
  a result structure.

For **instance actions**, construct an entity instance first with `MODIFY ENTITIES ... CREATE`,
then trigger the action with `MODIFY ENTITIES ... ACTION ... FIELDS ( ) WITH`.

For **static/factory actions**, trigger the action without prior instance creation.
Use the correct calling signature as defined in the BDEF.

Assert:

- the action result structure (if any);
- `failed` and `reported` for error paths;
- changed buffer values readable via `READ ENTITIES ... IN LOCAL MODE`;
- that the action was not called or produced no result when preconditions fail.

Do not generate action EML without verified action name, parameter names, and key fields.

### 7. Unmanaged behavior

For unmanaged RAP, inspect custom implementation details carefully.

Do not assume managed persistence behavior.

Prefer tests around explicit handler methods, injected repositories, or
EML-visible behavior depending on the source.

## EML Test Rules

When using EML in tests:

- use only verified BDEF and entity names;
- use only verified field names;
- use `%tky` as the default key reference in all EML statements; use `%key` only
  when the entity has no draft behavior and `%tky` is not available or not
  applicable; never mix `%tky` and `%key` within the same EML statement block;
- assert `failed`, `reported`, and `mapped` where relevant;
- use `ROLLBACK ENTITIES` in teardown when EML changes transactional state;
- avoid `COMMIT ENTITIES` unless the user explicitly asks for an
  integration-like scenario and the environment supports it safely;
- keep test data minimal;
- do not depend on productive database content.

## RAP Dependency Isolation

When RAP logic reads SQL tables or CDS entities, isolate those reads with the
appropriate test environment if available and allowed.

When RAP logic calls services, repositories, message helpers, authorization
helpers, number ranges, locks, or external APIs, prefer existing project seams or
local fakes. If no seam exists, report a testability blocker.

## RAP Output Assertions

Prefer assertions against observable RAP behavior:

- `failed` keys and causes;
- `reported` messages and severities;
- `mapped` content after create operations;
- read-back values from transactional buffer;
- absence of failed/reported entries for success paths;
- dependency interactions when a fake captures calls.
