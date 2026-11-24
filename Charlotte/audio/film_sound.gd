class_name FilmSound
extends Node
## The sound of a film on the movie night (`FilmArt`): while it plays the game's music is put away and the film has its own
## sound, all synthesised in code (no files, nothing to license): an ambience for each of its four scenes (wind, rain, water,
## crickets…) that melts into the next, a small original music-box score that loops under it, and sound effects that fall on
## the picture's own moments (`CUES`: the sleigh bells, the paint can's BONG, the bubbles, the ice…).
##   var sound := FilmSound.new(); add_child(sound); sound.start("nemo")   …   sound.stop()
## Nothing is made or played under `--audio-driver Dummy` (tests and screenshots). When the film ends, the music comes back.

const RATE := 22050
const SCENE := (FilmArt.LENGTH - 2.0 * FilmArt.CARD) / 4.0
const AMB_DB := -9.0
const SCORE_DB := -15.0
const FX_DB := -4.0

## The ambience of each film's four scenes.
const AMBIENCE := {
	"film": ["wind", "wind", "wind", "night"],
	"grinch": ["night", "wind", "night", "day"],
	"maison": ["wind", "hum", "night", "wind"],
	"ratatouille": ["city", "wind", "kitchen", "hum"],
	"reine": ["wind", "wind", "wind", "day"],
	"lion": ["savanna", "savanna", "waterfall", "night"],
	"nemo": ["water", "water", "water", "water"],
	"up": ["day", "wind", "waterfall", "waterfall"],
	"totoro": ["rain", "forest", "night", "day"],
}
## The score of each film: the root note (MIDI), the chords (semitones from the root, minor or major) and the tempo.
const SCORES := {
	"film": {"root": 60, "chords": [[0, 0], [5, 0], [9, 1], [7, 0]], "bpm": 66},
	"grinch": {"root": 57, "chords": [[0, 1], [8, 0], [3, 0], [7, 0]], "bpm": 72},
	"maison": {"root": 62, "chords": [[0, 0], [7, 0], [9, 1], [5, 0]], "bpm": 84},
	"ratatouille": {"root": 57, "chords": [[0, 1], [5, 0], [7, 0], [0, 1]], "bpm": 96},
	"reine": {"root": 62, "chords": [[0, 1], [3, 0], [10, 0], [5, 0]], "bpm": 60},
	"lion": {"root": 55, "chords": [[0, 0], [5, 0], [7, 0], [0, 0]], "bpm": 78},
	"nemo": {"root": 64, "chords": [[0, 0], [7, 0], [9, 1], [5, 0]], "bpm": 72},
	"up": {"root": 60, "chords": [[0, 0], [9, 1], [5, 0], [7, 0]], "bpm": 88},
	"totoro": {"root": 65, "chords": [[0, 0], [7, 0], [5, 0], [0, 0]], "bpm": 80},
}
## Sound effects on the picture: [seconds into the film, sound, volume (dB), pitch] — or [from, to, every, sound, volume] to
## repeat. Sounds are `Sfx` ones ("chime", "swoosh"…) or this file's own (`_oneshot`).
const CUES := {
	"film": [[26.0, "swoosh", 0.0, 1.0], [28.0, 46.0, 2.6, "sleigh_bells", -2.0], [54.0, "chime", -3.0, 1.2], [58.0, "chime", -5.0, 1.5],
		[72.0, "ice", -6.0, 1.0], [82.0, "chime", -4.0, 0.8]],
	"grinch": [[30.0, "swoosh", 0.0, 0.7], [50.0, "click", 2.0, 0.6], [54.0, "click", 2.0, 0.55], [58.0, "click", 2.0, 0.5], [62.0, "click", 2.0, 0.45],
		[72.0, 74.0, 0.6, "bell", -2.0], [78.0, "chime", -2.0, 0.8], [82.0, "chime", -2.0, 1.0], [86.0, "chime", -2.0, 1.25]],
	"maison": [[5.0, "plane", -3.0, 1.0], [49.4, "bong", 0.0, 1.0], [56.4, "bong", 0.0, 1.0], [63.4, "bong", 0.0, 1.0], [48.0, "swoosh", -4.0, 1.0],
		[72.0, "car", -4.0, 1.0], [84.0, "chime", -4.0, 1.3]],
	"ratatouille": [[10.0, "chime", -6.0, 1.5], [32.0, "pop", -6.0, 0.8], [52.0, 66.0, 3.0, "pop", -9.0], [72.0, "chime", -3.0, 1.0], [76.0, "chime", -4.0, 1.5]],
	"reine": [[28.0, 46.0, 2.2, "ice", -4.0], [52.0, "ice_rise", -2.0, 1.0], [56.0, 66.0, 3.0, "ice", -6.0], [78.0, "chime", -3.0, 1.2]],
	"lion": [[8.0, "bird", -3.0, 1.0], [14.0, "bird", -4.0, 0.9], [28.0, "drum", 0.0, 1.0], [32.0, "chime", -4.0, 1.0], [54.0, 60.0, 3.0, "bird", -5.0], [88.0, "howl", -3.0, 1.0]],
	"nemo": [[6.0, 90.0, 2.4, "bubbles", -5.0], [74.0, "whale", -2.0, 1.0]],
	"up": [[8.0, 22.0, 1.4, "balloon", -6.0], [28.0, "swoosh", 0.0, 1.2], [34.0, "chime", -4.0, 1.2], [88.0, "balloon", -5.0, 1.0]],
	"totoro": [[34.0, "bird", -6.0, 0.8], [52.0, "swoosh", -2.0, 0.8], [72.0, "chime", -5.0, 0.9], [78.0, "bird", -4.0, 1.0], [84.0, "bird", -5.0, 1.2]],
}

