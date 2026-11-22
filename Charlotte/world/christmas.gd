class_name Christmas
extends RefCounted
## Christmas (quest "noel", winter, after the tree; Julien), the long quest of the winter as Halloween is the autumn's, step by
## step (`GameState.flags.noel_step`), all at home (`house.gd`):
##   1. Maman asks whether she has written to Santa: at her desk the drawing pad opens on the letter ("Pour le père Noël !");
##      she carries it (`Carry` "lettre") to Maman, who will post it to the North Pole, H0H 0H0 (Canada Post's real one);
##   2. cookies for Santa with Maman at the kitchen counter (`BAKE`: mix, cut, ice), then the plate and a glass of milk in her
##      arms (`Carry` "biscuits") to put under the tree;
##   3. the réveillon at the dining table: candles, tourtière, bûche de Noël, then off to bed;
##   4. bed: "Bonne nuit… le père Noël s'en vient !", sleigh bells, a sleigh crossing the night;
##   5. Christmas morning: the plate empty but for crumbs, Santa's note, and the presents under the tree (`PRESENTS`); she opens
##      them, the family wishes each other a merry Christmas, and the quest is done. Her capybara plush sits on her bed after
##      (`flags.noel_capybara`).

const QUEST := "noel"
const STEP := "noel_step"
const BAKED := "noel_baked"
const OPENED := "noel_opened"
const PLUSH := "noel_capybara"
const PLATE := "noel_plate"
const HEADING := "🎅  Noël"
## Baking with Maman, one click each: what Charlotte says, what Maman says.
const BAKE := [
	["On mélange la pâte !", "Doucement, pour pas en mettre partout !"],
	["Je découpe des bonhommes pis des étoiles !", "Oh, qu'ils sont beaux !"],
	["Pis du glaçage rouge pis vert !", "Ding ! Les biscuits sont prêts !"],
]
## The réveillon, around the table: [who (0 Papa, 1 Maman, -1 Charlotte), line].
const REVEILLON := [
	[0, "De la tourtière ! Mon plat préféré du temps des Fêtes."],
	[1, "Pis du ragoût de boulettes, comme chez ta grand-mère."],
	[-1, "Pis une bûche de Noël pour dessert ? Miam !"],
	[0, "Joyeux réveillon, mes amours !"],
	[1, "Astheure, au lit, ma chouette ! Le père Noël passe\njuste quand les enfants dorment."],
]
## The presents under the tree (six, Julien: "at least five, and much better looking"): id, what she says opening it. The order is
## the order of `present(kind)`: its wrapping.
const PRESENTS := [
	["capybara", "Une peluche de capybara ! Avec une orange sur la tête !"],
	["crayons", "Une grosse boîte de crayons de toutes les couleurs !"],
	["livre", "Un livre d'histoires ! « Le petit renard des neiges » !"],
	["jeu", "Un jeu de serpents pis échelles, avec des dés !"],
	["mitaines", "Des mitaines pis une tuque toutes douces ! Pour l'hiver !"],
	["patins", "Des patins à glace ! Je vais patiner avec Papa !"],
]


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


## Her plate for Santa, drawn by `CookieStudio` with her own cookies: where the two pictures (the full plate and, for the morning,
## the crumbs) are kept in her game's folder.
static var _plate_cache := {}


static func plate_path(eaten: bool) -> String:
	return GameState.slot_dir() + ("/biscuits_manges.png" if eaten else "/biscuits_pere_noel.png")


static func save_plate(full: Image, eaten: Image, plate: String, drink: String) -> void:
	DirAccess.make_dir_recursive_absolute(GameState.slot_dir())
	full.save_png(plate_path(false))
	eaten.save_png(plate_path(true))
	GameState.flags[BAKED] = BAKE.size()
	GameState.flags[PLATE] = {"plate": plate, "drink": drink}
	_plate_cache.clear()


## What she chose to drink with them ("lait", "chocolat", "chaud"), "" before the cookies are made.
static func drink() -> String:
	return str(GameState.flags.get(PLATE, {}).get("drink", ""))


static func baked() -> int:
	return int(GameState.flags.get(BAKED, 0))


static func opened() -> Array:
	return GameState.flags.get(OPENED, [])


static func open_present(id: String) -> void:
	var now := opened().duplicate()
	if id not in now:
		now.append(id)
	GameState.flags[OPENED] = now


static func has_plush() -> bool:
	return GameState.flags.get(PLUSH, false)


static func clear() -> void:
	for key in [STEP, BAKED, OPENED, PLUSH, PLATE]:
		GameState.flags.erase(key)
	for eaten in [false, true]:
		if FileAccess.file_exists(plate_path(eaten)):
			DirAccess.remove_absolute(plate_path(eaten))
	_plate_cache.clear()


