class_name ShopModel
extends RefCounted

const Roster = preload("res://scripts/roster/moveset_model.gd")
const CONFIG_PATH := "res://resources/economy/test_economy.json"

var definitions: Array[Dictionary] = []
var config: Dictionary = {}
var coins: int = 0
var bench: Array[Dictionary] = []
var offers: Array[int] = []
var seed_value: int = 0
var next_instance_id: int = 1
var rng := RandomNumberGenerator.new()
var planning_open: bool = true

func load_data() -> String:
	var roster = Roster.new()
	var error: String = roster.load_definitions()
	if error != "":
		return error
	definitions = roster.definitions
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return "Cannot open economy config"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return "Invalid economy config"
	config = parsed
	if config.prices.size() != definitions.size() or config.weights.size() != definitions.size() or int(config.reroll_cost) != 2:
		return "Invalid economy config dimensions or reroll cost"
	for index in definitions.size():
		if int(config.prices[index]) < 0 or int(config.weights[index]) < 0:
			return "Negative price or weight"
	return ""

func reset(new_seed: int) -> void:
	seed_value = new_seed
	rng.seed = new_seed
	coins = int(config.starting_coins)
	bench.clear()
	next_instance_id = 1
	planning_open = true
	offers = _generate_offers()

func buy(slot: int) -> String:
	if not planning_open:
		return "Shop is closed"
	if slot < 0 or slot >= offers.size() or offers[slot] < 0:
		return "Invalid or empty offer"
	var definition_index: int = offers[slot]
	var price: int = int(config.prices[definition_index])
	if coins < price:
		return "Insufficient coins"
	var candidate: Array[Dictionary] = bench.duplicate(true)
	candidate.append({"instance_id": next_instance_id, "definition_index": definition_index, "star": 1})
	_resolve_merges(candidate)
	if candidate.size() > int(config.bench_capacity):
		return "Bench is full"
	# Commit all changes only after validation and merge preview succeed.
	bench = candidate
	coins -= price
	next_instance_id += 1
	offers[slot] = -1
	return "Purchased %s for %d coins" % [definitions[definition_index].name, price]

func reroll() -> String:
	if not planning_open:
		return "Shop is closed"
	if coins < int(config.reroll_cost):
		return "Insufficient coins for reroll"
	var next_offers: Array[int] = _generate_offers()
	coins -= int(config.reroll_cost)
	offers = next_offers
	return "Rerolled for 2 coins"

func setup_full_bench() -> void:
	bench.clear()
	for index in definitions.size():
		bench.append({"instance_id": index + 1, "definition_index": index, "star": 1})
	next_instance_id = definitions.size() + 1

func setup_merge_bench(definition_index: int) -> void:
	bench.clear()
	for index in 2:
		bench.append({"instance_id": index + 1, "definition_index": definition_index, "star": 1})
	var other := 0
	while bench.size() < 9:
		if other != definition_index:
			bench.append({"instance_id": bench.size() + 1, "definition_index": other, "star": 1})
		other += 1
	next_instance_id = 10

func setup_zero_coins() -> void:
	coins = 0

func _generate_offers() -> Array[int]:
	var generated: Array[int] = []
	var total: int = 0
	for weight in config.weights:
		total += int(weight)
	assert(total > 0)
	for slot in 5:
		var draw: int = rng.randi_range(1, total)
		for index in config.weights.size():
			draw -= int(config.weights[index])
			if draw <= 0:
				generated.append(index)
				break
	return generated

func _resolve_merges(items: Array[Dictionary]) -> void:
	# Test policy: first two existing copies and the new copy become the oldest instance.
	# Repeat for 1->2 and 2->3; never merge past star 3.
	var changed := true
	while changed:
		changed = false
		for star in [1, 2]:
			for definition_index in definitions.size():
				var matches: Array[int] = []
				for index in items.size():
					if items[index].definition_index == definition_index and items[index].star == star:
						matches.append(index)
				if matches.size() >= 3:
					items[matches[0]].star = star + 1
					items.remove_at(matches[2])
					items.remove_at(matches[1])
					changed = true
					break
			if changed:
				break
