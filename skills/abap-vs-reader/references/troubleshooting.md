# Troubleshooting

## Known issues (apply workaround, do not chase)

| Issue | Workaround |
|---|---|
| `open-abap.ps1` does nothing from the **VS Code integrated terminal** (focus stays on the terminal pane → `Ctrl+Shift+A` consumed by the terminal) | Run from an external PowerShell window, or ask the user to single-click the object in the ADT Project Explorer. Do not chain unattended from inside the integrated terminal. |
| `run_vscode_command abap.open.object` / `abap.openObject` return Failed | Command IDs are not exposed by ADT contributions. Use `open-abap.ps1` only. |
| Physical cache file is **0 bytes** right after Open Object | ADT writes metadata first, fetches body asynchronously. Trigger a `read_file` against the **virtual** `abap:` URI to populate the body, then re-read from cache if needed. |
| `read_file` against a virtual `abap:` URI works even though the object was never opened | Intended (pull-through fetch). This is why Phase 1 is primary. |
| `file_search` cannot find ABAP source by user-friendly filename | Cache uses URL-encoded names + non-standard extensions. Use `Get-ChildItem -Filter` against `<cache_base>/.adt/<subdir>/`. |

## Symptom table

| Symptom | Likely cause | Fix |
|---|---|---|
| Virtual `read_file` ENOENT but object exists in system | Sub-package chain in URI is wrong | SKILL Step 1.4 |
| Virtual read returns empty | Cache eviction race | Retry once after 2 s; still empty → Phase 2 |
| Virtual read returns HTTP/network error | ADT extension disconnected | Ask user to reconnect; do not fall back |
| `Test-Path` MISSING for an object that exists in system | Object never opened in this session | Auto-open loop (cache-fallback F5) or ask user to click the object |
| Cache directory exists but empty | ADT fetch was interrupted | Re-trigger auto-open; if still empty after 2 attempts → restart ADT extension |
| `cache_base` validation fails | New `workspaceStorage` was created | Recovery search in cache-fallback F1 |
| Read returns ADT metadata XML, not source | A `.ap*` / `.$$$` / `.devck` file was selected | Re-apply skip list (object-types.md) |
| Two different objects map to the same physical path | `system_id` mismatch | Re-check it matches the segment after `/repotree-v1/` |
| Just-activated object not visible | Activation does not auto-cache; only opening does | Always run auto-open loop after activation |
| Class implementation reads slow | Whole `.acinc` instead of line ranges | Read `.aclass` first; then read only relevant method ranges |
| Service binding has no readable source | SRVB stores XML metadata only | Read the linked Service Definition (`.assrvds`) |
