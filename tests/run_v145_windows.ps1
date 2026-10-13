$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$results = Join-Path $repoRoot 'test-results'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$source = Join-Path $repoRoot 'UnRen-DDAC-v145-python.py'
$bat = Join-Path $repoRoot 'UnRen-DDAC-v145.bat'
$python = (Get-Command python -ErrorAction Stop).Source
# Keep the BAT's runtime cache and terms marker isolated to this CI run.
$env:LOCALAPPDATA = Join-Path $env:RUNNER_TEMP 'ddac-v145-localappdata'
New-Item -ItemType Directory -Force -Path $env:LOCALAPPDATA | Out-Null

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
}

function Invoke-ProcessWithInput([string]$exe, [string[]]$arguments, [string]$inputText, [string]$logPath, [string]$workingDirectory, [int]$timeoutSeconds = 900) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = ($arguments | ForEach-Object { '"' + ($_ -replace '"','\"') + '"' }) -join ' '
    $psi.WorkingDirectory = $workingDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $p.StandardInput.Write($inputText)
    $p.StandardInput.Close()
    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($timeoutSeconds * 1000)) {
        try { $p.Kill() } catch {}
        throw "Timeout ($timeoutSeconds s): $exe $($psi.Arguments)"
    }
    $outText = $stdoutTask.Result
    $errText = $stderrTask.Result
    [IO.File]::WriteAllText($logPath, ($outText + "`r`n--- STDERR ---`r`n" + $errText), (New-Object System.Text.UTF8Encoding($false)))
    return [pscustomobject]@{ ExitCode = $p.ExitCode; Output = $outText; Error = $errText }
}

function Invoke-BatchWithInput([string]$inputText, [string]$logPath, [string]$workingDirectory, [int]$timeoutSeconds = 900) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec
    # The batch filename is deliberately simple and the working directory isolates the fixture.
    $psi.Arguments = '/d /s /c "call UnRen-DDAC-v145.bat"'
    $psi.WorkingDirectory = $workingDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()
    $p.StandardInput.Write($inputText)
    $p.StandardInput.Close()
    if (-not $p.WaitForExit($timeoutSeconds * 1000)) {
        try { $p.Kill() } catch {}
        throw "Timeout ($timeoutSeconds s): cmd.exe $($psi.Arguments)"
    }
    $outText = $stdoutTask.Result
    $errText = $stderrTask.Result
    [IO.File]::WriteAllText($logPath, ($outText + "`r`n--- STDERR ---`r`n" + $errText), (New-Object System.Text.UTF8Encoding($false)))
    return [pscustomobject]@{ ExitCode = $p.ExitCode; Output = $outText; Error = $errText }
}

Write-Host '== 1. Verify BAT embedded Python payload =='
$lines = [IO.File]::ReadAllLines($bat, [Text.Encoding]::UTF8)
$start = [Array]::IndexOf($lines, 'REM ##DDAC_DIALOGOS_PYTHON_START##')
$end = [Array]::IndexOf($lines, 'REM ##DDAC_DIALOGOS_PYTHON_END##')
Assert-True ($start -ge 0 -and $end -gt $start) 'Embedded Python markers missing or reversed.'
$b64 = New-Object System.Collections.Generic.List[string]
for ($i = $start + 1; $i -lt $end; $i++) {
    $line = $lines[$i]
    if ($line.StartsWith('REM ')) { [void]$b64.Add($line.Substring(4)) }
}
$embedded = [Convert]::FromBase64String(($b64 -join ''))
$embeddedPath = Join-Path $results 'embedded-from-bat.py'
[IO.File]::WriteAllBytes($embeddedPath, $embedded)
$sourceNormalized = Join-Path $results 'source-normalized.py'
$sourceText = [IO.File]::ReadAllText($source).Replace("`r`n","`n").Replace("`r","`n")
[IO.File]::WriteAllText($sourceNormalized, $sourceText, (New-Object System.Text.UTF8Encoding($false)))
$sourceHash = (Get-FileHash -LiteralPath $sourceNormalized -Algorithm SHA256).Hash.ToLowerInvariant()
$embeddedHash = (Get-FileHash -LiteralPath $embeddedPath -Algorithm SHA256).Hash.ToLowerInvariant()
Assert-True ($sourceHash -eq $embeddedHash) "Payload mismatch: source=$sourceHash embedded=$embeddedHash"
Write-Host "PAYLOAD MATCH: $sourceHash"

