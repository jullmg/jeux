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
## The presents under the tree: id, what she says opening it.
const PRESENTS := [
	["capybara", "Une peluche de capybara ! Avec une orange sur la tête !"],
	["crayons", "Une grosse boîte de crayons de toutes les couleurs !"],
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


## Canvas 100 × 90: a wrapped present: `kind` 0 red paper with a gold ribbon, 1 green with white dots and a red ribbon; its
## bottom on the bottom edge. `open`: the lid off, tissue paper spilling.
static func present(kind: int, open := false) -> ImageTexture:
	var paper := "#C8202A" if kind == 0 else "#2F7A45"
	var ribbon := "#E9B824" if kind == 0 else "#D42A3A"
	var s := '<rect x="12" y="34" width="76" height="54" rx="3" fill="%s" stroke="#00000044" stroke-width="2"/>' % paper
	if kind == 1:
		for p in [[24, 48], [44, 70], [66, 52], [78, 76], [30, 80], [56, 40]]:
			s += '<circle cx="%d" cy="%d" r="3" fill="#FFFFFF" opacity="0.8"/>' % p
	s += '<rect x="44" y="34" width="12" height="54" fill="%s"/>' % ribbon
	if open:
		s += '<path d="M14 34 Q30 14 44 30 Q52 10 62 30 Q76 16 86 34 Z" fill="#FFFFFF" stroke="#D9DEE6" stroke-width="1.5"/>'
		s += '<rect x="58" y="2" width="40" height="14" rx="2" fill="%s" stroke="#00000044" stroke-width="2" transform="rotate(24 78 9)"/>' % paper
	else:
		s += '<rect x="8" y="24" width="84" height="14" rx="2" fill="%s" stroke="#00000044" stroke-width="2"/>' % paper
		s += '<rect x="44" y="24" width="12" height="14" fill="%s"/>' % ribbon
		s += '<path d="M50 24 Q30 2 36 20 Q40 26 50 24 Q70 2 64 20 Q60 26 50 24" fill="%s" stroke="#00000044" stroke-width="1.5"/>' % ribbon
	return InteriorArt.tex(100, 90, s)


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
