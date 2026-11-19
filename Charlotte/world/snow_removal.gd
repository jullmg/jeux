class_name SnowRemoval
extends Node2D
## 6e Avenue the morning after the storm (`Snowstorm`, quest "souffleuse"), in front of Charlotte's duplex: the heaps of snow on
## her porch and steps (drawn behind her), Papa shovelling at the foot of the steps, the windrow along the curb and the city's
## orange signs (this node, in front of the people, with the lamps and the traffic), then the snow removal going by: the big
## snow blower eating the windrow and blowing it into the dump truck beside it. main.gd adds it after the street's props.

## The heaps, from the porch down to the sidewalk: [x from her door, y of their foot, width] (world px).
const PILE_SPOTS := [[-30.0, 538.0, 96.0], [-92.0, 554.0, 56.0], [-118.0, 576.0, 62.0], [-150.0, 600.0, 74.0]]
## Where Papa stands (x from her door), on the sidewalk at the foot of the steps.
const PAPA_DX := -250.0
## The windrow along the curb: its top, and how far it runs either side of her door.
const BANK_TOP := 668.0
const BANK_SPAN := 2600.0
## The orange signs along the curb (x from her door).
const SIGNS := [-640.0, 330.0, 1050.0]
## The convoy: how fast it comes (px/s, leftward), its pictures' scales, where its tyres touch the road (below the view).
const SPEED := 115.0
const BLOWER_SCALE := 0.85
const TRUCK_SCALE := 0.76
const BLOWER_FOOT := 772.0
const TRUCK_FOOT := 744.0
const TRUCK_LAG := 80.0
const PAPA_SHOVELS := 2.6

var scene: StreetScene
var door_x := 0.0

var _papa: Character
var _behind: Node2D
var _piles: Array[_Pile] = []
var _bank: _Bank
var _blower: Sprite2D
var _truck: Sprite2D
var _rolling := false
var _passed := false
var _shovel_in := 0.0
var _rumble := 0.0


func _ready() -> void:
	var charlotte: Character = scene._charlotte
	# What stands behind her: the heaps on the steps, and Papa.
	_behind = Node2D.new()
	scene.add_child(_behind)
	scene.move_child(_behind, charlotte.get_index())
	for i in PILE_SPOTS.size():
		var spot: Array = PILE_SPOTS[i]
		var pile := _Pile.new()
		pile.position = Vector2(door_x + spot[0], spot[1])
		pile.width = spot[2]
		pile.visible = i not in Snowstorm.cleared()
		_behind.add_child(pile)
		_piles.append(pile)
		scene.add_child(DoorSpot.make(Rect2(pile.position + Vector2(-pile.width / 2.0 - 10.0, -44.0), Vector2(pile.width + 20.0, 56.0)),
			_shovel.bind(i), pile.position.x))
		scene.add_child(QuestMark.make(pile.position + Vector2(0, -60), func() -> bool:
			return Snowstorm.step() == 2 and Carry.has("pelle") and pile.visible and pile.amount > 0.99, 0.7))
	_papa = Character.new()
	var look := CharacterLook.dad()
	Season.dress_for_weather(look)
	_papa.look = look
	_papa.scale = Vector2.ONE * StreetScene.CHAR_SCALE * 1.18
	_papa.position = Vector2(door_x + PAPA_DX, StreetScene.CHARLOTTE_Y - 4.0)
	_papa.facing = 1
	_behind.add_child(_papa)
	var big := Sprite2D.new()
	big.texture = Snowstorm.shovel(true)
	big.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	big.scale = Vector2.ONE * 1.5
	big.rotation = deg_to_rad(18.0)
	big.offset = Vector2(0, 30)
	_papa.carry(big)
	scene.add_child(DoorSpot.make(Rect2(_papa.position + Vector2(-50, -220), Vector2(100, 220)), _talk_to_papa, _papa.position.x + 90.0))
	scene.add_child(QuestMark.make(_papa.position + Vector2(0, -250), func() -> bool:
		return Snowstorm.step() == 2 and not Carry.has("pelle")))
	# In front of the people: the signs, the windrow, then the convoy when it comes.
	for dx: float in SIGNS:
		_add_sign(door_x + dx)
	_bank = _Bank.new()
	_bank.x0 = door_x - BANK_SPAN
	_bank.x1 = door_x + BANK_SPAN
	_bank.eaten = _bank.x1
	add_child(_bank)
	if Snowstorm.step() == 3:
		_start_convoy.call_deferred()
	elif not Carry.has("pelle"):
		var hello := create_tween()
		hello.tween_interval(1.2)
		hello.tween_callback(_papa_says.bind("Allô, Chachoue ! Toute une bordée, hein ?\nViens chercher ta pelle !"))


