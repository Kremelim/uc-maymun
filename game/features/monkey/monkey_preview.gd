extends Node3D
## Looks at a monkey model in motion, at the table as in the game. Open
## features/monkey/monkey_preview.tscn, pick the model in the inspector (Body) and
## press F6. The keys are listed on screen.

@export var body: PackedScene = preload("res://assets/monkeys/test_monkey.glb")
@export var fur_tint := Color.WHITE
@export var toon := true

const TURN_SPEED := 1.5
## The camera looks at the monkey's chest from the front left, past the table's edge.
const LOOK_AT := Vector3(0, 0.85, -0.25)
const HELP := "1 yakalandı · 2 sevinç · 3 hayal kırıklığı · K konuş · A aksesuarlar · D denetçi şapkası · ← → döndür"

var _talking := false
var _accessories := false
var _auditor := false
var _time := 0.0

@onready var _monkey: Monkey = $Monkey
@onready var _help: Label = $Help


func _ready() -> void:
	_monkey.dress(body, fur_tint, toon)
	_monkey.set_player_name(body.resource_path.get_file())
	_help.text = HELP
	($Camera3D as Camera3D).look_at(LOOK_AT)


func _process(delta: float) -> void:
	_time += delta
	if _talking:
		# A made-up voice: syllables of different loudness.
		_monkey.set_mouth_open(absf(sin(_time * 11.0)) * (0.5 + 0.5 * absf(sin(_time * 1.7))))
	var turn := Input.get_axis("ui_left", "ui_right")
	_monkey.rotation.y += turn * TURN_SPEED * delta


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			_monkey.react("caught")
		KEY_2:
			_monkey.react("cheer")
		KEY_3:
			_monkey.react("slump")
		KEY_K:
			_talking = not _talking
		KEY_A:
			_accessories = not _accessories
			var keys := (load("res://data/rules_v0_3.tres") as RulesConfig).accessory_keys
			_monkey.set_accessories(keys if _accessories else PackedStringArray())
		KEY_D:
			_auditor = not _auditor
			_monkey.set_auditor(_auditor)
