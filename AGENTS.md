# Team Playbook: SurvivorQuest: Huyền Thoại Võ Lâm

This repository operates with a dedicated 4-member autonomous development team: **Planner**, **Designer**, **Dev**, and **Tester**. Both Claude Code (`.claude/agents/`) and GitHub Copilot CLI (`.github/agents/`) recognize these roles.

---

## 👥 The Team

| Role | Agent Name | Title | Primary Responsibility |
|:---|:---|:---|:---|
| **Planner** | `planner` | Combat & Roguelike System Designer | Plans wave progression, weapon upgrade branches, martial arts sect balance, and milestone roadmaps. |
| **Designer** | `designer` | Wuxia Visual & Juice Designer | Designs Ba Lang Huyen props, lacquer HUD weapon/relic slots, boss gong alerts, and XP gem arcs. |
| **Developer** | `dev` | Combat Systems Developer | Implements GDScript combat logic, player movement, mob AI, wave spawning director, and upgrade mechanics. |
| **Tester** | `tester` | CI & Integration QA Engineer | Maintains ./scripts/ci.sh, GUT unit/integration tests, flake elimination, and regression protection. |

---

## 🔄 Collaboration & Handoff Workflow

```text
[1. Planner]  ──> Feature Spec & Task Breakdown (Scoping)
      │
[2. Designer] ──> UI/UX Layout, Aesthetics & Visual Polish
      │
[3. Dev]      ──> Clean Code Implementation (Minimal Diffs)
      │
[4. Tester]   ──> Gate Verification via `./scripts/ci.sh`
```

### 1. Planner (`planner`)
- Breaks milestones into atomic tasks (1-3 files each).
- Defines explicit acceptance criteria and edge cases.
- Hands off a clear specification to Designer and Dev.

### 2. Designer (`designer`)
- Establishes UI structure, layout hierarchy, and aesthetic details.
- Defines visual effects, color palettes, animations, and feel.
- Ensures design consistency across all screens/scenes.

### 3. Developer (`dev`)
- Implements the feature or bugfix matching the spec.
- Keeps diffs minimal: does not touch whitespace or unrelated files.
- Never commits secrets or modifies forbidden config.

### 4. Tester (`tester`)
- Verifies the implementation against acceptance criteria.
- Executes `./scripts/ci.sh` to verify green build & tests.
- Reverts or reports regressions immediately if tests fail.

---

## 🚀 How to Run Team Tasks

### With GitHub Copilot CLI
```bash
# Run with a specific role
copilot --agent planner -p "Decompose next milestone into atomic tasks"
copilot --agent designer -p "Review and improve UI layout and visual polish"
copilot --agent dev -p "Implement task specification"
copilot --agent tester -p "Verify test coverage and run ./scripts/ci.sh"
```

### With Claude Code CLI
```bash
claude --agent planner -p "Plan the next feature"
claude --agent dev -p "Implement the requested change"
```

### With `fcc-task` / Autonomous Loop
```bash
fcc-task add "[Planner] Plan the next feature" --cwd . --agent planner
fcc-task add "[Designer] Polish UI and visual juice" --cwd . --agent designer
fcc-task add "[Dev] Implement feature logic" --cwd . --agent dev
fcc-task add "[Tester] Verify gate and hunt test flakes" --cwd . --agent tester
```

---

## 🛡️ Quality Gate
- **Command**: `./scripts/ci.sh`
- Every task must pass this command with exit code 0 before being merged or considered complete.