Write-Host '== 2. Python compile and engine self-tests =='
& $python -m py_compile $source (Join-Path $repoRoot 'build_v145_payload.py')
Assert-True ($LASTEXITCODE -eq 0) 'py_compile failed.'
foreach ($mode in @('selftest_v145','preflight_tokens','preflight_sintaxe')) {
    $testRoot = Join-Path $env:RUNNER_TEMP ("ddac-" + $mode)
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
    $logPath = Join-Path $results ("python-" + $mode + '.log')
    $r = Invoke-ProcessWithInput -exe $python -arguments @($source, $mode, $testRoot, '1') -inputText '' -logPath $logPath -workingDirectory $repoRoot -timeoutSeconds 300
    Assert-True ($r.ExitCode -eq 0) "$mode failed; inspect $logPath"
    Write-Host "$mode : PASS"
}

Write-Host '== 3. End-to-end BAT extraction and reintegration in CMD =='
$fixture = Join-Path $env:RUNNER_TEMP 'DDLC-fixture-acao-espacos'
if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'game') | Out-Null
Copy-Item -LiteralPath $bat -Destination (Join-Path $fixture 'UnRen-DDAC-v145.bat')
$scriptOriginal = @'
define e = Character("Emily")
label start:
    e "Hello there."
    menu:
        "Choose a route"
        "Open the door":
            $ route = "door"
        "Stay here":
            $ route = "stay"
    e "Goodbye."
'@
$screensOriginal = @'
screen quick_menu():
    textbutton "Save" action ShowMenu("save")
    textbutton "Settings" action ShowMenu("preferences")
    textbutton "Quit" action Quit(confirm=True)
'@
$scriptPath = Join-Path $fixture 'game/script.rpy'
$screensPath = Join-Path $fixture 'game/screens.rpy'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($scriptPath, $scriptOriginal.Replace("`n", "`r`n"), $utf8NoBom)
[IO.File]::WriteAllText($screensPath, $screensOriginal.Replace("`n", "`r`n"), $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $fixture 'log.txt'), "Ren'Py 8.0.3`r`n", $utf8NoBom)
$originalScriptHash = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash
$originalScreensHash = (Get-FileHash -LiteralPath $screensPath -Algorithm SHA256).Hash

# Language 1, accept the test environment's DDAC terms, menu 1, download the
# official embedded Python (size/SHA checked by the BAT), continue, then dismiss pause.
$extractInput = "1`r`n1`r`n1`r`n2`r`n1`r`n2`r`n1`r`nx`r`n"
$batLog1 = Join-Path $results 'bat-option-1-extraction.log'
[IO.File]::WriteAllText((Join-Path $results 'bat-input-extract.txt'), $extractInput, [Text.Encoding]::ASCII)
$proc1 = Invoke-BatchWithInput -inputText $extractInput -logPath $batLog1 -workingDirectory $fixture -timeoutSeconds 360
Assert-True ($proc1.ExitCode -eq 0) "BAT extraction exited $($proc1.ExitCode); inspect $batLog1. Output: $($proc1.Output.Substring(0, [Math]::Min(1200, $proc1.Output.Length)))"
$extractLog = Get-Content -LiteralPath (Join-Path $fixture 'UnRen-DDAC-Extração-de-Diálogos.txt') -Raw -ErrorAction Stop
Assert-True ($extractLog.Contains('SEM VALIDAÇÃO')) 'Extraction report did not clearly mark oracle fallback.'
$extracted = Join-Path $fixture 'DDAC-Diálogos-Extraídos'
Assert-True (Test-Path -LiteralPath (Join-Path $extracted 'script.rpy')) 'Extracted script.rpy missing.'
Assert-True (Test-Path -LiteralPath (Join-Path $extracted 'screens.rpy')) 'Extracted screens.rpy missing.'

