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
var last_merge_survivor_id: int = 0
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
	if str(config.get("merge_policy", "")) != "prefer_deployed_oldest_id":
		return "Unsupported provisional merge policy"
	if int(config.get("starting_coins", -1)) < 0 or int(config.get("round_income", -1)) < 0 or int(config.get("bonus_2_0", -1)) < 0:
		return "Invalid economy income or bonus"
	if int(config.get("reroll_cost", -1)) != 2 or int(config.get("shop_offer_count", -1)) != 5 or int(config.get("bench_capacity", -1)) != 9 or int(config.get("merge_requirement", -1)) != 3 or int(config.get("max_star_level", -1)) != 3:
		return "Invalid confirmed economy rule"
	if not config.get("allow_duplicate_offers", null) is bool: return "Invalid duplicate-offer policy"
	var entries: Array = config.get("characters", [])
	if entries.size() != definitions.size(): return "Expected one shop entry per character"
	var prices: Array[int] = []
	var weights: Array[int] = []
	var available: Array[bool] = []
	var total_weight: int = 0
	for index in definitions.size():
		var entry: Variant = entries[index]
		if not entry is Dictionary or str(entry.get("id", "")) != str(definitions[index].id) or not entry.has("cost") or not entry.has("weight") or not entry.has("available"):
			return "Invalid character shop entry"
		var cost: int = int(entry.cost)
		var weight: int = int(entry.weight)
		if cost < 0 or weight < 0 or not entry.available is bool: return "Invalid character price, weight, or availability"
		prices.append(cost)
		weights.append(weight)
		available.append(bool(entry.available))
		if entry.available: total_weight += weight
	if total_weight <= 0: return "Shop has no available weighted characters"
	if not config.allow_duplicate_offers:
		var positive_count: int = 0
		for index in weights.size():
			if available[index] and weights[index] > 0: positive_count += 1
		if positive_count < int(config.shop_offer_count): return "Not enough available characters for unique offers"
	config["prices"] = prices
	config["weights"] = weights
	config["availability"] = available
	return ""

func reset(new_seed: int) -> void:
	seed_value = new_seed
	rng.seed = new_seed
	coins = int(config.starting_coins)
	bench.clear()
	next_instance_id = 1
	last_merge_survivor_id = 0
	planning_open = true
	offers = _generate_offers()

func can_buy(slot: int) -> String:
	if not planning_open:
		return "Shop is closed"
	if slot < 0 or slot >= offers.size() or offers[slot] < 0:
		return "Invalid or empty offer"
	var definition_index: int = offers[slot]
	if not config.availability[definition_index]: return "Character is unavailable"
	var price: int = int(config.prices[definition_index])
	if coins < price:
		return "Insufficient coins"
	var candidate: Array[Dictionary] = bench.duplicate(true)
	candidate.append({"instance_id": next_instance_id, "definition_index": definition_index, "star": 1})
	_resolve_merges(candidate)
	if _bench_count(candidate) > int(config.bench_capacity):
		return "Bench is full"
	return ""

func buy(slot: int) -> String:
	var error: String = can_buy(slot)
	if error != "": return error
	var definition_index: int = offers[slot]
	var price: int = int(config.prices[definition_index])
	var candidate: Array[Dictionary] = bench.duplicate(true)
	candidate.append({"instance_id": next_instance_id, "definition_index": definition_index, "star": 1})
	var merge_results: Array[Dictionary] = _resolve_merges(candidate)
	# Commit all changes only after validation and merge preview succeed.
	bench = candidate
	last_merge_survivor_id = int(merge_results.back().survivor_id) if not merge_results.is_empty() else 0
	coins -= price
	next_instance_id += 1
	offers[slot] = -1
	var message: String = "Purchased %s for %d coins" % [definitions[definition_index].name, price]
	if not merge_results.is_empty():
		var merge_messages: Array[String] = []
		for merged in merge_results: merge_messages.append("Merged into #%d ★%d (kept its cards and anchor)" % [merged.survivor_id, merged.star])
		message += "; " + "; ".join(merge_messages)
	return message

func can_reroll() -> String:
	if not planning_open: return "Shop is closed"
	if coins < int(config.reroll_cost): return "Insufficient coins for reroll"
	return ""

func reroll() -> String:
	var error: String = can_reroll()
	if error != "": return error
	var next_offers: Array[int] = _generate_offers()
	coins -= int(config.reroll_cost)
	offers = next_offers
	return "Rerolled for %d coins" % int(config.reroll_cost)

func award_coins(amount: int) -> String:
	if amount < 0: return "Invalid coin reward"
	coins += amount
	return ""

func begin_round(income: int, shop_enabled: bool) -> String:
	if income < 0: return "Invalid round income"
	coins += income
	planning_open = shop_enabled
	if shop_enabled: offers = _generate_offers()
	return ""

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
	var remaining_weights: Array = config.weights.duplicate()
	for slot in int(config.shop_offer_count):
		var total: int = 0
		for index in remaining_weights.size():
			if config.availability[index]: total += int(remaining_weights[index])
		assert(total > 0)
		var draw: int = rng.randi_range(1, total)
		for index in remaining_weights.size():
			if not config.availability[index]: continue
			draw -= int(remaining_weights[index])
			if draw <= 0:
				generated.append(index)
				if not config.allow_duplicate_offers: remaining_weights[index] = 0
				break
	return generated

func _resolve_merges(items: Array[Dictionary]) -> Array[Dictionary]:
	# Provisional: keep the oldest deployed copy, or the oldest bench copy.
	# Its anchor and ordered cards survive. All three source copies are consumed
	# into that survivor, with no role or anchor change.
	var merges: Array[Dictionary] = []
	var changed := true
	while changed:
		changed = false
		for star in range(1, int(config.max_star_level)):
			for definition_index in definitions.size():
				var matches: Array[int] = []
				for index in items.size():
					if items[index].definition_index == definition_index and items[index].star == star:
						matches.append(index)
				if matches.size() >= int(config.merge_requirement):
					matches.sort_custom(func(a: int, b: int) -> bool:
						var a_deployed: bool = items[a].get("location", "bench") != "bench"
						var b_deployed: bool = items[b].get("location", "bench") != "bench"
						if a_deployed != b_deployed: return a_deployed
						return int(items[a].instance_id) < int(items[b].instance_id))
					var survivor: int = matches[0]
					var survivor_id: int = int(items[survivor].instance_id)
					items[survivor].star = star + 1
					var removed: Array[int] = [matches[1], matches[2]]
					removed.sort()
					removed.reverse()
					for index in removed: items.remove_at(index)
					merges.append({"survivor_id": survivor_id, "star": star + 1})
					changed = true
					break
			if changed:
				break
	return merges

func _bench_count(items: Array[Dictionary]) -> int:
	var count: int = 0
	for item in items:
		if item.get("location", "bench") == "bench":
			count += 1
	return count
