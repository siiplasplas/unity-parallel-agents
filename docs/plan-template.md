# Plan: <milestone>

Write this before any agent starts. Two jobs that own the same folder never run at the same time.

| # | Job | Owns (folders) | Done when | Lane | Depends on | Agent | Reviewer |
|---|-----|----------------|-----------|------|------------|-------|----------|
| 1 | Parry window tuning | Assets/Scripts/Combat/Parry/, Assets/Tests/Combat/ | Window 180 ms, 90 ms on hard; EditMode tests pass | script (worktree) | none | Claude Code | Codex |
| 2 | Boss phase 2 AI | Assets/Scripts/Boss/ | Phase 2 triggers at 50% HP; tests pass; build passes | script (worktree) | none | Codex | Claude Code |
| 3 | Arena collapsing floor | Assets/Scenes/Arena.unity, Assets/Prefabs/Arena/ | 5 tiles fall in order, no softlock in PlayMode test | scene (one at a time) | 2 | Claude Code | Codex |

Lanes:
- **script (worktree)**: runs in parallel, one Git worktree per job.
- **scene (one at a time)**: scenes, prefabs, shared assets. Runs in the main checkout, one job after another.

Reviewer is always a different model than the agent that wrote the job.
