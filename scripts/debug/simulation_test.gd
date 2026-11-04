extends Node3D

const Simulation = preload("res://scripts/simulation/arena_simulation.gd")
const Grid = preload("res://scripts/simulation/grid_map.gd")

@onready var runner_mesh: MeshInstance3D = $Runner
@onready var guard_mesh: MeshInstance3D = $Guard
@onready var scenario_picker: OptionButton = $UI/Panel/VBox/Scenario
@onready var status_label: Label = $UI/Panel/VBox/Status
@onready var details_label: Label = $UI/Panel/VBox/Details
@onready var run_button: Button = $UI/Panel/VBox/Buttons/Run
@onready var pause_button: Button = $UI/Panel/VBox/Buttons/Pause
@onready var step_button: Button = $UI/Panel/VBox/Buttons/Step
@onready var reset_button: Button = $UI/Panel/VBox/Buttons/Reset

var simulation = Simulation.new()
var running: bool = false
var accumulator: float = 0.0

func _ready() -> void:
	for title in ["Basic movement", "Boundary and patrol", "Repeatability", "Tag", "Round trip (provisional U)"]:
		scenario_picker.add_item(title)
	scenario_picker.item_selected.connect(func(_index: int) -> void: _reset_scenario())
	run_button.pressed.connect(func() -> void: running = true)
	pause_button.pressed.connect(func() -> void: running = false)
	step_button.pressed.connect(_step_once)
	reset_button.pressed.connect(_reset_scenario)
	_reset_scenario()

func _process(delta: float) -> void:
	if not running:
		return
	accumulator += delta
	while accumulator >= float(simulation.tick_ms) / 1000.0 and running:
		accumulator -= float(simulation.tick_ms) / 1000.0
		_step_once()

func _step_once() -> void:
	simulation.step()
	_update_view()
	if simulation.result != "RUNNING":
		running = false

func _reset_scenario() -> void:
	running = false
	accumulator = 0.0
	var runner: Dictionary = {"id": "runner", "role": "runner", "pos": Vector2i(1, 0), "commands": ["F", "R", "F", "S"]}
	var guard: Dictionary = {"id": "guard", "role": "horizontal", "pos": Vector2i(3, 4), "patrol_row": 4, "commands": ["L", "S", "R", "S"]}
	match scenario_picker.selected:
		1:
			runner.commands = ["L", "L", "F", "S"]
			guard.commands = ["U", "L", "L", "L"]
		2:
			runner.commands = ["F", "R", "F", "L"]
			guard.commands = ["S"]
		3:
			runner.pos = Vector2i(1, 1)
			runner.commands = ["F"]
			guard.pos = Vector2i(1, 2)
			guard.patrol_row = 2
			guard.commands = ["S"]
		4:
			runner.commands = ["F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F"]
			guard.commands = ["S"]
			guard.pos = Vector2i(3, 6)
			guard.patrol_row = 6
	simulation.initialize([runner, guard])
	_update_view()

func _update_view() -> void:
	var lines: Array[String] = []
	for unit in simulation.units:
		var mesh: MeshInstance3D = runner_mesh if unit.role == "runner" else guard_mesh
		mesh.position = Grid.to_world(unit.pos) + Vector3(0, 0.55, 0)
		mesh.visible = unit.active
		lines.append("%s  %s  command %s  %d ticks left%s" % [unit.id, unit.pos, unit.commands[unit.index], unit.remaining, " TAGGED" if unit.tagged else ""])
	status_label.text = "Tick %03d     Result: %s" % [simulation.tick, simulation.result]
	details_label.text = "\n".join(lines) + "\n" + "\n".join(simulation.events) + "\nProvisional: overlap tags; tag before victory; U return command; invalid move stays."
