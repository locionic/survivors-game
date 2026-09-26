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
# Queue Milestone 1 task:
fcc-task add "Implement 20-wave arena director and intermission shop UI" \
  --cwd "/home/renovibe79/survivors-game" \
  --title "Milestone 1: Wave Arena Director"

# List queued and active tasks:
fcc-task list

# Execute the next pending task:
fcc-task run-once

# Run the continuous 24/7 autonomous loop:
fcc-task daemon
```

---

## 3. Automated Quality Gate
Whenever `fcc-task` runs, it:
1. Validates `/home/renovibe79/survivors-game` working tree.
2. Creates branch `agent/task-<id>`.
3. Runs the prompt with `fcc-bunny`.
4. Runs tests (if available, e.g. `godot --headless -s tests/...`).
5. If GREEN: Commits to the branch and marks `completed`.
6. If RED: Automatically feeds errors back to Claude Code for up to 3 retry attempts. If still failing, cleanly reverts working changes to protect the codebase.
