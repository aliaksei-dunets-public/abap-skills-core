# Example: SQL Table Isolation with `cl_osql_test_environment`

Use when production directly reads transparent DB tables with Open SQL. Use
only verified table names and row types.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA osql_environment TYPE REF TO if_osql_test_environment.
    DATA cut TYPE REF TO <class_under_test>.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS <method_under_test>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD class_setup.
    osql_environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( '<db_table_name>' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    osql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    osql_environment->clear_doubles( ).
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <method_under_test>_<scenario>.
    DATA test_rows TYPE STANDARD TABLE OF <db_table_name>.

    test_rows = VALUE #(
      ( <field_1> = <value_1>
        <field_2> = <value_2> ) ).

    osql_environment->insert_test_data( test_rows ).

    DATA(result) = cut-><method_under_test>( <input> ).

    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = result
      msg = '<explain SQL-backed behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Rules:
- Direct Open SQL table access only.
- List every directly selected table in the dependency list.
- Clear doubles between tests.
- If the environment forbids this API, use a project-approved isolation
  pattern or report a blocker.
