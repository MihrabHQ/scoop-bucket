# Point bucket/mihrab.json at Mihrab's latest release, once its Windows
# installers are attached (they arrive some forty minutes after the tag).
# Prints "updated <version>" when it changed the manifest, nothing otherwise.
$ErrorActionPreference = 'Stop'
$path = Join-Path $PSScriptRoot '..\bucket\mihrab.json'
$m = Get-Content $path -Raw | ConvertFrom-Json

$headers = @{ 'User-Agent' = 'mihrab-scoop-bucket' }
if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
$rel = Invoke-RestMethod -Headers $headers 'https://api.github.com/repos/MihrabHQ/Mihrab/releases/latest'
$version = $rel.tag_name -replace '^v', ''
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "unexpected tag $($rel.tag_name)" }
if ([version]$version -le [version]$m.version) { return }

$want = @{ '64bit' = "Mihrab-$version-win-x64.exe"; 'arm64' = "Mihrab-$version-win-arm64.exe" }
foreach ($arch in $want.Keys) {
    if (-not ($rel.assets | Where-Object name -eq $want[$arch])) {
        Write-Host "$($rel.tag_name) has no $($want[$arch]) yet; trying again later"
        return
    }
}

$tmp = New-Item -ItemType Directory -Force (Join-Path ([IO.Path]::GetTempPath()) 'mihrab-scoop')
foreach ($arch in $want.Keys) {
    $url = "https://github.com/MihrabHQ/Mihrab/releases/download/v$version/$($want[$arch])"
    $file = Join-Path $tmp $want[$arch]
    Invoke-WebRequest -Uri $url -OutFile $file -Headers @{ 'User-Agent' = 'mihrab-scoop-bucket' }
    $m.architecture.$arch.url = "$url#/dl.7z"
    $m.architecture.$arch.hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
}
$m.version = $version
# Scoop's own buckets use four spaces; ConvertTo-Json writes two, so widen it.
$json = ($m | ConvertTo-Json -Depth 10) -replace '(?m)^((?:  )+)', '$1$1'
[IO.File]::WriteAllText((Resolve-Path $path), $json + "`n", [Text.UTF8Encoding]::new($false))
"updated $version"
