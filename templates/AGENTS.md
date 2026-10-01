# Rules for coding agents in this Unity project

Drop this file in your repo root (also as CLAUDE.md for Claude Code). Fill in the folder table per job.

## Your job
- Job: <one sentence>
- Done when: <a check anyone can run, e.g. "EditMode tests in Combat.Tests pass and the player build succeeds">
- Folders you own: <e.g. Assets/Scripts/Combat/, Assets/Tests/Combat/>
- Folders you may read but not change: everything else

## Hard rules
1. Change files only inside the folders you own. If you need a change elsewhere, stop and write it in your report.
2. Do not open, create or edit scenes (*.unity), prefabs (*.prefab) or shared assets unless this job owns them.
   Scene and prefab work runs one job at a time.
3. Every new or moved asset keeps its .meta file. Never delete or regenerate a .meta file. Commit them together.
4. Do not touch ProjectSettings/, Packages/manifest.json or assembly definitions you do not own.
5. Before you say "done", run: scripts/unity-check.sh <this worktree> all   (or unity-check.ps1)
   Paste the result. A job is done when the check passes, not when you think it works.
6. Commit on your own branch only. Never merge, rebase or push to main.

## Report
- What changed (files)
- Check result (paste)
- Anything you needed outside your folders
