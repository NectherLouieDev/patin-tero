extends Control

const Model = preload("res://scripts/roster/moveset_model.gd")

@onready var character_picker: OptionButton = $Margin/Rows/Character
@onready var star_picker: SpinBox = $Margin/Rows/Star
@onready var summary: Label = $Margin/Rows/Summary
@onready var cards: ItemList = $Margin/Rows/Cards
@onready var feedback: Label = $Margin/Rows/Feedback
@onready var playback: Label = $Margin/Rows/Playback

var model = Model.new()
var running: bool = false
var elapsed: float = 0.0
var last_command: String = "none"

func _ready() -> void:
	var error: String = model.load_definitions()
	if error != "":
		feedback.text = error
		return
	for definition in model.definitions:
		character_picker.add_item(str(definition.name))
	character_picker.item_selected.connect(func(index: int) -> void: _show_error(model.choose_character(index)))
	star_picker.value_changed.connect(func(value: float) -> void: _show_error(model.set_star(int(value))))
	$Margin/Rows/CardActions/Equip.pressed.connect(func() -> void: _show_error(model.equip(cards.get_selected_items()[0] if not cards.get_selected_items().is_empty() else -1)))
	$Margin/Rows/CardActions/Unequip.pressed.connect(func() -> void: _show_error(model.unequip(cards.get_selected_items()[0] if not cards.get_selected_items().is_empty() else -1)))
	$Margin/Rows/CardActions/Up.pressed.connect(func() -> void: _show_error(model.move_card(cards.get_selected_items()[0] if not cards.get_selected_items().is_empty() else -1, -1)))
	$Margin/Rows/CardActions/Down.pressed.connect(func() -> void: _show_error(model.move_card(cards.get_selected_items()[0] if not cards.get_selected_items().is_empty() else -1, 1)))
	$Margin/Rows/PlaybackActions/Step.pressed.connect(_step)
	$Margin/Rows/PlaybackActions/Run.pressed.connect(func() -> void: running = true)
	$Margin/Rows/PlaybackActions/Pause.pressed.connect(func() -> void: running = false)
	$Margin/Rows/PlaybackActions/Reset.pressed.connect(func() -> void: running = false; model.reset_cursor(); last_command = "none"; _refresh())
	_refresh()

func _process(delta: float) -> void:
	if not running or model.definitions.is_empty():
		return
	elapsed += delta
	while elapsed >= (0.75 if model.current_command() in ["T", "C"] else 0.5):
		elapsed -= (0.75 if model.current_command() in ["T", "C"] else 0.5)
		_step()

func _step() -> void:
	if model.definitions.is_empty():
		return
	last_command = model.step_command()
	_refresh()

func _show_error(error: String) -> void:
	feedback.text = "Accepted" if error == "" else "REJECTED: " + error
	if error == "":
		running = false
		elapsed = 0.0
		last_command = "none"
	_refresh()

func _refresh() -> void:
	if model.definitions.is_empty():
		return
	var definition: Dictionary = model.definitions[model.selected]
	star_picker.set_value_no_signal(model.star_level)
	summary.text = "%s | %s | TEST PLACEHOLDER\n%d star: %d card capacity" % [definition.name, definition.role, model.star_level, model.star_level]
	var previous: PackedInt32Array = cards.get_selected_items()
	cards.clear()
	for index in 3:
		var card: Dictionary = definition.cards[index]
		var order: int = model.equipped.find(index)
		cards.add_item("%s  %s: %s" % ["Equipped #%d" % (order + 1) if order >= 0 else "Available", card.name, " ".join(card.commands)])
	if not previous.is_empty():
		cards.select(previous[0])
	playback.text = "Executed: %d | Last: %s | Next: card %d, command %d (%s)" % [model.executed, last_command, model.equipped[model.card_index] + 1, model.command_index + 1, model.current_command()]
