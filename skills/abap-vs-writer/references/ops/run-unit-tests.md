# Operation: Run ABAP Unit Tests

Runs ABAP Unit Tests for one or more objects. The tool auto-discovers the test
class include — always pass the main `.clas.abap` URI, not the testclass file.

---

## Get the URI

Same priority as activate: use `filePath` from create response, or build from
`references/uri-patterns.md`.

Always use the **main class URI** ending in `.clas.abap` — the tool finds the
`testclasses.acinc` automatically.

---

## Call

`abap_run_unit_tests`:

```
uris: ["{uri_to_main_clas_abap}"]
```

---

## Response Handling

**Tests pass:** output contains test method names with status PASS. Report summary.

**Tests fail:** output contains failure details (method name, assertion message,
expected vs actual). Report the full output verbatim — do not summarise failures.

**No tests found:** output is "No tests found" or similar. Inform the user that
the class has no test class include yet.

---

## Example

Run tests for `ZCL_MY_CLASS` in `$TMP`:

```
uris: ["abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap"]
```
