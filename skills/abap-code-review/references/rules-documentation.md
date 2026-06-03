# Documentation Rules (DOC)

Check ABAP Docs and Knowledge Transfer document completeness.

| Rule ID | What to check | Severity |
|---------|--------------|----------|
| DOC-01 | Interface or global class with public methods that have no `"!` ABAP Doc comment above them | INFO |
| DOC-02 | Interface method parameters (`IMPORTING`, `EXPORTING`, `RETURNING`) not individually documented with `"! @parameter <name>` ABAP Doc tags | INFO |
| DOC-03 | Behavior Definition object in review set but no reference to a KT (Knowledge Transfer) document in any accompanying comment or conversation context | INFO |
| DOC-04 | Non-standard RAP Action (any `action` in BDEF that is not `create`, `update`, `delete`, `edit`, `activate`, `discard`, `resume`) without a comment indicating where the KT document entry is | INFO |
| DOC-05 | Object with `obsolete`, `old`, `deprecated`, `unused`, `todo remove`, or `to be deleted` in its name or a leading comment, but not assigned to the project obsolete package (`obsolete_package` from config) | INFO |
