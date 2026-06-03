# Testability Rules (TEST)

Check unit test presence, structure, and isolation quality.

| Rule ID | What to check | Severity |
|---------|--------------|----------|
| TEST-01 | Global class with business logic (validations, calculations, data transformations) but no `CLASS ... FOR TESTING` companion class in the test include | INFO |
| TEST-02 | Inside a `FOR TESTING` class: direct `SELECT` from DB tables, or direct FM/BAPI calls without `CL_ABAP_TESTDOUBLE` or `CL_OSQL_TEST_ENVIRONMENT` | INFO |
| TEST-03 | Test method reads `SY-UNAME`, `SY-DATUM`, `SY-UZEIT`, or similar system fields directly — these must be injected or mocked for deterministic tests | INFO |
| TEST-04 | Method with `IF`/`CASE`/`WHEN` branching logic that has no corresponding test method exercising each branch | INFO |
| TEST-05 | Production business logic placed inside a `FOR TESTING` class | INFO |
