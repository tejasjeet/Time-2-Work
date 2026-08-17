# Build a release APK that talks to your cloud API.
# Usage:
#   .\scripts\build-release-apk.ps1 "https://time2work-api.onrender.com/api"

param(
  [Parameter(Mandatory = $true)]
  [string]$ApiBase
)

$ErrorActionPreference = "Stop"
$mobile = Join-Path $PSScriptRoot ".." "mobile" | Resolve-Path

Write-Host "Building release APK with API_BASE=$ApiBase" -ForegroundColor Cyan
Push-Location $mobile
try {
  flutter build apk --release --dart-define=API_BASE=$ApiBase
  $apk = Join-Path $mobile "build\app\outputs\flutter-apk\app-release.apk"
  Write-Host ""
  Write-Host "APK ready:" -ForegroundColor Green
  Write-Host "  $apk"
  Write-Host ""
  Write-Host "Copy this file to any Android phone and install it."
} finally {
  Pop-Location
}
