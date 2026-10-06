[CmdletBinding()]
param(
    [string]$Package = "vn.zenithas.plato",
    [string]$Serial = "",
    [ValidateRange(0, 3600)]
    [int]$WaitSeconds = 0,
    [switch]$KillAppProcess
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw "adb was not found. Install Android Platform Tools and add adb to PATH."
}

$connected = @(
    adb devices |
        Select-Object -Skip 1 |
        ForEach-Object { ($_ -split "\s+")[0] } |
        Where-Object { $_ }
)
if (-not $Serial) {
    if ($connected.Count -ne 1) {
        throw "Connect exactly one Android device or pass -Serial. Connected: $($connected -join ', ')"
    }
    $Serial = $connected[0]
}
if ($connected -notcontains $Serial) {
    throw "Device $Serial is not connected or not authorized."
}

$adbPrefix = @("-s", $Serial)
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDirectory = Join-Path $PSScriptRoot "..\build\notification-manual-test\$timestamp"
$outputDirectory = [System.IO.Path]::GetFullPath($outputDirectory)
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

function Invoke-AdbText {
    param([Parameter(Mandatory)][string[]]$Arguments)
    return (& adb @adbPrefix @Arguments 2>&1 | Out-String)
}

function Save-Snapshot {
    param([Parameter(Mandatory)][string]$Name)
    $directory = Join-Path $outputDirectory $Name
    New-Item -ItemType Directory -Path $directory -Force | Out-Null

    Invoke-AdbText @("shell", "getprop", "ro.product.model") |
        Set-Content -Encoding utf8 (Join-Path $directory "device-model.txt")
    Invoke-AdbText @("shell", "getprop", "ro.build.version.release") |
        Set-Content -Encoding utf8 (Join-Path $directory "android-version.txt")
    Invoke-AdbText @("shell", "pidof", $Package) |
        Set-Content -Encoding utf8 (Join-Path $directory "process.txt")
    Invoke-AdbText @("shell", "cmd", "appops", "get", $Package, "POST_NOTIFICATION") |
        Set-Content -Encoding utf8 (Join-Path $directory "notification-permission.txt")
    Invoke-AdbText @("shell", "dumpsys", "package", $Package) |
        Set-Content -Encoding utf8 (Join-Path $directory "package.txt")
    Invoke-AdbText @("shell", "dumpsys", "jobscheduler", $Package) |
        Set-Content -Encoding utf8 (Join-Path $directory "jobscheduler.txt")
    Invoke-AdbText @("shell", "dumpsys", "alarm") |
        Select-String -Pattern $Package -Context 4,8 |
        Out-String |
        Set-Content -Encoding utf8 (Join-Path $directory "alarms.txt")
    Invoke-AdbText @("shell", "dumpsys", "notification", "--noredact") |
        Select-String -Pattern "$Package|plato_reminders_v2|NotificationRecord" -Context 3,8 |
        Out-String |
        Set-Content -Encoding utf8 (Join-Path $directory "notifications.txt")
    Invoke-AdbText @("shell", "dumpsys", "deviceidle") |
        Set-Content -Encoding utf8 (Join-Path $directory "device-idle.txt")
    Invoke-AdbText @("logcat", "-d", "-v", "time") |
        Select-String -Pattern "Plato|NotificationCoordinator|WorkManager|reminder_refresh" |
        Out-String |
        Set-Content -Encoding utf8 (Join-Path $directory "notification-logcat.txt")
}

Write-Host "Collecting initial notification state from $Serial..."
Save-Snapshot "before"

if ($KillAppProcess) {
    Write-Host "Killing only the background app process (not Force stop)..."
    Invoke-AdbText @("shell", "am", "kill", $Package) |
        Set-Content -Encoding utf8 (Join-Path $outputDirectory "am-kill.txt")
}

if ($WaitSeconds -gt 0) {
    Write-Host "Waiting $WaitSeconds seconds. Keep the phone locked and do not reopen Plato..."
    Start-Sleep -Seconds $WaitSeconds
    Write-Host "Collecting final notification state..."
    Save-Snapshot "after"
}

@"
Package: $Package
Device: $Serial
Captured: $(Get-Date -Format o)
WaitSeconds: $WaitSeconds
KillAppProcess: $KillAppProcess

This script never uses Force stop and does not clear app data.
Compare before/after/notifications.txt and before/after/alarms.txt.
"@ | Set-Content -Encoding utf8 (Join-Path $outputDirectory "README.txt")

Write-Host "Evidence saved to: $outputDirectory"
