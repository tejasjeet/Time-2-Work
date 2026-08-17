# Time2Work — live dev on phone (auto hot reload, no APK reinstall).
# Usage: .\scripts\dev-phone.ps1

param(
  [string]$DeviceId = "",
  [string]$ApiBase = ""
)

$ErrorActionPreference = "Stop"

$Root = Split-Path $PSScriptRoot -Parent
$Mobile = Join-Path $Root "mobile"
$Flutter = "D:\flutter\bin\flutter.bat"
$Adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$LogFile = Join-Path $Root ".flutter-run.log"
$UriFile = Join-Path $Root ".flutter-dev-uri.txt"

function Get-LanIp {
  $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -ne "WellKnown" -and $_.InterfaceAlias -match "Wi-Fi|Ethernet" } |
    Select-Object -First 1 -ExpandProperty IPAddress
  if (-not $ip) { throw "Could not detect PC Wi-Fi IP." }
  return $ip
}

function Get-AndroidDevice {
  if (-not (Test-Path $Adb)) { throw "adb not found at $Adb" }
  $lines = & $Adb devices 2>$null | Select-Object -Skip 1
  foreach ($line in $lines) {
    if ($line -match "^(?<id>\S+)\s+device$") { return $Matches.id }
  }
  throw "No Android phone connected. Enable USB debugging and plug in USB."
}

function Get-FlutterVmUri {
  if (Test-Path $UriFile) {
    $saved = (Get-Content $UriFile -Raw).Trim()
    if ($saved) { return $saved }
  }
  if (-not (Test-Path $LogFile)) { return $null }
  $log = Get-Content $LogFile -Raw -ErrorAction SilentlyContinue
  if ($log -match "A Dart VM Service on .+ is available at:\s+(\S+)") {
    return $Matches[1]
  }
  return $null
}

function Invoke-HotReload {
  param([string]$ChangedPath)
  $uri = Get-FlutterVmUri
  if (-not $uri) { return }

  $needsRestart = $ChangedPath -match "pubspec\.yaml|\\assets\\|/assets/"
  $endpoint = if ($needsRestart) { "$uri/restart" } else { "$uri/hotReload" }
  $label = if ($needsRestart) { "Hot restart" } else { "Hot reload" }

  try {
    Invoke-RestMethod -Method Post -Uri $endpoint -TimeoutSec 8 | Out-Null
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $label" -ForegroundColor Green
  } catch {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Waiting for Flutter..." -ForegroundColor DarkGray
  }
}

if (-not (Test-Path $Flutter)) { throw "Flutter not found at $Flutter" }
if (-not $ApiBase) { $ApiBase = "http://$(Get-LanIp):4000/api" }
if (-not $DeviceId) { $DeviceId = Get-AndroidDevice }

Remove-Item $LogFile, $UriFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Time2Work LIVE DEV" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Phone : $DeviceId"
Write-Host "API   : $ApiBase"
Write-Host ""
Write-Host "1) Flutter opens in a new window (first time ~2 min build)"
Write-Host "2) Keep THIS window open for auto updates on phone"
Write-Host "3) Edit mobile code -> phone updates in ~2 sec"
Write-Host ""

$flutterCmd = @"
Set-Location '$Mobile'
`$uri = `$null
& '$Flutter' run -d $DeviceId --dart-define=API_BASE=$ApiBase 2>&1 | ForEach-Object {
  Write-Host `$_
  if (`$_ -match 'A Dart VM Service on .+ is available at:\s+(\S+)') {
    `$uri = `$Matches[1]
    Set-Content -Path '$UriFile' -Value `$uri -NoNewline
  }
}
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $flutterCmd

Write-Host "Waiting for Flutter to start on phone..." -ForegroundColor Yellow
$deadline = (Get-Date).AddMinutes(5)
while ((Get-Date) -lt $deadline) {
  if (Get-FlutterVmUri) {
    Write-Host "Connected. Auto hot reload is active." -ForegroundColor Green
    break
  }
  Start-Sleep -Seconds 2
}

$watchPaths = @(
  (Join-Path $Mobile "lib"),
  (Join-Path $Mobile "assets"),
  (Join-Path $Mobile "pubspec.yaml")
)

$signatures = @{}
foreach ($path in $watchPaths) {
  if (Test-Path $path -PathType Leaf) {
    $signatures[$path] = (Get-Item $path).LastWriteTimeUtc.Ticks
  } elseif (Test-Path $path -PathType Container) {
    Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
      $signatures[$_.FullName] = $_.LastWriteTimeUtc.Ticks
    }
  }
}

$lastReloadAt = Get-Date "2000-01-01"

try {
  while ($true) {
    foreach ($path in $watchPaths) {
      $files = @()
      if (Test-Path $path -PathType Leaf) { $files = @(Get-Item $path) }
      elseif (Test-Path $path -PathType Container) {
        $files = Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue
      }

      foreach ($file in $files) {
        $ticks = $file.LastWriteTimeUtc.Ticks
        $key = $file.FullName
        if ($signatures.ContainsKey($key) -and $signatures[$key] -eq $ticks) { continue }
        $signatures[$key] = $ticks
        if (((Get-Date) - $lastReloadAt).TotalMilliseconds -lt 900) { continue }
        Invoke-HotReload -ChangedPath $key
        $lastReloadAt = Get-Date
      }
    }
    Start-Sleep -Milliseconds 700
  }
} finally {
  Write-Host "Live dev watcher stopped." -ForegroundColor Yellow
}
