extends Control

const Tournament = preload("res://scripts/tournament/tournament_model.gd")

@onready var seed_input: SpinBox = $Margin/Columns/Left/Seed
@onready var tie_toggle: CheckBox = $Margin/Columns/Left/TieFixture
@onready var guard_choice: OptionButton = $Margin/Columns/Left/GuardColumn
@onready var offers: ItemList = $Margin/Columns/Left/Offers
@onready var bench: ItemList = $Margin/Columns/Left/Bench
@onready var stage_label: Label = $Margin/Columns/Right/Stage
@onready var standing_label: Label = $Margin/Columns/Right/Standings
@onready var pairing_label: Label = $Margin/Columns/Right/Pairings
@onready var history_label: Label = $Margin/Columns/Right/History
@onready var champion_label: Label = $Margin/Columns/Right/Champion
@onready var feedback: Label = $Margin/Columns/Right/Feedback

var tournament = Tournament.new()

func _ready() -> void:
	guard_choice.add_item("Guard column 0: blocks test runner")
	guard_choice.add_item("Guard column 3: avoids test runner")
	$Margin/Columns/Left/Actions/Buy.pressed.connect(_buy)
	$Margin/Columns/Left/Actions/Reroll.pressed.connect(func() -> void: _show(tournament.reroll()))
	$Margin/Columns/Left/New.pressed.connect(_new_tournament)
	$Margin/Columns/Right/Actions/Lock.pressed.connect(_lock)
	$Margin/Columns/Right/Actions/Play.pressed.connect(func() -> void: _show(tournament.play_next_match()))
	$Margin/Columns/Right/Actions/Advance.pressed.connect(func() -> void: _show(tournament.advance_stage()))
	_new_tournament()

func _new_tournament() -> void:
	var error: String = tournament.initialize(int(seed_input.value))
	feedback.text = "New tournament started" if error == "" else error
	_refresh()

func _buy() -> void:
	var picked: PackedInt32Array = offers.get_selected_items()
	_show(tournament.buy(picked[0] if not picked.is_empty() else -1))

func _lock() -> void:
	tournament.tie_fixture = tie_toggle.button_pressed
	tournament.guard_column = 0 if guard_choice.selected == 0 else 3
	var error: String = tournament.lock_planning()
	_show("Planning locked" if error == "" else error)

func _show(message: String) -> void:
	feedback.text = message
	_refresh()

func _refresh() -> void:
	if tournament.shop.definitions.is_empty(): return
	stage_label.text = "Stage %d | %d active | Phase: %s | Seed: %d | Coins: %d\nPROVISIONAL pairing, elimination, and tie rules" % [tournament.stage_index + 1, tournament.active.size(), tournament.phase, tournament.seed_value, tournament.shop.coins]
	if not tournament.player_snapshot.is_empty():
		var locked_ids: Array[String] = []
		for unit in tournament.player_snapshot.units:
			locked_ids.append("#%d" % unit.instance_id)
		stage_label.text += "\nPlayer locked IDs: " + ", ".join(locked_ids)
	offers.clear()
	for index in tournament.shop.offers.size():
		var definition_index: int = tournament.shop.offers[index]
		offers.add_item("%d. %s" % [index + 1, "SOLD" if definition_index < 0 else "%s — %d coins" % [tournament.shop.definitions[definition_index].name, int(tournament.shop.config.prices[definition_index])]])
	bench.clear()
	for item in tournament.shop.bench:
		bench.add_item("#%d %s | %d star" % [item.instance_id, tournament.shop.definitions[item.definition_index].name, item.star])
	var ranked: Array[int] = tournament.active.duplicate()
	ranked.sort_custom(func(a: int, b: int) -> bool:
		if tournament.standings[a].points != tournament.standings[b].points: return tournament.standings[a].points > tournament.standings[b].points
		return a < b)
	var lines: Array[String] = ["STANDINGS (points / matches)"]
	for id in ranked:
		lines.append("P%d — %d / %d" % [id, tournament.standings[id].points, tournament.standings[id].matches])
	standing_label.text = "\n".join(lines)
	var scheduled: Array[String] = ["PAIRINGS"]
	for index in tournament.pairings.size():
		var pairing: Dictionary = tournament.pairings[index]
		scheduled.append("%s P%d vs P%d" % ["DONE" if index < tournament.next_match else "NEXT", pairing.a, pairing.b])
	pairing_label.text = "\n".join(scheduled)
	var recent: Array[String] = ["MATCH RESULTS"]
	for index in range(maxi(0, tournament.match_history.size() - 5), tournament.match_history.size()):
		var entry: Dictionary = tournament.match_history[index]
		recent.append("Stage %d: P%d vs P%d = %s | arenas %s @%d / %s @%d" % [entry.stage + 1, entry.a, entry.b, entry.result.score, entry.result.arena_a.type, entry.result.arena_a.tick, entry.result.arena_b.type, entry.result.arena_b.tick])
	history_label.text = "\n".join(recent)
	champion_label.text = "CHAMPION: P%d" % tournament.champion if tournament.champion > 0 else "Championship pending"
	if tournament.last_tiebreak != "":
		champion_label.text += "\nTiebreak: " + tournament.last_tiebreak
	$Margin/Columns/Left/Actions/Buy.disabled = tournament.phase != "PLANNING" or 1 not in tournament.active or tournament.active.size() == 2
	$Margin/Columns/Left/Actions/Reroll.disabled = $Margin/Columns/Left/Actions/Buy.disabled
	$Margin/Columns/Right/Actions/Lock.disabled = tournament.phase != "PLANNING"
	$Margin/Columns/Right/Actions/Play.disabled = tournament.phase != "MATCHES"
	$Margin/Columns/Right/Actions/Advance.disabled = tournament.phase != "STANDINGS"
