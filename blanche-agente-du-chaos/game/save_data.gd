class_name SaveData
extends RefCounted
## La progression et les options, dans un fichier JSON de user://.
## Un fichier absent, abîmé ou d'une autre version ne fait jamais planter : on repart de valeurs sûres.

const VERSION := 1
const DEFAULT_OPTIONS := {
	"music": 0.7, "sfx": 0.9, "fullscreen": false, "reduced_motion": false, "long_hints": false,
}

## Vide pour les essais (`--no-save`) : rien n'est lu ni écrit.
var path: String
var unlocked := 1
var stars: Dictionary = {}
var best: Dictionary = {}
var options: Dictionary = DEFAULT_OPTIONS.duplicate()
var finished_seen := false


func _init(path_ := "user://save.json") -> void:
	path = path_
	load_file()


func reset_defaults() -> void:
	unlocked = 1
	stars = {}
	best = {}
	options = DEFAULT_OPTIONS.duplicate()
	finished_seen = false


func load_file() -> void:
	reset_defaults()
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		# On garde le fichier abîmé à côté plutôt que de l'écraser sans trace.
		DirAccess.copy_absolute(path, path + ".abime")
		return
	var d: Dictionary = json.data
	unlocked = clampi(int(_number(d.get("unlocked"), 1)), 1, Levels.COUNT)
	finished_seen = d.get("finished_seen") == true
	for pair: Array in [[d.get("stars"), stars, 3], [d.get("best"), best, 1000000]]:
		if pair[0] is Dictionary:
			for key: String in pair[0]:
				var id := int(key)
				if id >= 1 and id <= Levels.COUNT:
					pair[1][str(id)] = clampi(int(_number(pair[0][key], 0)), 0, pair[2])
	var o: Variant = d.get("options")
	if o is Dictionary:
		for key: String in DEFAULT_OPTIONS:
			var def: Variant = DEFAULT_OPTIONS[key]
			if def is bool and o.get(key) is bool:
				options[key] = o[key]
			elif def is float:
				options[key] = clampf(_number(o.get(key), def), 0.0, 1.0)


static func _number(v: Variant, fallback: float) -> float:
	if v is float or v is int:
		return float(v)
	return fallback


func save_file() -> bool:
	if path == "":
		return false
	var data := {"version": VERSION, "unlocked": unlocked, "stars": stars, "best": best, "options": options,
		"finished_seen": finished_seen}
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return DirAccess.rename_absolute(tmp, path) == OK


## Efface la progression, mais garde les options.
func erase_progress() -> void:
	var keep := options.duplicate()
	reset_defaults()
	options = keep
	save_file()


func stars_of(level: int) -> int:
	return int(stars.get(str(level), 0))


func best_of(level: int) -> int:
	return int(best.get(str(level), 0))


func total_stars() -> int:
	var n := 0
	for id in range(1, Levels.COUNT + 1):
		n += stars_of(id)
	return n


## Note le résultat d'un niveau ; vrai si c'est un nouveau record.
func record(level: int, score: int, got: int) -> bool:
	var new_best := score > best_of(level)
	if new_best:
		best[str(level)] = score
	if got > stars_of(level):
		stars[str(level)] = got
	if got >= 1:
		unlocked = maxi(unlocked, mini(Levels.COUNT, level + 1))
	save_file()
	return new_best
