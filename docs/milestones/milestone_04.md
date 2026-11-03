# Milestone 4 — Economy and Shop

Status: implemented and automated checks passed; awaiting developer playtest.

## Deliverable

Open `res://scenes/debug/economy_test.tscn`. The scene shows coins, five offers, nine bench slots, a seed control, purchase and reroll actions, and debug setup buttons. Economy values are loaded from `resources/economy/test_economy.json` and are visibly provisional.

## Manual acceptance

1. Reset with seed 42 and note all five offers. Change the seed, reset, then restore 42 and reset. Expect the original five offers again.
2. Select an offer and buy it. Expect one bench entry, a sold offer, and exactly its displayed price deducted.
3. Reset, press TEST: zero coins, and try Buy and Reroll. Expect rejection and no change to offers or bench.
4. Reset, press TEST: full bench, and buy an offer. Expect rejection with the same coins, nine entries, and five offers.
5. Reset, select an offer, press TEST: prepare merge, then buy that offer. Expect the full bench to become eight entries with one matching two-star character and one price deduction.
6. Reset and reroll. Expect exactly two coins deducted and five new seeded offers.

## Automated result

Godot 4.7.1 launched the scene headlessly. `godot --headless --path . --script res://tests/economy/run_tests.gd` passed 11 checks with zero failures, covering seeded offers, purchases, sold offers, two-coin rerolls, insufficient funds, full bench rollback, merge admission, and closed-shop rejection.

## Known limitations

- Starting coins, prices, offer weights, duplicate-offer behavior, and merge survivor policy are provisional; see `docs/decisions/gameplay_decisions.md`.
- This is a dedicated economy test bench. Connecting purchased instances to the deployment scene requires the later unified planning flow.
- The character data and offers use the Milestone 2 placeholder roster.
