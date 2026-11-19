class_name TreeSale
extends Node2D
## The school's Christmas tree sale in the schoolyard (`XmasTree`, quest "sapin", step 2; `cour_ecole.gd` in its "sapin" mode,
## a Saturday: no pupils, no bell). By the gate: the volunteer's folding table with the cash box and the hot chocolate under a
## red banner, the wooden rack against the fence with the wrapped trees leaning on it under a string of lights, and the four
## trees for sale standing in a row, each with its tag. Papa came with her. She clicks a tree, says yes, the volunteer wraps
## it, Papa pays, takes it on his shoulder, and they carry it home.

const TABLE_X := 360.0
const RACK_X := 560.0
## The trees for sale (world x of each one's foot), one per XmasTree.SHAPES.
const TREE_XS := [700.0, 880.0, 1060.0, 1240.0]
const TREE_SCALE := 0.62
const PAPA_X := 300.0
const SELLER_LINES := ["Bonjour ! Tous les sous vont à l'école.", "Un chocolat chaud avec ça ? C'est cadeau !",
	"Ils arrivent direct des Laurentides !"]

var scene: StreetScene
var _papa: Character
var _seller: Character
var _trees: Array[Sprite2D] = []
var _busy := false
var _line := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	var y: float = StreetScene.CHARLOTTE_Y
	# The rack of wrapped trees against the fence, the string of lights over it.
	var rack := _sprite(rack_picture(), 1.0)
	rack.position = Vector2(RACK_X, y - 40.0 - 300.0)
	add_child(rack)
	# The volunteer behind the table.
	_seller = Character.new()
	var look := CharacterLook.random(rng, "adult")
	Season.dress_for_weather(look)
	_seller.look = look
	_seller.scale = Vector2.ONE * StreetScene.CHAR_SCALE * 1.15
	_seller.position = Vector2(TABLE_X + 40.0, y - 22.0)
	_seller.facing = 1
	_seller.fidgets = true
	add_child(_seller)
	var table := _sprite(table_picture(), 1.0)
	table.position = Vector2(TABLE_X - 60.0, y - 14.0 - 130.0)
	add_child(table)
	# The banner over the stand.
	var banner := ColorRect.new()
	banner.color = Color("#C8202A")
	banner.size = Vector2(250, 46)
	banner.position = Vector2(TABLE_X - 70.0, y - 330.0)
	add_child(banner)
	scene._label("VENTE DE SAPINS", banner.position + Vector2(125, 15), Vector2(250, 24), 18, Color.WHITE, Color("#7E1418"))
	scene._label("au profit de l'école", banner.position + Vector2(125, 35), Vector2(250, 16), 11, Color("#FFE9A8"), Color("#7E1418"))
	# The four trees for sale, each in its cross foot, with its tag.
	for i in TREE_XS.size():
		var tree := _sprite(XmasTree.picture(i, [], true), TREE_SCALE)
		tree.position = Vector2(TREE_XS[i] - XmasTree.W / 2.0 * TREE_SCALE, y - 20.0 - XmasTree.H * TREE_SCALE)
		add_child(tree)
		_trees.append(tree)
		var info: Array = XmasTree.SHAPES[i]
		scene._label("%s\n%s" % [info[0], info[3]], Vector2(TREE_XS[i], y - 6.0), Vector2(110, 30), 11, Color("#1E1E1E"), Color.WHITE)
	_papa = Character.new()
	var dad := CharacterLook.dad()
	Season.dress_for_weather(dad)
	_papa.look = dad
	_papa.scale = Vector2.ONE * StreetScene.CHAR_SCALE * 1.18
	_papa.position = Vector2(PAPA_X, y - 6.0)
	_papa.facing = 1
	_papa.fidgets = true
	add_child(_papa)


## The clickable parts, once Charlotte is in the scene.
func build_spots() -> void:
	for i in TREE_XS.size():
		var tree := _trees[i]
		var size := tree.texture.get_size() * TREE_SCALE
		scene.add_child(DoorSpot.make(Rect2(tree.position + Vector2(size.x * 0.15, size.y * 0.1), size * Vector2(0.7, 0.9)),
			_pick.bind(i), TREE_XS[i] - 70.0))
		scene.add_child(QuestMark.make(Vector2(TREE_XS[i], tree.position.y - 18.0), func() -> bool: return not _busy, 0.7))
	scene.add_child(DoorSpot.make(Rect2(TABLE_X - 60.0, StreetScene.CHARLOTTE_Y - 240.0, 240.0, 230.0), func() -> void:
		_line += 1
		_seller_says(SELLER_LINES[_line % SELLER_LINES.size()]), TABLE_X + 200.0))
	scene.add_child(DoorSpot.make(Rect2(_papa.position + Vector2(-50, -220), Vector2(100, 220)), func() -> void:
		_papa_says("Prends ton temps, Chachoue.\nChoisis celui que tu veux !"), _papa.position.x + 90.0))
	var hello := create_tween()
	hello.tween_interval(1.0)
	hello.tween_callback(_papa_says.bind("Regarde tous ces sapins !\nLequel tu choisis ?"))
	hello.tween_interval(3.2)
	hello.tween_callback(_seller_says.bind(SELLER_LINES[0]))


