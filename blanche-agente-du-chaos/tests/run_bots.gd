extends SceneTree
## Fait jouer des robots sur les niveaux et écrit les statistiques en JSON.
## godot --headless --path . -s res://tests/run_bots.gd -- --levels=1,2 --games=100 --profiles=prudent_300 --out=f.json
## Un profil est « style_réactionEnMillisecondes ».

const DT := 0.05


func _init() -> void:
	var levels: Array = range(1, Levels.COUNT + 1)
	var profiles: Array = ["prudent_300", "equilibre_500"]
	var games := 20
	var out := ""
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		match kv[0]:
			"--levels":
				levels = Array(kv[1].split(",")).map(func(s: String) -> int: return int(s))
			"--profiles":
				profiles = Array(kv[1].split(","))
			"--games":
				games = int(kv[1])
			"--out":
				out = kv[1]
	var grids := {}
	var results: Array = []
	for id: int in levels:
		var level := Levels.load_level(id)
		var piece := Levels.piece_of(level)
		if not grids.has(piece):
			var m := RoomMap.new(piece)
			grids[piece] = [m, Sim.dog_grid(m), Sim.mom_grid(m)]
		var map: RoomMap = grids[piece][0]
		var nav: Nav = grids[piece][1]
		var mom_nav: Nav = grids[piece][2]
		for profile: String in profiles:
			results.append(run(map, nav, mom_nav, level, profile, games))
			var r: Dictionary = results.back()
			print("niveau %d %-14s médiane %5d  q25 %5d  q75 %5d  réussite %3d%%  3★ %3d%%  au coin %.1f  trésor %2d%%" % [id,
				profile, r.median, r.q25, r.q75, r.pass_rate, r.three_rate, r.caught, r.treasure])
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(results))
	quit()


static func run(map: RoomMap, nav: Nav, mom_nav: Nav, level: Dictionary, profile: String, games: int) -> Dictionary:
	var parts := profile.split("_")
	var scores: Array[int] = []
	var passed := 0
	var three := 0
	var caught := 0
	var treasure := 0
	var stuck := 0
	for g in games:
		var sim := Sim.new(map, level, 1000 + g, nav, mom_nav)
		var bot := Bot.new(sim, parts[0], float(parts[1]) / 1000.0, 0.9, 5000 + g)
		var still := 0.0
		var last := sim.dog_pos
		var worst := 0.0
		while not sim.over:
			bot.step(DT)
			sim.step(DT, bot.move, bot.grab)
			sim.events.clear()
			# Coincée : elle veut avancer depuis longtemps sans bouger.
			if bot.move.length() > 0.5 and sim.dog_state == Sim.Dog.FREE and sim.dog_pos.distance_to(last) < 0.004:
				still += DT
				worst = maxf(worst, still)
			else:
				still = 0.0
			last = sim.dog_pos
		if worst > 6.0:
			stuck += 1
		scores.append(sim.score)
		caught += sim.caught_count
		treasure += sim.eaten[Sim.Size.TREASURE]
		if sim.stars() >= 1:
			passed += 1
		if sim.stars() >= 3:
			three += 1
	scores.sort()
	return {
		"level": level.id, "profile": profile, "games": games,
		"median": scores[games / 2], "q25": scores[games / 4], "q75": scores[games * 3 / 4],
		"pass_rate": 100.0 * passed / games, "three_rate": 100.0 * three / games,
		"caught": float(caught) / games, "treasure": 100.0 * treasure / games, "stuck": stuck, "scores": scores,
	}
