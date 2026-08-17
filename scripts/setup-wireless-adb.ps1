# One-time setup: use phone without USB cable after this.
# Phone and PC must be on the same Wi-Fi.

$Adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $Adb)) { throw "adb not found" }

$usb = & $Adb devices | Select-String "device$"
if (-not $usb) { throw "Connect phone with USB first and allow USB debugging." }

$usbId = ($usb[0].Line -split "\s+")[0]
Write-Host "Using USB device: $usbId"
Write-Host "Enabling wireless debugging on port 5555..."
& $Adb -s $usbId tcpip 5555 | Out-Null
Start-Sleep -Seconds 2

$phoneIp = (& $Adb -s $usbId shell "ip route" 2>$null | Select-String "src" | ForEach-Object {
  if ($_ -match "src\s+(\d+\.\d+\.\d+\.\d+)") { $Matches[1] }
}) | Select-Object -First 1

if (-not $phoneIp) {
  throw "Could not read phone Wi-Fi IP. Keep USB connected and try again."
}

$pcIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.InterfaceAlias -match "Wi-Fi|Ethernet" } | Select-Object -First 1 -ExpandProperty IPAddress)
Write-Host "PC Wi-Fi IP: $pcIp"
Write-Host "Phone Wi-Fi IP: $phoneIp"
if ($pcIp -and ($pcIp.Split('.')[0..1] -join '.') -ne ($phoneIp.Split('.')[0..1] -join '.')) {
  Write-Host "WARNING: Phone and PC look like different Wi-Fi networks. Wireless ADB may fail." -ForegroundColor Yellow
  Write-Host "Connect both to the SAME Wi-Fi, then run this script again." -ForegroundColor Yellow
}

Write-Host "Connecting wirelessly to $phoneIp ..."
& $Adb connect "${phoneIp}:5555"
& $Adb devices -l

Write-Host ""
Write-Host "Done. You can unplug USB now." -ForegroundColor Green
Write-Host "Next time run: .\scripts\dev-phone.ps1"
