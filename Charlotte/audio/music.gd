extends Node
## Autoload "Music": the soundtrack (the user's tracks, made with Suno), from audio/music/<name>.mp3 / .ogg / .wav,
## on the "Musique" bus, looping, crossfading from one track to the next. Scenes ask for a track with fallbacks:
## Music.play(["street_winter", "street"]) plays the first that exists; if none exists, whatever is playing
## carries on (so the title theme keeps going until a street theme is added).

const FOLDER := "res://audio/music/"
const VOLUME_DB := -6.0
const FADE := 1.5

var _players: Array[AudioStreamPlayer] = []
var _current := -1
var _track := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = Sfx.BUS_MUSIC
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)


## Plays the first of `names` that has a file, crossfading from the current track (nothing if it's already playing).
func play(names: Array) -> void:
	for track_name in names:
		var stream := _load(track_name)
		if stream == null:
			continue
		if track_name == _track:
			return
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
		return


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
			if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
				stream.loop = true
			elif stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream.loop_end = int(stream.get_length() * stream.mix_rate)
			return stream
	return null
