extends Node
## Autoload "Session": the host-authoritative night at the table.
## The host owns the Night (core/night.gd) and the bots in empty seats. Every peer
## receives only its own seat's view plus the seat names, and sends intents
## (e.g. {"type": "declare", "amount": 4}) that the host checks against the rules.

signal view_changed(view: Dictionary)

const RULES: RulesConfig = preload("res://data/rules_v0_3.tres")
## Bots act one at a time, each after this long, so people can follow what happens.
## --bot-delay=0 makes them instant (tests).
const BOT_DELAY_SEC := 1.4
## Bots in empty seats get one of these at random. Bribes need talking, so no corrupt bots.
const BOT_KINDS := ["dürüst", "açgözlü", "kinci", "bedavacı"]
## A bot that takes over from someone who left plays it straight.
const REPLACEMENT_KIND := "dürüst"

## The local seat's latest view, cached so a scene that loads late can read it.
var view: Dictionary = {}
## Seat -> name shown at the table, bots included. Public.
var seat_names := PackedStringArray()
## Seats played by bots. Public.
var bot_seats: Array = []

var _night: Night  # host only
var _bots: Dictionary = {}  # host only: seat -> SeatBot
var _seat_to_peer: Dictionary = {}  # host only
var _bot_turn_pending := false


## Host only. `roster` holds the people (seats 0..n-1); `bot_kinds` fill the seats after them.
## A negative seed picks a random one; it is printed so a night can be replayed.
## Without `basic_first`, even the first match uses the full rules.
func host_begin(roster: Dictionary, bot_kinds: Array, night_seed: int = -1, basic_first: bool = true) -> void:
	reset()
	if night_seed < 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		night_seed = rng.seed & 0x7FFFFFFF
	print("Night seed: %d" % night_seed)
	var seat_count := roster.size() + bot_kinds.size()
	seat_names.resize(seat_count)
	for peer_id: int in roster:
		var seat: int = roster[peer_id]["seat"]
		_seat_to_peer[seat] = peer_id
		seat_names[seat] = roster[peer_id]["name"]
	for i in bot_kinds.size():
		var seat := roster.size() + i
		seat_names[seat] = "Bot %d" % (i + 1)
		_add_bot(seat, bot_kinds[i], night_seed)
	var rules := RULES
	if not basic_first:
		rules = RULES.duplicate()
		rules.basic_matches = 0
	_night = Night.new(rules, seat_count, night_seed, Time.get_ticks_msec())
	_changed()


## Host only: bots for the empty seats, chosen with the given RNG.
func pick_bot_kinds(count: int, rng: RandomNumberGenerator) -> Array:
	var kinds: Array = []
	for i in count:
		kinds.append(BOT_KINDS[rng.randi_range(0, BOT_KINDS.size() - 1)])
	return kinds


## Host only: someone left mid-night, a bot plays on in their seat.
func host_replace_with_bot(seat: int) -> void:
	if _night == null or not _seat_to_peer.has(seat):
		return
	_seat_to_peer.erase(seat)
	_add_bot(seat, REPLACEMENT_KIND, _night.night_seed)
	seat_names[seat] = "%s (bot)" % seat_names[seat]
	_night.add_event({"type": "replaced", "seat": seat})
	_changed()


## Host only: the full truth, for debugging and tests. Never send it anywhere.
func host_night() -> Night:
	return _night


## Sends an intent for the local seat; the host decides whether it counts.
func request(intent: Dictionary) -> void:
	if Network.is_host():
		_apply(Network.local_seat(), intent)
	else:
		_rpc_request.rpc_id(1, intent)


func reset() -> void:
	view = {}
	seat_names = PackedStringArray()
	bot_seats = []
	_night = null
	_bots.clear()
	_seat_to_peer.clear()
	_bot_turn_pending = false


func _process(_delta: float) -> void:
	if _night != null and _night.tick(Time.get_ticks_msec()):
		_changed()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request(intent: Dictionary) -> void:
	if not Network.is_host():
		return
	_apply(Network.seat_of(multiplayer.get_remote_sender_id()), intent)


func _apply(seat: int, intent: Dictionary) -> void:
	if _night == null or seat == -1 or _bots.has(seat):
		return
	if _night.apply(seat, intent):
		_changed()
	# Otherwise the intent breaks the rules (or came too late): ignored, the host stays authoritative.


func _add_bot(seat: int, kind: String, night_seed: int) -> void:
	_bots[seat] = SeatBot.new(kind, seat, RULES, night_seed)
	bot_seats.append(seat)
	bot_seats.sort()


func _changed() -> void:
	_push_all()
	_schedule_bots()


func _schedule_bots() -> void:
	if _bot_turn_pending or _night == null:
		return
	var bots_awaited := false
	for seat: int in _night.awaiting():
		bots_awaited = bots_awaited or _bots.has(seat)
	if not bots_awaited:
		return
	_bot_turn_pending = true
	var delay := float(CmdArgs.value("--bot-delay", str(BOT_DELAY_SEC)))
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	else:
		await get_tree().process_frame
	_bot_turn_pending = false
	if _night == null:
		return  # the night ended while we waited
	var acted := false
	for seat: int in _night.awaiting():
		if acted or not _bots.has(seat):
			continue
		for intent in (_bots[seat] as SeatBot).intents(_night.view_for(seat)):
			acted = _night.apply(seat, intent) or acted
	if acted:
		_changed()


func _push_all() -> void:
	var connected := multiplayer.get_peers()
	for seat: int in _seat_to_peer:
		var peer_id: int = _seat_to_peer[seat]
		var payload := {"view": _night.view_for(seat), "names": seat_names, "bots": bot_seats}
		if peer_id == multiplayer.get_unique_id():
			_receive(payload)
		elif peer_id in connected:
			# Not yet the case when several people leave at once: a bot takes their seat one by one.
			_receive.rpc_id(peer_id, payload)


@rpc("authority", "call_remote", "reliable")
func _receive(payload: Dictionary) -> void:
	view = payload["view"]
	seat_names = payload["names"]
	bot_seats = payload["bots"]
	view_changed.emit(view)
