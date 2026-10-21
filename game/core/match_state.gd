class_name MatchState
extends RefCounted
## One whole match under the paper prototype rules (docs/gdd/kurallar-v0.3.md;
## RulesConfig switches turn it back into earlier versions). Pure and seeded:
## no nodes, no networking. Whoever runs the match (the host, or the simulator)
## feeds it each phase's decisions in order. Players may only see view_for(seat)
## and, as the auditor, audit_peek(); reveal() is for Hesap Günü at the end.
##
## Round: start_round → declare (all; minimums are paid at the reveal) →
## vouch / transfer → end_negotiation → contribute (all) → choose_audit_target →
## [audit_peek, transfer] → resolve_audit → buy → end_round.

enum Phase { ROUND_OVER, DECLARE, NEGOTIATE, CONTRIBUTE, AUDIT_CHOOSE, AUDIT_DECIDE, SHOP, MATCH_OVER }

const NONE := -1
const TO_POT := -2

var rules: RulesConfig
var seat_count: int
## Who audits the first round; the others follow in seat order.
var first_auditor := 0
var phase := Phase.ROUND_OVER
var round_index := -1
## Debt carried into the next installment. Negative means credit.
var carry := 0
var cash := PackedInt32Array()
var total_contributed := PackedInt32Array()
## Per seat, the accessory indices it owns. Public.
var accessories: Array = []

var incomes := PackedInt32Array()
var declarations := PackedInt32Array()
var vouches := PackedInt32Array()
## Paid by each seat the moment the declarations are revealed. Public.
var minimums := PackedInt32Array()
## Each seat's whole contribution this round (minimum + extra), once everyone has chosen.
var contributions := PackedInt32Array()
var pot := 0
var audit_target := NONE

## Public record of each finished round.
var history: Array[Dictionary] = []
## Unpaid debts between players (rules.unpaid_becomes_iou): {"from", "to", "amount", "round"}. Public.
var ious: Array[Dictionary] = []

var _secrets: Array[Dictionary] = []  # per finished round, for Hesap Günü
var _transfers: Array[Dictionary] = []  # this round's under-the-table transfers
var _extras := PackedInt32Array()  # closed fists, until everyone has chosen
var _audit: Dictionary = {}  # this round's public audit outcome
var _covered_up := false
var _unpaid := 0  # payments nobody could make this round; they join the common debt
var _rng := RandomNumberGenerator.new()


func _init(p_rules: RulesConfig, p_seat_count: int, match_seed: int, p_first_auditor: int = 0) -> void:
	assert(p_seat_count >= 2 and p_seat_count <= p_rules.max_players, "seat count out of range")
	rules = p_rules
	seat_count = p_seat_count
	first_auditor = posmod(p_first_auditor, seat_count)
	_rng.seed = match_seed
	cash.resize(seat_count)
	total_contributed.resize(seat_count)
	for seat in seat_count:
		accessories.append([])


func auditor() -> int:
	return (first_auditor + round_index) % seat_count


## Who audits first in match `match_index` (from 0) of a night.
static func first_auditor_of(p_rules: RulesConfig, match_index: int, p_seat_count: int) -> int:
	return match_index % p_seat_count if p_rules.rotate_first_auditor else 0


func is_last_round() -> bool:
	return round_index == rules.round_count - 1


func installment_due() -> int:
	return rules.installment + carry


func total_income() -> int:
	return _sum(incomes)


## Coins the declarations do not account for. Negative when people over-declared.
func missing() -> int:
	return total_income() - _sum(declarations)


func start_round() -> void:
	assert(phase == Phase.ROUND_OVER and round_index < rules.round_count - 1, "no round to start")
	round_index += 1
	var income_set: PackedInt32Array = rules.income_sets[_rng.randi_range(0, rules.income_sets.size() - 1)]
	incomes = TableState._shuffled(income_set, _rng).slice(0, seat_count)
	for seat in seat_count:
		cash[seat] += incomes[seat]
	declarations = _filled(NONE)
	vouches = _filled(NONE)
	minimums = _filled(0)
	contributions = _filled(NONE)
	_extras = _filled(NONE)
	pot = 0
	audit_target = NONE
	_transfers = []
	_audit = {}
	_covered_up = false
	_unpaid = 0
	phase = Phase.DECLARE


