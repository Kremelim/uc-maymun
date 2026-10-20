class_name MonkeyPlaceholder
extends Node3D
## Grey-box stand-in for a monkey: body, head and a floating label.

var _player_name := ""
var _declaration := TableState.NOT_DECLARED

@onready var _label: Label3D = $Label3D


func set_player_name(player_name: String) -> void:
	_player_name = player_name
	_update_label()


func set_declaration(amount: int) -> void:
	_declaration = amount
	_update_label()


func _update_label() -> void:
	var status := "düşünüyor…" if _declaration == TableState.NOT_DECLARED else "beyan: %d" % _declaration
	_label.text = "%s\n%s" % [_player_name, status]
