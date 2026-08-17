# Seed your cloud MongoDB (Atlas) with demo users, jobs, marketplace data.
# Usage:
#   .\scripts\seed-cloud.ps1 "mongodb+srv://USER:PASS@cluster.mongodb.net/time2work"

param(
  [Parameter(Mandatory = $true)]
  [string]$MongoUri
)

$ErrorActionPreference = "Stop"
$backend = Join-Path $PSScriptRoot ".." "backend" | Resolve-Path

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
