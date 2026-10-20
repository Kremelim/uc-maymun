class_name MonkeyPlaceholder
extends Node3D
## Grey-box stand-in for a monkey: body, head, a floating label, and a voice
## that comes from its head while the mouth follows how loud it is.

const MOUTH_CLOSED := 0.1
## Speech is quiet in RMS terms (around 0.05-0.2), so scale it up for the mouth.
## Calibrate with the HUD's incoming-voice line once real Steam levels are known.
const MOUTH_GAIN := 10.0
## How fast the mouth closes when the voice stops, in "fully open" per second.
const MOUTH_CLOSE_SPEED := 5.0
const VOICE_BUFFER_SECONDS := 0.4
## The name turns this colour while the monkey talks, to see at a glance who is speaking.
const SPEAKING_COLOR := Color(1.0, 0.85, 0.3)
const SPEAKING_THRESHOLD := 0.15

var _player_name := ""
var _status := ""
var _mouth_open := 0.0
var _voice_playback: AudioStreamGeneratorPlayback

@onready var _label: Label3D = $Label3D
@onready var _mouth: MeshInstance3D = $Head/Muzzle/Mouth
@onready var _voice_player: AudioStreamPlayer3D = $Head/VoicePlayer


func set_player_name(player_name: String) -> void:
	_player_name = player_name
	_update_label()


func set_status(status: String) -> void:
	_status = status
	_update_label()


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


func _process(delta: float) -> void:
	_mouth_open = move_toward(_mouth_open, 0.0, MOUTH_CLOSE_SPEED * delta)
	_mouth.scale.y = lerpf(MOUTH_CLOSED, 1.0, _mouth_open)
	_label.modulate = SPEAKING_COLOR if _mouth_open > SPEAKING_THRESHOLD else Color.WHITE


func _update_label() -> void:
	_label.text = "%s\n%s" % [_player_name, _status] if _status != "" else _player_name
