param([int]$BuildNumber = 3)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterBin = Join-Path $env:USERPROFILE 'flutter-sdk\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutterBin)) {
    $flutterBin = (Get-Command flutter -ErrorAction Stop).Source
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'android\key.properties'))) {
    throw 'Restore android/key.properties and the original release keystore before building an update.'
}
Push-Location $projectRoot
try {
    & $flutterBin analyze
    if ($LASTEXITCODE -ne 0) { throw 'Static checks failed.' }
    & $flutterBin test
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    & $flutterBin build apk --release --build-number $BuildNumber
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    Write-Output (Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk')
} finally {
    Pop-Location
}
