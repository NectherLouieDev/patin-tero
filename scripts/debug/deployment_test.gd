extends Node3D

const Roster = preload("res://scripts/roster/moveset_model.gd")
const Formation = preload("res://scripts/formation/formation_model.gd")
const Simulation = preload("res://scripts/simulation/arena_simulation.gd")
const Grid = preload("res://scripts/simulation/grid_map.gd")

@onready var camera: Camera3D = $Camera3D
@onready var bench: ItemList = $UI/Panel/Rows/Bench
@onready var preview: Label = $UI/Panel/Rows/Preview
@onready var status: Label = $UI/Panel/Rows/Status
@onready var battle_button: Button = $UI/Panel/Rows/Actions/Battle
@onready var return_button: Button = $UI/Panel/Rows/Actions/Return

var roster = Roster.new()
var formation = Formation.new()
var selected: int = -1
var dragging: bool = false
var battling: bool = false
var elapsed: float = 0.0
var offense = Simulation.new()
var defense = Simulation.new()

func _ready() -> void:
	var error: String = roster.load_definitions()
	if error != "":
		status.text = error
		return
	formation.initialize(roster.definitions)
	for definition in roster.definitions:
		bench.add_item(str(definition.name))
	bench.item_selected.connect(_select)
	bench.item_clicked.connect(_begin_drag)
	return_button.pressed.connect(_return_selected)
	battle_button.pressed.connect(_begin_battle)
	_update_view()

func _select(index: int) -> void:
	selected = index
	_update_view()

func _begin_drag(index: int, _position: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT and not battling:
		selected = index
		dragging = true
		status.text = "Release over a marked anchor to deploy."
		_update_view()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or event.pressed:
		return
	if dragging:
		dragging = false
		var drop: Dictionary = _pick_anchor(event.position)
		if drop.is_empty():
			status.text = "Invalid drop: character remains in its previous location."
		else:
			var error: String = formation.place(selected, drop.arena, drop.cell)
			status.text = "Deployed to %s %s" % [drop.arena, drop.cell] if error == "" else "Invalid drop: " + error
		_update_view()
	elif not battling:
		var hit: Dictionary = _pick_anchor(event.position)
		for index in formation.placements:
			var placed: Dictionary = formation.placements[index]
			if not hit.is_empty() and placed.arena == hit.arena and placed.cell == hit.cell:
				selected = index
				bench.select(index)
				_update_view()
				break

func _pick_anchor(screen_position: Vector2) -> Dictionary:
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.001:
		return {}
	var distance: float = -origin.y / direction.y
	if distance <= 0.0:
		return {}
	var hit: Vector3 = origin + direction * distance
	var arena: String = "offense" if hit.x < 0.0 else "defense"
	var center_x: float = -4.0 if arena == "offense" else 4.0
	var local_x: float = hit.x - center_x
	var cell := Vector2i(roundi(local_x + 1.5), roundi(hit.z + 3.5))
	if arena == "defense" and selected >= 0 and roster.definitions[selected].role == "center" and absf(local_x) < 0.35 and absf(hit.z + 0.5) < 0.35:
		return {"arena": arena, "cell": Vector2i(-1, 3)}
	if not Grid.contains_cell(cell) or absf(local_x - (float(cell.x) - 1.5)) > 0.48 or absf(hit.z - (float(cell.y) - 3.5)) > 0.48:
		return {}
	return {"arena": arena, "cell": cell}

func _return_selected() -> void:
	if battling:
		return
	var error: String = formation.return_to_bench(selected)
	status.text = "Returned to bench" if error == "" else error
	_update_view()

func _begin_battle() -> void:
	if battling:
		return
	var offense_units: Array[Dictionary] = []
	var defense_units: Array[Dictionary] = []
	for index in formation.placements:
		var placed: Dictionary = formation.placements[index]
		var definition: Dictionary = roster.definitions[index]
		var unit: Dictionary = {"id": "player_%d" % index, "role": definition.role, "pos": placed.cell, "commands": definition.cards[0].commands.duplicate()}
		if definition.role == "horizontal":
			unit["patrol_row"] = placed.cell.y
		if placed.arena == "offense":
			offense_units.append(unit)
		else:
			defense_units.append(unit)
	if offense_units.is_empty() or defense_units.is_empty():
		status.text = "Deploy at least one runner and one guard before battle."
		return
	# Isolated opponent fixtures let both persistent arenas demonstrate a battle.
	offense_units.append({"id": "fixture_guard", "role": "horizontal", "pos": Vector2i(3, 4), "patrol_row": 4, "commands": ["S"]})
	defense_units.append({"id": "fixture_runner", "role": "runner", "pos": Vector2i(0, 0), "commands": ["F", "S", "F", "S"]})
	offense.initialize(offense_units)
	defense.initialize(defense_units)
	battling = true
	status.text = "Battle running in both arenas (opponents are test fixtures)."
	_update_view()

func _process(delta: float) -> void:
	if not battling:
		return
	elapsed += delta
	while elapsed >= 0.05:
		elapsed -= 0.05
		offense.step()
		defense.step()
	_update_view()

func _update_view() -> void:
	for index in 9:
		var bench_text: String = str(roster.definitions[index].name) if index < roster.definitions.size() else ""
		if formation.placements.has(index):
			bench_text += "  [DEPLOYED: %s]" % formation.placements[index].arena
		if index < bench.item_count:
			bench.set_item_text(index, bench_text)
		var mesh: MeshInstance3D = get_node("Units/Unit%d" % index)
		mesh.visible = formation.placements.has(index)
		if not mesh.visible:
			continue
		var placed: Dictionary = formation.placements[index]
		var cell: Vector2i = placed.cell
		if battling:
			var simulation = offense if placed.arena == "offense" else defense
			for unit in simulation.units:
				if unit.id == "player_%d" % index:
					cell = unit.pos
					mesh.visible = unit.active
					break
		mesh.position = _world_position(placed.arena, cell) + Vector3(0, 0.45, 0)
	if selected >= 0 and not roster.definitions.is_empty():
		var definition: Dictionary = roster.definitions[selected]
		var lines: Array[String] = ["%s (%s) — TEST PLACEHOLDER" % [definition.name, definition.role]]
		for card in definition.cards:
			lines.append("%s: %s" % [card.name, " ".join(card.commands)])
		preview.text = "\n".join(lines)
	else:
		preview.text = "Select a character to preview its moveset."
	if battling:
		battle_button.disabled = true
		return_button.disabled = true
		status.text = "Battle: offense tick %d %s | defense tick %d %s\nOpponent units are test fixtures." % [offense.tick, offense.result, defense.tick, defense.result]

func _world_position(arena: String, cell: Vector2i) -> Vector3:
	var center_x: float = -4.0 if arena == "offense" else 4.0
	return Vector3(center_x + (0.0 if cell.x == -1 else float(cell.x) - 1.5), 0.0, float(cell.y) - 3.5)
