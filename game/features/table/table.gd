extends Node3D
## Table scene: presentation only. Reads Session's cached views and sends intents
## back; every rule lives in core/ and runs on the host.

const MONKEY_SCENE: PackedScene = preload("res://features/table/monkey_placeholder.tscn")
const SEAT_RADIUS := 1.6
const EYE_HEIGHT := 1.35
const LOOK_TARGET := Vector3(0, 0.8, 0)

var _monkeys: Dictionary = {}  # seat -> MonkeyPlaceholder

@onready var _seats_root: Node3D = $Seats
@onready var _camera: Camera3D = $Camera3D
@onready var _income_label: Label = %IncomeLabel
@onready var _table_label: Label = %TableLabel
@onready var _declare_spin: SpinBox = %DeclareSpin
@onready var _declare_button: Button = %DeclareButton
@onready var _new_round_button: Button = %NewRoundButton
@onready var _leave_button: Button = %LeaveButton


func _ready() -> void:
	_build_seats()
	Session.public_state_changed.connect(_on_public_state_changed)
	Session.private_view_changed.connect(_on_private_view_changed)
	_declare_button.pressed.connect(_on_declare_pressed)
	_new_round_button.visible = Network.is_host()
	_new_round_button.pressed.connect(Session.host_new_round)
	_leave_button.pressed.connect(Network.leave)
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
			_camera.position = floor_position + Vector3.UP * EYE_HEIGHT
			_camera.look_at(LOOK_TARGET)
			continue
		var monkey := MONKEY_SCENE.instantiate() as MonkeyPlaceholder
		_seats_root.add_child(monkey)
		monkey.position = floor_position
		monkey.look_at(Vector3.ZERO)
		monkey.set_player_name(info["name"])
		_monkeys[seat] = monkey


func _seat_position(seat: int) -> Vector3:
	var angle := TAU * seat / Session.RULES.max_players
	return Vector3(sin(angle), 0, cos(angle)) * SEAT_RADIUS


func _on_public_state_changed(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		_table_label.text = "Masa hazırlanıyor…"
		return
	var declarations: PackedInt32Array = snapshot["declarations"]
	for seat: int in _monkeys:
		_monkeys[seat].set_declaration(declarations[seat])
	var lines := PackedStringArray(["Tur %d · Masaya dağıtılan toplam: %d" % [snapshot["round"], snapshot["total_income"]]])
	var my_seat := Network.local_seat()
	if my_seat >= 0 and declarations[my_seat] != TableState.NOT_DECLARED:
		lines.append("Senin beyanın: %d" % declarations[my_seat])
	if snapshot.has("missing"):
		lines.append("KAYIP JETON: %d" % snapshot["missing"])
	else:
		lines.append("Beyanlar bekleniyor…")
	_table_label.text = "\n".join(lines)
	_declare_spin.max_value = snapshot["total_income"]


func _on_private_view_changed(view: Dictionary) -> void:
	if view.is_empty():
		_income_label.text = "Gelir bekleniyor…"
		return
	_income_label.text = "Gelirin: %d jeton (bunu sadece sen görüyorsun)" % view["income"]


func _on_declare_pressed() -> void:
	Session.request_declare(int(_declare_spin.value))
