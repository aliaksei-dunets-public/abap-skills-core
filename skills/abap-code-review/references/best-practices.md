# Best Practices

Use these heuristics to prioritize findings by engineering risk, not by style preference.

## Review Order

Always review in this order:

1. correctness and behavioral regressions
2. contract and error-handling integrity
3. Clean Core and released API usage
4. SQL and performance risks
5. naming and maintainability

## Correctness

Flag issues such as:

- missing guards for initial or invalid state
- broken branching that skips required logic
- incorrect defaulting that changes business behavior
- state updates that leave objects inconsistent

## Error Handling

Flag issues such as:

- swallowed exceptions without explicit handling intent
- generic catches that hide root causes
- missing message propagation where consumers depend on it
- success paths that ignore failed outcomes

## Transaction Safety

Flag issues such as:

- implicit commit assumptions
- unsafe update sequences
- mixed read and write behavior that can leave partial state

## SQL And Data Access

Flag issues such as:

- `SELECT *` without a good reason
- missing filters on potentially large reads
- row-by-row database access in loops
- unverified use of non-released access paths when that matters

## Maintainability

Low-severity findings can include unclear names, dense methods, and mixed responsibilities. Do not let these outrank behavioral defects.
