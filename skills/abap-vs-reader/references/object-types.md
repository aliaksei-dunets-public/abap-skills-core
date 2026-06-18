# Object types

## Type table

| Object type | `<TYPE_LABEL>` | `<filename>` suffix |
|---|---|---|
| Class | `Source Code Library/Classes` | `.clas.abap` |
| Interface | `Source Code Library/Interfaces` | `.intf.abap` |
| Behavior Definition | `Source Code Library/Behavior Definitions` | `.bdef.abap` |
| Behavior Implementation (`BP_R_*`) | `Source Code Library/Classes` | `.clas.abap` |
| CDS Data Definition | `Source Code Library/Data Definitions` | `.ddls.asddls` |
| Metadata Extension | `Source Code Library/Metadata Extensions` | `.ddlx.asddlxex` |
| Service Definition | `Source Code Library/Service Definitions` | `.srvd.asrvds` |
| Service Binding | `Source Code Library/Service Bindings` | `.srvb.srvbsvb` |
| Program | `Source Code Library/Programs` | `.prog.abap` |
| Include | `Source Code Library/Includes` | `.prog.abap` |
| Function Module | `Source Code Library/Function Groups/<GROUP>/Function Modules/<NAME>` | `.fugr.func.abap` |
| Database Table | `Data Dictionary/Database Tables` | `.tabl.abap` |
| Structure | `Data Dictionary/Structures` | `.stru.abap` |
| Data Element | `Data Dictionary/Data Elements` | `.dtel.abap` |
| Domain | `Data Dictionary/Domains` | `.doma.abap` |

When in doubt, expand the object node in ADT Project Explorer — the on-screen filename wins.

## Class file selection by `include_type`

| `include_type` | Files to read |
|---|---|
| `all` (default) | `.clas.abap` + every `.clas.<part>.abap` |
| `main` | `.clas.abap` only |
| `definitions` | `.clas.definitions.abap` |
| `implementations` | `.clas.implementations.abap` |
| `testclasses` | `.clas.testclasses.abap` |
| `macros` | `.clas.macros.abap` |
