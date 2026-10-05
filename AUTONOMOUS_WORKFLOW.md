# 24/7 Autonomous Game Development Workflow with Claude Code (`fcc-bunny`)

This document outlines how autonomous agents (Antigravity & Claude Code) develop, test, and iterate on **SurvivorQuest: Huyền Thoại Võ Lâm** 24/7 with zero Antigravity token burn.

---

## 1. Core Architecture

- **Orchestrator**: Antigravity (Architect / Game Designer)
- **Heavy Executor**: Claude Code running via local Free Claude Code proxy on model `anthropic/opencode/space-bunny-free` ($0 cost, 0 session tokens)
- **Daemon & Task Queue**: `fcc-task` backed by SQLite WAL database (`~/.fcc/autonomous_tasks.db`)
- **Isolation**: Each task runs in an isolated Git branch (`agent/task-<id>`) with automated rollback if broken.

---

## 2. Quick Command Reference

### Run a Single Direct Task with Claude Code
```bash
fcc-bunny "Refactor scripts/player.gd to support 6 simultaneous weapon slots"
```

### Queue Tasks for Autonomous 24/7 Execution
```bash
# Queue Milestone 1 task. --cwd is derived at run time; this used to read
# /home/renovibe79/survivors-game, which resolved only on the machine that
# wrote it and failed on every other host.
fcc-task add "Implement 20-wave arena director and intermission shop UI" \
  --cwd "$(pwd)" \
  --title "Milestone 1: Wave Arena Director"

# List queued and active tasks:
fcc-task list

# Execute the next pending task:
fcc-task run-once

# Run the continuous 24/7 autonomous loop:
fcc-task daemon
```

`fcc-task` and `fcc-bunny` are implemented in the `agent-copilot` repo. Until
this document was reconciled with what exists, they were named here and
implemented nowhere, so every command above was aspirational.

---

## 3. Automated Quality Gate
Whenever `fcc-task` runs, it:
1. Validates the target working tree. A dirty git tree is **refused**, not stashed —
   a stash that outlives the task is a change nobody will remember to pop.
2. Creates branch `agent/task-<id>`. In a directory that is not a git repo it takes
   a file snapshot instead and restores from it on failure.
3. Runs the prompt with `fcc-bunny`.
4. Runs the repo's own test runner, probing `run_tests.sh`, `scripts/ci.sh`, and
   `ci.sh`. It refuses the task outright if none is found: no suite means no gate,
   and work that cannot be gated should not be done by something nobody is watching.
5. If GREEN: Commits to the branch and marks `completed`.
6. If RED: Automatically feeds errors back to Claude Code for up to 3 retry attempts. If still failing, cleanly reverts working changes to protect the codebase.

The daemon never pushes. Merging is a human decision made with the tests already
run — the one part of this that stays manual.
