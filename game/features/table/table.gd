extends Node3D
## Table scene: presentation only. Reads Session's cached views and sends intents
## back; every rule lives in core/ and runs on the host.

const MONKEY_SCENE: PackedScene = preload("res://features/table/monkey_placeholder.tscn")
const SEAT_RADIUS := 1.6
const EYE_HEIGHT := 1.35
## The camera sits a little behind the seat so the neighbours fit in view.
const CAMERA_BACK := 0.5
const LOOK_TARGET := Vector3(0, 0.8, 0)
## The meter uses the same scaling as the mouths, so "full" means a wide-open mouth.
const MIC_METER_GAIN := MonkeyPlaceholder.MOUTH_GAIN

var _monkeys: Dictionary = {}  # seat -> MonkeyPlaceholder
var _self_voice_playback: AudioStreamGeneratorPlayback

@onready var _seats_root: Node3D = $Seats
@onready var _camera: Camera3D = $Camera3D
@onready var _income_label: Label = %IncomeLabel
@onready var _table_label: Label = %TableLabel
@onready var _declare_spin: SpinBox = %DeclareSpin
@onready var _declare_button: Button = %DeclareButton
@onready var _new_round_button: Button = %NewRoundButton
@onready var _leave_button: Button = %LeaveButton
@onready var _voice_row: Control = %VoiceRow
@onready var _mic_toggle: CheckButton = %MicToggle
@onready var _loopback_toggle: CheckButton = %LoopbackToggle
@onready var _mic_meter: ProgressBar = %MicMeter
@onready var _incoming_voice_label: Label = %IncomingVoiceLabel
@onready var _self_voice: AudioStreamPlayer = $SelfVoice


func _ready() -> void:
	_build_seats()
	Session.public_state_changed.connect(_on_public_state_changed)
	Session.private_view_changed.connect(_on_private_view_changed)
	_declare_button.pressed.connect(_on_declare_pressed)
	_new_round_button.visible = Network.is_host()
	_new_round_button.pressed.connect(Session.host_new_round)
	_leave_button.pressed.connect(Network.leave)
	_setup_voice()
	# Data may have arrived while this scene was loading; Session keeps the latest copy.
	_on_public_state_changed(Session.public_state)
	_on_private_view_changed(Session.private_view)


func _build_seats() -> void:
	var my_seat := Network.local_seat()
	for peer_id: int in Network.roster:
		var info: Dictionary = Network.roster[peer_id]
		var seat: int = info["seat"]
		var floor_position := _seat_position(seat)
		if seat == my_seat:
			# First person: we sit here, so we see the table instead of our own monkey.
			_camera.position = floor_position * (1.0 + CAMERA_BACK / SEAT_RADIUS) + Vector3.UP * EYE_HEIGHT
			_camera.look_at(LOOK_TARGET)
			continue
		var monkey := MONKEY_SCENE.instantiate() as MonkeyPlaceholder
		_seats_root.add_child(monkey)
		monkey.position = floor_position
		monkey.look_at(Vector3.ZERO)
		monkey.set_player_name(info["name"])
		_monkeys[seat] = monkey


func _setup_voice() -> void:
	_voice_row.visible = VoiceChat.is_available()
	_loopback_toggle.visible = VoiceChat.is_available()
	_incoming_voice_label.visible = VoiceChat.is_available()
	if not VoiceChat.is_available():
		return
	for seat: int in _monkeys:
		_monkeys[seat].setup_voice(VoiceChat.sample_rate())
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = VoiceChat.sample_rate()
	generator.buffer_length = MonkeyPlaceholder.VOICE_BUFFER_SECONDS
	_self_voice.stream = generator
	_self_voice.play()
	_self_voice_playback = _self_voice.get_stream_playback()
	_mic_toggle.button_pressed = VoiceChat.mic_enabled
	_loopback_toggle.button_pressed = VoiceChat.loopback
	_mic_toggle.toggled.connect(func(on: bool) -> void: VoiceChat.mic_enabled = on)
	_loopback_toggle.toggled.connect(func(on: bool) -> void: VoiceChat.loopback = on)
	VoiceChat.voice_received.connect(_on_voice_received)


func _process(_delta: float) -> void:
	if _voice_row.visible:
		_mic_meter.value = clampf(VoiceChat.own_level * MIC_METER_GAIN, 0.0, 1.0)
		_incoming_voice_label.text = _incoming_voice_text()


## e.g. "Gelen ses: Gonc 0.12 · Abdulalim — · Ulas —" ("—" = nothing in the last second).
func _incoming_voice_text() -> String:
	var parts := PackedStringArray()
	for peer_id: int in Network.roster:
		if peer_id == multiplayer.get_unique_id():
			continue
		var level := VoiceChat.incoming_level(peer_id)
		var shown := "—" if level < 0.0 else "%.2f" % level
		parts.append("%s %s" % [Network.roster[peer_id]["name"], shown])
	return "Gelen ses: " + " · ".join(parts)


func _on_voice_received(peer_id: int, frames: PackedVector2Array, level: float) -> void:
	if peer_id == multiplayer.get_unique_id():
		# Loopback test: our own voice, played without position.
		if _self_voice_playback.get_frames_available() >= frames.size():
			_self_voice_playback.push_buffer(frames)
		return
	var monkey: MonkeyPlaceholder = _monkeys.get(Network.seat_of(peer_id))
	if monkey != null:
		monkey.push_voice(frames, level)


func _seat_position(seat: int) -> Vector3:
	var angle := TAU * seat / Session.RULES.max_players
	return Vector3(sin(angle), 0, cos(angle)) * SEAT_RADIUS


func _on_public_state_changed(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		_table_label.text = "Masa hazırlanıyor…"
		return
	var revealed := snapshot.has("declarations")
	var declared: Array = snapshot["declared"]
	for seat: int in _monkeys:
		var status := "düşünüyor…"
		if revealed:
			status = "beyan: %d" % snapshot["declarations"][seat]
		elif declared[seat]:
			status = "beyanını verdi"
		_monkeys[seat].set_status(status)
	var lines := PackedStringArray(["Tur %d · Masaya dağıtılan toplam: %d" % [snapshot["round"], snapshot["total_income"]]])
	if revealed:
		lines.append(_missing_text(snapshot["missing"]))
	else:
		lines.append("Beyanlar bekleniyor (%d/%d)…" % [declared.count(true), declared.size()])
	_table_label.text = "\n".join(lines)
	_declare_spin.max_value = snapshot["total_income"]
	_declare_button.disabled = revealed
	# The private panel's "(will be revealed)" note depends on the public state.
	_on_private_view_changed(Session.private_view)


func _on_private_view_changed(view: Dictionary) -> void:
	if view.is_empty():
		_income_label.text = "Gelir bekleniyor…"
		return
	var text := "Gelirin: %d jeton (bunu sadece sen görüyorsun)" % view["income"]
	if view["declaration"] != TableState.NOT_DECLARED:
		text += "\nSenin beyanın: %d" % view["declaration"]
		if not Session.public_state.has("declarations"):
			text += " (herkes beyan edince açılacak)"
	_income_label.text = text


static func _missing_text(missing: int) -> String:
	if missing > 0:
		return "KAYIP JETON: %d" % missing
	if missing < 0:
		return "BEYAN FAZLASI: %d (biri aldığından fazlasını beyan etti)" % -missing
	return "Kayıp jeton yok. Herkes doğru söylüyor… ya da öyle görünüyor."


func _on_declare_pressed() -> void:
	Session.request_declare(int(_declare_spin.value))
