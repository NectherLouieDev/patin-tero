class_name MatchController
extends RefCounted

const Simulation = preload("res://scripts/simulation/arena_simulation.gd")

var arena_a = Simulation.new() # A offense versus B defense
var arena_b = Simulation.new() # B offense versus A defense
var seed_value: int = 0
var finalized: bool = false
var finalization_count: int = 0
var result: Dictionary = {}
var _snapshot_a: Dictionary = {}
var _snapshot_b: Dictionary = {}

func initialize(snapshot_a: Dictionary, snapshot_b: Dictionary, seed: int = 42) -> String:
	if not snapshot_a.get("locked", false) or not snapshot_b.get("locked", false):
		return "Both formations must be locked"
	if not snapshot_a.has("units") or not snapshot_b.has("units"):
		return "Missing formation units"
	var config_a: Array[Dictionary] = []
	var config_b: Array[Dictionary] = []
	var error := _append_units(config_a, snapshot_a.units, "offense", "A")
	if error != "": return error
	error = _append_units(config_a, snapshot_b.units, "defense", "B")
	if error != "": return error
	error = _append_units(config_b, snapshot_b.units, "offense", "B")
	if error != "": return error
	error = _append_units(config_b, snapshot_a.units, "defense", "A")
	if error != "": return error
	if not _has_role(config_a, "runner") or not _has_guard(config_a) or not _has_role(config_b, "runner") or not _has_guard(config_b):
		return "Each arena needs a runner and a guard"
	_snapshot_a = snapshot_a.duplicate(true)
	_snapshot_b = snapshot_b.duplicate(true)
	seed_value = seed
	arena_a.initialize(config_a)
	arena_b.initialize(config_b)
	finalized = false
	finalization_count = 0
	result.clear()
	return ""

func step() -> void:
	if finalized:
		return
	arena_a.step()
	arena_b.step()
	if arena_a.result == "RUNNING" or arena_b.result == "RUNNING":
		return
	var winner_a: String = "A" if arena_a.result == "RUNNER_WIN" else "B"
	var winner_b: String = "B" if arena_b.result == "RUNNER_WIN" else "A"
	var points_a: int = int(winner_a == "A") + int(winner_b == "A")
	var points_b: int = 2 - points_a
	result = {
		"arena_a": {"winner": winner_a, "type": arena_a.result, "tick": arena_a.tick, "reason": arena_a.result_reason},
		"arena_b": {"winner": winner_b, "type": arena_b.result, "tick": arena_b.tick, "reason": arena_b.result_reason},
		"points_a": points_a, "points_b": points_b, "score": "%d-%d" % [points_a, points_b],
		"seed": seed_value
	}
	finalized = true
	finalization_count += 1

func run_to_completion(max_ticks: int = 1000) -> Dictionary:
	while not finalized and max(arena_a.tick, arena_b.tick) < max_ticks:
		step()
	return result.duplicate(true)

func replay_record() -> Dictionary:
	return {"seed": seed_value, "snapshot_a": _snapshot_a.duplicate(true), "snapshot_b": _snapshot_b.duplicate(true), "expected_result": result.duplicate(true)}

func _append_units(output: Array[Dictionary], units: Array, assignment: String, player: String) -> String:
	for unit in units:
		if not unit is Dictionary or not unit.has("arena") or not unit.has("role") or not unit.has("cell") or not unit.has("commands") or not unit.has("instance_id"):
			return "Invalid locked unit"
		if unit.arena != assignment:
			continue
		if unit.commands.is_empty():
			return "Unit has no commands"
		var simulated: Dictionary = {"id": "%s_%d" % [player, unit.instance_id], "role": unit.role, "pos": unit.cell, "commands": unit.commands.duplicate(true), "team": player, "definition_id": unit.get("definition_id", ""), "star": unit.get("star", 1)}
		if unit.role == "horizontal":
			simulated["patrol_row"] = unit.cell.y
		output.append(simulated)
	return ""

func _has_role(units: Array[Dictionary], role: String) -> bool:
	for unit in units:
		if unit.role == role:
			return true
	return false

func _has_guard(units: Array[Dictionary]) -> bool:
	for unit in units:
		if unit.role in ["horizontal", "center"]:
			return true
	return false
