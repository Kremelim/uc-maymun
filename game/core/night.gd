class_name Night
extends RefCounted
## A night at the table: rules.matches_per_night matches between the same seats
## (docs/gdd/kurallar-v0.3.md, "Gece skoru"), plus the pacing the rules leave to the
## players: ready checks, the negotiation timer, and moving on between rounds and matches.
## Pure and seeded like MatchState. The host owns one; players act through apply()
## and may only see view_for(their seat). Time comes in through tick(), so tests control it.
##
## Intents are dictionaries, e.g. {"type": "declare", "amount": 4}:
## declare(amount), vouch(target, NONE takes it back), transfer(to, amount),
## contribute(extra), choose(target), decide(report), buy(item), ready.

const NONE := MatchState.NONE
## Each player's view carries this many of the latest events it may see.
const EVENTS_IN_VIEW := 40

var rules: RulesConfig
var seat_count: int
var night_seed: int
var match_index := 0
var current_match: MatchState
## Placement points summed over the night's finished matches.
var night_points := PackedInt32Array()
## Who is done with the current ready-check phase (negotiation, shop, between matches).
var ready: Array = []
var night_over := false

var _events: Array[Dictionary] = []  # {"id", "type", ..., "for": [] = everyone, else only those seats}
var _next_event_id := 0
var _now_msec := 0
var _deadline_msec := 0
var _entered := []  # [match_index, round, phase] whose entry steps have run


func _init(p_rules: RulesConfig, p_seat_count: int, p_night_seed: int, now_msec: int = 0) -> void:
	rules = p_rules
	seat_count = p_seat_count
	night_seed = p_night_seed
	_now_msec = now_msec
	night_points.resize(seat_count)
	_start_match(0)
	_advance()


## Whether match `index` of a night is played with the basic rules.
static func is_basic(p_rules: RulesConfig, index: int) -> bool:
	return index < p_rules.basic_matches


## The seed of match `index` of a night. Only the host may know it: with the seed,
## anyone could deal the cards again and read every income.
static func match_seed_of(p_night_seed: int, index: int) -> int:
	return p_night_seed + index


## Returns false and changes nothing when the rules do not allow the intent right now.
func apply(seat: int, intent: Dictionary) -> bool:
	if night_over or seat < 0 or seat >= seat_count:
		return false
	var m := current_match
	var ok := false
	match str(intent.get("type", "")):
		"declare":
			var first_time := m.phase == MatchState.Phase.DECLARE and m.declarations[seat] == NONE
			ok = m.declare(seat, int(intent.get("amount", NONE)))
			if ok and first_time:
				_event({"type": "declared", "seat": seat})
		"vouch":
			var target := int(intent.get("target", NONE))
			ok = m.phase == MatchState.Phase.NEGOTIATE and m.vouches[seat] != target and m.vouch(seat, target)
			if ok:
				_event({"type": "vouched", "seat": seat, "target": target})
		"transfer":
			var to := int(intent.get("to", NONE))
			var amount := int(intent.get("amount", 0))
			ok = m.transfer(seat, to, amount)
			if ok:
				_event({"type": "transfer", "from": seat, "to": to, "amount": amount}, [seat, to])
		"contribute":
			ok = m.contribute(seat, int(intent.get("extra", -1)))
			if ok:
				_event({"type": "contributed", "seat": seat})
		"choose":
			ok = seat == m.auditor() and m.choose_audit_target(int(intent.get("target", NONE)))
			if ok:
				_event({"type": "audit_target", "auditor": seat, "target": m.audit_target})
		"decide":
			ok = seat == m.auditor() and m.phase == MatchState.Phase.AUDIT_DECIDE
			if ok:
				_resolve_audit(bool(intent.get("report", true)))
		"buy":
			var item := int(intent.get("item", NONE))
			ok = m.buy(seat, item)
			if ok:
				_event({"type": "bought", "seat": seat, "item": item})
		"ready":
			ok = _in_ready_phase() and not ready[seat]
			if ok:
				ready[seat] = true
	if ok:
		_advance()
	return ok


## Moves the clock on. Returns true when that changed the table (the negotiation ran out).
func tick(now_msec: int) -> bool:
	_now_msec = now_msec
	if night_over or current_match.phase != MatchState.Phase.NEGOTIATE or _now_msec < _deadline_msec:
		return false
	_advance()
	return true


