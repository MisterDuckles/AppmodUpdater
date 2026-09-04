$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logPath = Join-Path $scriptRoot "spicetify.log"
$mutex = New-Object Threading.Mutex($false, "Local\AppmodUpdater")

if (-not $mutex.WaitOne(0)) {
    exit 0
}

try {
    Set-Location $scriptRoot
    if (Test-Path $logPath -PathType Leaf -and (Get-Item $logPath).Length -gt 1MB) {
        Move-Item $logPath "$logPath.1" -Force
    }

    function Write-LogMessage {
        param([AllowEmptyString()][string]$Message)
        if ([string]::IsNullOrWhiteSpace($Message)) { return }
        $cleanMessage = $Message -replace '\x1b\[[0-9;]*m', ''
        $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $cleanMessage"
        Write-Host $Message
        Add-Content -Path $logPath -Value $entry
    }

    function Invoke-Spicetify {
        param([Parameter(Mandatory)][string[]]$Arguments)
        Write-LogMessage ("spicetify " + ($Arguments -join ' '))
        & $spicetifyPath @Arguments 2>&1 | ForEach-Object { Write-LogMessage ([string]$_) }
        if ($LASTEXITCODE -ne 0) {
            throw "Spicetify failed with exit code $LASTEXITCODE."
        }
    }

    Add-Content -Path $logPath -Value "`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting updater"
    $spicetifyCommand = Get-Command spicetify -CommandType Application -ErrorAction SilentlyContinue
    $spicetifyPath = if ($spicetifyCommand) { $spicetifyCommand.Source } else { Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe' }
    if (-not (Test-Path $spicetifyPath)) {
        Write-LogMessage "Spicetify is not installed or is not available in PATH."
        exit 1
    }

    $spotifyWasRunning = [bool](Get-Process -Name Spotify -ErrorAction SilentlyContinue)
    Write-LogMessage "Updating Spicetify"
    Invoke-Spicetify @('update', '--no-restart')
    Write-LogMessage "Restoring Spicetify config"
    Invoke-Spicetify @('restore', 'backup', 'apply', '--no-restart')

    if ($spotifyWasRunning) {
        Write-LogMessage "Restarting Spotify"
        Invoke-Spicetify @('restart')
    } else {
        Write-LogMessage "Spotify was not running; skipping restart"
    }
    Write-LogMessage "Updater completed successfully"
    exit 0
} catch {
    Write-LogMessage "ERROR: $($_.Exception.Message)"
    exit 1
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}