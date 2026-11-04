# Shared Roster and Formation State — Integration Checkpoint

Status: implemented and headless checks passed; awaiting developer playtest. This checkpoint supports the reconciled roadmap before bot opponents and the player-facing UI.

## Deliverable

Open `res://scenes/debug/shared_session_test.tscn`. The scene contains two persistent 3D arenas with authored tile and unit nodes and the approved camera transform. Its controls let you buy, reroll, inspect owned instance IDs, deploy by logical anchor, return to bench, equip and order cards, lock, run a fixture match, and continue to the next planning round.

The same `SharedSession` instance is now used by the integrated scene and `TournamentModel`. It owns the shop's instance collection, deployment location, card order, and locked snapshot. `MatchController` consumes a copy of that snapshot.

## Manual acceptance

1. Open the scene. Note test-owned IDs #1 runner and #2 guard. Select an offer and Buy. Note the purchased ID and coin charge.
2. Select the purchased unit. Choose its role's arena and a valid anchor: runner offense row 0; horizontal guard defense row 2, 4, or 6; center guard defense center lane `(-1, 3)`. Deploy it and confirm its ID and location persist in the owned list and its mesh appears.
3. Try a wrong-role anchor or an occupied anchor. Confirm rejection and the previous location remains.
4. Deploy the starter runner at offense `(0, 0)` and starter guard at defense `(0, 2)`. Select a unit and inspect its three placeholder card sequences. Try to equip a second card at one star; expect a capacity rejection.
5. Lock. Confirm the snapshot lists the same owned IDs, definitions, and coordinates. Attempt to buy, return, or edit cards after lock; expect rejection and an unchanged snapshot.
6. Run Test match. Confirm the replay input retains those instance IDs. Press Next round and confirm ownership and placement persist; press Reset and confirm only the two starters remain with fresh coins and no snapshot.
7. In the tournament test scene, purchase a distinct unit, lock planning, and confirm the same purchased ID appears in the player snapshot used for a match.

## Automated validation

Godot 4.7.1 launched the integration scene headlessly. `godot --headless --path . --script res://tests/roster/run_shared_session_tests.gd` passed 15 checks with zero failures. Existing economy, planning, match, and tournament test runners also passed with zero failures after integration.

## Known limitations

- The integration scene uses coordinate controls for deployment. The earlier planning test scene remains the drag interaction test.
- The shared session uses the shop's owned-instance collection as its authority. The old isolated debug scenes continue to create their own test states.
- Starter units, merge inheritance, center guard placement, and fixture match commands remain provisional; see `docs/decisions/gameplay_decisions.md`.
- Final bot opponents and the player-facing game flow are separate roadmap milestones.
