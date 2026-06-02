# Example: Interface Test Double with CL_ABAP_TESTDOUBLE

`CL_ABAP_TESTDOUBLE` is the ABAP Test Double Framework shipped with SAP NetWeaver / S/4HANA.
It generates a dynamic double for any interface at runtime, removing the need to write a
hand-coded local fake class. Use it when you need declarative stub/spy/interaction-verification
behavior and do not want to maintain a separate fake class per interface. Prefer a hand-written
local fake (`ltd_*`) when the interface is large but only one or two methods are exercised, or
when the test logic is complex enough that an explicit implementation is more readable.

---

## When to Use

- The production unit depends on an interface injected via constructor or setter, and the
  interface has many methods that do not all need stubbing.
- You need to verify that a specific method was called (interaction verification / spy behavior)
  without writing counter fields manually.
- You need to assert the number of times a method was called, or the exact arguments it received.
- You need to configure a method to raise a specific exception to test the error path.
- The project profile does not restrict `CL_ABAP_TESTDOUBLE`.

---

## Basic Pattern: Creating the Double

The `CREATE` method takes the interface name as a `STRING` (uppercase) and returns `REF TO OBJECT`.
Cast it immediately with `CAST` to the interface type.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace application-specific names with verified identifiers ---

CLASS ltc_order_processor DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut              TYPE REF TO zcl_order_processor.
    DATA double_validator TYPE REF TO if_order_validator.

    METHODS setup.
    METHODS validate_succeeds_valid_order   FOR TESTING.
    METHODS validate_fails_invalid_order    FOR TESTING.
ENDCLASS.

CLASS ltc_order_processor IMPLEMENTATION.

  METHOD setup.
    " Create the double — recreated per test to reset call history
    double_validator = CAST if_order_validator(
      cl_abap_testdouble=>create( 'IF_ORDER_VALIDATOR' ) ).

    " Inject through constructor
    cut = NEW zcl_order_processor( io_validator = double_validator ).
  ENDMETHOD.

  METHOD validate_succeeds_valid_order.
    " Arrange — configure stub: return true for this input
    cl_abap_testdouble=>configure_call( double_validator
      )->returning( abap_true ).
    double_validator->is_valid( iv_order_id = '4500000001' ).

    " Act
    DATA(lv_result) = cut->process( iv_order_id = '4500000001' ).

    " Assert
    cl_abap_unit_assert=>assert_true(
      act = lv_result
      msg = 'process() should succeed when validator returns true' ).
  ENDMETHOD.

  METHOD validate_fails_invalid_order.
    " Arrange
    cl_abap_testdouble=>configure_call( double_validator
      )->returning( abap_false ).
    double_validator->is_valid( iv_order_id = '0000000000' ).

    " Act
    DATA(lv_result) = cut->process( iv_order_id = '0000000000' ).

    " Assert
    cl_abap_unit_assert=>assert_false(
      act = lv_result
      msg = 'process() should fail when validator returns false' ).
  ENDMETHOD.

ENDCLASS.
```

---

## Configuring Return Values

`CONFIGURE_CALL` / `RETURNING` works in two steps:

1. Call `CL_ABAP_TESTDOUBLE=>CONFIGURE_CALL( double )->RETURNING( value )` to set the return value.
2. Immediately invoke the method on the double with the exact input to register the stub.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY ---

" Configure for specific input
cl_abap_testdouble=>configure_call( double_pricing )->returning( '100.00' ).
double_pricing->get_price( iv_material = 'MAT-001' iv_quantity = 10 ).

" Configure different return for different input
cl_abap_testdouble=>configure_call( double_pricing )->returning( '90.00' ).
double_pricing->get_price( iv_material = 'MAT-001' iv_quantity = 100 ).

" Any call with parameters not configured returns the type-initial value.
```

---

## Verifying Interactions

Use `CL_ABAP_TESTDOUBLE=>ASSERT_CALLS_WERE_MADE( double )` to verify all configured
call expectations were satisfied.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY ---

METHOD sends_notification_once.
  " Arrange — configure stub with exact call count expectation
  cl_abap_testdouble=>configure_call( double_notifier
    )->times( 1 ).
  double_notifier->send( iv_recipient = 'user@example.com' ).

  " Act
  cut->complete_order( iv_order_id = '4500000002' ).

  " Assert — verify the method was called exactly once
  cl_abap_testdouble=>assert_calls_were_made( double_notifier ).
ENDMETHOD.
```

---

## Configuring Exceptions

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY ---

METHOD process_raises_exception_on_validation_error.
  " Arrange — configure the double to raise an exception
  cl_abap_testdouble=>configure_call( double_validator
    )->raising( 'ZCX_VALIDATION_ERROR' ).
  double_validator->is_valid( iv_order_id = 'BAD-ORDER' ).

  " Act + Assert
  TRY.
    cut->process( iv_order_id = 'BAD-ORDER' ).
    cl_abap_unit_assert=>fail(
      msg = 'Expected ZCX_VALIDATION_ERROR to be raised' ).
  CATCH zcx_validation_error.
    " Expected path
  ENDTRY.
ENDMETHOD.
```

The exception class name passed to `RAISING()` is a `STRING` with the exact ABAP class name.
The exception must be declared in the interface method's `RAISING` clause.

---

## Full Test Class Example

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace application-specific names with verified identifiers ---

