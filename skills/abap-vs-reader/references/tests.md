# Tests

Self-contained suite under `scripts/tests/` validating the input contract of
`open-abap.ps1`. Zero dependencies — no Pester required.

## Layout

```
scripts/
  open-abap.ps1
  tests/
    Invoke-Tests.ps1        # discovery + runner
    open-abap.Tests.ps1     # tests for open-abap.ps1
```

## Run the suite

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "<skills_root>/abap-vs-reader/scripts/tests/Invoke-Tests.ps1"
```

Optional `-Filter '<wildcard>'` to run a subset.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | All tests passed |
| `1` | At least one test failed |
| `2` | Runner failure (no `*.Tests.ps1` files found) |

## When to run

- After editing `open-abap.ps1` — failure-detection substrings in
  `cache-fallback.md` (Step F6) must stay green.
- Before committing changes to the core repository.
- As part of `abap-skill-manager validate` (auto-runs `Invoke-Tests.ps1` for every skill).

## Adding more tests

Drop a new `*.Tests.ps1` file alongside `Invoke-Tests.ps1`. DSL:

```powershell
Test 'short description of the case' {
    Assert-Equal 'expected' 'actual'
    Assert-True  ($x -gt 0)
    Assert-Match 'pattern' $someText
    Assert-NotMatch 'forbidden' $someText
    Assert-Throws { Bad-Call }
}
```

Each `Test` block runs independently — a failure in one does not abort the rest.
