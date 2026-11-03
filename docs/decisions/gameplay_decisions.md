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

