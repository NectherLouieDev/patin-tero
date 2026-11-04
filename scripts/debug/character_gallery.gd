extends Node3D

const Roster = preload("res://scripts/roster/moveset_model.gd")

var roster = Roster.new()
var units: Array[Dictionary] = []
var selected: int = 0
var display_state: int = 0
var clock: float = 0.0

@onready var arena: ArenaVisual = $Arena

func _ready() -> void:
	var error: String = roster.load_definitions()
	if error != "":
		$UI/Panel/Rows/Summary.text = error
		return
	arena.set_assignment("gallery")
	for index in roster.definitions.size():
		var definition: Dictionary = roster.definitions[index]
		var cell := Vector2i(index % 3, (index / 3) * 3)
		units.append({"id": "gallery_%d" % index, "definition_id": definition.id, "role": definition.role, "pos": cell, "team": "A", "star": 1, "active": true, "last_command": "", "reached_end": false, "active_effect": "", "victory": false})
		$UI/Panel/Rows/Characters.add_item(str(definition.name))
	for label in ["Idle", "Move", "STAY", "TAUNT", "SCARE", "Tagged", "Round trip", "Victory"]:
		$UI/Panel/Rows/State.add_item(label)
	$UI/Panel/Rows/Characters.item_selected.connect(_select_character)
	$UI/Panel/Rows/Star.value_changed.connect(_set_star)
	$UI/Panel/Rows/State.item_selected.connect(_set_state)
	$UI/Panel/Rows/Characters.select(0)
	_refresh_summary()
	arena.display_units(units)

func _process(delta: float) -> void:
	if units.is_empty(): return
	clock += delta
	for index in units.size():
		var reset_unit: Dictionary = units[index]
		reset_unit.pos = Vector2i(index % 3, (index / 3) * 3)
		reset_unit.active = true
		reset_unit.tagged = false
		reset_unit.active_effect = ""
		reset_unit.victory = false
		reset_unit.completed_trip = false
		reset_unit.reached_end = false
		reset_unit.last_command = ""
	var unit: Dictionary = units[selected]
	var base_cell := Vector2i(selected % 3, (selected / 3) * 3)
	match display_state:
		1:
			unit.last_command = "F"
			if fmod(clock, 2.0) >= 1.0: unit.pos = base_cell + Vector2i(0, 1)
		2: unit.last_command = "S"
		3:
			if unit.role == "runner": unit.active_effect = "T"
		4:
			if unit.role != "runner": unit.active_effect = "C"
		5:
			unit.active = false
			unit.tagged = true
		6:
			if unit.role == "runner":
				unit.reached_end = true
				unit.completed_trip = true
				unit.victory = true
		7: unit.victory = true
	arena.display_units(units, delta, true)

func _select_character(index: int) -> void:
	selected = index
	clock = 0.0
	$UI/Panel/Rows/Star.set_value_no_signal(int(units[index].star))
	_refresh_summary()

func _set_star(value: float) -> void:
	units[selected].star = int(value)
	_refresh_summary()

func _set_state(index: int) -> void:
	display_state = index
	clock = 0.0
	_refresh_summary()

func _refresh_summary() -> void:
	var definition: Dictionary = roster.definitions[selected]
	var lines: Array[String] = ["%s • %s • ★%d" % [definition.name, definition.role, int(units[selected].star)], "Provisional name and card patterns"]
	for card in definition.cards: lines.append("%s: %s" % [card.name, " → ".join(card.commands)])
	if display_state == 3 and definition.role != "runner": lines.append("TAUNT belongs to runners")
	if display_state == 4 and definition.role == "runner": lines.append("SCARE belongs to guards")
	$UI/Panel/Rows/Summary.text = "\n".join(lines)