## Seats the table is waiting for right now.
func awaiting() -> Array:
	var m := current_match
	var seats: Array = []
	if night_over:
		return seats
	for seat in seat_count:
		var waiting := false
		match m.phase:
			MatchState.Phase.DECLARE:
				waiting = m.declarations[seat] == NONE
			MatchState.Phase.CONTRIBUTE:
				waiting = not m.has_contributed(seat)
			MatchState.Phase.AUDIT_CHOOSE, MatchState.Phase.AUDIT_DECIDE:
				waiting = seat == m.auditor()
			MatchState.Phase.NEGOTIATE, MatchState.Phase.SHOP, MatchState.Phase.MATCH_OVER:
				waiting = not ready[seat]
		if waiting:
			seats.append(seat)
	return seats


## For things that happen outside the rules, e.g. a bot taking over a seat.
func add_event(event: Dictionary) -> void:
	_event(event)


## The match view plus the night around it: what `seat` may know and nothing more.
func view_for(seat: int) -> Dictionary:
	var view := current_match.view_for(seat)
	view["match_index"] = match_index
	view["matches_per_night"] = rules.matches_per_night
	view["night_points"] = night_points.duplicate()
	view["ready"] = ready.duplicate()
	view["awaiting"] = awaiting()
	view["night_over"] = night_over
	view["seconds_left"] = -1
	if current_match.phase == MatchState.Phase.NEGOTIATE and not night_over:
		view["seconds_left"] = maxi(0, ceili((_deadline_msec - _now_msec) / 1000.0))
	var events: Array = []
	for event: Dictionary in _events:
		var audience: Array = event["for"]
		if audience.is_empty() or seat in audience:
			var shown := event.duplicate()
			shown.erase("for")
			events.append(shown)
	view["events"] = events.slice(maxi(0, events.size() - EVENTS_IN_VIEW))
	return view


func _start_match(index: int) -> void:
	match_index = index
	var first := MatchState.first_auditor_of(rules, index, seat_count)
	var basic := is_basic(rules, index)
	current_match = MatchState.new(rules, seat_count, match_seed_of(night_seed, index), first, basic)
	_event({"type": "match_started", "match": index, "basic": basic})
	_start_round()


func _start_round() -> void:
	current_match.start_round()
	_event({"type": "round_started", "round": current_match.round_index, "auditor": current_match.auditor()})


func _resolve_audit(report: bool) -> void:
	var m := current_match
	var due := m.installment_due()
	m.resolve_audit(report)
	var audit := m.audit_outcome()
	_event({"type": "audit_result", "auditor": m.auditor(), "target": audit["target"], "caught": audit["caught"],
		"difference": audit["difference"]})
	_event({"type": "installment", "due": due, "pot": m.pot, "carry": m.carry})


## Runs the steps the table takes on its own, until it needs a player again.
func _advance() -> void:
	while not night_over:
		var m := current_match
		var here := [match_index, m.round_index, m.phase]
		if here != _entered:
			_entered = here
			_on_enter(m.phase)
		if m.phase == MatchState.Phase.NEGOTIATE and (_all_ready() or _now_msec >= _deadline_msec):
			m.end_negotiation()
		elif m.phase == MatchState.Phase.SHOP and (_all_ready() or not m.shop_open()):
			m.end_round()
			if not m.is_over():
				_start_round()
		elif m.phase == MatchState.Phase.MATCH_OVER and _all_ready():
			if match_index + 1 < rules.matches_per_night:
				_start_match(match_index + 1)
			else:
				night_over = true
				_event({"type": "night_over", "night_points": night_points.duplicate()})
		else:
			return


func _on_enter(phase: int) -> void:
	var m := current_match
	_clear_ready()
	match phase:
		MatchState.Phase.NEGOTIATE:
			_deadline_msec = _now_msec + rules.negotiation_seconds * 1000
			_event({"type": "declarations_revealed", "missing": m.missing()})
		MatchState.Phase.AUDIT_CHOOSE:
			_event({"type": "contributions_revealed", "pot": m.pot, "due": m.installment_due()})
		MatchState.Phase.MATCH_OVER:
			var points := m.points()
			for seat in seat_count:
				night_points[seat] += points[seat]
			_event({"type": "match_over", "match": match_index, "succeeded": m.succeeded(), "points": points})


func _in_ready_phase() -> bool:
	return current_match.phase in [MatchState.Phase.NEGOTIATE, MatchState.Phase.SHOP, MatchState.Phase.MATCH_OVER]


func _all_ready() -> bool:
	return not ready.has(false)


func _clear_ready() -> void:
	ready.clear()
	ready.resize(seat_count)
	ready.fill(false)


func _event(event: Dictionary, audience: Array = []) -> void:
	event["id"] = _next_event_id
	event["for"] = audience
	_next_event_id += 1
	_events.append(event)
