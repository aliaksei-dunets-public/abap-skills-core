# Authoring Gotchas

ABAP-specific compile-time and runtime traps for unit-test generation. Load
when production code uses fixed-value domains, raises exceptions, or has
identifiers near the 30-character limit.

## 1. Domain fixed-value list — literal check

When a parameter / attribute is typed against a data element whose domain has
a **fixed-value list**, the compiler rejects literal `CONV` whose value is not
in the list. This blocks negative-path tests passing a deliberately invalid
value.

> Symptom: `Value 'XX' violates the domain fixed value list.`

Fix: assemble the argument into a **named data object** typed with a
**generic** base type of the same length and kind. The fixed-value check is
compile-time on literals only.

```abap
" Use a GENERIC type (e.g. c LENGTH 2, or string) — NOT the domain-restricted DE.
DATA lv_arg TYPE <generic_type_same_length>.
lv_arg = 'XX'.                                 " out-of-range — OK on DATA
cut-><method_under_test>( lv_arg ).
```

> Do NOT declare `lv_arg TYPE <de_with_fixed_values>` and assign `'XX'` —
> that still triggers the check.

## 2. TRY/CATCH wrapping for `RAISING` methods

When the method declares `RAISING <exception>`, every call site — including
success-path tests — must handle it or the test class fails activation.

```abap
" Success-path
TRY.
    DATA(result) = cut-><method_under_test>( <good_input> ).
    " success-path assertions
  CATCH <exception_class>.
    cl_abap_unit_assert=>fail( msg = '<must NOT raise for valid input>' ).
ENDTRY.

" Exception-path
TRY.
    cut-><method_under_test>( <bad_input> ).
    cl_abap_unit_assert=>fail( msg = '<must raise for invalid input>' ).
  CATCH <exception_class>.
    " expected — empty body
ENDTRY.
```

The trailing `fail` after the call in the exception-path test is what catches
the silent miss when the method does NOT raise.

### Multiple `RAISING` types

Write one test per declared exception. Catch only the expected type. If the
method raises a different one, it propagates uncaught and the framework
records a test **error** (correct outcome — catching both would hide bugs).

## 3. 30-character identifier limit

Class and method names are limited to 30 characters total.

| Too long | Shortened |
|---|---|
| `ltc_get_deploy_mode_manager` (29 — borderline) | `ltc_deploy_mode_mgr` |
| `ltc_authorization_check_handler` (32) | `ltc_auth_check_handler` |
| `get_deploy_mode_by_value_returns_match` | `get_by_value_returns_match` |
| `get_deploy_mode_by_name_raises_unknown` | `get_by_name_raises_unknown` |

Drop redundant context — the test class name already carries it.

## 4. ABAP Doc on test methods

ABAP Doc (`"!`) on `FOR TESTING` declarations triggers a syntax warning. Use
star comments (`*`) above the declaration or implementation instead.

```abap
* Pins the current implementation fact: get_X_by_name keys on CharacValue,
* not on CharacDescr. Update when the lookup field is corrected.
METHOD <test_method>.
  ...
ENDMETHOD.
```

## 5. Behavior-pinning tests

When a test documents a counter-intuitive but currently correct
implementation fact, name it explicitly and add a star-comment header
stating which behavior is pinned. Pin only when fixing the behavior is out
of scope — if it is fixable now, report it as a code quality issue instead.

```abap
METHOD get_by_name_keys_on_value.
  " IMPLEMENTATION FACT: get_X_by_name currently looks up rows by
  " <actual_field>, not <expected_field_per_method_name>. This test pins
  " the actual behavior. If the lookup is later corrected, update this test.
  ...
ENDMETHOD.
```
