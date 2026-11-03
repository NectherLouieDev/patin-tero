# AGENTS.md — PATIN / TERO!

## 1. Project Identity

**Project:** PATIN / TERO!  
**Engine:** Godot 4.x  
**Language:** GDScript  
**Platform:** Windows Desktop  
**Input:** Mouse and keyboard  
**Genre:** Deterministic strategy auto-battler  
**Camera:** Slightly isometric 3D  
**Visual Style:** Minimalist, stylized, low-poly 3D

PATIN / TERO! is inspired by the Filipino street game Patintero.

Players assemble teams of runners and guards, deploy them onto a 4×8 grid, configure signature movement cards, and watch both sides execute their strategies automatically.

The primary gameplay experience is:

**PLAN → WATCH → ADAPT**

The game features an eight-player survival tournament with elimination stages:

**8 → 6 → 4 → 2 → 1**

This document defines the development standards and architectural requirements that Codex must follow.

---

## 2. Primary Development Objective

Build a complete, playable, testable MVP in Godot 4.

Development must follow seven sequential milestones.

Every milestone must produce:

1. A runnable Godot scene or playable game state.
2. Visible gameplay behavior.
3. Manual acceptance tests.
4. Automated tests for relevant deterministic rules.
5. Clear expected results.
6. A summary of implemented files and features.
7. A list of known limitations.
8. A clear PASS/FAIL result for each acceptance test.

**Do not proceed automatically to the next milestone.**

Wait for the developer to review and approve the current milestone.

A milestone is not complete merely because scripts compile.

---

## 3. Non-Negotiable Development Rules

### 3.1 Engine and Language

- Use Godot 4.x.
- Use GDScript for gameplay and tools.
- Prefer typed GDScript.
- Use Godot's built-in nodes, signals, and Resources.
- Avoid external plugins unless explicitly approved.
- Do not introduce C#, C++, or third-party frameworks without approval.

### 3.2 Architecture

Use a modular, data-driven architecture.

Separate:

- Simulation logic.
- Gameplay state.
- Game application flow.
- UI and input.
- 3D presentation.
- Persistence and replay.

**Never use rendered character positions to calculate authoritative gameplay outcomes.**

### 3.3 Code Quality

- Follow Godot 4 conventions.
- Use descriptive class, variable, and function names.
- Prefer composition over deep inheritance.
- Keep classes focused on one responsibility.
- Avoid unnecessary abstractions.
- Avoid circular dependencies.
- Do not create global singletons for systems that only exist during a tournament.
- Document non-obvious deterministic rules.
- Use signals for meaningful state changes.
- Validate inputs at system boundaries.

### 3.4 Scope Control

Implement only the active milestone.

Do not add:

- Unrequested game modes.
- Complex AI behavior.
- Unapproved combat mechanics.
- Health or damage systems.
- Permanent stat upgrades.
- Procedural levels.
- Unnecessary visual polish.
- Multiplayer networking before the architecture is ready.

Prefer simple working implementations over speculative features.

---

## 4. Core Gameplay Rules

### 4.1 Arena

Each arena contains:

- Four columns.
- Eight rows.
- Logical X coordinates from 0 to 3.
- Logical Y coordinates from 0 to 7.

All authoritative positions use integer grid coordinates.

### 4.2 Units

There are three gameplay roles:

**Runner**
- Attempts to reach row 7.
- Must return to row 0 without being tagged.
- A successful round trip wins the offensive arena.

**Horizontal Guard**
- Patrols an assigned horizontal line.
- Attempts to tag runners.

**Center Guard**
- Patrols the central vertical line.
- Attempts to tag runners.

### 4.3 Deployment Limits

A player may deploy up to:

- Three runners.
- Three horizontal guards.
- One center guard.

Runner starting anchors are on row 0.

Horizontal guards occupy assigned patrol lines associated with rows 2, 4, and 6.

The center guard uses the central vertical patrol line between columns 1 and 2.

**Important:** The exact logical representation of the center guard's line must be explicitly specified before implementation. Do not assume it occupies an ordinary cell.

### 4.4 Commands

Runner commands:

- F — Forward
- L — Left
- R — Right
- DL — Diagonal Left
- DR — Diagonal Right
- S — Stay
- T — TAUNT

