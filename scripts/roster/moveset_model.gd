class_name MovesetModel
extends RefCounted

const DATA_PATH := "res://resources/characters/test_roster.json"
const ALLOWED := {
	"runner": ["F", "L", "R", "DL", "DR", "S", "T"],
	"horizontal": ["L", "R", "S", "C"],
	"center": ["U", "D", "S", "C"]
}

var definitions: Array[Dictionary] = []
var selected: int = 0
var star_level: int = 1
var equipped: Array[int] = [0]
var card_index: int = 0
var command_index: int = 0
var executed: int = 0

func load_definitions() -> String:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return "Cannot open roster data"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("definitions"):
		return "Invalid roster data"
	definitions.clear()
	var ids: Dictionary = {}
	var visual_keys: Dictionary = {}
	var card_ids: Dictionary = {}
	var patterns: Dictionary = {}
	for entry in parsed.definitions:
		var error := validate_definition(entry)
		if error != "":
			return error
		if ids.has(entry.id) or visual_keys.has(entry.visual_key): return "Duplicate character identity or visual"
		ids[entry.id] = true
		visual_keys[entry.visual_key] = true
		for card in entry.cards:
			var pattern: String = ",".join(card.commands)
			if card_ids.has(card.id) or patterns.has(pattern): return "Duplicate signature card identity or pattern"
			card_ids[card.id] = true
			patterns[pattern] = true
		definitions.append(entry)
	if definitions.size() != 9:
		return "Expected nine definitions"
	return ""

func validate_definition(entry: Dictionary) -> String:
	if not entry.has("id") or not entry.has("name") or not entry.has("role") or not entry.has("cards") or not entry.has("visual_key"):
		return "Missing character fields"
	if not ALLOWED.has(entry.role) or entry.cards.size() != 3:
		return "Invalid role or card count: %s" % entry.id
	var seen: Dictionary = {}
	for card in entry.cards:
		if not card.has("id") or not card.has("name") or not card.has("commands"):
			return "Missing card fields"
		if seen.has(card.id) or card.commands.size() != 4:
			return "Duplicate card or invalid command count: %s" % card.id
		seen[card.id] = true
		for command in card.commands:
			if command not in ALLOWED[entry.role]:
				return "Invalid %s command: %s" % [entry.role, command]
	return ""

func choose_character(index: int) -> String:
	if index < 0 or index >= definitions.size():
		return "Invalid character"
	selected = index
	star_level = 1
	equipped = [0]
	reset_cursor()
	return ""

func set_star(value: int) -> String:
	if value < 1 or value > 3:
		return "Star level must be 1 to 3"
	star_level = value
	while equipped.size() > value:
		equipped.pop_back()
	reset_cursor()
	return ""

func equip(card: int) -> String:
	if card < 0 or card >= 3:
		return "Invalid card"
	if card in equipped:
		return "Card already equipped"
	if equipped.size() >= star_level:
		return "Card capacity reached"
	equipped.append(card)
	reset_cursor()
	return ""

func unequip(card: int) -> String:
	if card not in equipped:
		return "Card is not equipped"
	if equipped.size() == 1:
		return "At least one card is required"
	equipped.erase(card)
	reset_cursor()
	return ""

func move_card(card: int, offset: int) -> String:
	var from := equipped.find(card)
	var target := from + offset
	if from < 0 or target < 0 or target >= equipped.size():
		return "Cannot move card in that direction"
	equipped.remove_at(from)
	equipped.insert(target, card)
	reset_cursor()
	return ""

func reset_cursor() -> void:
	card_index = 0
	command_index = 0
	executed = 0

func current_command() -> String:
	return str(definitions[selected].cards[equipped[card_index]].commands[command_index])

func step_command() -> String:
	var command := current_command()
	executed += 1
	command_index += 1
	if command_index == 4:
		command_index = 0
		card_index = (card_index + 1) % equipped.size()
	return command
