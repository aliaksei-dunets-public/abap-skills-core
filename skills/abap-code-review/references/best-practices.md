# Best Practices

Use these heuristics to prioritize findings by engineering risk, not by style preference.

## Review Category Order

Always apply and report findings in this order — it matches the SKILL.md phase structure:

1. **Performance** (PERF) — database access patterns, loop safety, aggregation
2. **Clean ABAP** (CLEAN) — code structure, OO design, syntax modernity
3. **Naming** (NAME) — identifiers, object names, parameter prefixes
4. **RAP Correctness** (RAP) — behavior contract, EML, authorization
5. **CDS Architecture** (CDS) — layering, annotations, associations
6. **Clean Core** (CCORE) — released API usage, extension boundaries, upgrade safety
7. **Testability** (TEST) — test presence, isolation, coverage
8. **Documentation** (DOC) — ABAP Docs, KT references

This order reflects descending risk to runtime behavior. Style and documentation findings must never outrank behavioral or contract defects in the findings table.

## Correctness

Flag issues such as:

- Missing guards for initial or invalid state.
- Broken branching that skips required logic.
- Incorrect defaulting that changes business behavior.
- State updates that leave objects inconsistent.

## Error Handling

Flag issues such as:

- Swallowed exceptions without explicit handling intent.
- Generic catches that hide root causes.
- Missing message propagation where consumers depend on it.
- Success paths that ignore failed outcomes.

## Transaction Safety

Flag issues such as:

- Implicit commit assumptions.
- Unsafe update sequences.
- Mixed read and write behavior that can leave partial state.

## SQL and Data Access

Flag issues such as:

- `SELECT *` without a good reason.
- Missing filters on potentially large reads.
- Row-by-row database access in loops.
- Unverified use of non-released access paths when that matters.

## Maintainability

Low-severity findings can include unclear names, dense methods, and mixed responsibilities. Do not let these outrank behavioral defects.
