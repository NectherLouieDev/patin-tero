# Milestone 5 — Formation Planning and Lock

Status: implemented and automated checks passed; awaiting developer playtest.

## Deliverable

Open `res://scenes/debug/planning_test.tscn`. It retains the two 3D arena views, fixed reference camera, bench, and visible anchors from Milestone 3. Its planning panel adds star level, card selection/order, formation lock, and snapshot inspection.

## Manual acceptance

1. Select a runner and drag it onto offense row 0. Select a guard and drag it onto a valid defense anchor. Both should appear in their arenas.
2. Drag a runner to defense, another runner onto an occupied anchor, and a fourth runner onto offense. Each invalid action should report rejection and preserve previous placements.
3. Select the runner, set two stars, select card 2, and press Equip. Select card 2 and press Earlier. Its displayed order should become #1.
4. At one star, attempt to equip a second card. Expect a capacity rejection. Attempt a duplicate or invalid reorder and expect rejection.
5. Select either unit and inspect its three placeholder card sequences. Press Lock formation with both offense and defense populated.
6. Confirm the snapshot lists units, anchors, star levels, and ordered card IDs. Try to drag, return, or edit cards after lock; the snapshot and arena placements should remain unchanged.
7. Restart the scene, press Lock formation with no deployments, and confirm it explains why locking is rejected.

## Automated result

Godot 4.7.1 launched the scene headlessly. `godot --headless --path . --script res://tests/formation/run_planning_tests.gd` passed 16 checks with zero failures, including ownership, anchors, card capacity/order, lock validation, snapshot deep-copy behavior, and both arenas remaining present.

## Known limitations

- The planning scene uses nine test-owned placeholder units. Shop purchases and merge inheritance are not yet connected to it.
- Center-line geometry and the minimum lock composition are provisional; see `docs/decisions/gameplay_decisions.md`.
- Mouse drag behavior and layout still require developer visual playtesting. Lock captures a battle snapshot; the dual-arena match flow is Milestone 6.
