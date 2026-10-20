extends TestSuite

const VoiceChatScript := preload("res://net/voice_chat.gd")


func test_pcm16_round_trip() -> void:
	var pcm := VoiceChatScript.make_tone_pcm16(160, 16000, 200.0, 0.5, 0.0)
	assert_eq(pcm.size(), 320, "two bytes per sample")
	var frames := VoiceChatScript.pcm16_to_frames(pcm, pcm.size())
	assert_eq(frames.size(), 160, "one frame per sample")
	var peak := 0.0
	for frame in frames:
		assert_true(frame.x == frame.y, "mono is copied to both channels")
		peak = maxf(peak, absf(frame.x))
	assert_true(absf(peak - 0.5) < 0.01, "peak should match the amplitude, got %f" % peak)


func test_only_written_bytes_become_audio() -> void:
	# Steam's decompressVoice returns its whole buffer; only "size" bytes are real audio.
	var buffer := PackedByteArray()
	buffer.resize(1000)
	assert_eq(VoiceChatScript.pcm16_to_frames(buffer, 320).size(), 160, "frames from 320 written bytes")
	assert_eq(VoiceChatScript.pcm16_to_frames(buffer, 5000).size(), 500, "never read past the buffer")


func test_level_of_a_sine_is_its_rms() -> void:
	# The RMS of a sine wave is amplitude / sqrt(2).
	var pcm := VoiceChatScript.make_tone_pcm16(1600, 16000, 200.0, 0.4, 0.0)
	var level := VoiceChatScript.level_of(VoiceChatScript.pcm16_to_frames(pcm, pcm.size()))
	assert_true(absf(level - 0.4 / sqrt(2.0)) < 0.01, "RMS level, got %f" % level)
	assert_eq(VoiceChatScript.level_of(PackedVector2Array()), 0.0, "silence")
