extends Node
## Autoload "VoiceChat": voice at the table.
## Each peer records its microphone through Steam (compressed by Steam's voice
## codec) and sends the packets to the host, which relays them to everyone else.
## As with all other messages, clients only ever talk to the host. Playback and
## mouth movement belong to the table scene, which listens to `voice_received`.
##
## Without Steam there is no microphone. `--fake-voice` swaps the microphone for
## a test tone and the codec for raw 16-bit PCM, so headless tests can check the relay.

signal voice_received(peer_id: int, frames: PackedVector2Array, level: float)

## Voice gets its own channel so it never waits behind reliable game messages.
const CHANNEL := 1
## A voice packet is a few hundred bytes; anything far bigger is dropped.
const MAX_PACKET_BYTES := 16384
## Steam's getVoice() defaults to 1 KB, which can truncate a slow frame's audio.
const STEAM_READ_BUFFER := 8192
const VOICE_RESULT_OK := 0
const FAKE_SAMPLE_RATE := 16000
const FAKE_PACKETS_PER_SECOND := 50
const FAKE_TONE_HZ := 220.0
const FAKE_TONE_AMPLITUDE := 0.3
## Upper bound on fake packets per frame, so a long hitch does not flood the network.
const FAKE_MAX_PACKETS_PER_FRAME := 5

var mic_enabled := true
## Plays your own voice back to you, to test the microphone alone.
var loopback := false
## Level (0..1) of the last packet we recorded, for the HUD's microphone meter.
var own_level := 0.0

var _steam: Object
var _fake := false
var _recording := false
var _sample_rate := 48000
var _fake_clock := 0.0
var _fake_phase := 0.0


func _ready() -> void:
	_fake = CmdArgs.has_flag("--fake-voice")
	if _fake:
		_sample_rate = FAKE_SAMPLE_RATE
	elif SteamService.available:
		_steam = Engine.get_singleton("Steam")
		_sample_rate = clampi(_steam.getVoiceOptimalSampleRate(), 11025, 48000)


func is_available() -> bool:
	return _fake or _steam != null


## Received frames are always at this rate: Steam's decoder converts to whatever we ask for.
func sample_rate() -> int:
	return _sample_rate


func _process(delta: float) -> void:
	_set_recording(mic_enabled and Network.game_in_progress and is_available())
	if not _recording:
		return
	var packets := _read_fake_packets(delta) if _fake else _read_steam_packets()
	for packet in packets:
		_send(packet)


func _set_recording(on: bool) -> void:
	if on == _recording:
		return
	_recording = on
	if _steam != null:
		if on:
			_steam.startVoiceRecording()
		else:
			_steam.stopVoiceRecording()
		# Tells Steam we handle voice ourselves, so its own voice chat steps aside.
		_steam.setInGameVoiceSpeaking(SteamService.steam_id, on)
	if not on:
		own_level = 0.0


func _read_steam_packets() -> Array[PackedByteArray]:
	var packets: Array[PackedByteArray] = []
	var available: Dictionary = _steam.getAvailableVoice()
	if available.get("result", -1) != VOICE_RESULT_OK or available.get("size", 0) == 0:
		return packets
	var voice: Dictionary = _steam.getVoice(STEAM_READ_BUFFER)
	if voice.get("result", -1) == VOICE_RESULT_OK and voice.get("size", 0) > 0:
		packets.append(voice["buffer"])
	return packets


func _read_fake_packets(delta: float) -> Array[PackedByteArray]:
	var packets: Array[PackedByteArray] = []
	var interval := 1.0 / FAKE_PACKETS_PER_SECOND
	_fake_clock = minf(_fake_clock + delta, interval * FAKE_MAX_PACKETS_PER_FRAME)
	while _fake_clock >= interval:
		_fake_clock -= interval
		var samples := int(FAKE_SAMPLE_RATE * interval)
		packets.append(make_tone_pcm16(samples, FAKE_SAMPLE_RATE, FAKE_TONE_HZ, FAKE_TONE_AMPLITUDE, _fake_phase))
		_fake_phase = fmod(_fake_phase + TAU * FAKE_TONE_HZ * samples / FAKE_SAMPLE_RATE, TAU)
	return packets


func _send(packet: PackedByteArray) -> void:
	var me := multiplayer.get_unique_id()
	var frames := _decode(packet)
	own_level = level_of(frames)
	if loopback:
		voice_received.emit(me, frames, own_level)
	if Network.is_host():
		_relay(me, packet)
	else:
		_to_host.rpc_id(1, packet)


@rpc("any_peer", "call_remote", "unreliable_ordered", CHANNEL)
func _to_host(packet: PackedByteArray) -> void:
	if not Network.is_host():
		return
	var speaker := multiplayer.get_remote_sender_id()
	if not Network.roster.has(speaker) or packet.size() > MAX_PACKET_BYTES:
		return
	_relay(speaker, packet)


## Host only: sends a speaker's packet to everyone except the speaker, and plays it here.
func _relay(speaker: int, packet: PackedByteArray) -> void:
	var me := multiplayer.get_unique_id()
	for peer_id: int in Network.roster:
		if peer_id != speaker and peer_id != me:
			_from_host.rpc_id(peer_id, speaker, packet)
	if speaker != me:
		_play(speaker, packet)


@rpc("authority", "call_remote", "unreliable_ordered", CHANNEL)
func _from_host(speaker: int, packet: PackedByteArray) -> void:
	if packet.size() <= MAX_PACKET_BYTES:
		_play(speaker, packet)


func _play(speaker: int, packet: PackedByteArray) -> void:
	var frames := _decode(packet)
	if not frames.is_empty():
		voice_received.emit(speaker, frames, level_of(frames))


func _decode(packet: PackedByteArray) -> PackedVector2Array:
	if _fake:
		return pcm16_to_frames(packet, packet.size())
	if _steam == null:
		return PackedVector2Array()
	# One second of 16-bit mono at our rate is far more than any packet holds.
	var decoded: Dictionary = _steam.decompressVoice(packet, _sample_rate, _sample_rate * 2)
	if decoded.get("result", -1) != VOICE_RESULT_OK:
		return PackedVector2Array()
	# "uncompressed" always has the full buffer size; only the first "size" bytes are audio.
	return pcm16_to_frames(decoded["uncompressed"], decoded["size"])


## Little-endian 16-bit mono PCM to stereo frames for AudioStreamGenerator.
static func pcm16_to_frames(pcm: PackedByteArray, byte_count: int) -> PackedVector2Array:
	var frames := PackedVector2Array()
	frames.resize(floori(mini(byte_count, pcm.size()) / 2.0))
	for i in frames.size():
		var sample := pcm.decode_s16(i * 2) / 32768.0
		frames[i] = Vector2(sample, sample)
	return frames


## Root mean square loudness, 0 (silence) to 1 (full scale).
static func level_of(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var sum := 0.0
	for frame in frames:
		sum += frame.x * frame.x
	return sqrt(sum / frames.size())


static func make_tone_pcm16(sample_count: int, rate: int, hz: float, amplitude: float, start_phase: float) -> PackedByteArray:
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in sample_count:
		var value := amplitude * sin(start_phase + TAU * hz * i / rate)
		pcm.encode_s16(i * 2, int(value * 32767.0))
	return pcm
