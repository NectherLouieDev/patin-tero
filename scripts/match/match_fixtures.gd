class_name MatchFixtures
extends RefCounted

const RETURN_TRIP: Array[String] = ["F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F"]

static func build(score_case: int) -> Dictionary:
	# Fixture A wins offense for 2-0 and 1-1. Fixture B wins offense for 1-1 and 0-2.
	var a_wins_offense: bool = score_case != 2
	var b_wins_offense: bool = score_case != 0
	var a: Dictionary = {"locked": true, "units": [
		_unit(1, "fixture_a_runner", "runner", "offense", Vector2i(0, 0), RETURN_TRIP),
		_unit(2, "fixture_a_guard", "horizontal", "defense", Vector2i(3, 4) if b_wins_offense else Vector2i(0, 2), ["S"])
	]}
	var b: Dictionary = {"locked": true, "units": [
		_unit(3, "fixture_b_runner", "runner", "offense", Vector2i(0, 0), RETURN_TRIP),
		_unit(4, "fixture_b_guard", "horizontal", "defense", Vector2i(3, 4) if a_wins_offense else Vector2i(0, 2), ["S"])
	]}
	return {"a": a, "b": b, "name": ["2-0", "1-1", "0-2"][score_case]}

static func _unit(id: int, definition_id: String, role: String, arena: String, cell: Vector2i, commands: Array[String]) -> Dictionary:
	return {"instance_id": id, "definition_id": definition_id, "role": role, "arena": arena, "cell": cell, "star": 1, "card_ids": ["TEST_MATCH_FIXTURE"], "commands": commands.duplicate()}
