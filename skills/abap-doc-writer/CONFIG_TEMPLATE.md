# Config Template: abap-doc-writer

## Required in `project-config.md`

- Primary namespace (used to infer object names when bare names are provided)

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
