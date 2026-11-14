# Copies fleet's worker templates into hc's templates folder, where they are
# this machine's to edit, such as a command: line naming its models. Rerun
# after the repo's templates change: a copy you have not edited is replaced,
# and one you have gets the repo's changes merged in (git merge-file), against
# the version this install last copied, kept in .fleet\. install.sh is the
# macOS/Linux version.
$ErrorActionPreference = "Stop"

$repo = Join-Path $PSScriptRoot "herdr-core/templates"
$path = Join-Path $env:APPDATA "herdr-core/templates"
$base = Join-Path $path ".fleet"

function Same($a, $b) {
    (Test-Path -LiteralPath $a) -and (Test-Path -LiteralPath $b) -and
        ((Get-FileHash -LiteralPath $a).Hash -eq (Get-FileHash -LiteralPath $b).Hash)
}

# An earlier install linked the whole folder to the repo. Delete() removes
# only the link.
$item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
if ($item -and $item.LinkType) { $item.Delete(); $item = $null }
if ($item -and -not (Test-Path -LiteralPath $base)) {
    throw "$path exists and was not written by fleet; move it aside and rerun."
}
New-Item -ItemType Directory -Path $base -Force | Out-Null

$conflicts = 0
foreach ($src in Get-ChildItem -LiteralPath $repo -Filter *.md -File) {
    $dest = Join-Path $path $src.Name
    $old = Join-Path $base $src.Name
    if (-not (Test-Path -LiteralPath $dest) -or -not (Test-Path -LiteralPath $old)) {
        Copy-Item -LiteralPath $src.FullName -Destination $dest -Force
        Write-Host "added    $dest"
    } elseif (Same $src.FullName $old) {
        Write-Host "ok       $dest"
        continue
    } elseif (Same $dest $old) {
        Copy-Item -LiteralPath $src.FullName -Destination $dest -Force
        Write-Host "updated  $dest"
    } else {
        git merge-file -L "this machine" -L "last install" -L "repo" $dest $old $src.FullName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "merged   $dest"
        } else {
            Write-Warning "CONFLICT $dest: resolve the <<<<<<< markers by hand"
            $conflicts = 1
        }
    }
    Copy-Item -LiteralPath $src.FullName -Destination $old -Force
}

# Templates the repo no longer has.
foreach ($old in Get-ChildItem -LiteralPath $base -Filter *.md -File) {
    if (Test-Path -LiteralPath (Join-Path $repo $old.Name)) { continue }
    $dest = Join-Path $path $old.Name
    if (Same $dest $old.FullName) {
        Remove-Item -LiteralPath $dest
        Write-Host "removed  $dest"
    } elseif (Test-Path -LiteralPath $dest) {
        Write-Host "kept     ${dest}: the repo dropped it, but it was edited here; delete it if unneeded"
    }
    Remove-Item -LiteralPath $old.FullName
}
exit $conflicts
