extends Control
## Spike lobby: host or join a table through Steam, or on the local network for testing.

@onready var _name_edit: LineEdit = %NameEdit
@onready var _steam_status_label: Label = %SteamStatusLabel
@onready var _steam_section: Control = %SteamSection
@onready var _steam_host_button: Button = %SteamHostButton
@onready var _invite_button: Button = %InviteButton
@onready var _lobby_code_edit: LineEdit = %LobbyCodeEdit
@onready var _join_code_button: Button = %JoinCodeButton
@onready var _copy_code_button: Button = %CopyCodeButton
@onready var _address_edit: LineEdit = %AddressEdit
@onready var _host_button: Button = %HostButton
@onready var _join_button: Button = %JoinButton
@onready var _start_button: Button = %StartButton
@onready var _players_label: Label = %PlayersLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_steam_host_button.pressed.connect(_on_steam_host_pressed)
	_join_code_button.pressed.connect(_on_join_code_pressed)
	_invite_button.pressed.connect(SteamService.invite_friends)
	_copy_code_button.pressed.connect(func() -> void: DisplayServer.clipboard_set(str(SteamService.lobby_id)))
	_start_button.pressed.connect(Network.start_game)
	Network.roster_changed.connect(_on_roster_changed)
	Network.connection_failed.connect(_on_connection_failed)
	_steam_status_label.text = SteamService.status_message
	_steam_section.visible = SteamService.available
	var default_name := SteamService.persona_name if SteamService.available else ""
	_name_edit.text = CmdArgs.value("--name", default_name)
	_set_status(Network.last_message)
	_place_window()
	_refresh()
	# Dev shortcuts for multi-instance runs (docs/spike-m1.md) and the e2e test.
	if not Network.auto_connect_used:
		Network.auto_connect_used = true
		if CmdArgs.has_flag("--auto-host"):
			_on_host_pressed()
		elif CmdArgs.has_flag("--auto-join"):
			_on_join_pressed()


func _on_host_pressed() -> void:
	if Network.host_lan_game(_name_edit.text, _port()):
		_set_status("Masa kuruldu. Arkadaşların %d portundan bağlanabilir." % _port())
	_refresh()


func _on_join_pressed() -> void:
	if Network.join_lan_game(_address_edit.text.strip_edges(), _port(), _name_edit.text):
		_set_status("Bağlanılıyor…")
		_set_connect_buttons_disabled(true)


func _on_steam_host_pressed() -> void:
	Network.host_steam_game(_name_edit.text)
	_set_status("Steam lobisi kuruluyor…")
	_set_connect_buttons_disabled(true)


func _on_join_code_pressed() -> void:
	var code := _lobby_code_edit.text.strip_edges()
	if not code.is_valid_int():
		_set_status("Lobi kodu sadece rakamlardan oluşur.")
		return
	Network.join_steam_lobby(code.to_int(), _name_edit.text)
	_set_status("Steam lobisine giriliyor…")
	_set_connect_buttons_disabled(true)


func _on_connection_failed(reason: String) -> void:
	_set_status(reason)
	_refresh()


func _on_roster_changed(_roster: Dictionary) -> void:
	_set_status("")
	_refresh()
	var auto_start := int(CmdArgs.value("--auto-start", "0"))
	if Network.is_host() and auto_start > 0 and Network.roster.size() >= auto_start:
		Network.start_game.call_deferred()


func _refresh() -> void:
	var at_table := not Network.roster.is_empty()
	_set_connect_buttons_disabled(at_table)
	_name_edit.editable = not at_table
	_address_edit.editable = not at_table
	var hosting_steam := at_table and Network.is_host() and SteamService.lobby_id != 0
	_invite_button.visible = hosting_steam
	_copy_code_button.visible = hosting_steam
	_join_code_button.visible = not hosting_steam
	_lobby_code_edit.editable = not at_table
	if hosting_steam:
		_lobby_code_edit.text = str(SteamService.lobby_id)
	_start_button.visible = Network.is_host()
	_start_button.disabled = Network.roster.size() < Session.RULES.min_players
	if not at_table:
		_players_label.text = "Henüz bir masada değilsin."
		return
	var me := multiplayer.get_unique_id()
	var lines := PackedStringArray()
	for peer_id: int in Network.roster:
		var info: Dictionary = Network.roster[peer_id]
		var tags := ""
		if peer_id == 1:
			tags += " (host)"
		if peer_id == me:
			tags += " (sen)"
		lines.append("Koltuk %d: %s%s" % [info["seat"] + 1, info["name"], tags])
	_players_label.text = "\n".join(lines)
	get_window().title = "Üç Maymun — %s" % Network.roster[me]["name"] if Network.roster.has(me) else "Üç Maymun"


func _set_connect_buttons_disabled(disabled: bool) -> void:
	_host_button.disabled = disabled
	_join_button.disabled = disabled
	_steam_host_button.disabled = disabled
	_join_code_button.disabled = disabled


func _set_status(message: String) -> void:
	_status_label.text = message


func _port() -> int:
	return int(CmdArgs.value("--port", str(PeerFactory.DEFAULT_PORT)))


## With --win=N (0-3), tiles the window into a 2x2 grid so four instances fit on one screen.
## Skipped when the editor embeds the game, since the editor owns that window.
func _place_window() -> void:
	var index := int(CmdArgs.value("--win", "-1"))
	if index < 0 or DisplayServer.get_name() == "headless" or Engine.is_embedded_in_editor():
		return
	var screen := DisplayServer.screen_get_usable_rect()
	@warning_ignore("integer_division")  # whole pixels are what we want
	var cell_size := screen.size / 2
	var cell := screen.position + Vector2i(index % 2 * cell_size.x, int(index / 2.0) * cell_size.y)
	# Size and position apply to the content area, so leave room for the title bar and borders.
	var border := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	var inset := DisplayServer.window_get_position() - DisplayServer.window_get_position_with_decorations()
	DisplayServer.window_set_size(cell_size - border)
	DisplayServer.window_set_position(cell + inset)
