# Example: RAP EML-Based Test

Use when behavior must be triggered through RAP runtime semantics —
validations, determinations, actions, or transactional buffer behavior.

> **DURATION:** EML tests that internally trigger a BDEF kernel lookup
> (`cl_abap_behvdescr=>get_instance` or similar) may exceed the `SHORT`
> budget — use `DURATION MEDIUM`. Pure EML tests with no kernel lookup may
> stay on `DURATION SHORT`.

Use only verified BDEF, entity, field, and key names.

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

Negative validation:

```abap
cl_abap_unit_assert=>assert_not_initial(
  act = failed-<entity_name>
  msg = 'Invalid input should produce a failed entry' ).

cl_abap_unit_assert=>assert_not_initial(
  act = reported-<entity_name>
  msg = 'Invalid input should produce a reported message' ).
```

Rules:
- Prefer `IN LOCAL MODE` for behavior-implementation internals.
- `ROLLBACK ENTITIES` in teardown for state-mutating tests.
- No `COMMIT ENTITIES` unless explicitly requested.
- Do not invent draft EML — confirm BDEF, fields, and required keys first.
