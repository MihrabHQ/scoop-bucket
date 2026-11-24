# Install Mihrab from a manifest with Scoop, start it, and remove it again —
# what someone running `scoop install mihrab` gets, on a clean Windows.
#   pwsh scripts/test-install.ps1 [bucket/mihrab.json]
param([string]$Manifest = "bucket/mihrab.json")
$ErrorActionPreference = 'Stop'
$Manifest = (Resolve-Path $Manifest).Path

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    # The runner is an administrator; Scoop refuses one unless told.
    Invoke-Expression "& {$(Invoke-RestMethod https://get.scoop.sh)} -RunAsAdmin"
    $env:PATH = "$env:USERPROFILE\scoop\shims;$env:PATH"
}

scoop install $Manifest
if ($LASTEXITCODE -ne 0) { throw "scoop install failed ($LASTEXITCODE)" }

$app = "$env:USERPROFILE\scoop\apps\mihrab\current"
foreach ($f in @('Mihrab.exe', 'resources\app.asar')) {
    if (-not (Test-Path (Join-Path $app $f))) {
        Get-ChildItem $app | Format-Table Name, Length | Out-String | Write-Host
        throw "missing after install: $f"
    }
}
foreach ($f in @('$PLUGINSDIR', 'Uninstall Mihrab.exe')) {
    if (Test-Path -LiteralPath (Join-Path $app $f)) { throw "left behind from the installer: $f" }
}
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Scoop Apps\Mihrab.lnk"
if (-not (Test-Path $lnk)) { throw "no Start menu shortcut at $lnk" }

# It starts, and is still running a while later (a broken unpack exits at once).
$p = Start-Process (Join-Path $app 'Mihrab.exe') -PassThru
Start-Sleep -Seconds 25
if ($p.HasExited) { throw "Mihrab exited at start with code $($p.ExitCode)" }
Write-Host "Mihrab is running (pid $($p.Id))"
Get-Process mihrab -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
# Where the README and the website say its settings are.
if (-not (Test-Path "$env:APPDATA\Mihrab")) { throw "no settings folder at $env:APPDATA\Mihrab" }

# The remove line the README and the website give, as given.
scoop uninstall mihrab; Remove-Item -Recurse "$env:APPDATA\Mihrab"
if ($LASTEXITCODE -ne 0) { throw "scoop uninstall failed ($LASTEXITCODE)" }
if (Test-Path "$env:APPDATA\Mihrab") { throw "settings left at $env:APPDATA\Mihrab" }
if (Test-Path "$env:USERPROFILE\scoop\apps\mihrab") { throw "still installed after uninstall" }
if (Test-Path $lnk) { throw "the shortcut outlived the app" }
Write-Host "installed, started and removed: OK"
