# Quick recipes (PowerShell)

Copy-pasteable snippets for common ad-hoc needs against the physical cache.

## List all objects of a given type

```powershell
Get-ChildItem -LiteralPath "<cache_base>/.adt/<subdir>" -Directory |
  Select-Object @{N='Decoded';E={ [System.Web.HttpUtility]::UrlDecode($_.Name).ToUpper() }}
```

## Find every object whose name contains a substring (any type)

```powershell
$subdirs = @(
  'classlib/classes', 'classlib/interfaces',
  'ddic/ddlsources', 'ddic/tables', 'ddic/structures',
  'wbobj2/bo/bdef', 'ddic/srvdsources', 'programs'
)
foreach ($s in $subdirs) {
  Get-ChildItem -LiteralPath "<cache_base>/.adt/$s" -Directory `
    -Filter "*<partial>*" -EA SilentlyContinue |
    ForEach-Object { "$s : $($_.Name)" }
}
```

## Grep across a whole class (signature + all includes)

```powershell
Get-ChildItem -LiteralPath "<object_cache_dir>" -Include *.aclass,*.acinc -File |
  Select-String -Pattern '<regex>'
```

## Confirm the cache is alive after activation

```powershell
$dir = "<object_cache_dir>"
if (Test-Path $dir) {
  Get-ChildItem -LiteralPath $dir |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 Name, Length, LastWriteTime
}
```

If the most recent `LastWriteTime` is older than the user's last activation,
re-trigger the auto-open loop.
