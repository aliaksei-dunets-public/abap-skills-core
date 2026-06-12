# Example: Accessing Private Members with FRIENDS Clause

Use this pattern when the method under test is private or protected and cannot be
reached through the public interface. This is an on-premise / S/4HANA on-premise
pattern. Do not use in ABAP Cloud unless the project profile explicitly allows it.

Only use FRIENDS when direct method invocation is genuinely the best test strategy
and the production class cannot be reasonably refactored to expose a testing seam.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---

"--- Production class (abbreviated) ---
CLASS <class_under_test> DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PRIVATE SECTION.
    METHODS <private_method>
      IMPORTING iv_input TYPE <input_type>
      RETURNING VALUE(rv_result) TYPE <result_type>.
ENDCLASS.

"--- Local test class: declares friendship with the production class ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO <class_under_test>.

    METHODS setup.
    METHODS <private_method>_<scenario> FOR TESTING.
ENDCLASS.

"--- Production class definition must name the test class as FRIENDS ---
CLASS <class_under_test> DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  FRIENDS ltc_<unit_name>.          "<<< Add this line to production class
  ...

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <private_method>_<scenario>.
    " Arrange
    DATA(lv_input) = <test_input_value>.

    " Act — direct call to private method via friendship
    DATA(lv_result) = cut-><private_method>( lv_input ).

    " Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = lv_result
      msg = '<describe expected private-method behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

## When to Use

- The logic inside the private method is complex enough to warrant direct test coverage.
- The method has multiple branches or error paths that are hard to trigger through the
  public API alone.
- The project profile confirms FRIENDS clause is allowed.
- S/4HANA on-premise or S/4HANA Cloud Private Edition environment.

## When NOT to Use

- ABAP Cloud or S/4HANA Cloud Public Edition (unless project profile explicitly allows it).
- The private method can be reached indirectly through a public method with
  reasonable test setup.
- The FRIENDS clause would require modifying a production class that is in a
  released or transport-locked package — use `LOCAL FRIENDS` in the testclasses
  include instead (see section below).
- The private method belongs to a third-party or SAP standard class.

## Usage Rules

- The `FRIENDS` declaration must be added to the production class definition —
  the test class cannot grant itself friendship unilaterally.
- List only the test class names that genuinely need access.
- Do not use FRIENDS as a shortcut to bypass refactoring. Prefer exposing a
  testing seam through a public factory method, injection, or interface when feasible.
- Remove the FRIENDS clause if the test class is deleted or renamed.

---

## Non-invasive variant: `LOCAL FRIENDS` in the testclasses include

Use this variant when the production class is in a released or transport-locked
package, when you must not modify production source, or when you only need
test-time access to private members from a local test class living in the same
class's testclasses include.

`LOCAL FRIENDS` is declared in the **testclasses include** of the production
class — the production source itself stays untouched. The friendship is scoped
to the local test class only.

```abap
"--- testclasses include of <class_under_test> ---

" Forward declaration is REQUIRED — LOCAL FRIENDS is parsed before the
" CLASS ltc_<unit_name> DEFINITION below.
CLASS ltc_<unit_name> DEFINITION DEFERRED.

" Grant the local test class access to private members of the production class.
" The production class definition does not need to mention the test class.
CLASS <class_under_test> DEFINITION LOCAL FRIENDS ltc_<unit_name>.

CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO <class_under_test>.
    METHODS setup.
    METHODS <private_method>_<scenario> FOR TESTING.
ENDCLASS.
```

### When to prefer LOCAL FRIENDS over FRIENDS

| Situation | Use |
|---|---|
| Production class is in a released package or already widely consumed | `LOCAL FRIENDS` |
| Test class is local to the production class's testclasses include | `LOCAL FRIENDS` |
| Test class is a dedicated, package-level helper class shared across multiple test classes | `FRIENDS` (declared in production) — note: embeds test-class name in production source; production class cannot activate without the helper present |
| You must reset a private static singleton between tests | `LOCAL FRIENDS` |

### Singleton state reset (verified pattern)

Production singletons created with `CREATE PRIVATE` and an internal
`go_instance` static class-data reference cache state from their constructor.
The cache survives across test methods unless reset.

`LOCAL FRIENDS` lets the test class clear the cache between scenarios so each
test sees a fresh constructor pass against the current CDS / SQL test doubles.

```abap
"--- Production class (read-only, NOT modified) ---
CLASS <class_under_test> DEFINITION
  PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(ro_instance) TYPE REF TO <class_under_test>.
  PRIVATE SECTION.
    CLASS-DATA go_instance TYPE REF TO <class_under_test>.
    METHODS constructor.                          " reads CDS/SQL into mt_cache once
    DATA mt_cache TYPE <cache_table_type>.
ENDCLASS.

"--- testclasses include ---
CLASS ltc_<unit_name> DEFINITION DEFERRED.
CLASS <class_under_test> DEFINITION LOCAL FRIENDS ltc_<unit_name>.

CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    CLASS-DATA cds_environment TYPE REF TO if_cds_test_environment.
    DATA cut TYPE REF TO <class_under_test>.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.
    METHODS reset_singleton.
    METHODS <scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD class_setup.
    " Initialize once for the whole test class.
    " Use create( i_for_entity = '<view_name>' ) — see cds-test-environment.md.
    cds_environment = cl_cds_test_environment=>create(
      i_for_entity = '<cds_entity_name>' ).
  ENDMETHOD.

  METHOD class_teardown.
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD reset_singleton.
    " Direct field access via LOCAL FRIENDS — no production change needed.
    " go_instance is PRIVATE CLASS-DATA; LOCAL FRIENDS grants this access.
    CLEAR <class_under_test>=>go_instance.
  ENDMETHOD.

  METHOD setup.
    cds_environment->clear_doubles( ).
    reset_singleton( ).
  ENDMETHOD.

  METHOD teardown.
    " Cleans up after the last test method in the class (class_teardown destroys
    " the environment, but clearing here keeps state tidy for any unexpected
    " re-use). setup already runs before each test, so this is belt-and-braces.
    cds_environment->clear_doubles( ).
    reset_singleton( ).
  ENDMETHOD.

  METHOD <scenario>.
    " 1. Seed CDS doubles — use the row type of the DOUBLED entity,
    "    not the view type. See cds-test-environment.md "What gets doubled".
    "    Do NOT initialize cut here; get_instance must be called AFTER seeding
    "    so the constructor reads the freshly inserted doubles.
    DATA rows TYPE STANDARD TABLE OF <doubled_entity_row_type>.
    rows = VALUE #( ( <key_field> = <value> ) ).
    cds_environment->insert_test_data( i_data = rows ).

    " 2. Call get_instance — constructor runs against the freshly seeded doubles.
    cut = <class_under_test>=>get_instance( ).

    " 3. Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected>
      act = cut-><method>( )
      msg = '<describe expected behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Without the singleton reset, the first test method seeds the cache and every
subsequent test reuses it regardless of fresh `insert_test_data` calls — tests
become order-dependent and silently wrong.
