# Clean Core

Use this reference when the review touches released API usage, extension boundaries, or upgrade-safe design. This is a cross-cutting concern — apply it alongside other category rules, not as a separate pass.

## Core Principles

- Prefer released APIs, released CDS views, and stable extension points.
- Flag direct use of unreleased or restricted internals when policy or platform rules disallow them.
- Prefer upgrade-safe extension patterns over modifications or tightly coupled internals.

## Rules

| Rule ID | What to check | Severity | Notes |
|---------|--------------|----------|-------|
| CCORE-01 | Direct use of an SAP internal object (class, FM, table) that has no released API equivalent — identifiable by `@ReleaseState: RESTRICTED` or absence of release annotation | WARNING | When released status cannot be confirmed during review, record as a verification gap rather than reporting a finding. |
| CCORE-02 | Direct modification (`ENHANCEMENT`, `BADI` implementation, or include modification) of a standard SAP object instead of using the published extension point | CRITICAL | |
| CCORE-03 | Data access path that bypasses a released CDS view or BAPI and reads an SAP private table directly without explicit project approval | WARNING | |
| CCORE-04 | Tight coupling to SAP implementation details (hard-coded internal keys, undocumented field offsets, private structure fields) that would break on an upgrade | WARNING | |

## Reporting Guidance

When released status cannot be confirmed during review, state that as a verification gap instead of inventing certainty.
