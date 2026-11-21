extends Node
## Every wall seen down every cross street must have straight lines (Julien, 2026-11-21: the bricks, the roof lines and the
## floor lines of the vistas were sawtoothed). A picture laid on a receding wall is drawn by `CrossStreet._wall_grid`, which
## measures how much a level line of the picture bends in each cell; this tool loads every street, lets it draw its vistas,
## and fails if any cell bends more than `CrossStreet.MAX_BEND` px, or if nothing was drawn (the check would prove nothing).
## Run it after touching a vista or a wall (a window is needed to draw: it opens, checks and quits by itself, exit code 1 on a
## failure), muted and in the background like every window run:
##   open -W -g -n -a /Applications/Godot.app --stdout F --stderr F --args --path . --screen $(tools/ecran_macbook.sh) \
##     --audio-driver Dummy --quit-after 6000 res://tools/check_walls.tscn -- --no-save

const STREETS := ["main", "sixieme_est", "holt", "cinquieme", "cinquieme_ouest", "dandurand", "dandurand_sud",
	"masson_impair", "masson_pair", "ruelle_dandurand"]


func _ready() -> void:
	Season.current = "winter"
	var bad: Array[String] = []
	for key: String in STREETS:
		CrossStreet.worst_bend = 0.0
		var before := CrossStreet.grids_drawn
		var t0 := Time.get_ticks_msec()
		var scene: Node = load("res://scenes/%s.tscn" % key).instantiate()
		add_child(scene)
		for i in (150 if key.begins_with("masson") else 8):
			await get_tree().process_frame
		var bend := CrossStreet.worst_bend
		print("checked %s: %d wall grids, worst bend %.2f px (%d ms)" % [key, CrossStreet.grids_drawn - before, bend, Time.get_ticks_msec() - t0])
		if bend > CrossStreet.MAX_BEND:
			bad.append("%s bends a level line by %.2f px" % [key, bend])
		scene.queue_free()
		await get_tree().process_frame
	# The source guard: the only textured `draw_polygon` left in the vistas is the screen-parallel face of a tower (`_tower_end`,
	# a flat rectangle, which cannot bend). Any other picture on a receding wall goes through `CrossStreet._wall_grid`.
	var source := FileAccess.get_file_as_string("res://world/cross_street.gd")
	var textured := RegEx.create_from_string("(?s)draw_polygon\\((?:(?!draw_polygon\\().){0,600}?, tex\\)").search_all(source).size()
	if textured > 1:
		bad.append("%d textured draw_polygon calls in world/cross_street.gd: a picture on a receding wall must use _wall_grid" % textured)
	var failed := not bad.is_empty() or CrossStreet.grids_drawn == 0
	print("%s: %d wall grids (%d cells) drawn in all (limit %.2f px)" % ["FAIL" if failed else "OK", CrossStreet.grids_drawn, CrossStreet.grid_cells, CrossStreet.MAX_BEND])
	for b in bad:
		print("  - " + b)
	get_tree().quit(1 if failed else 0)
