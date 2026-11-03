extends SceneTree

const Model = preload("res://scripts/roster/moveset_model.gd")
var failures := 0

func _initialize() -> void:
	var model = Model.new()
	check("load nine definitions", model.load_definitions() == "" and model.definitions.size() == 9)
	var counts := {"runner": 0, "horizontal": 0, "center": 0}
	for definition in model.definitions:
		counts[definition.role] += 1
		check("valid %s" % definition.id, model.validate_definition(definition) == "" and definition.placeholder)
	check("role distribution", counts.runner == 4 and counts.horizontal == 3 and counts.center == 2)
	check("one star rejects second card", model.equip(1) == "Card capacity reached")
	check("two stars allow second card", model.set_star(2) == "" and model.equip(1) == "")
	check("duplicate rejected", model.equip(1) == "Card already equipped")
	check("three stars allow third card", model.set_star(3) == "" and model.equip(2) == "")
	check("order can change", model.move_card(2, -1) == "" and model.equipped == [0, 2, 1])
	var expected: Array[String] = []
	for card_index in model.equipped:
		for command in model.definitions[0].cards[card_index].commands:
			expected.append(command)
	var actual: Array[String] = []
	for i in 24:
		actual.append(model.step_command())
	check("ordered sequence loops identically", actual.slice(0, 12) == expected and actual.slice(12, 24) == expected)
	var invalid: Dictionary = model.definitions[0].duplicate(true)
	invalid.cards[0].commands[0] = "C"
	check("role invalid command rejected", model.validate_definition(invalid).begins_with("Invalid runner command"))
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1