## Declarations are secret until the last one is in; then all are revealed at once.
func declare(seat: int, amount: int) -> bool:
	if phase != Phase.DECLARE or not _is_seat(seat) or amount < 0 or amount > total_income():
		return false
	if rules.auditor_card_open and seat == auditor() and amount != incomes[seat]:
		return false  # everyone can see the auditor's card
	declarations[seat] = amount
	if not declarations.has(NONE):
		_pay_minimums()
		phase = Phase.NEGOTIATE
	return true


## One vouch per player per round (a new one replaces it); never for yourself.
## The auditor cannot vouch: they would earn the vouch reward by calling their own
## target clean. Vouching for the auditor is meaningless, since nobody audits them.
func vouch(seat: int, target: int) -> bool:
	if phase != Phase.NEGOTIATE or not _is_seat(seat) or not _is_seat(target) or seat == target:
		return false
	if seat == auditor() or target == auditor():
		return false
	vouches[seat] = target
	return true


## Under the table: secret, never binding, and possible while negotiating and around the audit.
func transfer(from: int, to: int, amount: int) -> bool:
	if phase not in [Phase.NEGOTIATE, Phase.AUDIT_CHOOSE, Phase.AUDIT_DECIDE]:
		return false
	if not _is_seat(from) or not _is_seat(to) or from == to or amount <= 0 or amount > cash[from]:
		return false
	cash[from] -= amount
	cash[to] += amount
	_transfers.append({"from": from, "to": to, "amount": amount})
	return true


func end_negotiation() -> void:
	assert(phase == Phase.NEGOTIATE, "not negotiating")
	phase = Phase.CONTRIBUTE


## What a declaration of `amount` obliges a seat to pay right away under min_contribution_ratio.
func minimum_for(amount: int) -> int:
	return ceili(amount * rules.min_contribution_ratio - 0.000001)  # 25 × 0.56 = 14.000000000000002 must stay 14


## Contributions on top of the minimum, in closed fists: they count once everyone has chosen.
func contribute(seat: int, extra: int) -> bool:
	if phase != Phase.CONTRIBUTE or not _is_seat(seat) or extra < 0 or extra > cash[seat]:
		return false
	_extras[seat] = extra
	if not _extras.has(NONE):
		for s in seat_count:
			cash[s] -= _extras[s]
			pot += _extras[s]
			contributions[s] = minimums[s] + _extras[s]
			total_contributed[s] += contributions[s]
		phase = Phase.AUDIT_CHOOSE
	return true


func choose_audit_target(target: int) -> bool:
	if phase != Phase.AUDIT_CHOOSE or not _is_seat(target) or target == auditor():
		return false
	audit_target = target
	phase = Phase.AUDIT_DECIDE
	return true


## What only the auditor sees: the audited player's real income this round.
func audit_peek() -> int:
	assert(phase == Phase.AUDIT_DECIDE, "nobody is being audited")
	return incomes[audit_target]


func fine_for(lie: int) -> int:
	return ceili(absi(lie) * rules.fine_multiplier)


## How far `seat`'s declaration is from the truth in a way the rules call a lie:
## positive = hid coins, negative = over-declared (if that counts), else 0.
func lie_amount(seat: int) -> int:
	var difference := incomes[seat] - declarations[seat]
	if difference > 0 or (difference < 0 and rules.over_declaration_is_lie):
		return difference
	return 0


