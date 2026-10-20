extends TestSuite

const RULES: RulesConfig = preload("res://data/rules_v0_1.tres")

var _nobody_declared: Array = [false, false, false, false]


func _dealt_table(seats: int, match_seed: int) -> TableState:
	var rng := RandomNumberGenerator.new()
	rng.seed = match_seed
	var table := TableState.new(RULES, seats)
	table.deal(rng)
	return table


func _sum(values: PackedInt32Array) -> int:
	var total := 0
	for value in values:
		total += value
	return total


func test_rules_data_matches_design_doc() -> void:
	# docs/gdd/kurallar-v0.1.md: 8 income sets, each totalling 20.
	assert_eq(RULES.income_sets.size(), 8, "income set count")
	for income_set in RULES.income_sets:
		assert_eq(income_set.size(), 4, "values per set %s" % income_set)
		assert_eq(_sum(income_set), 20, "total of set %s" % income_set)


func test_same_seed_deals_same_incomes() -> void:
	for match_seed: int in [1, 42, 9001]:
		var a := _dealt_table(4, match_seed)
		var b := _dealt_table(4, match_seed)
		for seat in 4:
			assert_eq(a.income_of(seat), b.income_of(seat), "seed %d seat %d" % [match_seed, seat])


func test_four_seats_receive_one_whole_income_set() -> void:
	for match_seed in 200:
		var table := _dealt_table(4, match_seed)
		assert_eq(table.total_income(), 20, "seed %d total" % match_seed)
		var dealt := PackedInt32Array()
		for seat in 4:
			dealt.append(table.income_of(seat))
		dealt.sort()
		var known := false
		for income_set in RULES.income_sets:
			var sorted_set := income_set.duplicate()
			sorted_set.sort()
			known = known or sorted_set == dealt
		assert_true(known, "seed %d dealt %s, which is not a known set" % [match_seed, dealt])


func test_shuffle_puts_every_value_in_every_seat() -> void:
	# Set 1 is 2,4,6,8. Over many seeds, seat 0 should see all four values.
	var seen := {}
	for match_seed in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = match_seed
		var shuffled := TableState._shuffled(RULES.income_sets[0], rng)
		seen[shuffled[0]] = true
	assert_eq(seen.size(), 4, "distinct values seen in seat 0")


func test_public_snapshot_never_contains_incomes() -> void:
	var table := _dealt_table(4, 7)
	var snapshot := table.public_snapshot()
	assert_eq(snapshot.keys(), ["round", "total_income", "declared"], "public keys before declarations")
	assert_eq(snapshot["declared"], _nobody_declared, "nobody has declared yet")


func test_private_view_shows_only_own_income_and_declaration() -> void:
	var table := _dealt_table(4, 7)
	table.declare(2, 3)
	for seat in 4:
		var view := table.private_view(seat)
		assert_eq(view.keys(), ["seat", "income", "declaration"], "private keys for seat %d" % seat)
		assert_eq(view["income"], table.income_of(seat), "income in private view of seat %d" % seat)
	assert_eq(table.private_view(2)["declaration"], 3, "own declaration")
	assert_eq(table.private_view(1)["declaration"], TableState.NOT_DECLARED, "someone else's declaration")


func test_declarations_stay_hidden_until_everyone_declares() -> void:
	# Rules v0.1: slips are written in secret and revealed at the same time.
	var table := _dealt_table(4, 11)
	for seat in 3:
		table.declare(seat, 2)
	var snapshot := table.public_snapshot()
	assert_true(not snapshot.has("declarations"), "amounts must stay hidden while someone is still declaring")
	assert_true(not snapshot.has("missing"), "missing must wait for the last declaration")
	assert_eq(snapshot["declared"], [true, true, true, false], "who has declared is public")


func test_missing_coins_after_reveal() -> void:
	var table := _dealt_table(4, 11)
	for seat in 3:
		table.declare(seat, table.income_of(seat))
	table.declare(3, table.income_of(3) - 1)  # seat 3 hides one coin
	var snapshot := table.public_snapshot()
	assert_eq(snapshot["missing"], 1, "missing coins")
	assert_eq(snapshot["declarations"][3], table.income_of(3) - 1, "revealed declaration of seat 3")


func test_over_declaring_gives_negative_missing() -> void:
	var table := _dealt_table(4, 11)
	for seat in 4:
		table.declare(seat, table.income_of(seat))
	assert_eq(table.public_snapshot()["missing"], 0, "everyone honest")
	table = _dealt_table(4, 11)
	for seat in 4:
		table.declare(seat, table.income_of(seat) + (2 if seat == 0 else 0))
	assert_eq(table.public_snapshot()["missing"], -2, "seat 0 over-declared by two")


func test_declarations_lock_after_reveal() -> void:
	var table := _dealt_table(4, 11)
	table.declare(0, 1)
	table.declare(0, 2)  # changing your mind before the reveal is fine
	for seat in range(1, 4):
		table.declare(seat, 1)
	assert_true(not table.declare(0, 5), "no changes after the reveal")
	assert_eq(table.public_snapshot()["declarations"], PackedInt32Array([2, 1, 1, 1]), "revealed declarations")


func test_invalid_declarations_are_rejected() -> void:
	var table := _dealt_table(4, 3)
	assert_true(not table.declare(-1, 2), "negative seat must be rejected")
	assert_true(not table.declare(4, 2), "seat out of range must be rejected")
	assert_true(not table.declare(0, -1), "negative amount must be rejected")
	assert_true(not table.declare(0, 21), "more than the table total must be rejected")
	assert_eq(table.public_snapshot()["declared"], _nobody_declared, "rejected declarations change nothing")


func test_new_round_clears_declarations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var table := TableState.new(RULES, 4)
	table.deal(rng)
	for seat in 4:
		table.declare(seat, 1)
	table.deal(rng)
	assert_eq(table.round_number, 2, "round number")
	assert_eq(table.public_snapshot()["declared"], _nobody_declared, "declarations after a new deal")
	assert_true(table.declare(0, 1), "declaring is open again")


func test_fewer_seats_get_a_slice_of_the_set() -> void:
	var table := _dealt_table(2, 13)
	assert_eq(table.seat_count, 2, "seat count")
	assert_eq(table.total_income(), table.income_of(0) + table.income_of(1), "total covers only dealt seats")
