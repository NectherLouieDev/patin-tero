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

## Milestone 5 planning test policy

- The planning scene exposes the nine placeholder characters as test-owned units. The star control permits 1–3 stars for card-capacity testing. A unified purchased-instance roster and merge inheritance require later integration.
- A valid lock requires at least one deployed runner on offense and one deployed guard on defense. These minimums make the two-arena test inspectable and require confirmation for final formation rules.
- Lock stores a deep-copied snapshot of deployed instance IDs, definition IDs, anchors, star levels, equipped card IDs, and flattened command order. Post-lock planning edits are rejected.

## Milestone 6 match test policies

- The match scene uses two explicitly marked locked test snapshots for each 2–0, 1–1, and 0–2 case. Test runners use the provisional `U` return command from Milestone 1 so round trips can finish.
- The fixture seed is recorded as 42. The current battle logic uses no randomness; retaining the seed establishes replay input format for future approved random rules.
- A match result finalizes only after both arenas have terminal results. No arena timeout or draw policy is imposed; those rules remain open.

## Milestone 7 provisional tournament policies

- Each stage pairs active participants by ascending ID, one match per pair. The six-player stage has three matches. After all matches finish, the top six, four, two, or one advance according to the target stage size.
- Standings accumulate arena points across stages. Ties use total points, then arena wins, then lower participant ID. The championship uses the same order when its match ends 1–1. These pairing and tiebreak rules require approval.
- The tournament test starts the player with one placeholder runner and one placeholder horizontal guard. Bought distinct characters are automatically deployed into available role anchors when planning locks; duplicate copies stay on the bench. The user can choose the first guard's column. This is an isolated planning policy until a unified interactive planning flow is available.
- The locked player formation supplies roles and anchors to matches. Placeholder runner commands are replaced with the provisional return-trip fixture and guard commands with Stay, because final card sequences and a runner turnaround rule are unresolved.
- This earlier tournament checkpoint used seeded non-player fixtures. Milestone 7 bot opponents now supersede those fixtures in normal tournament matches. The optional debug-only 1–1 tie mode mirrors a valid bot formation on both sides.

## Shared-state integration checkpoint policies

- A shared session now owns the player's shop instance collection, placement, equipped card order, and locked snapshot. Purchased units keep their instance IDs through deployment and match input. The earlier isolated debug scenes remain available as subsystem tests.
- The provisional merge policy applies only to three bench copies of the same definition and star. The oldest bench instance survives, keeps its card order, returns at the higher star level, and the other two IDs are removed. Deployed units do not merge in this checkpoint. A full bench may still accept a purchase that immediately merges.
- The integration scene starts with one test runner and one test guard so a match can be reached without relying on random shop offers. Purchased duplicates are separate owned instances, subject to role and anchor limits.
- The match integration test overrides placeholder commands with the provisional round-trip and Stay fixture policy while retaining the locked snapshot's instance IDs, roles, and anchors. Final command behavior still requires approved runner return and card rules.

## Milestone 9 interface policy

- The player-facing main scene uses the same tournament model and shared roster. It adds no new scoring or economy rules. The previously documented automatic placement policy fills any available owned units when the player locks formation. Normal non-player matches now use Milestone 7 bot snapshots.
- A match advances one fixed logical tick at a time for live viewing. UI frame rate, pause, and step affect presentation timing only; tournament scoring occurs after both arenas finish.

## Milestone 7 bot-opponent test policy

- Bot participant IDs 2–8 each own a persistent `SharedSession`, starting with the same provisional runner and horizontal guard as the player. Their shop RNG seed is `tournament_seed × 1009 + participant_id × 17`; their stage decision seed is `tournament_seed × 1000003 + participant_id × 1009 + stage × 9176`. Both seeds and each stage's offers, purchases, roster, ordered cards, placement, and locked snapshot are recorded.
- An active bot buys at most one affordable offer per non-championship stage while its roster has fewer than six units. It does not reroll. It chooses up to its star capacity of distinct cards and tries seeded role-valid anchors through `SharedSession` public actions; excess units stay on the bench. The bot keeps its roster across stages and repositions through the same validated session actions. Bots receive the same base round income and Section 5 2–0 match bonus as the player.
- The earlier bot checkpoint substituted a return-trip fixture in battle. The Section 2 playable loop now executes each selected card's commands; the runner turnaround policy below supersedes that fixture override in tournament matches.
- Normal tournament matches use player and bot locked snapshots. The debug-only forced-tie toggle mirrors one valid bot snapshot to test standings tiebreaks; dedicated match fixtures remain only in isolated match tests.

## Section 2 playable-loop provisional rules

