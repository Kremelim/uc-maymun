extends TestSuite
## The rules as executable checks. Most tests start from v0.1 (docs/gdd/kurallar-v0.1.md)
## and turn on one v0.2 switch at a time. Seat 0 audits round 1.

const RULES: RulesConfig = preload("res://data/rules_v0_1.tres")
const RULES_V0_2: RulesConfig = preload("res://data/rules_v0_2.tres")


func _match(rules: RulesConfig = RULES) -> MatchState:
	var state := MatchState.new(rules, 4, 7)
	state.start_round()
	return state


## Replaces the dealt incomes so a test does not depend on the shuffle.
func _set_incomes(state: MatchState, values: Array) -> void:
	for seat in state.seat_count:
		state.cash[seat] += int(values[seat]) - state.incomes[seat]
		state.incomes[seat] = values[seat]


func _declare_all(state: MatchState, values: Array) -> void:
	for seat in state.seat_count:
		assert_true(state.declare(seat, values[seat]), "declare seat %d" % seat)


func _contribute_all(state: MatchState, values: Array) -> void:
	for seat in state.seat_count:
		assert_true(state.contribute(seat, values[seat]), "contribute seat %d" % seat)


## Declares, contributes and audits `target`, leaving the state in the shop phase.
func _round(state: MatchState, incomes: Array, declared: Array, contributed: Array, target: int, report: bool) -> void:
	_set_incomes(state, incomes)
	_declare_all(state, declared)
	state.end_negotiation()
	_contribute_all(state, contributed)
	assert_true(state.choose_audit_target(target), "choose target %d" % target)
	state.resolve_audit(report)


func _next_seat_after_auditor(state: MatchState) -> int:
	return (state.auditor() + 1) % state.seat_count


func test_rules_data_matches_design_doc() -> void:
	assert_eq(RULES.min_players, 3, "at least 3 players")
	assert_eq(RULES.round_count, 4, "rounds")
	assert_eq(RULES.installment, 12, "installment")
	assert_eq(RULES.shortfall_interest, 1.5, "interest")
	assert_eq(RULES.fine_multiplier, 1, "fine multiplier")
	assert_eq(RULES.audit_compensation, 1, "compensation for a clean audit")
	assert_eq(RULES.vouch_reward, 2, "vouch reward")
	assert_eq(RULES.accessory_prices, PackedInt32Array([4, 6, 8, 12, 20]), "accessory prices")
	assert_eq(RULES.accessory_values, PackedInt32Array([5, 7, 10, 15, 25]), "accessory values")
	assert_eq(RULES.placement_points, PackedInt32Array([5, 3, 2, 1]), "placement points")
	assert_eq(RULES.auditor_card_open, false, "variant off in v0.1")
	assert_eq(RULES.min_contribution_ratio, 0.0, "variant off in v0.1")


func test_v0_2_data_matches_design_doc() -> void:
	assert_eq(RULES_V0_2.auditor_card_open, true, "the auditor's card is open")
	assert_eq(RULES_V0_2.min_contribution_ratio, 0.6, "minimum contribution 60%")
	assert_eq(RULES_V0_2.last_round_shop, false, "no shop after the last audit")
	for property: String in ["min_players", "max_players", "round_count", "income_sets", "installment",
			"shortfall_interest", "fine_multiplier", "audit_compensation", "vouch_reward",
			"over_declaration_is_lie", "accessory_names", "accessory_prices", "accessory_values", "placement_points"]:
		assert_eq(RULES_V0_2.get(property), RULES.get(property), "%s unchanged from v0.1" % property)
	# kurallar-v0.2.md: at an honest table the minimums alone pay the installment.
	var state := MatchState.new(RULES_V0_2, 4, 1)
	for income_set in RULES_V0_2.income_sets:
		var minimums := 0
		for income in income_set:
			minimums += state.minimum_for(income)
		assert_true(minimums >= RULES_V0_2.installment and minimums <= RULES_V0_2.installment + 2,
			"honest minimums for %s: %d" % [income_set, minimums])


func test_same_seed_same_incomes() -> void:
	var a := MatchState.new(RULES, 4, 99)
	var b := MatchState.new(RULES, 4, 99)
	a.start_round()
	b.start_round()
	assert_eq(a.incomes, b.incomes, "first round")