## The auditor reports (which only matters when there is a lie) or calls it clean.
## Calling a liar clean is a cover-up: it stays secret until Hesap Günü.
func resolve_audit(report: bool) -> void:
	assert(phase == Phase.AUDIT_DECIDE, "nobody is being audited")
	var target := audit_target
	var lie := lie_amount(target)
	var vouchers := vouchers_of(target)
	var caught := report and lie != 0
	if caught:
		if lie > 0:
			_pay(target, TO_POT, lie)  # the hidden coins go back to the table
		var fine := fine_for(lie)
		var share_each := 0
		if not vouchers.is_empty():
			# Vouchers share half the fine; the liar pays the rest.
			share_each = floori(floori(fine / 2.0) / float(vouchers.size()))
		for voucher: int in vouchers:
			_pay(voucher, auditor(), share_each)
		_pay(target, auditor(), fine - share_each * vouchers.size())
	else:
		_pay(auditor(), target, rules.audit_compensation)
		for voucher: int in vouchers:
			cash[voucher] += rules.vouch_reward
	_covered_up = lie != 0 and not caught
	_audit = {"target": target, "caught": caught, "difference": absi(lie) if caught else 0}
	_close_installment()
	phase = Phase.SHOP


func can_buy(seat: int, item: int) -> bool:
	if phase != Phase.SHOP or not _is_seat(seat) or item < 0 or item >= rules.accessory_prices.size():
		return false
	if is_last_round() and not rules.last_round_shop:
		return false
	return rules.accessory_prices[item] <= cash[seat]


func buy(seat: int, item: int) -> bool:
	if not can_buy(seat, item):
		return false
	cash[seat] -= rules.accessory_prices[item]
	(accessories[seat] as Array).append(item)
	return true


func end_round() -> void:
	assert(phase == Phase.SHOP, "round not finished")
	history.append({
		"round": round_index,
		"auditor": auditor(),
		"total_income": total_income(),
		"declarations": declarations.duplicate(),
		"missing": missing(),
		"vouches": vouches.duplicate(),
		"minimums": minimums.duplicate(),
		"contributions": contributions.duplicate(),
		"audit": _audit.duplicate(),
		"unpaid": _unpaid,
		"carry_after": carry,
	})
	_secrets.append({
		"incomes": incomes.duplicate(),
		"covered_up": _covered_up,
		"transfers": _transfers.duplicate(true),
	})
	phase = Phase.MATCH_OVER if is_last_round() else Phase.ROUND_OVER


func is_over() -> bool:
	return phase == Phase.MATCH_OVER


func succeeded() -> bool:
	return is_over() and carry <= 0


func accessory_value(seat: int) -> int:
	var total := 0
	for item: int in accessories[seat]:
		total += rules.accessory_values[item]
	return total


## What the IOUs add to (owed to `seat`) or take from (owed by it) its wealth.
func iou_balance(seat: int) -> int:
	return balance_of(ious, seat)


## iou_balance over a list of IOUs, e.g. the one in a player's view.
static func balance_of(iou_list: Array, seat: int) -> int:
	var balance := 0
	for iou: Dictionary in iou_list:
		if iou["to"] == seat:
			balance += int(iou["amount"])
		if iou["from"] == seat:
			balance -= int(iou["amount"])
	return balance


## Cash plus accessories at their end value, with IOUs settled. Can go negative.
func wealth(seat: int) -> int:
	return cash[seat] + accessory_value(seat) + iou_balance(seat)


## Seats from first to last: richest first, then whoever put more into the table.
func ranking() -> Array:
	var seats: Array = range(seat_count)
	seats.sort_custom(func(a: int, b: int) -> bool: return _rank_key(a) > _rank_key(b))
	return seats


## Night score for this match. Players tied on wealth and contributions share the better place.
func points() -> PackedInt32Array:
	var result := _filled(0)
	if not succeeded():
		return result
	var order := ranking()
	for place in order.size():
		var seat: int = order[place]
		var shared_place := place
		while shared_place > 0 and _rank_key(order[shared_place - 1]) == _rank_key(seat):
			shared_place -= 1
		result[seat] = rules.placement_points[mini(shared_place, rules.placement_points.size() - 1)]
	return result


## Seats with the most points; empty when the table sank.
func winners() -> Array:
	var scores := points()
	var best := 0
	for score in scores:
		best = maxi(best, score)
	var result: Array = []
	if best > 0:
		for seat in seat_count:
			if scores[seat] == best:
				result.append(seat)
	return result


func vouchers_of(target: int) -> Array:
	var result: Array = []
	for seat in seat_count:
		if vouches[seat] == target:
			result.append(seat)
	return result


