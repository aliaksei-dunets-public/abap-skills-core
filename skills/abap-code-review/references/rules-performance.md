# Performance Rules (PERF)

Examine all database access statements and data processing logic.

| Rule ID | What to check | Severity | Notes |
|---------|--------------|----------|-------|
| PERF-01 | `SELECT *` or `SELECT ... INTO TABLE` without an explicit field list | CRITICAL | |
| PERF-02 | Any `SELECT`, `SELECT SINGLE`, or `OPEN CURSOR` inside a `LOOP AT ... ENDLOOP` block | CRITICAL | In RAP `validate_*` or `determine_*` methods, RAP-01 is the primary finding; still report PERF-02 additionally if the SELECT is also inside a loop. |
| PERF-03 | `FOR ALL ENTRIES IN` not immediately preceded (within ~5 lines) by `IF <table> IS NOT INITIAL` or `CHECK <table> IS NOT INITIAL` | CRITICAL | |
| PERF-04 | Code that sorts or filters data where sort order matters but no `ORDER BY` clause is present on the SELECT | WARNING | |
| PERF-05 | `SORT` or `DELETE ADJACENT DUPLICATES` on large internal tables when an `ORDER BY` in the SQL SELECT or a CDS view could handle this server-side | WARNING | |
| PERF-06 | `BYPASSING BUFFER` used without a comment on the immediately preceding line or as an inline comment on the same line explaining why | WARNING | "Adjacent" means the line directly above the statement, or an inline comment on the same line — a comment elsewhere in the method does not satisfy this rule. |
| PERF-07 | Aggregation (`SUM`, `COUNT`, `MAX`, `MIN`, `AVG`) computed via `LOOP AT` accumulation instead of SQL `GROUP BY` or aggregate functions in the SELECT | WARNING | |
