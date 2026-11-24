# Mihrab for Scoop

[Mihrab](https://mihrab.elghamri.se) — prayer times, the adhan, the Madinah
muṣḥaf and a prayer journal; open source, no ads, no account — for Windows,
through [Scoop](https://scoop.sh).

```powershell
scoop bucket add mihrab https://github.com/MihrabHQ/scoop-bucket
scoop install mihrab/mihrab
```

Update with `scoop update mihrab`; remove with `scoop uninstall mihrab`.
Mihrab keeps its settings in `%APPDATA%\Mihrab`, which an uninstall leaves;
delete that folder as well to remove them:

```powershell
scoop uninstall mihrab; Remove-Item -Recurse "$env:APPDATA\Mihrab"
```

## How it stays current

`bucket/mihrab.json` points at the Windows installers attached to
[Mihrab's releases](https://github.com/MihrabHQ/Mihrab/releases). Every hour
`update.yml` looks for a newer release whose installers are attached, points
the manifest at it, installs, starts and removes it on a Windows runner, and
pushes only if all of that worked. `ci.yml` does the same install test on
every push.

The installers are not code-signed, but Scoop never runs them: it unpacks
the app from them, so Windows SmartScreen does not come into it. Other ways
to install Mihrab on Windows — the Microsoft Store, `winget` and the
installer itself — are on [the website](https://mihrab.elghamri.se/#install).

Mihrab is licensed under the AGPL-3.0-or-later; this bucket under the same.
