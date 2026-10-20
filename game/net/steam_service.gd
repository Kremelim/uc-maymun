extends Node
## Autoload "SteamService": Steam start-up, lobbies and invites.
## Optional by design: without the GodotSteam extension, a running Steam client,
## or in headless tests, `available` stays false and the game offers LAN play.
## Steam is reached through Engine.get_singleton() rather than the `Steam` global,
## so these scripts still compile when the extension failed to load.

signal lobby_ready(lobby_id: int)
signal lobby_entered(lobby_id: int, owner_steam_id: int)
signal lobby_failed(reason: String)

## Valve's public test app (Spacewar) until we have our own App ID from Steam Direct.
const APP_ID := 480
## Steamworks values, checked against the extension by tests/unit/test_steam_service.gd.
const STEAM_API_INIT_RESULT_OK := 0
const STEAM_API_INIT_RESULT_NO_STEAM_CLIENT := 2
const STEAM_API_INIT_RESULT_VERSION_MISMATCH := 3
const LOBBY_TYPE_FRIENDS_ONLY := 1
const CHAT_ROOM_ENTER_RESPONSE_SUCCESS := 1
const RESULT_OK := 1  # k_EResultOK, as passed to lobby_created

var available := false
var status_message := ""
var persona_name := ""
var steam_id := 0
var lobby_id := 0

var _steam: Object


func _ready() -> void:
	set_process(false)
	if DisplayServer.get_name() == "headless" or CmdArgs.has_flag("--no-steam"):
		status_message = "Steam kullanılmıyor."
		return
	if not Engine.has_singleton("Steam"):
		status_message = "GodotSteam eklentisi yüklenemedi (git lfs install yapıldı mı?)."
		return
	_steam = Engine.get_singleton("Steam")
	var result: Dictionary = _steam.steamInitEx(APP_ID, false)
	if result["status"] != STEAM_API_INIT_RESULT_OK:
		status_message = _init_failure_message(result["status"], result["verbal"])
		push_warning("Steam init failed: %s" % result)
		return
	available = true
	persona_name = _steam.getPersonaName()
	steam_id = _steam.getSteamID()
	status_message = "Steam: %s olarak bağlısın." % persona_name
	_steam.connect("lobby_created", _on_lobby_created)
	_steam.connect("lobby_joined", _on_lobby_joined)
	_steam.connect("join_requested", _on_join_requested)
	set_process(true)
	var launch_lobby := lobby_from_launch_args(OS.get_cmdline_args())
	if launch_lobby != 0:
		join_lobby.call_deferred(launch_lobby)


func _process(_delta: float) -> void:
	_steam.run_callbacks()


func create_lobby(max_members: int) -> void:
	_steam.createLobby(LOBBY_TYPE_FRIENDS_ONLY, max_members)


func join_lobby(id: int) -> void:
	_steam.joinLobby(id)


## Opens the Steam overlay's invite dialog. The overlay may not show up when the
## game runs from the Godot editor; joining with the lobby code works either way.
func invite_friends() -> void:
	if lobby_id != 0:
		_steam.activateGameOverlayInviteDialog(lobby_id)


func set_lobby_joinable(joinable: bool) -> void:
	if lobby_id != 0:
		_steam.setLobbyJoinable(lobby_id, joinable)


func leave_lobby() -> void:
	if lobby_id != 0:
		_steam.leaveLobby(lobby_id)
		lobby_id = 0


static func _init_failure_message(status: int, verbal: String) -> String:
	match status:
		STEAM_API_INIT_RESULT_NO_STEAM_CLIENT:
			return "Steam açık değil. Steam'i açıp oyunu yeniden başlat; şimdilik sadece yerel ağ var."
		STEAM_API_INIT_RESULT_VERSION_MISMATCH:
			return "Steam güncel değil. Güncelleyip oyunu yeniden başlat; şimdilik sadece yerel ağ var."
	return "Steam başlatılamadı (%s). Şimdilik sadece yerel ağ var." % verbal


## Accepting an invite while the game is closed starts it with "+connect_lobby <id>".
## With the test App ID 480 Steam starts Spacewar instead, so this matters later.
static func lobby_from_launch_args(args: PackedStringArray) -> int:
	var index := args.find("+connect_lobby")
	if index == -1 or index + 1 >= args.size() or not args[index + 1].is_valid_int():
		return 0
	return args[index + 1].to_int()


func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if result != RESULT_OK:
		lobby_failed.emit("Steam lobisi kurulamadı (kod %d)." % result)
		return
	lobby_id = new_lobby_id
	_steam.setLobbyJoinable(lobby_id, true)
	lobby_ready.emit(lobby_id)


func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_failed.emit("Lobiye girilemedi (kod %d)." % response)
		return
	lobby_id = joined_lobby_id
	var owner_id: int = _steam.getLobbyOwner(joined_lobby_id)
	# The host "joins" its own lobby too; its peer is created from lobby_ready instead.
	if owner_id != steam_id:
		lobby_entered.emit(joined_lobby_id, owner_id)


## Accepting an invite (or "Join game") in Steam while the game is running.
func _on_join_requested(requested_lobby_id: int, _friend_id: int) -> void:
	join_lobby(requested_lobby_id)
