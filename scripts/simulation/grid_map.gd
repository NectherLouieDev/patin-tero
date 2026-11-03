class_name ArenaGridMap
extends RefCounted

const COLUMNS: int = 4
const ROWS: int = 8

static func contains_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS

static func to_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) - 1.5, 0.0, float(cell.y) - 3.5)