Guard commands:

- L — Left
- R — Right
- U — Up
- D — Down
- S — Stay
- C — SCARE

Standard command duration: **500 milliseconds**.

TAUNT and SCARE duration: **750 milliseconds**.

Movement is deterministic.

Units execute commands automatically.

Players cannot change commands during battle.

### 4.5 Signature Cards

Each character has exactly three signature cards.

Each card contains exactly four commands.

Card capacity:

- 1-star character: one equipped card.
- 2-star character: two distinct equipped cards.
- 3-star character: three distinct equipped cards.

Cards execute sequentially.

When the last command finishes, execution loops to the first equipped card.

Card order matters.

### 4.6 Character Roster

The MVP contains nine character definitions:

- Four runners.
- Three horizontal guards.
- Two center guards.

Character names, card names, and exact command sequences must be loaded from data definitions.

Do not invent final signature card sequences.

Temporary placeholder definitions are allowed for testing, but must be clearly marked as placeholders.

### 4.7 Merging

Three identical characters of the same star level merge into one character of the next star level.

Maximum star level: three.

Merging increases card capacity, not movement speed or combat statistics.

The inheritance rules for deployment and card configuration are not yet finalized.

### 4.8 Economy

- Tournament-only currency: coins.
- Shop offers: five.
- Shop reroll cost: two coins.
- Bench capacity: nine characters.
- Purchases must be atomic.
- Insufficient coins must reject a purchase.
- Full bench must reject a purchase unless a valid merge frees capacity.
- Championship shop access is disabled.

Starting coins, unit prices, round income, bonuses, and shop weights remain configurable and require approval.

### 4.9 Match Rules

Each match runs two independent arenas:

**Arena A:** Player A offense versus Player B defense.

**Arena B:** Player B offense versus Player A defense.

Each arena victory awards one tournament point.

Possible match scores:

- 2–0
- 1–1
- 0–2

Do not finalize scoring until both arena results are available.

### 4.10 Tournament

Eight participants enter Survival League.

Elimination stages:

8 → 6 → 4 → 2 → 1

The tournament must support:

- Pairings.
- Match execution.
- Results.
- Tournament points.
- Standings.
- Tiebreakers.
- Elimination.
- Championship.
- Champion presentation.

Some tournament rules remain unresolved.

Use configurable, documented provisional rules only when necessary to make a milestone testable.

Do not present provisional rules as finalized design decisions.

---

## 5. Deterministic Simulation Requirements

The simulation must be independent of:

- Rendering frame rate.
- Physics frame rate.
- Animation speed.
- Scene-tree ordering.
- UI input.
- Camera position.
- Visual interpolation.

Use a logical simulation clock based on integer ticks.

**Provisional recommendation:** 50 ms per tick.

At this tick rate:

- Standard commands take 10 ticks.
- TAUNT and SCARE take 15 ticks.

The tick duration must be configurable.

### 5.1 Simulation Pipeline

A simulation step should:

1. Identify scheduled command completions.
2. Calculate intended movement.
3. Validate movement restrictions.
4. Resolve simultaneous movement.
5. Commit logical positions.
6. Resolve command effects.
7. Resolve tagging.
8. Evaluate arena victory conditions.
9. Emit simulation events.
10. Advance logical state.

The precise ordering of simultaneous movement, special effects, tagging, and victory must be finalized and tested.

### 5.2 Logical State

Each simulated unit must track:

- Unique unit ID.
- Character definition ID.
- Player/team ID.
- Role.
- Logical position.
- Star level.
- Equipped card sequence.
- Current card index.
- Current command index.
- Remaining command ticks.
- Active/tagged status.
- Relevant special effect state.
- Runner round-trip progress.

### 5.3 Simulation API

Prefer a headless simulation interface resembling:

```gdscript
simulation.initialize(config)
simulation.step()
simulation.run_until_finished()
simulation.get_state()
simulation.get_result()
simulation.reset()
```

The exact API may evolve, but simulation code must remain usable without loading a 3D arena.

### 5.4 Replay and Determinism

Identical initial states, rules, and seeds must produce identical outcomes.

Use reproducible random number generation only where randomness is explicitly required.

Do not use unseeded randomness inside authoritative battle simulation.

