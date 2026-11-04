# Milestone 9 — Player-Facing UI

Status: implemented; automated checks passed; awaiting developer playtest.

## Deliverable

The configured main scene is `res://scenes/main/game.tscn`. Press Play Project in Godot to enter tournament setup. Its two 4×8 arenas, camera, placeholder units, and controls are authored as scene nodes. The camera uses the approved transform from `simulation_test.tscn`.

The interface follows setup → shop and roster → formation → live two-arena battle → match results → standings → next stage or champion. A fresh tournament returns to setup and clears the prior tournament state. Mouse controls and Godot's standard keyboard focus navigation are available; Space runs or pauses battle. The UI invokes `TournamentModel` and `SharedSession` public actions and reads their state for display.

## Manual acceptance

1. Open the project and press Play Project. Enter seed 42 and Start Tournament. Confirm five offers, two starter units, 20 coins, and eight participants.
2. Press Buy Selected without an offer. Confirm a clear selection message and unchanged coins. Select an offer and buy it; confirm roster and coins update. Reroll and confirm five new offers and the two-coin cost.
3. Open formation planning. Select the starter runner and deploy to Offense `(1, 0)`; select the guard and deploy to Defense `(1, 4)`. Confirm meshes appear on the two boards. Try to place the runner on Defense and verify rejection without changing its placement.
4. Select card 1 for a one-star unit and Equip Card. Confirm the capacity rejection and unchanged cards. Lock Formation. Confirm battle starts and both arenas remain visible.
5. Pause with Space, Step one tick, then resume. Confirm ticks and unit positions advance. At the result, inspect the score and both arena outcomes. Continue through every pairing to standings.
6. Advance through 8 → 6 → 4 → 2 → 1. Confirm the championship shop is closed, one champion appears, and New Tournament resets the stage, balance, roster, and results.
7. Use Tab, Shift+Tab, Enter, and arrow keys to complete the setup, shop, and formation controls without a mouse. At 1280×720, confirm labels and primary actions remain readable.

## Automated validation

Godot 4.7.1 launched the configured main scene headlessly. `res://tests/ui/run_flow_tests.gd` passed the complete tournament path and checks for invalid purchase and placement, authoritative balance and roster changes, card rejection, persistent scene-tree arenas, the approved camera transform, and fresh-tournament reset. Existing simulation, roster, shared-session, economy, formation, match, and tournament runners also passed with zero failures.

## Known limitations

- Non-player teams use the deterministic bot policy documented in Milestone 7. The later Section 2 playable-loop update added a provisional runner turnaround, income, rewards, and shop refresh; final values and rules remain open.
- This milestone offers a readable functional interface. Replay controls, settings, broader resolution checks, and visual polish belong to Milestone 10.
- Battle uses the approved 50 ms logical tick. The interface updates visuals at this rate without changing simulation logic.
