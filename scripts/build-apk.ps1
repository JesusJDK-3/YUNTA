[CmdletBinding()]
param(
  [string]$FlutterCommand = 'flutter'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$definesPath = Join-Path $projectRoot '.env.json'

if (-not (Test-Path -LiteralPath $definesPath -PathType Leaf)) {
  throw 'Falta .env.json. Copia supabase.defines.example.json y configura Supabase.'
}

$defines = Get-Content -LiteralPath $definesPath -Raw | ConvertFrom-Json
$required = @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')
foreach ($name in $required) {
  if (-not $defines.$name) { throw "Falta la propiedad $name en .env.json." }
}

$flutter = Get-Command $FlutterCommand -ErrorAction SilentlyContinue
if (-not $flutter) { throw 'No se encontró Flutter. Añade flutter/bin al PATH.' }

Push-Location $projectRoot
try {
  & $flutter.Source build apk --debug "--dart-define-from-file=$definesPath"
  if ($LASTEXITCODE -ne 0) { throw 'Flutter no pudo compilar el APK.' }

  $apk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
  $outputDirectory = Join-Path $projectRoot 'artifacts'
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
  Copy-Item -LiteralPath $apk -Destination (Join-Path $outputDirectory 'Yunta-debug.apk') -Force
} finally {
  Pop-Location
}

Write-Output 'APK generado en artifacts/Yunta-debug.apk.'
