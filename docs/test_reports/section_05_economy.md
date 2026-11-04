# Section 5 economy validation

Godot 4.7.1 stable was used for headless project import, scene launch, and automated regression checks.

## Automated coverage

- Shop tests cover seeded five-offer generation, explicit availability, optional unique offers, affordability and full-bench preview, atomic purchase rejection, reroll cost, deployed roster preservation, and merging.
- Tournament income tests use seed 1, which produces 2–0, 1–1, and 0–2 matches in the opening stage. They verify the bonus for the 2–0 winner only, then check survivor base income and no next-round income for eliminated players.
- Player UI tests cover modal availability, portrait and role display, click purchase, sold and unaffordable disabled states, low-coin reroll disable, battle shop closure, and the full tournament flow.
- Existing match, bot, roster, formation, simulation, and loop tests protect the surrounding systems.
- A balance smoke survey completed 20 deterministic tournaments. It found 15 cases where a participant survived a 0–2 loss; each still had at least enough coins for a test-price unit in an open-shop stage. This checks basic recovery and nonnegative balances, not final competitive balance.

All 15 automated test runners passed after the Section 5 changes.

## Manual acceptance pending

The developer should play the seed-1 shop, merge, battle, results, standings, and next-round loop and verify visual clarity and pacing. Balance values are provisional.
