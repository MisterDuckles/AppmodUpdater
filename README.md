# AppmodUpdater
=======================================

AppmodUpdater is a guided Windows installer and updater for Spotify and Spicetify. It can optionally install Spicetify Marketplace and Vencord for Discord.

> [!NOTE]
> This is a fork, not the original project. It is based on [Spicetify-Autoupdater](https://github.com/itsgoog/Spicetify-Autoupdater) by [itsgoog](https://github.com/itsgoog) and the original contributors. The original license and attribution are preserved in this repository, and this fork remains available under the GNU GPL v3.0.


### Script details:

`spicetify.ps1` updates Spicetify, reapplies the configuration, and only restarts Spotify when it was already running. It waits 30 seconds after sign-in, prevents duplicate runs, and rotates `spicetify.log` above 1 MB.

> [!NOTE]
> A batch file (`update.bat`) is included in case anyone has issues with the powershell script but both function mostly identically.


### How to use:

For the easiest setup, open PowerShell and run this one-liner:

```powershell
irm https://raw.githubusercontent.com/MisterDuckles/AppmodUpdater/main/bootstrap.ps1 | iex
```

It downloads the latest version to `%USERPROFILE%\AppmodUpdater` and starts the installer. Follow the prompts. Spotify is required; Spicetify, Marketplace, and Vencord are optional prompts.

For a manual setup, download or clone this repository to a permanent folder and run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1
```

`start.vbs` runs the updater after Windows sign-in. You can also use the management commands below.

```powershell
.\install.ps1 -Action status
.\install.ps1 -Action run-now
.\install.ps1 -Action uninstall
.\install.ps1 -StartupDelaySeconds 60
```

`status` reports the installation state. `run-now` starts an update immediately. `uninstall` removes the startup shortcut but keeps the repository files.

> [!IMPORTANT]
> PowerShell defaults to blocking scripts as a security measure so you may need to adjust your settings. This restriction can be bypassed using `powershell.exe -ExecutionPolicy Bypass -File spicetify.ps1`. Alternatively, you can disable the script protection altogether using `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted`.


### Safety notes:

- Every optional installation asks for confirmation.
- The updater stops on errors and does not restart Spotify when it was closed.
- Review scripts before running them and prefer versioned releases over an unpinned branch.


### Links

* [Spicetify](https://spicetify.app/)
* [Spicetify Docs](https://spicetify.app/docs/getting-started "Getting Started")
* [Vencord Installer](https://github.com/Vencord/Installer)