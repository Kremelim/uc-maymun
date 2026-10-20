extends TestSuite

const SteamServiceScript := preload("res://net/steam_service.gd")


func test_steam_constants_match_the_extension() -> void:
	# steam_service.gd copies these values so it compiles without GodotSteam;
	# this catches a GodotSteam upgrade that changes them.
	if not Engine.has_singleton("Steam"):
		failures.append("GodotSteam is not loaded (is game/addons/godotsteam present and pulled with LFS?)")
		return
	var steam := Engine.get_singleton("Steam")
	var ours := {
		"STEAM_API_INIT_RESULT_OK": SteamServiceScript.STEAM_API_INIT_RESULT_OK,
		"STEAM_API_INIT_RESULT_NO_STEAM_CLIENT": SteamServiceScript.STEAM_API_INIT_RESULT_NO_STEAM_CLIENT,
		"STEAM_API_INIT_RESULT_VERSION_MISMATCH": SteamServiceScript.STEAM_API_INIT_RESULT_VERSION_MISMATCH,
		"LOBBY_TYPE_FRIENDS_ONLY": SteamServiceScript.LOBBY_TYPE_FRIENDS_ONLY,
		"CHAT_ROOM_ENTER_RESPONSE_SUCCESS": SteamServiceScript.CHAT_ROOM_ENTER_RESPONSE_SUCCESS,
	}
	for constant: String in ours:
		assert_eq(ours[constant], steam.get(constant), constant)


func test_steam_multiplayer_peer_is_available() -> void:
	assert_true(ClassDB.class_exists("SteamMultiplayerPeer"), "SteamMultiplayerPeer class")
	for method: String in ["create_host", "create_client"]:
		assert_true(ClassDB.class_has_method("SteamMultiplayerPeer", method), "SteamMultiplayerPeer.%s" % method)


func test_lobby_from_launch_args() -> void:
	assert_eq(SteamServiceScript.lobby_from_launch_args(PackedStringArray(["+connect_lobby", "109775241"])), 109775241, "lobby id")
	assert_eq(SteamServiceScript.lobby_from_launch_args(PackedStringArray(["--path", "game"])), 0, "no lobby argument")
	assert_eq(SteamServiceScript.lobby_from_launch_args(PackedStringArray(["+connect_lobby"])), 0, "missing id")
	assert_eq(SteamServiceScript.lobby_from_launch_args(PackedStringArray(["+connect_lobby", "abc"])), 0, "not a number")
