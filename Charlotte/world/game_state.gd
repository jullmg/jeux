class_name GameState
extends RefCounted
## The game in progress, and its save: where Charlotte is (scene and x), the day, the season, her pocket money,
## the quests and a few story flags. There are SLOTS games side by side: each keeps its save, Charlotte's outfit
## (CharacterLook) and her drawings (DrawingPad) in its own folder, `slot_dir()`. Test runs (--screenshot=, --x=,
## -s scripts) never touch the saves.

const SLOTS := 3
const START_MONEY := 5.0
const START_AGE := 7
## Where the last game played is remembered (with the other settings).
const SETTINGS := "user://settings.cfg"
## The single save of older versions, moved into slot 1.
const OLD_SAVE := "user://save.json"

## Which game is being played (1..SLOTS).
static var slot := 1
## Charlotte's age: she starts at 7 and grows up slowly (a whole year of seasons and many quests).
static var age := START_AGE
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


static func slot_dir(n := 0) -> String:
	return "user://slots/%d" % (n if n > 0 else slot)


static func save_path(n := 0) -> String:
	return slot_dir(n) + "/save.json"


static func has_save(n := 0) -> bool:
	return FileAccess.file_exists(save_path(n))


static func any_save() -> bool:
	for n in range(1, SLOTS + 1):
		if has_save(n):
			return true
	return false


## The game played last (to "Continuer"), or the first one saved.
static func last_slot() -> int:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	var n := int(cfg.get_value("game", "last_slot", 1))
	if has_save(n):
		return n
	for k in range(1, SLOTS + 1):
		if has_save(k):
			return k
	return 1


static func _remember_slot() -> void:
	if not enabled():
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("game", "last_slot", slot)
	cfg.save(SETTINGS)


## What a saved game looks like, for the list of games: {season, age, money, stars}, or {} if the slot is empty.
static func summary(n: int) -> Dictionary:
	if not has_save(n):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path(n)))
	if not data is Dictionary:
		return {}
	var stars := 0
	for state in (data.get("quests", {}) as Dictionary).values():
		if state == "done":
			stars += 1
	return {"season": str(data.get("season", "autumn")), "age": int(data.get("age", START_AGE)),
		"money": float(data.get("money", START_MONEY)), "stars": stars}


## Moves the single save of older versions (and its outfit and drawings) into slot 1.
static func migrate() -> void:
	if not enabled() or not FileAccess.file_exists(OLD_SAVE) or has_save(1):
		return
	DirAccess.make_dir_recursive_absolute(slot_dir(1) + "/drawings")
	var root := DirAccess.open("user://")
	root.rename("save.json", "slots/1/save.json")
	if root.file_exists("charlotte_outfit.tres"):
		root.rename("charlotte_outfit.tres", "slots/1/charlotte_outfit.tres")
	var old := DirAccess.open("user://drawings")
	if old:
		for name in old.get_files():
			old.rename(name, ProjectSettings.globalize_path(slot_dir(1) + "/drawings/" + name))


static func save_game(scene: String, x: float) -> void:
	if not enabled() or scene.is_empty():
		return
	var data := {
		"version": 2, "scene": scene, "x": x,
		"day": Season.day, "season": Season.current, "age": age,
		"money": money, "quests": quests, "flags": flags,
	}
	DirAccess.make_dir_recursive_absolute(slot_dir())
	var file := FileAccess.open(save_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


## Restores game `n` and puts Charlotte back where she was; returns the scene to load ("" if none).
static func load_game(n: int) -> String:
	if not has_save(n):
		return ""
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path(n)))
	if not data is Dictionary:
		return ""
	slot = n
	_remember_slot()
	CharacterLook.reload_outfit()
	Season.day = int(data.get("day", 1))
	Season.current = str(data.get("season", "autumn"))
	age = int(data.get("age", START_AGE))
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


## A fresh start in slot `n`: day 1 in autumn, starting money, no quests done, her usual dress, a bare fridge.
static func new_game(n := 1) -> void:
	slot = n
	Season.day = 1
	Season.current = "autumn"
	age = START_AGE
	money = START_MONEY
	quests = {}
	flags = {}
	Transition.street_x = NAN
	Transition.inside_x = NAN
	if enabled():
		erase(n)
		_remember_slot()
	CharacterLook.reload_outfit()


## Deletes game `n`: its save, outfit and drawings.
static func erase(n: int) -> void:
	if not enabled():
		return
	for folder in [slot_dir(n) + "/drawings", slot_dir(n)]:
		var dir := DirAccess.open(folder)
		if dir:
			for name in dir.get_files():
				dir.remove(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_dir(n) + "/drawings"))
