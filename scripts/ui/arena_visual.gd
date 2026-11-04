class_name ArenaVisual
extends Node3D

var assignment: String = "offense"
@export var tag_material: Material
@export var taunt_material: Material
@export var scare_material: Material
@export var victory_material: Material

@onready var unit_pool: Array[Node] = $Units.get_children()
@onready var runner_mesh: Mesh = $Units/Unit0.mesh
@onready var guard_mesh: Mesh = $Units/Unit1.mesh
@onready var first_material: Material = $Units/Unit0.material_override
@onready var second_material: Material = $Units/Unit1.material_override
@onready var preview_pool: Array[Node] = $PreviewMarkers.get_children()
var shown_ids: Array[String] = []
var was_active: Array[bool] = []
var flash_left: Array[float] = []
var visual_clock: Array[float] = []

func _ready() -> void:
	for index in unit_pool.size():
		shown_ids.append("")
		was_active.append(false)
		flash_left.append(0.0)
		visual_clock.append(0.0)
	show_anchors("")

func set_assignment(value: String) -> void:
	assignment = value
	show_anchors("")

func show_anchors(role: String) -> void:
	$RunnerAnchors.visible = assignment == "offense" and role == "runner"
	$GuardAnchors.visible = assignment == "defense" and role == "horizontal"
	$CenterAnchor.visible = assignment == "defense" and role == "center"

func display_units(units: Array, delta: float = 0.0, animate: bool = false) -> void:
	for index in unit_pool.size():
		unit_pool[index].visible = false
		if index >= units.size(): shown_ids[index] = ""
	for index in mini(unit_pool.size(), units.size()):
		var unit: Dictionary = units[index]
		var mesh: MeshInstance3D = unit_pool[index]
		var cell: Vector2i = unit.pos
		var target := Vector3(0.0 if cell.x == -1 else float(cell.x) - 1.5, 0.52, float(cell.y) - 3.5)
		var identity: String = str(unit.get("id", "planning_%d" % index))
		if shown_ids[index] != identity:
			was_active[index] = false
			flash_left[index] = 0.0
			visual_clock[index] = 0.0
		if animate and shown_ids[index] == identity:
			mesh.position = mesh.position.lerp(target, clampf(delta * 18.0, 0.0, 1.0))
		else:
			mesh.position = target
		shown_ids[index] = identity
		mesh.mesh = runner_mesh if unit.role == "runner" else guard_mesh
		var visuals: Node3D = mesh.get_node("Visuals")
		var visual_index: int = clampi(int(str(unit.get("definition_id", "slot_1")).trim_prefix("slot_")) - 1, 0, 8)
		for variant_index in 9:
			visuals.get_node("Variant%d" % variant_index).visible = variant_index == visual_index
		var star: int = clampi(int(unit.get("star", 1)), 1, 3)
		for badge_index in 3:
			visuals.get_node("Star%d" % (badge_index + 1)).visible = badge_index < star
		visuals.get_node("TeamBadge").material_override = first_material if unit.get("team", "A") == "A" else second_material
		var active: bool = bool(unit.get("active", true))
		if animate and was_active[index] and not active and unit.get("tagged", false): flash_left[index] = 0.5
		if not animate: flash_left[index] = 0.0
		else: flash_left[index] = maxf(0.0, flash_left[index] - delta)
		was_active[index] = active
		var command: String = str(unit.get("active_effect", ""))
		var won: bool = bool(unit.get("victory", false))
		var completed: bool = bool(unit.get("completed_trip", false))
		mesh.material_override = tag_material if flash_left[index] > 0.0 else (victory_material if won else (taunt_material if command == "T" and active else (scare_material if command == "C" and active else (first_material if unit.get("team", "A") == "A" else second_material))))
		visual_clock[index] += delta
		var phase: float = visual_clock[index]
		var moving: bool = animate and Vector2(mesh.position.x, mesh.position.z).distance_to(Vector2(target.x, target.z)) > 0.02
		var bob: float = 0.0
		var pulse: float = 1.0
		if flash_left[index] > 0.0:
			bob = 0.04 * absf(sin(phase * 22.0))
			pulse = 1.25
		elif completed:
			bob = 0.2 * absf(sin(phase * 9.0))
			pulse = 1.12 + 0.06 * sin(phase * 11.0)
		elif won:
			bob = 0.11 * absf(sin(phase * 6.0))
			pulse = 1.07 + 0.05 * sin(phase * 8.0)
		elif command == "T" and active:
			bob = 0.1 * absf(sin(phase * 10.0))
			pulse = 1.1 + 0.07 * sin(phase * 11.0)
		elif command == "C" and active:
			bob = 0.05 * sin(phase * 8.0)
			pulse = 1.1 + 0.05 * sin(phase * 12.0)
		elif moving:
			bob = 0.09 * absf(sin(phase * 16.0))
		elif active:
			bob = 0.025 * sin(phase * (3.0 if unit.get("last_command", "") == "S" else 2.0))
		mesh.position.y = target.y + bob
		mesh.scale = Vector3(1.25, 0.72, 1.25) if flash_left[index] > 0.0 else Vector3.ONE * pulse
		visuals.rotation_degrees.z = 12.0 * sin(phase * 13.0) if command == "C" and active else (8.0 * sin(phase * 7.0) if command == "T" and active else (6.0 * sin(phase * 10.0) if won else 0.0))
		visuals.rotation_degrees.y = fmod(phase * 220.0, 360.0) if completed else 0.0
		var desired_angle: float = 0.0
		if unit.role == "runner": desired_angle = PI if unit.get("reached_end", false) else 0.0
		elif unit.get("last_command", "") == "L": desired_angle = -PI / 2.0
		elif unit.get("last_command", "") == "R": desired_angle = PI / 2.0
		elif unit.get("last_command", "") == "U": desired_angle = PI
		mesh.rotation.y = lerp_angle(mesh.rotation.y, desired_angle, clampf(delta * 12.0, 0.0, 1.0)) if animate and delta > 0.0 else desired_angle
		mesh.visible = active or flash_left[index] > 0.0

