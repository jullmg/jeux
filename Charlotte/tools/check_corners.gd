extends SceneTree
## Every corner of every street, checked: the building at each corner must look the same seen from either street (Julien,
## 2026-11-19). Loads each street scene, lets it lay out its cross streets, and lists the corners whose two faces are drawn at
## heights too far apart (`StreetScene.corner_mismatches`, see `_join_corners`). Run it after drawing or changing any building
## at a corner:
##   Godot --headless --path . -s res://tools/check_corners.gd -- --no-save
## It prints "OK" or the corners to fix (in the generator, so both faces of the building agree), and quits by itself.

const STREETS := ["main", "sixieme_est", "holt", "cinquieme", "cinquieme_ouest", "dandurand", "dandurand_sud",
	"masson_impair", "masson_pair"]

var _i := 0
var _wait := 0
var _found: Array[String] = []


func _initialize() -> void:
	load("res://world/season.gd").current = "winter"
	create_timer(300.0).timeout.connect(quit)
	_next()


func _next() -> void:
	if _i >= STREETS.size():
		print("OK: every corner building looks the same from both streets." if _found.is_empty() else "%d corner(s) to fix:" % _found.size())
		for f in _found:
			print("  - " + f)
		quit()
		return
	change_scene_to_file("res://scenes/%s.tscn" % STREETS[_i])
	_wait = 3


func _process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		if _wait == 0 and current_scene:
			print("checked ", STREETS[_i], ": ", current_scene.get("_cross_streets").size(), " cross streets")
			for m in current_scene.get("corner_mismatches"):
				_found.append(m)
			_i += 1
			_next()
	return false
