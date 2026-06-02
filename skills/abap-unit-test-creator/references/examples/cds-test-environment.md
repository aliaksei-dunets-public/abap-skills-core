# Example: CDS Isolation with `cl_cds_test_environment`

Use this example when production code reads from CDS entities/views and the target environment supports CDS test doubles.

Use only verified CDS names, dependency names, and row types.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA cds_environment TYPE REF TO if_cds_test_environment.
    DATA cut TYPE REF TO <class_under_test>.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS <method_under_test>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD class_setup.
    cds_environment = cl_cds_test_environment=>create(
      i_for_entity = '<cds_entity_name>' ).
  ENDMETHOD.

  METHOD class_teardown.
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    cds_environment->clear_doubles( ).
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <method_under_test>_<scenario>.
    DATA test_rows TYPE STANDARD TABLE OF <cds_dependency_or_table_type>.

    test_rows = VALUE #(
      ( <field_1> = <value_1>
        <field_2> = <value_2> ) ).

    cds_environment->insert_test_data( test_rows ).

    DATA(result) = cut-><method_under_test>( <input> ).

    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = result
      msg = '<explain CDS-backed behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Usage rules:

- Use this pattern only when the production code reads CDS entities/views.
- Do not use this pattern for direct SQL table access unless the source also uses CDS access.
- Verify exact row types before generating final code.
- If CDS dependencies cannot be identified, inspect metadata or report assumptions.
