extends Node3D

const Tournament = preload("res://scripts/tournament/tournament_model.gd")
const ArenaView = preload("res://scripts/ui/arena_visual.gd")
const Simulation = preload("res://scripts/simulation/arena_simulation.gd")
const TICK_SECONDS := 0.05

var tournament = Tournament.new()
var screen: String = "SETUP"
var selected_instance: int = 0
var running: bool = false
var elapsed: float = 0.0
var battle_countdown: float = 0.0
var battle_speed: int = 1
var dragging_roster: bool = false
var notice: String = "Start a tournament to enter the shop."
var shop_icons: Array[Texture2D] = []

@onready var groups: Dictionary = {
	"SETUP": $UI/Left/Rows/Setup,
	"SHOP": $UI/Left/Rows/Shop,
	"PLAN": $UI/Left/Rows/Planning,
	"BATTLE": $UI/Left/Rows/Battle,
	"RESULTS": $UI/Left/Rows/Results,
	"STANDINGS": $UI/Left/Rows/Standings,
	"CHAMPION": $UI/Left/Rows/Champion,
}
@onready var offense_view: ArenaView = $Offense
@onready var defense_view: ArenaView = $Defense
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	for index in 9:
		shop_icons.append(load("res://assets/characters/shop_icons/slot_%d.svg" % (index + 1)))
	offense_view.set_assignment("offense")
	defense_view.set_assignment("defense")
	$UI/Left/Rows/Setup/Start.pressed.connect(start_tournament)
	$UI/Left/Rows/Shop/Buy.pressed.connect(buy_selected)
	$UI/Left/Rows/Shop/Reroll.pressed.connect(reroll_shop)
	$UI/Left/Rows/Shop/ToPlan.pressed.connect(open_planning)
	$UI/Left/Rows/Planning/Rows/Back.pressed.connect(open_shop)
	$UI/Left/Rows/Planning/Rows/Deploy.pressed.connect(deploy_selected)
	$UI/Left/Rows/Planning/Rows/Return.pressed.connect(return_selected)
	$UI/Left/Rows/Planning/Rows/Equip.pressed.connect(equip_selected)
	$UI/Left/Rows/Planning/Rows/UseOnly.pressed.connect(use_only_selected_card)
	$UI/Left/Rows/Planning/Rows/Unequip.pressed.connect(unequip_selected_card)
	$UI/Left/Rows/Planning/Rows/Earlier.pressed.connect(move_card_earlier)
	$UI/Left/Rows/Planning/Rows/Later.pressed.connect(move_card_later)
	$UI/ShopPopup/Rows/Close.pressed.connect(close_shop_popup)
	$UI/ShopPopup/Rows/Buy.pressed.connect(buy_popup_selected)
	$UI/ShopPopup/Rows/Reroll.pressed.connect(reroll_shop)
	$UI/Left/Rows/Planning/Rows/Lock.pressed.connect(lock_formation)
	$UI/Left/Rows/Battle/Pause.pressed.connect(toggle_run)
	$UI/Left/Rows/Battle/Step.pressed.connect(step_battle)
	$UI/Left/Rows/Battle/Speed.pressed.connect(toggle_battle_speed)
	$UI/Left/Rows/Results/Continue.pressed.connect(continue_after_result)
	$UI/Left/Rows/Standings/Advance.pressed.connect(advance_stage)
	$UI/Left/Rows/Champion/New.pressed.connect(new_tournament_setup)
	$UI/Left/Rows/Planning/Rows/Arena.add_item("Offense")
	$UI/Left/Rows/Planning/Rows/Arena.add_item("Defense")
	$UI/Left/Rows/Shop/Bench.item_selected.connect(_select_bench)
	$UI/Left/Rows/Shop/Offers.item_selected.connect(func(_index: int) -> void: _refresh_shop_controls())
	$UI/ShopPopup/Rows/Offers.item_selected.connect(func(_index: int) -> void: _refresh_shop_controls())
	$UI/ShopPopup/Rows/Offers.item_clicked.connect(_click_popup_offer)
	$UI/Left/Rows/Planning/Rows/Roster.item_selected.connect(_select_roster)
	$UI/Left/Rows/Planning/Rows/Roster.item_clicked.connect(_begin_roster_drag)
	$UI/Right/Rows/Content/History.item_selected.connect(_select_history)
	$UI/Left/Rows/Planning/Rows/Arena.item_selected.connect(func(_index: int) -> void: _refresh())
	_refresh()

