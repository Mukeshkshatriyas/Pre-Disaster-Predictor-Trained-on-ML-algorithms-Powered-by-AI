$ErrorActionPreference = 'Stop'

$frontendPath = Join-Path $PSScriptRoot 'FloodGuard'
$nodeModulesPath = Join-Path $frontendPath 'node_modules'

if (-not (Test-Path $nodeModulesPath)) {
    Push-Location $frontendPath
    try {
        npm ci
        if ($LASTEXITCODE -ne 0) {
            throw 'Failed to install FloodGuard frontend dependencies.'
        }
    }
    finally {
        Pop-Location
    }
}

$frontendPort = 3000
while ($true) {
    $existingConnections = @(Get-NetTCPConnection -LocalPort $frontendPort -ErrorAction SilentlyContinue)
    if ($existingConnections.Count -eq 0) {
        break
    }
    $frontendPort++
}

$dashboardUrl = "http://localhost:$frontendPort/"

$pythonPath = Join-Path $PSScriptRoot 'venv\Scripts\python.exe'
if (-not (Test-Path $pythonPath)) {
    $pythonPath = 'python'
}

$apiCommand = "Set-Location -LiteralPath '$PSScriptRoot'; `$env:FLOODGUARD_DASHBOARD_URL = '$dashboardUrl'; & '$pythonPath' '.\app.py'"
$frontendCommand = "Set-Location -LiteralPath '$frontendPath'; npm run dev -- --hostname 127.0.0.1 --port $frontendPort"

Start-Process -FilePath 'powershell.exe' -WorkingDirectory $PSScriptRoot -ArgumentList @('-NoExit', '-Command', $apiCommand)
Start-Process -FilePath 'powershell.exe' -WorkingDirectory $frontendPath -ArgumentList @('-NoExit', '-Command', $frontendCommand)

Write-Host 'Flask API: http://localhost:5000'
Write-Host "FloodGuard dashboard: $dashboardUrl"
Write-Host 'After the frontend is ready, open http://localhost:5000 to be redirected to the dashboard.'