# Authoring Gotchas — Compile-Time and Runtime Pitfalls

Short reference covering ABAP-specific authoring traps that affect unit-test
generation but are not strictly isolation, coverage, or RAP topics. Load this
file when generating tests against ABAP S/4HANA on-premise or ABAP Cloud
production code that uses fixed-value domains, raises exceptions, or relies on
tightly bounded identifier lengths.

## Domain fixed-value list — compile-time literal check

When a method parameter or attribute is typed against a data element whose
domain has a **fixed-value list**, the ABAP compiler rejects literal `CONV`
expressions whose value is not in the list. This affects "negative-path" tests
that pass a deliberately invalid value to assert exception behavior.

### Symptom

```
Value 'XX' violates the domain fixed value list.
```

### Fix

Assemble the lookup argument into a **named data object** (variable or constant)
typed against a generic base type of the same length and ABAP type. The
fixed-value check is compile-time only on **literals**; it does not fire when
the right-hand side is a named data object.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
" Declare a helper variable with a GENERIC type of the same length/kind,
" NOT with the domain-restricted data element type.
DATA lv_arg TYPE <generic_type_same_length>.   " e.g. c LENGTH 2, or string
lv_arg = 'XX'.                                 " out-of-range value — OK, no domain check on DATA

" Pass the variable — fixed-value check does not fire on variable-to-variable assignments.
cut-><method_under_test>( lv_arg ).
```

> **Do NOT** declare `lv_arg TYPE <de_with_fixed_values>` and assign a literal
> `lv_arg = 'XX'` — assigning an out-of-range string literal to a domain-typed
> variable still triggers the compile-time check. Use a generic type.

## TRY/CATCH wrapping for `RAISING` methods

When the method under test declares `RAISING <exception>`, every call site —
including success-path tests — must handle the exception or the test class will
fail activation.

### Success-path test

```abap
TRY.
    DATA(result) = cut-><method_under_test>( <good_input> ).
    " success-path assertions here
  CATCH <exception_class>.
    cl_abap_unit_assert=>fail( msg = '<method must NOT raise for valid input>' ).
ENDTRY.
```

### Exception-path test

```abap
TRY.
    cut-><method_under_test>( <bad_input> ).
    cl_abap_unit_assert=>fail( msg = '<method must raise for invalid input>' ).
  CATCH <exception_class>.
    " expected — empty body
ENDTRY.
```

The `fail` call AFTER the method invocation in the exception-path test is what
detects the silent miss when the method does NOT raise. A bare `CATCH` without
the trailing `fail` would let a non-raising method pass the test by accident.

### Multiple RAISING types

When the method declares `RAISING cx_a cx_b`, write a separate test for each
exception and catch **only the expected type** in that test. If the method
raises a different exception (e.g. `cx_b` when you expected `cx_a`), it will
propagate out of the test method uncaught — the framework records this as a
test **error** (runtime abort), not a test failure. That is the correct outcome:
catching both types in one `CATCH` block would hide the wrong-exception bug.

```abap
" Test targeting cx_a only:
TRY.
    cut-><method_under_test>( <input_that_should_raise_cx_a> ).
    cl_abap_unit_assert=>fail( msg = 'must raise cx_a' ).
  CATCH cx_a.
    " expected
ENDTRY.

" Repeat the same structure for each additional declared exception:
" TRY.
"     cut-><method_under_test>( <input_that_should_raise_cx_b> ).
"     cl_abap_unit_assert=>fail( msg = 'must raise cx_b' ).
"   CATCH cx_b.
"     " expected
" ENDTRY.
```

## Test method name length

ABAP identifiers (class names, method names) are limited to **30 characters**
total. This applies to both the test class name and each test method name.

### Test class name

`ltc_<unit_name>` counts against the 30-character budget. Shorten `<unit_name>`
if the production class name is long:

| Too long (rejected) | Shortened (accepted) |
|---|---|
| `ltc_get_deploy_mode_manager` (29 chars — borderline) | `ltc_deploy_mode_mgr` |
| `ltc_authorization_check_handler` (32 chars) | `ltc_auth_check_handler` |

### Test method name

The `<method>_<scenario>` naming convention means the scenario suffix eats
directly into the same 30-character budget. Shorten to the single most
important verb+noun pair:

| Too long (rejected) | Shortened (accepted) |
|---|---|
| `get_deploy_mode_by_value_returns_match` | `get_by_value_returns_match` |
| `get_deploy_mode_by_name_keys_on_value` | `get_by_name_keys_on_value` |
| `get_deploy_mode_by_name_raises_unknown` | `get_by_name_raises_unknown` |

Drop the redundant context (`deploy_mode`) — the test class name already
carries it.

## ABAP Doc (`"!`) on test method declarations

ABAP Doc comments (`"!`) on `FOR TESTING` method declarations trigger a syntax
warning. Use freestyle star comments (`*`) above the method declaration or
implementation instead.

```abap
* Pins the current implementation fact: get_X_by_name keys on CharacValue,
* not on CharacDescr. Update when the lookup field is corrected.
METHOD <test_method>.
  ...
ENDMETHOD.
```

## Behavior-pinning tests

When a unit test documents a known but counter-intuitive implementation fact
(e.g. a method named `get_by_name` that actually keys on a different field),
make this explicit in the test method name AND in a star-comment header above
the body. State precisely which behavior is pinned so a future developer who
fixes the underlying issue knows to update the test.

**Use pinning only when fixing the underlying behavior is out of scope for the
current task.** Do NOT pin a bug that can be fixed in the same session — report
it as a code quality issue instead. A pinned test on a fixable bug actively
misleads future developers by making the wrong behavior look intentional.

```abap
METHOD get_by_name_keys_on_value.
  " IMPLEMENTATION FACT: get_X_by_name currently looks up rows by <actual_field>
  " (not by <expected_field_per_method_name>) — see the implementation. This
  " test pins down the actual behaviour. If the lookup is later switched to
  " <expected_field_per_method_name> this test must be updated.
  ...
ENDMETHOD.
```

A pinned-behavior test is more valuable than no test at all when refactoring
the underlying production logic is out of scope.
