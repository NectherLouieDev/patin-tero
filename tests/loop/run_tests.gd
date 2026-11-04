extends SceneTree

const Simulation = preload("res://scripts/simulation/arena_simulation.gd")
const Session = preload("res://scripts/core/shared_session.gd")
const Tournament = preload("res://scripts/tournament/tournament_model.gd")
const Moveset = preload("res://scripts/roster/moveset_model.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner = {"id": "runner", "role": "runner", "pos": Vector2i(1, 0), "commands": ["F"]}
	var guard = {"id": "guard", "role": "horizontal", "pos": Vector2i(3, 4), "patrol_row": 4, "commands": ["S"]}
	var arena = Simulation.new()
	arena.initialize([runner, guard], 50, 200)
	_check(arena.run_until_finished() == "RUNNER_WIN" and arena.tick == 140 and arena.result_reason.contains("round trip"), "selected forward command turns around and completes a trip")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(1, 0), "commands": ["S"]}, guard], 50, 30)
	_check(arena.run_until_finished() == "GUARD_WIN" and arena.tick == 30 and arena.result_reason.contains("Time limit"), "arena time limit resolves stalled runners")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(0, 0), "commands": ["F"]}, guard, {"id": "second_guard", "role": "horizontal", "pos": Vector2i(0, 1), "patrol_row": 1, "commands": ["S"]}], 50, 30)
	for tick in 10: arena.step()
	_check(arena.result == "GUARD_WIN" and arena.result_reason.contains("second_guard"), "all guards are checked for tags")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(0, 2), "commands": ["R"]}, {"id": "guard", "role": "horizontal", "pos": Vector2i(1, 2), "patrol_row": 2, "commands": ["L"]}], 50, 30)
	for tick in 10: arena.step()
	_check(arena.result == "GUARD_WIN" and arena.result_reason.contains("tagged"), "opposing units crossing cells tag deterministically")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(1, 7), "commands": ["S", "L", "R", "DL", "DR"]}, {"id": "guard", "role": "horizontal", "pos": Vector2i(3, 2), "patrol_row": 2, "commands": ["S"]}], 50, 100)
	for tick in 50: arena.step()
	_check(arena.units[1].pos == Vector2i(1, 5) and arena.units[1].reached_end, "runner left, right, and diagonals follow reversed facing")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(1, 3), "commands": ["S"]}, {"id": "center", "role": "center", "pos": Vector2i(-1, 3), "commands": ["S"]}], 50, 30)
	for tick in 10: arena.step()
	_check(arena.result == "RUNNING" and arena.units[1].active, "center guard does not tag without a center-line crossing")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(1, 3), "commands": ["R"]}, {"id": "center", "role": "center", "pos": Vector2i(-1, 3), "commands": ["S"]}], 50, 30)
	for tick in 10: arena.step()
	_check(arena.result == "GUARD_WIN" and arena.result_reason.contains("tagged by center"), "center-line path crossing tags at the same time and position")
	var moveset = Moveset.new()
	moveset.load_definitions()
	var invalid_horizontal: Dictionary = moveset.definitions[4].duplicate(true)
	invalid_horizontal.cards[0].commands[0] = "U"
	var invalid_center: Dictionary = moveset.definitions[7].duplicate(true)
	invalid_center.cards[0].commands[0] = "L"
	_check(moveset.validate_definition(invalid_horizontal).begins_with("Invalid") and moveset.validate_definition(invalid_center).begins_with("Invalid"), "guard cards reject commands outside their patrol axis")
	arena.initialize([{"id": "runner", "role": "runner", "pos": Vector2i(0, 0), "commands": ["T", "S"]}, {"id": "guard", "role": "horizontal", "pos": Vector2i(3, 4), "patrol_row": 4, "commands": ["C", "S"]}], 50, 100)
	_check(arena.units[1].active_effect == "T" and arena.units[0].active_effect == "C", "TAUNT and SCARE begin visibly on their first command")
	for tick in 14: arena.step()
	_check(arena.units[1].active_effect == "T" and arena.units[0].active_effect == "C", "special commands last 750 milliseconds")
	arena.step()
	_check(arena.units[1].active_effect == "" and arena.units[0].active_effect == "" and "runner: TAUNT ended" in arena.events and "guard: SCARE ended" in arena.events, "special command expiration is deterministic and reported")
	var preview: Array[Vector2i] = arena.preview_path("runner", Vector2i(1, 6), ["F", "L", "DL"], 3)
	_check(preview == [Vector2i(1, 6), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 6)], "planning preview follows runner turnaround and facing")
	var economy = Session.new()
	var economy_repeat = Session.new()
	economy.initialize(42, true)
	economy_repeat.initialize(42, true)
	economy.buy(0)
	economy_repeat.buy(0)
	var previous_coins: int = economy.shop.coins
	economy.begin_next_round(true, 5)
	economy_repeat.begin_next_round(true, 5)
	_check(economy.shop.coins == previous_coins + 5 and economy.shop.offers.size() == 5 and not -1 in economy.shop.offers, "new round grants income and five unsold offers")
	_check(economy.shop.offers == economy_repeat.shop.offers, "new-round offer refresh repeats from seed")
	economy.begin_next_round(false, 5)
	_check(economy.buy(0) == "Shop is closed", "championship shop remains closed")
	var normal = Tournament.new()
	var alternate = Tournament.new()
	normal.initialize(42)
	alternate.initialize(42)
	alternate.session.set_cards(1, [2])
	normal.lock_planning()
	alternate.lock_planning()
	normal.begin_next_match()
	alternate.begin_next_match()
	var first_commands: Array = normal.current_match.replay_record().snapshot_a.units[0].commands
	var alternate_commands: Array = alternate.current_match.replay_record().snapshot_a.units[0].commands
	_check(first_commands != alternate_commands, "tournament battle keeps chosen card commands")
	for tick in 20:
		normal.current_match.step()
		alternate.current_match.step()
	var first_position: Vector2i = normal.current_match.arena_a.units[0].pos
	var alternate_position: Vector2i = alternate.current_match.arena_a.units[0].pos
	_check(first_position != alternate_position, "different selected cards change battle movement")
	var tournament = Tournament.new()
	tournament.initialize(42)
	tournament.buy(0)
	tournament.tie_fixture = true
	tournament.lock_planning()
	var coins_before: int = tournament.shop.coins
	var bot_coins_before: int = tournament.bots[2].session.shop.coins
	tournament.play_next_match()
	var first_result: Dictionary = tournament.match_history[0]
	_check(first_result.result.score == "1-1" and first_result.reward_a == 0 and first_result.reward_b == 0 and tournament.shop.coins == coins_before, "tied match gives no 2–0 coin bonus")
	_check(tournament.bots[2].session.shop.coins == bot_coins_before, "bots follow the same 2–0 bonus rule")
	while tournament.phase == "MATCHES": tournament.play_next_match()
	var after_matches: int = tournament.shop.coins
	tournament.advance_stage()
	_check(tournament.phase == "PLANNING" and tournament.shop.coins == after_matches + 5 and not -1 in tournament.shop.offers, "survivor receives income and fresh offers")
	var final_game = Tournament.new()
	final_game.initialize(42)
	while final_game.active.size() > 2:
		final_game.lock_planning()
		while final_game.phase == "MATCHES": final_game.play_next_match()
		final_game.advance_stage()
	final_game.lock_planning()
	final_game.play_next_match()
	var final: Dictionary = final_game.match_history.back()
	if final.result.points_a == final.result.points_b:
		final.result.points_a = 2
		final.result.points_b = 0
	var match_winner: int = int(final.a) if final.result.points_a > final.result.points_b else int(final.b)
	var match_loser: int = int(final.b) if match_winner == final.a else int(final.a)
	final_game.standings[match_loser].points = 999
	final_game.advance_stage()
	_check(final_game.champion == match_winner, "championship match winner takes title despite prior points")
	var tied_final = Tournament.new()
	tied_final.initialize(42)
	while tied_final.active.size() > 2:
		tied_final.lock_planning()
		while tied_final.phase == "MATCHES": tied_final.play_next_match()
		tied_final.advance_stage()
	tied_final.tie_fixture = true
	tied_final.lock_planning()
	tied_final.play_next_match()
	var finalist_a: int = int(tied_final.match_history.back().a)
	var finalist_b: int = int(tied_final.match_history.back().b)
	var expected_tie_winner: int = finalist_a
	if tied_final.standings[finalist_b].points > tied_final.standings[finalist_a].points or (tied_final.standings[finalist_b].points == tied_final.standings[finalist_a].points and tied_final.standings[finalist_b].arena_wins > tied_final.standings[finalist_a].arena_wins): expected_tie_winner = finalist_b
	_check(tied_final.match_history.back().result.score == "1-1", "debug tie case reaches championship tiebreak")
	tied_final.advance_stage()
	_check(tied_final.champion == expected_tie_winner and tied_final.last_tiebreak.contains("Championship tied"), "tied championship uses declared standings tiebreak")
	if failures.is_empty():
		print("PASS: playable core loop")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, description: String) -> void:
	if not condition: failures.append(description)
