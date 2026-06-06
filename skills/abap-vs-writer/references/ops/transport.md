# Operation: Transport Requests

Manage transport requests for ABAP objects in non-local packages.

**$TMP rule:** Objects in `$TMP` never need a transport. Skip this entire file
and use `transportRequestNumber = ""`.

---

## Get existing TRs

Before creating or modifying any non-$TMP object, call `abap_transport-get`:

```
destination:        {destination from config}
objectName:         {object name uppercase, e.g. "ZCL_MY_CLASS"}
objectType:         {objectType, e.g. "CLAS/OC"}
developmentPackage: {package name, e.g. "ZMYPKG"}
isCreation:         true   (for new objects) | false (for modifications)
```

**Show the full list of returned TRs to the user.** Wait for explicit selection.
Never auto-select a TR number.

If `isRecordingRequired` is `false` in the response, transport is optional —
inform the user and ask whether to assign one.

---

## Create a new TR

Only call `abap_transport-create` if the user explicitly asks to create a new
transport request:

```
destination:          {destination from config}
objectName:           {object name uppercase}
objectType:           {objectType}
developmentPackage:   {package name}
transportDescription: {short description, max 60 chars, like a commit message}
isCreation:           true | false
```

Report the new TR number to the user. Then use it as `transportRequestNumber`
in `create_object`.

---

## TR for RAP Generator

When generating RAP objects in a non-$TMP package, call `abap_transport-get`
with:
```
objectType:         "DEVC/K"
objectName:         {package name}
developmentPackage: {package name}
isCreation:         true
```

---

## Safety Rules

1. Never call `abap_transport-create` without user request
2. Never auto-select from the TR list — always wait for user choice
3. Never skip transport for non-$TMP packages unless `isRecordingRequired` is `false`
   and the user confirms they want to proceed without a TR
