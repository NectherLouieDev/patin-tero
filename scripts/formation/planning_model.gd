class_name PlanningModel
extends RefCounted

const Roster = preload("res://scripts/roster/moveset_model.gd")

var definitions: Array[Dictionary] = []
var formation: FormationModel
var owned: Array[int] = []
var stars: Dictionary = {}
var equipped: Dictionary = {}
var locked: bool = false
var _locked_snapshot: Dictionary = {}

func initialize(roster: Array[Dictionary], deployment: FormationModel) -> void:
	definitions = roster
	formation = deployment
	owned.clear()
	stars.clear()
	equipped.clear()
	locked = false
	_locked_snapshot.clear()
	for index in definitions.size():
		owned.append(index) # Nine test-owned instances until a unified roster exists.
		stars[index] = 1
		equipped[index] = [0]

func deploy(index: int, arena: String, cell: Vector2i) -> String:
	if locked:
		return "Formation is locked"
	if index not in owned:
		return "Character is not owned"
	return formation.place(index, arena, cell)

func return_to_bench(index: int) -> String:
	if locked:
		return "Formation is locked"
	return formation.return_to_bench(index)

func set_star(index: int, level: int) -> String:
	if locked:
		return "Formation is locked"
	if index not in owned or level < 1 or level > 3:
		return "Invalid owned unit or star level"
	stars[index] = level
	var cards: Array = equipped[index]
	while cards.size() > level:
		cards.pop_back()
	equipped[index] = cards
	return ""

func equip(index: int, card: int) -> String:
	if locked:
		return "Formation is locked"
	if index not in owned or card < 0 or card >= 3:
		return "Invalid unit or card"
	var cards: Array = equipped[index]
	if card in cards:
		return "Card already equipped"
	if cards.size() >= int(stars[index]):
		return "Card capacity reached"
	cards.append(card)
	equipped[index] = cards
	return ""

func unequip(index: int, card: int) -> String:
	if locked:
		return "Formation is locked"
	if index not in owned or card not in equipped[index]:
		return "Card is not equipped"
	var cards: Array = equipped[index]
	if cards.size() == 1:
		return "At least one card is required"
	cards.erase(card)
	equipped[index] = cards
	return ""

func move_card(index: int, card: int, offset: int) -> String:
	if locked:
		return "Formation is locked"
	if index not in owned:
		return "Character is not owned"
	var cards: Array = equipped[index]
	var from: int = cards.find(card)
	var target: int = from + offset
	if from < 0 or target < 0 or target >= cards.size():
		return "Cannot move card in that direction"
	cards.remove_at(from)
	cards.insert(target, card)
	equipped[index] = cards
	return ""

func validate_for_lock() -> String:
	var offense_count := 0
	var defense_count := 0
	for index in formation.placements:
		if index not in owned:
			return "Deployed character is not owned"
		var placed: Dictionary = formation.placements[index]
		var check := formation.validate(index, placed.arena, placed.cell)
		if check != "":
			return check
		if placed.arena == "offense":
			offense_count += 1
		else:
			defense_count += 1
		var cards: Array = equipped[index]
		if cards.is_empty() or cards.size() > int(stars[index]):
			return "Invalid card capacity"
		var seen := {}
		for card in cards:
			if card < 0 or card >= 3 or seen.has(card):
				return "Invalid or duplicate card"
			seen[card] = true
			for command in definitions[index].cards[card].commands:
				if command not in Roster.ALLOWED[definitions[index].role]:
					return "Role-invalid command"
	if offense_count == 0 or defense_count == 0:
		return "Deploy at least one runner and one guard"
	return ""

func lock() -> String:
	if locked:
		return "Formation is already locked"
	var error := validate_for_lock()
	if error != "":
		return error
	var units: Array[Dictionary] = []
	var indices: Array = formation.placements.keys()
	indices.sort()
	for index in indices:
		var placed: Dictionary = formation.placements[index]
		var selected_cards: Array = equipped[index]
		var card_ids: Array[String] = []
		var commands: Array[String] = []
		for card in selected_cards:
			card_ids.append(str(definitions[index].cards[card].id))
			for command in definitions[index].cards[card].commands:
				commands.append(str(command))
		units.append({"instance_id": index + 1, "definition_id": definitions[index].id, "role": definitions[index].role, "arena": placed.arena, "cell": placed.cell, "star": stars[index], "card_ids": card_ids, "commands": commands})
	_locked_snapshot = {"locked": true, "units": units}
	locked = true
	return ""

func get_locked_snapshot() -> Dictionary:
	return _locked_snapshot.duplicate(true)
