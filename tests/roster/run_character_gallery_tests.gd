extends SceneTree

const Gallery = preload("res://scenes/debug/character_gallery.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gallery: Node3D = Gallery.instantiate()
	root.add_child(gallery)
	await process_frame
	_check(gallery.get_node("UI/Panel/Rows/Characters").item_count == 9, "all nine provisional characters can be inspected")
	var arena: Node3D = gallery.get_node("Arena")
	for index in 9:
		_check(arena.get_node("Units/Unit%d/Visuals/Variant%d" % [index, index]).visible, "character %d uses its own authored silhouette" % [index + 1])
	gallery._select_character(8)
	gallery._set_star(3.0)
	gallery._process(0.05)
	_check(arena.get_node("Units/Unit8/Visuals/Star3").visible and gallery.get_node("UI/Panel/Rows/Summary").text.contains("★3"), "three-star visual badge and character details agree")
	gallery._set_state(4)
	gallery._process(0.05)
	_check(arena.get_node("Units/Unit8").material_override == arena.scare_material, "guard SCARE preview uses its visual state")
	gallery._set_state(7)
	gallery._process(0.05)
	_check(arena.get_node("Units/Unit8").material_override == arena.victory_material, "victory preview uses its visual state")
	gallery.queue_free()
	if failures.is_empty():
		print("PASS: Section 4 character gallery")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, description: String) -> void:
	if not condition: failures.append(description)
