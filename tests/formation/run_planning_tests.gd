extends SceneTree

const Roster = preload("res://scripts/roster/moveset_model.gd")
const Formation = preload("res://scripts/formation/formation_model.gd")
const Planning = preload("res://scripts/formation/planning_model.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var roster = Roster.new()
	check("roster loads", roster.load_definitions() == "")
	var formation = Formation.new()
	formation.initialize(roster.definitions)
	var planning = Planning.new()
	planning.initialize(roster.definitions, formation)
	check("empty formation cannot lock", planning.lock() == "Deploy at least one runner and one guard")
	check("unowned character rejected", planning.deploy(20, "offense", Vector2i(0, 0)) == "Character is not owned")
	check("valid runner and guard deploy", planning.deploy(0, "offense", Vector2i(0, 0)) == "" and planning.deploy(4, "defense", Vector2i(0, 2)) == "")
	var before: Dictionary = formation.snapshot()
	check("wrong-role edit preserves placement", planning.deploy(0, "defense", Vector2i(0, 2)) != "" and formation.snapshot() == before)
	check("occupied anchor rejected", planning.deploy(1, "offense", Vector2i(0, 0)) != "")
	check("one-star card capacity", planning.equip(0, 1) == "Card capacity reached")
	check("two-star card configuration", planning.set_star(0, 2) == "" and planning.equip(0, 1) == "")
	check("duplicate card rejected", planning.equip(0, 1) == "Card already equipped")
	check("ordered cards change", planning.move_card(0, 1, -1) == "" and planning.equipped[0] == [1, 0])
	check("valid formation locks", planning.lock() == "" and planning.locked)
	var snapshot: Dictionary = planning.get_locked_snapshot()
	check("snapshot includes ordered commands", snapshot.units[0].card_ids[0] == roster.definitions[0].cards[1].id and snapshot.units[0].commands.size() == 8)
	check("post-lock edits rejected", planning.deploy(1, "offense", Vector2i(1, 0)) == "Formation is locked" and planning.return_to_bench(0) == "Formation is locked" and planning.equip(0, 2) == "Formation is locked")
	check("snapshot unchanged after rejected edits", planning.get_locked_snapshot() == snapshot)
	var external_copy: Dictionary = planning.get_locked_snapshot()
	external_copy.units[0].cell = Vector2i(3, 7)
	check("snapshot getter returns deep copy", planning.get_locked_snapshot() == snapshot)
	var scene: PackedScene = load("res://scenes/debug/planning_test.tscn")
	var view: Node3D = scene.instantiate()
	root.add_child(view)
	check("planning scene keeps both arenas", view.has_node("Offense") and view.has_node("Defense"))
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1