"----------------------------------------------------------------------
" Assumed interface (defined elsewhere):
"   INTERFACE if_stock_checker
"     METHODS is_in_stock
"       IMPORTING iv_material TYPE matnr
"       RETURNING VALUE(rv_result) TYPE abap_bool
"       RAISING zcx_stock_check_error.
"   ENDINTERFACE.
"----------------------------------------------------------------------

CLASS ltc_order_fulfillment DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut          TYPE REF TO zcl_order_fulfillment.
    DATA double_stock TYPE REF TO if_stock_checker.

    METHODS setup.
    METHODS fulfill_succeeds_when_in_stock    FOR TESTING.
    METHODS fulfill_fails_not_in_stock        FOR TESTING.
    METHODS fulfill_handles_check_error       FOR TESTING.
    METHODS fulfill_calls_stock_check_once    FOR TESTING.
ENDCLASS.

CLASS ltc_order_fulfillment IMPLEMENTATION.

  METHOD setup.
    double_stock = CAST if_stock_checker(
      cl_abap_testdouble=>create( 'IF_STOCK_CHECKER' ) ).
    cut = NEW zcl_order_fulfillment( io_stock_checker = double_stock ).
  ENDMETHOD.

  METHOD fulfill_succeeds_when_in_stock.
    cl_abap_testdouble=>configure_call( double_stock
      )->returning( abap_true ).
    double_stock->is_in_stock( iv_material = 'MAT-WIDGET-01' ).

    DATA(lv_fulfilled) = cut->fulfill_order(
      iv_order_id = '4500000100'
      iv_material = 'MAT-WIDGET-01' ).

    cl_abap_unit_assert=>assert_true(
      act = lv_fulfilled
      msg = 'Order fulfillment should succeed when material is in stock' ).
  ENDMETHOD.

  METHOD fulfill_fails_not_in_stock.
    cl_abap_testdouble=>configure_call( double_stock
      )->returning( abap_false ).
    double_stock->is_in_stock( iv_material = 'MAT-WIDGET-01' ).

    DATA(lv_fulfilled) = cut->fulfill_order(
      iv_order_id = '4500000101'
      iv_material = 'MAT-WIDGET-01' ).

    cl_abap_unit_assert=>assert_false(
      act = lv_fulfilled
      msg = 'Order fulfillment should fail when material is out of stock' ).
  ENDMETHOD.

  METHOD fulfill_handles_check_error.
    cl_abap_testdouble=>configure_call( double_stock
      )->raising( 'ZCX_STOCK_CHECK_ERROR' ).
    double_stock->is_in_stock( iv_material = 'MAT-UNKNOWN' ).

    TRY.
      cut->fulfill_order(
        iv_order_id = '4500000102'
        iv_material = 'MAT-UNKNOWN' ).
      cl_abap_unit_assert=>fail(
        msg = 'ZCX_STOCK_CHECK_ERROR should have been raised or handled' ).
    CATCH zcx_stock_check_error.
      " Expected path
    ENDTRY.
  ENDMETHOD.

  METHOD fulfill_calls_stock_check_once.
    " Arrange with call count expectation
    cl_abap_testdouble=>configure_call( double_stock
      )->returning( abap_true
      )->times( 1 ).
    double_stock->is_in_stock( iv_material = 'MAT-WIDGET-02' ).

    cut->fulfill_order(
      iv_order_id = '4500000103'
      iv_material = 'MAT-WIDGET-02' ).

    " Verify is_in_stock was called exactly once
    cl_abap_testdouble=>assert_calls_were_made( double_stock ).
  ENDMETHOD.

ENDCLASS.
```

---

## Usage Rules

- `CL_ABAP_TESTDOUBLE=>CREATE` takes the interface name as a `STRING` (uppercase);
  the return type is `REF TO OBJECT` — cast immediately with `CAST`.
- `CONFIGURE_CALL` must be followed immediately by a direct method call on the double
  to register the stub; that recording call does not invoke production logic.
- `RETURNING( value )` and `RAISING( 'CLASS_NAME' )` chain on the result of `CONFIGURE_CALL`.
- `TIMES( n )` sets the expected invocation count; omitting it means unconstrained calls.
- `ASSERT_CALLS_WERE_MADE( double )` verifies all `TIMES`-configured expectations.
  Call it after the Act step or in `teardown`.
- Recreate the double in `setup` per test (not `class_setup`) to ensure a clean call
  history for each test.
- The double returns the type-initial value for any method not explicitly configured.
- Do not configure the same method twice for identical inputs without recreating the
  double first; behavior of duplicate configuration is version-dependent.
- Note: verify whether your system supports `CL_ABAP_TESTDOUBLE=>IGNORE_PARAMETER` —
  availability varies by ABAP platform release.

---

## When NOT to Use (prefer local fake instead)

- The interface has only one or two methods and stub logic is trivial — a hand-written
  `ltd_*` fake is more readable with lower framework overhead.
- The fake needs to accumulate internal state (e.g., collect all calls into an internal
  table for later inspection) that is clearer as an explicit implementation.
- The project profile or target environment restricts `CL_ABAP_TESTDOUBLE`.
- The test needs to verify complex call sequences (method A before method B with linked
  arguments) — hand-written fakes with explicit call-log fields are clearer.
- The production code creates the dependency internally without an injection seam —
  `CL_ABAP_TESTDOUBLE` cannot substitute an internally created object; introduce a
  constructor injection or factory seam first.
