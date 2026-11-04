extends SceneTree

const Controller = preload("res://scripts/match/match_controller.gd")
const Fixtures = preload("res://scripts/match/match_fixtures.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for score_case in 3:
		var fixture: Dictionary = Fixtures.build(score_case)
		var game = Controller.new()
		check("fixture %s initializes" % fixture.name, game.initialize(fixture.a, fixture.b, 42) == "")
		check("independent arena states", game.arena_a != game.arena_b and game.arena_a.units[0] != game.arena_b.units[0])
		for tick in 20:
			game.step()
		if score_case != 1:
			check("score waits for slower arena %s" % fixture.name, not game.finalized and game.result.is_empty())
		var result: Dictionary = game.run_to_completion()
		check("score %s" % fixture.name, result.score == fixture.name and game.finalization_count == 1)
		for extra in 10: game.step()
		check("finalizes only once %s" % fixture.name, game.finalization_count == 1 and game.result == result)
		var record: Dictionary = game.replay_record()
		var replay = Controller.new()
		check("replay initializes %s" % fixture.name, replay.initialize(record.snapshot_a, record.snapshot_b, record.seed) == "")
		check("replay matches authoritative result %s" % fixture.name, replay.run_to_completion() == record.expected_result)
		var faster_view = Controller.new()
		faster_view.initialize(fixture.a, fixture.b, 42)
		while not faster_view.finalized:
			for visual_batch in 4:
				faster_view.step()
		check("visual batch speed preserves result %s" % fixture.name, faster_view.result == result)
	var invalid = Controller.new()
	check("unlocked formation rejected", invalid.initialize({"locked": false, "units": []}, Fixtures.build(0).b) == "Both formations must be locked")
	var scene: PackedScene = load("res://scenes/debug/match_test.tscn")
	var view: Node3D = scene.instantiate()
	root.add_child(view)
	check("match scene retains both arena nodes", view.has_node("Offense") and view.has_node("Defense"))
	view._start_match()
	check("scene starts both snapshots", view.running and view.controller.arena_a.units.size() == 2 and view.controller.arena_b.units.size() == 2)
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1
