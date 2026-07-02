# Object Type Sort Order

Used in Phase 1 (COLLECT) to produce the canonical, deduplicated object list.
Sorting order defines both the display order in Phase 2 (SHOW LIST) and the
read order in Phase 3 (READ SOURCES).

---

## Sort Order

| # | Type Code | Display Name | Virtual URI file extension |
|---|---|---|---|
| 1 | DDLS | CDS View | `.asddls` |
| 2 | DDLX | Metadata Extension | `.asddlxex` |
| 3 | BDEF | Behavior Definition | `.asbdef` |
| 4 | SRVD | Service Definition | `.assrvds` |
| 5 | SRVB | Service Binding | XML only — no source read |
| 6 | INTF | Interface | `.intf.abap` |
| 7 | CLAS | Class | `.clas.abap` (+ sibling includes) |
| 8 | TABL | Database Table | `.tabl` |
| 9 | STRU | Structure | `.stru` |
| 10 | AUTH | Authorization Object | `.auth` |
| 11 | ENQU | Lock Object | `.enqu` |
| 12 | DTEL | Data Element | `.dtel` |
| 13 | DOMA | Domain | `.doma` |
| 14 | MSAG | Message Class | `.prog.msag` |
| 15 | OTHER | Any other type | — |

---

## Deduplication Rule

When the same object appears in multiple sources (e.g. both in package and TR), keep one entry and record all sources in the `source` field, comma-separated.

---

## Notes

- Behavior pool classes (`BP_R_*`, `BP_C_*`) are type CLAS.
- Service Binding (SRVB) has no readable ABAP source — XML metadata only. List in artifacts table but do not attempt source read.
- See `abap-vs-reader` SKILL.md for virtual URI construction details.