Support state serialization and stable result verification.

A replay mismatch is a test failure.

---

## 6. Project Structure

Use the following initial structure:

```text
res://
├── scenes/
│   ├── main/
│   ├── tournament/
│   ├── arena/
│   ├── characters/
│   ├── ui/
│   ├── replay/
│   └── debug/
├── scripts/
│   ├── core/
│   ├── simulation/
│   ├── tournament/
│   ├── economy/
│   ├── roster/
│   ├── formation/
│   ├── replay/
│   ├── ui/
│   └── utilities/
├── resources/
│   ├── characters/
│   ├── signature_cards/
│   ├── economy/
│   └── tournament/
├── assets/
│   ├── models/
│   ├── materials/
│   ├── textures/
│   ├── audio/
│   └── fonts/
├── tests/
│   ├── simulation/
│   ├── economy/
│   ├── tournament/
│   └── replay/
└── docs/
    ├── milestones/
    ├── decisions/
    └── test_reports/
```

Do not create empty directories or unnecessary scripts merely to satisfy this structure.

Create them when needed.

---

## 7. System Responsibilities

### GameManager

Coordinates application-level session lifecycle and major state transitions.

### TournamentManager

Owns tournament stages, pairings, standings, elimination, and championship state.

### MatchController

Coordinates the two independent arena simulations and produces one authoritative match result.

### ArenaSimulation

Owns logical simulation state, command execution, movement, tagging, and arena victory.

### EconomyManager

Validates and applies coin transactions.

### ShopManager

Generates five reproducible shop offers.

### RosterManager

Owns characters, bench capacity, merging, and star upgrades.

### FormationManager

Validates deployments and equipped card configurations.

### ReplayManager

Records and reconstructs deterministic matches.

### SaveManager

Handles versioned persistent settings and records.

Use clear ownership boundaries.

Do not allow the UI to directly mutate authoritative game state.

---

## 8. 3D Presentation Rules

The game uses two persistent, slightly isometric 3D arenas.

One represents the player's offense.

The other represents the player's defense.

Both arenas remain in the same scene during planning and battle.

Use simple primitives during early milestones:

- PlaneMesh or BoxMesh for grid tiles.
- Capsules, cylinders, or simple stylized meshes for characters.
- Distinct shapes/colors for runners and guards.
- Visible deployment anchors.
- A fixed slightly isometric camera.

Do not spend early milestones creating final character models or environmental artwork.

Visual character movement should interpolate between logical positions.

Interpolation must never change authoritative simulation state.

---

## 9. UI and Interaction Rules

Use Godot Control nodes for the interface.

The UI must support:

- Character selection.
- Drag-and-drop deployment.
- Valid anchor highlighting.
- Invalid drop cancellation.
- Nine-slot bench.
- Five-offer shop.
- Moveset card editing.
- Card reordering.
- Single-unit preview.
- Formation lock.
- Battle observation.
- Results.
- Standings.
- Replay controls.

Reference resolution: 1920×1080.

Minimum supported resolution: 1280×720.

All essential gameplay actions must work with mouse and keyboard.

---

## 10. Milestone-Driven Development

Implement milestones in order.

### Milestone 1 — Deterministic Grid Simulation

**Deliverable:** Runnable 4×8 simulation test scene.

Required features:

- Logical grid.
- Runner movement.
- Guard movement.
- Command timing.
- Movement validation.
- Tagging.
- Round-trip detection.
- Reset.
- Simulation stepping.
- Debug information.

Manual acceptance tests:

1. Run a predefined movement scenario.
2. Observe units moving according to commands.
3. Confirm invalid movement cannot leave the grid.
4. Confirm guards remain within their patrol restrictions.
5. Confirm tagging works.
6. Confirm a valid round trip wins the arena.
7. Reset and repeat the same scenario three times.
8. Verify identical outcomes.

**Pass condition:** All tests succeed with repeatable results.

### Milestone 2 — Character and Moveset Data

**Deliverable:** Runnable character and card test scene.

Required features:

- Nine character definitions.
- Three signature cards per character.
- Four commands per card.
- Star levels.
- Equipped card capacity.
- Card ordering.
- Command looping.

Manual acceptance tests:

