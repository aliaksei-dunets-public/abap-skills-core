# ABAP Object Types — Schema Reference

Use this file to build `objectContent` for `abap_creation-run_validation` and
`abap_creation-create_object`. Do NOT call `abap_creation-get_object_type_details`
at runtime — all schemas are here.

## Critical Rule

`objectContent` MUST be a JSON-encoded string (not a raw object):

```
objectContent: "{\"packageName\":\"$TMP\",\"name\":\"ZCL_MY_CLASS\",\"description\":\"My class\"}"
```

Passing individual fields (name=, description=) fails with "Enter valid object properties."

---

## Object Type Table

| Display Name | objectType | name maxLength | Required fields | Optional fields |
|---|---|---|---|---|
| ABAP Class | `CLAS/OC` | 30 | packageName, name, description | superclass, interfaces |
| ABAP Interface | `INTF/OI` | 30 | packageName, name, description | interfaces |
| Behavior Definition | `BDEF/BDO` | 30 | packageName, rootEntity, name, description | implementationType |
| Access Control | `DCLS/DL` | 30 | packageName, name, description | protectedEntity |
| Data Definition | `DDLS/DF` | 30 | packageName, name, description | referencedObject |
| Metadata Extension | `DDLX/EX` | **40** | packageName, name, description | extendedEntity |
| CDS Aspect | `DRAS/RAS` | 30 | packageName, name, description | — |
| CDS Type | `DRTY/STY` | 30 | packageName, name, description | — |
| Service Binding | `SRVB/SVB` | 30 | packageName, name, description, serviceDefinition | bindingType |
| Service Definition | `SRVD/SRV` | 30 | packageName, name, description | sourceType, referencedObject |
| Change Document Object | `CHDO/CHD` | **15** | packageName, name, description | — |
| SAP Object Node Type | `NONT/NOT` | 30 | packageName, name, description, sapObjectType | isRootNode |
| Number Range Object | `NROB/NRO` | **10** | packageName, name, description | — |
| SAP Object Type | `RONT/ROT` | 30 | packageName, name, description | typeCategory |

**Non-standard name lengths (exceptions to default 30):**
- `DDLX/EX` → max **40**
- `CHDO/CHD` → max **15**
- `NROB/NRO` → max **10**

---

## Optional Field Enum Values

### BDEF/BDO — implementationType
`Managed` | `Unmanaged` | `Projection` | `Abstract` | `Interface`

### SRVB/SVB — bindingType
`OData V2 - UI` | `OData V4 - UI`

### SRVD/SRV — sourceType
`S` (Service Definition) | `X` (External) | *(empty string for default)*

### RONT/ROT — typeCategory
`Business Object` | `Technical Object` | `Analytical Object` |
`Configuration Object` | `Dependent Object` | `Hierarchy Object`

---

## objectContent Examples

**ABAP Class in $TMP:**
```json
{"packageName":"$TMP","name":"ZCL_MY_CLASS","description":"My class description"}
```

**ABAP Interface in $TMP:**
```json
{"packageName":"$TMP","name":"ZIF_MY_INTERFACE","description":"My interface"}
```

**CDS Data Definition in $TMP:**
```json
{"packageName":"$TMP","name":"ZI_MY_VIEW","description":"My CDS view"}
```

**Behavior Definition in $TMP:**
```json
{"packageName":"$TMP","name":"ZI_MY_VIEW","description":"Behavior for ZI_MY_VIEW","rootEntity":"ZI_MY_VIEW","implementationType":"Managed"}
```

**Service Binding in $TMP:**
```json
{"packageName":"$TMP","name":"ZUI_MY_SRV_O4","description":"OData V4 UI Service","serviceDefinition":"ZSD_MY_SRV","bindingType":"OData V4 - UI"}
```
---
