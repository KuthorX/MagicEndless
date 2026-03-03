class_name RuntimeBgm
extends RefCounted

static func create_menu_stream() -> AudioStreamWAV:
	return _make_stream(36.0, 100.0, false)

static func create_battle_stream() -> AudioStreamWAV:
	return _make_stream(84.0, 124.0, true)

static func _make_stream(seconds: float, bpm: float, bright: bool) -> AudioStreamWAV:
	var sr := 22050
	var samples: int = int(seconds * float(sr))
	var beat: float = 60.0 / bpm
	var data := PackedByteArray()
	data.resize(samples * 2)

	var chords: Array = [
		[220.0, 261.63, 329.63], # Am
		[174.61, 220.0, 261.63], # F
		[196.0, 246.94, 293.66], # G
		[164.81, 207.65, 246.94] # E
	]
	var lead_scale: Array = [0.0, 3.0, 7.0, 10.0, 12.0, 15.0, 19.0, 15.0]
	var intensity: float = 1.22 if bright else 0.92

	for i in samples:
		var t: float = float(i) / float(sr)
		var bar: int = int(floor(t / (beat * 4.0))) % chords.size()
		var chord: Array = chords[bar]
		var beat_t: float = fmod(t, beat)
		var half_t: float = fmod(t, beat * 0.5)
		var pulse: float = 0.88 + 0.12 * sin(TAU * (1.0 / beat) * t)

		var pad: float = 0.0
		for f in chord:
			var ff: float = float(f)
			pad += sin(TAU * ff * t) * 0.10
			pad += sin(TAU * ff * 2.0 * t) * 0.024
			pad += sin(TAU * ff * 0.5 * t) * 0.05
		pad /= float(chord.size())

		var bass_f: float = float(chord[0]) * 0.5
		var bass_gate: float = 1.0 if beat_t < beat * 0.34 else 0.44
		var bass: float = sin(TAU * bass_f * t) * 0.15 * bass_gate
		bass += sin(TAU * bass_f * 0.5 * t) * 0.05 * bass_gate

		var step: int = int(floor(t / (beat * 0.5))) % lead_scale.size()
		var lead_semi: float = float(lead_scale[step])
		var root: float = float(chord[0]) * (2.0 if bright else 1.65)
		var lead_f: float = root * pow(2.0, lead_semi / 12.0)
		var lead_env: float = 1.0 - clampf(half_t / (beat * 0.5), 0.0, 1.0)
		lead_env = pow(lead_env, 1.8)
		var lead: float = sin(TAU * lead_f * t) * 0.092 * lead_env
		lead += sin(TAU * lead_f * 2.0 * t) * 0.024 * lead_env

		var kick_gate: float = 1.0 if beat_t < 0.085 else 0.0
		var kick: float = sin(TAU * (58.0 - 34.0 * beat_t) * t) * 0.16 * kick_gate
		var snare_t: float = fmod(t + beat * 0.5, beat)
		var snare_env: float = 1.0 - clampf(snare_t / 0.07, 0.0, 1.0)
		var snare: float = (sin(TAU * 1800.0 * t) + sin(TAU * 2400.0 * t) * 0.6) * 0.022 * snare_env
		var hat_env: float = 1.0 - clampf(half_t / 0.04, 0.0, 1.0)
		var hat: float = sin(TAU * 5200.0 * t) * 0.011 * hat_env

		var v: float = (pad + bass + lead + kick + snare + hat) * pulse * intensity
		v = clampf(v, -0.90, 0.90)
		var s: int = int(round(v * 32767.0))
		var u: int = s & 0xFFFF
		data[i * 2] = u & 0xFF
		data[i * 2 + 1] = (u >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = data
	return wav
