# Milestone 7 — Single-Player Bot Opponents

Status: implemented and headless tests passed; awaiting developer playtest.

## Objective and scope

Fill the seven non-player tournament slots with deterministic bots. Each bot uses its own shop and shared roster session, buys units, selects cards, deploys a valid offense and defense formation, and retains its roster across stages. Normal tournament pairings now pass player or bot locked snapshots to the existing `MatchController`.

## Deliverables

- `res://scenes/debug/bot_test.tscn` shows the selected bot's roster, balance, purchase, decision seed, card order, anchors, and match results. It can run the first player-versus-bot pairing and the next bot-versus-bot pairing.
- The configured main scene identifies bots in pairings, results, and standings.
- `BotParticipant` records a deep copy of each stage's seed, offers, purchases, roster, card choices, placements, and locked snapshot. The tournament retains these records even after elimination.
- `SharedSession.set_cards` validates a chosen card sequence, including one-star replacement, without changing state on rejection.

## Manual acceptance

1. Open `res://scenes/debug/bot_test.tscn`. Start with seed 42. Confirm seven bot slots are available and Bot P2 begins with a valid runner, guard, and seeded purchase.
2. Press Generate and lock bot formations. Inspect Bot P2's decision seed, one purchase, three-unit roster, ordered cards, and valid offense/defense anchors. Select other bots and inspect their distinct recorded plans.
3. Press Run P1 vs Bot P2, then Run Bot P3 vs Bot P4. Confirm both scores and arena results appear and the tournament match count advances.
4. Start fresh with seed 42 and repeat. Confirm the displayed bot decisions and first two match results match exactly. Change the seed and confirm decisions change.
5. Press Play Project to run the main scene. Complete a tournament and confirm bot names appear in battle, results, and standings. Inspect that progression still reaches one champion.

## Automated acceptance

Godot 4.7.1 launched `bot_test.tscn` headlessly. `res://tests/bots/run_tests.gd` passed checks for seven bots, validated purchases/cards/anchors, same-seed decision histories, snapshot inputs to player-versus-bot and bot-versus-bot matches, stepped versus direct result agreement, full-tournament repeatability, a changed-seed comparison, and the authored inspection scene. The existing simulation, roster, shared-session, economy, formation, match, tournament, and UI runners passed with zero failures.

## Known limitations

- Bot purchases, maximum roster size, anchor selection, and per-stage spending are simple provisional policies, not final difficulty or balance rules.
- At this checkpoint, placeholder card commands were overridden for battles. The later Section 2 playable-loop update now executes selected cards with a provisional automatic runner turnaround and arena time limit; see `docs/decisions/gameplay_decisions.md`.
- The debug-only forced-tie mode mirrors a valid bot formation to exercise standings tiebreaks. Normal tournament matches use separate participant formations.