func _process(delta: float) -> void:
	# Papa shovels steadily until the snow removal has gone by.
	if not _passed:
		_shovel_in -= delta
		if _shovel_in <= 0.0:
			_shovel_in = PAPA_SHOVELS
			_papa.facing = 1
			_papa.pet(0.7, 0.3)
			if OnScreen.near(_papa, 100.0):
				_throw(_papa.position + Vector2(50, -20), 1.0)
	if not _rolling:
		return
	_blower.position.x -= SPEED * delta
	_truck.position.x -= SPEED * delta
	_bank.eaten = minf(_bank.eaten, _blower.position.x + 30.0)
	_bank.queue_redraw()
	_rumble -= delta
	if _rumble <= 0.0:
		_rumble = 3.4
		Sfx.play("snowblower", _blower.position + Snowstorm.BLOWER_SIZE * BLOWER_SCALE / 2.0, -3.0)
	var cam := get_viewport().get_camera_2d()
	var left := (cam.get_screen_center_position().x if cam else _blower.position.x) - StreetScene.VIEW.x / 2.0
	var tail := _truck.position.x + Snowstorm.TRUCK_SIZE.x * TRUCK_SCALE
	if tail < left - 60.0 or tail < door_x - BANK_SPAN:
		_rolling = false
		_gone_by()


# ── Papa and the shovels ──────────────────────────────────────

func _talk_to_papa() -> void:
	var charlotte: Character = scene._charlotte
	_papa.facing = 1 if charlotte.position.x > _papa.position.x else -1
	match Snowstorm.step():
		2:
			if Carry.has("pelle"):
				_papa_says("Le perron pis les marches, ma grande !\nMoi, je fais le trottoir.")
			elif Carry.take(charlotte, "pelle"):
				Sfx.play("pop", charlotte.position + Vector2(0, -80))
				_papa.express("happy", 2.0)
				_papa_says("Tiens, ta petite pelle !\nDéneige le perron pis les marches.")
				Notebook.announce("step", "Déneige le perron pis les marches avec ta pelle !", Snowstorm.HEADING)
			else:
				_charlotte_says(Carry.FULL_HANDS)
		3:
			_papa_says("Regarde-la aller, la souffleuse !")


# One heap: she pushes the shovel in and throws the snow toward the street; the last one brings the snow removal.
func _shovel(i: int) -> void:
	var charlotte: Character = scene._charlotte
	var pile := _piles[i]
	if not pile.visible or pile.amount < 0.99 or Snowstorm.step() != 2:
		return
	if not Carry.has("pelle"):
		_charlotte_says("Il me faut une pelle !\nPapa en a une pour moi.")
		return
	charlotte.facing = 1 if pile.position.x > charlotte.position.x else -1
	charlotte.pet(0.8, 0.4)
	charlotte.express("effort", 1.0)
	Sfx.play("shovel", pile.position)
	_throw(pile.position + Vector2(0, -16), 1.4)
	Snowstorm.clear_pile(i)
	var melt := create_tween()
	melt.tween_property(pile, "amount", 0.0, 0.6).set_ease(Tween.EASE_OUT)
	melt.tween_callback(func() -> void: pile.visible = false)
	if not Snowstorm.all_cleared():
		return
	Snowstorm.set_step(3)
	var after := create_tween()
	after.tween_interval(1.2)
	after.tween_callback(func() -> void:
		charlotte.express("happy", 2.0)
		_papa.express("happy", 2.0)
		_papa_says("Bravo, Chachoue ! Ça, c'est de l'ouvrage !\n… Écoute ! La souffleuse s'en vient !"))
	after.tween_interval(3.2)
	after.tween_callback(_start_convoy)


# A shovelful of snow flying off toward the street.
func _throw(from: Vector2, size: float) -> void:
	var puff := _Puff.new()
	puff.position = from
	puff.size = size
	scene.add_child(puff)


func _charlotte_says(text: String) -> void:
	var charlotte: Character = scene._charlotte
	Bubble.say(scene, charlotte.position + Vector2(0, -190), text, 2.6)


