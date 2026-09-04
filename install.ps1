<#
.SYNOPSIS
    Installs Spicetify Autoupdater by creating a startup shortcut for start.vbs.
.DESCRIPTION
    Run this from the folder where you extracted the release. It checks that
    all required files are present, creates a shortcut in the Windows Startup
    folder pointing to start.vbs, and confirms the installation succeeded.
.NOTES
    If PowerShell blocks the script with an execution policy error, run:
    powershell.exe -ExecutionPolicy Bypass -File install.ps1
#>

param(
    [ValidateSet('install', 'status', 'run-now', 'uninstall')]
    [string]$Action = 'install',
    [ValidateRange(0, 3600)]
    [int]$StartupDelaySeconds = 30
)

# Displays a banner, matching the style used in spicetify.ps1
function Write-Sep {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$Message
    )
    $top = "`n +/------------------------------\+`n"
    $bot = "`n +\------------------------------/+`n"
    Write-Host $top $Message $bot
}

function Test-SpotifyInstalled {
    $spotifyPaths = @(
        "$env:APPDATA\Spotify\Spotify.exe",
        "$env:LOCALAPPDATA\Spotify\Spotify.exe"
    )
    return ($spotifyPaths | Where-Object { Test-Path $_ } | Select-Object -First 1)
}

function Get-SpicetifyExecutable {
    $command = Get-Command spicetify -CommandType Application -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $localPath = Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe'
    if (Test-Path $localPath) { return $localPath }
    return $null
}

function Ensure-Spicetify {
    if (Get-SpicetifyExecutable) {
        Write-Host "[OK] Spicetify is already installed." -ForegroundColor Green
        return $true
    }

    Write-Host "[INFO] Spicetify is not installed." -ForegroundColor Cyan
    $response = Read-Host "Install Spicetify using the official installer? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "[SKIPPED] Spicetify installation cancelled." -ForegroundColor Yellow
        return $false
    }

    try {
        Invoke-RestMethod 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1' | Invoke-Expression
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
    } catch {
        Write-Host "[ERROR] Spicetify installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    if (-not (Get-SpicetifyExecutable)) {
        Write-Host "[ERROR] Spicetify was installed but is not available in PATH yet." -ForegroundColor Red
        return $false
    }

    Write-Host "[OK] Spicetify installed successfully." -ForegroundColor Green
    return $true
}

