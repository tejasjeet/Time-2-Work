# Build + install release APK (only when you need a standalone app without PC).
param(
  [string]$ApiBase = ""
)

$Root = Split-Path $PSScriptRoot -Parent
$Mobile = Join-Path $Root "mobile"
$Flutter = "D:\flutter\bin\flutter.bat"
$Adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

if (-not $ApiBase) {
  $ip = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.InterfaceAlias -match "Wi-Fi|Ethernet" } |
    Select-Object -First 1 -ExpandProperty IPAddress
  $ApiBase = "http://${ip}:4000/api"
}

Set-Location $Mobile
& $Flutter build apk --release --dart-define=API_BASE=$ApiBase
& $Adb install -r "build\app\outputs\flutter-apk\app-release.apk"
Write-Host "Release APK installed. API: $ApiBase" -ForegroundColor Green
