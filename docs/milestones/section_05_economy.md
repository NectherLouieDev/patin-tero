# Section 5 — Economy, Shop, and Unit Progression

## Objective

Make the tournament economy playable and readable from initial purchase through match rewards, round income, merges, and the championship restriction.

## Scope and deliverables

- Configured per-character cost, weight, and availability; configured five-offer generation and duplicate policy.
- Atomic purchases, two-coin rerolls, nine bench slots, and three-copy same-star merges with the documented provisional inheritance policy.
- Separate provisional +1 coin bonus for a 2–0 winner; +5 base income to survivors at the next planning phase.
- Planning shop modal with authored placeholder portraits, role, cost, ownership, purchase availability, current coins, reroll cost, round income, and bonus information.
- Disabled unaffordable, sold, and full-bench offers; disabled reroll below two coins; clear transaction and merge feedback.
- New-tournament economy reset and championship shop restriction.

## Test scenarios and acceptance criteria

1. Launch `res://scenes/main/game.tscn` and start seed `1`. The shop opens over planning with five pictured offers, each showing name, role, price, and ownership. Click an available offer to buy; its slot becomes sold and the exact cost is deducted.
2. Close the shop and deploy a runner and guard. Reopen the shop; the formation remains. Reroll and confirm exactly two coins are spent and five offers are regenerated while the formation remains. Individual characters may appear again by chance.
3. Buy the two `TEST Habulin` copies in opening slots 2 and 5 with starter runner #1 deployed. The merge message identifies #1 as a two-star survivor and its cards and anchor persist.
4. Spend down to fewer than two coins. Reroll disables. Unaffordable or full-bench offers disable without deducting coins.
5. Lock and play a match. The shop closes and cannot reopen during battle. A 2–0 winner receives the configured +1 bonus; 1–1 and 0–2 give no match bonus. After all stage results, survivors receive +5 base coins before the next planning shop opens.
6. Continue to the championship. The shop is closed. Start a new tournament and confirm coins, offers, and upgrades reset.

## Implementation status

Implemented and automated tests passed. Developer visual and gameplay acceptance is pending.

## Known issues

- The starting balance, per-character prices, base income, offer weights, availability, and duplicate policy are clearly labeled test balance values. Only the provisional +1 2–0 bonus was explicitly chosen for this section. A 20-seed smoke survey checks basic viability; final competitive balance still needs playtesting.
- Shop portraits are readable placeholder vector icons. Final character portraits and economy balance remain subject to later art and playtesting.
