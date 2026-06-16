# Object types — virtual URI segments and physical cache subdirs

Authoritative type mapping. Coordinate systems:

- **Virtual URI** (Phase 1, primary): `abap:/repotree-v1/<system>/<root>/<package>/.../<TYPE_LABEL>/<DISPLAY_NAME>/<filename>`. Mirrors package containment.
- **Physical cache** (Phase 2, fallback): `<cache_base>/.adt/<subdir>/<encoded_name>/<file>.<ext>`. Flat layout.

## Casing & encoding rules

- Virtual `<DISPLAY_NAME>`: **uppercase** namespace + name → `(HEC4)CL_FOO`.
- Virtual `<filename>` prefix: **lowercase** display form → `(hec4)cl_foo.clas.abap`.
- Spaces and parens in virtual paths: pass **literally** (no `%20`/`%28`/`%29`). `read_file` URL-encodes internally; pre-encoding produces ENOENT.
- Physical encoded name: strip parens → `/` → lowercase → URL-encode (`/` → `%2f`, `#` → `%23`).

## Type table

| Object type | Virtual `<TYPE_LABEL>` | Virtual filename suffix | Physical `.adt/` subdir | Physical extension(s) |
|---|---|---|---|---|
| Class | `Source Code Library/Classes` | `.clas.abap` | `classlib/classes` | `.aclass` (signature) + `.acinc` (parts) |
| Interface | `Source Code Library/Interfaces` | `.intf.abap` | `classlib/interfaces` | `.aint` |
| Behavior Definition | `Source Code Library/Behavior Definitions` | `.bdef.abap` | `wbobj2/bo/bdef` | `.asbdef` |
| Behavior Implementation (`BP_R_*`) | `Source Code Library/Classes` | `.clas.abap` | `classlib/classes` | `.aclass` + `.acinc` (treated as classes) |
| CDS Data Definition | `Source Code Library/Data Definitions` | `.ddls.asddls` | `ddic/ddlsources` | `.asddls` |
| Metadata Extension | `Source Code Library/Metadata Extensions` | `.ddlx.asddlxex` | `wbobj2/ddic/ddlxex` | `.asddlxex` |
| Service Definition | `Source Code Library/Service Definitions` | `.srvd.asrvds` | `ddic/srvdsources` | `.assrvds` |
| Service Binding | `Source Code Library/Service Bindings` | `.srvb.srvbsvb` | `wbobj/businessservices/bindings` | `.srvbsvb` (XML metadata only) |
| Program | `Source Code Library/Programs` | `.prog.abap` | `programs` | `.prog` |
| Include | `Source Code Library/Includes` | `.prog.abap` | `programs/includes` | `.prog` |
| Function Group | `Source Code Library/Function Groups/<GROUP>` | container | `functions/groups` | `.fugr` |
| Function Module | `…/<GROUP>/Function Modules/<NAME>` | `.fugr.func.abap` | `functions/groups/<group>/modules` | `.fugr.func` |
| Type Group | `Source Code Library/Type Groups` | `.prog.abap` | `programs/typegroups` | `.prog` |
| Message Class | `Source Code Library/Message Classes` | `.prog.msag` | `programs/messageclasses` | `.prog.msag` |
| Database Table | `Data Dictionary/Database Tables` | `.tabl.abap` | `ddic/tables` | `.tabl` |
| Structure | `Data Dictionary/Structures` | `.stru.abap` | `ddic/structures` | `.stru` |
| Data Element | `Data Dictionary/Data Elements` | `.dtel.abap` | `ddic/dataelements` | `.dtel` |
| Domain | `Data Dictionary/Domains` | `.doma.abap` | `ddic/domains` | `.doma` |
| Search Help | `Data Dictionary/Search Helps` | `.shlp.abap` | `ddic/searchhelps` | `.shlp` |
| Lock Object | `Data Dictionary/Lock Objects` | `.enqu.abap` | `ddic/lockobjects` | `.enqu` |
| Table Type | `Data Dictionary/Table Types` | `.ttyp.abap` | `ddic/tabletypes` | `.ttyp` |
| Type Definition (DDIC) | — | — | `ddic/types` | `.type` |
| Authorization Object | — | — | `wbobj/authorizationobjects` | `.auth` |
| Number Range Object | — | — | `wbobj/numberrangeobjects` | `.nrobj` |

> `wbobj` (older repo objects) vs `wbobj2` (newer RAP/CDS artefacts) are not interchangeable.

> Suffixes can shift by SAP_BASIS / ADT extension version. When in doubt, expand the object node in the ADT Project Explorer — the on-screen filename wins.

## Skip list (ADT metadata, not source)

```
.apclass  .apint  .apddls  .apddlxex  .apbdef  .apsrvds
.aptec  .astec  .$$$  .prefs  .project  .properties  .devck
*.texts.*.properties
```

## Class file selection by `include_type`

| `include_type` | Files (physical) | Files (virtual) |
|---|---|---|
| `all` (default) | `.aclass` + every `.acinc` | `.clas.abap` + every `.clas.<part>.abap` |
| `main` | `.aclass` only | `.clas.abap` only |
| `definitions` | `*definitions.acinc` | `.clas.definitions.abap` |
| `implementations` | `*implementations.acinc` | `.clas.implementations.abap` |
| `testclasses` | `*testclasses.acinc` | `.clas.testclasses.abap` |
| `macros` | `*macros.acinc` | `.clas.macros.abap` |