1. Select and inspect each character.
2. Equip cards at different star levels.
3. Reorder cards.
4. Execute equipped commands.
5. Verify correct looping.
6. Verify invalid configurations are rejected.

**Pass condition:** Card execution is correct and deterministic.

### Milestone 3 — 3D Arena and Deployment

**Deliverable:** Playable dual-arena planning scene.

Required features:

- Two persistent 3D arenas.
- Slightly isometric camera.
- Valid deployment anchors.
- Character selection.
- Drag-and-drop deployment.
- Invalid drop recovery.
- Bench interaction.
- Single-unit preview.

Manual acceptance tests:

1. Deploy a runner.
2. Deploy horizontal guards.
3. Deploy a center guard.
4. Attempt invalid placements.
5. Return a unit to the bench.
6. Preview a unit's moveset.
7. Start a battle without replacing the arena scenes.

**Pass condition:** All deployment operations behave predictably.

### Milestone 4 — Economy and Roster

**Deliverable:** Functional shop and roster interface.

Required features:

- Coins.
- Five shop offers.
- Two-coin reroll.
- Character purchases.
- Nine-slot bench.
- Three-copy merging.
- Star upgrades.
- Atomic transactions.

Manual acceptance tests:

1. Purchase a character.
2. Verify coin deduction.
3. Reroll the shop.
4. Verify the two-coin cost.
5. Merge three identical characters.
6. Upgrade to three stars.
7. Fill the bench.
8. Attempt an invalid purchase.
9. Verify rejected transactions change nothing.

**Pass condition:** Economy and roster data remain valid.

### Milestone 5 — Match and Tournament

**Deliverable:** Playable eight-player Survival League.

Required features:

- Two arena simulations per match.
- Match results.
- Tournament points.
- Pairings.
- Standings.
- Elimination.
- Championship.
- Champion presentation.

Use deterministic simulated opponents or simple predefined formations for testing.

Do not introduce complex opponent AI unless explicitly approved.

Manual acceptance tests:

1. Start an eight-player tournament.
2. Complete a dual-arena match.
3. Verify match scoring.
4. Verify tournament points.
5. Advance through 8 → 6 → 4 → 2.
6. Confirm the championship shop is disabled.
7. Complete the championship.
8. Verify one champion is declared.

**Pass condition:** A complete tournament runs without manual state modification.

### Milestone 6 — Replay and UI Polish

**Deliverable:** Player-facing UI with replay functionality.

Required features:

- Match results.
- Standings.
- Replay recording.
- Replay loading.
- Play/pause/restart.
- Determinism verification.
- Basic settings.
- UI scaling.

Manual acceptance tests:

1. Complete a match.
2. Open its replay.
3. Play and pause the replay.
4. Restart playback.
5. Verify replay results match the original.
6. Inspect results and standings.
7. Test at 1920×1080.
8. Test at 1280×720.

**Pass condition:** Replay results match and UI remains usable.

### Milestone 7 — Testing and Balancing

**Deliverable:** Stable playable MVP build.

Required features:

- Regression tests.
- Simulation verification.
- Economy validation.
- Tournament validation.
- Usability improvements.
- Bug fixes.
- Balance testing.

Manual acceptance tests:

1. Complete at least three full tournaments.
2. Test multiple formations.
3. Test different equipped cards.
4. Verify repeatability.
5. Test invalid purchases.
6. Test full bench conditions.
7. Test invalid formations.
8. Verify no duplicate tournament points.
9. Verify a new tournament resets session state.

**Pass condition:** All critical tests pass with no known progression-blocking bugs.

---

## 11. Mandatory Developer Test Scenes

Each milestone should provide a dedicated test scene or an accessible debug menu.

Use filenames such as:

```text
scenes/debug/simulation_test.tscn
scenes/debug/moveset_test.tscn
scenes/debug/deployment_test.tscn
scenes/debug/economy_test.tscn
scenes/debug/tournament_test.tscn
scenes/debug/replay_test.tscn
```

Create each scene when its milestone begins.

Test scenes should provide visible controls where appropriate:

- Run.
- Pause.
- Step.
- Reset.
- Load Scenario.
- Show State.
- Show Result.

The developer must be able to test functionality without editing source code.

---

