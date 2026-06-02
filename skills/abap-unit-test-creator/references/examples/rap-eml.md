# Example: RAP EML-Based Unit Test Pattern

Use this example when the behavior must be triggered through RAP runtime semantics, such as validations, determinations, actions, or transactional buffer behavior.

Use only verified BDEF names, entity names, field names, keys, and response types.

> **DURATION note:** EML tests that internally trigger a BDEF kernel lookup
> (`cl_abap_behvdescr=>get_instance` or similar) may exceed the `SHORT` time
> budget. Use `DURATION MEDIUM` for such tests. Pure EML tests that do not
> perform a kernel BDEF lookup may use `DURATION SHORT`.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltc_<behavior_entity> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS <operation>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<behavior_entity> IMPLEMENTATION.
  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD <operation>_<scenario>.
    " Arrange + Act
    MODIFY ENTITIES OF <bdef_name> IN LOCAL MODE
      ENTITY <entity_name>
      CREATE FIELDS ( <field_1> <field_2> )
      WITH VALUE #(
        ( %cid = 'CID_1'
          <field_1> = <value_1>
          <field_2> = <value_2> ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed)
      REPORTED DATA(reported).

    " Assert
    cl_abap_unit_assert=>assert_initial(
      act = failed-<entity_name>
      msg = 'Valid input should not produce failed entries' ).

    cl_abap_unit_assert=>assert_initial(
      act = reported-<entity_name>
      msg = 'Valid input should not produce reported messages' ).
  ENDMETHOD.
ENDCLASS.
```

Negative validation pattern:

```abap
cl_abap_unit_assert=>assert_not_initial(
  act = failed-<entity_name>
  msg = 'Invalid input should produce a failed entry' ).

cl_abap_unit_assert=>assert_not_initial(
  act = reported-<entity_name>
  msg = 'Invalid input should produce a reported message' ).
```

Usage rules:

- Prefer `IN LOCAL MODE` when testing behavior implementation internals and when supported.
- Use `ROLLBACK ENTITIES` in teardown for tests that modify transactional state.
- Do not use `COMMIT ENTITIES` for isolated unit tests unless explicitly requested and safe.
- Do not generate generic draft EML unless the behavior definition confirms draft behavior and required fields.
