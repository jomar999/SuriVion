$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $projectRoot 'backend'
$pythonExe = Join-Path $backendDir '.venv\Scripts\python.exe'
$adbExe = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $pythonExe)) {
    throw "Python venv not found at: $pythonExe"
}

if (-not (Test-Path $adbExe)) {
    throw "adb.exe not found at: $adbExe"
}

Write-Host '[1/4] Starting backend server in a new PowerShell window...'
$backendCommand = "Set-Location '$backendDir'; & '$pythonExe' gemini_server.py"
Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $backendCommand | Out-Null

Start-Sleep -Seconds 1

Write-Host '[2/4] Setting up USB reverse tunnel (5000 -> 5000)...'
& $adbExe reverse tcp:5000 tcp:5000 | Out-Null

Write-Host '[3/4] Detecting Android device from flutter devices...'
$devices = flutter devices --machine | ConvertFrom-Json
$androidDevice = $devices | Where-Object { $_.targetPlatform -like 'android*' } | Select-Object -First 1

if (-not $androidDevice) {
    throw 'No Android device found. Connect phone with USB debugging enabled, then retry.'
}

$deviceId = $androidDevice.id
Write-Host "Found device: $deviceId"

Write-Host '[4/4] Running Flutter app in USB mode...'
flutter run -d $deviceId --dart-define="CHAT_ENDPOINT=http://127.0.0.1:5000/chat"
