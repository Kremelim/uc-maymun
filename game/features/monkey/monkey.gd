class_name Monkey
extends Node3D
## One monkey at the table. The table tells it everything through this script: name and
## status, auditor or not, which accessories it wears, its voice, and reactions. A body
## shows it: an imported model that follows docs/sanatci-sartnamesi.md (bone names,
## the "jaw_open" and "blink" shapes, acc_* and auditor_hat nodes, the animations).
## New monkeys only change the cast (MonkeyCast), not this script or the table.

## Speech is quiet in RMS terms (around 0.05-0.2), so scale it up for the mouth.
## Calibrate with the HUD's incoming-voice line once real Steam levels are known.
const MOUTH_GAIN := 10.0
## How fast the mouth closes when the voice stops, in "fully open" per second.
const MOUTH_CLOSE_SPEED := 5.0
const VOICE_BUFFER_SECONDS := 0.4
## The name turns this colour while the monkey talks, to see at a glance who is speaking.
const SPEAKING_COLOR := Color(1.0, 0.85, 0.3)
const SPEAKING_THRESHOLD := 0.15

## What the model must contain, by name (see docs/sanatci-sartnamesi.md).
const HEAD_BONE := "Head"
const MOUTH_SHAPE := "jaw_open"
const BLINK_SHAPE := "blink"
const ACCESSORY_PREFIX := "acc_"
const AUDITOR_HAT := "auditor_hat"
const IDLE := "idle"
const TALK := "talk"
const REACTIONS: Array[String] = ["caught", "cheer", "slump"]

## The talk animation starts after this much voice and stops after this much silence,
## so short sounds only move the mouth.
const TALK_AFTER_SEC := 0.25
const QUIET_AFTER_SEC := 0.8
const ANIMATION_BLEND_SEC := 0.25
const BLINK_SEC := 0.14
const BLINK_EVERY_SEC := Vector2(2.0, 5.5)
## The name floats this far above the head bone (which sits at the top of the neck).
const LABEL_ABOVE_HEAD := 0.42
## Material names that take the seat's fur tint.
const FUR_MATERIAL := "fur"
## Toon look (style A in docs/m3-plan.md): banded light and a dark outline.
const OUTLINE_COLOR := Color(0.07, 0.04, 0.03)
const OUTLINE_THICKNESS := 0.006

var _player_name := ""
var _status := ""
var _mouth_open := 0.0
var _voice_playback: AudioStreamGeneratorPlayback
var _body: Node3D
var _skeleton: Skeleton3D
var _head: BoneAttachment3D
var _animations: AnimationPlayer
## [MeshInstance3D, blend shape index] pairs.
var _mouth_shapes: Array = []
var _blink_shapes: Array = []
var _accessories: Dictionary = {}  # key -> Array of Node3D
var _hats: Array[Node3D] = []
## The body's materials, copied for the tint and the toon look. Held here too: when the
## monkey is freed its children (the meshes) go first, and a mesh freed in the frame it
## changed would otherwise reach for its materials after they are gone.
var _materials: Array[Material] = []
var _reacting := false
var _talking := false
var _voice_sec := 0.0
var _quiet_sec := 0.0
var _blink_in_sec := 0.0
var _blink_sec := -1.0

@onready var _label: Label3D = $Label3D
@onready var _voice_player: AudioStreamPlayer3D = $VoicePlayer