static func hint() -> String:
	match step():
		1:
			if Carry.has("lettre"):
				return "Donne ta lettre à Maman : elle va la poster au Pôle Nord."
			return "Écris ta lettre au père Noël, à ton bureau dans ta chambre."
		2:
			if Carry.has("biscuits"):
				return "Mets l'assiette de biscuits pis le verre de lait sous le sapin, dans le salon."
			return "Fais des biscuits pour le père Noël avec Maman, au comptoir de la cuisine : mélange, étends, découpe, cuis et décore !"
		3:
			return "C'est le réveillon ! Va à la table de la salle à manger, dans le salon."
		4:
			return "Va te coucher : le père Noël passe juste quand les enfants dorment !"
		5:
			return "C'est le matin de Noël ! Ouvre tes cadeaux sous le sapin."
	return str(Quests.ALL[QUEST].hint)


# ── Pictures ────────────────────────────────────────────────

## Canvas 90 × 64: her letter to Santa in its envelope, a red stamp, the address in lines (words don't render in these).
static func letter() -> ImageTexture:
	var s := '<rect x="4" y="6" width="82" height="54" rx="3" fill="#FFFDF5" stroke="#B8A98A" stroke-width="2"/>'
	s += '<path d="M4 8 L45 36 L86 8" stroke="#C9BBA0" stroke-width="2" fill="none"/>'
	s += '<rect x="66" y="12" width="14" height="16" fill="#D42A3A" stroke="#7E1418" stroke-width="1.5"/><path d="M70 22 l3 -5 l3 5 Z" fill="#FFFFFF"/>'
	for i in 3:
		s += '<path d="M%d %d H%d" stroke="#2E6FD8" stroke-width="2"/>' % [30, 40 + i * 6, 64 - i * 6]
	s += '<path d="M14 50 q4 -6 8 0 q4 6 8 0" stroke="#E5383B" stroke-width="2" fill="none"/>'
	return InteriorArt.tex(90, 64, s)


## Canvas 110 × 80: a plate of iced cookies (gingerbread men, stars) and a glass of milk; `eaten`: only crumbs and an empty
## glass are left, and Santa's folded note.
static func cookies(eaten := false) -> ImageTexture:
	if GameState.flags.has(PLATE) and FileAccess.file_exists(plate_path(eaten)):
		if not _plate_cache.has(eaten):
			var img := Image.load_from_file(plate_path(eaten))
			img.convert(Image.FORMAT_RGBA8)
			img.resize(110, 80, Image.INTERPOLATE_LANCZOS)
			img.generate_mipmaps()
			_plate_cache[eaten] = ImageTexture.create_from_image(img)
		return _plate_cache[eaten]
	var s := '<ellipse cx="46" cy="64" rx="42" ry="11" fill="#FFFFFF" stroke="#B8C4D0" stroke-width="2"/>'
	s += '<ellipse cx="46" cy="62" rx="32" ry="7" fill="#EEF3F8"/>'
	if eaten:
		for p in [[30, 62], [40, 60], [52, 63], [60, 61], [45, 64]]:
			s += '<circle cx="%d" cy="%d" r="1.8" fill="#B5793F"/>' % p
		s += '<rect x="14" y="40" width="26" height="18" rx="2" fill="#FFFDF5" stroke="#C9BBA0" stroke-width="1.5" transform="rotate(-8 27 49)"/>'
		s += '<path d="M18 46 H34 M18 51 H30" stroke="#D42A3A" stroke-width="1.5" transform="rotate(-8 27 49)"/>'
	else:
		# A gingerbread man, a star, another man.
		for k in 2:
			var x := 28.0 + k * 34.0
			s += '<circle cx="%s" cy="44" r="6" fill="#B5793F" stroke="#7E4E22" stroke-width="1.5"/>' % x
			s += '<path d="M%s 50 h12 l4 6 h-6 v8 h-4 v-5 h-0 v5 h-4 v-8 h-6 Z" fill="#B5793F" stroke="#7E4E22" stroke-width="1.5"/>' % (x - 6.0)
			s += '<path d="M%s 54 h6" stroke="#FFFFFF" stroke-width="1.6"/><circle cx="%s" cy="57" r="1.2" fill="#D42A3A"/>' % [x - 3.0, x]
		var star := ""
		for i in 10:
			var a := -PI / 2.0 + i * PI / 5.0
			var r := 10.0 if i % 2 == 0 else 4.5
			star += "%.1f,%.1f " % [45.0 + cos(a) * r, 56.0 + sin(a) * r]
		s += '<polygon points="%s" fill="#E9B824" stroke="#A8801A" stroke-width="1.2"/>' % star
		s += '<path d="M40 56 h10" stroke="#3BAA5C" stroke-width="2"/>'
	# The glass of milk.
	s += '<path d="M82 22 H104 L101 70 H85 Z" fill="#E6F0FA" stroke="#9FB2C6" stroke-width="2"/>'
	if not eaten:
		s += '<path d="M83 30 H103 L101 69 H85 Z" fill="#FFFFFF"/>'
	else:
		s += '<path d="M85 64 H101 L101 69 H85 Z" fill="#FFFFFF" opacity="0.8"/>'
	s += '<path d="M86 26 L88 64" stroke="#FFFFFF" stroke-width="2" opacity="0.7"/>'
	return InteriorArt.tex(110, 80, s)


