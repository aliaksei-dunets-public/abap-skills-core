# Best Practices

Use these heuristics to prioritize findings by engineering risk, not by style preference.

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
