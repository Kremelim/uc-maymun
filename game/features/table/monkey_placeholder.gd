class_name MonkeyPlaceholder
extends Node3D
## Grey-box stand-in for a monkey: body, head and a floating label.

var _player_name := ""
var _status := ""

@onready var _label: Label3D = $Label3D


func set_player_name(player_name: String) -> void:
	_player_name = player_name
	_update_label()


func set_status(status: String) -> void:
	_status = status
	_update_label()


func _update_label() -> void:
	_label.text = "%s\n%s" % [_player_name, _status] if _status != "" else _player_name