function Ensure-Marketplace {
    $spicetifyPath = Get-SpicetifyExecutable
    $marketplace = (& $spicetifyPath config custom_apps 2>$null | Out-String)
    if ($marketplace -match 'marketplace') {
        Write-Host "[OK] Spicetify Marketplace is already configured." -ForegroundColor Green
        return $true
    }

    $response = Read-Host "Install Spicetify Marketplace? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "[SKIPPED] Marketplace installation cancelled." -ForegroundColor Yellow
        return $true
    }

    try {
        Invoke-RestMethod 'https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.ps1' | Invoke-Expression
        Write-Host "[OK] Spicetify Marketplace installed." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Marketplace installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Ensure-Vencord {
    $vencordPaths = @("$env:APPDATA\Vencord", "$env:LOCALAPPDATA\Vencord")
    if ($vencordPaths | Where-Object { Test-Path $_ } | Select-Object -First 1) {
        Write-Host "[OK] Vencord is already installed." -ForegroundColor Green
        return $true
    }

    $response = Read-Host "Install Vencord for Discord? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "[SKIPPED] Vencord installation cancelled." -ForegroundColor Yellow
        return $true
    }

    try {
        Invoke-RestMethod 'https://raw.githubusercontent.com/Vencord/Installer/main/install.ps1' | Invoke-Expression
        Write-Host "[OK] Vencord installer completed." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Vencord installation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-StartupPaths {
    $startupPath = [System.Environment]::GetFolderPath('Startup')
    return @{
        Startup = $startupPath
        Shortcut = Join-Path $startupPath 'SpicetifyAutoupdater.lnk'
    }
}

function Show-Status {
    $paths = Get-StartupPaths
    $spotify = Test-SpotifyInstalled
    $spicetify = Get-SpicetifyExecutable
    [pscustomobject]@{
        Spotify = if ($spotify) { 'Installed' } else { 'Missing' }
        Spicetify = if ($spicetify) { 'Installed' } else { 'Missing' }
        Autostart = if (Test-Path $paths.Shortcut) { 'Enabled' } else { 'Disabled' }
        UpdaterPath = $PSScriptRoot
        StartupDelaySeconds = $StartupDelaySeconds
    } | Format-List
}

function Invoke-Now {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'spicetify.ps1')
    exit $LASTEXITCODE
}

function Uninstall-Autoupdater {
    $paths = Get-StartupPaths
    if (Test-Path $paths.Shortcut) {
        Remove-Item $paths.Shortcut -Force
        Write-Host "[OK] Startup shortcut removed." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Startup shortcut was not installed." -ForegroundColor Cyan
    }
    Write-Host "Updater files were kept in $PSScriptRoot. Remove that folder manually if no longer needed."
}

function Install-AutoupdaterShortcut {
    try {
        # 1. Must be run from a saved .ps1 file, not pasted into the console
        if ([string]::IsNullOrEmpty($PSScriptRoot)) {
            throw "This script must be saved and run as a .ps1 file (it won't work if pasted directly into the console)."
        }

        # 2. Confirm the release was extracted correctly (all required files present)
        $RequiredFiles = @("start.vbs", "spicetify.ps1", "update.bat")
        foreach ($file in $RequiredFiles) {
            $path = Join-Path $PSScriptRoot $file
            if (-not (Test-Path -Path $path)) {
                throw "Required file '$file' was not found in: $PSScriptRoot`nMake sure you extracted the full release archive before running this script."
            }
        }

        if (-not (Test-SpotifyInstalled)) {
            throw "Spotify was not found. Install Spotify first, then run this installer again."
        }
        if (-not (Ensure-Spicetify)) {
            throw "Spicetify is required before the updater can be installed."
        }
        if (-not (Ensure-Marketplace)) {
            throw "Marketplace installation failed."
        }
        if (-not (Ensure-Vencord)) {
            throw "Vencord installation failed."
        }

        $StartupPath  = [System.Environment]::GetFolderPath('Startup')
        $VbsPath      = Join-Path $PSScriptRoot "start.vbs"
        $ShortcutPath = Join-Path $StartupPath "SpicetifyAutoupdater.lnk"

        # 3. Check if already installed, and verify if the user wants to overwrite the existing shortcut
        if (Test-Path -Path $ShortcutPath) {
            Write-Host "[INFO] A Spicetify Autoupdater shortcut already exists in the Startup folder." -ForegroundColor Cyan
            $response = Read-Host "Overwrite it? (Y/N)"
            if ($response -notmatch '^[Yy]') {
                Write-Host "[SKIPPED] Installation cancelled." -ForegroundColor Yellow
                return
            }
        }

        # 4. Create the Windows shortcut
        $WScriptShell = New-Object -ComObject WScript.Shell
        try {
            $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
            $Shortcut.TargetPath       = $VbsPath
            $Shortcut.WorkingDirectory = $PSScriptRoot
            $Shortcut.Arguments       = [string]$StartupDelaySeconds
            $Shortcut.Description      = "Automated Spicetify Updater"

            $Shortcut.Save()
        } finally {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($WScriptShell) | Out-Null
        }

        # 5. Confirm the .lnk file was actually created
        if (-not (Test-Path -Path $ShortcutPath)) {
            throw "The system failed to save the shortcut in the Startup folder."
        }

        Write-Host "[OK] Shortcut created successfully in the Startup folder ($StartupPath)!" -ForegroundColor Green
        Write-Host "[OK] Spicetify Autoupdater is now installed and will run every time you log in." -ForegroundColor Green
        Write-Host "     You can test it right away by double-clicking 'start.vbs', then check 'spicetify.log' for the results." -ForegroundColor Gray

    } catch {
        Write-Host "[ERROR] Could not complete the installation." -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

switch ($Action) {
    'status' { Show-Status }
    'run-now' { Invoke-Now }
    'uninstall' { Uninstall-Autoupdater }
    'install' {
        Write-Sep "|*   Installing AppmodUpdater   *|"
        Install-AutoupdaterShortcut
    }
}