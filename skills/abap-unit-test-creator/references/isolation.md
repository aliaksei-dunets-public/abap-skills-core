# Dependency Isolation for ABAP Unit Test Authoring

Use this reference when the production code has SQL, CDS, interface, concrete,
static, RAP EML, authorization, number range, lock, date/time/user, HTTP/RFC/BAPI,
function module, application log, or message dependencies.

## Dependency Analysis Depth Rule

Analyse only **depth-1 dependencies** — the direct dependencies of the target
artifact. Do not inspect or mock transitive dependencies.

**Exception:** look one level deeper (depth 2) only when a depth-1 dependency is
a concrete class with no interface seam, and only to identify the correct point
at which to introduce a wrapper or interface. Never generate tests at depth 2.

**Rationale:** a proper depth-1 mock (e.g. `ZIF_VALIDATOR`) hides everything
behind it. The SQL inside `ZCL_VALIDATOR` is irrelevant to the test for
`ZCL_ORDER_PROCESSOR` — the mock controls that boundary completely. Following
transitive dependencies adds analysis cost with no testing benefit and risks
generating mocks that are not needed.



| Dependency type | Preferred isolation strategy |
|---|---|
| Interface dependency | Existing project fake, local fake class (`ltd_`), or `cl_abap_testdouble` if available and allowed by environment |
| Concrete class dependency | Existing seam, wrapper interface, factory injection, or testability blocker |
| Static method dependency | Wrapper/interface seam, test seam if allowed, or testability blocker |
| Direct SQL table access | `cl_osql_test_environment` if available and allowed |
| CDS entity access | `cl_cds_test_environment` if available and allowed |
| RAP EML interaction | EML-based test with transactional isolation, usually local mode where applicable |
| RAP validation/determination | Direct handler test or EML-based test depending on accessibility and scenario |
| RAP saver/finalize/check_before_save | Verify failed/reported/messages/buffered behavior without productive persistence |
| Draft behavior | Explicitly determine active vs draft scenario before generating EML |
| Authorization check | Authorization seam, wrapper, project helper, or testability blocker |
| Date/time/user context | Injected clock/context provider, wrapper, or project-approved seam |
| Number range | Wrapper or fake provider |
| Lock object | Wrapper or fake lock provider |
| HTTP/RFC/BAPI/FM call | Wrapper interface or testability blocker |
| Application log | Wrapper/fake logger or assertion against captured messages |

## Interface and Test Double Strategy

For interface dependencies:

1. Prefer an existing project-specific fake, stub, or test helper.
2. Use a local fake class (`ltd_`) when behavior is simple and explicit.
3. Use `cl_abap_testdouble` when interaction verification (call count, argument
   capture, exception injection) is needed and the framework is allowed by the
   environment and project profile.
4. If production code depends on concrete classes or static APIs without a seam,
   report a testability blocker and recommend a minimal refactoring.

Do not introduce broad dependency injection refactoring unless the user explicitly
asks for production code changes.

If production code already has a dependency injection seam, use that seam.

If no seam exists, prefer reporting the blocker over generating fragile tests.

## SQL Test Environment Rules

For SQL table dependencies:

- use `cl_osql_test_environment` when production code directly selects from
  transparent database tables;
- create the environment in `class_setup` if available and allowed;
- define exact dependency table names from the production source;
- insert test data per scenario;
- clear test doubles in `setup` or `teardown`;
- destroy the environment in `class_teardown`;
- never depend on productive table content.

## CDS Test Environment Rules

For CDS dependencies:

- use `cl_cds_test_environment` when production code reads from CDS entities or
  views;
- create the environment in `class_setup` if available and allowed;
- use exact CDS entities and dependency names from source or metadata;
- insert data with the row type of the **doubled entity**, not the row type of
  the CDS view passed to `i_for_entity` — by default
  `cl_cds_test_environment=>create` doubles the immediate `select from` source
  (a transparent table when the view selects directly from a DB table, or an
  intermediate CDS view when the view selects from another CDS view) and any
  association target views, NOT the view itself;
- when a view filters via an association target field
  (e.g. `where _Other.<field> = ...`), seed the **association target view**
  (not its leaf table) — the framework registers the target as a doubled CDS
  view;
- do not list a view's own association targets in `create_for_multiple_cds` —
  they are auto-doubled and the framework will reject the duplicate;
- clear test data between tests;
- destroy the environment in `class_teardown`;
- never use productive data as test data.

Do not mix SQL and CDS test environments unless the production unit really uses
both direct SQL table access and CDS access.

## External Dependency Rules

For HTTP, RFC, BAPI, function module, update task, application log, lock object,
number range, authorization, date/time/user, or system context dependencies:

- prefer an existing project seam, wrapper, or provider;
- otherwise use a local fake if the seam already exists;
- do not call external systems or productive infrastructure from ABAP Unit tests;
- report a testability blocker when there is no safe seam.

## Testability Blockers

Common blockers include:

- hard-coded static dependencies without a seam;
- direct object creation of external dependencies inside the method under test;
- direct HTTP/RFC/BAPI/function module calls;
- update task usage;
- `COMMIT WORK` or `COMMIT ENTITIES`;
- hard-coded date, time, user, or system context;
- number range or lock object calls without a wrapper;
- real authorization checks without a seam;
- productive DB reads that cannot be isolated in the target environment;
- unavailable or unknown BDEF/CDS/DDIC metadata.

When a blocker is identified, do not generate misleading tests. Report the blocker
using this format. The "Minimal recommended production change" section is
**mandatory** — always provide a concrete, specific refactoring suggestion, not
a generic statement. Name the interface to extract, the seam to introduce, or
the wrapper to add.

```markdown
## Testability Blocker

Affected unit: `<class_or_behavior>` / `<method_or_handler>`

Blocker: The method creates or calls `<dependency>` directly, so the test cannot
replace it with a fake or test double.

Why this blocks isolated testing:
- The test would call productive logic or external side effects.
- The dependency behavior cannot be controlled deterministically.
- Assertions would depend on runtime state outside the unit under test.

Minimal recommended production change:
- Introduce `<interface_name>` or a small wrapper around `<dependency>`.
- Inject it through the constructor, factory, or project-approved test seam.

Possible test strategy after the change:
- Use a local fake implementing `<interface_name>`.
- Verify the successful path, failure path, and no-call path for invalid input.
```

Note: a testability blocker report is an exception to the code-only output rule —
it is markdown prose, not ABAP code. Keep the proposed production change minimal.
