extends Node
## Autoload "Voice": the voice that reads Charlotte's homework out loud. It is the computer's own voice (Godot's
## text to speech, `DisplayServer.tts_*`, which needs `audio/general/text_to_speech` on in the project settings),
## so there is no sound file and no licence, and it can read any sentence we write — « Écris le nombre cent. »
## It asks for a Québec French voice (Amélie on a Mac), a little slower than the machine's own pace because she
## is seven. Nothing is spoken when the sound is muted or when "Voix" is turned off in the options.

const SETTINGS := "user://settings.cfg"
## The French voices we like first, by name: the real Québec ones before the robotic old ones.
const PREFERRED := ["Amélie", "Amelie", "Chantal", "Sandy", "Shelley", "Flo", "Thomas", "Audrey"]
## Read a bit slower than the default: she is still learning to read along.
const RATE := 0.92

var _voice := ""
var _looked := false


## True when the computer has a voice we can use at all (none on a headless run, or with the feature off).
func available() -> bool:
	return not _id().is_empty()


## Reads `text` aloud, cutting short whatever was being said.
func say(text: String) -> void:
	if text.strip_edges().is_empty() or not available() or not enabled():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _id(), 60, 1.0, RATE, 0, true)


func stop() -> void:
	if available():
		DisplayServer.tts_stop()


func speaking() -> bool:
	return available() and DisplayServer.tts_is_speaking()


## Off while the sound is muted, and when the option is unticked.
func enabled() -> bool:
	if AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")):
		return false
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	return bool(cfg.get_value("options", "voice", true))


## Every French voice installed, best first: for the options, and to remember one in the settings.
func voices() -> Array:
	var out: Array = []
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return out
	for one in DisplayServer.tts_get_voices():
		if str(one.get("language", "")).to_lower().begins_with("fr"):
			out.append(one)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _rank(a) < _rank(b))
	return out


# The voice we speak with, looked up once: the one kept in the settings if it is still installed, else the best
# French one, else nothing at all (no voice, or a run without a window).
func _id() -> String:
	if _looked:
		return _voice
	_looked = true
	var french := voices()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	var wanted := str(cfg.get_value("options", "voice_id", ""))
	for one: Dictionary in french:
		if str(one.id) == wanted:
			_voice = wanted
			return _voice
	if not french.is_empty():
		_voice = str(french[0].id)
	return _voice


# Québec French first, then France; inside each, the names we like best.
func _rank(v: Dictionary) -> int:
	var place := PREFERRED.find(str(v.get("name", "")))
	var language := str(v.get("language", "")).to_lower().replace("-", "_")
	return (0 if language.begins_with("fr_ca") else 100) + (place if place >= 0 else PREFERRED.size())
