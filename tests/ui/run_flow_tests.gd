extends SceneTree

const MAIN = preload("res://scenes/main/game.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = MAIN.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.screen == "SETUP", "main scene opens at setup")
	_check(game.get_node("UI/Right/Rows/Content/Lobby").text.contains("7 seeded bots") and game.get_node("UI/Right/Rows/Content/Lobby").text.contains("8 → 6 → 4 → 2 → 1"), "lobby states participants and format")
	var arena_a: Node = game.get_node("Offense")
	var arena_b: Node = game.get_node("Defense")
	_check(arena_a.get_node("Tiles").get_child_count() == 32 and arena_b.get_node("Tiles").get_child_count() == 32, "both instanced grids have 32 authored tiles")
	_check(arena_a.get_node("Units").get_child_count() == 16 and arena_b.get_node("Units").get_child_count() == 16, "placeholder unit nodes are in each arena scene tree")
	_check(arena_a.get_node("PreviewMarkers").get_child_count() == 8 and arena_b.get_node("PreviewMarkers").get_child_count() == 8, "path preview markers are authored in both arena scenes")
	var visual_runner: Dictionary = {"id": "test_runner", "definition_id": "slot_4", "star": 3, "role": "runner", "pos": Vector2i(1, 7), "team": "A", "active": true, "reached_end": true, "active_effect": "T"}
	arena_a.display_units([visual_runner], 0.0, true)
	_check(arena_a.get_node("Units/Unit0").rotation_degrees.y == 180.0 and arena_a.get_node("Units/Unit0").material_override == arena_a.taunt_material, "runner heading reverses and TAUNT changes its material")
	_check(arena_a.get_node("Units/Unit0/Visuals/Variant3").visible and arena_a.get_node("Units/Unit0/Visuals/Star3").visible, "character identity and three-star badge render from unit state")
	visual_runner.active_effect = ""
	visual_runner.victory = true
	arena_a.display_units([visual_runner], 0.05, true)
	_check(arena_a.get_node("Units/Unit0").material_override == arena_a.victory_material, "completed round trip displays victory cue")
	visual_runner.active = false
	visual_runner.tagged = true
	arena_a.display_units([visual_runner], 0.05, true)
	_check(arena_a.get_node("Units/Unit0").visible and arena_a.get_node("Units/Unit0").material_override == arena_a.tag_material, "tag keeps a visible brief hit cue")
	arena_a.display_units([], 0.0, false)
	_check(is_equal_approx(game.get_node("Camera3D").position.y, 13.427067), "main camera uses the approved transform")
	game.start_tournament()
	_check(game.screen == "PLAN" and game.get_node("UI/ShopPopup").visible and game.get_node("UI/ShopBlocker").visible, "start opens planning shop modal over arenas")
	_check(game.tournament.shop.bench.size() >= 2, "starters appear in roster")
	var first_role: String = str(game.tournament.shop.definitions[game.tournament.shop.offers[0]].role).capitalize()
	_check(game.get_node("UI/ShopPopup/Rows/Offers").get_item_icon(0) != null and game.get_node("UI/ShopPopup/Rows/Offers").get_item_text(0).contains("coins") and game.get_node("UI/ShopPopup/Rows/Offers").get_item_text(0).contains(first_role), "shop offer shows portrait, role, and cost")
	var coins: int = game.tournament.shop.coins
	game.buy_popup_selected()
	_check(game.tournament.shop.coins == coins and game.notice.contains("Select"), "invalid buy preserves coins and explains action")
	game.get_node("UI/ShopPopup/Rows/Offers").emit_signal("item_clicked", 0, Vector2.ZERO, MOUSE_BUTTON_LEFT)
	_check(game.tournament.shop.coins < coins and game.tournament.shop.bench.size() == 3, "shop purchase changes authoritative roster and balance")
	_check(game.get_node("UI/ShopPopup/Rows/Offers").is_item_disabled(0) and game.get_node("UI/ShopPopup/Rows/Balance").text.contains("2–0 bonus"), "sold offer is disabled and reward rule is displayed")
	coins = game.tournament.shop.coins
	game.reroll_shop()
	_check(game.tournament.shop.coins == coins - 2 and game.tournament.shop.offers.size() == 5, "reroll uses authoritative shop cost")
	coins = game.tournament.shop.coins
	game.tournament.shop.coins = 0
	game._refresh()
	_check(game.get_node("UI/ShopPopup/Rows/Reroll").disabled and game.get_node("UI/ShopPopup/Rows/Offers").is_item_disabled(0), "unaffordable offers and reroll disable below their costs")
	game.tournament.shop.coins = coins
	game._refresh()
	game.open_planning()
	_check(game.screen == "PLAN", "shop opens planning")
	game.open_shop_popup()
	_check(game.screen == "PLAN" and game.get_node("UI/ShopPopup").visible, "shop window opens over planning")
	game.close_shop_popup()
	_check(game.screen == "PLAN" and not game.get_node("UI/ShopPopup").visible and not game.get_node("UI/ShopBlocker").visible, "closing shop restores arena interaction")
	game.selected_instance = 1
	game.get_node("UI/Left/Rows/Planning/Rows/Arena").select(1)
	game.get_node("UI/Left/Rows/Planning/Rows/X").value = 1
	game.get_node("UI/Left/Rows/Planning/Rows/Y").value = 1
	game.deploy_selected()
	_check(game.tournament.session.get_instance(1).location == "bench" and game.notice.contains("Runner"), "invalid placement keeps unit on bench")
	game.get_node("UI/Left/Rows/Planning/Rows/Arena").select(0)
	game.get_node("UI/Left/Rows/Planning/Rows/Y").value = 0
	var runner_anchor: Vector2 = game.get_node("Camera3D").unproject_position(arena_a.to_global(Vector3(-0.5, 0, -3.5)))
	game._begin_roster_drag(0, Vector2.ZERO, MOUSE_BUTTON_LEFT)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = runner_anchor
	game._input(release)
	_check(game.tournament.session.get_instance(1).cell == Vector2i(1, 0), "dragging a runner to a scene anchor deploys it")
	_check(arena_a.get_node("PreviewMarkers/Marker0").visible and game.get_node("UI/Left/Rows/Planning/Rows/CardPreview").text.contains("PATH PREVIEW"), "deployed runner displays its command path in the scene and panel")
	game._begin_roster_drag(0, Vector2.ZERO, MOUSE_BUTTON_LEFT)
	release.position = game.get_node("Camera3D").unproject_position(Vector3(0, 0, 0))
	game._input(release)
	_check(game.tournament.session.get_instance(1).cell == Vector2i(1, 0), "invalid drop preserves the previous deployment")
	game.selected_instance = 2
	game.get_node("UI/Left/Rows/Planning/Rows/Arena").select(1)
	game.get_node("UI/Left/Rows/Planning/Rows/Y").value = 4
	game.deploy_selected()
	_check(game.tournament.session.get_instance(2).cell == Vector2i(1, 4), "valid guard anchor is shown in shared state")
	game.selected_instance = 1
	game.get_node("UI/Left/Rows/Planning/Rows/Card").value = 2
	game.use_only_selected_card()
	_check(game.tournament.session.get_instance(1).cards == [2], "one-star player selects a different signature card")
	game.get_node("UI/Left/Rows/Planning/Rows/Card").value = 1
	game.equip_selected()
	_check(game.tournament.session.get_instance(1).cards == [2] and game.notice.contains("capacity"), "one-star card rejection preserves card order")
	game.lock_formation()
	_check(game.screen == "BATTLE" and not game.get_node("UI/ShopPopup").visible, "locking starts first match and closes shop")
	game.open_shop_popup()
	_check(not game.get_node("UI/ShopPopup").visible and game.notice.contains("closed"), "shop cannot reopen during battle")
	_check(not arena_a.get_node("PreviewMarkers/Marker0").visible and game.battle_countdown > 0.0, "battle clears planning markers and begins a countdown")
	game._process(1.0)
	_check(game.tournament.current_match.arena_a.tick == 0 and game.get_node("UI/Left/Rows/Battle/Status").text.contains("starts in"), "countdown holds simulation before the match")
	game._process(2.0)
	game._process(0.05)
	_check(game.tournament.current_match.arena_a.tick > 0 and game.get_node("UI/Left/Rows/Battle/Focus").text.contains("Command"), "live battle advances and reports selected unit command")
	_check(game.tournament.player_snapshot.units.size() == 3, "manual formation and purchased unit reach match input")
	var chosen_commands: Array = []
	for unit in game.tournament.current_match.replay_record().snapshot_a.units:
		if unit.instance_id == 1: chosen_commands = unit.commands
	_check(chosen_commands == game.tournament.shop.definitions[0].cards[2].commands, "battle executes the selected runner card commands")
	var tick_before_speed: int = game.tournament.current_match.arena_a.tick
	game.toggle_battle_speed()
	_check(game.tournament.current_match.arena_a.tick == tick_before_speed and game.battle_speed == 4, "display speed does not step authoritative battle")
	game.toggle_battle_speed()
	_check(game.get_node("Offense") == arena_a and game.get_node("Defense") == arena_b, "arenas persist through battle")
	var guard: int = 0
	while game.screen != "CHAMPION" and guard < 50:
		guard += 1
		if game.screen == "BATTLE":
			for tick in 1000:
				if game.screen != "BATTLE": break
				game._step_match()
			_check(game.screen == "RESULTS", "match reaches result")
		elif game.screen == "RESULTS": game.continue_after_result()
		elif game.screen == "STANDINGS":
			game.advance_stage()
			if game.screen == "PLAN" and game.tournament.shop.planning_open and 1 in game.tournament.active:
				_check(game.get_node("UI/ShopPopup").visible, "new round reopens the planning shop")
		elif game.screen == "SHOP" or game.screen == "PLAN":
			game.open_planning()
			if game.get_node("UI/ShopPopup").visible: game.close_shop_popup()
			game.lock_formation()
		else: break
	_check(game.screen == "CHAMPION" and game.tournament.champion > 0, "full tournament declares champion")
	_check(game.get_node("UI/Right/Rows/Content/History").item_count == 10 and game.get_node("UI/Right/Rows/Content/HistoryDetails").text.contains("A:"), "completed matches are reviewable")
	_check(game.get_node("UI/Left/Rows/Champion/Summary").text.contains("Final standings"), "champion screen shows final performance")
	_check(game.get_node("Offense") == arena_a and game.get_node("Defense") == arena_b, "arenas persist through tournament")
	game.get_node("UI/Left/Rows/Champion/New").emit_signal("pressed")
	_check(game.screen == "SETUP", "new tournament returns to setup")
	_check(game.tournament.match_history.is_empty() and game.tournament.current_match == null, "new tournament setup clears prior match state")
	game.start_tournament()
	_check(game.tournament.match_history.is_empty() and game.tournament.stage_index == 0, "new tournament clears prior results")
	game.open_planning()
	game.open_shop_popup()
	var popup_coins: int = game.tournament.shop.coins
	game.get_node("UI/ShopPopup/Rows/Offers").select(0)
	game.buy_popup_selected()
	_check(game.tournament.shop.coins < popup_coins and game.tournament.shop.bench.size() == 3 and game.screen == "PLAN", "modal shop purchases while planning stays open")
	game.close_shop_popup()
	game.queue_free()
	if failures.is_empty():
		print("PASS: Milestone 9 player flow")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, description: String) -> void:
	if not condition: failures.append(description)


