# Project Guidelines & Team Routing: SurvivorQuest: Huyền Thoại Võ Lâm

## Verification Command
```bash
./scripts/ci.sh
```
Always run `./scripts/ci.sh` to verify changes. An exit code 0 is required for all tasks.

## Team Roles & Agents
This project has configured team roles located in `.claude/agents/` and `.github/agents/`:
- **`planner`**: Combat & Roguelike System Designer - Scope features and milestones.
- **`designer`**: Wuxia Visual & Juice Designer - UI/UX, styling, animations, and game feel.
- **`dev`**: Combat Systems Developer - Core systems code and bug fixes.
- **`tester`**: CI & Integration QA Engineer - Quality gate validation and test cases.

Consult `AGENTS.md` for full role details and handoff conventions.
