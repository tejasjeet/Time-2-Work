# Seed your cloud MongoDB (Atlas) with demo users, jobs, marketplace data.
# Usage:
#   .\scripts\seed-cloud.ps1
#   .\scripts\seed-cloud.ps1 "mongodb+srv://USER:PASS@cluster.mongodb.net/time2work"

param(
  [Parameter(Mandatory = $false)]
  [string]$MongoUri
)

$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot ".." | Resolve-Path
$backend = Join-Path $root "backend" | Resolve-Path
$credsFile = Join-Path $root "atlas-credentials.env"

if (-not $MongoUri -and (Test-Path $credsFile)) {
  Get-Content $credsFile | ForEach-Object {
    if ($_ -match '^\s*MONGODB_URI\s*=\s*"(.+)"\s*$') {
      $MongoUri = $Matches[1]
    }
  }
}

if (-not $MongoUri) {
  Write-Error "Pass MongoUri or create atlas-credentials.env with MONGODB_URI."
}

if ($MongoUri -notmatch '/[^/?]+$') {
  $MongoUri = "$MongoUri/time2work"
}

Write-Host "Seeding cloud database..." -ForegroundColor Cyan
Push-Location $backend
try {
  $env:MONGO_URI = $MongoUri
  $env:NODE_ENV = "production"
  npm run seed
  Write-Host ""
  Write-Host "Done. Test login:" -ForegroundColor Green
  Write-Host "  Worker phone:   9999990001  OTP: 123456"
  Write-Host "  Business phone: 9999990002  OTP: 123456"
} finally {
  Pop-Location
}
