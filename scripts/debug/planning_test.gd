extends "res://scripts/debug/deployment_test.gd"

const Planning = preload("res://scripts/formation/planning_model.gd")

@onready var star_picker: SpinBox = $UI/Panel/Rows/Star
@onready var cards_list: ItemList = $UI/Panel/Rows/Cards
@onready var snapshot_label: Label = $UI/Panel/Rows/Snapshot
@onready var equip_button: Button = $UI/Panel/Rows/CardActions/Equip
@onready var unequip_button: Button = $UI/Panel/Rows/CardActions/Unequip
@onready var earlier_button: Button = $UI/Panel/Rows/CardActions/Earlier
@onready var later_button: Button = $UI/Panel/Rows/CardActions/Later

var planning = Planning.new()

func _ready() -> void:
	super._ready()
	if roster.definitions.is_empty():
		return
	planning.initialize(roster.definitions, formation)
	star_picker.value_changed.connect(func(value: float) -> void: _show_edit(planning.set_star(selected, int(value))))
	equip_button.pressed.connect(func() -> void: _show_edit(planning.equip(selected, _selected_card())))
	unequip_button.pressed.connect(func() -> void: _show_edit(planning.unequip(selected, _selected_card())))
	earlier_button.pressed.connect(func() -> void: _show_edit(planning.move_card(selected, _selected_card(), -1)))
	later_button.pressed.connect(func() -> void: _show_edit(planning.move_card(selected, _selected_card(), 1)))
	_update_view()

func _input(event: InputEvent) -> void:
	if planning.locked:
		return
	super._input(event)

func _begin_drag(index: int, position: Vector2, button: int) -> void:
	if planning.locked:
		status.text = "Formation is locked"
		return
	super._begin_drag(index, position, button)

func _place_selected(arena: String, cell: Vector2i) -> String:
	return planning.deploy(selected, arena, cell)

func _return_selected() -> void:
	var error: String = planning.return_to_bench(selected)
	status.text = "Returned to bench" if error == "" else "REJECTED: " + error
	_update_view()

func _begin_battle() -> void:
	var error: String = planning.lock()
	status.text = "LOCKED: battle snapshot captured" if error == "" else "CANNOT LOCK: " + error
	_update_view()

func _selected_card() -> int:
	var selection: PackedInt32Array = cards_list.get_selected_items()
	return selection[0] if not selection.is_empty() else -1

func _show_edit(error: String) -> void:
	status.text = "Card configuration updated" if error == "" else "REJECTED: " + error
	_update_view()

func _update_view() -> void:
	super._update_view()
	if planning.definitions.is_empty():
		return
	var is_locked: bool = planning.locked
	battle_button.disabled = is_locked
	return_button.disabled = is_locked
	star_picker.editable = not is_locked
	for button in [equip_button, unequip_button, earlier_button, later_button]:
		button.disabled = is_locked
	if selected >= 0:
		star_picker.set_value_no_signal(int(planning.stars[selected]))
		var previous: PackedInt32Array = cards_list.get_selected_items()
		cards_list.clear()
		var definition: Dictionary = planning.definitions[selected]
		var equipped_cards: Array = planning.equipped[selected]
		for card_index in 3:
			var position: int = equipped_cards.find(card_index)
			var card: Dictionary = definition.cards[card_index]
			cards_list.add_item("%s %s: %s" % ["#%d" % (position + 1) if position >= 0 else "Available", card.name, " ".join(card.commands)])
		if not previous.is_empty():
			cards_list.select(previous[0])
	else:
		cards_list.clear()
	if is_locked:
		var snapshot: Dictionary = planning.get_locked_snapshot()
		var lines: Array[String] = ["LOCKED SNAPSHOT: %d units" % snapshot.units.size()]
		for unit in snapshot.units:
			lines.append("%s %s %s | %d star | cards %s" % [unit.definition_id, unit.arena, unit.cell, unit.star, ", ".join(unit.card_ids)])
		snapshot_label.text = "\n".join(lines)
	else:
		snapshot_label.text = "No locked snapshot. Deploy runner + guard, then Lock formation."
