class_name PeerFactory
extends RefCounted
## The only place that knows which transports exist. Everything else talks to
## MultiplayerPeer, so LAN (ENet) and Steam games share all the game code.

const DEFAULT_PORT := 7777
## SteamMultiplayerPeer's virtual port; host and clients must use the same one.
const STEAM_VIRTUAL_PORT := 0


static func create_enet_host(port: int, max_clients: int) -> MultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	if err != OK:
		push_error("Could not host on port %d: %s" % [port, error_string(err)])
		return null
	return peer


static func create_enet_client(address: String, port: int) -> MultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Could not connect to %s:%d: %s" % [address, port, error_string(err)])
		return null
	return peer


## Created dynamically (not SteamMultiplayerPeer.new()) so this file compiles without GodotSteam.
static func create_steam_host() -> MultiplayerPeer:
	var peer := ClassDB.instantiate("SteamMultiplayerPeer") as MultiplayerPeer
	var err: Error = peer.call("create_host", STEAM_VIRTUAL_PORT)
	if err != OK:
		push_error("Could not host a Steam game: %s" % error_string(err))
		return null
	return peer


static func create_steam_client(host_steam_id: int) -> MultiplayerPeer:
	var peer := ClassDB.instantiate("SteamMultiplayerPeer") as MultiplayerPeer
	var err: Error = peer.call("create_client", host_steam_id, STEAM_VIRTUAL_PORT)
	if err != OK:
		push_error("Could not connect to Steam user %d: %s" % [host_steam_id, error_string(err)])
		return null
	return peer
