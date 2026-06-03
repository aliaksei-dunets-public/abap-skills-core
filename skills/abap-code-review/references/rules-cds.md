# CDS Architecture Rules (CDS)

Check CDS view structure, annotations, and layering.

| Rule ID | What to check | Severity | Notes |
|---------|--------------|----------|-------|
| CDS-01 | Explicit `where mandt = ...` or `where mandt = $session.client` when the entity is already client-dependent via `@ClientHandling.algorithm: #SESSION_VARIABLE` or inherits client dependency from a base view | WARNING | Verify the entity's `@ClientHandling` annotation before reporting. If the annotation is absent or unclear, record as a verification gap rather than flagging a false WARNING. |
| CDS-02 | `@UI.*` annotations present in an Interface View instead of a Metadata Extension | WARNING | |
| CDS-03 | `inner join` or `left outer join` for a navigation path that is optional and accessed rarely — a CDS association would be more appropriate | WARNING | |
| CDS-04 | Association declared with cardinality `[1..1]` but the ON condition can result in 0 matching rows (no guaranteed FK constraint) | WARNING | |
| CDS-05 | Projection View with a `from` clause pointing directly to a DB table instead of an Interface View — violates CDS layering | CRITICAL | May co-occur with RAP-06 when the entity is also service-exposed without a BDEF. Report both if applicable — they describe different problems (layering vs. missing contract). |
| CDS-06 | `@OData.publish` annotation in a CDS view — service must be activated via admin transaction, not locally in ADT | WARNING | |
