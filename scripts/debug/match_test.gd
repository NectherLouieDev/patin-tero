extends Node3D

const Controller = preload("res://scripts/match/match_controller.gd")
const Fixtures = preload("res://scripts/match/match_fixtures.gd")
const Grid = preload("res://scripts/simulation/grid_map.gd")

@onready var scenario_picker: OptionButton = $UI/Panel/Rows/Scenario
@onready var speed_picker: OptionButton = $UI/Panel/Rows/Speed
@onready var status_label: Label = $UI/Panel/Rows/Status
@onready var arena_a_label: Label = $UI/Panel/Rows/ArenaA
@onready var arena_b_label: Label = $UI/Panel/Rows/ArenaB
@onready var result_label: Label = $UI/Panel/Rows/Result
@onready var replay_label: Label = $UI/Panel/Rows/Replay

var controller = Controller.new()
var running: bool = false
var elapsed: float = 0.0
var last_result: Dictionary = {}
var fixture_name: String = ""

func _ready() -> void:
	for title in ["2-0 | A wins both", "1-1 | split", "0-2 | B wins both"]:
		scenario_picker.add_item(title)
	for title in ["0.5x", "1x", "2x", "4x"]:
		speed_picker.add_item(title)
	speed_picker.select(1)
	$UI/Panel/Rows/Actions/Start.pressed.connect(_start_match)
	$UI/Panel/Rows/Actions/Pause.pressed.connect(func() -> void: running = false; status_label.text = "Paused")
	$UI/Panel/Rows/Actions/Step.pressed.connect(_step_once)
	$UI/Panel/Rows/Actions/Reset.pressed.connect(_reset_match)
	scenario_picker.item_selected.connect(func(_index: int) -> void: last_result.clear(); _reset_match())
	_reset_match()

func _start_match() -> void:
	if controller.finalized:
		_reset_match()
	running = true
	status_label.text = "Running locked fixture snapshots"

func _reset_match() -> void:
	running = false
	elapsed = 0.0
	var fixture: Dictionary = Fixtures.build(scenario_picker.selected)
	fixture_name = fixture.name
	var error: String = controller.initialize(fixture.a, fixture.b, 42)
	status_label.text = "Ready: locked fixture %s, seed 42" % fixture_name if error == "" else error
	_snap_unit_positions()
	_update_labels()

func _process(delta: float) -> void:
	if running and not controller.finalized:
		var speeds: Array[float] = [0.5, 1.0, 2.0, 4.0]
		elapsed += delta * speeds[speed_picker.selected]
		while elapsed >= 0.05 and not controller.finalized:
			elapsed -= 0.05
			_step_once()
	_update_unit_positions(delta)

func _step_once() -> void:
	if controller.finalized:
		return
	controller.step()
	_update_labels()
	if controller.finalized:
		running = false
		var record: Dictionary = controller.replay_record()
		replay_label.text = "Replay record: seed %d, two locked snapshots, final result captured." % record.seed
		if not last_result.is_empty():
			replay_label.text += " Repeatability: %s" % ("MATCH" if last_result == controller.result else "MISMATCH")
		last_result = controller.result.duplicate(true)

func _update_labels() -> void:
	arena_a_label.text = "Arena A: A offense vs B defense | Tick %03d | %s" % [controller.arena_a.tick, controller.arena_a.result]
	arena_b_label.text = "Arena B: B offense vs A defense | Tick %03d | %s" % [controller.arena_b.tick, controller.arena_b.result]
	result_label.text = "Match waiting for both arenas" if not controller.finalized else "FINAL SCORE A–B: %s | A: %s | B: %s" % [controller.result.score, controller.result.arena_a.type, controller.result.arena_b.type]
	if not controller.finalized and not running:
		replay_label.text = "Reset and run the same fixture to compare results."

func _snap_unit_positions() -> void:
	for entry in _unit_views():
		entry.mesh.position = _unit_target(entry.arena, entry.unit)
		entry.mesh.visible = true

func _update_unit_positions(delta: float) -> void:
	for entry in _unit_views():
		var target: Vector3 = _unit_target(entry.arena, entry.unit)
		entry.mesh.position = entry.mesh.position.lerp(target, minf(1.0, delta * 12.0))
		entry.mesh.visible = entry.unit.active

func _unit_target(arena: String, unit: Dictionary) -> Vector3:
	var center_x: float = -4.0 if arena == "a" else 4.0
	return Grid.to_world(unit.pos) + Vector3(center_x, 0.55, 0)

func _unit_views() -> Array[Dictionary]:
	var views: Array[Dictionary] = []
	for unit in controller.arena_a.units:
		views.append({"mesh": $Units/A_Runner if unit.role == "runner" else $Units/A_Guard, "arena": "a", "unit": unit})
	for unit in controller.arena_b.units:
		views.append({"mesh": $Units/B_Runner if unit.role == "runner" else $Units/B_Guard, "arena": "b", "unit": unit})
	return views
