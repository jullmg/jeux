extends Node
## Autoload "Sfx": the game's sound effects, synthesised in code the first time each is played (no audio
## files, nothing to license). Sfx.play("door", world_position) plays one in the world (louder near the
## camera); without a position it plays flat (UI). Effects go to the "Effets" bus; "Musique" is ready for
## the music tracks.

const RATE := 22050
const BUS_SFX := "Effets"
const BUS_MUSIC := "Musique"

var _cache := {}
var _world: Array[AudioStreamPlayer2D] = []
var _flat: Array[AudioStreamPlayer] = []
var _next_world := 0
var _next_flat := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in [BUS_SFX, BUS_MUSIC]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in 14:
		var p := AudioStreamPlayer2D.new()
		p.bus = BUS_SFX
		p.max_distance = 1500.0
		p.attenuation = 1.4
		add_child(p)
		_world.append(p)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_flat.append(p)


## Plays a sound. `at`: world position (Vector2.INF = not in the world, e.g. UI). A little random pitch
## keeps repeated sounds (footsteps) from sounding mechanical.
func play(sound: String, at := Vector2.INF, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _stream(sound)
	if stream == null:
		return
	var vary := pitch * _rng.randf_range(0.94, 1.06)
	if at == Vector2.INF:
		var p := _flat[_next_flat]
		_next_flat = (_next_flat + 1) % _flat.size()
		p.stream = stream
		p.volume_db = volume_db
		p.pitch_scale = vary
		p.play()
	else:
		var p := _world[_next_world]
		_next_world = (_next_world + 1) % _world.size()
		p.stream = stream
		p.global_position = at
		p.volume_db = volume_db
		p.pitch_scale = vary
		p.play()


## Outdoor ambience for a scene: now and then a bird calls somewhere near the camera (not in winter).
func ambience(parent: Node) -> void:
	if Season.is_winter():
		return
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	parent.add_child(timer)
	timer.timeout.connect(func():
		timer.wait_time = _rng.randf_range(2.5, 7.0)
		var cam := parent.get_viewport().get_camera_2d()
		var x := (cam.get_screen_center_position().x if cam else 640.0) + _rng.randf_range(-600.0, 600.0)
		var calls := _rng.randi_range(1, 3)
		for i in calls:
			get_tree().create_timer(i * 0.35).timeout.connect(func(): play("bird", Vector2(x, 200.0), -6.0, _rng.randf_range(0.85, 1.2))))


## Footstep sound for a surface: "wood" indoors; outside it depends on the season.
func step_for(outside: bool) -> String:
	if not outside:
		return "step_wood"
	match Season.current:
		"autumn":
			return "step_leaves"
		"winter":
			return "step_snow"
	return "step_street"


func _stream(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		var samples := _synth(sound)
		_cache[sound] = _wav(samples) if not samples.is_empty() else null
	return _cache[sound]


# ── Synthesis ───────────────────────────────────────────────────

func _synth(sound: String) -> PackedFloat32Array:
	_rng.seed = hash(sound)
	match sound:
		"click":
			return _click()
		"step_wood":
			return _thud(0.09, 140.0, 0.5, 2200.0)
		"step_street":
			return _thud(0.08, 95.0, 0.35, 3000.0)
		"step_leaves":
			return _crunch(0.16, 0.45, 0.35)
		"step_snow":
			return _crunch(0.15, 0.35, 0.8)
		"door":
			return _door()
		"meow":
			return _meow()
		"purr":
			return _purr()
		"bark":
			return _bark()
		"squeak":
			return _chirp(0.12, 2400.0, 3300.0, 0.22)
		"nibble":
			return _crunch(0.05, 0.25, 0.1)
		"tv":
			return _tv()
		"fridge":
			return _fridge()
		"pop":
			return _chirp(0.07, 900.0, 1450.0, 0.3)
		"page":
			return _swish(0.25, 0.28, 1500.0)
		"swoosh":
			return _swish(0.3, 0.3, 900.0)
		"chime":
			return _chime([880.0, 1318.5], 0.16, 0.28)
		"miam":
			return _chime([660.0, 880.0, 1046.5], 0.11, 0.26)
		"bell":
			return _chime([1568.0, 2093.0, 1568.0], 0.08, 0.22)
		"goodnight":
			return _chime([1046.5, 784.0, 659.3, 523.3], 0.22, 0.2)
		"bird":
			return _bird()
		"wind":
			return _wind()
	return PackedFloat32Array()


func _buffer(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


# One-pole low-pass coefficient for a cutoff in Hz.
func _lp(cutoff: float) -> float:
	return 1.0 - exp(-TAU * cutoff / RATE)


func _click() -> PackedFloat32Array:
	var out := _buffer(0.045)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = _noise() * exp(-t * 220.0) * 0.5 + sin(TAU * 2600.0 * t) * exp(-t * 160.0) * 0.3
	return out


# A soft knock: a low tone and a puff of muffled noise.
func _thud(seconds: float, tone: float, noise_gain: float, cutoff: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var y := 0.0
	var a := _lp(cutoff)
	for i in out.size():
		var t := float(i) / RATE
		y += a * (_noise() - y)
		out[i] = y * noise_gain * exp(-t * 55.0) + sin(TAU * tone * t) * exp(-t * 45.0) * 0.45
	return out


# Crisp crackles (leaves) or a softer, grainier crunch (snow): sparse noise bursts, low-passed by `soft`.
func _crunch(seconds: float, gain: float, soft: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var y := 0.0
	var a := _lp(lerpf(7000.0, 1800.0, soft))
	for i in out.size():
		var t := float(i) / RATE
		var grain := _noise() if _rng.randf() < lerpf(0.25, 0.7, soft) else 0.0
		y += a * (grain - y)
		out[i] = y * gain * 2.0 * exp(-t * 16.0) * sin(PI * minf(1.0, t / 0.01))
	return out


func _door() -> PackedFloat32Array:
	var out := _buffer(0.55)
	var y := 0.0
	var a := _lp(900.0)
	for i in out.size():
		var t := float(i) / RATE
		y += a * (_noise() - y)
		var thunk := sin(TAU * 78.0 * t) * exp(-t * 11.0) * 0.6 + y * exp(-t * 30.0) * 0.5
		var latch_t := t - 0.38
		var latch := (_noise() * 0.4 + sin(TAU * 3000.0 * latch_t) * 0.3) * exp(-latch_t * 200.0) if latch_t > 0.0 else 0.0
		out[i] = thunk + latch
	return out


# A little cat's "miaou": a rising-then-falling voice with a few harmonics.
func _meow() -> PackedFloat32Array:
	var out := _buffer(0.6)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var f := 520.0 + 380.0 * sin(PI * t / 0.6) - 120.0 * t
		phase += TAU * f / RATE
		var env := minf(1.0, t / 0.05) * minf(1.0, (0.6 - t) / 0.2)
		out[i] = (sin(phase) + 0.45 * sin(2.0 * phase) + 0.2 * sin(3.0 * phase)) * env * 0.28
	return out


func _purr() -> PackedFloat32Array:
	var out := _buffer(1.5)
	var y := 0.0
	var a := _lp(260.0)
	for i in out.size():
		var t := float(i) / RATE
		y += a * (_noise() - y)
		var rumble := absf(sin(TAU * 13.0 * t))
		var env := minf(1.0, t / 0.2) * minf(1.0, (1.5 - t) / 0.3)
		out[i] = y * 3.0 * rumble * env * 0.6
	return out


func _bark() -> PackedFloat32Array:
	var out := _buffer(0.24)
	var phase := 0.0
	var y := 0.0
	var a := _lp(2500.0)
	for i in out.size():
		var t := float(i) / RATE
		var f := lerpf(480.0, 260.0, t / 0.24)
		phase += TAU * f / RATE
		var saw := fmod(phase / TAU, 1.0) * 2.0 - 1.0
		y += a * (saw * 0.7 + _noise() * 0.3 - y)
		out[i] = y * minf(1.0, t / 0.01) * exp(-t * 9.0) * 0.55
	return out


func _chirp(seconds: float, from: float, to: float, gain: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(from, to, t / seconds) / RATE
		out[i] = sin(phase) * sin(PI * t / seconds) * gain
	return out


func _tv() -> PackedFloat32Array:
	var out := _buffer(0.35)
	var y := 0.0
	var a := _lp(5000.0)
	for i in out.size():
		var t := float(i) / RATE
		y += a * (_noise() - y)
		var click := sin(TAU * 1800.0 * t) * exp(-t * 120.0) * 0.3
		out[i] = click + y * 0.35 * minf(1.0, t / 0.02) * minf(1.0, (0.35 - t) / 0.08)
	return out


func _fridge() -> PackedFloat32Array:
	var out := _buffer(0.7)
	var y := 0.0
	var a := _lp(1200.0)
	for i in out.size():
		var t := float(i) / RATE
		y += a * (_noise() - y)
		var pop := y * exp(-t * 45.0) * 0.6
		var hum := (sin(TAU * 60.0 * t) + 0.5 * sin(TAU * 120.0 * t)) * 0.08 * minf(1.0, t / 0.1) * minf(1.0, (0.7 - t) / 0.2)
		out[i] = pop + hum
	return out


# A breathy swish (page turn, clothes): noise whose brightness rises and falls.
func _swish(seconds: float, gain: float, cutoff: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var y := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var shape := sin(PI * t / seconds)
		y += _lp(200.0 + cutoff * shape) * (_noise() - y)
		out[i] = y * shape * gain * 2.0
	return out


# Bright notes one after another, each ringing out (a happy "ding").
func _chime(notes: Array, note_len: float, gain: float) -> PackedFloat32Array:
	var out := _buffer(note_len * notes.size() + 0.4)
	for n in notes.size():
		var start := int(n * note_len * RATE)
		for i in range(start, out.size()):
			var t := float(i - start) / RATE
			out[i] += (sin(TAU * notes[n] * t) + 0.25 * sin(TAU * notes[n] * 2.0 * t)) * exp(-t * 7.0) * gain
	return out


func _bird() -> PackedFloat32Array:
	var out := _buffer(0.32)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var f := 3200.0 + 1400.0 * sin(TAU * 14.0 * t) - 1500.0 * t
		phase += TAU * f / RATE
		var env := absf(sin(PI * t / 0.08)) * minf(1.0, (0.32 - t) / 0.1)
		out[i] = sin(phase) * env * 0.12
	return out


func _wind() -> PackedFloat32Array:
	var out := _buffer(3.0)
	var y := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var shape := sin(PI * t / 3.0)
		y += _lp(300.0 + 500.0 * shape * (0.6 + 0.4 * sin(t * 5.0))) * (_noise() - y)
		out[i] = y * shape * 0.5
	return out


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