func test_honest_round_pays_the_installment() -> void:
	var state := _match()
	_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [3, 3, 3, 3], 1, true)
	assert_eq(state.carry, 0, "installment paid exactly")
	# Clean audit: the auditor (seat 0) pays seat 1 one coin.
	assert_eq(state.cash, PackedInt32Array([1, 3, 2, 2]), "cash after a clean audit")


func test_shortfall_carries_with_interest() -> void:
	var state := _match()
	_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [2, 2, 2, 3], 1, true)
	assert_eq(state.carry, 5, "short by 3, times 1.5 rounded up")
	state.end_round()
	state.start_round()
	assert_eq(state.installment_due(), 17, "next installment")


func test_surplus_counts_towards_the_next_installment() -> void:
	var state := _match()
	_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [4, 4, 4, 3], 1, true)
	assert_eq(state.carry, -3, "three coins of credit")


func test_caught_liar_returns_coins_and_pays_the_fine() -> void:
	var state := _match()
	# Seat 3 got 8, declares 5 (hides 3) and is audited by seat 0.
	_round(state, [4, 4, 4, 8], [4, 4, 4, 5], [3, 3, 3, 0], 3, true)
	assert_eq(state.cash[3], 8 - 3 - 3, "returns 3 and pays a fine of 3")
	assert_eq(state.cash[0], 4 - 3 + 3, "the auditor gets the fine")
	assert_eq(state.carry, 0, "the 3 returned coins complete the installment")
	assert_eq(state.view_for(1)["audit"], {"target": 3, "caught": true, "difference": 3}, "public outcome")


func test_vouchers_share_half_the_fine() -> void:
	var state := _match()
	_set_incomes(state, [4, 4, 4, 8])
	_declare_all(state, [4, 4, 4, 4])
	assert_true(state.vouch(1, 3), "seat 1 vouches for seat 3")
	assert_true(state.vouch(2, 3), "seat 2 vouches for seat 3")
	state.end_negotiation()
	_contribute_all(state, [3, 3, 3, 0])
	state.choose_audit_target(3)
	state.resolve_audit(true)
	# Hid 4, fine 4: half (2) split between the two vouchers, the liar pays the other 2.
	assert_eq(state.cash[1], 4 - 3 - 1, "voucher 1 pays 1")
	assert_eq(state.cash[2], 4 - 3 - 1, "voucher 2 pays 1")
	assert_eq(state.cash[3], 8 - 4 - 2, "the liar returns 4 and pays 2")
	assert_eq(state.cash[0], 4 - 3 + 4, "the auditor gets the whole fine")


func test_vouching_for_an_honest_player_pays_from_the_bank() -> void:
	var state := _match()
	_set_incomes(state, [5, 5, 5, 5])
	_declare_all(state, [5, 5, 5, 5])
	state.vouch(2, 1)
	state.end_negotiation()
	_contribute_all(state, [3, 3, 3, 3])
	state.choose_audit_target(1)
	state.resolve_audit(true)
	assert_eq(state.cash[2], 5 - 3 + 2, "voucher reward")


func test_auditor_cannot_vouch_and_nobody_vouches_for_the_auditor() -> void:
	var state := _match()
	_declare_all(state, [1, 1, 1, 1])
	assert_true(not state.vouch(0, 1), "the auditor (seat 0) cannot vouch")
	assert_true(not state.vouch(1, 0), "vouching for the auditor is pointless")
	assert_true(not state.vouch(2, 2), "nobody vouches for themselves")
	assert_true(state.vouch(2, 1), "a normal vouch")
	state.end_negotiation()
	_contribute_all(state, [0, 0, 0, 0])
	assert_true(not state.choose_audit_target(0), "the auditor cannot audit themselves")


func test_cover_up_looks_clean_until_hesap_gunu() -> void:
	var state := _match()
	_round(state, [4, 4, 4, 8], [4, 4, 4, 5], [3, 3, 3, 3], 3, false)
	assert_eq(state.view_for(1)["audit"], {"target": 3, "caught": false, "difference": 0}, "looks clean")
	assert_eq(state.cash[3], 8 - 3 + 1, "the liar even gets the compensation")
	state.end_round()
	for i in 3:
		state.start_round()
		_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [3, 3, 3, 3], _next_seat_after_auditor(state), true)
		state.end_round()
	assert_true(state.reveal()[0]["covered_up"], "Hesap Günü shows the cover-up")
	assert_true(not state.reveal()[1]["covered_up"], "no cover-up in an honest round")


