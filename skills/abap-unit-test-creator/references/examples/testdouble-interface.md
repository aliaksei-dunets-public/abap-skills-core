# Example: Interface Test Double with `cl_abap_testdouble`

Dynamic test double for any interface — no hand-coded fake class. Use when
declarative stub/spy/interaction-verification is needed and the interface is
large or the test must verify call counts, arguments, or injected
exceptions. Prefer a hand-written `ltd_*` fake when only one or two methods
are exercised, when state must be accumulated explicitly, or when complex
call sequences are clearer in code.

## When to use vs. local fake

| Use `cl_abap_testdouble` | Use hand-written `ltd_*` |
|---|---|
| Interface has many methods, only some need stubbing | Only 1–2 methods exercised, trivial logic |
| Need call count / argument verification (`times`, `assert_calls_were_made`) | Need to collect state into an internal table for later inspection |
| Need to inject an exception (`raising`) | Project profile / target environment forbids `cl_abap_testdouble` |
| Project profile allows the framework | Complex linked-call sequences clearer as explicit code |
| Production injects the interface via constructor / setter | Production creates the dependency internally — neither approach works; introduce a seam first |

## Basic pattern

`CREATE` takes the interface name as `STRING` (uppercase) and returns
`REF TO OBJECT`. Cast immediately.

```abap
"--- ILLUSTRATIVE EXAMPLE — replace application-specific names with verified ones ---
CLASS ltc_order_processor DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut              TYPE REF TO zcl_order_processor.
    DATA double_validator TYPE REF TO if_order_validator.

    METHODS setup.
    METHODS validate_succeeds_valid_order FOR TESTING.
    METHODS validate_fails_invalid_order  FOR TESTING.
ENDCLASS.

CLASS ltc_order_processor IMPLEMENTATION.
  METHOD setup.
    " Recreate per test to reset call history.
    double_validator = CAST if_order_validator(
      cl_abap_testdouble=>create( 'IF_ORDER_VALIDATOR' ) ).
    cut = NEW zcl_order_processor( io_validator = double_validator ).
  ENDMETHOD.

  METHOD validate_succeeds_valid_order.
    cl_abap_testdouble=>configure_call( double_validator
      )->returning( abap_true ).
    double_validator->is_valid( iv_order_id = '4500000001' ).

    DATA(lv_result) = cut->process( iv_order_id = '4500000001' ).

    cl_abap_unit_assert=>assert_true(
      act = lv_result
      msg = 'process() should succeed when validator returns true' ).
  ENDMETHOD.

  METHOD validate_fails_invalid_order.
    cl_abap_testdouble=>configure_call( double_validator
      )->returning( abap_false ).
    double_validator->is_valid( iv_order_id = '0000000000' ).

    DATA(lv_result) = cut->process( iv_order_id = '0000000000' ).

    cl_abap_unit_assert=>assert_false(
      act = lv_result
      msg = 'process() should fail when validator returns false' ).
  ENDMETHOD.
ENDCLASS.
```

## Configuring return values

Two-step: configure → register the stub by calling the method on the double.
The recording call does not invoke production logic.

```abap
" Configure for specific input
cl_abap_testdouble=>configure_call( double_pricing )->returning( '100.00' ).
double_pricing->get_price( iv_material = 'MAT-001' iv_quantity = 10 ).

" Different return for different input
cl_abap_testdouble=>configure_call( double_pricing )->returning( '90.00' ).
double_pricing->get_price( iv_material = 'MAT-001' iv_quantity = 100 ).

" Calls with un-configured arguments return the type-initial value.
```

## Verifying interactions

```abap
METHOD sends_notification_once.
  cl_abap_testdouble=>configure_call( double_notifier )->times( 1 ).
  double_notifier->send( iv_recipient = 'user@example.com' ).

  cut->complete_order( iv_order_id = '4500000002' ).

  cl_abap_testdouble=>assert_calls_were_made( double_notifier ).
ENDMETHOD.
```

## Configuring exceptions

```abap
METHOD process_raises_exception_on_validation_error.
  cl_abap_testdouble=>configure_call( double_validator
    )->raising( 'ZCX_VALIDATION_ERROR' ).
  double_validator->is_valid( iv_order_id = 'BAD-ORDER' ).

  TRY.
      cut->process( iv_order_id = 'BAD-ORDER' ).
      cl_abap_unit_assert=>fail( msg = 'Expected ZCX_VALIDATION_ERROR' ).
    CATCH zcx_validation_error.
      " expected
  ENDTRY.
ENDMETHOD.
```

The class name passed to `raising()` is a `STRING` with the exact ABAP
class name. The exception must be in the interface method's `RAISING` clause.

## Rules

- `create` takes the interface name as `STRING` (uppercase); return type is
  `REF TO OBJECT` — cast immediately with `CAST`.
- `configure_call` must be followed immediately by a direct method call on
  the double to register the stub.
- `returning(value)` / `raising('CLASS_NAME')` chain on the result of
  `configure_call`. `times(n)` sets the expected invocation count.
- Recreate the double in `setup` (not `class_setup`) for a clean call
  history per test.
- The double returns the type-initial value for un-configured methods.
- `cl_abap_testdouble=>ignore_parameter` availability is platform-dependent
  — verify before relying on it.
