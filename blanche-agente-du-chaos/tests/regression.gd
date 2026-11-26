extends SceneTree
## Non-régression des missions de la cuisine : les robots rejouent les missions 1 à 8 avec des graines fixes, et chaque
## partie doit donner exactement le même score et la même suite d'événements que celle enregistrée.
## godot --headless --path . -s res://tests/regression.gd -- --no-save [--ecrire]

const FILE := "res://tests/regression_cuisine.json"
const LEVELS := 8
const PROFILES := ["equilibre_300", "gourmand_300", "novice_700", "campeur_300", "spam_300", "sage_300"]
const GAMES := 3
const DT := 0.05


func _init() -> void:
	var write := OS.get_cmdline_user_args().has("--ecrire")
	var games := {}
	var maps := {}
	for id in range(1, LEVELS + 1):
		var level := Levels.load_level(id)
		var piece := Levels.piece_of(level)
		if not maps.has(piece):
			var map := RoomMap.new(piece)
			maps[piece] = [map, Sim.dog_grid(map), Sim.mom_grid(map)]
		var m: Array = maps[piece]
		for profile: String in PROFILES:
			for g in GAMES:
				games["%d_%s_%d" % [id, profile, g]] = play(m[0], m[1], m[2], level, profile, g)
	if write:
		var f := FileAccess.open(FILE, FileAccess.WRITE)
		f.store_string(JSON.stringify(games, "\t", true))
		f.close()
		print("RÉFÉRENCE ÉCRITE : %d parties" % games.size())
		quit(0)
		return
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	var failures := 0
	if not expected is Dictionary or expected.size() != games.size():
		printerr("référence absente ou incomplète")
		quit(1)
		return
	for key: String in games:
		# Les deux côtés passent par JSON : les entiers relus deviennent des nombres à virgule.
		var now: Variant = JSON.parse_string(JSON.stringify(games[key]))
		if not expected.has(key) or JSON.stringify(expected[key], "", true) != JSON.stringify(now, "", true):
			failures += 1
			if failures <= 8:
				printerr("  partie différente : %s\n    avant %s\n    après %s" % [key, JSON.stringify(expected.get(key)),
					JSON.stringify(games[key])])
	print("NON-RÉGRESSION : %d parties, %d différentes" % [games.size(), failures])
	quit(1 if failures > 0 else 0)


static func play(map: RoomMap, nav: Nav, mom_nav: Nav, level: Dictionary, profile: String, g: int) -> Dictionary:
	var parts := profile.split("_")
	var sim := Sim.new(map, level, 700 + g * 31, nav, mom_nav)
	var bot := Bot.new(sim, parts[0], float(parts[1]) / 1000.0, 0.9, 900 + g)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	var count := 0
	while not sim.over:
		bot.step(DT)
		sim.step(DT, bot.move, bot.grab)
		for e in sim.drain_events():
			count += 1
			ctx.update(("%s@%.4f;" % [e.type, e.time]).to_utf8_buffer())
	return {
		"score": sim.score, "caught": sim.caught_count, "eaten": sim.eaten, "events": count,
		"digest": ctx.finish().hex_encode(), "dog": "%.4f,%.4f" % [sim.dog_pos.x, sim.dog_pos.y],
		"mom": "%.4f,%.4f" % [sim.mom_pos.x, sim.mom_pos.y], "suspicion": "%.4f" % sim.suspicion,
	}
