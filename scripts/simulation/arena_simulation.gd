class_name ArenaSimulation
extends RefCounted

const Grid = preload("res://scripts/simulation/grid_map.gd")
const STANDARD_MS: int = 500
const SPECIAL_MS: int = 750

var tick_ms: int = 50
var max_ticks: int = 320
var tick: int = 0
var units: Array[Dictionary] = []
var result: String = "RUNNING"
var result_reason: String = ""
var events: Array[String] = []
var _initial: Array[Dictionary] = []

func initialize(config: Array[Dictionary], milliseconds_per_tick: int = 50, time_limit_ticks: int = 320) -> void:
	assert(milliseconds_per_tick > 0 and STANDARD_MS % milliseconds_per_tick == 0 and SPECIAL_MS % milliseconds_per_tick == 0)
	assert(time_limit_ticks > 0)
	tick_ms = milliseconds_per_tick
	max_ticks = time_limit_ticks
	_initial = config.duplicate(true)
	reset()

func reset() -> void:
	tick = 0
	result = "RUNNING"
	result_reason = ""
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
		unit["active_effect"] = str(unit.commands[0]) if str(unit.commands[0]) in ["T", "C"] else ""
		unit["completed_trip"] = false
		unit["victory"] = false

func step() -> void:
	if result != "RUNNING":
		return
	tick += 1
	events.clear()
	var previous: Dictionary = {}
	for unit in units: previous[unit.id] = unit.pos
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
		if command in ["T", "C"]: events.append("%s: %s ended" % [unit.id, "TAUNT" if command == "T" else "SCARE"])
		unit.pos = destinations[unit.id]
		unit.last_command = command
		events.append("%s: %s -> %s" % [unit.id, command, unit.pos])
		unit.index = (unit.index + 1) % unit.commands.size()
		unit.remaining = _duration(str(unit.commands[unit.index]))
		var next_command: String = str(unit.commands[unit.index])
		unit.active_effect = next_command if next_command in ["T", "C"] else ""
		if unit.active_effect != "": events.append("%s: %s began" % [unit.id, "TAUNT" if next_command == "T" else "SCARE"])
	# Provisional: compare both complete movement segments at the same normalized
	# instant. Tags precede a same-tick round trip and guards are checked by ID.
	for runner in units:
		if runner.role != "runner" or not runner.active:
			continue
		for guard in units:
			if guard.role == "runner" or not guard.active:
				continue
			var touching: bool = _paths_intersect(previous[runner.id], runner.pos, previous[guard.id], guard.pos, guard.role)
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
			runner.completed_trip = true
			runner.victory = true
			result = "RUNNER_WIN"
			result_reason = "%s completed the round trip" % runner.id
			events.append(result_reason)
			return
	var any_runner: bool = false
	for unit in units:
		if unit.role == "runner" and unit.active:
			any_runner = true
	if not any_runner:
		result = "GUARD_WIN"
		for unit in units:
			if unit.role != "runner" and unit.active: unit.victory = true
		result_reason = "All runners tagged"
		for event in events:
			if " tagged by " in event: result_reason += "; " + event
	elif tick >= max_ticks:
		result = "GUARD_WIN"
		for unit in units:
			if unit.role != "runner" and unit.active: unit.victory = true
		result_reason = "Time limit reached at tick %d" % tick
		events.append(result_reason)

func run_until_finished(max_ticks: int = 1000) -> String:
	while result == "RUNNING" and tick < max_ticks:
		step()
	return result

func get_state() -> Dictionary:
	return {"tick": tick, "result": result, "reason": result_reason, "units": units.duplicate(true)}

func preview_path(role: String, start: Vector2i, commands: Array, command_count: int = 8) -> Array[Vector2i]:
	var unit: Dictionary = {"role": role, "pos": start, "reached_end": false, "patrol_row": start.y}
	var path: Array[Vector2i] = [start]
	if commands.is_empty(): return path
	for index in command_count:
		unit.pos = _destination(unit, str(commands[index % commands.size()]))
		path.append(unit.pos)
		if role == "runner" and unit.pos.y == 7: unit.reached_end = true
		if role == "runner" and unit.reached_end and unit.pos.y == 0: break
	return path

func _duration(command: String) -> int:
	return (SPECIAL_MS if command in ["T", "C"] else STANDARD_MS) / tick_ms

func _paths_intersect(runner_from: Vector2i, runner_to: Vector2i, guard_from: Vector2i, guard_to: Vector2i, guard_role: String) -> bool:
	var r0 := Vector2(float(runner_from.x), float(runner_from.y))
	var r1 := Vector2(float(runner_to.x), float(runner_to.y))
	var g0 := Vector2(1.5, float(guard_from.y)) if guard_role == "center" else Vector2(float(guard_from.x), float(guard_from.y))
	var g1 := Vector2(1.5, float(guard_to.y)) if guard_role == "center" else Vector2(float(guard_to.x), float(guard_to.y))
	var relative_velocity: Vector2 = (r1 - r0) - (g1 - g0)
	var gap: Vector2 = g0 - r0
	var instant: float = 0.0
	var constrained: bool = false
	for axis in 2:
		var speed: float = relative_velocity[axis]
		var distance: float = gap[axis]
		if absf(speed) < 0.0001:
			if absf(distance) > 0.0001: return false
		else:
			var candidate: float = distance / speed
			if constrained and absf(instant - candidate) > 0.0001: return false
			instant = candidate
			constrained = true
	return instant <= 1.0001 and instant >= -0.0001

func _destination(unit: Dictionary, command: String) -> Vector2i:
	var current: Vector2i = unit.pos
	var delta: Vector2i = Vector2i.ZERO
	var returning: bool = unit.role == "runner" and bool(unit.get("reached_end", false))
	match command:
		"F": delta = Vector2i(0, -1 if returning else 1)
		"L": delta = Vector2i(1 if returning else -1, 0) if unit.role == "runner" else Vector2i(-1, 0)
		"R": delta = Vector2i(-1 if returning else 1, 0) if unit.role == "runner" else Vector2i(1, 0)
		"DL": delta = Vector2i(1 if returning else -1, -1 if returning else 1)
		"DR": delta = Vector2i(-1 if returning else 1, -1 if returning else 1)
		"U": delta = Vector2i(0, -1)
		"D": delta = Vector2i(0, 1)
		"S", "T", "C": pass # Effects are deliberately unspecified.
		_: return current
	var role: String = str(unit.role)
	if role == "runner" and command not in ["F", "L", "R", "DL", "DR", "S", "T"]:
		return current
	if role == "horizontal" and command not in ["L", "R", "S", "C"]:
		return current
	if role == "center" and command not in ["U", "D", "S", "C"]:
		return current
	var target: Vector2i = current + delta
	if role == "center":
		return target if target.x == -1 and target.y >= 0 and target.y < Grid.ROWS else current
	if not Grid.contains_cell(target):
		return current
	if role == "horizontal" and target.y != int(unit.get("patrol_row", current.y)):
		return current
	return target
