class_name FormationModel
extends RefCounted

const Grid = preload("res://scripts/simulation/grid_map.gd")

var definitions: Array[Dictionary] = []
var placements: Dictionary = {} # character index -> {arena, cell}

func initialize(roster: Array[Dictionary]) -> void:
	definitions = roster
	placements.clear()

func validate(index: int, arena: String, cell: Vector2i) -> String:
	if index < 0 or index >= definitions.size():
		return "Select a character from the bench"
	var role: String = definitions[index].role
	if role == "runner":
		if arena != "offense" or cell.y != 0 or not Grid.contains_cell(cell):
			return "Runner anchor must be on offense row 0"
	else:
		if arena != "defense":
			return "Guards belong in the defense arena"
		if role == "horizontal" and (cell.y not in [2, 4, 6] or not Grid.contains_cell(cell)):
			return "Horizontal guard anchor must be on row 2, 4, or 6"
		if role == "center" and cell != Vector2i(-1, 3):
			return "Center guard uses the marked center-line anchor"
	var role_count := 0
	for other_index in placements:
		if other_index == index:
			continue
		var other: Dictionary = placements[other_index]
		if other.arena == arena and other.cell == cell:
			return "Anchor is occupied"
		if definitions[other_index].role == role:
			role_count += 1
		if role == "horizontal" and definitions[other_index].role == "horizontal" and other.cell.y == cell.y:
			return "Only one horizontal guard per patrol row"
	var limit := 3 if role != "center" else 1
	if role_count >= limit:
		return "Role deployment limit reached"
	return ""

func place(index: int, arena: String, cell: Vector2i) -> String:
	var error := validate(index, arena, cell)
	if error == "":
		placements[index] = {"arena": arena, "cell": cell}
	return error

func return_to_bench(index: int) -> String:
	if not placements.has(index):
		return "Character is already on the bench"
	placements.erase(index)
	return ""

func snapshot() -> Dictionary:
	return placements.duplicate(true)
