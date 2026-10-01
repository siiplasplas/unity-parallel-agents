# Check one agent's worktree headless: EditMode tests, PlayMode tests and a player build.
# A job is done when this passes, not when the agent says so.
#
# Usage:  .\scripts\unity-check.ps1 -Project ..\mygame-combat [-Check all|editmode|playmode|build] [-Unity "C:\...\Unity.exe"]
#   -Unity defaults to $env:UNITY. Use the editor version the project uses.
#   The project must not be open in an editor at the same time (Unity locks the folder).
#   "build" needs AgentBuild.cs in the project's Assets/Editor/ folder (see unity/Assets/Editor).
#
# Exit code: 0 = everything passed, 1 = something failed. Logs and results: <project>\Logs\agent-check\
param(
  [Parameter(Mandatory = $true)][string]$Project,
  [ValidateSet("all", "editmode", "playmode", "build")][string]$Check = "all",
  [string]$Unity = $env:UNITY
)
if (-not $Unity) { Write-Error "Set -Unity or `$env:UNITY to the Unity editor executable"; exit 2 }
if (-not (Test-Path $Unity)) { Write-Error "Unity editor not found: $Unity"; exit 2 }
$Unity = (Resolve-Path $Unity).Path
$proj = (Resolve-Path $Project).Path
$out = Join-Path $proj "Logs\agent-check"
New-Item -ItemType Directory -Force $out | Out-Null
$script:failed = 0

# Unity.exe is a GUI app: PowerShell does not wait for it unless we use Start-Process -Wait.
function Invoke-Unity([string[]]$UnityArgs) {
  $quoted = $UnityArgs | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }
  (Start-Process -FilePath $Unity -ArgumentList ($quoted -join ' ') -Wait -PassThru -NoNewWindow).ExitCode
}

function Test-Platform([string]$Platform) {
  Write-Host "== $Platform tests"
  $code = Invoke-Unity @("-batchmode", "-projectPath", $proj, "-runTests", "-testPlatform", $Platform,
    "-testResults", (Join-Path $out "$Platform-results.xml"), "-logFile", (Join-Path $out "$Platform.log"))
  switch ($code) {
    0 { Write-Host "   passed" }
    2 { Write-Host "   FAILED: some tests failed, see $out\$Platform-results.xml"; $script:failed = 1 }
    default { Write-Host "   ERROR: tests did not run, see $out\$Platform.log"; $script:failed = 1 }
  }
}

function Test-Build {
  Write-Host "== player build"
  $code = Invoke-Unity @("-batchmode", "-quit", "-projectPath", $proj, "-executeMethod", "AgentBuild.Build",
    "-buildPath", (Join-Path $out "build"), "-logFile", (Join-Path $out "build.log"))
  if ($code -eq 0) { Write-Host "   passed" } else { Write-Host "   FAILED: see $out\build.log"; $script:failed = 1 }
}

switch ($Check) {
  "editmode" { Test-Platform "EditMode" }
  "playmode" { Test-Platform "PlayMode" }
  "build"    { Test-Build }
  "all"      { Test-Platform "EditMode"; Test-Platform "PlayMode"; Test-Build }
}
exit $script:failed