func show_preview(cells: Array) -> void:
	for marker in preview_pool: marker.visible = false
	for index in mini(preview_pool.size(), cells.size()):
		var cell: Vector2i = cells[index]
		preview_pool[index].position = Vector3(0.0 if cell.x == -1 else float(cell.x) - 1.5, 0.17, float(cell.y) - 3.5)
		preview_pool[index].visible = true

func pick_anchor(screen_position: Vector2, camera: Camera3D, role: String) -> Dictionary:
	if role == "runner" and assignment != "offense": return {}
	if role != "runner" and assignment != "defense": return {}
	var local: Vector3 = _project_to_board(screen_position, camera)
	if local == Vector3.INF: return {}
	if role == "center":
		return {"arena": assignment, "cell": Vector2i(-1, 3)} if absf(local.x) < 0.38 and absf(local.z + 0.5) < 0.38 else {}
	var cell := Vector2i(roundi(local.x + 1.5), roundi(local.z + 3.5))
	if cell.x < 0 or cell.x > 3 or absf(local.x - (float(cell.x) - 1.5)) > 0.47 or absf(local.z - (float(cell.y) - 3.5)) > 0.47: return {}
	if role == "runner" and cell.y != 0: return {}
	if role == "horizontal" and cell.y not in [2, 4, 6]: return {}
	return {"arena": assignment, "cell": cell}

func pick_occupied_cell(screen_position: Vector2, camera: Camera3D) -> Dictionary:
	var local: Vector3 = _project_to_board(screen_position, camera)
	if local == Vector3.INF: return {}
	if assignment == "defense" and absf(local.x) < 0.38 and absf(local.z + 0.5) < 0.38:
		return {"arena": assignment, "cell": Vector2i(-1, 3)}
	var cell := Vector2i(roundi(local.x + 1.5), roundi(local.z + 3.5))
	if cell.x < 0 or cell.x > 3 or cell.y < 0 or cell.y > 7: return {}
	if absf(local.x - (float(cell.x) - 1.5)) > 0.47 or absf(local.z - (float(cell.y) - 3.5)) > 0.47: return {}
	return {"arena": assignment, "cell": cell}

func _project_to_board(screen_position: Vector2, camera: Camera3D) -> Vector3:
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.001: return Vector3.INF
	var distance: float = -origin.y / direction.y
	if distance <= 0.0: return Vector3.INF
	return to_local(origin + direction * distance)
