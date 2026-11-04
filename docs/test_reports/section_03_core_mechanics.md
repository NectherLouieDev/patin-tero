# Section 3 core mechanics validation

Godot: 4.7.1 stable. Validation ran headless on the main scene and the test runners.

## Automated results

- `tests/simulation/run_tests.gd` — pass
- `tests/economy/run_tests.gd` — pass
- `tests/roster/run_tests.gd` — pass
- `tests/roster/run_shared_session_tests.gd` — pass
- `tests/formation/run_tests.gd` — pass
- `tests/formation/run_planning_tests.gd` — pass
- `tests/match/run_tests.gd` — pass
- `tests/tournament/run_tests.gd` — pass
- `tests/bots/run_tests.gd` — pass
- `tests/loop/run_tests.gd` — pass
- `tests/ui/run_flow_tests.gd` — pass

The simulation test initially failed because its older round-trip fixture used runner `U`. The fixture was updated to repeat `F` with automatic facing reversal. Simulation, match, and UI tests passed after the correction. The editor scan completed with exit code 0 but printed a Windows safe-save warning while writing editor state; no script parse error appeared. The main scene also launched headlessly.

## Manual acceptance pending

Open `res://scenes/main/game.tscn` in Godot and verify the two boards, drag and command-path preview, countdown, movement and heading cues, pause/step/resume, tag and special-command colors, and results-to-championship flow. The developer has not yet confirmed the visual and gameplay acceptance checks.
