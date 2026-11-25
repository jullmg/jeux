extends Node
## Autoload « Sound » : bruitages et musique.
## Une musique peut être remplacée en déposant res://audio/music/<nom>.ogg, .mp3 ou .wav.

const SFX_DIR := "res://audio/generated/%s.wav"
const MUSIC_DIR := "res://audio/music/%s.%s"
const VOICES := 12

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _tension: AudioStreamPlayer
var _music_name := ""
var _hum: AudioStreamPlayer
var _humming := false
var _tension_wanted := 0.0
var _tension_now := 0.0
## Vrai quand le jeu se ferme : plus aucun son ne repart.
var _closed := false
## Les derniers bruitages joués (pour les tests).
var history: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: String in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_tension = AudioStreamPlayer.new()
	_tension.bus = "Music"
	_tension.volume_db = -60.0
	add_child(_tension)
	_hum = AudioStreamPlayer.new()
	_hum.bus = "Effects"
	_hum.volume_db = -15.0
	add_child(_hum)


func _exit_tree() -> void:
	silence()


## Coupe tout et lâche les sons : à appeler quelques images avant de quitter, pour ne rien laisser derrière.
func silence() -> void:
	_music_name = ""
	_humming = false
	for p in _players + [_music, _tension, _hum]:
		p.stop()
		p.stream = null
	_cache.clear()


func set_volumes(music: float, effects: float) -> void:
	_set_bus("Music", music)
	_set_bus("Effects", effects)


func _set_bus(bus: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(i, value <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(value, 0.001)))


## Avant de quitter : le silence, et rien ne recommence.
func close() -> void:
	_closed = true
	silence()


func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	if _closed:
		return
	var path := SFX_DIR % sound
	if not _cache.has(sound):
		if not ResourceLoader.exists(path):
			push_warning("son absent : " + sound)
			return
		_cache[sound] = load(path)
	history.append(sound)
	if history.size() > 200:
		history.pop_front()
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _cache[sound]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func _music_stream(track: String) -> AudioStream:
	for ext: String in ["ogg", "mp3", "wav"]:
		var custom := MUSIC_DIR % [track, ext]
		if ResourceLoader.exists(custom):
			return _looped(load(custom))
	var path := SFX_DIR % ("musique_" + track)
	if ResourceLoader.exists(path):
		return _looped(load(path))
	return null


func _looped(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif stream != null and "loop" in stream:
		stream.loop = true
	return stream


## Le fredonnement de Maman : il s'arrête net quand elle se doute de quelque chose.
func hum(on: bool) -> void:
	if _closed or on == _humming:
		return
	_humming = on
	if not on:
		_hum.stop()
		return
	if _hum.stream == null:
		var path := SFX_DIR % "fredon"
		if not ResourceLoader.exists(path):
			return
		_hum.stream = _looped(load(path))
	_hum.play()


## « menu » ou « jeu ». En jeu, la couche de tension suit le soupçon.
func music(track: String) -> void:
	if _closed or track == _music_name:
		return
	_music_name = track
	_music.stop()
	_tension.stop()
	if track == "":
		return
	_music.stream = _music_stream(track)
	if _music.stream:
		_music.play()
	if track == "jeu":
		_tension.stream = _music_stream("tension")
		_tension_now = 0.0
		_tension_wanted = 0.0
		_tension.volume_db = -60.0
		if _tension.stream:
			_tension.play()


func set_tension(value: float) -> void:
	_tension_wanted = clampf(value, 0.0, 1.0)


func _process(delta: float) -> void:
	_tension_now = move_toward(_tension_now, _tension_wanted, delta * 0.8)
	_tension.volume_db = linear_to_db(maxf(_tension_now, 0.001))
