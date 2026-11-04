class_name ProvisionalMatchPolicy
extends RefCounted

# Isolated fixture command sequence. Tournament matches execute selected cards
# with the same provisional runner turnaround rule.
const RETURN_TRIP: Array[String] = ["F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F", "F"]
const POLICY_ID: String = "selected_cards_turnaround_v1"

static func battle_snapshot(locked_snapshot: Dictionary) -> Dictionary:
	return locked_snapshot.duplicate(true)
