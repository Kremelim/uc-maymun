extends Node
## Autoload "Session": the host-authoritative match.
## The host owns the TableState. Each client receives the public snapshot plus
## its own private view, and sends intents (e.g. "declare 2") that the host validates.

signal public_state_changed(snapshot: Dictionary)
signal private_view_changed(view: Dictionary)

const RULES: RulesConfig = preload("res://data/rules_v0_3.tres")

## Latest data this peer is allowed to see. Cached so a scene that loads late can read it.
var public_state: Dictionary = {}
var private_view: Dictionary = {}

var _state: TableState  # host only
var _rng := RandomNumberGenerator.new()
var _seat_to_peer: Dictionary = {}  # host only


## Host only. A negative seed picks a random one; it is printed so bugs can be replayed.
func host_begin(roster: Dictionary, match_seed: int = -1) -> void:
	_seat_to_peer.clear()
	for peer_id: int in roster:
		_seat_to_peer[roster[peer_id]["seat"]] = peer_id
	if match_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = match_seed
	print("Match seed: %d" % _rng.seed)
	_state = TableState.new(RULES, roster.size())
	host_new_round()


func host_new_round() -> void:
	if not Network.is_host() or _state == null:
		return
	_state.deal(_rng)
	_push_all()


## Host only: the full truth, for debugging and tests. Never send it anywhere.
func host_state() -> TableState:
	return _state


func request_declare(amount: int) -> void:
	if Network.is_host():
		_apply_declare(multiplayer.get_unique_id(), amount)
	else:
		_rpc_request_declare.rpc_id(1, amount)


func reset() -> void:
	public_state = {}
	private_view = {}
	_state = null
	_seat_to_peer.clear()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_declare(amount: int) -> void:
	if not Network.is_host():
		return
	_apply_declare(multiplayer.get_remote_sender_id(), amount)


func _apply_declare(peer_id: int, amount: int) -> void:
	if _state == null:
		return
	var seat := Network.seat_of(peer_id)
	if seat == -1 or not _state.declare(seat, amount):
		return  # Invalid intent: ignored, the host's state stays authoritative.
	_push_private(seat)
	_push_public()


func _push_all() -> void:
	for seat: int in _seat_to_peer:
		_push_private(seat)
	_push_public()


func _push_private(seat: int) -> void:
	var peer_id: int = _seat_to_peer[seat]
	var view := _state.private_view(seat)
	if peer_id == multiplayer.get_unique_id():
		_receive_private(view)
	else:
		_receive_private.rpc_id(peer_id, view)


func _push_public() -> void:
	_receive_public.rpc(_state.public_snapshot())


@rpc("authority", "call_local", "reliable")
func _receive_public(snapshot: Dictionary) -> void:
	public_state = snapshot
	public_state_changed.emit(snapshot)


@rpc("authority", "call_remote", "reliable")
func _receive_private(view: Dictionary) -> void:
	private_view = view
	private_view_changed.emit(view)
