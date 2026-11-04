extends Node3D

const Session = preload("res://scripts/core/shared_session.gd")
const Grid = preload("res://scripts/simulation/grid_map.gd")

@onready var offers: ItemList = $UI/Panel/Rows/Offers
@onready var owned: ItemList = $UI/Panel/Rows/Owned
@onready var arena_picker: OptionButton = $UI/Panel/Rows/Arena
@onready var x_picker: SpinBox = $UI/Panel/Rows/Coordinates/X
@onready var y_picker: SpinBox = $UI/Panel/Rows/Coordinates/Y
@onready var card_picker: OptionButton = $UI/Panel/Rows/Card
@onready var summary: Label = $UI/Panel/Rows/Summary
@onready var status: Label = $UI/Panel/Rows/Status
@onready var snapshot_label: Label = $UI/Panel/Rows/Snapshot

var session = Session.new()
var selected_id: int = -1
var last_match: Dictionary = {}

func _ready() -> void:
	arena_picker.add_item("Offense")
	arena_picker.add_item("Defense")
	for card_index in 3: card_picker.add_item("Card %d" % (card_index + 1))
	owned.item_selected.connect(func(index: int) -> void: selected_id = int(session.shop.bench[index].instance_id); _refresh())
	$UI/Panel/Rows/ShopActions/Buy.pressed.connect(_buy)
	$UI/Panel/Rows/ShopActions/Reroll.pressed.connect(func() -> void: _show(session.reroll()))
	$UI/Panel/Rows/PlacementActions/Deploy.pressed.connect(_deploy)
	$UI/Panel/Rows/PlacementActions/Return.pressed.connect(func() -> void: _show(session.return_to_bench(selected_id)))
	$UI/Panel/Rows/CardActions/Equip.pressed.connect(func() -> void: _show(session.equip(selected_id, card_picker.selected)))
	$UI/Panel/Rows/CardActions/Earlier.pressed.connect(func() -> void: _show(session.move_card(selected_id, card_picker.selected, -1)))
	$UI/Panel/Rows/FlowActions/Lock.pressed.connect(func() -> void: _show(session.lock()))
	$UI/Panel/Rows/FlowActions/Match.pressed.connect(_play_match)
	$UI/Panel/Rows/FlowActions/Next.pressed.connect(func() -> void: session.begin_next_round(); _show("Next planning round"))
	$UI/Panel/Rows/FlowActions/Reset.pressed.connect(_reset)
	_reset()

func _reset() -> void:
	var error: String = session.initialize(42, true)
	selected_id = 1
	last_match.clear()
	_show("Ready with two provisional starters" if error == "" else error)

func _buy() -> void:
	var selection: PackedInt32Array = offers.get_selected_items()
	_show(session.buy(selection[0] if not selection.is_empty() else -1))

func _deploy() -> void:
	var arena: String = "offense" if arena_picker.selected == 0 else "defense"
	_show(session.deploy(selected_id, arena, Vector2i(int(x_picker.value), int(y_picker.value))))

func _play_match() -> void:
	last_match = session.start_test_match()
	_show(last_match.error if last_match.has("error") else "Match result A–B: %s" % last_match.result.score)

func _show(message: String) -> void:
	status.text = message
	_refresh()

func _refresh() -> void:
	if session.shop.definitions.is_empty(): return
	summary.text = "Coins %d | Offers %d | Owned %d | Bench %d/9 | %s" % [session.shop.coins, session.shop.offers.size(), session.shop.bench.size(), session.shop._bench_count(session.shop.bench), "LOCKED" if session.locked else "PLANNING"]
	offers.clear()
	for index in session.shop.offers.size():
		var definition_index: int = session.shop.offers[index]
		offers.add_item("%d: %s" % [index + 1, "SOLD" if definition_index < 0 else "%s (%d coins)" % [session.shop.definitions[definition_index].name, int(session.shop.config.prices[definition_index])]])
	owned.clear()
	var selected_row: int = -1
	for index in session.shop.bench.size():
		var item: Dictionary = session.shop.bench[index]
		owned.add_item("#%d %s | %d star | %s | cards %s" % [item.instance_id, session.shop.definitions[int(item.definition_index)].name, item.star, item.get("location", "bench"), str(item.get("cards", [0]))])
		if int(item.instance_id) == selected_id: selected_row = index
	if selected_row >= 0: owned.select(selected_row)
	else: selected_id = -1
	for index in 18:
		var mesh: MeshInstance3D = get_node("Units/Unit%d" % index)
		mesh.visible = false
		if index >= session.shop.bench.size(): continue
		var item: Dictionary = session.shop.bench[index]
		var location: String = str(item.get("location", "bench"))
		if location == "bench": continue
		var world: Vector3 = Grid.to_world(item.cell)
		if item.cell.x == -1: world.x = 0.0
		world.x += -4.0 if location == "offense" else 4.0
		mesh.position = world + Vector3(0, 0.55, 0)
		mesh.visible = true
		var is_runner: bool = session.shop.definitions[int(item.definition_index)].role == "runner"
		mesh.mesh = $Units/RunnerReference.mesh if is_runner else $Units/GuardReference.mesh
		mesh.material_override = $Units/RunnerReference.material_override if is_runner else $Units/GuardReference.material_override
	if session.locked:
		var lines: Array[String] = ["LOCKED SNAPSHOT — %d units" % session.get_snapshot().units.size()]
		for unit in session.get_snapshot().units:
			lines.append("#%d %s %s %s" % [unit.instance_id, unit.definition_id, unit.arena, unit.cell])
		snapshot_label.text = "\n".join(lines)
	else:
		var lines: Array[String] = ["No locked snapshot"]
		var selected: Dictionary = session.get_instance(selected_id)
		if not selected.is_empty():
			var definition: Dictionary = session.shop.definitions[int(selected.definition_index)]
			for index in 3:
				lines.append("Card %d %s: %s" % [index + 1, "EQUIPPED" if index in selected.get("cards", [0]) else "available", " ".join(definition.cards[index].commands)])
		snapshot_label.text = "\n".join(lines)
	if not last_match.is_empty() and last_match.has("result"):
		snapshot_label.text += "\nMatch input preserves owned IDs. Score: " + last_match.result.score
