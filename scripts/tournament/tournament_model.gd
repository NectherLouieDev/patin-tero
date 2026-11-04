class_name TournamentModel
extends RefCounted

const Session = preload("res://scripts/core/shared_session.gd")
const Match = preload("res://scripts/match/match_controller.gd")
const Bot = preload("res://scripts/bots/bot_participant.gd")
const MatchPolicy = preload("res://scripts/match/provisional_match_policy.gd")
const TARGETS: Array[int] = [8, 6, 4, 2, 1]

var session = Session.new()
var shop = session.shop
var bots: Dictionary = {}
var active: Array[int] = []
var standings: Dictionary = {}
var stage_index: int = 0
var phase: String = "SETUP"
var pairings: Array[Dictionary] = []
var next_match: int = 0
var match_history: Array[Dictionary] = []
var elimination_history: Array[Dictionary] = []
var champion: int = 0
var seed_value: int = 42
var tie_fixture: bool = false
var guard_column: int = 0
var player_snapshot: Dictionary = {}
var last_tiebreak: String = ""
var current_match = null

func initialize(seed: int = 42) -> String:
	var error: String = session.initialize(seed, true)
	if error != "": return error
	seed_value = seed
	active.clear()
	standings.clear()
	bots.clear()
	for id in 8:
		active.append(id + 1)
		standings[id + 1] = {"points": 0, "arena_wins": 0, "matches": 0}
		if id + 1 > 1:
			var bot = Bot.new()
			error = bot.initialize(seed, id + 1)
			if error != "": return error
			bots[id + 1] = bot
	for id in range(2, 9):
		error = bots[id].prepare_stage(0, true)
		if error != "": return "Bot P%d: %s" % [id, error]
	stage_index = 0
	phase = "PLANNING"
	pairings.clear()
	next_match = 0
	match_history.clear()
	elimination_history.clear()
	champion = 0
	tie_fixture = false
	guard_column = 0
	player_snapshot.clear()
	last_tiebreak = ""
	current_match = null
	shop.planning_open = true
	return ""

func buy(slot: int) -> String:
	if phase != "PLANNING" or 1 not in active or active.size() == 2:
		return "Shop unavailable in this phase"
	return session.buy(slot)

func reroll() -> String:
	if phase != "PLANNING" or 1 not in active or active.size() == 2:
		return "Shop unavailable in this phase"
	return session.reroll()

func lock_planning() -> String:
	if phase != "PLANNING":
		return "Planning is not open"
	if 1 in active:
		var error: String = session.auto_deploy_first_roles(guard_column)
		if error != "": return error
		error = session.lock()
		if error != "": return error
		player_snapshot = session.get_snapshot()
	for id in active:
		if id == 1: continue
		var bot_error: String = bots[id].prepare_stage(stage_index, active.size() != 2)
		if bot_error != "": return "Bot P%d: %s" % [id, bot_error]
	pairings = _make_pairings()
	next_match = 0
	current_match = null
	phase = "MATCHES"
	shop.planning_open = false
	return ""

func play_next_match() -> String:
	var error: String = begin_next_match()
	if error != "": return error
	var outcome: Dictionary = current_match.run_to_completion()
	if outcome.is_empty(): return "Match did not finish within 1000 ticks"
	return _commit_current_match()

func begin_next_match() -> String:
	if phase != "MATCHES" or next_match >= pairings.size():
		return "No match is ready"
	if current_match != null and not current_match.finalized:
		return "Current match is still running"
	var pairing: Dictionary = pairings[next_match]
	var snapshot_a: Dictionary = _snapshot_for(int(pairing.a))
	var snapshot_b: Dictionary = _snapshot_for(int(pairing.b))
	# Isolated debug tie mode mirrors one valid bot formation on both sides.
	if tie_fixture:
		snapshot_a = bots[pairing.b].get_match_snapshot()
		snapshot_b = snapshot_a.duplicate(true)
	current_match = Match.new()
	var match_seed: int = seed_value + stage_index * 100 + next_match
	var error: String = current_match.initialize(snapshot_a, snapshot_b, match_seed)
	if error != "":
		current_match = null
		return error
	return ""

func step_current_match() -> String:
	if current_match == null or current_match.finalized:
		return "No running match"
	current_match.step()
	if current_match.finalized:
		return _commit_current_match()
	return ""

