# Section 2 — Playable Core Loop Completion

Status: implemented and headless tests passed; awaiting developer playtest.

## Objective and deliverable

Press Play Project to launch `res://scenes/main/game.tscn`. The game uses two persistent instances of `res://scenes/arena/arena.tscn`, each with authored 4×8 tiles, role anchors, and placeholder unit nodes. The approved camera transform remains in the main scene.

The player can enter an eight-participant tournament, buy and merge units, open and close the shop over planning, drag units to valid anchors, select and order cards, watch both arenas resolve, inspect causes and coin rewards, review past match summaries and the next opponent, advance through eliminations, and reach a champion with final standings.

## Provisional decisions

Five coins of round income, one coin per arena point, 320 ticks per arena, automatic runner reversal after reaching row 7, deterministic crossing tags, and championship match precedence are test policies. Their exact rules and values require design approval. Placeholder card content remains labeled TEST. See `docs/decisions/gameplay_decisions.md`.

## Manual acceptance

1. Press Play Project. Confirm the lobby shows you, seven bots, readiness, and the 8 → 6 → 4 → 2 → 1 format. Start with seed 42.
2. Buy an offer and open formation planning. Open the shop window from planning, buy or reroll, then close it. Confirm the formation screen and both arenas remain in place.
3. Select a runner in the roster and drag it to a highlighted offense row 0 anchor. Select a guard and drag it to a defense patrol anchor. Try an invalid drop; confirm the previous placement stays unchanged.
4. Inspect the three TEST cards and their four commands. Use **Use Only Selected Card** to replace a one-star unit's card. For a higher-star unit, equip distinct cards, move one earlier or later, and confirm the displayed order.
5. Lock and watch battle. Pause, step, and toggle display speed. Confirm both arenas continue independently, movement follows the selected cards, and a result appears after both arenas finish or reach the time limit.
6. Inspect the score, each arena's reason, and coins earned. Continue through the stage, select a previous match in the history list, and inspect the next opponent's public roster and cards.
7. Advance and confirm five new offers and five base-income coins for survivors, plus any Section 5 2–0 match bonus. Repeat through the championship; confirm the final match winner becomes champion when the score is decisive. Inspect full standings and start a new tournament.

## Automated validation

`res://tests/loop/run_tests.gd` passed provisional turnaround, timeout, crossing and multi-guard tags, seeded round refresh, income and rewards, selected-card movement, and championship precedence. `res://tests/ui/run_flow_tests.gd` passed the full main-scene tournament flow, instanced scene-tree arenas, drag placement, shop overlay, card selection, history, and champion presentation. Existing simulation, roster, economy, formation, match, bot, and tournament runners passed after the changes.

## Known limits

- Exact card content, round economy values, arena time limit, collision priority, and championship tiebreak remain provisional.
- Match history is reviewable as result summaries; interactive replay playback and settings remain outside this update.
- Manual visual and mouse playtesting by the developer is pending. No commit is created before approval.
