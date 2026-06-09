<#
.SYNOPSIS
    Minimal, dependency-free test runner for the abap-vs-reader scripts.

.DESCRIPTION
    Discovers all *.Tests.ps1 files in the same directory and executes their
    test cases. Works on Windows PowerShell 5.1 and PowerShell 7+ without
    requiring Pester to be installed.

    Test files declare cases with the helper `Test "name" { ... }` which is
    defined in this runner. Each test block runs in isolation; an uncaught
    exception inside a block is recorded as a failure but does not abort the
    rest of the suite.

    Exit codes:
      0 -- all tests passed
      1 -- at least one test failed
      2 -- runner itself failed (no test files found, etc.)

.PARAMETER Path
    Directory to search for *.Tests.ps1 files. Defaults to the directory
    containing this script.

.PARAMETER Filter
    Optional wildcard filter applied to test names. Only matching tests run.

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Tests.ps1

.EXAMPLE
    .\Invoke-Tests.ps1 -Filter '*display-form*'
#>
[CmdletBinding()]
param(
    [string]$Path,
    [string]$Filter = '*'
)

if (-not $Path) {
    $Path = Split-Path -Parent $MyInvocation.MyCommand.Path
}

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "Test directory not found: $Path"
    exit 2
}

# ---------------------------------------------------------------------------
# Test DSL -- all helpers below are dot-sourced into each test file scope.
# ---------------------------------------------------------------------------

# Per-suite state. Re-initialised in Invoke-TestSuite below.
$script:__Tests = [System.Collections.ArrayList]::new()

function Test {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)] [string]$Name,
        [Parameter(Mandatory = $true, Position = 1)] [scriptblock]$Body
    )
    [void]$script:__Tests.Add([pscustomobject]@{
        Name = $Name
        Body = $Body
    })
}

function Assert-True {
    param([bool]$Condition, [string]$Message = 'Expected condition to be true.')
    if (-not $Condition) { throw "Assert-True failed: $Message" }
}

function Assert-False {
    param([bool]$Condition, [string]$Message = 'Expected condition to be false.')
    if ($Condition) { throw "Assert-False failed: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        $detail = if ($Message) { " ($Message)" } else { '' }
        throw "Assert-Equal failed$detail. Expected: <$Expected> Actual: <$Actual>"
    }
}

function Assert-Match {
    param([string]$Pattern, [string]$Actual, [string]$Message)
    if ($Actual -notmatch $Pattern) {
        $detail = if ($Message) { " ($Message)" } else { '' }
        throw "Assert-Match failed$detail. Pattern: <$Pattern> Actual: <$Actual>"
    }
}

function Assert-NotMatch {
    param([string]$Pattern, [string]$Actual, [string]$Message)
    if ($Actual -match $Pattern) {
        $detail = if ($Message) { " ($Message)" } else { '' }
        throw "Assert-NotMatch failed$detail. Pattern: <$Pattern> matched: <$Actual>"
    }
}

function Assert-Throws {
    param(
        [Parameter(Mandatory = $true)] [scriptblock]$Action,
        [string]$ExpectedMessagePattern
    )
    $threw = $false
    $msg = $null
    try { & $Action } catch {
        $threw = $true
        $msg = $_.Exception.Message
    }
    if (-not $threw) { throw 'Assert-Throws failed: action did not throw.' }
    if ($ExpectedMessagePattern -and ($msg -notmatch $ExpectedMessagePattern)) {
        throw "Assert-Throws failed: message <$msg> did not match pattern <$ExpectedMessagePattern>."
    }
}

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

function Invoke-TestSuite {
    param([string]$File, [string]$Filter)

    $script:__Tests = [System.Collections.ArrayList]::new()
    Write-Host ''
    Write-Host "=== $([System.IO.Path]::GetFileName($File)) ===" -ForegroundColor Cyan

    try {
        . $File
    } catch {
        Write-Host ("  [LOAD ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
        return [pscustomobject]@{
            File   = $File
            Total  = 0
            Passed = 0
            Failed = 1
            Errors = @($_.Exception.Message)
        }
    }

    $passed = 0
    $failed = 0
    $errors = [System.Collections.ArrayList]::new()

    foreach ($t in $script:__Tests) {
        if ($t.Name -notlike $Filter) { continue }
        try {
            & $t.Body
            $passed++
            Write-Host ("  [PASS] {0}" -f $t.Name) -ForegroundColor Green
        } catch {
            $failed++
            $msg = $_.Exception.Message
            [void]$errors.Add(("[{0}] {1}" -f $t.Name, $msg))
            Write-Host ("  [FAIL] {0}" -f $t.Name) -ForegroundColor Red
            Write-Host ("         {0}" -f $msg) -ForegroundColor Red
        }
    }

    return [pscustomobject]@{
        File   = $File
        Total  = $passed + $failed
        Passed = $passed
        Failed = $failed
        Errors = $errors
    }
}

$testFiles = Get-ChildItem -LiteralPath $Path -Filter '*.Tests.ps1' -File
if ($testFiles.Count -eq 0) {
    Write-Error "No test files (*.Tests.ps1) found in: $Path"
    exit 2
}

$results = foreach ($file in $testFiles) {
    Invoke-TestSuite -File $file.FullName -Filter $Filter
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

$totalPassed = ($results | Measure-Object -Property Passed -Sum).Sum
$totalFailed = ($results | Measure-Object -Property Failed -Sum).Sum
$totalRun    = ($results | Measure-Object -Property Total  -Sum).Sum

Write-Host ''
Write-Host '======================================================'
if ($totalFailed -eq 0) {
    Write-Host ("RESULT: PASS  ({0} test(s))" -f $totalRun) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("RESULT: FAIL  ({0}/{1} failed)" -f $totalFailed, $totalRun) -ForegroundColor Red
    foreach ($r in $results) {
        if ($r.Failed -gt 0) {
            foreach ($err in $r.Errors) {
                Write-Host ("  - {0}" -f $err) -ForegroundColor Red
            }
        }
    }
    exit 1
}
