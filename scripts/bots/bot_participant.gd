class_name BotParticipant
extends RefCounted

const Session = preload("res://scripts/core/shared_session.gd")
const MatchPolicy = preload("res://scripts/match/provisional_match_policy.gd")
const MAX_ROSTER: int = 6

var participant_id: int = 0
var tournament_seed: int = 0
var session = Session.new()
var decision_history: Array[Dictionary] = []
var locked_snapshot: Dictionary = {}

func initialize(seed: int, id: int) -> String:
	if id < 2 or id > 8: return "Bot participant ID must be 2 through 8"
	participant_id = id
	tournament_seed = seed
	decision_history.clear()
	locked_snapshot.clear()
	session = Session.new()
	return session.initialize(seed * 1009 + id * 17, true)

func prepare_stage(stage: int, shop_enabled: bool = true) -> String:
	if stage < 0: return "Invalid stage"
	if session.locked and not decision_history.is_empty() and int(decision_history.back().stage) == stage:
		return ""
	if session.locked or not shop_enabled: session.begin_next_round(shop_enabled)
	var decision_seed: int = tournament_seed * 1000003 + participant_id * 1009 + stage * 9176
	var rng := RandomNumberGenerator.new()
	rng.seed = decision_seed
	var record: Dictionary = {"participant_id": participant_id, "stage": stage, "seed": decision_seed, "offers": session.shop.offers.duplicate(), "purchases": [], "cards": [], "placements": [], "roster": []}
	if shop_enabled and session.shop.bench.size() < MAX_ROSTER:
		var slots: Array = _shuffled([0, 1, 2, 3, 4], rng)
		for slot in slots:
			var definition_index: int = session.shop.offers[slot]
			if definition_index < 0 or session.shop.coins < int(session.shop.config.prices[definition_index]): continue
			var purchase: String = session.buy(slot)
			if purchase.begins_with("Purchased"):
				record.purchases.append({"slot": slot, "definition_id": session.shop.definitions[definition_index].id, "cost": int(session.shop.config.prices[definition_index]), "result": purchase})
				break
	for item in session.shop.bench:
		if item.get("location", "bench") == "bench": continue
		var error: String = session.return_to_bench(int(item.instance_id))
		if error != "": return error
	for item in session.shop.bench:
		var instance_id: int = int(item.instance_id)
		var definition: Dictionary = session.shop.definitions[int(item.definition_index)]
		var card_options: Array = _shuffled([0, 1, 2], rng)
		var chosen: Array = card_options.slice(0, mini(int(item.star), 3))
		var error: String = session.set_cards(instance_id, chosen)
		if error != "": return error
		record.cards.append({"instance_id": instance_id, "card_indices": chosen.duplicate(), "card_ids": chosen.map(func(index: int) -> String: return str(definition.cards[index].id))})
		var arena: String = "offense" if definition.role == "runner" else "defense"
		var anchors: Array = _anchors_for(str(definition.role), rng)
		for cell in anchors:
			error = session.deploy(instance_id, arena, cell)
			if error == "":
				record.placements.append({"instance_id": instance_id, "arena": arena, "cell": cell})
				break
		record.roster.append({"instance_id": instance_id, "definition_id": definition.id, "star": int(item.star)})
	var lock_error: String = session.lock()
	if lock_error != "": return lock_error
	locked_snapshot = session.get_snapshot()
	record["snapshot"] = locked_snapshot.duplicate(true)
	decision_history.append(record.duplicate(true))
	return ""

func get_snapshot() -> Dictionary:
	return locked_snapshot.duplicate(true)

func get_match_snapshot() -> Dictionary:
	return MatchPolicy.battle_snapshot(locked_snapshot)

func get_decisions() -> Array[Dictionary]:
	return decision_history.duplicate(true)

func _anchors_for(role: String, rng: RandomNumberGenerator) -> Array:
	var anchors: Array = []
	if role == "runner":
		for column in 4: anchors.append(Vector2i(column, 0))
	elif role == "horizontal":
		for row in [2, 4, 6]:
			for column in 4: anchors.append(Vector2i(column, row))
	else:
		anchors.append(Vector2i(-1, 3))
	return _shuffled(anchors, rng)

func _shuffled(source: Array, rng: RandomNumberGenerator) -> Array:
	var output: Array = source.duplicate()
	for index in range(output.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var value: Variant = output[index]
		output[index] = output[other]
		output[other] = value
	return output