## Canvas 120 × 110: a wrapped present, its foot on the bottom edge. `kind` (0 to 5, the order of `PRESENTS`): 0 a big red box with a
## gold bow, 1 green with white dots and a red ribbon, 2 blue with snowflakes (a flat one, the book), 3 kraft paper with twine and holly
## (a flat game box), 4 pink with gold stars and curling ribbon, 5 a tall gift bag with tissue paper. `open`: the lid off and tissue
## paper spilling out, the wrapping lying about.
static func present(kind: int, open := false) -> ImageTexture:
	var s := '<ellipse cx="62" cy="104" rx="46" ry="6" fill="#000000" opacity="0.16"/>'
	if kind == 5:
		return InteriorArt.tex(120, 110, s + _gift_bag(open))
	var spec: Array = [
		# w, h, paper, shade, ribbon, pattern, bow
		[74.0, 58.0, "#C8202A", "#9E1620", "#E9B824", "plain", "gold"],
		[60.0, 50.0, "#2F7A45", "#1F5A32", "#D42A3A", "dots", "red"],
		[84.0, 38.0, "#3A78C9", "#2858A0", "#EEF4FA", "snow", "white"],
		[80.0, 34.0, "#C9A06A", "#A87F48", "#7A5632", "kraft", "twine"],
		[56.0, 56.0, "#EE7BB0", "#C4558A", "#F2C230", "stars", "gold"],
	][kind]
	var w: float = spec[0]
	var h: float = spec[1]
	var paper: String = spec[2]
	var shade: String = spec[3]
	var ribbon: String = spec[4]
	var depth := Vector2(14.0, -12.0)
	var x0 := 60.0 - (w + depth.x) / 2.0
	var y1 := 100.0
	var y0 := y1 - h
	var light := Color(paper).lightened(0.22).to_html(false)
	# Front, right side, top (an open box shows its dark inside instead of a lid).
	var body := ""
	body += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [x0, y0, w, h, paper]
	body += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [x0 + w, y0, x0 + w + depth.x, y0 + depth.y, x0 + w + depth.x, y1 + depth.y, x0 + w, y1, shade]
	if open:
		body += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [x0, y0, x0 + w, y0, x0 + w + depth.x, y0 + depth.y, x0 + depth.x, y0 + depth.y, shade]
		body += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="#2A1A12" opacity="0.8"/>' % [x0 + 4.0, y0, x0 + w - 4.0, y0, x0 + w + depth.x - 4.0, y0 + depth.y + 2.0, x0 + depth.x + 4.0, y0 + depth.y + 2.0]
	else:
		body += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="#%s"/>' % [x0, y0, x0 + w, y0, x0 + w + depth.x, y0 + depth.y, x0 + depth.x, y0 + depth.y, light]
	body += _wrap_pattern(spec[5], x0, y0, w, h, ribbon)
	var rx := x0 + w / 2.0 - 5.0
	body += '<rect x="%s" y="%s" width="10" height="%s" fill="%s"/>' % [rx, y0, h, ribbon]
	if not open:
		body += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s"/>' % [rx, y0, rx + 10.0, y0, rx + 10.0 + depth.x, y0 + depth.y, rx + depth.x, y0 + depth.y, '#' + Color(ribbon).lightened(0.15).to_html(false)]
	body += '<rect x="%s" y="%s" width="%s" height="9" fill="%s" opacity="0.85"/>' % [x0, y0 + h / 2.0 - 4.5, w, ribbon]
	body += '<path d="M%s %s v%s" stroke="#FFFFFF" stroke-width="1.5" opacity="0.35" fill="none"/>' % [x0 + 3.0, y0 + 3.0, h - 6.0]
	body += '<path d="M%s %s h%s v%s h-%s Z M%s %s l%s %s" fill="none" stroke="#00000044" stroke-width="1.6" stroke-linejoin="round"/>' % [x0, y0, w, h, w, x0 + w, y0, depth.x, depth.y]
	var bow_at := Vector2(rx + 5.0 + depth.x / 2.0, y0 + depth.y / 2.0)
	if open:
		# The lid leans against the box; tissue paper in puffs comes out of it; the bow lies on the floor.
		var lid := '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s" stroke="#00000055" stroke-width="1.6"/>' % [x0 + w + 4.0, y0 + 6.0, x0 + w + 22.0, y0 - 22.0, x0 + w + 36.0, y0 - 10.0, x0 + w + 18.0, y0 + 16.0, paper]
		lid += '<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s" opacity="0.9"/>' % [x0 + w + 22.0, y0 - 4.0, x0 + w + 26.0, y0 - 11.0, x0 + w + 30.0, y0 - 7.0, x0 + w + 26.0, y0, ribbon]
		var tissue := ""
		for k in 4:
			var cx := x0 + 14.0 + k * (w - 26.0) / 3.0 + depth.x / 2.0
			var top := y0 - 14.0 - (k % 2) * 8.0
			tissue += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s" stroke="#D0D6DE" stroke-width="1.2"/>' % [cx - 12.0, y0 + 2.0, cx - 12.0, top, cx, top + 4.0, cx + 12.0, top - 2.0, cx + 12.0, y0 + 2.0, "#FFFFFF" if k % 2 == 0 else "#FFE9F2"]
		return InteriorArt.tex(120, 110, s + body + tissue + lid + _loose_bow(Vector2(x0 - 6.0, y1 - 4.0), ribbon))
	body += _bow(bow_at, ribbon, str(spec[6]))
	body += _tag(Vector2(x0 + 6.0, y0 + h - 16.0))
	return InteriorArt.tex(120, 110, s + body)


