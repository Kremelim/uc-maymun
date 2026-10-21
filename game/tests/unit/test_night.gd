extends TestSuite
## The night around the matches: pacing, ready checks, the negotiation timer, what
## each seat may see, and that bots playing through intents replay the simulator.

const RULES: RulesConfig = preload("res://data/rules_v0_3.tres")
const KINDS := ["açgözlü", "dürüst", "kinci", "bedavacı"]
const NIGHT_SEED := 4242


## v0.3 without the basic first match, for tests about the full rules.
func _full_rules() -> RulesConfig:
	var rules: RulesConfig = RULES.duplicate()
	rules.basic_matches = 0
	return rules


func _bots(kinds: Array = KINDS) -> Array[SeatBot]:
	var bots: Array[SeatBot] = []
	for seat in kinds.size():
		bots.append(SeatBot.new(kinds[seat], seat, RULES, NIGHT_SEED))
	return bots


## Lets the bots act until `done` returns true (or the night ends). Returns the steps taken.
func _play(night: Night, bots: Array[SeatBot], done: Callable) -> int:
	var steps := 0
	while not night.night_over and not done.call() and steps < 10000:
		var acted := false
		for seat in bots.size():
			for intent in bots[seat].intents(night.view_for(seat)):
				assert_true(night.apply(seat, intent), "seat %d %s" % [seat, intent])
				acted = true
		assert_true(acted, "someone must act in phase %d" % night.current_match.phase)
		if not acted:
			break
		steps += 1
	return steps


func _in_phase(night: Night, phase: int) -> Callable:
	return func() -> bool: return night.current_match.phase == phase


func test_bots_online_replay_the_simulator() -> void:
	var night := Night.new(RULES, 4, NIGHT_SEED)
	var bots := _bots()
	var results: Array = []
	var record := func() -> bool:
		if night.current_match.is_over() and results.size() == night.match_index:
			var wealth := PackedInt32Array()
			for seat in 4:
				wealth.append(night.current_match.wealth(seat))
			results.append({"points": night.current_match.points(), "wealth": wealth})
		return false
	_play(night, bots, record)
	assert_true(night.night_over, "the night ends")
	assert_eq(results.size(), RULES.matches_per_night, "every match finished")
	var total := PackedInt32Array([0, 0, 0, 0])
	for index in results.size():
		var sim_bots: Array[SimBot] = []
		for kind: String in KINDS:
			sim_bots.append(SimBot.preset(kind))
		var expected := MatchRunner.play(RULES, sim_bots, Night.match_seed_of(NIGHT_SEED, index),
			MatchState.first_auditor_of(RULES, index, 4), Night.is_basic(RULES, index))
		assert_eq(results[index]["points"], expected["points"], "match %d points" % index)
		assert_eq(results[index]["wealth"], expected["wealth"], "match %d wealth" % index)
		for seat in 4:
			total[seat] += (expected["points"] as PackedInt32Array)[seat]
	assert_eq(night.night_points, total, "night points add up the matches")


func test_first_auditor_moves_on_each_match() -> void:
	var night := Night.new(RULES, 4, NIGHT_SEED)
	var bots := _bots()
	for index in 3:
		assert_eq(night.current_match.auditor(), index, "match %d starts with seat %d auditing" % [index, index])
		_play(night, bots, func() -> bool: return night.match_index > index)


func test_the_first_match_teaches_the_basic_rules() -> void:
	var night := Night.new(RULES, 4, NIGHT_SEED)
	var bots := _bots()
	assert_eq(night.view_for(0)["basic"], true, "match 1 is basic")
	var shops: Array = []
	_play(night, bots, func() -> bool:
		if night.current_match.phase == MatchState.Phase.SHOP:
			shops.append([night.match_index, night.current_match.round_index])
		return night.match_index == 1 and night.current_match.phase == MatchState.Phase.NEGOTIATE)
	assert_eq(shops.filter(func(s: Array) -> bool: return s[0] == 0), [], "no shop in the basic match")
	assert_eq(night.view_for(0)["basic"], false, "match 2 has the full rules")
	var auditor := night.current_match.auditor()
	assert_true(night.apply((auditor + 1) % 4, {"type": "vouch", "target": (auditor + 2) % 4}), "vouching is back")