func _pick(i: int) -> void:
	if _busy:
		return
	var info: Array = XmasTree.SHAPES[i]
	scene._control.enabled = false
	var card := ChoiceCard.ask(scene, "« %s », à %s. Celui-là ?" % [info[0], info[3]],
		[{"text": "Oui, celui-là !", "color": Color("#2F7A45")}, {"text": "Je regarde encore"}])
	card.chose.connect(func(k: int) -> void:
		scene._control.enabled = true
		if k == 0:
			_buy(i))


# Wrapped, paid for, on Papa's shoulder, and home.
func _buy(i: int) -> void:
	_busy = true
	scene._control.hands_off = true
	GameState.flags[XmasTree.CHOICE] = i
	var tree := _trees[i]
	var charlotte: Character = scene._charlotte
	charlotte.express("grin", 2.0)
	var steps := create_tween()
	steps.tween_callback(_papa_says.bind("Bon choix, Chachoue !\nY va être magnifique dans le salon."))
	steps.tween_interval(2.8)
	steps.tween_callback(_seller_says.bind("Je vous l'emballe !"))
	# The net pulls its boughs in.
	steps.tween_property(tree, "scale:x", TREE_SCALE * 0.62, 0.8)
	steps.parallel().tween_property(tree, "position:x", TREE_XS[i] - XmasTree.W / 2.0 * TREE_SCALE * 0.62, 0.8)
	steps.tween_callback(func() -> void:
		Sfx.play("chime", _seller.global_position)
		_papa_says("Tenez, monsieur. Pis gardez la monnaie,\nc'est pour l'école !")
		_papa.is_walking = true
		_papa.facing = 1)
	steps.tween_property(_papa, "position:x", TREE_XS[i] - 70.0, absf(TREE_XS[i] - 70.0 - _papa.position.x) / 140.0)
	steps.tween_callback(func() -> void:
		_papa.is_walking = false
		# On his shoulder, lying back.
		tree.reparent(_papa)
		tree.rotation = deg_to_rad(-72.0)
		tree.position = Vector2(-150, -260)
		tree.scale = Vector2(TREE_SCALE * 0.62, TREE_SCALE) / _papa.scale
		_papa.express("happy", 2.0)
		Notebook.announce("step", "Votre sapin est choisi ! On le rapporte à la maison.", XmasTree.HEADING))
	steps.tween_interval(2.0)
	steps.tween_callback(func() -> void:
		XmasTree.set_step(3)
		Transition.inside_x = XmasTree.HOME_X
		Transition.change_scene_saying(scene, XmasTree.HOME, "Papa pis toi rapportez le sapin à la maison…", 1.6))


func _papa_says(text: String) -> void:
	_papa.express("talk", 2.0)
	Bubble.say(scene, _papa.global_position + Vector2(0, -225), text, 3.0)


func _seller_says(text: String) -> void:
	_seller.express("talk", 2.0)
	Bubble.say(scene, _seller.global_position + Vector2(0, -215), text, 3.0)