$replacements = @{
    '"Emily"'='"Emília"'; '"Hello there."'='"Olá!"'; '"Choose a route"'='"Escolha uma rota"';
    '"Open the door"'='"Abra a porta"'; '"Stay here"'='"Fique aqui"'; '"Goodbye."'='"Até logo!"';
    '"Save"'='"Salvar"'; '"Settings"'='"Configurações"'; '"Quit"'='"Sair"'
}
foreach ($name in @('script.rpy','screens.rpy')) {
    $path = Join-Path $extracted $name
    $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    foreach ($key in $replacements.Keys) { $text = $text.Replace($key, $replacements[$key]) }
    [IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

# Terms were accepted in the isolated test cache. Select option 3, normal reintegration, then dismiss pause.
$reinjectInput = "1`r`n3`r`n1`r`nx`r`n"
$input2 = Join-Path $results 'bat-input-reinject.txt'
[IO.File]::WriteAllText($input2, $reinjectInput, [Text.Encoding]::ASCII)
$batLog2 = Join-Path $results 'bat-option-3-reintegration.log'
$proc2 = Invoke-BatchWithInput -inputText $reinjectInput -logPath $batLog2 -workingDirectory $fixture -timeoutSeconds 360
Assert-True ($proc2.ExitCode -eq 0) "BAT reintegration exited $($proc2.ExitCode); inspect $batLog2. Output: $($proc2.Output.Substring(0, [Math]::Min(1200, $proc2.Output.Length)))"
$outScript = Join-Path $fixture 'DDAC-Diálogos-Mesclados\game\script.rpy'
$outScreens = Join-Path $fixture 'DDAC-Diálogos-Mesclados\game\screens.rpy'
Assert-True (Test-Path -LiteralPath $outScript) 'Reintegrated script.rpy missing.'
Assert-True (Test-Path -LiteralPath $outScreens) 'Reintegrated screens.rpy missing.'
$scriptText = [IO.File]::ReadAllText($outScript, [Text.Encoding]::UTF8)
$screensText = [IO.File]::ReadAllText($outScreens, [Text.Encoding]::UTF8)
foreach ($expected in @('Character("Emília")','"Olá!"','"Escolha uma rota"','"Abra a porta"','"Fique aqui"','"Até logo!"','$ route = "door"','$ route = "stay"')) {
    Assert-True ($scriptText.Contains($expected)) "Reintegrated script missing expected content: $expected"
}
foreach ($expected in @('textbutton "Salvar" action ShowMenu("save")','textbutton "Configurações" action ShowMenu("preferences")','textbutton "Sair" action Quit(confirm=True)')) {
    Assert-True ($screensText.Contains($expected)) "Reintegrated screen missing expected action/text: $expected"
}
Assert-True ((Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash -eq $originalScriptHash) 'Original game/script.rpy was modified.'
Assert-True ((Get-FileHash -LiteralPath $screensPath -Algorithm SHA256).Hash -eq $originalScreensHash) 'Original game/screens.rpy was modified.'
Write-Host 'BAT option 1 + option 3 round-trip: PASS (synthetic fixture, no real mod assets)'

Write-Host '== 4. Record current known limitation: packed-only fixture =='
$packed = Join-Path $env:RUNNER_TEMP 'DDAC packed-only fixture'
if (Test-Path -LiteralPath $packed) { Remove-Item -LiteralPath $packed -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $packed 'game') | Out-Null
[IO.File]::WriteAllText((Join-Path $packed 'game/scripts.rpa'), 'synthetic placeholder; not a real archive', $utf8NoBom)
[IO.File]::WriteAllText((Join-Path $packed 'game/script.rpyc'), 'synthetic placeholder; not compiled bytecode', $utf8NoBom)
$packedLog = Join-Path $results 'packed-only-preflight.log'
$packedResult = Invoke-ProcessWithInput -exe $python -arguments @($source, 'preflight', $packed, '1', 'extrair') -inputText '' -logPath $packedLog -workingDirectory $repoRoot -timeoutSeconds 120
Assert-True ($packedResult.ExitCode -ne 0) 'Packed-only fixture unexpectedly passed without visible source scripts.'
Assert-True ($packedResult.Output.Contains('BLOQUEADO')) 'Packed-only fixture was not clearly blocked.'
Write-Host 'Packed-only fixture: EXPECTED BLOCK BY DESIGN (extract/decompile sources upstream)'

$summary = @"
DDAC V145 Windows CI summary
Payload SHA-256: $sourceHash
Engine self-tests: PASS
BAT option 1 extraction: PASS (synthetic fixture)
BAT option 3 reintegration: PASS (synthetic fixture)
Original fixture files unchanged: PASS
Oracle fallback labeled SEM VALIDAÇÃO: PASS
Packed-only RPA/RPYC fixture: EXPECTED BLOCK BY DESIGN (source extraction/decompilation happens upstream)
No DDLC/template assets or copyrighted game files were used.
"@
[IO.File]::WriteAllText((Join-Path $results 'SUMMARY.txt'), $summary, $utf8NoBom)
Write-Host $summary