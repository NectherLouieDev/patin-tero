extends SceneTree

const Roster = preload("res://scripts/roster/moveset_model.gd")
const Formation = preload("res://scripts/formation/formation_model.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var roster = Roster.new()
	check("load roster", roster.load_definitions() == "")
	var formation = Formation.new()
	formation.initialize(roster.definitions)
	check("runner offense row 0", formation.place(0, "offense", Vector2i(0, 0)) == "")
	var before: Dictionary = formation.snapshot()
	check("invalid runner row rejected without change", formation.place(0, "offense", Vector2i(0, 1)) != "" and formation.snapshot() == before)
	check("occupied anchor rejected", formation.place(1, "offense", Vector2i(0, 0)) != "")
	check("three runner limit", formation.place(1, "offense", Vector2i(1, 0)) == "" and formation.place(2, "offense", Vector2i(2, 0)) == "" and formation.place(3, "offense", Vector2i(3, 0)) != "")
	check("guard patrol anchor", formation.place(4, "defense", Vector2i(0, 2)) == "")
	check("guard wrong row rejected", formation.place(5, "defense", Vector2i(0, 3)) != "")
	check("one guard per row", formation.place(5, "defense", Vector2i(1, 2)) != "")
	check("center lane anchor", formation.place(7, "defense", Vector2i(-1, 3)) == "")
	check("center ordinary cell rejected", formation.place(8, "defense", Vector2i(1, 3)) != "")
	check("return to bench", formation.return_to_bench(1) == "" and not formation.placements.has(1))
	var scene: PackedScene = load("res://scenes/debug/deployment_test.tscn")
	var view: Node3D = scene.instantiate()
	root.add_child(view)
	check("both arena nodes exist", view.has_node("Offense") and view.has_node("Defense"))
	view.formation.place(0, "offense", Vector2i(0, 0))
	view.formation.place(4, "defense", Vector2i(0, 2))
	view._begin_battle()
	check("battle keeps both arenas", view.battling and view.has_node("Offense") and view.has_node("Defense") and view.offense.units.size() > 0 and view.defense.units.size() > 0)
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1
