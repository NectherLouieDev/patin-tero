# Section 3 — Core Gameplay Mechanics playable loop

## Objective

Make the existing shop, planning, two-arena match, results, standings, and next-round loop clear enough to play and inspect while completing the partial Section 3 movement and feedback features.

## Scope and deliverables

- Runner movement relative to facing on the outbound and return legs.
- Role-valid guard commands and patrol boundaries.
- Deterministic path-based interception, including swaps, diagonal crossings, and the center lane.
- Timed `TAUNT` and `SCARE` state with visible begin and end cues; gameplay effects remain unresolved.
- Authored 3D heading and movement-preview markers, a battle countdown, interpolated unit movement, tag feedback, and selected-command readout.
- Updated isolated fixture sequences that exercise the current runner turnaround policy.

## Test scenarios and acceptance criteria

1. Launch `res://scenes/main/game.tscn`, start a seeded tournament, buy a unit, and open planning. The shop balance and roster update.
2. Place a runner and guard. The selected deployed unit shows a path on its board and a coordinate path in the panel. Invalid role anchors reject placement.
3. Lock. The battle waits through a three-second countdown, then both arenas advance. Pause freezes the tick; Step advances one tick; Run resumes. The default view is 1× and can switch to 4×.
4. Watch a runner reach row 7 and turn toward row 0. Facing and lateral commands reverse with its direction.
5. Watch a tag and confirm the brief pink cue and result reason. `TAUNT` and `SCARE` show blue and purple while active and are reported at expiration.
6. Continue through results, standings, the next stage, and the championship. A fresh tournament resets prior results.

## Implementation status

Implemented and automated tests passed. Developer visual and gameplay acceptance is pending.

## Known issues and provisional rules

- `TAUNT` and `SCARE` have timing and display cues only. Their gameplay effects and interactions require design approval.
- Simultaneous collision timing and tag priority, center-lane representation, invalid-move behavior, runner turnaround, and the 320-tick guard-win limit remain provisional. See `docs/decisions/gameplay_decisions.md`.
- Character art and signature-card data remain test placeholders. The camera uses the developer-approved perspective top-down transform.
