# URI Patterns for ABAP ADT Objects

Use these patterns to build URIs for `abap_activate_objects` and
`abap_run_unit_tests`. The preferred source for a URI is always the `filePath`
field returned by `abap_creation-create_object` — use these patterns only when
`filePath` is not available.

## Placeholders

| Placeholder | Value |
|---|---|
| `{DEST}` | destination from config, e.g. `ISD_001_C5227045_EN` |
| `{USER}` | SAP username uppercase, e.g. `C5227045` |
| `{NAME_UPPER}` | Object name uppercase, e.g. `ZCL_MY_CLASS` |
| `{name_lower}` | Object name lowercase, e.g. `zcl_my_class` |
| `{PKG_ENC}` | URL-encoded package path segment (see Package Objects section) |

---

## $TMP Local Objects

Base: `abap:/repotree-v1/{DEST}/Local%20Objects%20%28%24TMP%29/{USER}/Source%20Code%20Library`

| Object type | objectType | Append to base | File extension |
|---|---|---|---|
| Class | CLAS/OC | `/Classes/{NAME_UPPER}/{name_lower}.clas.abap` | `.clas.abap` |
| Interface | INTF/OI | `/Interfaces/{NAME_UPPER}/{name_lower}.intf.abap` | `.intf.abap` |
| Data Definition | DDLS/DF | `/Data%20Definitions/{NAME_UPPER}/{name_lower}.ddls.asddls` | `.ddls.asddls` |
| Metadata Extension | DDLX/EX | `/Metadata%20Extensions/{NAME_UPPER}/{name_lower}.ddlx.asddlxex` | `.ddlx.asddlxex` |
| Behavior Definition | BDEF/BDO | `/Behavior%20Definitions/{NAME_UPPER}/{name_lower}.bdef.asbdef` | `.bdef.asbdef` |
| Service Definition | SRVD/SRV | `/Service%20Definitions/{NAME_UPPER}/{name_lower}.srvd.assrvds` | `.srvd.assrvds` |
| Service Binding | SRVB/SVB | `/Service%20Bindings/{NAME_UPPER}/{name_lower}.srvb.srvbsvb` | `.srvb.srvbsvb` |
| Access Control | DCLS/DL | `/Access%20Controls/{NAME_UPPER}/{name_lower}.dcls.asdcls` | `.dcls.asdcls` |

### $TMP Class — Full Example

```
abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap
```

### $TMP Interface — Full Example

```
abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Interfaces/ZIF_MY_INTERFACE/zif_my_interface.intf.abap
```

---

## Package-Based Objects

Base: `abap:/repotree-v1/{DEST}/System%20Library/{PKG_ENC}/Source%20Library/{PKG_ENC}`

`{PKG_ENC}` is the URL-encoded package name. Example for package `ZMYPKG`:
`ZMYPKG` → `ZMYPKG` (no encoding needed for alphanumeric names).

For namespace packages like `(HEC4)PP`:
`(HEC4)PP` → `%28HEC4%29PP`

### Package Object — Full Example (ZMYPKG, class ZCL_MY_CLASS)

```
abap:/repotree-v1/ISD_001_C5227045_EN/System%20Library/ZMYPKG/Source%20Library/ZMYPKG/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap
```

The object type folders and file extensions are the same as for $TMP objects above.

---

## Activation Limit

`abap_activate_objects` accepts a maximum of **15 URIs** per call. If activating
more than 15 objects, split into multiple calls.