func test_negotiation_ends_when_everyone_is_ready_or_time_runs_out() -> void:
	var night := Night.new(RULES, 4, NIGHT_SEED, 1000)
	for seat in 4:
		night.apply(seat, {"type": "declare", "amount": night.current_match.incomes[seat]})
	assert_eq(night.current_match.phase, MatchState.Phase.NEGOTIATE, "declarations revealed")
	assert_eq(night.view_for(0)["seconds_left"], RULES.negotiation_seconds, "the timer starts")
	for seat in 3:
		assert_true(night.apply(seat, {"type": "ready"}), "seat %d ready" % seat)
	assert_true(not night.apply(0, {"type": "ready"}), "ready once")
	assert_eq(night.awaiting(), [3], "waiting for the last one")
	assert_true(not night.tick(1000 + RULES.negotiation_seconds * 1000 - 1), "not yet")
	assert_eq(night.view_for(0)["seconds_left"], 1, "a second left")
	assert_true(night.tick(1000 + RULES.negotiation_seconds * 1000), "time is up")
	assert_eq(night.current_match.phase, MatchState.Phase.CONTRIBUTE, "on to contributions")


func test_intents_are_checked() -> void:
	var night := Night.new(RULES, 4, NIGHT_SEED)
	assert_true(not night.apply(1, {"type": "choose", "target": 2}), "not the time to audit")
	assert_true(not night.apply(1, {"type": "fly"}), "unknown intent")
	assert_true(not night.apply(4, {"type": "declare", "amount": 1}), "no such seat")
	assert_true(not night.apply(1, {"type": "ready"}), "nothing to be ready for while declaring")
	var bots := _bots()
	_play(night, bots, _in_phase(night, MatchState.Phase.AUDIT_CHOOSE))
	var auditor := night.current_match.auditor()
	var other := (auditor + 1) % 4
	assert_true(not night.apply(other, {"type": "choose", "target": auditor}), "only the auditor chooses")
	assert_true(not night.apply(auditor, {"type": "choose", "target": auditor}), "not themselves")
	assert_true(night.apply(auditor, {"type": "choose", "target": other}), "the auditor chooses")
	assert_true(not night.apply(other, {"type": "decide", "report": false}), "only the auditor decides")


func test_views_keep_secrets() -> void:
	var night := Night.new(_full_rules(), 4, NIGHT_SEED)
	var bots := _bots()
	_play(night, bots, _in_phase(night, MatchState.Phase.NEGOTIATE))
	var giver := 0
	while night.current_match.cash[giver] == 0:
		giver += 1
	var taker := (giver + 1) % 4
	assert_true(night.apply(giver, {"type": "transfer", "to": taker, "amount": 1}), "a coin under the table")
	for seat in 4:
		var transfers := _events_of(night.view_for(seat), "transfer")
		assert_eq(transfers.size(), 1 if seat in [giver, taker] else 0, "seat %d sees the transfer only if involved" % seat)
	_play(night, bots, _in_phase(night, MatchState.Phase.AUDIT_DECIDE))
	var auditor := night.current_match.auditor()
	for seat in 4:
		var view := night.view_for(seat)
		assert_eq(view.has("audit_peek"), seat == auditor, "seat %d and the auditor's peek" % seat)
		assert_true(not _has_key(view, "incomes") and not view.has("reckoning"), "no incomes before Hesap Günü")
	_play(night, bots, _in_phase(night, MatchState.Phase.MATCH_OVER))
	var reckoning: Dictionary = night.view_for(0)["reckoning"]
	assert_eq((reckoning["rounds"] as Array).size(), RULES.round_count, "Hesap Günü opens every round")


func test_last_round_skips_the_closed_shop() -> void:
	var night := Night.new(_full_rules(), 4, NIGHT_SEED)
	var bots := _bots()
	var shops: Array = []
	_play(night, bots, func() -> bool:
		if night.current_match.phase == MatchState.Phase.SHOP and night.current_match.round_index not in shops:
			shops.append(night.current_match.round_index)
		return night.current_match.is_over())
	assert_eq(shops, [0, 1, 2], "the shop opens after rounds 1-3 only")
	assert_eq(night.awaiting(), [0, 1, 2, 3], "everyone confirms the next match")


static func _events_of(view: Dictionary, type: String) -> Array:
	return (view["events"] as Array).filter(func(event: Dictionary) -> bool: return event["type"] == type)


static func _has_key(value: Variant, key: String) -> bool:
	if value is Dictionary:
		for k: Variant in value:
			if str(k) == key or _has_key(value[k], key):
				return true
	elif value is Array:
		for item: Variant in value:
			if _has_key(item, key):
				return true
	return false
