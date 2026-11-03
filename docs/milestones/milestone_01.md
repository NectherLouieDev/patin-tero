# Milestone 1 — Deterministic Grid Simulation

Status: implemented and headless checks passed; awaiting developer playtest.

## Deliverable

Open `res://scenes/debug/simulation_test.tscn`. It has a 4 × 8 grid made of scene tree mesh instances, a fixed camera, runner and guard placeholders, named scenarios, and Run, Pause, Step, Reset controls.

## Manual acceptance

1. Run Basic movement. The runner advances on every tenth tick. Pause and Step to confirm one logical tick per press.
2. Run Boundary and patrol. Repeated left moves stay at column 0; the guard stays on row 4 despite its Up command.
3. Run Tag. The runner is tagged and the result becomes GUARD_WIN.
4. Run Round trip. The runner reaches row 7, returns to row 0 with the provisional U command, and wins.
5. Run Repeatability three times with Reset between runs. Compare tick, coordinates, command, and result.

Automated command: `godot --headless --path . --script res://tests/simulation/run_tests.gd`

Validation on Godot 4.7.1: project import passed, debug scene launched headlessly, and eight automated checks passed with zero failures. Visual interaction still needs developer playtest.

## Known open decisions

See `docs/decisions/gameplay_decisions.md`. Center guard geometry, runner turn around, simultaneous interactions, special effects, and arena timeout require approval.
