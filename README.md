# Run Claude Code and Codex agents in parallel on one Unity project

A practical setup for running several AI coding agents (Claude Code, OpenAI Codex, or both) on the same Unity project at once, without broken scenes, GUID conflicts or a stalled "manager" agent. Scripts for Windows (PowerShell) and macOS/Linux (bash), an agent rules template, a plan template and a headless build entry point.

> **Short answer.** Give every script job its own Git worktree. Decide which folders each agent owns before it starts. Let only one agent at a time touch scenes, prefabs and shared assets. Check every job with headless tests and a real build. Have the work reviewed by a different model than the one that wrote it. Do not put a single manager agent in the middle of everything.

This repo is the do-it-yourself version. [Mirven](https://mirven.app) is a desktop app that does all of it for you (see [the end](#doing-it-by-hand-vs-with-mirven)).

---

## What goes wrong when agents share a Unity project

| Problem | Why it happens |
|---|---|
| **Scenes and prefabs collide** | Unity stores scenes, prefabs and many assets as large YAML files. Two agents editing the same scene produce conflicts that a text merge cannot resolve safely, even with Smart Merge. |
| **.meta files and GUIDs drift** | Every asset has a `.meta` file with a GUID that other assets reference. Two branches creating or moving the same asset end up with different GUIDs, and references break after the merge. |
| **One editor per folder** | The Unity Editor locks a project folder while it is open. Agents cannot build or test in the same open project at the same time. |
| **The manager agent stalls** | The usual multi-agent setup has one orchestrator that hands out work and reads every report. Its context fills with everyone's news until it forgets, repeats itself and stops. |
| **"Done" is not done** | An agent reporting success is a claim. Without a compile, tests and a build, broken code reaches main. |

## The setup

### 1. Make the project mergeable

- **Project Settings → Editor → Asset Serialization:** `Force Text`
- **Project Settings → Version Control → Mode:** `Visible Meta Files`
- Commit every `.meta` file together with its asset.
- Use [`templates/unity.gitignore`](templates/unity.gitignore) so `Library/`, `Temp/`, `Logs/` and `UserSettings/` stay out of Git.

### 2. One Git worktree per script job

A worktree is a second working folder on its own branch, sharing the same repository. Each agent gets its own folder and branch.

```bash
# bash (macOS / Linux / Git Bash)
scripts/new-agent-worktree.sh combat-parry main
COPY_LIBRARY=1 scripts/new-agent-worktree.sh boss-phase2 main   # reuse Library/ to skip most of the reimport
```

```powershell
# PowerShell (Windows)
.\scripts\new-agent-worktree.ps1 -Job combat-parry -Base main
.\scripts\new-agent-worktree.ps1 -Job boss-phase2 -Base main -CopyLibrary
```

This creates `../<repo>-combat-parry` on branch `agent/combat-parry`. Start the agent in that folder.

Each worktree is a separate Unity project folder with its own `Library/`, so its first open or batchmode run reimports assets. On a big project that costs time and disk. Copying `Library/` from the main checkout (same Unity version) usually saves most of it. Remove finished worktrees with `git worktree remove`.

### 3. Decide who owns which folders, before anyone starts

Write the plan down: for each job, the folders it will touch and what "done" means. Two jobs that own the same folder never run at the same time. See [`docs/plan-template.md`](docs/plan-template.md).

Put the rules in front of every agent with [`templates/AGENTS.md`](templates/AGENTS.md) (copy it as `CLAUDE.md` too, for Claude Code). It tells the agent which folders it owns, to leave scenes and `.meta` files alone, and to run the check before claiming it is done.

Assembly definitions (`.asmdef`) per feature folder help further: a change in one area stops forcing recompiles and errors in another.

### 4. Scenes, prefabs and shared assets take turns

Run script jobs in parallel. Give scene, prefab and shared-asset work a single lane in the main checkout, one job at a time. Splitting levels into additive scenes and building with small prefabs means jobs wait on each other less.

When a scene merge is unavoidable, use Unity Smart Merge. Add [`templates/unity.gitattributes`](templates/unity.gitattributes) as `.gitattributes`, then register the driver once per machine:

```bash
git config merge.unityyamlmerge.name "Unity SmartMerge (UnityYamlMerge)"
git config merge.unityyamlmerge.driver "'<UNITY_EDITOR_DIR>/Data/Tools/UnityYAMLMerge' merge -h -p --force %O %B %A %A"
git config merge.unityyamlmerge.recursive binary
```

On Windows `<UNITY_EDITOR_DIR>` is something like `C:/Program Files/Unity/Hub/Editor/<version>/Editor` and the tool is `UnityYAMLMerge.exe`. On macOS it is inside `Unity.app/Contents/Tools/`.

### 5. Check every job with a real build

Run checks headless, in the job's own worktree, while no editor has that folder open:

```bash
UNITY="/Applications/Unity/Hub/Editor/<version>/Unity.app/Contents/MacOS/Unity" \
  scripts/unity-check.sh ../mygame-combat-parry all
```

```powershell
.\scripts\unity-check.ps1 -Project ..\mygame-combat-parry -Unity "C:\Program Files\Unity\Hub\Editor\<version>\Editor\Unity.exe"
```

It runs EditMode tests, PlayMode tests and a player build, writes results to `<project>/Logs/agent-check/` and exits non-zero if anything fails. For the build step, copy [`unity/Assets/Editor/AgentBuild.cs`](unity/Assets/Editor/AgentBuild.cs) into your project's `Assets/Editor/`.

A job is done when this passes. Send a failed check back to the same agent with the error first.

### 6. Review with a different model

A model reviewing its own code tends to approve it. Have Codex review what Claude Code wrote and the other way round. Merge only after a person has read the result.

### 7. Replace the manager with a plan

Instead of one agent reading every report, give each agent only its job, its folders, its finish line and the few project notes it needs. Coordination lives in the written plan, where you can read it, not in one model's context window.

## What's in this repo

```
scripts/new-agent-worktree.sh|.ps1   create a worktree + branch per job, optionally reuse Library/
scripts/unity-check.sh|.ps1          headless EditMode + PlayMode tests + player build, one exit code
unity/Assets/Editor/AgentBuild.cs    -executeMethod build entry point (exit 0/1)
templates/AGENTS.md                  rules to give every agent (also as CLAUDE.md)
templates/unity.gitignore            Unity ignores, per-checkout folders out of Git
templates/unity.gitattributes        Smart Merge for scenes/prefabs, binaries never text-merged
docs/plan-template.md                job table: owned folders, finish line, lane, reviewer
```

## FAQ

**Can Claude Code and Codex work on the same Unity project at the same time?**
Yes, if each works in its own worktree on its own folders, and scene work takes turns. Use one to review the other.

**How many agents can run at once?**
As many as your disk, CPU and plan limits allow. Every worktree is a full Unity project folder, and every headless check starts its own editor process.

**Do I need Unity Pro for batchmode?**
Batchmode and `-runTests` work with any Unity license that can open the project on that machine.

**Why not one big agent with subagents?**
That works for small changes. On a game project, the orchestrator's context fills with reports, and subagents still need folder ownership and scene rules to avoid colliding.

## Doing it by hand vs with Mirven

Everything above works with plain Git, Claude Code, Codex and these scripts. **[Mirven](https://mirven.app) is an AI game studio for Unity that does it for you:** you describe what the game needs, Astra (its planner) turns it into jobs with owned folders and finish lines, script jobs run in their own worktrees, scene and asset jobs take turns, every job is checked with tests, a real Unity build and a review by a model that did not write it, project memory gives each job only the notes it needs, and nothing merges until you say yes. It runs on your own machine with your own Claude Code or Codex account. Free private beta: [mirven.app/beta](https://mirven.app/beta).

Full guide: [mirven.app/guides/parallel-agents-unity](https://mirven.app/guides/parallel-agents-unity) · FAQ: [mirven.app/faq](https://mirven.app/faq)

## License

MIT