func _process(delta: float) -> void:
	if screen == "RESULTS":
		_draw_units(delta)
		return
	if screen != "BATTLE" or not running: return
	if battle_countdown > 0.0:
		battle_countdown = maxf(0.0, battle_countdown - delta)
		_refresh_battle_state()
		return
	elapsed += delta
	while elapsed >= TICK_SECONDS / float(battle_speed) and running:
		elapsed -= TICK_SECONDS / float(battle_speed)
		_step_match()
	_refresh_battle_state()
	_draw_units(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and $UI/ShopPopup.visible:
		close_shop_popup()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and screen == "BATTLE":
		toggle_run()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if screen != "PLAN" or 1 not in tournament.active or $UI/ShopPopup.visible or not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or event.pressed: return
	var drop: Dictionary = _pick_board_anchor(event.position)
	if dragging_roster:
		dragging_roster = false
		if not drop.is_empty(): _deploy_to(drop)
		elif event.position.x > 312.0: _message("Release over a highlighted role anchor.")
		return
	var occupied: Dictionary = offense_view.pick_occupied_cell(event.position, camera)
	if occupied.is_empty(): occupied = defense_view.pick_occupied_cell(event.position, camera)
	if not occupied.is_empty():
		for index in tournament.shop.bench.size():
			var item: Dictionary = tournament.shop.bench[index]
			if item.get("location", "bench") == occupied.arena and item.get("cell", Vector2i(-9, -9)) == occupied.cell:
				_select_roster(index)
				return
	if not drop.is_empty() and selected_instance > 0: _deploy_to(drop)

func start_tournament() -> void:
	var error: String = tournament.initialize(int($UI/Left/Rows/Setup/Seed.value))
	if error != "": _message(error); return
	selected_instance = 1
	_set_screen("PLAN", "Tournament started with seven seeded bots. Click an offer to buy, then close the shop to plan.")
	open_shop_popup()

func new_tournament_setup() -> void:
	tournament = Tournament.new()
	selected_instance = 0
	running = false
	elapsed = 0.0
	battle_countdown = 0.0
	$UI/ShopPopup.visible = false
	$UI/ShopBlocker.visible = false
	_set_screen("SETUP", "Enter a seed to start a fresh tournament.")

func buy_selected() -> void:
	var picked: PackedInt32Array = $UI/Left/Rows/Shop/Offers.get_selected_items()
	if picked.is_empty(): _message("Select a shop offer first."); return
	var result: String = tournament.buy(picked[0])
	if result.begins_with("Purchased") and tournament.shop.last_merge_survivor_id > 0: selected_instance = tournament.shop.last_merge_survivor_id
	_message(result)

func reroll_shop() -> void:
	_message(tournament.reroll())

func open_planning() -> void:
	if tournament.phase != "PLANNING": _message("Planning is unavailable."); return
	_set_screen("PLAN", "Select a unit and an anchor, then deploy it. Lock when ready.")

func open_shop() -> void:
	open_shop_popup()

func open_shop_popup() -> void:
	if screen != "PLAN" or tournament.phase != "PLANNING" or not tournament.shop.planning_open or 1 not in tournament.active:
		_message("The shop is closed for this stage.")
		return
	$UI/ShopPopup.visible = true
	$UI/ShopBlocker.visible = true
	_refresh()

func close_shop_popup() -> void:
	$UI/ShopPopup.visible = false
	$UI/ShopBlocker.visible = false
	_refresh()

func buy_popup_selected() -> void:
	var picked: PackedInt32Array = $UI/ShopPopup/Rows/Offers.get_selected_items()
	if picked.is_empty(): _message("Select a shop offer first."); return
	var result: String = tournament.buy(picked[0])
	if result.begins_with("Purchased") and tournament.shop.last_merge_survivor_id > 0: selected_instance = tournament.shop.last_merge_survivor_id
	_message(result)

func _click_popup_offer(index: int, _position: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT: return
	var reason: String = tournament.shop.can_buy(index)
	if reason != "":
		_message(reason)
		return
	var result: String = tournament.buy(index)
	if result.begins_with("Purchased") and tournament.shop.last_merge_survivor_id > 0: selected_instance = tournament.shop.last_merge_survivor_id
	_message(result)

func _select_bench(index: int) -> void:
	if index < tournament.shop.bench.size(): selected_instance = int(tournament.shop.bench[index].instance_id)
	_refresh()

func _select_roster(index: int) -> void:
	if index < tournament.shop.bench.size():
		selected_instance = int(tournament.shop.bench[index].instance_id)
		var selected: Dictionary = tournament.session.get_instance(selected_instance)
		if selected.has("cell"):
			$UI/Left/Rows/Planning/Rows/Arena.select(0 if selected.location == "offense" else 1)
			$UI/Left/Rows/Planning/Rows/X.value = selected.cell.x
			$UI/Left/Rows/Planning/Rows/Y.value = selected.cell.y
	_refresh()

func _begin_roster_drag(index: int, _position: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT or tournament.phase != "PLANNING" or 1 not in tournament.active: return
	_select_roster(index)
	dragging_roster = true

func _pick_board_anchor(screen_position: Vector2) -> Dictionary:
	var selected: Dictionary = tournament.session.get_instance(selected_instance)
	if selected.is_empty(): return {}
	var role: String = str(tournament.shop.definitions[int(selected.definition_index)].role)
	var anchor: Dictionary = offense_view.pick_anchor(screen_position, camera, role)
	return anchor if not anchor.is_empty() else defense_view.pick_anchor(screen_position, camera, role)

func _deploy_to(anchor: Dictionary) -> void:
	var result: String = tournament.session.deploy(selected_instance, str(anchor.arena), anchor.cell)
	if result == "":
		$UI/Left/Rows/Planning/Rows/Arena.select(0 if anchor.arena == "offense" else 1)
		$UI/Left/Rows/Planning/Rows/X.value = anchor.cell.x
		$UI/Left/Rows/Planning/Rows/Y.value = anchor.cell.y
	_message("Unit #%d deployed to %s (%d, %d)." % [selected_instance, anchor.arena, anchor.cell.x, anchor.cell.y] if result == "" else result)

func deploy_selected() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var arena: String = "offense" if $UI/Left/Rows/Planning/Rows/Arena.selected == 0 else "defense"
	var cell := Vector2i(int($UI/Left/Rows/Planning/Rows/X.value), int($UI/Left/Rows/Planning/Rows/Y.value))
	var result: String = tournament.session.deploy(selected_instance, arena, cell)
	_message("Unit #%d deployed to %s (%d, %d)." % [selected_instance, arena, cell.x, cell.y] if result == "" else result)

func return_selected() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var result: String = tournament.session.return_to_bench(selected_instance)
	_message("Unit #%d returned to bench." % selected_instance if result == "" else result)

func equip_selected() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var index: int = int($UI/Left/Rows/Planning/Rows/Card.value)
	var result: String = tournament.session.equip(selected_instance, index)
	_message("Card %d equipped." % [index + 1] if result == "" else result)

func use_only_selected_card() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var index: int = int($UI/Left/Rows/Planning/Rows/Card.value)
	var result: String = tournament.session.set_cards(selected_instance, [index])
	_message("Using only card %d." % [index + 1] if result == "" else result)

func unequip_selected_card() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var cards: Array = tournament.session.get_instance(selected_instance).get("cards", []).duplicate()
	cards.erase(int($UI/Left/Rows/Planning/Rows/Card.value))
	var result: String = tournament.session.set_cards(selected_instance, cards)
	_message("Card removed." if result == "" else result)

func move_card_earlier() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var index: int = int($UI/Left/Rows/Planning/Rows/Card.value)
	var result: String = tournament.session.move_card(selected_instance, index, -1)
	_message("Card moved earlier." if result == "" else result)

func move_card_later() -> void:
	if selected_instance == 0: _message("Select a roster unit first."); return
	var index: int = int($UI/Left/Rows/Planning/Rows/Card.value)
	var result: String = tournament.session.move_card(selected_instance, index, 1)
	_message("Card moved later." if result == "" else result)

func lock_formation() -> void:
	var result: String = tournament.lock_planning()
	if result != "": _message(result); return
	begin_battle()

func begin_battle() -> void:
	var result: String = tournament.begin_next_match()
	if result != "": _message(result); return
	running = true
	elapsed = 0.0
	battle_countdown = 3.0
	var pair: Dictionary = tournament.pairings[tournament.next_match]
	_set_screen("BATTLE", "%s versus %s. Battle starts after the countdown." % [_participant_name(int(pair.a)), _participant_name(int(pair.b))])

func toggle_run() -> void:
	if screen != "BATTLE": return
	running = not running
	_message("Battle running." if running else "Battle paused. Press Step or Space to resume.")

func step_battle() -> void:
	if screen != "BATTLE": return
	running = false
	battle_countdown = 0.0
	_step_match()
	_refresh()

func toggle_battle_speed() -> void:
	battle_speed = 1 if battle_speed == 4 else 4
	_message("Battle display speed: %dx." % battle_speed)

func _step_match() -> void:
	var result: String = tournament.step_current_match()
	if result != "":
		running = false
		_set_screen("RESULTS", result)

func continue_after_result() -> void:
	if tournament.phase == "MATCHES": begin_battle()
	elif tournament.phase == "STANDINGS": _set_screen("STANDINGS", "All matches complete. Review the standings.")

func advance_stage() -> void:
	var result: String = tournament.advance_stage()
	if tournament.phase == "COMPLETE": _set_screen("CHAMPION", result)
	elif tournament.phase == "PLANNING":
		var message: String = "%s • You received +%d base coins." % [result, int(tournament.shop.config.round_income)] if 1 in tournament.active else "You were eliminated. Continue to watch the bot matches."
		if 1 in tournament.active and not tournament.shop.planning_open: message += " Championship shop is closed; adjust your formation and cards."
		_set_screen("PLAN", message)
		if tournament.shop.planning_open and 1 in tournament.active: open_shop_popup()
	else: _message(result)

func _set_screen(next: String, message: String) -> void:
	screen = next
	if next != "PLAN":
		$UI/ShopPopup.visible = false
		$UI/ShopBlocker.visible = false
	notice = message
	_refresh()

func _message(message: String) -> void:
	notice = message
	_refresh()

func _refresh() -> void:
	for key in groups: groups[key].visible = key == screen
	$UI/Left/Rows/Feedback.text = notice
	$UI/Left/Rows/Planning/Rows/Back.disabled = not tournament.shop.planning_open or 1 not in tournament.active or tournament.active.size() == 2
	var can_edit: bool = screen == "PLAN" and tournament.phase == "PLANNING" and 1 in tournament.active
	for path in ["Deploy", "Return", "Equip", "UseOnly", "Unequip", "Earlier", "Later"]:
		get_node("UI/Left/Rows/Planning/Rows/" + path).disabled = not can_edit
	$UI/Left/Rows/Planning/Rows/Lock.text = "Lock Formation & Battle →" if 1 in tournament.active else "Watch Next Bot Matches →"
	$UI/Left/Rows/Battle/Pause.text = "Pause (Space)" if running else "Run (Space)"
	$UI/Left/Rows/Battle/Speed.text = "Display speed: %dx" % battle_speed
	$UI/Right/Rows/Content/Heading.text = "PATIN / TERO!\nSURVIVAL LEAGUE"
	$UI/Right/Rows/Content/Stage.text = "Choose a seed to begin." if screen == "SETUP" else "Stage %d • %d players • %s\nCoins: %d" % [tournament.stage_index + 1, tournament.active.size(), tournament.phase, tournament.shop.coins]
	$UI/Right/Rows/Content/Lobby.text = "8-player Survival League\nYou + 7 seeded bots • ready\nEliminations: 8 → 6 → 4 → 2 → 1" if screen == "SETUP" else ""
	_refresh_shop()
	_refresh_shop_controls()
	_refresh_roster()
	_refresh_battle_state()
	_refresh_standings()
	_refresh_opponent()
	_refresh_history()
	_draw_units()

func _refresh_shop() -> void:
	var offers: ItemList = $UI/Left/Rows/Shop/Offers
	var selected: PackedInt32Array = offers.get_selected_items()
	offers.clear()
	for index in tournament.shop.offers.size():
		var definition_index: int = tournament.shop.offers[index]
		var icon: Texture2D = shop_icons[definition_index] if definition_index >= 0 and definition_index < shop_icons.size() else null
		offers.add_item(_offer_label(index), icon)
		offers.set_item_disabled(index, tournament.shop.can_buy(index) != "")
	if not selected.is_empty() and selected[0] < offers.item_count and not offers.is_item_disabled(selected[0]): offers.select(selected[0])
	var popup_offers: ItemList = $UI/ShopPopup/Rows/Offers
	var popup_selected: PackedInt32Array = popup_offers.get_selected_items()
	popup_offers.clear()
	for index in tournament.shop.offers.size():
		var definition_index: int = tournament.shop.offers[index]
		var icon: Texture2D = shop_icons[definition_index] if definition_index >= 0 and definition_index < shop_icons.size() else null
		popup_offers.add_item(_offer_label(index), icon)
		popup_offers.set_item_disabled(index, tournament.shop.can_buy(index) != "")
	if not popup_selected.is_empty() and popup_selected[0] < popup_offers.item_count and not popup_offers.is_item_disabled(popup_selected[0]): popup_offers.select(popup_selected[0])
	$UI/ShopPopup/Rows/Balance.text = "Coins: %d • Reroll: %d • Next round: +%d • 2–0 bonus: +%d" % [tournament.shop.coins, int(tournament.shop.config.reroll_cost), int(tournament.shop.config.round_income), int(tournament.shop.config.bonus_2_0)] if not tournament.shop.config.is_empty() else ""
	var bench: ItemList = $UI/Left/Rows/Shop/Bench
	bench.clear()
	for item in tournament.shop.bench:
		var definition: Dictionary = tournament.shop.definitions[int(item.definition_index)]
		bench.add_item("#%d %s ★%d • %s" % [item.instance_id, definition.name, item.star, item.get("location", "bench")])

func _offer_label(index: int) -> String:
	var definition_index: int = tournament.shop.offers[index]
	if definition_index < 0: return "%d. SOLD" % (index + 1)
	var definition: Dictionary = tournament.shop.definitions[definition_index]
	var owned: int = 0
	for item in tournament.shop.bench:
		if int(item.definition_index) == definition_index: owned += 1
	var reason: String = tournament.shop.can_buy(index)
	return "%d. %s • %s • %d coins • owned %d%s" % [index + 1, definition.name, str(definition.role).capitalize(), int(tournament.shop.config.prices[definition_index]), owned, " • " + reason if reason != "" else ""]

func _refresh_shop_controls() -> void:
	var shop_open: bool = tournament.phase == "PLANNING" and tournament.shop.planning_open and 1 in tournament.active and tournament.active.size() > 2
	for path in ["UI/Left/Rows/Shop", "UI/ShopPopup/Rows"]:
		var offers: ItemList = get_node(path + "/Offers")
		var picked: PackedInt32Array = offers.get_selected_items()
		var can_buy_selected: bool = shop_open and not picked.is_empty() and tournament.shop.can_buy(picked[0]) == ""
		get_node(path + "/Buy").disabled = not can_buy_selected
		get_node(path + "/Reroll").disabled = not shop_open or tournament.shop.can_reroll() != ""
		get_node(path + "/OfferDetails").text = _offer_detail(picked[0]) if not picked.is_empty() else "Select an available offer. Sold, unaffordable, and full-bench offers are disabled."

func _offer_detail(index: int) -> String:
	if index < 0 or index >= tournament.shop.offers.size() or tournament.shop.offers[index] < 0: return "This offer is sold."
	var definition_index: int = tournament.shop.offers[index]
	var definition: Dictionary = tournament.shop.definitions[definition_index]
	return "%s • %s • %d coins\n%s" % [definition.name, str(definition.role).capitalize(), int(tournament.shop.config.prices[definition_index]), "Available to purchase" if tournament.shop.can_buy(index) == "" else tournament.shop.can_buy(index)]

func _refresh_roster() -> void:
	var roster: ItemList = $UI/Left/Rows/Planning/Rows/Roster
	roster.clear()
	for item in tournament.shop.bench:
		var definition: Dictionary = tournament.shop.definitions[int(item.definition_index)]
		roster.add_item("#%d %s • %s • %s" % [item.instance_id, definition.name, definition.role, item.get("location", "bench")])
		if int(item.instance_id) == selected_instance: roster.select(roster.item_count - 1)
	var selected: Dictionary = tournament.session.get_instance(selected_instance)
	if selected.is_empty():
		$UI/Left/Rows/Planning/Rows/Selected.text = "Select an owned unit."
		$UI/Left/Rows/Planning/Rows/CardPreview.text = ""
		return
	var definition: Dictionary = tournament.shop.definitions[int(selected.definition_index)]
	var cards: Array[String] = []
	for index in selected.cards: cards.append(str(definition.cards[index].name))
	var location: String = str(selected.get("location", "bench"))
	if selected.has("cell"): location += " (%d, %d)" % [selected.cell.x, selected.cell.y]
	$UI/Left/Rows/Planning/Rows/Selected.text = "#%d %s ★%d\n%s • %s\nCards: %s" % [selected_instance, definition.name, selected.star, definition.role, location, ", ".join(cards)]
	var card_lines: Array[String] = ["CARD COMMANDS • selected order: %s" % str(selected.cards)]
	for index in definition.cards.size():
		var card: Dictionary = definition.cards[index]
		card_lines.append("%d. %s: %s" % [index, card.name, " ".join(card.commands)])
	$UI/Left/Rows/Planning/Rows/CardPreview.text = "\n".join(card_lines)
	if screen == "PLAN" and selected.has("cell"):
		var commands: Array = []
		for card_index in selected.cards: commands.append_array(definition.cards[card_index].commands)
		var path: Array[Vector2i] = Simulation.new().preview_path(str(definition.role), selected.cell, commands)
		card_lines.append("PATH PREVIEW • %s" % " → ".join(path.map(func(cell: Vector2i) -> String: return "(%d,%d)" % [cell.x, cell.y])))
		$UI/Left/Rows/Planning/Rows/CardPreview.text = "\n".join(card_lines)

func _refresh_battle_state() -> void:
	if tournament.current_match == null:
		$UI/Right/Rows/Content/Arenas.text = "OFFENSE / DEFENSE\nTwo 4×8 arenas"
		return
	var game = tournament.current_match
	$UI/Right/Rows/Content/Arenas.text = "ARENA A • %s offense\nTick %03d • %s\n\nARENA B • %s offense\nTick %03d • %s" % [_participant_name(int(tournament.pairings[maxi(0, tournament.next_match - int(game.finalized))].a)), game.arena_a.tick, game.arena_a.result, _participant_name(int(tournament.pairings[maxi(0, tournament.next_match - int(game.finalized))].b)), game.arena_b.tick, game.arena_b.result]
	$UI/Left/Rows/Battle/Status.text = "Tick %03d\nA: %s\nB: %s" % [game.arena_a.tick, game.arena_a.result, game.arena_b.result]
	if screen == "BATTLE":
		var count: String = " • starts in %d" % ceili(battle_countdown) if battle_countdown > 0.0 else (" • running" if running else " • paused")
		$UI/Left/Rows/Battle/Status.text += count
		var focus: Dictionary = {}
		for arena in [game.arena_a, game.arena_b]:
			for unit in arena.units:
				if selected_instance > 0 and str(unit.id).ends_with("_%d" % selected_instance) and int(tournament.pairings[tournament.next_match].a if str(unit.id).begins_with("A_") else tournament.pairings[tournament.next_match].b) == 1:
					focus = unit
					break
			if not focus.is_empty(): break
		if focus.is_empty() and not game.arena_a.units.is_empty(): focus = game.arena_a.units[0]
		var focus_name: String = str(focus.get("definition_id", focus.get("id", "Unit")))
		for definition in tournament.shop.definitions:
			if definition.id == focus.get("definition_id", ""):
				focus_name = str(definition.name)
				break
		$UI/Left/Rows/Battle/Focus.text = "%s ★%d • (%d,%d)\nCommand %s • %d ticks left%s" % [focus_name, int(focus.get("star", 1)), focus.get("pos", Vector2i.ZERO).x, focus.get("pos", Vector2i.ZERO).y, str(focus.commands[focus.index]) if focus.has("commands") else "—", int(focus.get("remaining", 0)), " • %s active" % ("TAUNT" if focus.get("active_effect", "") == "T" else "SCARE") if focus.get("active_effect", "") != "" else ""]
		var recent: Array[String] = []
		for event in game.arena_a.events: recent.append("A: " + event)
		for event in game.arena_b.events: recent.append("B: " + event)
		$UI/Left/Rows/Battle/Events.text = "EVENTS\n" + ("\n".join(recent.slice(maxi(0, recent.size() - 3))) if not recent.is_empty() else "Waiting for commands")
	if not tournament.match_history.is_empty():
		var last: Dictionary = tournament.match_history.back()
		var player_reward: int = int(last.reward_a) if last.a == 1 else (int(last.reward_b) if last.b == 1 else 0)
		var next_income: String = "Survivors receive +%d base coins after standings." % int(tournament.shop.config.round_income) if int(last.stage) < 3 else "Championship complete after standings."
		$UI/Left/Rows/Results/Summary.text = "%s vs %s • %s\nPoints: P%d +%d, P%d +%d\nArena A: %s at tick %d\n%s\nArena B: %s at tick %d\n%s\nYour 2–0 bonus: +%d coins\n%s" % [_participant_name(int(last.a)), _participant_name(int(last.b)), last.result.score, last.a, last.result.points_a, last.b, last.result.points_b, last.result.arena_a.type, last.result.arena_a.tick, last.result.arena_a.reason, last.result.arena_b.type, last.result.arena_b.tick, last.result.arena_b.reason, player_reward, next_income]

func _refresh_standings() -> void:
	var ranked: Array[int] = []
	for id in tournament.standings: ranked.append(int(id))
	ranked.sort_custom(func(a: int, b: int) -> bool:
		if tournament.standings[a].points != tournament.standings[b].points: return tournament.standings[a].points > tournament.standings[b].points
		if tournament.standings[a].arena_wins != tournament.standings[b].arena_wins: return tournament.standings[a].arena_wins > tournament.standings[b].arena_wins
		return a < b)
	if tournament.champion > 0:
		ranked.erase(tournament.champion)
		ranked.push_front(tournament.champion)
	var lines: Array[String] = ["STANDINGS • POINTS / MATCHES"]
	for id in ranked: lines.append("%s   %d / %d%s" % [_participant_name(id), tournament.standings[id].points, tournament.standings[id].matches, " • champion" if id == tournament.champion else ("" if id in tournament.active else " • out")])
	$UI/Right/Rows/Content/Ranking.text = "\n".join(lines)
	$UI/Left/Rows/Standings/Summary.text = "\n".join(lines)
	$UI/Left/Rows/Champion/Summary.text = "Champion: %s\nFinal standings:\n%s\n%s" % [_participant_name(tournament.champion), "\n".join(lines.slice(1)), tournament.last_tiebreak] if tournament.champion > 0 else "Championship pending"

func _refresh_opponent() -> void:
	if tournament.bots.is_empty():
		$UI/Right/Rows/Content/Opponent.text = ""
		return
	var opponent_id: int = 0
	if tournament.phase == "MATCHES" and tournament.next_match < tournament.pairings.size():
		var pair: Dictionary = tournament.pairings[tournament.next_match]
		if pair.a == 1: opponent_id = int(pair.b)
	elif 1 in tournament.active:
		for id in tournament.active:
			if id != 1: opponent_id = id; break
	if opponent_id == 0:
		$UI/Right/Rows/Content/Opponent.text = "Bot matches continue."
		return
	var snapshot: Dictionary = tournament.get_bot_snapshot(opponent_id)
	var names: Array[String] = []
	for unit in snapshot.get("units", []):
		var character_name: String = str(unit.definition_id)
		for definition in tournament.shop.definitions:
			if definition.id == unit.definition_id:
				character_name = str(definition.name)
				break
		names.append("%s ★%d %s • %s" % [character_name, unit.star, unit.role, ", ".join(unit.card_ids)])
	$UI/Right/Rows/Content/Opponent.text = "NEXT OPPONENT • Bot P%d\n%s" % [opponent_id, "\n".join(names)]

func _refresh_history() -> void:
	var history: ItemList = $UI/Right/Rows/Content/History
	var selected: PackedInt32Array = history.get_selected_items()
	history.clear()
	for entry in tournament.match_history:
		history.add_item("Stage %d: P%d–P%d  %s" % [entry.stage + 1, entry.a, entry.b, entry.result.score])
	if not selected.is_empty() and selected[0] < history.item_count: history.select(selected[0])
	elif history.item_count > 0: history.select(history.item_count - 1)
	_select_history(history.get_selected_items()[0] if not history.get_selected_items().is_empty() else -1)

func _select_history(index: int) -> void:
	if index < 0 or index >= tournament.match_history.size():
		$UI/Right/Rows/Content/HistoryDetails.text = "Select a completed match to review it."
		return
	var entry: Dictionary = tournament.match_history[index]
	$UI/Right/Rows/Content/HistoryDetails.text = "P%d vs P%d: %s\nA: %s (%s)\nB: %s (%s)" % [entry.a, entry.b, entry.result.score, entry.result.arena_a.type, entry.result.arena_a.reason, entry.result.arena_b.type, entry.result.arena_b.reason]

func _participant_name(id: int) -> String:
	return "You (P1)" if id == 1 else "Bot P%d" % id

func _draw_units(delta: float = 0.0) -> void:
	var offense_units: Array = []
	var defense_units: Array = []
	if screen in ["SHOP", "PLAN"] and 1 in tournament.active:
		for item in tournament.shop.bench:
			if item.get("location", "bench") != "bench":
				var definition: Dictionary = tournament.shop.definitions[int(item.definition_index)]
				var visual: Dictionary = {"role": definition.role, "pos": item.cell, "team": "A", "active": true, "definition_id": definition.id, "star": item.star}
				if item.location == "offense": offense_units.append(visual)
				else: defense_units.append(visual)
	elif screen in ["BATTLE", "RESULTS", "STANDINGS", "CHAMPION"] and tournament.current_match != null:
		offense_units = tournament.current_match.arena_a.units
		defense_units = tournament.current_match.arena_b.units
	offense_view.display_units(offense_units, delta, screen in ["BATTLE", "RESULTS"])
	defense_view.display_units(defense_units, delta, screen in ["BATTLE", "RESULTS"])
	var selected: Dictionary = tournament.session.get_instance(selected_instance)
	var role: String = "" if selected.is_empty() else str(tournament.shop.definitions[int(selected.definition_index)].role)
	offense_view.show_anchors(role if screen == "PLAN" and 1 in tournament.active else "")
	defense_view.show_anchors(role if screen == "PLAN" and 1 in tournament.active else "")
	var preview: Array = []
	if screen == "PLAN" and selected.has("cell"):
		var definition: Dictionary = tournament.shop.definitions[int(selected.definition_index)]
		var commands: Array = []
		for card_index in selected.cards: commands.append_array(definition.cards[card_index].commands)
		preview = Simulation.new().preview_path(role, selected.cell, commands).slice(1)
	offense_view.show_preview(preview if selected.get("location", "") == "offense" else [])
	defense_view.show_preview(preview if selected.get("location", "") == "defense" else [])