static func _wrap_pattern(kind: String, x0: float, y0: float, w: float, h: float, ribbon: String) -> String:
	var s := ""
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	match kind:
		"dots":
			for k in 16:
				s += '<circle cx="%s" cy="%s" r="2.6" fill="#FFFFFF" opacity="0.85"/>' % [x0 + 5.0 + rng.randf() * (w - 10.0), y0 + 5.0 + rng.randf() * (h - 10.0)]
		"snow":
			for k in 9:
				var cx := x0 + 8.0 + rng.randf() * (w - 16.0)
				var cy := y0 + 7.0 + rng.randf() * (h - 14.0)
				for a in 3:
					var ang := a * PI / 3.0
					s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="#FFFFFF" stroke-width="1.3" opacity="0.9"/>' % [cx - cos(ang) * 4.5, cy - sin(ang) * 4.5, cx + cos(ang) * 4.5, cy + sin(ang) * 4.5]
		"stars":
			for k in 10:
				var cx := x0 + 7.0 + rng.randf() * (w - 14.0)
				var cy := y0 + 7.0 + rng.randf() * (h - 14.0)
				var star := ""
				for i in 10:
					var a := -PI / 2.0 + i * PI / 5.0
					star += "%.1f,%.1f " % [cx + cos(a) * (3.6 if i % 2 == 0 else 1.5), cy + sin(a) * (3.6 if i % 2 == 0 else 1.5)]
				s += '<polygon points="%s" fill="#FFE27A" opacity="0.95"/>' % star
		"kraft":
			for k in 7:
				s += '<path d="M%s %s h%s" stroke="#8A6A3A" stroke-width="0.8" opacity="0.4"/>' % [x0 + 4.0 + rng.randf() * 10.0, y0 + 5.0 + k * (h / 7.5), 30.0 + rng.randf() * 36.0]
	return s


static func _bow(at: Vector2, ribbon: String, style: String) -> String:
	var dark := '#' + Color(ribbon).darkened(0.3).to_html(false)
	if style == "twine":
		# Twine knotted into a bow, a sprig of holly and two berries.
		var s := '<path d="M%s %s q-14 -12 -16 -2 q2 8 16 2 q14 6 16 -2 q-2 -10 -16 2" fill="none" stroke="#7A5632" stroke-width="2"/>' % [at.x, at.y]
		s += '<path d="M%s %s q-8 -10 -16 -4 q4 8 16 4 M%s %s q8 -10 16 -4 q-4 8 -16 4" fill="#2F7A45" stroke="#1F5A32" stroke-width="1"/>' % [at.x + 4.0, at.y - 2.0, at.x + 4.0, at.y - 2.0]
		s += '<circle cx="%s" cy="%s" r="2.6" fill="#D42A3A"/><circle cx="%s" cy="%s" r="2.4" fill="#D42A3A"/>' % [at.x + 2.0, at.y - 3.0, at.x + 7.0, at.y - 2.0]
		return s
	var s := '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s" stroke="%s" stroke-width="1.5"/>' % [at.x, at.y, at.x - 18.0, at.y - 22.0, at.x - 24.0, at.y - 4.0, at.x - 12.0, at.y + 8.0, at.x, at.y, ribbon, dark]
	s += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s" stroke="%s" stroke-width="1.5"/>' % [at.x, at.y, at.x + 18.0, at.y - 22.0, at.x + 24.0, at.y - 4.0, at.x + 12.0, at.y + 8.0, at.x, at.y, ribbon, dark]
	s += '<path d="M%s %s q-10 -6 -16 -2" stroke="%s" stroke-width="1.4" fill="none" opacity="0.5"/>' % [at.x - 4.0, at.y - 4.0, '#' + Color(ribbon).lightened(0.5).to_html(false)]
	s += '<circle cx="%s" cy="%s" r="5" fill="%s" stroke="%s" stroke-width="1.3"/>' % [at.x, at.y, ribbon, dark]
	s += '<path d="M%s %s q-6 12 -2 20 M%s %s q6 10 10 16" stroke="%s" stroke-width="3" fill="none" stroke-linecap="round"/>' % [at.x - 1.0, at.y + 4.0, at.x + 1.0, at.y + 4.0, ribbon]
	return s


