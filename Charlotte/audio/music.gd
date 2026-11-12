extends Node
## Autoload "Music": the soundtrack (the user's tracks, made with Suno), from audio/music/<name>.mp3 / .ogg / .wav,
## on the "Musique" bus, looping, crossfading from one track to the next. Scenes ask for a track with fallbacks:
## Music.play(["street_winter", "street"]) plays the first that exists; if none exists, the title theme plays (so the title
## theme goes on in the streets until a street theme is added, and a shop's or the flat's music never leaks into them).
const DEFAULT_TRACK := "title"

## Tracks that follow one another and loop as a set: asking for any of them starts or keeps the set, whichever is playing.
const PLAYLISTS := {"title": ["title", "title-02"]}
const FOLDER := "res://audio/music/"
const VOLUME_DB := -6.0
const FADE := 1.5

var _players: Array[AudioStreamPlayer] = []
var _current := -1
var _track := ""
var _advancing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = Sfx.BUS_MUSIC
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)


## Plays the first of `names` that has a file, crossfading from the current track (nothing if it's already playing, or if it
## is in the same playlist). With none found: the title theme, or, with `keep_if_missing`, whatever is playing.
func play(names: Array, keep_if_missing := false) -> void:
	# Run without sound (`--audio-driver Dummy`, how the test and screenshot runs are launched): no music at all, or the dummy
	# driver keeps the track's playback alive and Godot reports it as leaked at exit.
	if _silent:
		return
	var tracks := names.duplicate()
	if not keep_if_missing:
		tracks.append(DEFAULT_TRACK)
	for track_name in tracks:
		var stream := _load(track_name)
		if stream == null:
			continue
		var set_name := _playlist_of(track_name)
		if track_name == _track or (set_name != "" and set_name == _playlist_of(_track)):
			return
		_start(track_name, stream)
		return


func _start(track_name: String, stream: AudioStream) -> void:
	_track = track_name
	var old := _players[_current] if _current >= 0 else null
	_current = (_current + 1) % 2
	var player := _players[_current]
	player.stream = stream
	player.volume_db = -40.0
	player.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(player, "volume_db", VOLUME_DB, FADE)
	if old:
		tween.tween_property(old, "volume_db", -60.0, FADE)
		tween.chain().tween_callback(old.stop)


func _playlist_of(track_name: String) -> String:
	for set_name: String in PLAYLISTS:
		if track_name in PLAYLISTS[set_name]:
			return set_name
	return ""


# A playlist's track near its end: the next one fades in under it (the last one is followed by the first).
func _process(_delta: float) -> void:
	if _current < 0 or _advancing or _playlist_of(_track) == "":
		return
	var player := _players[_current]
	if not player.playing or player.stream == null:
		return
	if player.stream.get_length() - player.get_playback_position() < FADE:
		_advance()


func _advance() -> void:
	var set: Array = PLAYLISTS[_playlist_of(_track)]
	var next: String = set[(set.find(_track) + 1) % set.size()]
	_advancing = true
	var stream := _load(next)
	if stream:
		_start(next, stream)
	# The new track starts at 0, far from its end, so this can't fire again at once.
	_advancing = false


## At exit: nothing is left playing, so the track is let go before the audio server shuts down.
static var _silent: bool = AudioServer.get_driver_name() == "Dummy"


func _exit_tree() -> void:
	for player in _players:
		player.stop()
		player.stream = null


## Fades the music out (e.g. at bedtime).
func stop() -> void:
	if _current < 0:
		return
	var player := _players[_current]
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, FADE)
	tween.tween_callback(player.stop)
	_track = ""


func _load(track_name: String) -> AudioStream:
	for ext in ["ogg", "mp3", "wav"]:
		var path: String = FOLDER + track_name + "." + ext
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			# A playlist's tracks don't loop on their own: the next one follows.
			var loops := _playlist_of(track_name) == ""
			if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
				stream.loop = loops
			elif stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream.loop_end = int(stream.get_length() * stream.mix_rate)
			return stream
	return null
