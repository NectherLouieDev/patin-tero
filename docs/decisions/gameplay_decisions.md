# Milestone 1 provisional test policies

These policies make the isolated simulation testable. They are not final gameplay rules.

- Tick length: 50 ms. Standard commands take 10 ticks; TAUNT and SCARE take 15.
- Invalid movement stays in place and consumes its command duration.
- Destinations are calculated from the same starting state and committed by unit ID. Units may overlap.
- Tagging checks logical overlap after movement. A tag takes priority over a round trip on the same tick.
- The center guard uses a separate logical lane (`x = -1`) displayed at the boundary between columns 1 and 2. It tags a runner on the same row in column 1 or 2. This policy requires design approval before use in production.
- The runner's return trip uses a provisional `U` command because the approved runner command list contains no backward command. This is confined to the test fixture and simulation policy.
- TAUNT and SCARE consume time but have no gameplay effect until their rules are approved.
- No arena timeout is imposed in this milestone. Automated runs use a caller supplied tick limit.

## Milestone 3 provisional deployment policies

- The camera transform and 45° field of view in `scenes/debug/simulation_test.tscn` are the visual reference for deployment and future arena scenes, per the developer's direction.
- The planning test has one player offense arena and one player defense arena. The bench contains one test instance of each of the nine placeholder definitions.
- Runner anchors are the four cells of offense row 0. Horizontal guard anchors are defense rows 2, 4, and 6, with one guard per row. The center guard uses the separate marked lane anchor at logical `(-1, 3)`.
- Battle uses stationary or repeating opponent test fixtures in the opposite role so both arena simulations can run. These fixtures are not tournament opponents or final formations.

## Milestone 4 provisional economy policies

- `resources/economy/test_economy.json` sets a test starting balance of 20 coins and a test price of 3 coins for every placeholder character. These values are configurable and require balance approval.
- Offer weights are equal and duplicate offers are allowed. The five offers use a seeded `RandomNumberGenerator`; the weights and duplicate policy require approval.
- A purchase consumes its shop offer. A reroll replaces all five offers and costs the confirmed two coins.
- The shop test bench keeps the oldest matching instance when three identical same-star characters merge. It discards the other two and promotes the survivor by one star, up to three stars. Deployment and card-configuration inheritance remain unresolved, so this test policy carries only instance ID, definition ID, and star level.

