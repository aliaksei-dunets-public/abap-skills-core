# Object Type Sort Order

Used in Phase 1 (COLLECT) to produce the canonical, deduplicated object list.
Sorting order defines both the display order in Phase 2 (SHOW LIST) and the
read order in Phase 3 (READ SOURCES).

---

## Sort Order

| # | Type Code | Display Name | ADT subdir | Source extension |
|---|---|---|---|---|
| 1 | DDLS | CDS View | `ddic/ddlsources` | `.asddls` |
| 2 | DDLX | Metadata Extension | `wbobj2/ddic/ddlxex` | `.asddlxex` |
| 3 | BDEF | Behavior Definition | `wbobj2/bo/bdef` | `.asbdef` |
| 4 | SRVD | Service Definition | `ddic/srvdsources` | `.assrvds` |
| 5 | SRVB | Service Binding | `wbobj/businessservices/bindings` | `.srvbsvb` (XML only) |
| 6 | INTF | Interface | `classlib/interfaces` | `.aint` |
| 7 | CLAS | Class | `classlib/classes` | `.aclass` + `.acinc` |
| 8 | TABL | Database Table | `ddic/tables` | `.tabl` |
| 9 | DTEL | Data Element | `ddic/dataelements` | `.dtel` |
| 10 | DOMA | Domain | `ddic/domains` | `.doma` |
| 11 | MSAG | Message Class | `programs/messageclasses` | `.prog.msag` |
| 12 | OTHER | Any other type | — | — |

---

## Deduplication Rule

When the same object appears in multiple sources (e.g. both in package and TR), keep one entry and record all sources in the `source` field, comma-separated.

---

## Notes

- Behavior pool classes (`BP_R_*`, `BP_C_*`) are type CLAS and live in `classlib/classes`.
- Service Binding (SRVB) has no readable ABAP source — XML metadata only. List in artifacts table but do not attempt source read.
- Read `abap-vs-reader` SKILL.md for full cache path construction and virtual URI details.
