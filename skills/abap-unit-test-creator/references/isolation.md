# Dependency Isolation

Use when production code has SQL, CDS, interface, concrete, static, RAP EML,
authorization, number range, lock, date/time/user, HTTP/RFC/BAPI, function
module, application log, or message dependencies.

## Depth-1 rule

Mock only **direct** dependencies of the unit under test. A proper depth-1
fake (e.g. `ZIF_VALIDATOR`) hides everything behind it — transitive analysis
adds cost without benefit.

Look one level deeper only to identify where to introduce a wrapper or
interface when a depth-1 dependency is a concrete class with no seam. Never
generate tests at depth 2.

## Strategy table

| Dependency | Preferred isolation |
|---|---|
| Interface | Existing project fake → local fake (`ltd_`) → `cl_abap_testdouble` (if allowed) |
| Concrete class | Existing seam → wrapper interface → factory injection → blocker |
| Static method | Wrapper/interface seam → test seam (if allowed) → blocker |
| Direct SQL table | `cl_osql_test_environment` (if allowed) |
| CDS entity | `cl_cds_test_environment` (if allowed) |
| RAP EML | EML test with transactional isolation, usually `IN LOCAL MODE` |
| RAP validation/determination | Direct handler test or EML test, depending on accessibility |
| RAP saver/finalize/check_before_save | Assert failed/reported/messages/buffered without productive persistence |
| Draft behavior | Determine active vs draft scenario explicitly before EML |
| Authorization check | Authorization seam/wrapper/helper → blocker |
| Date/time/user context | Injected clock/context provider, wrapper, or approved seam |
| Number range / lock | Wrapper or fake provider |
| HTTP / RFC / BAPI / FM | Wrapper interface → blocker |
| Application log | Wrapper/fake logger or assert against captured messages |

## Interface and test double order

1. Existing project-specific fake/stub/helper.
2. Local fake (`ltd_`) when behavior is simple and explicit.
3. `cl_abap_testdouble` when interaction verification (call count, argument
   capture, exception injection) is needed and allowed.
4. If production depends on concrete classes or static APIs without a seam,
   report a blocker and recommend the minimal refactoring.

Do not introduce broad DI refactoring unless the user asks. Use existing
seams when present. Prefer reporting a blocker over generating fragile tests.

## SQL test environment rules

- Use `cl_osql_test_environment` when production directly selects from
  transparent tables.
- Create the environment in `class_setup`; destroy in `class_teardown`.
- List exact dependency table names from the source.
- `clear_doubles( )` in `setup` (or `teardown`).
- Insert test data per scenario. Never depend on productive content.

## CDS test environment rules

- Use `cl_cds_test_environment` when production reads CDS entities/views.
- Create in `class_setup`; destroy in `class_teardown`. Clear between tests.
- Insert with the row type of the **doubled entity**, not the row type of
  the view passed to `i_for_entity`. By default, the framework doubles:
  - the immediate `select from` source (transparent table or intermediate
    view, not the leaf at the bottom of a view stack), and
  - association target views referenced in the projection.
- When a view filters via an association target field (`where _Other.<f> = …`),
  seed the **target view**, not its leaf table.
- Do not list a view's own association targets in `create_for_multiple_cds` —
  they are auto-doubled and the framework rejects duplicates.
- Never use productive data.
- Do not mix SQL and CDS environments unless production really uses both.

## Testability blockers

Common blockers:
- Hard-coded static dependencies without a seam.
- Direct `NEW` of external dependencies inside the method under test.
- Direct HTTP/RFC/BAPI/FM calls; update task; `COMMIT WORK`/`COMMIT ENTITIES`.
- Hard-coded date, time, user, system context.
- Number range / lock without wrapper.
- Real authorization checks without a seam.
- Productive DB reads that cannot be isolated in the target environment.
- Unavailable BDEF/CDS/DDIC metadata.

When blocked, do not generate misleading tests. Use this template (markdown,
not ABAP). The "Minimal recommended production change" section is mandatory
— name the interface, seam, or wrapper concretely.

```markdown
## Testability Blocker

Affected unit: `<class_or_behavior>` / `<method_or_handler>`

Blocker: The method creates or calls `<dependency>` directly, so the test
cannot replace it with a fake or test double.

Minimal recommended production change:
- Introduce `<interface_name>` or a small wrapper around `<dependency>`.
- Inject it through the constructor, factory, or project-approved test seam.

Possible test strategy after the change:
- Use a local fake implementing `<interface_name>`.
- Verify success path, failure path, and no-call path for invalid input.
```
