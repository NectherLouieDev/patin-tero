extends SceneTree

const Tournament = preload("res://scripts/tournament/tournament_model.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var recovery_cases: int = 0
	for seed in range(1, 21):
		var game = Tournament.new()
		_check(game.initialize(seed) == "", "tournament initializes")
		while game.phase != "COMPLETE":
			_check(game.lock_planning() == "", "formation locks with available roles")
			while game.phase == "MATCHES":
				_check(game.play_next_match().begins_with("P"), "match resolves")
			var lost_both: Dictionary = {}
			for entry in game.match_history:
				if int(entry.stage) != game.stage_index: continue
				if entry.result.score == "2-0": lost_both[int(entry.b)] = true
				if entry.result.score == "0-2": lost_both[int(entry.a)] = true
			_check(game.advance_stage().length() > 0, "stage advances")
			for id in game.active:
				var balance: int = game.shop.coins if id == 1 else game.bots[id].session.shop.coins
				_check(balance >= 0, "survivor coin balance remains nonnegative")
				if game.phase == "PLANNING" and game.active.size() > 2 and lost_both.has(id):
					recovery_cases += 1
					_check(balance >= 3, "survivor of a 0–2 loss can still afford a test-price unit")
		_check(game.champion > 0, "tournament declares one champion")
	_check(recovery_cases > 0, "survey encountered early losses followed by survival")
	if failures.is_empty():
		print("PASS: Section 5 economy smoke survey across 20 seeds; recovery cases: %d" % recovery_cases)
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
