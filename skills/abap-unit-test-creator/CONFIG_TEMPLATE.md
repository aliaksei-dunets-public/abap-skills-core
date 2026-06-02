# Config Template: abap-unit-test-creator

## Required in `project-config.md`

- Primary namespace (used to infer object names when bare names are provided)
- Platform / environment (S/4HANA On-Premise, ABAP Cloud, etc.)

## Required in `configs/config.md`

- Source retrieval tool to use when user provides an object name (e.g. `abap-reader`)
- Test class prefix (default: `ltc_`)
- Fake/double class prefix (default: `ltd_`)

## Recommended in `configs/`

Create `configs/conventions.md` and link to it from `config.md` when you need to document:
- Approved test frameworks (`cl_abap_testdouble`, `cl_osql_test_environment`, `cl_cds_test_environment`)
- FRIENDS clause policy (allowed / not allowed)
- Test seam policy
- Dependency injection pattern (constructor / setter / factory)
- Test method naming pattern (`method_scenario` vs `when_condition_then_outcome`)
- EML mode preference (`local_mode` vs `standard`)
- Project-wide test data builder or fake registry class (if any)
- Rollback and teardown rules
- Any forbidden patterns (e.g. `COMMIT WORK`, native SQL, real BAPI calls)
