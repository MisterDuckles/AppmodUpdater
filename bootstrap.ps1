$ErrorActionPreference = 'Stop'

$destination = Join-Path $env:USERPROFILE 'AppmodUpdater'
$archive = Join-Path $env:TEMP 'AppmodUpdater-main.zip'
$extractPath = Join-Path $env:TEMP ('AppmodUpdater-' + [guid]::NewGuid().ToString())
$downloadUrl = 'https://github.com/MisterDuckles/AppmodUpdater/archive/refs/heads/main.zip'

if (Test-Path $destination) {
    throw "The destination already exists: $destination. Remove it or run install.ps1 there manually."
}

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archive
    Expand-Archive -Path $archive -DestinationPath $extractPath
    Move-Item -Path (Join-Path $extractPath 'AppmodUpdater-main') -Destination $destination
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destination 'install.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw "The AppmodUpdater installer exited with code $LASTEXITCODE."
    }
} finally {
    Remove-Item $archive -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
}