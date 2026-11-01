class_name GameState
extends RefCounted
## The game in progress, and its save file: where Charlotte is (scene and x), the day, the season, her pocket money,
## the quests and a few story flags. Her drawings (DrawingPad) and her outfit (CharacterLook) keep their own files;
## a new game clears them too. Test runs (--screenshot=, --x=, -s scripts) never touch the save.

const SAVE_PATH := "user://save.json"
const START_MONEY := 5.0

static var money := START_MONEY
## Quest id → "active" or "done" (see Quests).
static var quests := {}
## Story flags, e.g. "has_milk".
static var flags := {}


## Saving is off for test runs, so they never overwrite a real game.
static func enabled() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot=") or arg.begins_with("--x="):
			return false
	var args := OS.get_cmdline_args()
	return not (args.has("-s") or args.has("--script"))


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func save_game(scene: String, x: float) -> void:
	if not enabled() or scene.is_empty():
		return
	var data := {
		"version": 1, "scene": scene, "x": x,
		"day": Season.day, "season": Season.current,
		"money": money, "quests": quests, "flags": flags,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


## Restores the saved game and puts Charlotte back where she was; returns the scene to load ("" if none).
static func load_game() -> String:
	if not has_save():
		return ""
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		return ""
	Season.day = int(data.get("day", 1))
	Season.current = str(data.get("season", "autumn"))
	money = float(data.get("money", START_MONEY))
	quests = data.get("quests", {})
	flags = data.get("flags", {})
	var scene := str(data.get("scene", ""))
	var x := float(data.get("x", NAN))
	if scene.contains("/scenes/house") or scene.contains("/scenes/depanneur"):
		Transition.inside_x = x
	else:
		Transition.street_x = x
	return scene


## A fresh start: day 1 in autumn, starting money, no quests done, her usual dress, a bare fridge.
static func new_game() -> void:
	Season.day = 1
	Season.current = "autumn"
	money = START_MONEY
	quests = {}
	flags = {}
	Transition.street_x = NAN
	Transition.inside_x = NAN
	if enabled():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		CharacterLook.forget_outfit()
		DrawingPad.forget_all()