static func _loose_bow(at: Vector2, ribbon: String) -> String:
	var dark := '#' + Color(ribbon).darkened(0.3).to_html(false)
	return '<path d="M%s %s q-10 -12 -14 -2 q4 8 14 2 q10 6 14 -2 q-4 -10 -14 2" fill="%s" stroke="%s" stroke-width="1.4"/><circle cx="%s" cy="%s" r="3.4" fill="%s"/>' % [at.x, at.y, ribbon, dark, at.x, at.y, dark]


## A little paper tag on a string, hung on the front's corner.
static func _tag(at: Vector2) -> String:
	var s := '<path d="M%s %s q-4 -6 2 -10" stroke="#7A5632" stroke-width="1" fill="none"/>' % [at.x + 4.0, at.y]
	s += '<polygon points="%s,%s %s,%s %s,%s %s,%s %s,%s" fill="#FFFDF5" stroke="#B8A98A" stroke-width="1" transform="rotate(-8 %s %s)"/>' % [at.x, at.y, at.x + 8.0, at.y, at.x + 11.0, at.y + 4.0, at.x + 11.0, at.y + 14.0, at.x, at.y + 14.0, at.x, at.y]
	s += '<path d="M%s %s h6 M%s %s h5" stroke="#C8283A" stroke-width="1" transform="rotate(-8 %s %s)"/>' % [at.x + 2.0, at.y + 7.0, at.x + 2.0, at.y + 10.0, at.x, at.y]
	return s


## A tall gift bag: gold with white snowflakes, two cord handles, tissue paper (red and white) coming out of the top.
static func _gift_bag(open: bool) -> String:
	var s := ""
	var tissue := '<path d="M34 40 Q30 14 46 22 Q50 2 60 20 Q70 4 78 22 Q92 14 86 40 Z" fill="#FFFFFF" stroke="#D9DEE6" stroke-width="1.4"/>'
	tissue += '<path d="M44 40 Q42 20 54 26 Q58 10 64 28 Q74 18 76 40 Z" fill="#FF9EC4" opacity="0.95"/>'
	if open:
		tissue = '<path d="M30 42 Q18 8 42 18 Q50 -2 62 16 Q78 -4 88 20 Q106 12 92 42 Z" fill="#FFFFFF" stroke="#D9DEE6" stroke-width="1.4"/>'
		tissue += '<path d="M40 42 Q34 14 52 22 Q60 6 68 22 Q82 12 80 42 Z" fill="#FF9EC4" opacity="0.95"/><path d="M52 40 Q56 20 64 40 Z" fill="#F2C230"/>'
	s += tissue
	s += '<polygon points="28,40 92,40 98,102 22,102" fill="#E9B824" stroke="#A8801A" stroke-width="2"/>'
	s += '<polygon points="92,40 98,102 106,98 100,38" fill="#C99A18"/>'
	s += '<polygon points="28,40 92,40 94,52 26,52" fill="#F2C94A"/>'
	for k in 7:
		var cx := 36.0 + (k % 3) * 24.0 + (k / 3) * 9.0
		var cy := 62.0 + (k / 3) * 14.0
		for a in 3:
			var ang := a * PI / 3.0
			s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="#FFFFFF" stroke-width="1.6" opacity="0.9"/>' % [cx - cos(ang) * 5.5, cy - sin(ang) * 5.5, cx + cos(ang) * 5.5, cy + sin(ang) * 5.5]
	s += '<path d="M44 40 Q44 26 56 26 M76 40 Q76 26 64 26" stroke="#E5383B" stroke-width="3" fill="none"/>'
	s += '<circle cx="28" cy="46" r="2.5" fill="#FFFFFF" stroke="#A8801A" stroke-width="1"/><circle cx="92" cy="46" r="2.5" fill="#FFFFFF" stroke="#A8801A" stroke-width="1"/>'
	s += '<path d="M31 46 Q60 70 89 46" stroke="#E5383B" stroke-width="2.6" fill="none" opacity="0.9"/>'
	s += _tag(Vector2(70.0, 88.0))
	return s


