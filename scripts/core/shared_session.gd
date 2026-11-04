class_name SharedSession
extends RefCounted

const Shop = preload("res://scripts/economy/shop_model.gd")
const Grid = preload("res://scripts/simulation/grid_map.gd")
const Match = preload("res://scripts/match/match_controller.gd")
const Fixtures = preload("res://scripts/match/match_fixtures.gd")
const Allowed = preload("res://scripts/roster/moveset_model.gd")

var shop = Shop.new()
var locked: bool = false
var _snapshot: Dictionary = {}

func initialize(seed: int = 42, with_starters: bool = true) -> String:
	var error: String = shop.load_data()
	if error != "": return error
	shop.reset(seed)
	locked = false
	_snapshot.clear()
	if with_starters:
		shop.bench.append(_new_instance(0, 1))
		shop.bench.append(_new_instance(4, 2))
		shop.next_instance_id = 3
	return ""

func buy(slot: int) -> String:
	if locked: return "Formation is locked"
	var result: String = shop.buy(slot)
	if result.begins_with("Purchased"):
		_normalize_instances()
	return result

func reroll() -> String:
	if locked: return "Formation is locked"
	return shop.reroll()

func get_instance(instance_id: int) -> Dictionary:
	for item in shop.bench:
		if int(item.instance_id) == instance_id:
			return item.duplicate(true)
	return {}

func deploy(instance_id: int, arena: String, cell: Vector2i) -> String:
	if locked: return "Formation is locked"
	var item: Dictionary = _find(instance_id)
	if item.is_empty(): return "Instance is not owned"
	var error: String = _validate_placement(item, arena, cell)
	if error != "": return error
	item.location = arena
	item.cell = cell
	return ""

func return_to_bench(instance_id: int) -> String:
	if locked: return "Formation is locked"
	var item: Dictionary = _find(instance_id)
	if item.is_empty(): return "Instance is not owned"
	if item.get("location", "bench") == "bench": return "Instance is already on the bench"
	if shop._bench_count(shop.bench) >= int(shop.config.bench_capacity): return "Bench is full"
	item.location = "bench"
	item.erase("cell")
	return ""

func equip(instance_id: int, card_index: int) -> String:
	if locked: return "Formation is locked"
	var item: Dictionary = _find(instance_id)
	if item.is_empty(): return "Instance is not owned"
	if card_index < 0 or card_index >= 3: return "Invalid card"
	var cards: Array = item.get("cards", [0])
	if card_index in cards: return "Card already equipped"
	if cards.size() >= int(item.star): return "Card capacity reached"
	cards.append(card_index)
	item.cards = cards
	return ""

func set_cards(instance_id: int, card_indices: Array) -> String:
	if locked: return "Formation is locked"
	var item: Dictionary = _find(instance_id)
	if item.is_empty(): return "Instance is not owned"
	if card_indices.is_empty() or card_indices.size() > int(item.star): return "Invalid card capacity"
	var definition: Dictionary = shop.definitions[int(item.definition_index)]
	var seen: Dictionary = {}
	for value in card_indices:
		if not value is int or value < 0 or value >= definition.cards.size() or seen.has(value):
			return "Invalid or duplicate card"
		seen[value] = true
		for command in definition.cards[value].commands:
			if command not in Allowed.ALLOWED[definition.role]: return "Role-invalid command"
	item.cards = card_indices.duplicate()
	return ""

func move_card(instance_id: int, card_index: int, direction: int) -> String:
	if locked: return "Formation is locked"
	var item: Dictionary = _find(instance_id)
	if item.is_empty(): return "Instance is not owned"
	var cards: Array = item.get("cards", [0])
	var from: int = cards.find(card_index)
	var target: int = from + direction
	if from < 0 or target < 0 or target >= cards.size(): return "Cannot move card in that direction"
	cards.remove_at(from)
	cards.insert(target, card_index)
	item.cards = cards
	return ""

func lock() -> String:
	if locked: return "Formation is already locked"
	var offense: int = 0
	var defense: int = 0
	var units: Array[Dictionary] = []
	for item in shop.bench:
		var location: String = str(item.get("location", "bench"))
		if location == "bench": continue
		var error: String = _validate_placement(item, location, item.cell)
		if error != "": return error
		var definition: Dictionary = shop.definitions[int(item.definition_index)]
		var cards: Array = item.get("cards", [0])
		if cards.is_empty() or cards.size() > int(item.star): return "Invalid card capacity"
		var seen: Dictionary = {}
		var card_ids: Array[String] = []
		var commands: Array[String] = []
		for card_index in cards:
			if card_index < 0 or card_index >= 3 or seen.has(card_index): return "Invalid or duplicate card"
			seen[card_index] = true
			var card: Dictionary = definition.cards[card_index]
			card_ids.append(str(card.id))
			for command in card.commands:
				if command not in Allowed.ALLOWED[definition.role]: return "Role-invalid command"
				commands.append(str(command))
		units.append({"instance_id": item.instance_id, "definition_id": definition.id, "role": definition.role, "arena": location, "cell": item.cell, "star": item.star, "card_ids": card_ids, "commands": commands})
		if location == "offense": offense += 1
		else: defense += 1
	if offense == 0 or defense == 0: return "Deploy at least one runner and one guard"
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.instance_id < b.instance_id)
	_snapshot = {"locked": true, "units": units}
	locked = true
	shop.planning_open = false
	return ""

