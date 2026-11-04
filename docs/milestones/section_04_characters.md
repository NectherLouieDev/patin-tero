# Section 4 — Characters, Roles, and Signature Movesets

## Objective

Complete a playable character loop from purchase and merge through planning, battle, and results, with distinct provisional characters visible at the approved camera distance.

## Scope and deliverables

- Nine named but clearly provisional character definitions and 27 distinct, role-valid four-command test cards.
- An authored primitive visual variant for each definition, team marking, and one-to-three-star badges.
- Visual idle, move, facing-change, STAY, TAUNT, SCARE, tagged, round-trip, and victory responses that do not alter simulation timing.
- Deterministic merges that can include deployed copies, retain a valid survivor anchor and card order, cascade to three stars, and report the result in the shop.
- Character and star information in the battle and opponent panels, plus an interactive gallery at `res://scenes/debug/character_gallery.tscn`.

## Test scenarios and acceptance criteria

1. Open the gallery. All nine characters appear together with visibly different accessories. Selecting each character shows its role and three distinct card patterns.
2. Change the selected character to three stars. Three gold badges appear above it. Preview Move, STAY, TAUNT or SCARE where role-valid, Tagged, Round trip for a runner, and Victory.
3. In `res://scenes/main/game.tscn`, start a tournament, buy a unit, deploy it, choose and order cards subject to star capacity, lock formation, and watch its identity and star level carry into battle.
4. For a reproducible merge, start with seed `1`. Deploy starter runner `#1` at offense `(1,0)` and select its third card. The opening shop offers two more `TEST Habulin` copies in slots 2 and 5. Buy both through the planning shop window. The purchase reports `Merged into #1 ★2`; the runner remains at `(1,0)` with its chosen card and can now equip a second card. Chained matching upgrades stop at three stars.
5. Continue through match results, standings, and the next round. Identical seeds and configurations produce identical authoritative results.

## Implementation status

Implemented and automatically tested. Developer visual and gameplay acceptance is pending.

## Known issues

- Names and card patterns are approved as provisional test content, not final roster data.
- TAUNT and SCARE have timing and visual responses only, as approved for this playable build. Their gameplay effects await design rules.
- Character art uses authored primitives. The final art style and animation assets can replace these visual variants without changing simulation rules.
- Merge survivor selection and inheritance follow the documented configurable provisional policy until the final rule is approved.
