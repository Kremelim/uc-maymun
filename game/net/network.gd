extends Node
## Autoload "Network": connections and the lobby roster.
## The host is the authority: it assigns seats and starts the game; clients only ask.

signal roster_changed(roster: Dictionary)
signal connection_failed(reason: String)
signal disconnected(reason: String)

const LOBBY_SCENE := "res://features/lobby/lobby.tscn"
const TABLE_SCENE := "res://features/table/table.tscn"
const MAX_NAME_LENGTH := 16

## peer_id -> {"name": String, "seat": int}. The host syncs it, so it is identical on every peer.
var roster: Dictionary = {}
var game_in_progress := false
## Host's choice in the lobby: bots take the empty seats when the game starts.
var fill_with_bots := true
## Host's choice in the lobby: the night's first match uses the basic rules.
var basic_first_match := true
## Shown by the lobby after being sent back there (e.g. "the host left").
var last_message := ""
## --auto-host / --auto-join run once per launch, not every time the lobby reloads.
var auto_connect_used := false

var _is_host := false
var _hosting_via_steam := false
var _pending_name := ""


func _ready() -> void:
	# Clients talk only to the host: no client-to-client messages relayed through it.
	(multiplayer as SceneMultiplayer).server_relay = false
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	SteamService.lobby_ready.connect(_on_steam_lobby_ready)
	SteamService.lobby_entered.connect(_on_steam_lobby_entered)
	SteamService.lobby_failed.connect(_on_steam_lobby_failed)
	if CmdArgs.has_flag("--e2e"):
		var probe: Node = load("res://tests/e2e/e2e_probe.gd").new()
		probe.name = "E2EProbe"
		get_tree().root.add_child.call_deferred(probe)


func is_host() -> bool:
	return _is_host


func seat_of(peer_id: int) -> int:
	if not roster.has(peer_id):
		return -1
	return roster[peer_id]["seat"]


func local_seat() -> int:
	return seat_of(multiplayer.get_unique_id())


func host_lan_game(player_name: String, port: int) -> bool:
	var peer := PeerFactory.create_enet_host(port, Session.RULES.max_players - 1)
	if peer == null:
		connection_failed.emit("Port %d açılamadı." % port)
		return false
	_host_with(peer, player_name)
	return true


func join_lan_game(address: String, port: int, player_name: String) -> bool:
	var peer := PeerFactory.create_enet_client(address, port)
	if peer == null:
		connection_failed.emit("%s:%d adresine bağlanılamadı." % [address, port])
		return false
	_join_with(peer, player_name)
	return true


## Creates a friends-only Steam lobby; hosting starts once Steam confirms it (_on_steam_lobby_ready).
func host_steam_game(player_name: String) -> void:
	_pending_name = player_name
	_hosting_via_steam = true
	SteamService.create_lobby(Session.RULES.max_players)


## Joins by lobby code; invites accepted in Steam arrive through _on_steam_lobby_entered too.
func join_steam_lobby(lobby_id: int, player_name: String) -> void:
	_pending_name = player_name
	SteamService.join_lobby(lobby_id)


## How many bots would sit down if the game started now.
func bot_count() -> int:
	return Session.RULES.max_players - roster.size() if fill_with_bots else 0


func can_start() -> bool:
	return _is_host and not game_in_progress and roster.size() + bot_count() >= Session.RULES.min_players


## Host only. Seats are packed to 0..n-1 first so the rules engine sees contiguous seats;
## bots sit after the people.
func start_game() -> void:
	if not can_start():
		return
	game_in_progress = true
	SteamService.set_lobby_joinable(false)
	var peers: Array = roster.keys()
	peers.sort_custom(func(a: int, b: int) -> bool: return roster[a]["seat"] < roster[b]["seat"])
	for i in peers.size():
		roster[peers[i]]["seat"] = i
	_sync_roster.rpc(roster)
	_start_game.rpc()
	var night_seed := int(CmdArgs.value("--seed", "-1"))
	var kinds_rng := RandomNumberGenerator.new()
	kinds_rng.seed = night_seed if night_seed >= 0 else randi()
	var bot_kinds := Session.pick_bot_kinds(bot_count(), kinds_rng)
	var forced := CmdArgs.value("--bot-kinds").split(",", false)  # e.g. --bot-kinds=kinci,dürüst
	for i in mini(forced.size(), bot_kinds.size()):
		bot_kinds[i] = forced[i]
	Session.host_begin(roster, bot_kinds, night_seed, basic_first_match)


