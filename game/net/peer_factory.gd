class_name PeerFactory
extends RefCounted
## The only place that knows which transport we use. Everything else talks to
## MultiplayerPeer, so moving from ENet to Steam (SteamMultiplayerPeer) happens here.

const DEFAULT_PORT := 7777


static func create_host(port: int, max_clients: int) -> MultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	if err != OK:
		push_error("Could not host on port %d: %s" % [port, error_string(err)])
		return null
	return peer


static func create_client(address: String, port: int) -> MultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Could not connect to %s:%d: %s" % [address, port, error_string(err)])
		return null
	return peer