## What each present holds, drawn for the moment she opens it (canvas 110 × 90 unless said), by `PRESENTS` id.
static func gift_picture(id: String) -> ImageTexture:
	match id:
		"capybara":
			return capybara_plush()
		"crayons":
			return crayons()
		"livre":
			return picture_book()
		"jeu":
			return board_game()
		"mitaines":
			return mittens()
		"patins":
			return skates()
	return crayons()


## A picture book standing open-faced: a fox in the snow on its blue cover, the pages' edges.
static func picture_book() -> ImageTexture:
	var s := '<ellipse cx="55" cy="84" rx="40" ry="5" fill="#000000" opacity="0.15"/>'
	s += '<polygon points="22,12 88,12 92,16 92,80 88,84 22,84" fill="#F4EEE2" stroke="#B8A98A" stroke-width="1.5"/>'
	s += '<rect x="14" y="8" width="72" height="74" rx="4" fill="#3A78C9" stroke="#1E4A8A" stroke-width="2.5"/>'
	s += '<rect x="14" y="8" width="8" height="74" fill="#2858A0"/>'
	s += '<rect x="26" y="16" width="52" height="46" rx="3" fill="#BFE0F5" stroke="#FFFFFF" stroke-width="1.5"/>'
	s += '<path d="M26 52 Q40 44 52 50 Q66 42 78 50 V62 H26 Z" fill="#FFFFFF"/>'
	# The fox.
	s += '<path d="M40 52 Q38 38 50 36 Q60 36 62 44 L70 40 Q68 52 60 54 Z" fill="#E8742A" stroke="#A8480E" stroke-width="1.4"/>'
	s += '<path d="M42 38 L40 28 L48 34 Z M54 36 L58 27 L60 37 Z" fill="#E8742A" stroke="#A8480E" stroke-width="1.2"/>'
	s += '<path d="M62 44 Q76 40 74 52 Q68 54 62 50 Z" fill="#FFFFFF" stroke="#A8480E" stroke-width="1.2"/>'
	s += '<circle cx="48" cy="42" r="1.2" fill="#2A1A0E"/><circle cx="46" cy="45" r="1.4" fill="#2A1A0E"/>'
	for k in 7:
		s += '<circle cx="%d" cy="%d" r="1.3" fill="#FFFFFF"/>' % [30 + k * 8, 20 + (k * 7) % 22]
	s += '<rect x="30" y="66" width="44" height="6" rx="2" fill="#F2C230"/><path d="M34 69 h36" stroke="#A8801A" stroke-width="1.2"/>'
	return InteriorArt.tex(110, 90, s)


## A board game box: its lid's winding path, snakes and ladders, a pair of dice leaning on it.
static func board_game() -> ImageTexture:
	var s := '<ellipse cx="55" cy="82" rx="46" ry="5" fill="#000000" opacity="0.15"/>'
	s += '<polygon points="10,30 92,30 100,22 100,70 92,78 10,78" fill="#7A5632"/>'
	s += '<rect x="8" y="22" width="84" height="56" rx="3" fill="#F4E4B8" stroke="#7A5632" stroke-width="2.5"/>'
	for r in 4:
		for c in 6:
			var col: String = ["#E5383B", "#F2C230", "#3BAA5C", "#3A78C9"][(r + c) % 4]
			s += '<rect x="%d" y="%d" width="13" height="12" fill="%s" opacity="0.85"/>' % [12 + c * 13, 26 + r * 12, col]
	s += '<path d="M24 62 L36 38" stroke="#7A5632" stroke-width="3"/><path d="M28 62 L40 38" stroke="#7A5632" stroke-width="3"/>'
	s += '<path d="M62 32 Q70 40 60 46 Q50 52 62 58 Q70 62 66 68" stroke="#2F7A45" stroke-width="3.5" fill="none" stroke-linecap="round"/><circle cx="62" cy="32" r="3" fill="#2F7A45"/>'
	s += '<rect x="62" y="58" width="18" height="18" rx="3" fill="#FFFFFF" stroke="#8A8A94" stroke-width="1.5" transform="rotate(14 71 67)"/>'
	for p in [[66, 62], [76, 72], [71, 67]]:
		s += '<circle cx="%d" cy="%d" r="1.8" fill="#2A2A32" transform="rotate(14 71 67)"/>' % p
	s += '<rect x="84" y="62" width="16" height="16" rx="3" fill="#E5383B" stroke="#8A1A20" stroke-width="1.5" transform="rotate(-10 92 70)"/>'
	for p in [[88, 66], [96, 74]]:
		s += '<circle cx="%d" cy="%d" r="1.8" fill="#FFFFFF" transform="rotate(-10 92 70)"/>' % p
	return InteriorArt.tex(110, 90, s)