var film := ""
var _t := 0.0
var _scene := -1
var _playing := false
var _amb: Array[AudioStreamPlayer] = []
var _amb_on := 0
var _score: AudioStreamPlayer
var _fx: Array[AudioStreamPlayer] = []
var _fx_next := 0
var _cache := {}
var _cue_next: Array = []
var _repeat_at: Array = []
var _resume := ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = Sfx.BUS_SFX
		p.volume_db = -60.0
		add_child(p)
		_amb.append(p)
	_score = AudioStreamPlayer.new()
	_score.bus = Sfx.BUS_SFX
	_score.volume_db = -60.0
	add_child(_score)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = Sfx.BUS_SFX
		add_child(p)
		_fx.append(p)


func start(film_id: String) -> void:
	film = film_id
	_t = 0.0
	_scene = -1
	_playing = true
	_cue_next = []
	for c: Array in CUES.get(film, []):
		_cue_next.append(c.duplicate())
	_resume = str(Music._track)
	Music.stop()
	if Sfx._silent:
		return
	_score.stream = _make_score()
	_score.volume_db = -60.0
	_score.play()
	create_tween().tween_property(_score, "volume_db", SCORE_DB, 2.0)


## Ends the film's sound (fade out) and brings the music back.
func stop() -> void:
	if not _playing:
		return
	_playing = false
	for p in _amb + [_score]:
		if p.playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, 1.2)
			tw.tween_callback(p.stop)
	if _resume != "":
		Music.play([_resume])
	get_tree().create_timer(1.6).timeout.connect(queue_free)


func _exit_tree() -> void:
	for p in _amb + [_score] + _fx:
		if p:
			p.stop()
			p.stream = null
	_cache.clear()


func _process(delta: float) -> void:
	if not _playing:
		return
	_t += delta
	var scene := clampi(int((_t - FilmArt.CARD) / SCENE), 0, 3) if _t >= FilmArt.CARD else -1
	if scene != _scene and scene >= 0:
		_scene = scene
		_change_ambience(scene)
	var i := 0
	while i < _cue_next.size():
		var c: Array = _cue_next[i]
		if c.size() == 5:
			# [from, to, every, sound, volume]: repeated.
			if _t >= float(c[0]):
				if _t <= float(c[1]):
					_fire(str(c[3]), float(c[4]), 1.0)
				c[0] = float(c[0]) + float(c[2])
				if float(c[0]) > float(c[1]):
					_cue_next.remove_at(i)
					continue
		elif _t >= float(c[0]):
			_fire(str(c[1]), float(c[2]), float(c[3]))
			_cue_next.remove_at(i)
			continue
		i += 1
	if _t >= FilmArt.LENGTH:
		stop()


