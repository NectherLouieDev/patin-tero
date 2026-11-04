extends SceneTree

const Main = preload("res://scenes/main/game.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node3D = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.get_node("UI/Left/Rows/Setup/Seed").value = 1
	game.start_tournament()
	var shop = game.tournament.shop
	var seeded_offers: bool = shop.offers == [6, 0, 4, 4, 0]
	game.open_planning()
	game.selected_instance = 1
	game.get_node("UI/Left/Rows/Planning/Rows/Arena").select(0)
	game.get_node("UI/Left/Rows/Planning/Rows/X").value = 1
	game.get_node("UI/Left/Rows/Planning/Rows/Y").value = 0
	game.deploy_selected()
	game.get_node("UI/Left/Rows/Planning/Rows/Card").value = 2
	game.use_only_selected_card()
	game.open_shop_popup()
	game.get_node("UI/ShopPopup/Rows/Offers").select(1)
	game.buy_popup_selected()
	game.get_node("UI/ShopPopup/Rows/Offers").select(4)
	game.buy_popup_selected()
	var survivor: Dictionary = game.tournament.session.get_instance(1)
	var ok: bool = seeded_offers and game.selected_instance == 1 and game.notice.contains("Merged into #1") and survivor.star == 2 and survivor.cell == Vector2i(1, 0) and survivor.cards == [2] and shop.bench.size() == 2
	game.queue_free()
	if ok:
		print("PASS: merge selects deployed survivor and explains retained state")
		quit(0)
	else:
		push_error("merge feedback or selection did not match authoritative survivor")
		quit(1)