## Host only: everyone goes back to the lobby together, still connected.
func end_game(message: String) -> void:
	if _is_host and game_in_progress:
		_abort_game.rpc(message)


## Leaves the table (or stops hosting) and goes back to the lobby.
func leave(message: String = "") -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	SteamService.leave_lobby()
	_is_host = false
	_hosting_via_steam = false
	roster = {}
	game_in_progress = false
	last_message = message
	Session.reset()
	get_tree().change_scene_to_file(LOBBY_SCENE)


func _on_connected_to_server() -> void:
	_register.rpc_id(1, _pending_name)


@rpc("any_peer", "call_remote", "reliable")
func _register(player_name: String) -> void:
	if not _is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	if roster.has(sender):
		return
	var seat := _free_seat()
	if game_in_progress or seat == -1:
		_rejected.rpc_id(sender, "Masa dolu ya da oyun çoktan başladı.")
		return
	roster[sender] = {"name": _clean_name(player_name), "seat": seat}
	_sync_roster.rpc(roster)


@rpc("authority", "call_remote", "reliable")
func _rejected(reason: String) -> void:
	leave(reason)


@rpc("authority", "call_local", "reliable")
func _sync_roster(new_roster: Dictionary) -> void:
	roster = new_roster
	roster_changed.emit(roster)


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	game_in_progress = true
	get_tree().change_scene_to_file(TABLE_SCENE)


@rpc("authority", "call_local", "reliable")
func _abort_game(reason: String) -> void:
	game_in_progress = false
	if _is_host:
		SteamService.set_lobby_joinable(true)
	last_message = reason
	Session.reset()
	get_tree().change_scene_to_file(LOBBY_SCENE)


func _on_peer_disconnected(peer_id: int) -> void:
	# Deferred: when several peers drop in the same network poll, all of them are
	# gone by then, so we never send to a peer that is already disconnected.
	_handle_peer_left.call_deferred(peer_id)


func _handle_peer_left(peer_id: int) -> void:
	if not _is_host or not roster.has(peer_id):
		return
	var seat: int = roster[peer_id]["seat"]
	roster.erase(peer_id)
	_sync_roster.rpc(roster)
	if game_in_progress:
		Session.host_replace_with_bot(seat)  # the night goes on


func _on_connection_failed() -> void:
	leave("Bağlantı kurulamadı.")


func _on_server_disconnected() -> void:
	disconnected.emit("Host masadan kalktı.")
	leave("Host masadan kalktı.")


func _host_with(peer: MultiplayerPeer, player_name: String) -> void:
	multiplayer.multiplayer_peer = peer
	_is_host = true
	roster = {1: {"name": _clean_name(player_name), "seat": 0}}
	roster_changed.emit(roster)


func _join_with(peer: MultiplayerPeer, player_name: String) -> void:
	multiplayer.multiplayer_peer = peer
	_is_host = false
	_pending_name = _clean_name(player_name)


func _on_steam_lobby_ready(_lobby_id: int) -> void:
	if not _hosting_via_steam:
		return
	var peer := PeerFactory.create_steam_host()
	if peer == null:
		connection_failed.emit("Steam masası kurulamadı.")
		SteamService.leave_lobby()
		_hosting_via_steam = false
		return
	_host_with(peer, _pending_name)


func _on_steam_lobby_entered(_lobby_id: int, owner_steam_id: int) -> void:
	if not roster.is_empty():
		# Already at a table (e.g. accepted another invite mid-game): stay where we are.
		SteamService.leave_lobby()
		return
	var peer := PeerFactory.create_steam_client(owner_steam_id)
	if peer == null:
		connection_failed.emit("Steam masasına bağlanılamadı.")
		SteamService.leave_lobby()
		return
	# Invites accepted in Steam come without a typed name, so fall back to the Steam name.
	_join_with(peer, _pending_name if _pending_name != "" else SteamService.persona_name)


func _on_steam_lobby_failed(reason: String) -> void:
	_hosting_via_steam = false
	connection_failed.emit(reason)


func _free_seat() -> int:
	var taken: Array = []
	for info: Dictionary in roster.values():
		taken.append(info["seat"])
	for seat in Session.RULES.max_players:
		if seat not in taken:
			return seat
	return -1


func _clean_name(player_name: String) -> String:
	var cleaned := player_name.strip_edges().left(MAX_NAME_LENGTH)
	return cleaned if cleaned != "" else "Maymun"
