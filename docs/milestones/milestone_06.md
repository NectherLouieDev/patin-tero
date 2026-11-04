# Milestone 6 — Dual-Arena Match and Results

Status: implemented and headless checks passed; awaiting developer playtest.

## Deliverable

Open `res://scenes/debug/match_test.tscn`. The scene contains two persistent 3D arenas with scene-tree tile and unit meshes and the approved camera transform. The scenario menu offers prepared 2–0, 1–1, and 0–2 locked snapshot fixtures. Start, Pause, Step tick, Reset, and playback speed controls are visible.

## Manual acceptance

1. Choose 2–0 and press Start. Arena B should finish with a guard win earlier; the match result should remain pending until Arena A finishes its round trip. Final score should be 2–0 for A.
2. Reset, choose 1–1, and run. Both offensive runners should complete round trips. Final score should be 1–1.
3. Reset, choose 0–2, and run. Arena A should finish with a guard win earlier; final score should be 0–2 for A–B after Arena B finishes.
4. Use Pause and Step tick to inspect independent arena ticks and results. Both arena views should remain in place.
5. Run the same fixture twice with Reset. The displayed repeatability check should say MATCH. Repeat at 0.5x and 4x and confirm the score and completion ticks match.

## Automated result

Godot 4.7.1 launched the scene headlessly. `godot --headless --path . --script res://tests/match/run_tests.gd` passed 26 checks with zero failures across all three scores, arena isolation, waiting for both results, one-time finalization, replay agreement, speed-independent outcomes, and scene persistence.

## Known limitations

- Match scenarios are locked test fixtures, not the player's saved planning scene. The data format accepts snapshots from `PlanningModel`, but final card content and runner return rules are still unresolved.
- Runners use the provisional return command and guards use simple stationary fixtures. There is no timeout or draw rule yet.
- Visual movement is interpolated from logical positions. Its appearance and the UI still require developer playtesting in the Godot window.
