$ErrorActionPreference = 'Stop'

function Resolve-DartExecutable {
  $dartCommand = Get-Command dart -ErrorAction SilentlyContinue
  if ($dartCommand) {
    return $dartCommand.Source
  }

  if ($env:FLUTTER_ROOT) {
    $flutterRootDart = Join-Path $env:FLUTTER_ROOT 'bin\dart.bat'
    if (Test-Path $flutterRootDart) {
      return (Resolve-Path $flutterRootDart).Path
    }
  }

  $knownInstallations = @(
    'C:\src\flutter\bin\dart.bat',
    (Join-Path $env:USERPROFILE 'fvm\default\bin\dart.bat')
  )
  foreach ($candidate in $knownInstallations) {
    if (Test-Path $candidate) {
      return (Resolve-Path $candidate).Path
    }
  }

  $fvmDart = Join-Path $PSScriptRoot '..\.fvm\flutter_sdk\bin\dart.bat'
  if (Test-Path $fvmDart) {
    return (Resolve-Path $fvmDart).Path
  }

  throw "Dart SDK introuvable. Ajoute Dart/Flutter au PATH ou definis FLUTTER_ROOT."
}

$dartExe = Resolve-DartExecutable
& $dartExe doc --output docs/api
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Documentation API generee: docs/api/index.html"