func _commit_current_match() -> String:
	var pairing: Dictionary = pairings[next_match]
	var outcome: Dictionary = current_match.result
	standings[pairing.a].points += outcome.points_a
	standings[pairing.a].arena_wins += outcome.points_a
	standings[pairing.a].matches += 1
	standings[pairing.b].points += outcome.points_b
	standings[pairing.b].arena_wins += outcome.points_b
	standings[pairing.b].matches += 1
	var reward_a: int = int(shop.config.bonus_2_0) if int(outcome.points_a) == 2 else 0
	var reward_b: int = int(shop.config.bonus_2_0) if int(outcome.points_b) == 2 else 0
	_award_participant(int(pairing.a), reward_a)
	_award_participant(int(pairing.b), reward_b)
	match_history.append({"stage": stage_index, "a": pairing.a, "b": pairing.b, "result": outcome.duplicate(true), "reward_a": reward_a, "reward_b": reward_b, "replay": current_match.replay_record(), "policy": MatchPolicy.POLICY_ID})
	next_match += 1
	if next_match == pairings.size(): phase = "STANDINGS"
	return "P%d vs P%d: %s" % [pairing.a, pairing.b, outcome.score]

func advance_stage() -> String:
	if phase != "STANDINGS":
		return "Complete every match before advancing"
	var ranked: Array[int] = active.duplicate()
	ranked.sort_custom(func(a: int, b: int) -> bool:
		if standings[a].points != standings[b].points: return standings[a].points > standings[b].points
		if standings[a].arena_wins != standings[b].arena_wins: return standings[a].arena_wins > standings[b].arena_wins
		return a < b)
	last_tiebreak = "Points, then arena wins, then lower participant ID"
	var target: int = TARGETS[stage_index + 1]
	var eliminated: Array[int] = []
	if target == 1:
		var final_match: Dictionary = match_history.back()
		var winner: int = ranked[0]
		if final_match.result.points_a != final_match.result.points_b:
			winner = int(final_match.a) if final_match.result.points_a > final_match.result.points_b else int(final_match.b)
			last_tiebreak = "Championship match score decides the winner"
		else:
			last_tiebreak = "Championship tied: cumulative points, arena wins, then lower participant ID"
		for id in active:
			if id != winner: eliminated.append(id)
		active = [winner]
	else:
		for index in range(target, ranked.size()): eliminated.append(ranked[index])
		active.clear()
		for index in target: active.append(ranked[index])
	elimination_history.append({"from": TARGETS[stage_index], "to": target, "eliminated": eliminated})
	stage_index += 1
	if target == 1:
		champion = active[0]
		phase = "COMPLETE"
		shop.planning_open = false
		return "Champion: P%d" % champion
	phase = "PLANNING"
	current_match = null
	var shop_enabled: bool = target != 2
	var income: int = int(shop.config.round_income)
	if 1 in active:
		var player_error: String = session.begin_next_round(shop_enabled, income)
		if player_error != "": return player_error
	else: shop.planning_open = false
	for id in active:
		if id == 1: continue
		var bot_error: String = bots[id].session.begin_next_round(shop_enabled, income)
		if bot_error != "": return bot_error
		bot_error = bots[id].prepare_stage(stage_index, shop_enabled)
		if bot_error != "": return bot_error
	player_snapshot.clear()
	return "Advanced to %d participants" % target

func _make_pairings() -> Array[Dictionary]:
	var scheduled: Array[Dictionary] = []
	var ordered: Array[int] = active.duplicate()
	ordered.sort()
	for index in range(0, ordered.size(), 2):
		scheduled.append({"a": ordered[index], "b": ordered[index + 1]})
	return scheduled

func get_bot_snapshot(id: int) -> Dictionary:
	return bots[id].get_snapshot() if bots.has(id) else {}

func get_bot_decisions(id: int) -> Array[Dictionary]:
	return bots[id].get_decisions() if bots.has(id) else []

func _snapshot_for(id: int) -> Dictionary:
	return MatchPolicy.battle_snapshot(player_snapshot) if id == 1 else bots[id].get_match_snapshot()

func _award_participant(id: int, amount: int) -> void:
	if id == 1: shop.award_coins(amount)
	else: bots[id].session.shop.award_coins(amount)