## Puts a body on the monkey (replacing the old one). Call it once the monkey is in the tree.
func dress(body_scene: PackedScene, fur_tint: Color = Color.WHITE, toon: bool = false) -> void:
	if _body != null:
		_voice_player.reparent(self)
		_body.free()  # now, while _materials still holds its materials
	_mouth_shapes.clear()
	_blink_shapes.clear()
	_accessories.clear()
	_hats.clear()
	_materials.clear()
	_head = null
	_body = body_scene.instantiate() as Node3D
	# Models face +Z (glTF's front); the monkey faces -Z, like look_at() expects.
	_body.rotation.y = PI
	add_child(_body)
	_skeleton = _first(_body, "Skeleton3D") as Skeleton3D
	_animations = _first(_body, "AnimationPlayer") as AnimationPlayer
	for node: Node in _body.find_children("*", "Node3D", true, false):
		_collect(node as Node3D, fur_tint, toon)
	if _skeleton != null and _skeleton.find_bone(HEAD_BONE) >= 0:
		_head = BoneAttachment3D.new()
		_head.bone_name = HEAD_BONE
		_skeleton.add_child(_head)
		_voice_player.reparent(_head, false)
	if _hats.is_empty():
		_hats.append(_stand_in_hat())
	set_auditor(false)
	set_accessories(PackedStringArray())
	if _animations != null:
		for looping: String in [IDLE, TALK]:
			if _animations.has_animation(looping):
				_animations.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
		_animations.animation_finished.connect(_on_animation_finished)
		if _animations.has_animation(IDLE):
			_animations.play(IDLE)
			# Start somewhere in the loop, so the monkeys do not breathe in step.
			_animations.seek(randf() * _animations.current_animation_length, true)
	_blink_in_sec = randf_range(BLINK_EVERY_SEC.x, BLINK_EVERY_SEC.y)


func set_player_name(player_name: String) -> void:
	_player_name = player_name
	_update_label()


func set_status(status: String) -> void:
	_status = status
	_update_label()


func set_auditor(auditing: bool) -> void:
	for hat in _hats:
		hat.visible = auditing


## Shows the accessories with these keys (RulesConfig.accessory_keys) and hides the rest.
func set_accessories(keys: PackedStringArray) -> void:
	for key: String in _accessories:
		for node: Node3D in _accessories[key]:
			node.visible = key in keys


## Whether the body has an acc_<key> node for every key (if not, the table shows them instead).
func can_wear_all(keys: PackedStringArray) -> bool:
	for key in keys:
		if not _accessories.has(key):
			return false
	return true


## Plays a reaction ("caught", "cheer", "slump") once, then goes back to idle or talk.
## Returns false if the body has no such animation.
func react(reaction: String) -> bool:
	if _animations == null or not _animations.has_animation(reaction):
		return false
	_reacting = true
	_animations.play(reaction, ANIMATION_BLEND_SEC)
	return true


func setup_voice(mix_rate: int) -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = VOICE_BUFFER_SECONDS
	_voice_player.stream = generator
	_voice_player.play()
	_voice_playback = _voice_player.get_stream_playback()


func push_voice(frames: PackedVector2Array, level: float) -> void:
	# If the buffer is full we drop the packet rather than let the delay grow.
	if _voice_playback != null and _voice_playback.get_frames_available() >= frames.size():
		_voice_playback.push_buffer(frames)
	set_mouth_open(level * MOUTH_GAIN)


## 0 = closed, 1 = fully open. The mouth then closes on its own when no voice arrives.
func set_mouth_open(amount: float) -> void:
	_mouth_open = maxf(_mouth_open, clampf(amount, 0.0, 1.0))


func mouth_open() -> float:
	return _mouth_open


func _process(delta: float) -> void:
	_mouth_open = move_toward(_mouth_open, 0.0, MOUTH_CLOSE_SPEED * delta)
	_set_shapes(_mouth_shapes, _mouth_open)
	var speaking := _mouth_open > SPEAKING_THRESHOLD
	_label.modulate = SPEAKING_COLOR if speaking else Color.WHITE
	if _head != null:
		_label.global_position = _head.global_position + Vector3.UP * LABEL_ABOVE_HEAD
	_update_talking(speaking, delta)
	_update_blink(delta)


