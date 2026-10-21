class_name SimBot
extends RefCounted
## A player type for the simulator: a few parameters rather than cleverness, so
## we can ask "what happens at a table with two of these". A bot only reads the
## view MatchState gives its seat, like a real player.

const NONE := MatchState.NONE
## Below this suspicion a player looks trustworthy enough to vouch for.
const VOUCH_THRESHOLD := 1.0
## Coins kept back when shopping before the last round, for the next contribution.
const SHOPPING_RESERVE := 4

var kind := ""
## The rules this bot plays by; set by the runner, which may be testing a variant.
var rules: RulesConfig
## Share of the income hidden in a normal round, and in the round it audits (when nobody can audit it).
var hide_ratio := 0.0
var hide_ratio_as_auditor := 0.0
## 1 pays the share of the installment its declaration implies; less free-rides.
var share_factor := 1.0
## Share (0..1) of the table's unexplained gap it is willing to chip in for.
var cover_gap := 1.0
var corruptible := false
var offers_bribes := false
## In the last round, sinks the table when it believes it cannot win.
var spiteful := false
var buys_accessories := true
var vouches := true
var rng := RandomNumberGenerator.new()
## Set when a spiteful bot withheld its last contribution to sink the table.
var sank_the_table := false


static func preset(preset_kind: String) -> SimBot:
	var bot := SimBot.new()
	bot.kind = preset_kind
	match preset_kind:
		"dürüst":
			pass
		"açgözlü":
			bot.hide_ratio = 0.5
			bot.hide_ratio_as_auditor = 1.0
			bot.cover_gap = 0.5
		"fırsatçı":
			bot.hide_ratio_as_auditor = 1.0
		"yolsuz":
			bot.hide_ratio = 0.5
			bot.hide_ratio_as_auditor = 1.0
			bot.cover_gap = 0.5
			bot.corruptible = true
			bot.offers_bribes = true
		"kinci":
			bot.hide_ratio = 0.5
			bot.hide_ratio_as_auditor = 1.0
			bot.cover_gap = 0.5
			bot.spiteful = true
		"bedavacı":
			bot.share_factor = 0.6
			bot.cover_gap = 0.0
		_:
			push_error("Unknown bot preset: %s" % preset_kind)
	return bot


func declare(view: Dictionary) -> int:
	var ratio := hide_ratio_as_auditor if view["auditor"] == view["seat"] else hide_ratio
	var income: int = view["my_income"]
	return income - roundi(income * ratio)


func vouch_target(view: Dictionary) -> int:
	if not vouches or view["auditor"] == view["seat"]:
		return NONE
	var best := NONE
	var best_suspicion := VOUCH_THRESHOLD
	for seat in int(view["seat_count"]):
		if seat == view["seat"] or seat == view["auditor"]:
			continue
		var level := suspicion(view, seat)
		if level < best_suspicion:
			best = seat
			best_suspicion = level
	return best


## What it adds on top of the minimum it already paid. It aims for its share of the
## installment as implied by what it declared, plus part of the gap the table's
## declarations leave open.
func contribution(view: Dictionary) -> int:
	var due: int = view["installment_due"]
	var total: int = view["total_income"]
	if due <= 0 or total <= 0:
		return 0
	var own_share := float(due) * int(view["my_declaration"]) / total
	var gap := float(due) * maxi(int(view["missing"]), 0) / total
	var aim := ceili(own_share * share_factor + gap * cover_gap / int(view["seat_count"]))
	var extra := maxi(aim - (view["minimums"] as PackedInt32Array)[view["seat"]], 0)
	if spiteful and _is_last_round(view) and not _expects_to_win(view, extra):
		extra = 0
		sank_the_table = true
	return mini(extra, view["my_cash"])


func choose_audit_target(view: Dictionary) -> int:
	var best := NONE
	var best_suspicion := -1.0
	for seat in int(view["seat_count"]):
		if seat == view["seat"]:
			continue
		var level := suspicion(view, seat)
		if level > best_suspicion:
			best = seat
			best_suspicion = level
	return best


## As auditor who caught a lie: the bribe that beats reporting it, or -1 if it reports anyway.
func cover_up_price(fine: int, compensation: int) -> int:
	if not corruptible:
		return -1
	# Covering up earns the bribe minus the compensation it must pay; reporting earns the fine.
	return fine + compensation + 1


## As the caught liar: pays `price` only if that is cheaper than being reported.
func accepts_cover_up(price: int, loss_if_reported: int, compensation: int, cash: int) -> bool:
	return offers_bribes and price <= cash and price - compensation < loss_if_reported


## Accessory indices to buy, most expensive first. Before the last round it never spends
## more than its declarations can explain, so its accessories do not give it away.
func shopping_list(view: Dictionary) -> Array:
	var prices := rules.accessory_prices
	var list: Array = []
	if not buys_accessories:
		return list
	var budget: int = view["my_cash"]
	if not _is_last_round(view):
		budget = mini(budget - SHOPPING_RESERVE, _explainable_cash(view, view["seat"]) - SHOPPING_RESERVE)
	var by_price: Array = range(prices.size())
	by_price.sort_custom(func(a: int, b: int) -> bool: return prices[a] > prices[b])
	for item: int in by_price:
		while prices[item] <= budget:
			list.append(item)
			budget -= prices[item]
	return list


## How much a seat looks like it is hiding, from public information only.
func suspicion(view: Dictionary, seat: int) -> float:
	var level := 0.0
	# Spending that its declarations cannot explain is the strongest tell.
	var unexplained := _accessory_spend(view, seat) - _explainable_cash(view, seat, false)
	level += maxf(unexplained, 0.0)
	# A low declaration this round compared with an even split of the total.
	var declarations: PackedInt32Array = view["declarations"]
	if not declarations.is_empty():
		var even_share := float(view["total_income"]) / int(view["seat_count"])
		level += maxf(even_share - declarations[seat], 0.0) * 0.3
	for past: Dictionary in view["history"]:
		var audit: Dictionary = past["audit"]
		if audit.get("target", NONE) == seat and audit.get("caught", false):
			level += 2.0
	return level + rng.randf() * 0.5


## Cash a seat could have from what it declared, minus contributions and (optionally) purchases.
func _explainable_cash(view: Dictionary, seat: int, minus_spend: bool = true) -> int:
	var declared := 0
	for past: Dictionary in view["history"]:
		declared += (past["declarations"] as PackedInt32Array)[seat]
	var current: PackedInt32Array = view["declarations"]
	if not current.is_empty():
		declared += current[seat]
	var result := declared - int((view["total_contributed"] as PackedInt32Array)[seat])
	if minus_spend:
		result -= _accessory_spend(view, seat)
	return result


func _accessory_spend(view: Dictionary, seat: int) -> int:
	var spend := 0
	for item: int in view["accessories"][seat]:
		spend += rules.accessory_prices[item]
	return spend


## Rough guess: does it end richer than everyone else, from what others declared and spent?
func _expects_to_win(view: Dictionary, my_extra: int) -> bool:
	var mine := int(view["my_cash"]) - my_extra + _accessory_value(view, view["seat"])
	for seat in int(view["seat_count"]):
		if seat != view["seat"]:
			var theirs := _explainable_cash(view, seat) + _accessory_value(view, seat)
			if theirs > mine:
				return false
	return true


func _accessory_value(view: Dictionary, seat: int) -> int:
	var value := 0
	for item: int in view["accessories"][seat]:
		value += rules.accessory_values[item]
	return value


func _is_last_round(view: Dictionary) -> bool:
	return view["round"] == int(view["round_count"]) - 1
