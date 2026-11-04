extends SceneTree

const Tournament = preload("res://scripts/tournament/tournament_model.gd")
const Match = preload("res://scripts/match/match_controller.gd")
var failures := 0

func _initialize() -> void:
	var game = Tournament.new()
	check("fresh eight-player setup", game.initialize(42) == "" and game.active.size() == 8 and game.phase == "PLANNING")
	var first_offer: int = game.shop.offers[0]
	check("shop purchase joins tournament bench", game.buy(0).begins_with("Purchased") and game.shop.bench.size() == 3 and game.shop.bench[2].definition_index == first_offer)
	check("cannot advance before matches", game.advance_stage() == "Complete every match before advancing")
	check("starter plan locks", game.lock_planning() == "" and game.pairings.size() == 4)
	check("locked plan includes purchased distinct unit", game.player_snapshot.units.size() >= 2 and (game.player_snapshot.units.size() == 3 if first_offer not in [0, 4] else game.player_snapshot.units.size() == 2))
	check("cannot advance with pending matches", game.advance_stage() == "Complete every match before advancing")
	var expected: Array[int] = [6, 4, 2, 1]
	for target in expected:
		while game.phase == "MATCHES":
			check("match result recorded", game.play_next_match().begins_with("P"))
		check("stage results complete", game.phase == "STANDINGS" and game.next_match == game.pairings.size())
		var count_before: int = game.match_history.size()
		check("no duplicate match points", game.play_next_match() == "No match is ready" and game.match_history.size() == count_before)
		check("advances to %d" % target, game.advance_stage().length() > 0 and game.active.size() == target)
		if target < 1: break
		if game.phase == "PLANNING":
			if target == 2:
				check("championship shop closed", game.buy(0) == "Shop unavailable in this phase" and game.reroll() == "Shop unavailable in this phase")
			check("next stage locks", game.lock_planning() == "")
	check("one champion", game.phase == "COMPLETE" and game.champion == game.active[0] and game.champion > 0)
	check("stage counts", game.elimination_history.map(func(entry: Dictionary) -> int: return entry.to) == expected)
	var prior: Dictionary = game.match_history[0].replay
	var replay = Match.new()
	check("stored match replay", replay.initialize(prior.snapshot_a, prior.snapshot_b, prior.seed) == "" and replay.run_to_completion() == prior.expected_result)
	game.initialize(42)
	game.tie_fixture = true
	game.lock_planning()
	while game.phase == "MATCHES": game.play_next_match()
	check("tie fixture yields tied points", game.standings[1].points == 1 and game.standings[2].points == 1)
	game.advance_stage()
	check("documented tie breaker", game.last_tiebreak.contains("lower participant ID") and game.active == [1, 2, 3, 4, 5, 6])
	game.initialize(99)
	check("new tournament clears old state", game.phase == "PLANNING" and game.active.size() == 8 and game.match_history.is_empty() and game.elimination_history.is_empty() and game.champion == 0 and game.shop.bench.size() == 2)
	check("new tournament resets economy and upgrades", game.shop.coins == int(game.shop.config.starting_coins) and game.shop.offers.size() == 5 and game.shop.bench.all(func(unit: Dictionary) -> bool: return int(unit.star) == 1) and game.shop.next_instance_id == 3)
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1