func test_over_declaring_is_a_lie_when_the_rules_say_so() -> void:
	var lenient: RulesConfig = RULES.duplicate()
	lenient.over_declaration_is_lie = false
	for rules: RulesConfig in [RULES, lenient]:
		var state := _match(rules)
		# Seat 1 got 5 and declares 7.
		_round(state, [5, 5, 5, 5], [5, 7, 5, 5], [3, 3, 3, 3], 1, true)
		var caught: bool = state.view_for(2)["audit"]["caught"]
		assert_eq(caught, rules.over_declaration_is_lie, "caught exactly when over-declaring counts as a lie")
		assert_eq(state.cash[1], 5 - 3 - 2 if caught else 5 - 3 + 1, "fine of 2 with nothing to return, or compensation")


func test_fines_sell_accessories_and_the_rest_becomes_debt() -> void:
	var state := _match()
	_set_incomes(state, [5, 5, 5, 5])
	state.cash[3] = 0  # spent everything earlier...
	(state.accessories[3] as Array).append(2)  # ...on a Saat (price 8)
	_declare_all(state, [5, 5, 5, 0])  # seat 3 hid 5 it no longer has
	state.end_negotiation()
	_contribute_all(state, [3, 3, 3, 0])
	state.choose_audit_target(3)
	state.resolve_audit(true)
	# Owes 5 back: the Saat is sold for 8, 3 change. Fine 5: pays the 3, 2 stay unpaid.
	assert_eq((state.accessories[3] as Array).size(), 0, "the Saat was sold")
	assert_eq(state.cash[3], 0, "the change went into the fine")
	assert_eq(state.cash[0], 5 - 3 + 3, "the auditor only gets what could be paid")
	# Pot 9 + 5 returned = 14: 2 of credit, cancelled by the 2 unpaid coins.
	assert_eq(state.carry, 0, "unpaid fine joins the common debt")


func test_hidden_information_in_views() -> void:
	var state := _match()
	_set_incomes(state, [2, 4, 6, 8])
	state.declare(0, 2)
	var early := state.view_for(1)
	assert_eq(early["declarations"], PackedInt32Array(), "declarations hidden until all are in")
	assert_eq(early["my_income"], 4, "own income")
	_declare_all(state, [2, 4, 6, 8])
	state.end_negotiation()
	assert_true(state.contribute(0, 1), "first contribution")
	assert_eq(state.view_for(1)["contributions"], PackedInt32Array(), "contributions hidden until all are in")
	for key: String in state.view_for(1):
		assert_true(key != "incomes", "no view lists everyone's incomes")


func test_contributions_cannot_exceed_cash() -> void:
	var state := _match()
	_set_incomes(state, [2, 4, 6, 8])
	_declare_all(state, [2, 4, 6, 8])
	state.end_negotiation()
	assert_true(not state.contribute(0, 3), "only 2 in the pocket")


func test_shop_and_last_round_shop_switch() -> void:
	var no_last_shop: RulesConfig = RULES.duplicate()
	no_last_shop.last_round_shop = false
	var state := MatchState.new(no_last_shop, 4, 7)
	for i in 4:
		state.start_round()
		_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [3, 3, 3, 3], _next_seat_after_auditor(state), true)
		state.cash[2] += 4  # enough for a Gözlük
		if i < 3:
			assert_true(state.buy(2, 0), "Gözlük in round %d" % (i + 1))
		else:
			assert_true(not state.buy(2, 0), "no shopping after the last audit")
		state.end_round()
	assert_eq(state.accessory_value(2), 15, "three Gözlük worth 5 each")


func test_full_match_scoring() -> void:
	var state := MatchState.new(RULES, 4, 7)
	for i in 4:
		state.start_round()
		# Seat 3 always gets 8, declares 6 and is covered up; in its own audit round it audits seat 2.
		var target := 3 if state.auditor() != 3 else 2
		_round(state, [4, 4, 4, 8], [4, 4, 4, 6], [3, 3, 3, 3], target, false)
		state.end_round()
	assert_true(state.succeeded(), "installments paid")
	# Wealth: seat 3 = 4 x 5 + 3 compensations - 1 paid = 22; seat 2 = 4 + 1 - 1 = 4;
	# seats 0 and 1 = 4 - 1 = 3, tied on wealth and contributions, so they share third place.
	assert_eq(state.ranking()[0], 3, "seat 3 is richest")
	assert_eq(state.points(), PackedInt32Array([2, 2, 3, 5]), "points with a shared third place")
	assert_eq(state.winners(), [3], "one winner")


