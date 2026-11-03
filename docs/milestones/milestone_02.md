# Milestone 2 — Character and Moveset Data

Status: implemented and automated checks passed; awaiting developer playtest.

## Scope and deliverable

Open `res://scenes/debug/moveset_test.tscn`. The scene loads nine data definitions from `resources/characters/test_roster.json`: four runners, three horizontal guards, and two center guards. Each has three four-command test cards. All names and sequences are visibly marked as placeholders.

## Manual acceptance

1. Select all nine characters. Confirm role, placeholder status, and three card sequences appear.
2. At one star, select card 2 and press Equip. Expect `REJECTED: Card capacity reached`.
3. Set two stars, equip card 2, then try it again. Expect the first action accepted and the duplicate rejected.
4. Set three stars, equip card 3, select it, and press Move earlier. Confirm its displayed equipped order changes.
5. Press Step command 12 times. Confirm the next command returns to card 1. Press Run, Pause, and Reset cursor to observe automatic execution and restart.
6. Try Move earlier on the first equipped card and Unequip when only one card remains. Expect readable rejection and no state change.

## Automated result

Godot 4.7.1 launched the scene headlessly. `godot --headless --path . --script res://tests/roster/run_tests.gd` passed 17 checks with zero failures, covering definition validation, role distribution, star capacity, duplicates, reordering, command looping, and invalid role commands.

## Known limitations

- The character names and card sequences are test fixtures, pending approved content.
- The test scene previews command execution and timing; it does not move 3D units. Milestone 1 remains the arena movement test.
- TAUNT and SCARE retain the unresolved effects described in `docs/decisions/gameplay_decisions.md`.
