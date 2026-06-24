# Config Template: abap-doc-writer

## Optional in `project-config.md`

- Primary namespace — when provided, used to expand bare object names (e.g. `CL_UPLD` → `/HEC4/CL_UPLD`) in Phase 2

## Optional in `configs/config.md`

```yaml
# Language for generated doc descriptions (ISO 639-1 code, e.g. EN, DE)
doc_language: EN

# Max characters per "! line before word-wrapping
line_wrap: 90

# Document private methods (true = all visibility sections; false = public + protected only)
document_private: true

# Generate <p class="shorttext synchronized" lang="..."> as first line of new doc blocks
shorttext_synchronized: false
```
