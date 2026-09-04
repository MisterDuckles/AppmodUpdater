# AppmodUpdater
=======================================

AppmodUpdater is a guided Windows installer and updater for Spotify and Spicetify. It can optionally install Spicetify Marketplace and Vencord for Discord.


### Script details:

`spicetify.ps1` updates Spicetify, reapplies the configuration, and only restarts Spotify when it was already running. It waits 30 seconds after sign-in, prevents duplicate runs, and rotates `spicetify.log` above 1 MB.

> [!NOTE]
> A batch file (`update.bat`) is included in case anyone has issues with the powershell script but both function mostly identically.


### How to use:

1. Download or clone this repository to a permanent folder.
2. Open PowerShell in that folder.
3. Run `powershell.exe -ExecutionPolicy Bypass -File .\install.ps1`.
4. Follow the prompts. Spotify is required; Spicetify, Marketplace, and Vencord are optional prompts.

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