func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

func start_test_match() -> Dictionary:
	if not locked: return {"error": "Lock the formation first"}
	var player: Dictionary = get_snapshot()
	# Provisional return command lets placeholder cards complete a visible test match.
	for unit in player.units:
		unit.commands = Fixtures.RETURN_TRIP.duplicate() if unit.role == "runner" else ["S"]
	var opponent: Dictionary = Fixtures.build(0).b
	var game = Match.new()
	var error: String = game.initialize(player, opponent, shop.seed_value)
	if error != "": return {"error": error}
	var outcome: Dictionary = game.run_to_completion()
	if outcome.is_empty(): return {"error": "Match did not finish"}
	return {"result": outcome, "replay": game.replay_record()}

func begin_next_round(shop_enabled: bool = true, income: int = 0) -> String:
	var error: String = shop.begin_round(income, shop_enabled)
	if error != "": return error
	locked = false
	_snapshot.clear()
	return ""

func auto_deploy_first_roles(guard_column: int = 0) -> String:
	if locked: return "Formation is locked"
	var runners: int = 0
	var horizontals: int = 0
	var centers: int = 0
	for item in shop.bench:
		if item.get("location", "bench") == "bench": continue
		var role: String = shop.definitions[int(item.definition_index)].role
		if role == "runner": runners += 1
		elif role == "horizontal": horizontals += 1
		elif role == "center": centers += 1
	for item in shop.bench:
		if item.get("location", "bench") != "bench": continue
		var role: String = shop.definitions[int(item.definition_index)].role
		if role == "runner" and runners < 3:
			for column in 4:
				var cell := Vector2i(column, 0)
				if _validate_placement(item, "offense", cell) == "":
					var error: String = deploy(item.instance_id, "offense", cell)
					if error != "": return error
					runners += 1
					break
		elif role == "horizontal" and horizontals < 3:
			for row in [2, 4, 6]:
				var cell := Vector2i(guard_column, row)
				if _validate_placement(item, "defense", cell) == "":
					var error: String = deploy(item.instance_id, "defense", cell)
					if error != "": return error
					horizontals += 1
					break
		elif role == "center" and centers < 1:
			var error: String = deploy(item.instance_id, "defense", Vector2i(-1, 3))
			if error != "": return error
			centers += 1
	return "" if runners > 0 and horizontals + centers > 0 else "Roster needs a runner and a guard"

func _find(instance_id: int) -> Dictionary:
	for item in shop.bench:
		if int(item.instance_id) == instance_id: return item
	return {}

func _new_instance(definition_index: int, instance_id: int) -> Dictionary:
	return {"instance_id": instance_id, "definition_index": definition_index, "star": 1, "location": "bench", "cards": [0]}

func _normalize_instances() -> void:
	for item in shop.bench:
		if not item.has("location"): item.location = "bench"
		if not item.has("cards"): item.cards = [0]

func _validate_placement(item: Dictionary, arena: String, cell: Vector2i) -> String:
	var role: String = shop.definitions[int(item.definition_index)].role
	if role == "runner" and (arena != "offense" or cell.y != 0 or not Grid.contains_cell(cell)):
		return "Runner needs an offense row 0 anchor"
	if role == "horizontal" and (arena != "defense" or cell.y not in [2, 4, 6] or not Grid.contains_cell(cell)):
		return "Horizontal guard needs defense row 2, 4, or 6"
	if role == "center" and (arena != "defense" or cell != Vector2i(-1, 3)):
		return "Center guard needs its marked lane anchor"
	var same_role: int = 0
	for other in shop.bench:
		if int(other.instance_id) == int(item.instance_id) or other.get("location", "bench") == "bench": continue
		if other.location == arena and other.cell == cell: return "Anchor is occupied"
		var other_role: String = shop.definitions[int(other.definition_index)].role
		if other_role == role: same_role += 1
		if role == "horizontal" and other_role == "horizontal" and other.cell.y == cell.y: return "Only one guard per patrol row"
	if same_role >= (1 if role == "center" else 3): return "Role deployment limit reached"
	return ""
