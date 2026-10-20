class_name MatchRunner
extends RefCounted
## Plays one whole match between bots and reports what happened, seat by seat.
## The bots see only their own view, as players would; bribes happen between the
## auditor and a caught liar right after the audit peek, as a whispered deal.

## An installment paid with at most this many coins to spare counts as a close call.
const CLOSE_MARGIN := 2


static func play(rules: RulesConfig, bots: Array[SimBot], match_seed: int) -> Dictionary:
	var state := MatchState.new(rules, bots.size(), match_seed)
	for i in bots.size():
		bots[i].rules = rules
		bots[i].rng.seed = hash([match_seed, i])
	var lies := _zeros(bots.size())
	var caught := _zeros(bots.size())
	var covered := _zeros(bots.size())
	var auditor_round_lies := _zeros(bots.size())
	var bribes_paid := _zeros(bots.size())
	var sank_table := _zeros(bots.size())
	var shortfall_rounds := 0
	var close_rounds := 0
	var wealth_before_last_shop := PackedInt32Array()

	for round_index in rules.round_count:
		state.start_round()
		for seat in bots.size():
			if not state.declare(seat, bots[seat].declare(state.view_for(seat))):
				state.declare(seat, state.incomes[seat])  # e.g. the auditor's card is open
			if state.lie_amount(seat) != 0:
				lies[seat] += 1
				if seat == state.auditor():
					auditor_round_lies[seat] += 1
		for seat in bots.size():
			var vouch_for := bots[seat].vouch_target(state.view_for(seat))
			if vouch_for != MatchState.NONE:
				state.vouch(seat, vouch_for)
		state.end_negotiation()
		var due := state.installment_due()
		for seat in bots.size():
			state.contribute(seat, maxi(bots[seat].contribution(state.view_for(seat)), state.min_contribution(seat)))
			if bots[seat].sank_the_table:
				sank_table[seat] = 1

		var auditor := state.auditor()
		state.choose_audit_target(bots[auditor].choose_audit_target(state.view_for(auditor)))
		var target := state.audit_target
		state.audit_peek()  # the auditor's private look at the card
		var report := true
		var lie := state.lie_amount(target)
		if lie != 0:
			var fine := absi(lie) * rules.fine_multiplier
			var price := bots[auditor].cover_up_price(fine, rules.audit_compensation)
			var loss := maxi(lie, 0) + fine - _voucher_share(state, target, fine)
			if price > 0 and bots[target].accepts_cover_up(price, loss, rules.audit_compensation, state.cash[target]):
				state.transfer(target, auditor, price)
				bribes_paid[target] += price
				report = false
		state.resolve_audit(report)
		if lie != 0:
			if report:
				caught[target] += 1
			else:
				covered[target] += 1
		if state.pot < due:
			shortfall_rounds += 1
		elif state.pot - due <= CLOSE_MARGIN:
			close_rounds += 1

		if state.is_last_round():
			for seat in bots.size():
				wealth_before_last_shop.append(state.wealth(seat))
		for seat in bots.size():
			for item: int in bots[seat].shopping_list(state.view_for(seat)):
				state.buy(seat, item)
		state.end_round()

	var wealth := PackedInt32Array()
	var last_shop_gain := PackedInt32Array()
	for seat in bots.size():
		wealth.append(state.wealth(seat))
		last_shop_gain.append(state.wealth(seat) - wealth_before_last_shop[seat])
	return {
		"succeeded": state.succeeded(),
		"final_carry": state.carry,
		"points": state.points(),
		"winners": state.winners(),
		"wealth": wealth,
		"last_shop_gain": last_shop_gain,
		"lies": lies,
		"caught": caught,
		"covered": covered,
		"auditor_round_lies": auditor_round_lies,
		"bribes_paid": bribes_paid,
		"sank_table": sank_table,
		"shortfall_rounds": shortfall_rounds,
		"close_rounds": close_rounds,
	}


static func _zeros(size: int) -> PackedInt32Array:
	var array := PackedInt32Array()
	array.resize(size)
	return array


## The part of the fine the target's vouchers would pay if reported (see MatchState.resolve_audit).
static func _voucher_share(state: MatchState, target: int, fine: int) -> int:
	var vouchers := state.vouchers_of(target)
	if vouchers.is_empty():
		return 0
	return floori(floori(fine / 2.0) / float(vouchers.size())) * vouchers.size()