func _update_talking(speaking: bool, delta: float) -> void:
	_voice_sec = _voice_sec + delta if speaking else 0.0
	_quiet_sec = 0.0 if speaking else _quiet_sec + delta
	var talking := _talking
	if not _talking and _voice_sec > TALK_AFTER_SEC:
		talking = true
	elif _talking and _quiet_sec > QUIET_AFTER_SEC:
		talking = false
	if talking != _talking:
		_talking = talking
		if not _reacting:
			_play_base()


func _update_blink(delta: float) -> void:
	if _blink_sec >= 0.0:
		_blink_sec += delta
		# Closes and opens again: 0 -> 1 -> 0 over BLINK_SEC.
		_set_shapes(_blink_shapes, 1.0 - absf(_blink_sec / BLINK_SEC * 2.0 - 1.0))
		if _blink_sec >= BLINK_SEC:
			_blink_sec = -1.0
			_set_shapes(_blink_shapes, 0.0)
			_blink_in_sec = randf_range(BLINK_EVERY_SEC.x, BLINK_EVERY_SEC.y)
		return
	_blink_in_sec -= delta
	if _blink_in_sec <= 0.0:
		_blink_sec = 0.0


func _play_base() -> void:
	if _animations == null:
		return
	var base := TALK if _talking and _animations.has_animation(TALK) else IDLE
	if _animations.has_animation(base):
		_animations.play(base, ANIMATION_BLEND_SEC)


func _on_animation_finished(animation: StringName) -> void:
	if str(animation) in REACTIONS:
		_reacting = false
		_play_base()


func _collect(node: Node3D, fur_tint: Color, toon: bool) -> void:
	var node_name := str(node.name)
	if node_name.begins_with(ACCESSORY_PREFIX):
		var key := node_name.trim_prefix(ACCESSORY_PREFIX)
		if not _accessories.has(key):
			_accessories[key] = []
		_accessories[key].append(node)
	elif node_name == AUDITOR_HAT:
		_hats.append(node)
	var mesh := node as MeshInstance3D
	if mesh == null:
		return
	var mouth := mesh.find_blend_shape_by_name(MOUTH_SHAPE)
	if mouth >= 0:
		_mouth_shapes.append([mesh, mouth])
	var blink := mesh.find_blend_shape_by_name(BLINK_SHAPE)
	if blink >= 0:
		_blink_shapes.append([mesh, blink])
	for surface in mesh.get_surface_override_material_count():
		var material := mesh.get_active_material(surface) as BaseMaterial3D
		if material == null:
			continue
		var styled := material.duplicate() as BaseMaterial3D
		if material.resource_name == FUR_MATERIAL:
			styled.albedo_color *= fur_tint
		if toon:
			styled.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			styled.specular_mode = BaseMaterial3D.SPECULAR_TOON
			styled.stencil_mode = BaseMaterial3D.STENCIL_MODE_OUTLINE
			styled.stencil_color = OUTLINE_COLOR
			styled.stencil_outline_thickness = OUTLINE_THICKNESS
		mesh.set_surface_override_material(surface, styled)
		_materials.append(styled)


## A gold badge on the head, for a body without an auditor_hat node.
func _stand_in_hat() -> Node3D:
	var badge := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.1
	shape.bottom_radius = 0.12
	shape.height = 0.06
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.8, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.45, 0.05)
	shape.material = material
	badge.mesh = shape
	badge.position = Vector3.UP * (LABEL_ABOVE_HEAD - 0.15)
	if _head != null:
		_head.add_child(badge)
	else:
		badge.position.y += 1.0
		add_child(badge)
	return badge


static func _first(root: Node, type: String) -> Node:
	var found := root.find_children("*", type, true, false)
	return null if found.is_empty() else found[0]


static func _set_shapes(shapes: Array, value: float) -> void:
	for pair: Array in shapes:
		(pair[0] as MeshInstance3D).set_blend_shape_value(pair[1], value)


func _update_label() -> void:
	_label.text = "%s\n%s" % [_player_name, _status] if _status != "" else _player_name
