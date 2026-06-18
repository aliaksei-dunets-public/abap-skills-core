# Best Practices

Use this file as the risk lens for the architecture-first pass. Prioritize engineering and business risk over style preference.

## Review Questions

Answer these before you rely on rule findings:

- What is this object or change trying to do?
- Which control flow and data flow paths matter most?
- Which related objects define the contract or expected behavior?
- Which tests, if any, protect the changed behavior?

If you cannot answer a question from the available artifacts, record a verification gap.

## Correctness

Look for defects such as:

- Missing guards for initial, invalid, or unexpected state.
- Broken branching that skips required behavior.
- Incorrect defaulting that changes business meaning.
- State updates that leave objects inconsistent.
- Contract mismatches between caller and callee, CDS and behavior, or interface and implementation.

## Edge Cases And Error Handling

Look for risks such as:

- Swallowed exceptions without explicit intent.
- Generic catches that hide root causes.
- Missing error propagation or message mapping.
- Success paths that ignore failed outcomes.
- Missing handling for empty selections, duplicate input, partial updates, or failed dependent operations.

## Architecture And Consistency

Look for risks such as:

- Duplicate logic across methods, classes, or related artifacts.
- Cross-object behavior that encodes conflicting assumptions.
- Dense methods or mixed responsibilities that obscure intent.
- Code that works locally but breaks the overall business flow.

Report a confirmed finding only when the defect is supported by code and context. Otherwise, raise an architectural suspicion only when the signal is strong enough to help the next investigation.

## Dead, Obsolete, Or Unused Code

Look for:

- Branches that can no longer be reached.
- Compatibility code that no longer matches current flows.
- Unused helpers, wrappers, or interfaces when surrounding references suggest they are stale.

Do not guess. If unused status depends on repository-wide evidence you do not have, write an architectural suspicion or verification gap instead of a defect.

## SQL, Performance, And Transaction Safety

Look for risks such as:

- `SELECT *` without a reason.
- Missing filters on potentially large reads.
- Row-by-row database access in loops.
- Unsafe update sequences or implicit commit assumptions.
- Mixed read and write behavior that can leave partial state.

## Testability And Suggested Tests

Inspect existing tests when changed logic should be covered. Look for:

- no test coverage for changed logic
- missing negative-path or edge-case coverage
- tests that assert implementation detail instead of business outcome
- gaps where a regression could slip through despite green preflight checks

When `TESTSUG` is active, suggest only high-value tests that would reduce uncertainty or protect a meaningful risk.
