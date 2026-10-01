# Create a Git worktree + branch for one agent job, next to your Unity project.
#
# Usage:  .\scripts\new-agent-worktree.ps1 -Job combat-parry [-Base main] [-CopyLibrary] [-ProjectSubdir .]
param(
  [Parameter(Mandatory = $true)][string]$Job,
  [string]$Base = "HEAD",
  [switch]$CopyLibrary,
  [string]$ProjectSubdir = "."
)
$ErrorActionPreference = "Stop"

$root = (git rev-parse --show-toplevel).Trim()
$dest = Join-Path (Split-Path $root -Parent) ("{0}-{1}" -f (Split-Path $root -Leaf), $Job)
$branch = "agent/$Job"

git -C $root worktree add -b $branch $dest $Base
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$lib = Join-Path (Join-Path $root $ProjectSubdir) "Library"
if ($CopyLibrary -and (Test-Path $lib)) {
  Write-Host "Copying Library/ (Unity revalidates it on open; delete it if the editor complains)..."
  Copy-Item $lib (Join-Path (Join-Path $dest $ProjectSubdir) "Library") -Recurse
}

Write-Host ""
Write-Host "Worktree: $dest"
Write-Host "Branch:   $branch"
Write-Host "Point the agent at: $(Join-Path $dest $ProjectSubdir)"
Write-Host "Remove when merged: git worktree remove `"$dest`"; git branch -d $branch"
