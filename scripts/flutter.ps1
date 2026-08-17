# Use the shared Flutter SDK at D:\flutter
$Flutter = "D:\flutter\bin\flutter.bat"
if (-not (Test-Path $Flutter)) {
  throw "Flutter SDK not found at D:\flutter. Expected: D:\flutter\bin\flutter.bat"
}
& $Flutter @args