## A pair of mittens and a tuque, knitted in red and white with a snowflake.
static func mittens() -> ImageTexture:
	var s := '<ellipse cx="55" cy="84" rx="42" ry="5" fill="#000000" opacity="0.15"/>'
	# The tuque.
	s += '<path d="M24 48 Q22 14 52 12 Q82 14 80 48 Z" fill="#D42A3A" stroke="#8A1A20" stroke-width="2"/>'
	s += '<rect x="20" y="44" width="64" height="16" rx="6" fill="#FFFFFF" stroke="#B8A98A" stroke-width="1.8"/>'
	for k in 8:
		s += '<path d="M%d 46 v12" stroke="#E4D8C4" stroke-width="1.4"/>' % (26 + k * 7)
	s += '<circle cx="52" cy="10" r="8" fill="#FFFFFF" stroke="#B8A98A" stroke-width="1.5"/>'
	s += '<path d="M40 28 h24 M52 20 v16 M44 22 l16 12 M60 22 l-16 12" stroke="#FFFFFF" stroke-width="1.6" opacity="0.9"/>'
	# Two mittens: a round-topped hand, a thumb, a ribbed cuff and a snowflake.
	for m in [[24.0, 1.0], [86.0, -1.0]]:
		var x: float = m[0]
		var f: float = m[1]
		s += '<ellipse cx="%s" cy="66" rx="7.5" ry="11" fill="#3A78C9" stroke="#1E4A8A" stroke-width="2" transform="rotate(%s %s 66)"/>' % [x + 15.0 * f, 28.0 * f, x + 15.0 * f]
		s += '<path d="M%s 82 L%s 62 Q%s 42 %s 42 Q%s 42 %s 62 L%s 82 Z" fill="#3A78C9" stroke="#1E4A8A" stroke-width="2"/>' % [x - 12.0, x - 12.0, x - 12.0, x, x + 12.0, x + 12.0, x + 12.0]
		s += '<path d="M%s 52 Q%s 46 %s 48" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.4"/>' % [x - 8.0, x - 8.0, x - 2.0]
		s += '<rect x="%s" y="76" width="26" height="10" rx="3" fill="#FFFFFF" stroke="#B8A98A" stroke-width="1.6"/>' % (x - 13.0)
		for k in 5:
			s += '<path d="M%s 77 v8" stroke="#E4D8C4" stroke-width="1.3"/>' % (x - 9.0 + k * 5.0)
		s += '<path d="M%s 58 h12 M%s 52 v12 M%s 54 l8 8 M%s 54 l-8 8" stroke="#FFFFFF" stroke-width="1.6" opacity="0.95"/>' % [x - 6.0, x, x - 4.0, x + 4.0]
	return InteriorArt.tex(110, 90, s)


## A pair of white figure skates with pink laces and their blades.
static func skates() -> ImageTexture:
	var s := '<ellipse cx="55" cy="86" rx="46" ry="5" fill="#000000" opacity="0.15"/>'
	for k in 2:
		var dx := 4.0 + k * 46.0
		var dy := 0.0 if k == 0 else 4.0
		s += '<g transform="translate(%s %s)">' % [dx, dy]
		s += '<path d="M6 16 Q8 8 18 8 L28 8 L30 40 Q44 44 48 52 L48 62 L4 62 Q2 40 6 16 Z" fill="#FFFFFF" stroke="#8A8A94" stroke-width="2"/>'
		s += '<path d="M8 30 Q20 36 30 32" stroke="#D9DEE6" stroke-width="1.6" fill="none"/>'
		s += '<path d="M6 62 H48 V66 H6 Z" fill="#6A6A74"/>'
		s += '<path d="M2 70 H54 Q58 70 56 74 H0 Z" fill="#C9D2DA" stroke="#8A8A94" stroke-width="1.4"/>'
		s += '<path d="M14 66 v6 M40 66 v6" stroke="#8A8A94" stroke-width="2.4"/>'
		for r in 4:
			s += '<path d="M%s %s l8 -3" stroke="#FF7BB0" stroke-width="2.2" stroke-linecap="round"/>' % [14 + r % 2 * 2, 14 + r * 7]
		s += '<circle cx="12" cy="10" r="2.6" fill="#FF7BB0"/>'
		s += '</g>'
	return InteriorArt.tex(110, 90, s)


