# Milestone 3 — 3D Arena and Deployment

Status: implemented and headless checks passed; awaiting developer visual playtest.

## Deliverable

Open `res://scenes/debug/deployment_test.tscn`. Two 4 × 8 3D arenas and their mesh anchors are authored in the scene tree. The fixed camera uses the exact transform and field of view from `simulation_test.tscn`, as the camera reference for future scenes. The left arena is player offense; the right arena is player defense.

## Manual acceptance

1. Select a TEST runner in the bench and drag it to a yellow cell on offense row 0. Expect its green mesh and `[DEPLOYED: offense]` label.
2. Drag a horizontal guard to a yellow cell on defense row 2, 4, or 6. Expect its red mesh and defense label.
3. Drag a center guard to the yellow marker between columns 1 and 2 on defense row 3. Expect a red mesh on the center line.
4. Drag a runner to a non-anchor or a guard into the offense arena. Expect an invalid-drop message and the previous placement retained.
5. Select a deployed character and press Return selected. Expect its mesh to disappear and its bench label to clear.
6. Select any character. Expect its three test card sequences in the preview.
7. Deploy at least one runner and one guard, then press Start battle. Expect both arena nodes to stay visible while their tick/result labels advance. Deployment controls become disabled during battle.

## Automated result

Godot 4.7.1 launched the scene headlessly. `godot --headless --path . --script res://tests/formation/run_tests.gd` passed 13 checks with zero failures, covering anchors, limits, invalid placement preservation, bench return, arena existence, and battle persistence.

## Known limitations

- Final center guard geometry and battle fixture policy require approval; see `docs/decisions/gameplay_decisions.md`.
- The camera follows the transform approved from `simulation_test.tscn`.
- Drag interaction and visual legibility need developer playtesting in the Godot window. Opponent formations and richer battle UI belong to later work.