func _papa_says(text: String, seconds := 3.2) -> void:
	_papa.express("talk", seconds * 0.7)
	Bubble.say(scene, _papa.position + Vector2(0, -225), text, seconds)


# ── The snow removal ──────────────────────────────────────────

func _start_convoy() -> void:
	if _rolling or _passed:
		return
	Notebook.announce("step", "La souffleuse arrive ! Regarde-la passer.", Snowstorm.HEADING)
	var cam := get_viewport().get_camera_2d()
	var right := (cam.get_screen_center_position().x if cam else door_x) + StreetScene.VIEW.x / 2.0
	_truck = _vehicle(Snowstorm.truck(), TRUCK_SCALE, Vector2(right + 60.0 + TRUCK_LAG, TRUCK_FOOT - Snowstorm.TRUCK_SIZE.y * TRUCK_SCALE))
	_blower = _vehicle(Snowstorm.blower(), BLOWER_SCALE, Vector2(right + 60.0, BLOWER_FOOT - Snowstorm.BLOWER_SIZE.y * BLOWER_SCALE))
	_blower.add_child(_jet())
	for v in [_truck, _blower]:
		var beacon := _Beacon.new()
		beacon.position = Vector2(300, 52) if v == _blower else Vector2(106, 52)
		v.add_child(beacon)
	_rolling = true
	var look := create_tween()
	look.tween_interval(1.5)
	look.tween_callback(func() -> void:
		var charlotte: Character = scene._charlotte
		charlotte.express("wonder", 3.0)
		_charlotte_says("Wow ! Elle mange toute la neige !"))


func _vehicle(tex: Texture2D, k: float, at: Vector2) -> Sprite2D:
	var v := Sprite2D.new()
	v.texture = tex
	v.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	v.centered = false
	v.scale = Vector2.ONE * k
	v.position = at
	add_child(v)
	return v


# The snow blown up out of the chute and over into the truck's box behind it.
func _jet() -> CPUParticles2D:
	var jet := CPUParticles2D.new()
	jet.position = Snowstorm.CHUTE
	# Up out of the hood and down into the truck's box behind (its box runs about 250 to 620 in the blower's own units).
	jet.texture = _flake()
	jet.amount = 180
	jet.lifetime = 1.0
	jet.direction = Vector2(1.0, -0.9)
	jet.spread = 9.0
	jet.initial_velocity_min = 260.0
	jet.initial_velocity_max = 330.0
	jet.gravity = Vector2(0, 520)
	jet.scale_amount_min = 0.5
	jet.scale_amount_max = 1.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.95))
	fade.set_color(1, Color(0.92, 0.95, 1.0, 0.0))
	jet.color_ramp = fade
	return jet


static var _flake_tex: ImageTexture


# A soft round flake for the jet (a particle without a texture is a square).
static func _flake() -> ImageTexture:
	if _flake_tex == null:
		_flake_tex = InteriorArt.tex(16, 16, '<circle cx="8" cy="8" r="7" fill="#FFFFFF"/>')
	return _flake_tex


# It has gone by: the windrow is gone; Papa takes the shovel back and they go in for a hot chocolate. The quest is done.
func _gone_by() -> void:
	_passed = true
	for v in [_blower, _truck]:
		v.queue_free()
	_bank.visible = false
	var charlotte: Character = scene._charlotte
	var steps := create_tween()
	steps.tween_interval(0.6)
	steps.tween_callback(func() -> void:
		_papa.express("happy", 2.4)
		_papa_says("Plus de neige ! Merci pour ton aide, ma grande.\nOn rentre se faire un bon chocolat chaud ?", 3.8))
	steps.tween_interval(4.0)
	steps.tween_callback(func() -> void:
		if Carry.has("pelle"):
			Carry.put_down(charlotte)
		Quests.complete(Snowstorm.QUEST)
		Snowstorm.clear()
		charlotte.express("happy", 2.0)
		_charlotte_says("Oui ! Avec des guimauves !"))
	steps.tween_interval(1.0)
	# Papa goes back in through their front door.
	steps.tween_callback(func() -> void:
		_papa.facing = 1
		_papa.is_walking = true)
	steps.tween_property(_papa, "position:x", door_x - 60.0, absf(door_x - 60.0 - _papa.position.x) / 120.0)
	steps.tween_callback(func() -> void: _papa.is_walking = false)
	steps.tween_property(_papa, "modulate:a", 0.0, 0.5)
	steps.tween_callback(_papa.queue_free)