## Canvas 120 × 110: her capybara plush, sitting, an orange on its head (Julien's favourite); its bottom on the bottom edge.
static func capybara_plush() -> ImageTexture:
	var s := '<ellipse cx="60" cy="102" rx="44" ry="6" fill="#000000" opacity="0.15"/>'
	s += '<ellipse cx="62" cy="72" rx="46" ry="34" fill="#A8743F" stroke="#6E4520" stroke-width="2.5"/>'
	s += '<ellipse cx="48" cy="60" rx="20" ry="12" fill="#C08A52" opacity="0.7"/>'
	# Its blunt head, little ears, sleepy eye, the big nose.
	s += '<path d="M24 50 Q20 30 40 26 H74 Q96 28 96 48 Q96 64 78 66 H42 Q24 66 24 50 Z" fill="#B07C45" stroke="#6E4520" stroke-width="2.5"/>'
	s += '<ellipse cx="44" cy="26" rx="7" ry="5" fill="#8A5A2E" stroke="#6E4520" stroke-width="2"/><ellipse cx="72" cy="25" rx="7" ry="5" fill="#8A5A2E" stroke="#6E4520" stroke-width="2"/>'
	s += '<path d="M44 44 q5 4 10 0" stroke="#2A1A0E" stroke-width="2.5" fill="none" stroke-linecap="round"/>'
	s += '<ellipse cx="86" cy="50" rx="9" ry="8" fill="#5A3A20"/><circle cx="84" cy="48" r="1.8" fill="#FFFFFF" opacity="0.6"/>'
	s += '<circle cx="38" cy="52" r="5" fill="#E89A8A" opacity="0.6"/>'
	# Paws in front.
	s += '<ellipse cx="46" cy="100" rx="11" ry="6" fill="#8A5A2E"/><ellipse cx="78" cy="100" rx="11" ry="6" fill="#8A5A2E"/>'
	# The orange on its head, its leaf.
	s += '<circle cx="58" cy="18" r="13" fill="#FF9A1F" stroke="#C46A00" stroke-width="2"/><circle cx="54" cy="14" r="3" fill="#FFD08A"/>'
	s += '<path d="M58 6 q8 -6 14 -2 q-6 6 -14 2" fill="#3E8E3A"/>'
	return InteriorArt.tex(120, 110, s)


## Canvas 100 × 46: the tourtière in its dish, golden, a vent cut in its crust.
static func tourtiere() -> ImageTexture:
	var s := '<path d="M6 26 H94 L86 42 H14 Z" fill="#E7E2D8" stroke="#9FA6AE" stroke-width="2"/>'
	s += '<ellipse cx="50" cy="24" rx="42" ry="14" fill="#D9A04A" stroke="#A8742A" stroke-width="2"/>'
	s += '<ellipse cx="44" cy="20" rx="20" ry="6" fill="#ECC07A" opacity="0.8"/>'
	s += '<path d="M44 22 l6 -6 l6 6 M50 16 v10" stroke="#A8742A" stroke-width="2" fill="none"/>'
	for i in 14:
		var a := TAU * i / 14.0
		s += '<circle cx="%.1f" cy="%.1f" r="2.4" fill="#C98E3A"/>' % [50.0 + cos(a) * 40.0, 24.0 + sin(a) * 12.5]
	return InteriorArt.tex(100, 46, s)


## Canvas 90 × 60: a slice of bûche de Noël on its plate, a sprig of holly.
static func buche() -> ImageTexture:
	var s := '<ellipse cx="45" cy="50" rx="40" ry="8" fill="#FFFFFF" stroke="#B8C4D0" stroke-width="2"/>'
	s += '<rect x="18" y="22" width="54" height="26" rx="6" fill="#6B3E22" stroke="#40220F" stroke-width="2"/>'
	s += '<circle cx="66" cy="35" r="12" fill="#8A5A34" stroke="#40220F" stroke-width="2"/><path d="M66 35 m-7 0 a7 7 0 1 0 14 0 a4 4 0 1 0 -8 0" stroke="#F4E2C8" stroke-width="2" fill="none"/>'
	s += '<path d="M22 28 q8 -4 16 0 t16 0" stroke="#4A2A14" stroke-width="2" fill="none"/>'
	s += '<path d="M30 16 q6 -8 12 0 q-6 4 -12 0 M38 16 q6 -8 12 0 q-6 4 -12 0" fill="#2F7A45"/><circle cx="40" cy="20" r="3" fill="#D42A3A"/>'
	s += '<path d="M24 20 q4 -2 6 2" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.8"/>'
	return InteriorArt.tex(90, 60, s)


## Canvas 120 × 90: the big box of crayons, open, every colour standing in it.
static func crayons() -> ImageTexture:
	var s := ""
	var colours := ["#E5383B", "#FF8A2E", "#F2C230", "#3BAA5C", "#2E6FD8", "#9B3BD1", "#E86BB0", "#6B4528"]
	for i in colours.size():
		var x := 18.0 + i * 11.0
		s += '<path d="M%s 30 V12 L%s 4 L%s 12 V30 Z" fill="%s" stroke="#00000055" stroke-width="1"/>' % [x, x + 4.0, x + 8.0, colours[i]]
	s += '<rect x="12" y="28" width="96" height="58" rx="4" fill="#2E6FD8" stroke="#1E3A5A" stroke-width="2"/>'
	s += '<path d="M12 44 H108" stroke="#F2C230" stroke-width="5"/><circle cx="60" cy="66" r="12" fill="#F2C230"/>'
	return InteriorArt.tex(120, 90, s)