func test_sunk_table_scores_nothing() -> void:
	var state := MatchState.new(RULES, 4, 7)
	for i in 4:
		state.start_round()
		_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [0, 0, 0, 0], _next_seat_after_auditor(state), true)
		state.end_round()
	assert_true(not state.succeeded(), "nobody paid")
	assert_eq(state.points(), PackedInt32Array([0, 0, 0, 0]), "everyone scores 0")
	assert_eq(state.winners(), [], "no winner")


func test_ties_share_the_better_place() -> void:
	var state := MatchState.new(RULES, 4, 7)
	for i in 4:
		state.start_round()
		_round(state, [5, 5, 5, 5], [5, 5, 5, 5], [3, 3, 3, 3], _next_seat_after_auditor(state), true)
		state.end_round()
	# Every seat paid one compensation as auditor and received one: all equal.
	assert_eq(state.points(), PackedInt32Array([5, 5, 5, 5]), "a four-way tie shares first place")


func test_transfers_are_checked() -> void:
	var state := _match()
	_set_incomes(state, [2, 4, 6, 8])
	assert_true(not state.transfer(3, 0, 1), "no transfers while declaring")
	_declare_all(state, [2, 4, 6, 8])
	assert_true(not state.transfer(3, 0, 9), "cannot give more than you have")
	assert_true(not state.transfer(3, 3, 1), "not to yourself")
	assert_true(state.transfer(3, 0, 2), "a bribe")
	assert_eq(state.cash[0], 4, "received")
	assert_eq(state.view_for(1)["my_transfers"], [], "others do not see it")
	assert_eq((state.view_for(0)["my_transfers"] as Array).size(), 1, "the receiver does")


func test_open_auditor_card_forbids_the_auditors_lie() -> void:
	var rules: RulesConfig = RULES.duplicate()
	rules.auditor_card_open = true
	var state := _match(rules)
	_set_incomes(state, [5, 5, 5, 5])
	assert_true(not state.declare(0, 2), "the auditor (seat 0) cannot under-declare")
	assert_true(state.declare(0, 5), "the truth is fine")
	assert_true(state.declare(1, 2), "everyone else still can lie")


func test_minimums_are_paid_when_declarations_are_revealed() -> void:
	var rules: RulesConfig = RULES.duplicate()
	rules.min_contribution_ratio = 0.6
	var state := _match(rules)
	_set_incomes(state, [7, 5, 5, 3])
	assert_eq(state.minimum_for(7), 5, "60% of 7, rounded up")
	assert_true(state.declare(0, 7), "first declaration")
	assert_eq(state.pot, 0, "nothing is paid before the reveal")
	for seat: int in [1, 2, 3]:
		assert_true(state.declare(seat, [0, 5, 3, 8][seat]), "declare seat %d" % seat)
	assert_eq(state.minimums, PackedInt32Array([5, 3, 2, 3]), "seat 3 over-declared and pays all it has")
	assert_eq(state.pot, 13, "minimums are in the pot")
	assert_eq(state.cash, PackedInt32Array([2, 2, 3, 0]), "and out of the pockets")
	assert_eq(state.view_for(1)["minimums"], state.minimums, "minimums are public")
	# Paid before negotiating, so emptying your pocket into a friend's cannot dodge it.
	assert_true(state.transfer(0, 1, 2), "coins still pass under the table")
	state.end_negotiation()
	assert_true(not state.contribute(1, -1), "no negative extra")
	assert_true(not state.contribute(1, 5), "the extra comes from the cash left")
	_contribute_all(state, [0, 4, 0, 0])
	assert_eq(state.contributions, PackedInt32Array([5, 7, 2, 3]), "contribution = minimum + extra")
	assert_eq(state.pot, 17, "extras join the pot")
	assert_eq(state.total_contributed, PackedInt32Array([5, 7, 2, 3]), "the tie-break counts minimums too")
