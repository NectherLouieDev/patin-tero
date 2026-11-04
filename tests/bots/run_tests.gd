extends SceneTree

const Tournament = preload("res://scripts/tournament/tournament_model.gd")
const Match = preload("res://scripts/match/match_controller.gd")
const Session = preload("res://scripts/core/shared_session.gd")
const BotScene = preload("res://scenes/debug/bot_test.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var card_session = Session.new()
	card_session.initialize(42, true)
	_check(card_session.set_cards(1, [2]) == "" and card_session.get_instance(1).cards == [2], "one-star card can be selected through validation")
	_check(card_session.set_cards(1, [3]) == "Invalid or duplicate card" and card_session.get_instance(1).cards == [2], "invalid card keeps prior choice")
	_check(card_session.set_cards(1, [1, 1]) == "Invalid card capacity" and card_session.get_instance(1).cards == [2], "over-capacity choice keeps prior card")
	var first = Tournament.new()
	var second = Tournament.new()
	_check(first.initialize(42) == "" and second.initialize(42) == "", "same-seed tournaments initialize")
	_check(first.bots.size() == 7 and first.active.size() == 8, "seven bots fill the tournament")
	_check(first.lock_planning() == "" and second.lock_planning() == "", "bot plans lock through shared sessions")
	for id in range(2, 9):
		var record: Array[Dictionary] = first.get_bot_decisions(id)
		var snapshot: Dictionary = first.get_bot_snapshot(id)
		_check(record.size() == 1 and snapshot.locked, "Bot P%d has one recorded locked plan" % id)
		_check(record == second.get_bot_decisions(id), "Bot P%d repeats all decisions" % id)
		_check(first.bots[id].prepare_stage(0) == "" and first.get_bot_decisions(id).size() == 1, "Bot P%d stage preparation is idempotent" % id)
		_check(record[0].purchases.size() == 1 and first.bots[id].session.shop.coins == 17, "Bot P%d purchase uses shop cost" % id)
		_check(first.bots[id].session.set_cards(1, [0]) == "Formation is locked", "Bot P%d cannot edit cards after lock" % id)
		_check(_valid_snapshot(first.bots[id], snapshot), "Bot P%d cards and anchors are valid" % id)
		var match = Match.new()
		_check(match.initialize(first.bots[id].get_match_snapshot(), first.bots[2].get_match_snapshot(), 42) == "", "Bot P%d snapshot initializes normal match" % id)
	_check(first.begin_next_match() == "", "player-versus-bot match begins")
	var replay: Dictionary = first.current_match.replay_record()
	_check(replay.snapshot_b.units == first.bots[2].get_match_snapshot().units, "player pairing uses Bot P2 snapshot")
	for tick in 1000:
		if first.current_match.finalized: break
		first.step_current_match()
	_check(first.match_history.size() == 1, "player-versus-bot result recorded")
	_check(second.play_next_match().begins_with("P") and first.match_history[0].result == second.match_history[0].result, "stepped and direct playback agree")
	_check(first.begin_next_match() == "", "bot-versus-bot match begins")
	replay = first.current_match.replay_record()
	_check(replay.snapshot_a.units == first.bots[3].get_match_snapshot().units and replay.snapshot_b.units == first.bots[4].get_match_snapshot().units, "P3 versus P4 uses distinct bot snapshots")
	for tick in 1000:
		if first.current_match.finalized: break
		first.step_current_match()
	second.play_next_match()
	_check(first.match_history[1].result == second.match_history[1].result, "bot-versus-bot outcome repeats")
	_finish(first)
	_finish(second)
	_check(first.champion > 0 and first.champion == second.champion, "identical seeds yield the same champion")
	_check(first.match_history.map(func(entry: Dictionary) -> Dictionary: return entry.result) == second.match_history.map(func(entry: Dictionary) -> Dictionary: return entry.result), "every match result repeats")
	for id in range(2, 9): _check(first.get_bot_decisions(id) == second.get_bot_decisions(id), "Bot P%d stage history repeats" % id)
	var other = Tournament.new()
	other.initialize(43)
	other.lock_planning()
	var changed: bool = false
	for id in range(2, 9):
		if first.get_bot_decisions(id)[0] != other.get_bot_decisions(id)[0]: changed = true
	_check(changed, "different seed changes recorded decisions")
	var scene = BotScene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.get_node("Margin/Columns/Left/Generate").emit_signal("pressed")
	_check(scene.get_node("Margin/Columns/Right/Decisions").text.contains("decision seed"), "authored bot scene displays decisions")
	scene.queue_free()
	if failures.is_empty():
		print("PASS: deterministic bot opponents")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _valid_snapshot(bot, snapshot: Dictionary) -> bool:
	var offense: int = 0
	var defense: int = 0
	for unit in snapshot.units:
		var definition: Dictionary = {}
		for entry in bot.session.shop.definitions:
			if entry.id == unit.definition_id: definition = entry; break
		if definition.is_empty() or unit.role != definition.role: return false
		if unit.card_ids.is_empty() or unit.card_ids.size() > unit.star: return false
		var expected: Array[String] = []
		for card_id in unit.card_ids:
			var found: bool = false
			for card in definition.cards:
				if card.id == card_id:
					for command in card.commands: expected.append(command)
					found = true
					break
			if not found: return false
		if expected != unit.commands: return false
		if unit.role == "runner":
			if unit.arena != "offense" or unit.cell.y != 0 or unit.cell.x < 0 or unit.cell.x > 3: return false
			offense += 1
		elif unit.role == "horizontal":
			if unit.arena != "defense" or unit.cell.y not in [2, 4, 6] or unit.cell.x < 0 or unit.cell.x > 3: return false
			defense += 1
		else:
			if unit.arena != "defense" or unit.cell != Vector2i(-1, 3): return false
			defense += 1
	return offense > 0 and defense > 0

func _finish(game) -> void:
	while game.phase != "COMPLETE":
		while game.phase == "MATCHES":
			var result: String = game.play_next_match()
			if not result.begins_with("P"):
				failures.append("Tournament match failed: " + result)
				return
		if game.phase == "STANDINGS": game.advance_stage()
		if game.phase == "PLANNING":
			var error: String = game.lock_planning()
			if error != "": failures.append("Bot stage failed: " + error); return

func _check(condition: bool, description: String) -> void:
	if not condition: failures.append(description)