func _change_ambience(scene: int) -> void:
	if Sfx._silent:
		return
	var kind: String = (AMBIENCE.get(film, ["wind", "wind", "wind", "wind"]) as Array)[scene]
	var old := _amb[_amb_on]
	_amb_on = 1 - _amb_on
	var next := _amb[_amb_on]
	next.stream = _ambience(kind)
	next.volume_db = -60.0
	next.play()
	create_tween().tween_property(next, "volume_db", AMB_DB, 1.4)
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, 1.4)
		tw.tween_callback(old.stop)


func _fire(sound: String, volume_db: float, pitch: float) -> void:
	if Sfx._silent:
		return
	var own := _oneshot(sound)
	if own == null:
		Sfx.play(sound, Vector2.INF, volume_db, pitch)
		return
	var p := _fx[_fx_next]
	_fx_next = (_fx_next + 1) % _fx.size()
	p.stream = own
	p.volume_db = volume_db + FX_DB
	p.pitch_scale = pitch * _rng.randf_range(0.97, 1.03)
	p.play()


# ── Synthesis ───────────────────────────────────────────────────

func _buffer(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


func _lp(cutoff: float) -> float:
	return 1.0 - exp(-TAU * cutoff / RATE)


func _n() -> float:
	return _rng.randf_range(-1.0, 1.0)


func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var w := Sfx._wav(samples)
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


## A looping ambience of eight seconds; its ends are blended so the loop doesn't click.
func _ambience(kind: String) -> AudioStreamWAV:
	if _cache.has("amb_" + kind):
		return _cache["amb_" + kind]
	_rng.seed = hash(kind)
	var len_s := 8.0
	var out := _buffer(len_s)
	var y := 0.0
	var y2 := 0.0
	var a_lo := _lp(380.0)
	var a_mid := _lp(1400.0)
	for i in out.size():
		var t := float(i) / RATE
		var w := _n()
		y += a_lo * (w - y)
		y2 += a_mid * (w - y2)
		var v := 0.0
		match kind:
			"wind":
				v = y * (1.3 + 0.9 * sin(TAU * 0.13 * t) * sin(TAU * 0.31 * t + 1.0)) * 0.42
			"rain":
				v = (w - y2) * 0.2 + y * 0.1
			"water":
				v = y * 0.45 * (1.0 + 0.3 * sin(TAU * 0.21 * t)) + sin(TAU * 52.0 * t) * 0.05
			"waterfall":
				v = y2 * 0.34 + (w - y2) * 0.07
			"night":
				# Crickets: bursts of a high tone, pulsed fast, in two voices, over a faint wind.
				var burst := 1.0 if fmod(t * 2.4, 1.0) < 0.55 else 0.0
				var burst2 := 1.0 if fmod(t * 2.9 + 0.3, 1.0) < 0.5 else 0.0
				v = sin(TAU * 4300.0 * t) * burst * (0.5 + 0.5 * sin(TAU * 31.0 * t)) * 0.05 + sin(TAU * 3900.0 * t) * burst2 * (0.5 + 0.5 * sin(TAU * 27.0 * t)) * 0.04 + y * 0.2
			"day", "savanna", "forest":
				v = y * 0.35 * (1.0 + 0.4 * sin(TAU * 0.19 * t))
				if kind == "savanna":
					v += sin(TAU * 5200.0 * t) * (0.5 + 0.5 * sin(TAU * 60.0 * t)) * 0.012
			"kitchen":
				v = y2 * 0.12
			"city":
				v = y * 0.5 + sin(TAU * 60.0 * t) * 0.03
			"hum":
				v = sin(TAU * 55.0 * t) * 0.03 + y * 0.1
		out[i] = v
	# Little voices on top: bubbling in the kitchen, birds in the day and the forest.
	match kind:
		"kitchen":
			for k in 40:
				_blip(out, _rng.randf_range(0.0, len_s - 0.2), _rng.randf_range(300.0, 800.0), 0.05)
		"day", "forest", "savanna":
			for k in 7:
				_chirp(out, _rng.randf_range(0.2, len_s - 0.6), _rng.randf_range(2600.0, 4200.0))
	_fade_ends(out)
	var wav := _wav(out, true)
	_cache["amb_" + kind] = wav
	return wav


func _blip(out: PackedFloat32Array, at_s: float, freq: float, gain: float) -> void:
	var start := int(at_s * RATE)
	var n := int(0.09 * RATE)
	for i in n:
		if start + i >= out.size():
			return
		var t := float(i) / RATE
		out[start + i] += sin(TAU * (freq + 900.0 * t) * t) * exp(-t * 38.0) * gain


func _chirp(out: PackedFloat32Array, at_s: float, freq: float) -> void:
	var start := int(at_s * RATE)
	var notes := _rng.randi_range(2, 4)
	var pos := start
	for k in notes:
		var n := int(0.07 * RATE)
		for i in n:
			if pos + i >= out.size():
				return
			var t := float(i) / RATE
			out[pos + i] += sin(TAU * (freq * (1.0 + 0.25 * k) + 600.0 * t) * t) * sin(PI * float(i) / n) * 0.07
		pos += int(0.11 * RATE)


# A very short fade at both ends so a loop never clicks.
func _fade_ends(out: PackedFloat32Array) -> void:
	var f := int(0.05 * RATE)
	for i in f:
		var k := float(i) / f
		out[i] *= k
		out[out.size() - 1 - i] *= k


## A music-box score: the film's chords as arpeggios, a soft pad under them, about thirteen seconds that loop.
func _make_score() -> AudioStreamWAV:
	if _cache.has("score_" + film):
		return _cache["score_" + film]
	var s: Dictionary = SCORES.get(film, SCORES.film)
	var beat := 60.0 / float(s.bpm)
	var chords: Array = s.chords
	var total := chords.size() * 4.0 * beat
	var out := _buffer(total)
	var root: int = s.root
	for c in chords.size():
		var ch: Array = chords[c]
		var base := root + int(ch[0])
		var tones: Array = [0, 4 if int(ch[1]) == 0 else 3, 7, 12]
		var bar_start := c * 4.0 * beat
		# The arpeggio: eight notes, rising and falling, one every half beat.
		var order := [0, 1, 2, 3, 2, 1, 2, 1]
		for n in 8:
			var midi := base + 12 + int(tones[order[n]])
			_bell(out, bar_start + n * beat * 0.5, _hz(midi), 0.11)
		# A low pad on the chord's root and fifth, swelling and fading with the bar.
		for tone in [0, 7]:
			var f := _hz(base - 12 + tone)
			var a := int(bar_start * RATE)
			var n := int(4.0 * beat * RATE)
			for i in n:
				if a + i >= out.size():
					break
				var t := float(i) / RATE
				out[a + i] += sin(TAU * f * t) * sin(PI * float(i) / n) * 0.035
	# A lone high note at the end of the second bar, like a little question.
	_bell(out, beat * 4.0 * 2.0 - beat * 0.5, _hz(root + 24), 0.07)
	var wav := _wav(out, true)
	_cache["score_" + film] = wav
	return wav


func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


# A music-box note: a clear tone with a bright, quickly dying overtone.
func _bell(out: PackedFloat32Array, at_s: float, freq: float, gain: float) -> void:
	var start := int(at_s * RATE)
	var n := int(1.6 * RATE)
	for i in n:
		var idx := (start + i) % out.size()
		var t := float(i) / RATE
		out[idx] += (sin(TAU * freq * t) * exp(-t * 3.2) + 0.35 * sin(TAU * freq * 2.76 * t) * exp(-t * 9.0)) * minf(t * 400.0, 1.0) * gain


func _oneshot(sound: String) -> AudioStreamWAV:
	if _cache.has(sound):
		return _cache[sound]
	_rng.seed = hash("film_" + sound)
	var out := PackedFloat32Array()
	match sound:
		"sleigh_bells":
			out = _buffer(1.1)
			for k in 9:
				var at := _rng.randf_range(0.0, 0.7)
				var f := _rng.randf_range(2400.0, 4300.0)
				var start := int(at * RATE)
				for i in int(0.35 * RATE):
					var t := float(i) / RATE
					out[start + i] += (sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.51 * t)) * exp(-t * 14.0) * 0.12
		"plane":
			out = _buffer(7.0)
			var y := 0.0
			for i in out.size():
				var t := float(i) / RATE
				var swell := sin(PI * t / 7.0)
				y += _lp(260.0 + 500.0 * swell) * (_n() - y)
				out[i] = (y * 1.4 + sin(TAU * (120.0 + 40.0 * swell) * t) * 0.1) * pow(swell, 1.6) * 0.5
		"bong":
			out = _buffer(2.2)
			for i in out.size():
				var t := float(i) / RATE
				out[i] = (sin(TAU * 196.0 * t) * 0.5 + sin(TAU * 281.0 * t) * 0.3 + sin(TAU * 411.0 * t) * 0.2) * exp(-t * 2.4) * 0.6 + _n() * exp(-t * 140.0) * 0.5
		"bubbles":
			out = _buffer(1.6)
			for k in 7:
				var at := _rng.randf_range(0.0, 1.2)
				var f := _rng.randf_range(350.0, 800.0)
				var start := int(at * RATE)
				for i in int(0.12 * RATE):
					var t := float(i) / RATE
					out[start + i] += sin(TAU * (f + 2200.0 * t) * t) * exp(-t * 26.0) * 0.28
		"ice":
			out = _buffer(1.4)
			var notes := [1568.0, 1976.0, 2349.0, 2637.0]
			for k in notes.size():
				var start := int(k * 0.11 * RATE)
				for i in int(1.0 * RATE):
					var t := float(i) / RATE
					out[start + i] += (sin(TAU * notes[k] * t) + 0.4 * sin(TAU * notes[k] * 2.0 * t)) * exp(-t * 6.0) * 0.16
		"ice_rise":
			out = _buffer(4.0)
			for k in 12:
				var start := int(k * 0.28 * RATE)
				var f := 1046.5 * pow(2.0, k / 7.0)
				for i in int(0.9 * RATE):
					var t := float(i) / RATE
					out[start + i] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 3.0 * t)) * exp(-t * 5.0) * 0.12
		"balloon":
			out = _buffer(0.5)
			for i in out.size():
				var t := float(i) / RATE
				out[i] = sin(TAU * (600.0 + 1500.0 * t + 40.0 * sin(TAU * 38.0 * t)) * t) * sin(PI * t / 0.5) * 0.22
		"whale":
			out = _buffer(5.0)
			for i in out.size():
				var t := float(i) / RATE
				var f := 90.0 + 70.0 * sin(PI * t / 5.0) + 12.0 * sin(TAU * 0.8 * t)
				out[i] = (sin(TAU * f * t) + 0.5 * sin(TAU * f * 2.0 * t)) * sin(PI * t / 5.0) * 0.28
		"car":
			out = _buffer(6.0)
			var y := 0.0
			for i in out.size():
				var t := float(i) / RATE
				var swell := sin(PI * t / 6.0)
				y += _lp(500.0) * (_n() - y)
				out[i] = (y * 0.8 + sin(TAU * (70.0 + 30.0 * swell) * t) * 0.18) * pow(swell, 1.3) * 0.5
		"drum":
			out = _buffer(1.4)
			for k in 3:
				var start := int(k * 0.42 * RATE)
				for i in int(0.5 * RATE):
					var t := float(i) / RATE
					out[start + i] += sin(TAU * (90.0 - 30.0 * t) * t) * exp(-t * 7.0) * 0.55
		"howl":
			out = _buffer(3.2)
			for i in out.size():
				var t := float(i) / RATE
				var f := 330.0 + 330.0 * sin(PI * t / 3.2) * (1.0 - t / 6.0)
				out[i] = (sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t)) * sin(PI * t / 3.2) * 0.18
		_:
			return null
	var wav := _wav(out)
	_cache[sound] = wav
	return wav
