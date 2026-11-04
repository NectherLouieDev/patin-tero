extends SceneTree

const Simulation = preload("res://scripts/simulation/arena_simulation.gd")
var failures: int = 0

func _initialize() -> void:
	_timing_and_bounds()
	_patrol_and_tag()
	_round_trip_and_repeatability()
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func _check(label: String, condition: bool) -> void:
	print("%s: %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures += 1

func _unit(id: String, role: String, pos: Vector2i, commands: Array[String]) -> Dictionary:
	return {"id": id, "role": role, "pos": pos, "commands": commands}

func _timing_and_bounds() -> void:
	var sim = Simulation.new()
	sim.initialize([_unit("r", "runner", Vector2i(0, 0), ["L", "T", "F"])])
	for i in 9: sim.step()
	_check("standard command waits 10 ticks", sim.units[0].pos == Vector2i(0, 0) and sim.units[0].remaining == 1)
	sim.step()
	_check("invalid edge move stays", sim.units[0].pos == Vector2i(0, 0))
	for i in 15: sim.step()
	_check("special command waits 15 ticks", sim.units[0].pos == Vector2i(0, 0) and sim.units[0].index == 2)
	for i in 10: sim.step()
	_check("runner moves on completion", sim.units[0].pos == Vector2i(0, 1))

func _patrol_and_tag() -> void:
	var sim = Simulation.new()
	var guard: Dictionary = _unit("g", "horizontal", Vector2i(1, 2), ["U", "L"])
	guard.patrol_row = 2
	sim.initialize([guard, _unit("r", "runner", Vector2i(0, 1), ["S", "F"])])
	for i in 10: sim.step()
	_check("guard stays on patrol row", sim.units[0].pos == Vector2i(1, 2))
	for i in 10: sim.step()
	_check("same-cell tag resolves", sim.result == "GUARD_WIN" and sim.units[1].tagged)

func _round_trip_and_repeatability() -> void:
	var config: Array[Dictionary] = [_unit("r", "runner", Vector2i(0, 0), ["F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F"])]
	var sim = Simulation.new()
	sim.initialize(config)
	_check("round trip wins", sim.run_until_finished(200) == "RUNNER_WIN" and sim.tick == 140)
	var first: String = str(sim.get_state())
	sim.reset()
	sim.run_until_finished(200)
	_check("reset repeats exact state", str(sim.get_state()) == first)
