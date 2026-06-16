# Example: Accessing Private Members with FRIENDS / LOCAL FRIENDS

Use when the method under test is private/protected with no public seam.
On-premise / S/4HANA Private pattern. Forbidden in ABAP Cloud unless the
project profile allows it. Use only when direct invocation is genuinely the
best strategy and the class cannot be reasonably refactored.

## Variant choice

| Situation | Variant |
|---|---|
| Production class in a released or transport-locked package; must not modify production source | `LOCAL FRIENDS` (declared in the testclasses include — production stays untouched) |
| Local test class lives in the production class's testclasses include | `LOCAL FRIENDS` |
| Need to reset a private static singleton between tests | `LOCAL FRIENDS` |
| Test class is a dedicated package-level helper shared across multiple test classes | `FRIENDS` declared in the production class — embeds the helper name in production source |

## Variant A — `FRIENDS` in the production class

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---

"--- Production class ---
CLASS <class_under_test> DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  FRIENDS ltc_<unit_name>.          "<<< Add to production class

  PRIVATE SECTION.
    METHODS <private_method>
      IMPORTING iv_input         TYPE <input_type>
      RETURNING VALUE(rv_result) TYPE <result_type>.
ENDCLASS.

"--- Test class ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO <class_under_test>.

    METHODS setup.
    METHODS <private_method>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <private_method>_<scenario>.
    DATA(lv_input)  = <test_input_value>.
    DATA(lv_result) = cut-><private_method>( lv_input ).

    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = lv_result
      msg = '<describe expected private-method behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

## Variant B — `LOCAL FRIENDS` in the testclasses include

Production source stays untouched. Friendship is scoped to the local test
class.

```abap
"--- testclasses include of <class_under_test> ---

" Forward declaration is REQUIRED — LOCAL FRIENDS is parsed first.
CLASS ltc_<unit_name> DEFINITION DEFERRED.

" Grant the local test class access to private members of the production class.
" Production class definition does NOT need to mention the test class.
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

## Singleton state reset (verified pattern)

`CREATE PRIVATE` classes with an internal `go_instance` static reference
cache state from the constructor across test methods. `LOCAL FRIENDS` lets
the test class clear the cache so each test sees a fresh constructor pass
against current CDS / SQL doubles.

```abap
"--- Production class (read-only) ---
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
    cds_environment = cl_cds_test_environment=>create(
      i_for_entity = '<cds_entity_name>' ).
  ENDMETHOD.

  METHOD class_teardown.
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD reset_singleton.
    " Direct field access via LOCAL FRIENDS — no production change.
    CLEAR <class_under_test>=>go_instance.
  ENDMETHOD.

  METHOD setup.
    cds_environment->clear_doubles( ).
    reset_singleton( ).
  ENDMETHOD.

  METHOD teardown.
    cds_environment->clear_doubles( ).
    reset_singleton( ).
  ENDMETHOD.

  METHOD <scenario>.
    " 1. Seed CDS doubles BEFORE calling get_instance — constructor reads them.
    DATA rows TYPE STANDARD TABLE OF <doubled_entity_row_type>.
    rows = VALUE #( ( <key_field> = <value> ) ).
    cds_environment->insert_test_data( i_data = rows ).

    " 2. Build the singleton against fresh doubles.
    cut = <class_under_test>=>get_instance( ).

    " 3. Assert.
    cl_abap_unit_assert=>assert_equals(
      exp = <expected>
      act = cut-><method>( )
      msg = '<describe expected behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Without the singleton reset, the first test seeds the cache and every
subsequent test reuses it regardless of fresh `insert_test_data` calls —
tests become order-dependent and silently wrong.

## Rules

- Do not use FRIENDS in ABAP Cloud / Public unless the project profile
  explicitly allows it.
- Do not use FRIENDS as a shortcut to bypass refactoring. Prefer a public
  factory, injection, or interface seam when feasible.
- Do not declare FRIENDS for the private method of a third-party / SAP
  standard class.
- The `FRIENDS` clause in production must list only test classes that
  genuinely need access; remove on rename/deletion.