func _add_sign(x: float) -> void:
	var k := 0.85
	var sign := Sprite2D.new()
	sign.texture = Snowstorm.sign()
	sign.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sign.centered = false
	sign.scale = Vector2.ONE * k
	sign.position = Vector2(x - 30.0 * k, StreetScene.CURB_Y + 10.0 - 150.0 * k)
	add_child(sign)
	var settings := LabelSettings.new()
	settings.font_size = 6
	settings.font_color = Color("#1E1E1E")
	settings.line_spacing = -2.0
	var words := Label.new()
	words.text = "ENLÈVEMENT\nDE LA NEIGE"
	words.label_settings = settings
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.size = Vector2(44, 18)
	words.position = sign.position + Vector2(30.0 * k - 22.0, 44.0 * k)
	add_child(words)


# ── Pieces ────────────────────────────────────────────────────

## A heap of snow on a step: soft lumps, lit from the upper left, a blue shade below. `amount` 1 → 0 as it is shovelled.
class _Pile:
	extends Node2D
	var width := 60.0
	var amount := 1.0:
		set(v):
			amount = v
			queue_redraw()

	func _draw() -> void:
		var h := 22.0 * amount
		if h < 0.5:
			return
		var w := width * (0.6 + 0.4 * amount)
		draw_set_transform(Vector2(0, -h * 0.4), 0.0, Vector2(1.0, h / w * 1.4))
		draw_circle(Vector2(2, 3), w / 2.0, Color("#B9C9DC"))
		draw_circle(Vector2.ZERO, w / 2.0, Color("#F4F8FC"))
		draw_set_transform(Vector2.ZERO)
		for k in 3:
			var c := Vector2((k - 1) * w * 0.3, -h * (0.55 + 0.15 * (1 - absi(k - 1))))
			draw_circle(c, w * 0.18, Color("#FFFFFF"))
		draw_circle(Vector2(-w * 0.22, -h * 0.75), w * 0.08, Color(1, 1, 1, 0.9))


## The windrow the plough left along the curb, from `x0` to `x1`, eaten up to `eaten` by the blower.
class _Bank:
	extends Node2D
	var x0 := 0.0
	var x1 := 0.0
	var eaten := 0.0

	func _draw() -> void:
		var to := minf(x1, eaten)
		if to <= x0:
			return
		var top := PackedVector2Array()
		var x := x0
		while x <= to:
			var h := 26.0 + 8.0 * sin(x / 130.0) + 5.0 * sin(x / 47.0 + 1.3) + 3.0 * sin(x / 19.0)
			top.append(Vector2(x, SnowRemoval.BANK_TOP + 30.0 - h))
			x += 10.0
		top.append(Vector2(to, SnowRemoval.BANK_TOP + 26.0))
		var body := top.duplicate()
		body.append(Vector2(to, 730.0))
		body.append(Vector2(x0, 730.0))
		draw_colored_polygon(body, Color("#EEF3F8"))
		var shade := PackedVector2Array()
		for p in top:
			shade.append(p + Vector2(0, 16))
		shade.append(Vector2(to, 730.0))
		shade.append(Vector2(x0, 730.0))
		draw_colored_polygon(shade, Color("#D3DEEA"))
		draw_polyline(top, Color("#FFFFFF"), 3.0, true)
		# The clean cut the blower leaves.
		draw_line(Vector2(to, top[top.size() - 2].y), Vector2(to, 730.0), Color("#BCCBDC"), 3.0)


## A shovelful thrown: lumps of snow flying off and falling, fading.
class _Puff:
	extends Node2D
	var size := 1.0
	var _t := 0.0
	var _bits: Array = []

	func _ready() -> void:
		for i in 9:
			_bits.append([Vector2(randf_range(60.0, 160.0), randf_range(-170.0, -90.0)) * size, randf_range(2.5, 5.5) * size])

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.9:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		for bit: Array in _bits:
			var v: Vector2 = bit[0]
			var p := v * _t + Vector2(0, 420.0) * _t * _t
			draw_circle(p, bit[1], Color(1, 1, 1, 1.0 - _t / 0.9))


## A turning orange beacon on a roof: its glow sweeping round.
class _Beacon:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if OnScreen.near(self, 300.0):
			queue_redraw()

	func _draw() -> void:
		var on := 0.5 + 0.5 * sin(_t * 9.0)
		draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.55, 0.1, 0.25 * on))
		draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.75, 0.3, 0.6 * on))
