extends SceneTree

const Session = preload("res://scripts/core/shared_session.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = Session.new()
	check("session starts with owned starter IDs", session.initialize(42, true) == "" and session.shop.bench.size() == 2 and session.get_instance(1).instance_id == 1 and session.get_instance(2).instance_id == 2)
	var offer: int = session.shop.offers[0]
	var coins_before: int = session.shop.coins
	check("purchase retains stable new ID", session.buy(0).begins_with("Purchased") and session.get_instance(3).definition_index == offer and session.shop.coins == coins_before - int(session.shop.config.prices[offer]))
	check("invalid placement preserves instance", session.deploy(3, "offense" if session.shop.definitions[offer].role != "runner" else "defense", Vector2i(0, 2)) != "" and session.get_instance(3).location == "bench")
	check("starter roles deploy", session.deploy(1, "offense", Vector2i(0, 0)) == "" and session.deploy(2, "defense", Vector2i(0, 2)) == "")
	var role: String = session.shop.definitions[offer].role
	var arena: String = "offense" if role == "runner" else "defense"
	var cell: Vector2i = Vector2i(1, 0) if role == "runner" else (Vector2i(0, 4) if role == "horizontal" else Vector2i(-1, 3))
	check("purchased ID deploys", session.deploy(3, arena, cell) == "" and session.get_instance(3).location == arena)
	check("one-star card capacity enforced", session.equip(3, 1) == "Card capacity reached")
	check("formation locks same instance IDs", session.lock() == "" and session.get_snapshot().units.any(func(unit: Dictionary) -> bool: return unit.instance_id == 3))
	var snapshot: Dictionary = session.get_snapshot()
	check("post-lock mutation rejected", session.return_to_bench(3) == "Formation is locked" and session.buy(1) == "Formation is locked" and session.get_snapshot() == snapshot)
	var match_data: Dictionary = session.start_test_match()
	check("match input keeps purchased ID", match_data.has("result") and match_data.replay.snapshot_a.units.any(func(unit: Dictionary) -> bool: return unit.instance_id == 3))
	session.begin_next_round()
	check("next round keeps owned ID and placement", not session.locked and session.get_instance(3).location == arena and session.get_instance(3).instance_id == 3)
	var full = Session.new()
	full.initialize(42, false)
	full.shop.setup_full_bench()
	var state_before: String = str(full.shop.bench) + str(full.shop.coins) + str(full.shop.offers)
	check("full bench rejection is atomic", full.buy(0) == "Bench is full" and state_before == str(full.shop.bench) + str(full.shop.coins) + str(full.shop.offers))
	var merged = Session.new()
	merged.initialize(42, false)
	merged.shop.setup_merge_bench(merged.shop.offers[0])
	merged.shop.bench[0].cards = [0]
	var survivor_id: int = merged.shop.bench[0].instance_id
	check("full bench merge preserves survivor ID", merged.buy(0).begins_with("Purchased") and merged.get_instance(survivor_id).star == 2 and merged.get_instance(survivor_id).cards == [0])
	check("merge increases card capacity", merged.equip(survivor_id, 1) == "")
	var deployed_merge = Session.new()
	deployed_merge.initialize(42, false)
	deployed_merge.shop.bench.clear()
	deployed_merge.shop.bench.append({"instance_id": 1, "definition_index": 0, "star": 1, "location": "bench", "cards": [0]})
	deployed_merge.shop.bench.append({"instance_id": 2, "definition_index": 0, "star": 1, "location": "bench", "cards": [2]})
	deployed_merge.shop.next_instance_id = 3
	check("deployed copy can be set before merge", deployed_merge.deploy(2, "offense", Vector2i(2, 0)) == "")
	deployed_merge.shop.offers[0] = 0
	var deployed_result: String = deployed_merge.buy(0)
	check("merge retains deployed anchor and card order", deployed_result.contains("Merged into #2") and deployed_merge.shop.bench.size() == 1 and deployed_merge.get_instance(2).star == 2 and deployed_merge.get_instance(2).cell == Vector2i(2, 0) and deployed_merge.get_instance(2).cards == [2] and deployed_merge.get_instance(1).is_empty() and deployed_merge.get_instance(3).is_empty())
	session.initialize(42, true)
	check("new session resets state", session.shop.bench.size() == 2 and session.get_instance(3).is_empty() and session.get_snapshot().is_empty() and session.shop.coins == int(session.shop.config.starting_coins))
	var scene: PackedScene = load("res://scenes/debug/shared_session_test.tscn")
	var view: Node3D = scene.instantiate()
	root.add_child(view)
	check("integration scene has persistent arena views", view.has_node("Offense") and view.has_node("Defense"))
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1