## Everything `seat` may know right now: the public table plus its own secrets.
func view_for(seat: int) -> Dictionary:
	var declarations_open := phase > Phase.DECLARE
	var contributions_open := phase > Phase.CONTRIBUTE
	var my_transfers: Array = []
	for t: Dictionary in _transfers:
		if t["from"] == seat or t["to"] == seat:
			my_transfers.append(t.duplicate())
	var past_incomes := PackedInt32Array()
	for secret: Dictionary in _secrets:
		past_incomes.append((secret["incomes"] as PackedInt32Array)[seat])
	return {
		"seat": seat,
		"seat_count": seat_count,
		"round": round_index,
		"round_count": rules.round_count,
		"auditor": auditor(),
		"phase": phase,
		"total_income": total_income(),
		"installment_due": installment_due(),
		"carry": carry,
		"declarations": declarations.duplicate() if declarations_open else PackedInt32Array(),
		"missing": missing() if declarations_open else 0,
		"vouches": vouches.duplicate(),
		"minimums": minimums.duplicate(),
		"contributions": contributions.duplicate() if contributions_open else PackedInt32Array(),
		"audit": _audit.duplicate(),
		"accessories": accessories.duplicate(true),
		"total_contributed": total_contributed.duplicate(),
		"history": history.duplicate(true),
		"ious": ious.duplicate(true),
		"my_income": incomes[seat],
		"my_declaration": declarations[seat],
		"my_cash": cash[seat],
		"my_past_incomes": past_incomes,
		"my_transfers": my_transfers,
	}


## Hesap Günü: every round's real incomes, cover-ups and transfers. Only once the match is over.
func reveal() -> Array[Dictionary]:
	assert(is_over(), "Hesap Günü comes at the end")
	var rounds: Array[Dictionary] = []
	for i in history.size():
		var entry := history[i].duplicate(true)
		entry.merge(_secrets[i].duplicate(true))
		rounds.append(entry)
	return rounds


## Pays from cash first, then by selling accessories at their price, cheapest first,
## with any change back to cash. Whatever is still missing joins the common debt, or,
## owed to a player under rules.unpaid_becomes_iou, becomes an IOU.
func _pay(from: int, to: int, amount: int) -> void:
	var paid := mini(amount, cash[from])
	cash[from] -= paid
	var owed := amount - paid
	var items: Array = accessories[from]
	items.sort_custom(func(a: int, b: int) -> bool: return rules.accessory_prices[a] < rules.accessory_prices[b])
	while owed > 0 and not items.is_empty():
		var price := rules.accessory_prices[items.pop_front()]
		var used := mini(price, owed)
		owed -= used
		paid += used
		cash[from] += price - used
	if to == TO_POT:
		pot += paid
	else:
		cash[to] += paid
	if owed > 0 and to != TO_POT and rules.unpaid_becomes_iou:
		ious.append({"from": from, "to": to, "amount": owed, "round": round_index})
	else:
		_unpaid += owed


## Straight from the income just dealt, before anyone can pass coins under the table:
## otherwise emptying your pocket into a friend's would dodge the minimum.
func _pay_minimums() -> void:
	for seat in seat_count:
		minimums[seat] = mini(minimum_for(declarations[seat]), cash[seat])
		cash[seat] -= minimums[seat]
		pot += minimums[seat]


func _close_installment() -> void:
	var due_now := installment_due()
	if pot >= due_now:
		carry = due_now - pot
	else:
		carry = ceili((due_now - pot) * rules.shortfall_interest)
	carry += _unpaid


func _rank_key(seat: int) -> Vector2i:
	return Vector2i(wealth(seat), total_contributed[seat])


func _is_seat(seat: int) -> bool:
	return seat >= 0 and seat < seat_count


func _filled(value: int) -> PackedInt32Array:
	var array := PackedInt32Array()
	array.resize(seat_count)
	array.fill(value)
	return array


static func _sum(values: PackedInt32Array) -> int:
	var total := 0
	for value in values:
		total += value
	return total