func _sprite(tex: Texture2D, k: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.scale = Vector2.ONE * k
	return sprite


# ── Pictures ────────────────────────────────────────────────

## Canvas 700 × 300: a long wooden rack of two-by-fours against the fence, a dozen trees wrapped in white netting leaning on it,
## snow on its top rail, a string of big coloured bulbs along it; its feet on the bottom edge.
static func rack_picture() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9002
	var s := ""
	# Trees leaning back against the rail, narrow in their netting.
	for i in 11:
		var x := 30.0 + i * 60.0 + rng.randf_range(-8.0, 8.0)
		var h := rng.randf_range(200.0, 260.0)
		var lean := rng.randf_range(-12.0, -4.0)
		s += '<g transform="rotate(%.1f %.1f 296)">' % [lean, x]
		s += '<rect x="%.1f" y="%.1f" width="8" height="30" fill="#6B4528"/>' % [x - 4.0, 266.0]
		s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f 270 L%.1f 270 Q%.1f %.1f %.1f %.1f Z" fill="#245E38" stroke="#123A21" stroke-width="2"/>' % [x, 290.0 - h, x - 26.0, 290.0 - h * 0.4, x - 22.0, x + 22.0, x + 26.0, 290.0 - h * 0.4, x, 290.0 - h]
		for k in 7:
			var yy := 290.0 - h + 20.0 + k * (h - 40.0) / 7.0
			s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="#FFFFFF" stroke-width="1.4" opacity="0.7"/>' % [x - 22.0, yy, x + 22.0, yy + 18.0]
			s += '<path d="M%.1f %.1f L%.1f %.1f" stroke="#FFFFFF" stroke-width="1.4" opacity="0.7"/>' % [x + 22.0, yy, x - 22.0, yy + 18.0]
		s += '<path d="M%.1f %.1f q6 -8 12 -2" stroke="#FFFFFF" stroke-width="4" fill="none" opacity="0.9"/>' % [x - 8.0, 296.0 - h]
		s += '</g>'
	# The rack itself, over their trunks: two rails on posts.
	for y in [150.0, 230.0]:
		s += '<rect x="0" y="%s" width="700" height="12" fill="#B07A44" stroke="#6B4528" stroke-width="2"/>' % y
	s += '<path d="M0 150 H700" stroke="#FFFFFF" stroke-width="5" opacity="0.9"/>'
	for x in [20.0, 240.0, 460.0, 680.0]:
		s += '<rect x="%s" y="140" width="14" height="160" fill="#9A6838" stroke="#6B4528" stroke-width="2"/>' % (x - 7.0)
	# The string of lights along the top rail.
	var colours := ["#FF4D4D", "#FFD23F", "#4DA6FF", "#5BD16E", "#FF8AD8"]
	s += '<path d="M0 140 Q90 160 175 140 Q260 160 350 140 Q440 160 525 140 Q610 160 700 140" stroke="#1E1E1E" stroke-width="2" fill="none"/>'
	for i in 24:
		var x := 14.0 + i * 29.0
		var y := 140.0 + sin(fmod(x, 175.0) / 175.0 * PI) * 14.0
		s += '<ellipse cx="%.1f" cy="%.1f" rx="5" ry="7" fill="%s"/><circle cx="%.1f" cy="%.1f" r="9" fill="%s" opacity="0.25"/>' % [x, y + 8.0, colours[i % 5], x, y + 8.0, colours[i % 5]]
	return InteriorArt.tex(700, 300, s)


## Canvas 240 × 130: the volunteer's folding table under a red cloth: the cash box, the thermos of hot chocolate and its cups,
## a bowl of candy canes; its legs on the bottom edge.
static func table_picture() -> ImageTexture:
	var s := '<path d="M30 70 L18 130 M210 70 L222 130" stroke="#5A5A5A" stroke-width="5"/>'
	s += '<path d="M8 50 H232 V96 Q200 104 170 96 Q140 104 120 96 Q90 104 60 96 Q30 104 8 96 Z" fill="#C8202A" stroke="#7E1418" stroke-width="2"/>'
	s += '<path d="M8 50 H232" stroke="#FFFFFF" stroke-width="4"/>'
	for x in [30.0, 80.0, 130.0, 180.0]:
		s += '<path d="M%s 58 L%s 92" stroke="#FFFFFF" stroke-width="3" opacity="0.5"/>' % [x, x + 10.0]
	# The cash box.
	s += '<rect x="24" y="28" width="56" height="24" rx="3" fill="#3A6EA5" stroke="#1E3A5A" stroke-width="2"/><rect x="46" y="34" width="12" height="5" fill="#C9CED6"/>'
	# The thermos and cups.
	s += '<rect x="112" y="4" width="26" height="48" rx="6" fill="#D9473F" stroke="#7E1418" stroke-width="2"/><rect x="116" y="0" width="18" height="8" rx="2" fill="#3A3A3A"/>'
	for i in 3:
		s += '<path d="M%d 36 h14 l-2 16 h-10 Z" fill="#FFFFFF" stroke="#B8B8B8" stroke-width="1.5"/>' % (146 + i * 18)
	s += '<path d="M150 30 q3 -6 0 -12 M168 30 q3 -6 0 -12" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.7"/>'
	# Candy canes in a bowl.
	s += '<path d="M196 40 Q212 56 228 40 Z" fill="#E9B824" stroke="#A8801A" stroke-width="2"/>'
	for i in 3:
		var x := 202 + i * 8
		s += '<path d="M%d 42 V22 Q%d 16 %d 22" stroke="#FFFFFF" stroke-width="4" fill="none"/><path d="M%d 36 l4 -2 M%d 28 l4 -2" stroke="#D42A3A" stroke-width="2.5"/>' % [x, x + 4, x + 8, x - 2, x - 2]
	return InteriorArt.tex(240, 130, s)