## 12. Automated Testing

Use a repeatable testing approach compatible with the project's Godot version.

Prefer headless tests for simulation and data systems.

Automated tests should cover:

- Grid boundaries.
- Command execution.
- Command timing.
- Collision and tagging.
- Round-trip detection.
- Moveset looping.
- Card capacity.
- Shop transactions.
- Merging.
- Match scoring.
- Tournament standings.
- Replay determinism.

Do not introduce a third-party testing framework without approval.

If using a custom test runner, document how to execute it.

Every test must report clear PASS or FAIL results.

---

## 13. Definition of Done

A task is complete only when:

- The required feature is implemented.
- The project parses and runs.
- No new blocking errors are introduced.
- A manual test is available.
- Relevant automated tests pass.
- The expected result is documented.
- Existing functionality is not broken.
- Known limitations are disclosed.

Never claim that a feature was tested if the test was not actually executed.

Distinguish between:

- Implemented.
- Compiled.
- Automatically tested.
- Manually verified by the developer.

---

## 14. Codex Working Procedure

For every development task:

### Step 1 — Inspect

Read relevant existing files before making changes.

Check the current milestone and project structure.

### Step 2 — Plan

Provide a short implementation plan.

Identify:

- Files to create.
- Files to modify.
- Systems affected.
- Tests to add.
- Unresolved decisions.

### Step 3 — Implement

Implement only the requested milestone or task.

Prefer small, reviewable changes.

### Step 4 — Validate

Run available Godot parsing, project import, and automated tests.

Fix errors caused by the changes.

### Step 5 — Report

Provide:

1. Summary of changes.
2. Files created or modified.
3. How to run the feature.
4. Manual test steps.
5. Expected results.
6. Automated test results.
7. Known issues.
8. Next recommended task.

### Step 6 — Stop

Wait for developer confirmation before advancing to the next milestone.

---

## 15. Documentation Requirements

Maintain:

```text
docs/
├── milestones/
│   ├── milestone_01.md
│   ├── milestone_02.md
│   └── ...
├── decisions/
│   └── gameplay_decisions.md
└── test_reports/
    └── ...
```

Each milestone document should include:

- Objective.
- Scope.
- Deliverables.
- Test scenarios.
- Acceptance criteria.
- Implementation status.
- Known issues.

Record provisional gameplay rules in `gameplay_decisions.md`.

Do not silently change confirmed rules.

---

## 16. Unresolved Gameplay Decisions

The following require explicit confirmation:

- Exact TAUNT/SCARE interactions and effect priority.
- Simultaneous movement collision priority.
- Invalid movement behavior.
- Center guard logical coordinates and patrol behavior.
- Arena timeout duration and outcome.
- Runner turn-around and round-trip detection details.
- Starting coins.
- Unit purchase costs.
- Round income.
- 2–0 bonus amount.
- Shop offer probabilities.
- Merge inheritance behavior.
- Matchmaking algorithm.
- Number of rounds per elimination stage.
- Final tiebreaker rules.
- Championship tie resolution.
- Multiplayer authority and networking model.

When a task depends on an unresolved rule:

1. Identify the missing decision.
2. Propose a simple deterministic default.
3. Explain its gameplay implications.
4. Request approval before treating it as final.

For isolated technical testing, temporary rules may be used if clearly marked and centralized in configuration.

---

## 17. Milestone Completion Report Format

At the end of each milestone, report:

**Milestone:**  
**Status:** PASS / PARTIAL / BLOCKED

**Implemented Features:**
- ...

**Runnable Scene:**
- `res://...`

**Automated Tests:**
- Passed:
- Failed:
- Not executed:

**Manual Acceptance Tests:**
- Test 1:
- Test 2:
- Test 3:

**Known Issues:**
- ...

**Developer Verification Required:**
- ...

**Next Milestone:**
- ...

Do not mark a milestone fully complete until the developer confirms its manual acceptance tests.

---

## 18. Final Development Principle

**Build the smallest playable, verifiable system first.**

Correctness before polish.

Determinism before animation.

Gameplay systems before final artwork.

Playable milestones before additional features.

The developer must always be able to open Godot, run the current project, and observe meaningful progress.

**Never sacrifice testability for implementation speed.**