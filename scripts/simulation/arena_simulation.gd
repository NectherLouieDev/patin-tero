class_name ArenaSimulation
extends RefCounted

const Grid = preload("res://scripts/simulation/grid_map.gd")
const STANDARD_MS: int = 500
const SPECIAL_MS: int = 750

var tick_ms: int = 50
var tick: int = 0
var units: Array[Dictionary] = []
var result: String = "RUNNING"
var events: Array[String] = []
var _initial: Array[Dictionary] = []

func initialize(config: Array[Dictionary], milliseconds_per_tick: int = 50) -> void:
	assert(milliseconds_per_tick > 0 and STANDARD_MS % milliseconds_per_tick == 0 and SPECIAL_MS % milliseconds_per_tick == 0)
	tick_ms = milliseconds_per_tick
	_initial = config.duplicate(true)
	reset()

func reset() -> void:
	tick = 0
	result = "RUNNING"
	events.clear()
	units = _initial.duplicate(true)
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.id) < str(b.id))
	for unit in units:
		assert(unit.has("id") and unit.has("role") and unit.has("pos") and unit.has("commands"))
		assert(not unit.commands.is_empty())
		unit["index"] = 0
		unit["remaining"] = _duration(str(unit.commands[0]))
		unit["active"] = true
		unit["tagged"] = false
		unit["reached_end"] = false
		unit["last_command"] = ""

func step() -> void:
	if result != "RUNNING":
		return
	tick += 1
	events.clear()
	var completing: Array[Dictionary] = []
	var destinations: Dictionary = {}
	for unit in units:
		if not unit.active:
			continue
		unit.remaining -= 1
		if unit.remaining == 0:
			completing.append(unit)
			destinations[unit.id] = _destination(unit, str(unit.commands[unit.index]))
	# All destinations are calculated from the pre-step state, then committed in ID order.
	for unit in completing:
		var command: String = str(unit.commands[unit.index])
		unit.pos = destinations[unit.id]
		unit.last_command = command
		events.append("%s: %s -> %s" % [unit.id, command, unit.pos])
		unit.index = (unit.index + 1) % unit.commands.size()
		unit.remaining = _duration(str(unit.commands[unit.index]))
	# Provisional: same-cell tags after movement; tag wins over same-tick goal arrival.
	for runner in units:
		if runner.role != "runner" or not runner.active:
			continue
		for guard in units:
			if guard.role == "runner" or not guard.active:
				continue
			var touching: bool = runner.pos == guard.pos
			if guard.role == "center":
				touching = runner.pos.y == guard.pos.y and runner.pos.x in [1, 2]
			if touching:
				runner.active = false
				runner.tagged = true
				events.append("%s tagged by %s" % [runner.id, guard.id])
			break
	for runner in units:
		if runner.role != "runner" or not runner.active:
			continue
		if runner.pos.y == 7:
			runner.reached_end = true
		if runner.reached_end and runner.pos.y == 0:
			result = "RUNNER_WIN"
			events.append("%s completed round trip" % runner.id)
			return
	var any_runner: bool = false
	for unit in units:
		if unit.role == "runner" and unit.active:
			any_runner = true
	if not any_runner:
		result = "GUARD_WIN"

func run_until_finished(max_ticks: int = 1000) -> String:
	while result == "RUNNING" and tick < max_ticks:
		step()
	return result

func get_state() -> Dictionary:
	return {"tick": tick, "result": result, "units": units.duplicate(true)}

func _duration(command: String) -> int:
	return (SPECIAL_MS if command in ["T", "C"] else STANDARD_MS) / tick_ms

func _destination(unit: Dictionary, command: String) -> Vector2i:
	var current: Vector2i = unit.pos
	var delta: Vector2i = Vector2i.ZERO
	match command:
		"F": delta = Vector2i(0, 1)
		"L": delta = Vector2i(-1, 0)
		"R": delta = Vector2i(1, 0)
		"DL": delta = Vector2i(-1, 1)
		"DR": delta = Vector2i(1, 1)
		"U": delta = Vector2i(0, -1)
		"D": delta = Vector2i(0, 1)
		"S", "T", "C": pass # Effects are deliberately unspecified.
		_: return current
	var role: String = str(unit.role)
	if role == "runner" and command not in ["F", "L", "R", "DL", "DR", "S", "T", "U"]:
		return current
	if role != "runner" and command not in ["L", "R", "U", "D", "S", "C"]:
		return current
	var target: Vector2i = current + delta
	if role == "center":
		return target if target.x == -1 and target.y >= 0 and target.y < Grid.ROWS else current
	if not Grid.contains_cell(target):
		return current
	if role == "horizontal" and target.y != int(unit.get("patrol_row", current.y)):
		return current
	return target
