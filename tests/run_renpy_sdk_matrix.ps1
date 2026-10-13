$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot 'UnRen-DDAC-v145-python.py'
$version = $env:RENPY_VERSION
$baseUrl = $env:RENPY_DOWNLOAD_BASE
if ([string]::IsNullOrWhiteSpace($version) -or [string]::IsNullOrWhiteSpace($baseUrl)) {
    throw 'RENPY_VERSION and RENPY_DOWNLOAD_BASE must be provided by the workflow matrix.'
}
$archiveName = "renpy-$version-sdk.zip"
$work = Join-Path $env:RUNNER_TEMP ("ddac-renpy-sdk-" + $version)
$download = Join-Path $work $archiveName
$extract = Join-Path $work 'sdk'
$fixture = Join-Path $work 'fixture'
$results = Join-Path $repoRoot 'test-results'
New-Item -ItemType Directory -Force -Path $work, $extract, $results | Out-Null
$env:LOCALAPPDATA = Join-Path $work 'localappdata'
New-Item -ItemType Directory -Force -Path $env:LOCALAPPDATA | Out-Null

Write-Host "== Ren'Py SDK oracle test: $version =="
$checksumsUrl = "$baseUrl/checksums.txt"
$archiveUrl = "$baseUrl/$archiveName"
$checksumsPath = Join-Path $work 'checksums.txt'
Invoke-WebRequest -Uri $checksumsUrl -OutFile $checksumsPath
$checksumLines = Get-Content -LiteralPath $checksumsPath
$shaIndex = [Array]::IndexOf($checksumLines, '# sha256')
if ($shaIndex -lt 0) { throw "Official checksum file has no SHA-256 section: $checksumsUrl" }
$expectedHash = $null
for ($i = $shaIndex + 1; $i -lt $checksumLines.Count; $i++) {
    $line = $checksumLines[$i]
    if ($line -match '^# ' -or $line -match '^-----BEGIN PGP SIGNATURE-----') { break }
    if ($line -match ('^([0-9a-fA-F]{64})\s+' + [regex]::Escape($archiveName) + '\s*$')) {
        $expectedHash = $Matches[1].ToLowerInvariant()
        break
    }
}
if ([string]::IsNullOrWhiteSpace($expectedHash)) { throw "Official SHA-256 for $archiveName not found in $checksumsUrl" }
Invoke-WebRequest -Uri $archiveUrl -OutFile $download
$actualHash = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) { throw "SDK SHA-256 mismatch for $version. Expected $expectedHash, got $actualHash" }
Write-Host "SDK SHA-256 verified: $actualHash"
Expand-Archive -LiteralPath $download -DestinationPath $extract -Force
$sdkScript = Get-ChildItem -LiteralPath $extract -Filter 'renpy.py' -File -Recurse | Select-Object -First 1
if ($null -eq $sdkScript) { throw "renpy.py not found after extracting SDK $version" }
$sdkRoot = $sdkScript.Directory.FullName
Write-Host "SDK root: $sdkRoot"

$game = Join-Path $fixture 'game'
New-Item -ItemType Directory -Force -Path $game | Out-Null
$scriptText = @'
define e = Character("Emily")
label start:
    e "Hello, Ren'Py oracle!"
    "A plain narration line."
    menu:
        "Choose an option"
        "First choice":
            $ selected = "first"
        "Second choice":
            $ selected = "second"
'@
$screensText = @'
screen qa_screen():
    textbutton "Save" action ShowMenu("save")
    textbutton "Settings" action ShowMenu("preferences")
'@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $game 'script.rpy'), $scriptText, $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $game 'screens.rpy'), $screensText, $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $game 'options.rpy'), "init python:`r`n    config.debug_sound = False`r`n", $utf8NoBom)

$env:DDAC_RENPY_SDK = $sdkRoot
$python = (Get-Command python -ErrorAction Stop).Source
$log = Join-Path $results ("renpy-sdk-" + $version + '.log')
Push-Location $repoRoot
try {
    & $python $source 'extrair' $fixture '1' *> $log
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
if ($exitCode -ne 0) { throw "DDAC extraction failed under SDK $version (exit $exitCode); inspect $log" }
$reportPath = Join-Path $fixture 'DDAC-Dual-Relatorio.json'
if (-not (Test-Path -LiteralPath $reportPath)) { throw "DDAC report missing for SDK $version; inspect $log" }
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if (-not $report.oraculo_renpy_ativo) {
    $status = $report.validacao_renpy
    $detail = $report.oraculo_renpy | ConvertTo-Json -Depth 8
    throw "Oracle did not activate for Ren'Py $version. status=$status; oracle=$detail; inspect $log"
}
if ($report.terminal_status -ne 'EXTRACAO_CONCLUIDA') {
    throw "Unexpected terminal status for Ren'Py ${version}: $($report.terminal_status)"
}
Write-Host "PASS: Ren'Py $version oracle activated; native candidates=$($report.candidatos_renpy), canonical entries=$($report.canonicos)"
$summaryPath = Join-Path $results ("renpy-sdk-" + $version + '-summary.txt')
$summary = @"
Ren'Py SDK compatibility test: $version
SDK root: $sdkRoot
SDK URL: $archiveUrl
SDK SHA-256 verified: $actualHash
Oracle active: $($report.oraculo_renpy_ativo)
Terminal status: $($report.terminal_status)
Native candidates: $($report.candidatos_renpy)
Canonical entries: $($report.canonicos)
Log: $log
"@
[IO.File]::WriteAllText($summaryPath, $summary, $utf8NoBom)