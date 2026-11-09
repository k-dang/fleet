# Links fleet's worker templates into hc's config folder. A link, not a copy,
# so edits in this repo apply at once. install.sh is the macOS/Linux version.
$ErrorActionPreference = "Stop"

$hcConfig = Join-Path $env:APPDATA "herdr-core"
$path = Join-Path $hcConfig "templates"
$target = Join-Path $PSScriptRoot "herdr-core/templates"

$item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
if ($item) {
    if (-not $item.LinkType) {
        throw "$path exists and is not a link; move it aside and rerun."
    }
    if ([IO.Path]::GetFullPath($item.Target) -eq [IO.Path]::GetFullPath($target)) {
        Write-Host "ok      $path"
        return
    }
    Remove-Item -LiteralPath $path -Force
}
New-Item -ItemType Directory -Path $hcConfig -Force | Out-Null
New-Item -ItemType Junction -Path $path -Target $target | Out-Null
Write-Host "linked  $path -> $target"