- At the start of each surviving non-opening planning stage, every active participant receives five coins and five newly seeded shop offers, except when the championship shop is closed. The Section 5 rule below defines the separate 2–0 match bonus. Test values live in `resources/economy/test_economy.json` and require balance approval.
- Tournament battle snapshots now retain each player's and bot's chosen card commands. Once a runner reaches row 7, its subsequent `F`, `DL`, and `DR` commands move toward row 0 in the vertical axis. This automatic turnaround is provisional until the runner command set and turnaround rule are approved. Card names and sequences remain marked TEST placeholders.
- An arena ends in a guard win if no active runner remains or if its configurable 320-tick limit expires. After simultaneous movement, a runner is tagged by any opposing guard sharing its cell or swapping cells with it on that tick; center guards retain the existing same-row center-lane tag policy. Same-team overlap remains allowed. Tagging precedes round-trip victory on the same tick.
- A non-tied championship match score selects the champion, regardless of earlier cumulative points. A 1–1 championship uses cumulative points, then arena wins, then lower participant ID. This rule remains provisional pending the final championship specification.
- The main scene's two 3D boards are instances of `scenes/arena/arena.tscn` with authored mesh nodes. The shop window opens over formation planning. Previous matches can be inspected as result summaries; interactive replay playback remains a later task.

## Section 3 core-mechanics playable-loop update

- This section supersedes the early runner `U` fixture and same-row center-guard tag notes above. A runner automatically faces its starting side after reaching row 7. Its `F`, `L`, `R`, `DL`, and `DR` commands then follow that reversed facing. `U` is not a runner command. Isolated round-trip fixtures now repeat `F` for both legs.
- Horizontal guards accept only `L`, `R`, `S`, and `C` and remain on their assigned patrol row. Center guards accept only `U`, `D`, `S`, and `C` and remain in the center lane.
- Tagging compares complete movement paths at the same instant within a fixed command-completion tick, including swaps and diagonal crossings. The center lane is represented at `x = 1.5`; crossing it at the guard's row tags the runner. Guard checks use sorted ID order, and tags resolve before a same-tick round trip. This collision timing and priority remain provisional pending design approval.
- `TAUNT` and `SCARE` each occupy 750 ms. The simulation records when they begin and end, and the arena displays blue and purple unit cues while active. They still have no gameplay effect because their interactions and priority remain unresolved.
- The player-facing battle has a three-second display countdown, a default real-time view, optional 4× speed, per-unit command and coordinate readout, event feedback, interpolated movement, facing markers, and a brief pink tag cue. Planning shows the selected deployed unit's next eight command destinations with authored scene markers. These are presentation features; the logical simulation still uses integer ticks.

## Section 4 playable-character provisional decisions

- The developer approved use of the proposed Section 4 names and distinct test card patterns for the playable build. The nine names and 27 four-command sequences in `resources/characters/test_roster.json` are all marked `TEST`; they are not final character content. Each card has a distinct pattern and a role-valid command list.
- The developer chose timing and visual cues only for `TAUNT` and `SCARE`. They have no tactical gameplay effect until interaction rules are supplied. Their 750 ms timing and blue/purple animations remain visible in battle and the character gallery.
- The provisional merge policy is `prefer_deployed_oldest_id`, configured in `resources/economy/test_economy.json`. Three copies of the same definition and star level merge at purchase. The lowest-ID deployed copy survives if any is deployed; otherwise the lowest-ID bench copy survives. The survivor keeps its valid anchor and ordered cards, gains one star, and the other two instance IDs are removed. Cascading merges repeat through star 3. The purchase and merge are atomic, and the result message identifies the survivor. This policy supersedes the earlier bench-only merge test policy above and awaits final design approval.
- All nine visual variants are authored in `scenes/characters/character_visual.tscn` and instanced under the arena's existing unit nodes. Shape accessories, accent colors, team badges, and one-to-three gold star badges show character identity and level. Code changes transforms and materials for visual animation only; simulation state and tick timing remain authoritative.

## Section 5 playable-economy provisional decisions

- The developer approved a provisional **+1 coin only for a 2–0 match winner**. The earlier one-coin-per-arena-point payout above is superseded. A 1–1 result gives neither participant a match coin bonus; a 0–2 participant receives none. Tournament points remain one per arena win. Base round income remains a separate +5 coins to each survivor after standings advance and before the next planning phase.
- The test economy retains 20 starting coins and a test price of 3 coins for each character. Each shop character now has an explicit ID, cost, weight, and availability entry in `resources/economy/test_economy.json`. Equal weights, all-available characters, and duplicate offers are provisional balance settings. The duplicate-offer policy can be changed in configuration without changing shop code.
- The confirmed five offers, two-coin reroll, nine bench slots, three-copy merge requirement, and three-star ceiling are also stored in configuration and validated at load time.
- The player-facing shop opens as a modal over planning and the existing arenas. Offer portraits are placeholder SVG assets, and every offer shows role, price, ownership, and availability. Sold, unaffordable, and full-bench offers and an unaffordable reroll are disabled in the UI; the shop model remains authoritative for every transaction.

