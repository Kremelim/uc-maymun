extends Control
## Spike lobby: host a table or join one on the local network.

@onready var _name_edit: LineEdit = %NameEdit
@onready var _address_edit: LineEdit = %AddressEdit
@onready var _host_button: Button = %HostButton
@onready var _join_button: Button = %JoinButton
@onready var _start_button: Button = %StartButton
@onready var _players_label: Label = %PlayersLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_start_button.pressed.connect(Network.start_game)
	Network.roster_changed.connect(_on_roster_changed)
	Network.connection_failed.connect(_set_status)
	_name_edit.text = CmdArgs.value("--name", _name_edit.text)
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
	if Network.host_game(_name_edit.text, _port()):
		_set_status("Masa kuruldu. Arkadaşların %d portundan bağlanabilir." % _port())
	_refresh()


func _on_join_pressed() -> void:
	if Network.join_game(_address_edit.text.strip_edges(), _port(), _name_edit.text):
		_set_status("Bağlanılıyor…")
		_host_button.disabled = true
		_join_button.disabled = true


func _on_roster_changed(_roster: Dictionary) -> void:
	_set_status("")
	_refresh()
	var auto_start := int(CmdArgs.value("--auto-start", "0"))
	if Network.is_host() and auto_start > 0 and Network.roster.size() >= auto_start:
		Network.start_game.call_deferred()


func _refresh() -> void:
	var at_table := not Network.roster.is_empty()
	_host_button.disabled = at_table
	_join_button.disabled = at_table
	_name_edit.editable = not at_table
	_address_edit.editable = not at_table
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


func _set_status(message: String) -> void:
	_status_label.text = message


func _port() -> int:
	return int(CmdArgs.value("--port", str(PeerFactory.DEFAULT_PORT)))


## With --win=N (0-3), tiles the window into a 2x2 grid so four instances fit on one screen.
func _place_window() -> void:
	var index := int(CmdArgs.value("--win", "-1"))
	if index < 0 or DisplayServer.get_name() == "headless":
		return
	var screen := DisplayServer.screen_get_usable_rect()
	var half := screen.size / 2
	DisplayServer.window_set_size(half)
	DisplayServer.window_set_position(screen.position + Vector2i(index % 2 * half.x, int(index / 2.0) * half.y))
