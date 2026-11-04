extends Control

const Tournament = preload("res://scripts/tournament/tournament_model.gd")

var tournament = Tournament.new()

@onready var seed_input: SpinBox = $Margin/Columns/Left/Seed
@onready var bot_choice: OptionButton = $Margin/Columns/Left/Bot
@onready var roster_label: Label = $Margin/Columns/Left/Roster
@onready var decisions_label: Label = $Margin/Columns/Right/Decisions
@onready var matches_label: Label = $Margin/Columns/Right/Matches
@onready var status_label: Label = $Margin/Columns/Right/Status

func _ready() -> void:
	for id in range(2, 9): bot_choice.add_item("Bot P%d" % id, id)
	bot_choice.item_selected.connect(func(_index: int) -> void: _refresh())
	$Margin/Columns/Left/Start.pressed.connect(_start)
	$Margin/Columns/Left/Generate.pressed.connect(_generate)
	$Margin/Columns/Right/PlayerMatch.pressed.connect(_player_match)
	$Margin/Columns/Right/BotMatch.pressed.connect(_bot_match)
	$Margin/Columns/Right/Complete.pressed.connect(_complete_stage)
	_start()

func _start() -> void:
	var result: String = tournament.initialize(int(seed_input.value))
	status_label.text = "Eight participants ready. Generate bot plans." if result == "" else result
	_refresh()

func _generate() -> void:
	var result: String = tournament.lock_planning()
	status_label.text = "Seven bot formations locked." if result == "" else result
	_refresh()

func _player_match() -> void:
	if tournament.phase != "MATCHES" or tournament.next_match != 0:
		status_label.text = "Generate formations, then run the first pairing."
		return
	status_label.text = tournament.play_next_match()
	_refresh()

func _bot_match() -> void:
	if tournament.phase != "MATCHES" or tournament.next_match != 1:
		status_label.text = "Run the player match first; P3 vs P4 is next."
		return
	status_label.text = tournament.play_next_match()
	_refresh()

func _complete_stage() -> void:
	if tournament.phase != "MATCHES":
		status_label.text = "Generate bot plans first."
		return
	while tournament.phase == "MATCHES":
		var result: String = tournament.play_next_match()
		if not result.begins_with("P"):
			status_label.text = result
			_refresh()
			return
	status_label.text = "Stage matches complete. Review results and standings."
	_refresh()

func _refresh() -> void:
	if tournament.bots.is_empty(): return
	var id: int = bot_choice.get_selected_id()
	if id < 2: id = 2
	var bot = tournament.bots[id]
	var roster_lines: Array[String] = ["BOT P%d • seed %d" % [id, bot.session.shop.seed_value], "Coins: %d" % bot.session.shop.coins, "ROSTER"]
	for item in bot.session.shop.bench:
		var definition: Dictionary = bot.session.shop.definitions[int(item.definition_index)]
		roster_lines.append("#%d %s ★%d • %s" % [item.instance_id, definition.name, item.star, item.get("location", "bench")])
	roster_label.text = "\n".join(roster_lines)
	var history: Array[Dictionary] = tournament.get_bot_decisions(id)
	var detail: Array[String] = ["BOT DECISIONS"]
	for record in history:
		detail.append("Stage %d • decision seed %d" % [record.stage + 1, record.seed])
		for purchase in record.purchases: detail.append("Bought %s from slot %d for %d" % [purchase.definition_id, purchase.slot + 1, purchase.cost])
		for card in record.cards: detail.append("#%d cards: %s" % [card.instance_id, ", ".join(card.card_ids)])
		for placement in record.placements: detail.append("#%d %s (%d, %d)" % [placement.instance_id, placement.arena, placement.cell.x, placement.cell.y])
	decisions_label.text = "\n".join(detail)
	var match_lines: Array[String] = ["MATCH RESULTS"]
	for entry in tournament.match_history:
		match_lines.append("P%d vs P%d • %s • A:%s B:%s" % [entry.a, entry.b, entry.result.score, entry.result.arena_a.type, entry.result.arena_b.type])
	matches_label.text = "\n".join(match_lines)
