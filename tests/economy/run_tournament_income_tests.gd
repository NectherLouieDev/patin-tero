extends SceneTree

const Tournament = preload("res://scripts/tournament/tournament_model.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var game = Tournament.new()
	_check(game.initialize(1) == "", "seeded tournament starts")
	_check(game.lock_planning() == "", "opening formation locks")
	var scores: Dictionary = {}
	while game.phase == "MATCHES":
		var pair: Dictionary = game.pairings[game.next_match]
		var before_a: int = _coins(game, int(pair.a))
		var before_b: int = _coins(game, int(pair.b))
		game.play_next_match()
		var entry: Dictionary = game.match_history.back()
		var bonus_a: int = int(game.shop.config.bonus_2_0) if int(entry.result.points_a) == 2 else 0
		var bonus_b: int = int(game.shop.config.bonus_2_0) if int(entry.result.points_b) == 2 else 0
		_check(int(entry.reward_a) == bonus_a and int(entry.reward_b) == bonus_b and _coins(game, int(pair.a)) == before_a + bonus_a and _coins(game, int(pair.b)) == before_b + bonus_b, "only a 2–0 participant receives the match bonus")
		scores[entry.result.score] = true
	_check(scores.has("2-0") and scores.has("1-1") and scores.has("0-2"), "seed one exercises all match score cases")
	var before_round: Dictionary = {}
	for id in game.active: before_round[id] = _coins(game, id)
	_check(game.advance_stage().begins_with("Advanced"), "standings advance to the next round")
	for id in before_round:
		if id in game.active:
			var purchases: int = 0
			if id != 1:
				for purchase in game.bots[id].decision_history.back().purchases: purchases += int(purchase.cost)
			_check(_coins(game, id) == int(before_round[id]) + int(game.shop.config.round_income) - purchases, "survivor receives base income before planning purchases")
		else:
			_check(_coins(game, id) == int(before_round[id]), "eliminated player receives no next-round income")
	if failures.is_empty():
		print("PASS: Section 5 tournament income")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _coins(game, id: int) -> int:
	return game.shop.coins if id == 1 else game.bots[id].session.shop.coins

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
