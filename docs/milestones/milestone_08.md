# Milestone 8 — Tournament Survival Loop and Championship

Status: implemented and headless checks passed; awaiting developer playtest.

## Deliverable

Open `res://scenes/debug/tournament_test.tscn`. The scene shows eight participants, a player shop and bench, provisional planning controls, pairings, cumulative standings, match results, stage advancement, and champion presentation. Match results come from the dual-arena `MatchController`; each completed match keeps a replay record in tournament history.

## Manual acceptance

1. Start a fresh tournament with seed 42. Confirm eight participants, five offers, the starter runner and guard, and a planning phase.
2. Buy an offer or reroll. Confirm the coin cost and bench change. Choose a guard column, then press Lock plan. Confirm four pairings are scheduled.
3. Press Play next match four times. Inspect each score and both arena result types/ticks. Confirm Advance stage becomes available only after all four results.
4. Advance and confirm active counts of 6, then 4, then 2. At each stage, lock planning, play every pairing, and advance. At two participants, confirm shop purchase and reroll are disabled.
5. Play the championship match and advance. Confirm one champion and an active count of 1.
6. Start fresh with the same seed, enable TEST: force 1–1 ties, lock, and play all four opening matches. Advance and inspect the displayed tiebreak; lower participant IDs should advance when points are equal.
7. Start a fresh tournament with another seed. Confirm stage, standings, results, eliminations, and champion reset.

## Automated result

Godot 4.7.1 launched the scene headlessly. `godot --headless --path . --script res://tests/tournament/run_tests.gd` passed all checks with zero failures. The checks cover purchases in the tournament bench, locked planning, all stage counts, required match completion, duplicate-result prevention, championship shop closure, champion selection, replay reconstruction, ties, and fresh-tournament reset.

## Known limitations

- Pairing, six-player handling, cumulative standings, championship ties, starter units, and automatic placement of bought units are provisional; see `docs/decisions/gameplay_decisions.md`.
- Non-player fixture formations described in this earlier checkpoint have been replaced by deterministic bots in Milestone 7.
- The tournament scene shows match results and replay records but does not embed the 3D match view. Use `res://scenes/debug/match_test.tscn` to inspect arena visuals.
- Tournament records exist in memory for this prototype and are cleared by Start fresh tournament. Persistent saves and final opponent planning remain open.
