# PATIN / TERO! — Game Design Document

**Document status:** Reconstructed working draft  
**Purpose:** Product and implementation reference for the Godot project  
**Engine target:** Godot 4.x, GDScript, Windows desktop  
**Rule labels:** **Confirmed in recovered conversation** means directly stated in the available source. **Provisional** means a working assumption requiring confirmation. **Open** means do not finalize without a design decision.

> **Source limitation:** The referenced conversation preview exposed a detailed Section 9 and some implementation guidance, but did not expose the original text of Sections 1–8. This document consolidates all recoverable material and reconstructs missing section headings/content as clearly labeled working summaries. Restore the original source sections when available; do not treat reconstructed prose or provisional values as final design.

## Contents

1. [Game Overview](#1-game-overview)
2. [Game Pillars and Player Experience](#2-game-pillars-and-player-experience)
3. [Core Gameplay Rules](#3-core-gameplay-rules)
4. [Characters, Cards, and Progression](#4-characters-cards-and-progression)
5. [Economy and Shop](#5-economy-and-shop)
6. [Matches and Tournament](#6-matches-and-tournament)
7. [Presentation and Interface](#7-presentation-and-interface)
8. [Content Scope and Open Design](#8-content-scope-and-open-design)
9. [Technical Architecture and System Design](#9-technical-architecture-and-system-design)
10. [Revised Playable Milestone Roadmap](#10-revised-playable-milestone-roadmap)
11. [Decision Register](#11-decision-register)

---

## 1. Game Overview

**PATIN / TERO!** is a deterministic strategy auto-battler inspired by the Filipino street game Patintero. Players assemble teams of runners and guards, deploy them on a 4×8 grid, configure character signature movement cards, and watch both sides execute their plans automatically.

| Attribute | Working definition | Status |
|---|---|---|
| Genre | Deterministic strategy auto-battler | Confirmed |
| Engine | Godot 4.x | Confirmed |
| Language | GDScript | Confirmed |
| Platform | Windows desktop | Confirmed |
| Input | Mouse and keyboard | Confirmed |
| Camera | Slightly isometric 3D | Confirmed |
| Visual direction | Minimalist, stylized, low-poly 3D | Confirmed |
| Core loop | **PLAN → WATCH → ADAPT** | Confirmed |
| Tournament | Eight-player survival league | Confirmed |

### 1.1 High concept

Build and configure a roster, plan runner and guard behavior with repeating command cards, lock a formation, then observe a deterministic match. Adapt the roster and plans between rounds to survive an elimination tournament.

### 1.2 Design intent

The strategic choices are made before battle: which characters to field, where to deploy them, and which movement patterns to equip and order. Battle execution is automatic and reproducible. Visual animation communicates the simulation but never decides its result.

## 2. Game Pillars and Player Experience

### 2.1 Core pillars

1. **Readable planning:** players can inspect units, anchors, cards, and likely behavior before locking.
2. **Deterministic outcomes:** identical initial state, rules, and seed produce identical simulation results.
3. **Two-sided strategy:** each match includes a player offense and a player defense arena.
4. **Adaptation over a tournament:** roster and economy choices carry across rounds within the tournament.
5. **Observable playability:** every development milestone launches and offers direct manual checks.

These are working summaries inferred from the recoverable rules and architecture; confirm against original Sections 1–2 when available.

### 2.2 Player loop

1. Review tournament state and available resources.
2. Buy, sell/merge, and organize characters as supported by the current design.
3. Configure offense and defense formations, deployment anchors, and card order.
4. Lock the formations.
5. Watch both arenas resolve automatically.
6. Review arena outcomes, match points, and standings.
7. Adapt for the next planning phase, or enter the championship.

Steps beyond formation planning and battle observation are provisional where exact phase rules are not recovered.

## 3. Core Gameplay Rules

### 3.1 Arena grid

Each arena is a logical grid of four columns and eight rows.

| Property | Rule |
|---|---|
| Columns | 4, indexed `x = 0..3` |
| Rows | 8, indexed `y = 0..7` |
| Runner starting row | Row 0 |
| Runner destination row | Row 7 |
| Authoritative coordinates | Integer grid coordinates |

World-space positions are presentation only. Grid bounds and tagging must be evaluated in the simulation.

### 3.2 Roles and objectives

| Role | Movement / assignment | Objective |
|---|---|---|
| Runner | Starts on row 0; uses runner commands | Reach row 7, then return to row 0 without being tagged. A completed round trip wins the offensive arena. |
| Horizontal guard | Assigned to a horizontal patrol line associated with row 2, 4, or 6 | Patrol and attempt to tag runners. |
| Center guard | Patrols the central vertical line between columns 1 and 2 | Attempt to tag runners. Exact logical representation of this line is open. |

### 3.3 Deployment limits and anchors

Maximum deployment per player:

| Role | Maximum | Anchor rule |
|---|---:|---|
| Runners | 3 | Starting anchors on row 0 |
| Horizontal guards | 3 | Patrol assignments associated with rows 2, 4, and 6 |
| Center guards | 1 | Central vertical line between columns 1 and 2 |

Deployment validation must prevent invalid roles, occupied anchors where exclusivity applies, over-capacity formations, and units not owned by the player. Center-line geometry and exact anchor exclusivity are open decisions.

### 3.4 Command vocabulary and timing

| Role | Code | Meaning |
|---|---|---|
| Runner | `F` | Forward |
| Runner | `L` | Left |
| Runner | `R` | Right |
| Runner | `DL` | Diagonal left |
| Runner | `DR` | Diagonal right |
| Runner | `S` | Stay |
| Runner | `T` | TAUNT |
| Guard | `L` | Left |
| Guard | `R` | Right |
| Guard | `U` | Up |
| Guard | `D` | Down |
| Guard | `S` | Stay |
| Guard | `C` | SCARE |

| Command class | Duration |
|---|---:|
| Standard movement / stay | 500 ms |
| TAUNT / SCARE | 750 ms |
| Proposed simulation tick | 50 ms (provisional implementation recommendation) |

At a 50 ms tick, standard commands consume 10 ticks and TAUNT/SCARE consume 15. Tick duration may change if all durations remain exactly representable. The gameplay effects of TAUNT and SCARE are not specified in recoverable source and must remain open; do not invent their effects.

Commands execute automatically. Players cannot edit commands during battle. Invalid movement currently has a **provisional** behavior: the unit stays in place while the command duration is consumed.

### 3.5 Movement, tagging, and victory

The simulation resolves commands against role-specific movement restrictions and arena bounds. Guards remain within their patrol restrictions. Tagging is determined from logical state, never Godot physics or rendered distance.

The broad simulation step is:

1. Identify commands completing on the current logical tick.
2. Calculate intended movement.
3. Validate movement restrictions.
4. Resolve simultaneous movement deterministically.
5. Commit logical positions.
6. Resolve command effects.
7. Resolve tagging.
8. Evaluate arena victory.
9. Emit events and advance state.

The exact priority among simultaneous movement, crossing/overlap, special effects, tagging, and a runner completing a round trip is **open**. Define and test an explicit rule table before treating those edge cases as final.

## 4. Characters, Cards, and Progression

### 4.1 MVP roster

The recoverable specification calls for nine character definitions:

| Role | Count |
|---|---:|
| Runner | 4 |
| Horizontal guard | 3 |
| Center guard | 2 |
| **Total** | **9** |

Names, portraits, descriptions, card names, and exact card command sequences were not present in the recovered material. Load them from data resources. **Do not invent finalized character card sequences.** Temporary test sequences are permitted only when labeled as test placeholders and isolated from final content.

### 4.2 Signature cards

- Every character has exactly three signature cards.
- Every card contains exactly four commands.
- A 1-star character equips one card.
- A 2-star character equips two distinct cards.
- A 3-star character equips three distinct cards.
- Equipped cards execute in order; commands within each card execute sequentially.
- After the final command of the final equipped card, execution loops to the first equipped card.
- Card order changes behavior.

Character and card definitions should be data-driven. Validate card count, command count, role-appropriate commands, distinct equipped cards, and star-based capacity.

### 4.3 Merging and stars

Three identical characters at the same star level merge into one character at the next star level. Maximum star level is three. Star upgrades increase card capacity; they do not increase movement speed or combat statistics.

**Open:** Which instance survives a merge; how deployment, card selection/order, and other instance state transfer; whether deployed units can merge; and when merge resolution occurs. Do not silently choose inheritance rules.

## 5. Economy and Shop

### 5.1 Recovered rules

| Rule | Value | Status |
|---|---:|---|
| Currency | Tournament-only coins | Confirmed |
| Shop offers | 5 | Confirmed |
| Reroll cost | 2 coins | Confirmed |
| Bench capacity | 9 characters | Confirmed |
| Purchase transaction | Atomic; failed validation changes neither coins nor roster | Confirmed |
| Championship shop | Disabled | Confirmed |

Purchases require sufficient coins, a valid offer, bench capacity or a valid merge that creates capacity, and an eligible planning phase. A full bench or insufficient balance rejects the purchase without partial changes. Rerolls require the fixed cost and use reproducible offer generation when seeded.

### 5.2 Configurable, unresolved economy values

Starting coins, character prices, round income, bonuses (including any 2–0 bonus), shop weights, duplicate-offer behavior, and detailed round reward rules remain unresolved. Expose these as configuration data and label all development defaults provisional. Do not present sample defaults as finalized balance.

## 6. Matches and Tournament

### 6.1 Two-arena match

Each match runs two independent arenas:

| Arena | Offense | Defense |
|---|---|---|
| A | Player A | Player B |
| B | Player B | Player A |

Each arena victory awards one tournament point. A match can end `2–0`, `1–1`, or `0–2`. Match scoring is finalized only after both arena results are available. The two arenas share immutable definitions but never mutable unit positions or command state.

### 6.2 Tournament structure

Eight participants enter the Survival League. Recovered elimination counts are:

**8 → 6 → 4 → 2 → 1**

The system must support pairings, match execution, results, tournament points, standings, tiebreakers, elimination, championship, and champion presentation.

**Open:** Pairing algorithm, number of matches per stage, byes or special handling for odd participant counts (notably six), standings formula, tiebreakers, elimination selection, tie resolution, and championship rules. Use configurable provisional rules for playable tests; clearly label them and do not call them final.

## 7. Presentation and Interface

### 7.1 Visual presentation

The game uses two persistent, slightly isometric 3D arenas: one for the player's offense and one for defense. Keep both arena views present through planning and battle. Early milestones should use simple geometry: plane/box grid tiles, capsule/cylinder unit stand-ins, distinct role colors/shapes, visible deployment anchors, and a fixed camera. Final models and environmental polish are out of early milestone scope.

Visual movement interpolates between logical positions. Interpolation and animation never alter authoritative simulation state.

### 7.2 Interface and interaction

Use Godot `Control` nodes for menus, panels, and HUD. The intended interaction surface includes:

- Character selection and a nine-slot bench.
- Five-offer shop and reroll.
- Drag-and-drop deployment with valid-anchor highlights and invalid-drop cancellation.
- Moveset card editing and reordering.
- Single-unit preview.
- Formation lock.
- Battle observation and results.
- Tournament standings and replay controls.

Mouse raycasts may identify visual targets; the resulting action must be validated against logical data. The UI submits requests to gameplay systems and reflects confirmed results; it does not directly decide outcomes or mutate authoritative state.

| Display target | Resolution |
|---|---:|
| Reference | 1920×1080 |
| Minimum supported | 1280×720 |

## 8. Content Scope and Open Design

### 8.1 MVP scope

- Nine data-driven characters across the three defined roles.
- Repeating four-command signature cards and star-based card capacity.
- Two independent deterministic arena simulations per match.
- Planning, formation lock, automatic battle, results, tournament standings, and elimination flow.
- Tournament economy, shop, bench, and merging, with unresolved tuning values configurable.
- 3D arena presentation, mouse/keyboard UI, replay verification, and save/version support as milestones permit.

### 8.2 Explicit non-goals until separately approved

Do not add unrequested game modes, complex AI, combat/health/damage, permanent stat upgrades, procedural levels, or multiplayer networking during the MVP roadmap. Do not expand scope with speculative mechanics.

### 8.3 Source recovery and editorial policy

This document is a reconstructed working draft because original Sections 1–8 were not included in the accessible thread data. When source PDFs or original section text are supplied, reconcile this document against them and preserve contradictions in the decision register until resolved. Never convert a provisional implementation choice into a design fact by omission.

## 9. Technical Architecture and System Design

### 9.1 Technical overview and principles

| Component | Target |
|---|---|
| Engine | Godot 4 |
| Language | GDScript |
| Platform | Windows desktop |
| Rendering | Godot 3D renderer |
| UI | Godot `Control` nodes |
| Definitions | Custom Godot `Resource` classes |
| Simulation | Fixed-step, grid-based, integer logical time |
| Saves / replays | Versioned structured data |
| Multiplayer | Authority model open; no MVP networking |

Architecture priorities: reproducible battles; logic/presentation separation; data-driven characters and cards; explicit state transitions; reliable tournament scoring; replay compatibility; testability; and maintainable future extension.

### 9.2 High-level system architecture

```text
Game Application / GameManager
  └── TournamentManager
      └── MatchController
          ├── ArenaSimulation A (A offense vs B defense)
          └── ArenaSimulation B (B offense vs A defense)
              └── Match results → tournament points → replay records
```

Systems expose small interfaces. Use validated requests, explicit calls, and signals. Only truly global-lifetime systems should be Autoloads; tournament/match systems belong to their session.

### 9.3 Suggested project structure

```text
res://
├── scenes/{main,tournament,arena,characters,ui,replay,debug}/
├── scripts/{core,simulation,tournament,economy,roster,formation,replay,ui,utilities}/
├── resources/{characters,signature_cards,economy,tournament}/
├── assets/{models,materials,textures,audio,fonts}/
├── data/default_configs/
├── tests/{simulation,economy,tournament,replay}/
└── docs/{milestones,decisions,test_reports}/
```

Create folders when needed; do not add empty scaffolding only to match the diagram. Keep shared utilities independent of UI scenes and store gameplay definitions in reusable resources rather than hardcoding them into character scenes.

### 9.4 System ownership

| System | Responsibility |
|---|---|
| `GameManager` | Application session lifecycle and major phase transitions |
| `TournamentManager` | Stages, pairings, standings, elimination, championship |
| `MatchController` | Two arena lifecycles and authoritative match result |
| `ArenaSimulation` | Logical state, command execution, movement, tagging, victory |
| `EconomyManager` | Balances, rewards, transaction validation |
| `ShopManager` | Five reproducible offers and rerolls |
| `RosterManager` | Ownership, bench, merging, star upgrades |
| `FormationManager` | Deployment and equipped card configuration/validation |
| `ReplayManager` | Record, reconstruct, and verify deterministic matches |
| `SaveManager` | Versioned persistent settings and records |

The UI cannot directly mutate authoritative game state. A shop UI asks for a validated purchase; systems commit coins and roster atomically, then signal the result.

### 9.5 Game state machine

Use explicit states for the session flow (planning, battle, results, standings, championship, complete as applicable). Enforce transition guards:

- Planning advances only after formations are locked.
- Battle resolves only after both arenas finish.
- Standings/elimination update only after all current-stage matches finalize.
- Championship starts only with exactly two finalists.

Exact state names and stage transition details remain configurable until tournament rules are finalized.

### 9.6 Deterministic simulation

The simulation must not depend on render/physics frame rate, animation speed, scene-tree order, UI input, camera position, or visual interpolation. Use integer grid coordinates and integer logical time. If randomness is explicitly required, use a recorded seed; never use unseeded randomness in authoritative battle logic.

Recommended headless interface:

```gdscript
simulation.initialize(config)
simulation.step()
simulation.run_until_finished()
simulation.get_state()
simulation.get_result()
simulation.reset()
```

The API may evolve but must remain usable without loading a 3D arena.

Each logical unit tracks at least: unique unit ID, character definition ID, player/team ID, role, grid position, star level, equipped card sequence, current card/command indices, remaining command ticks, active/tagged status, relevant effect state, and runner round-trip progress.

### 9.7 Grid mapping and deployment

Use a reusable grid mapper to convert integer coordinates to `Vector3` for views. Deployment anchors are logical positions or patrol assignments validated by `FormationManager`, with corresponding visible indicators. Do not use world-space distance as the basis for movement validity or tagging.

### 9.8 Character and card resources

Suggested `CharacterDefinition` fields:

| Field | Type | Purpose |
|---|---|---|
| `character_id` | `StringName` | Stable unique ID |
| `display_name` | `String` | UI name |
| `role` | Enum | Runner / horizontal guard / center guard |
| `shop_cost` | `int` | Configurable purchase price |
| `shop_weight` | `int` | Configurable offer weight |
| `signature_cards` | Array of card resources | Three definitions |
| `visual_scene` | `PackedScene` | Presentation scene |
| `icon` | `Texture2D` | UI portrait |

Character instances store instance ID, definition ID, star level, roster location, deployment assignment, and equipped card order; static content remains in immutable definitions.

Suggested `SignatureCardDefinition` data: card ID, display name, character ID, command sequence, description, and icon. Use enumerated command identifiers, not arbitrary strings, in simulation. Validate commands against role. **Exact final card sequences are intentionally absent.**

### 9.9 Movement and collision resolution

Centralize intended destination calculation and validation in a movement resolver. Resolve all commands completing on the same tick using a stable rule order independent of scene-tree order. The current provisional invalid-move rule is stay in place and consume duration. Define edge cases—including crossings, simultaneous overlap, special effects, tagging, and goal arrival—in a deterministic decision table before production content depends on them.

Physics bodies may support picking or visual effects but cannot decide tags. TAUNT/SCARE effects use logical start/end ticks; visual effects follow simulation events. Their gameplay effects remain open.

### 9.10 Arena and match results

An `ArenaResult` should include arena ID, offense/defense player IDs, winner, victory type, completion tick, successful round trips, relevant tag statistics, and verification data. Each arena owns isolated mutable state.

`MatchController` receives two locked formation snapshots, constructs and starts both arena configurations from a defined initial tick, waits for both results, computes 2–0/1–1/0–2 points, finalizes exactly once, and notifies the tournament. `MatchResult` should include match ID, player IDs, both arena results, points per player, completion status, and replay reference.

### 9.11 Tournament data and scoring

Tournament state should include tournament ID, participants, stage, round, pairings, completed results, standings, elimination history, and championship state. Matchmaking should be replaceable/configurable. Standings derive only from authoritative match results and configured points/tiebreakers. Eliminate only after the relevant stage completes.

### 9.12 Economy, shop, roster, and formations

`EconomyManager` owns balances, income, bonuses, purchase costs, and reroll cost. `ShopManager` generates five offers from configurable weights and a reproducible seed; probabilities and duplicate-offer rules remain open. Purchases validate balance, offer, roster capacity/valid merge, and phase before any mutation.

`RosterManager` enforces nine bench slots and deterministic merges. Merge instance retention and configuration inheritance are open. `FormationManager` stores player ID, deployed instance IDs, anchors, equipped cards/order, and validation status. It checks ownership, role-specific anchors, active-unit limits, unique occupancy where applicable, card capacity, distinct cards, and valid commands. Formation lock creates an immutable snapshot for battle.

### 9.13 3D view and input

`ArenaView` displays the grid/anchors, spawns character views, animates simulation events, presents effects and victory, and synchronizes to logical events. Keep arena view instances persistent through planning, preview, and battle; update presentation mode without replacing the scenes.

An input controller handles selection, dragging, anchor highlighting, deployment requests, card selection/reorder, shop, preview, and ready/lock. Raycasts identify targets only; logical systems validate actions. Invalid requests return readable feedback.

### 9.14 Replay and save compatibility

Replay records should contain replay/match IDs, simulation version, locked formations, definition/version references (or embedded definitions as required), initial arena states, simulation parameters, random seed if used, expected results, and verification checksum. Replaying must reproduce the stored result; mismatch is reported as failure. Playback speed changes presentation only.

Save and replay formats are versioned structured data. Migration/compatibility policy is an implementation decision to document before persisted data becomes user-critical.

## 10. Revised Playable Milestone Roadmap

Every milestone must produce a runnable Godot scene/build, visible behavior, exact manual actions, expected results, pass/fail criteria, relevant automated regression checks for deterministic rules, a summary of files/features, and known limitations. No hidden prerequisites or manual edits to code/save data should be needed to run acceptance scenarios. Do not advance automatically: review and approve each milestone before starting the next. Scripts compiling alone does not complete a milestone.

### Milestone 1 — Deterministic Grid Simulation

**Playable deliverable:** Runnable 4×8 simulation test scene with debug state and reset.

**Features:** logical grid; runner/guard movement; command timing; boundary/patrol validation; tagging; round-trip detection; stepping; reset. Placeholder command patterns are test fixtures only.

**Manual acceptance:** (1) Launch the scene and run its named scenario. (2) Observe command-timed movement. (3) Attempt an invalid edge move and confirm the unit remains in bounds. (4) Confirm guards stay on permitted patrol paths. (5) Trigger and observe a tag. (6) Complete a runner round trip and observe arena victory. (7) Reset, run three times, and compare result/state summaries.

**Pass:** Every expected state/result is visible and all three repeated runs match. Include automated tests for timing, bounds, patrol constraints, tagging, victory, reset, and determinism. Document unresolved event priorities.

### Milestone 2 — Character and Moveset Data

**Playable deliverable:** Runnable roster/card inspection and execution scene using data resources.

**Features:** nine definition slots with missing final content marked; three cards × four commands per definition when actual content is supplied; star levels and card capacity; card ordering and loop. Use explicit test fixtures rather than fabricated final sequences.

**Manual acceptance:** (1) Inspect each available character definition and its status. (2) Equip cards at each star level. (3) Reorder equipped cards and verify displayed order. (4) Run the test fixture and inspect command progression/loop. (5) Try too many, duplicate, or role-invalid cards/commands and confirm clear rejection.

**Pass:** Valid configurations execute in order and loop; invalid configurations are rejected; final signature data is not fabricated. Automate resource validation and progression tests.

### Milestone 3 — Roster, Bench, and Merging

**Playable deliverable:** Runnable roster management scene with nine visible bench slots.

**Features:** ownership, capacity, star levels, merge trigger, clear transaction feedback. Keep unresolved survivor/inheritance policy configurable and visibly provisional.

**Manual acceptance:** (1) Add characters until nine slots are occupied. (2) Confirm a tenth non-merging addition is rejected with no partial change. (3) Add three identical same-star copies in the test fixture and observe one next-star result. (4) Verify no merge exceeds three stars. (5) Inspect retained deployment/card data and confirm the configured provisional policy is shown.

**Pass:** Capacity and merge counts are correct, deterministic, and non-destructive on failure. Automated tests cover capacity, identities, star ceiling, and transaction rollback.

### Milestone 4 — Economy and Shop

**Playable deliverable:** Runnable shop/transaction scene with visible balances and five offers.

**Features:** configurable starting balance/prices; buy; atomic rejection; two-coin reroll; seeded offer generation; bench integration.

**Manual acceptance:** (1) Open shop with a displayed test balance/config. (2) Buy an affordable offer and confirm one charge plus one roster addition. (3) Attempt an unaffordable purchase and confirm neither balance nor roster changes. (4) Fill bench and confirm purchase rejection unless a valid merge frees capacity. (5) Reroll with two coins and verify exact deduction; test insufficient balance. (6) Repeat with the same seed and verify offers match.

**Pass:** All transactions are atomic and seeded offers repeat. Display all tuning values as provisional until approved. Automate transaction and seed tests.

### Milestone 5 — Formation Planning and Lock

**Playable deliverable:** Runnable planning scene with two persistent arena views, bench, deployment anchors, card editor, preview, and lock action.

**Features:** role limits and anchors; drag/drop; invalid-drop cancellation; card selection/order; formation validation; immutable lock snapshot.

**Manual acceptance:** (1) Deploy valid roles to valid anchors. (2) Try wrong-role, occupied, and over-limit placements and confirm rejection. (3) Configure/reorder cards within star capacity. (4) Preview one unit. (5) Lock a valid formation and verify the snapshot. (6) Attempt editing after lock and confirm battle snapshot does not change.

**Pass:** Valid formations lock; invalid formations do not; views remain present. Automate validation and snapshot immutability. Center-line details remain provisional if undecided.

### Milestone 6 — Dual-Arena Match and Results

**Playable deliverable:** Runnable match scene that launches both arenas, visibly animates results, and displays match score.

**Features:** independent arena state; fixed-step simulation; interpolated visuals; both results; 2–0/1–1/0–2 scoring; readable debug/result feedback; replay capture or verification foundation.

**Manual acceptance:** (1) Start a prepared match. (2) Observe both arenas run from locked snapshots. (3) Confirm each arena can resolve independently. (4) Confirm match results wait for both arenas. (5) Exercise fixtures producing 2–0, 1–1, and 0–2. (6) Repeat identical seeded match and compare results. (7) Change visual playback speed and confirm authoritative result is unchanged.

**Pass:** Both arenas are isolated, result finalizes once, scores are correct and deterministic, and view speed cannot change outcome. Automate scoring, isolation, replay, and repeatability tests.

### Milestone 7 — Tournament Survival Loop and Championship

**Playable deliverable:** Runnable end-to-end eight-player tournament from setup through champion presentation.

**Features:** tournament stages, pairings, planning/shop/matches/results, standings, tiebreak handling, eliminations through 8→6→4→2→1, championship, champion presentation, persistent tournament record/replay references as scoped.

**Manual acceptance:** (1) Start a fresh eight-player tournament. (2) Complete planning and matches through each stage. (3) Inspect every result and standings update. (4) Verify stage participant counts reach 8, 6, 4, 2, then 1. (5) Trigger a tie fixture and inspect the configured tiebreak. (6) Complete championship and observe one champion. (7) Restart and verify tournament state does not leak into the new session; inspect saved/replay records if included.

**Pass:** Tournament transitions only after required matches finalize; counts and standings follow the displayed configurable rules; one champion is declared; restart isolation works. Automate pairing, standings, tiebreaks, elimination, transitions, and save/replay checks.

### Milestone completion report template

```text
Milestone:
Runnable scene / launch steps:
Implemented features and files:
Manual acceptance tests: PASS / FAIL (one result per test)
Automated regression checks:
Known limitations and provisional rules:
Decision requests for the designer:
Recommendation: review / revise
```

## 11. Decision Register

Treat this as the source of truth for unresolved rules. Record a decision, rationale, date, and affected sections when resolved.

| ID | Decision needed | Safe implementation posture |
|---|---|---|
| D-01 | Exact center-guard representation and central-line geometry | Model as a configurable patrol assignment; do not assume an ordinary cell. |
| D-02 | TAUNT and SCARE gameplay effects | Represent effect events/timing; leave effect payload configurable/unimplemented until specified. |
| D-03 | Simultaneous movement, crossing, occupancy, tag, and victory priority | Use an explicit deterministic rule table; do not rely on node order. |
| D-04 | Invalid movement behavior | Current recommendation: stay and consume duration; mark provisional. |
| D-05 | Exact final character/card names and command sequences | Load from approved data; never fabricate finalized sequences. |
| D-06 | Merge survivor and inheritance of deployment/cards | Make policy configurable and report it; avoid irreversible assumptions. |
| D-07 | Starting coins, prices, income, bonuses, shop weights, duplicates | Configurable provisional values only. |
| D-08 | Pairings, round structure, six-player handling, standings, tiebreaks, eliminations | Configurable tournament policy with visible provisional labels. |
| D-09 | Tick interval | 50 ms recommended; configurable while exact durations are preserved. |
| D-10 | Multiplayer authority model | Out of MVP implementation; finalize before network work. |
| D-11 | Save/replay schema migration policy | Version all persisted structures and document compatibility behavior. |
| D-12 | Original Sections 1–8 source text | Reconcile this reconstructed draft against original PDFs/text when available. |

---

## Codex usage contract

Use this GDD alongside the project `AGENTS.md`: the GDD defines the game; `AGENTS.md` defines development behavior. Implement one milestone at a time. Before coding, identify applicable GDD sections and unresolved decisions. Use provisional rules only when needed for a playable, testable milestone, label them in UI/debug output and reports, and keep them easy to replace. Never invent finalized card command sequences. Finish with a runnable deliverable, exact manual acceptance steps, PASS/FAIL results, automated regression checks where relevant, and known limitations. Stop at the milestone gate for review.
