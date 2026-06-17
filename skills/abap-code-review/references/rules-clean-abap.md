# Clean ABAP Rules (CLEAN)

Examine code structure, OO design, and syntax modernity.

| Rule ID | What to check | Severity | Notes |
|---------|--------------|----------|-------|
| CLEAN-01 | Any `FORM` or `PERFORM` statement in new code | CRITICAL | |
| CLEAN-02 | `TABLES` statement (obsolete work area declaration) | CRITICAL | |
| CLEAN-03 | `CATCH` block with no statements, or only `RETURN`/`EXIT` with no message or logging | CRITICAL | |
| CLEAN-04 | `MOVE-CORRESPONDING` — replace with `CORRESPONDING #( source MAPPING ... )` | WARNING | |
| CLEAN-05 | Non-constant `CLASS-DATA` (mutable global state) in a class definition | WARNING | |
| CLEAN-06 | Multi-step procedural assignment expressible with `VALUE #(...)`, `NEW #(...)`, `COND #(...)`, or `SWITCH #(...)` | WARNING | |
| CLEAN-08 | Commented-out blocks of production code (lines starting with `*` or `"` that contain ABAP statements, not explanatory prose) | INFO | |
| CLEAN-09 | Assignment between structurally incompatible types without explicit `CONV` or `CAST` | WARNING | |
