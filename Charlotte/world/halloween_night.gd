class_name HalloweenNight
extends Node2D
## The street on Halloween night: everything the evening adds to an ordinary `StreetScene`, built by
## `StreetScene._build_halloween()` while `Halloween.night()`.
##
## The night itself is a `CanvasModulate` (the whole street is multiplied down to a deep blue, so it keeps its drawing
## and its contrast instead of being washed out under a grey veil). Over that, one additive pass puts the light back
## where it belongs: the moon and the stars, the street lamps with their cones on the sidewalk, the lit windows of the
## houses that hand out candy, the flame of their jack-o'-lanterns, the lanterns the children carry, and a low mist.
## The houses that give also hang their decorations (`HalloweenArt`) and wait with a doorbell and a "!", while the dark
## ones are asleep. Other children walk past in little groups, each with a grown-up or two and a light of their own.

## At most how many children are out doing the rounds, shared between the little groups of `_trick_or_treaters`.
## A short street (Dandurand, Holt) gets fewer, or its troops stand on each other's toes.
const CHILDREN_OUT := 16

## The night, as a multiply over the whole canvas: cool and deep, but everything keeps its shape.
const NIGHT := Color(0.34, 0.38, 0.62)
## The same for a back lane, where nothing is lit at all: a touch lighter so it is not a black hole.
const NIGHT_LANE := Color(0.38, 0.42, 0.66)
const WINDOW_LIGHT := Color(1.0, 0.82, 0.42)
const LAMP_LIGHT := Color(1.0, 0.84, 0.52)
const PUMPKIN_LIGHT := Color(1.0, 0.56, 0.16)
## How many houses in three give out candy.
const GIVES := 2
const CANDY_LINES := ["Des bonbons ou un sort !", "Joyeuse Halloween !", "Des bonbons, s'il vous plaît !"]
const NEIGHBOUR_LINES := ["Oh, le beau déguisement ! Tiens, ma belle.", "Joyeuse Halloween ! Sers-toi.",
	"Ben voyons donc, que t'es belle ! Prends-en deux.", "Bonne Halloween, ma chouette !"]
const ASLEEP := ["Pas de lumière… ils dorment déjà.", "Celle-là est éteinte, on passe !", "Personne ici, y'a pas de citrouille."]

## The soft round light every glow is drawn with, made once: a disc fading out to nothing at its edge.
static var _glow_tex: ImageTexture


static func glow_texture() -> ImageTexture:
	if _glow_tex == null:
		var n := 128
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var half := n / 2.0
		for y in n:
			for x in n:
				var d: float = Vector2(x - half + 0.5, y - half + 0.5).length() / half
				var a: float = clampf(1.0 - d, 0.0, 1.0)
				a = a * a * (3.0 - 2.0 * a)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, pow(a, 1.7)))
		_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex


## Does this house give candy tonight? Always the same answer for the same house, so the street stays itself.
static func gives(street_key: String, art: String, i: int) -> bool:
	if art.begins_with("rue_") or art.begins_with("coin_") or art == "ecole" or art == "garages":
		return false
	return absi(hash("%s/%s/%d" % [street_key, art, i])) % 3 < GIVES


## Only the dark, the moon and the stars: for the back lanes, where nobody hands out candy. `who` (Charlotte) carries
## her lantern there too, so a lane is never a black wall.
static func darken(scene: Node2D, width: float, who: Node2D = null) -> void:
	var night := HalloweenNight.new()
	night.name = "HalloweenNight"
	night.z_index = 5
	night.lane_width = width
	night.lane_walker = who
	scene.add_child(night)


## Builds the whole evening into `scene` (a StreetScene).
static func build(scene: Node2D) -> void:
	var night := HalloweenNight.new()
	night.name = "HalloweenNight"
	night.z_index = 5
	scene.add_child(night)
	night._build(scene)


## Set instead of a street: only the dark over a lane this wide.
var lane_width := 0.0
## Who carries the lantern down that lane (Charlotte).
var lane_walker: Node2D
var _scene: Node2D
var _lights: _Lights
var _hangs: Array[Sprite2D] = []
var _time := 0.0


func _build(scene: Node2D) -> void:
	_scene = scene
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scene.seed_value) + 777
	_fall_of_night(NIGHT)
	var moon_at := Vector2(scene._street_width * 0.5, 118.0)
	var moon := _Moon.new()
	moon.where = moon_at
	moon.shade = NIGHT
	add_child(moon)
	var bats := _Bats.new()
	bats.width = scene._street_width
	bats.seed_value = int(scene.seed_value) + 31
	add_child(bats)
	_lights = _new_light_pass()
	_lights.moon = moon_at
	_lights.width = scene._street_width
	_lights.ground_y = StreetScene.CURB_Y
	for i in 110:
		_lights.stars.append(Vector3(rng.randf_range(0.0, scene._street_width), rng.randf_range(10.0, 330.0),
			rng.randf_range(0.7, 1.8)))
	_lights.lantern = scene._charlotte
	# Her own bag, the one she keeps all evening.
	if scene._charlotte:
		CandyBag.give(scene._charlotte, CandyBag.charlotte_kind())
	for x: float in scene._lamp_x:
		_lights.lamps.append(Vector2(x - 8.0, 470.0))
	_dress_the_houses(scene, rng)
	_trick_or_treaters(scene, rng)


func _ready() -> void:
	if lane_width <= 0.0:
		return
	_fall_of_night(NIGHT_LANE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var moon_at := Vector2(lane_width * 0.4, 104.0)
	var moon := _Moon.new()
	moon.where = moon_at
	moon.shade = NIGHT_LANE
	add_child(moon)
	var bats := _Bats.new()
	bats.width = lane_width
	bats.seed_value = 77
	add_child(bats)
	_lights = _new_light_pass()
	_lights.moon = moon_at
	_lights.width = lane_width
	_lights.ground_y = 700.0
	_lights.lantern = lane_walker
	for i in 80:
		_lights.stars.append(Vector3(rng.randf_range(0.0, lane_width), rng.randf_range(10.0, 300.0),
			rng.randf_range(0.7, 1.8)))


# Night over the whole canvas: a multiply, so the street keeps its colours and its contrast, only darker and bluer.
func _fall_of_night(shade: Color) -> void:
	var dark := CanvasModulate.new()
	dark.name = "Night"
	dark.color = shade
	add_child(dark)


# The one additive pass every light is drawn in.
func _new_light_pass() -> _Lights:
	var lights := _Lights.new()
	lights.z_index = 1
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	lights.material = glow
	add_child(lights)
	return lights


func _process(delta: float) -> void:
	_time += delta
	# The hung ghosts and webs sway a little in the night air.
	for i in _hangs.size():
		var s := _hangs[i]
		if is_instance_valid(s):
			s.rotation = sin(_time * 1.1 + i * 1.7) * 0.05
	if _lights:
		_lights.flicker = _time
		_lights.queue_redraw()


# Every house: the ones that give light their windows and put their decorations out, the others stay dark.
func _dress_the_houses(scene: Node2D, rng: RandomNumberGenerator) -> void:
	var panes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/decor/windows.json"))
	var s: float = StreetScene.HOUSE_SCALE
	for i in scene.layout.size():
		var art: String = scene.layout[i]
		if scene.cross_streets.has(art):
			continue
		var origin: Vector2 = scene._house_origin(i)
		# A lane mouth gets nothing at all: it stays a black hole, and Charlotte won't go in there tonight.
		if art.begins_with("ruelle"):
			continue
		var house_gives := HalloweenNight.gives(str(scene.street_key), art, i)
		# The glass of this house, lit or dark. It is painted over its facade but UNDER everything the house draws
		# in front of its windows (`StreetScene.over_tex`), so its outdoor stair, its balconies and their railings
		# still pass in front of the light instead of being covered by it.
		var dark: Array[Dictionary] = []
		var warm: Array[Dictionary] = []
		for w: Dictionary in panes.get(art, []):
			var r: Array = w.pane
			var rect := Rect2(origin + Vector2(float(r[0]), float(r[1])) * s, Vector2(float(r[2]), float(r[3])) * s)
			var bar := origin.y + float(w.get("bar_y", 0.0)) * s
			# A basement window never lights up, even in a house that gives.
			var pane := {"rect": rect, "bar": bar, "trim": Color(str(w.get("trim", "#FFFFFF")))}
			if house_gives and rect.position.y < StreetScene.HOUSE_BASE_Y - 40.0:
				warm.append(pane)
				_lights.windows.append(rect)
			else:
				dark.append(pane)
		var facade: Sprite2D = scene._house_sprites.get(i)
		# Where this house's own things go among the scene's children: its glass right over its facade, then the
		# garden (so a tombstone stands behind the fence), then everything the house draws in front of its windows,
		# and last what sits on the porch and the steps.
		var slot := -1
		if facade != null:
			slot = facade.get_index() + 1
			if not (dark.is_empty() and warm.is_empty()):
				var shutters := _Shutters.new()
				shutters.shade = NIGHT
				shutters.panes = dark
				shutters.lit = warm
				scene.add_child(shutters)
				scene.move_child(shutters, slot)
				slot += 1
		if not house_gives:
			continue
		var door_x: float = scene._door_x(art)
		if is_nan(door_x):
			door_x = origin.x + scene._tex(art).get_width() * s * 0.5
		_lights.porches.append(Vector2(door_x, StreetScene.HOUSE_BASE_Y - 158.0))
		var width: float = scene._tex(art).get_width() * s
		var spots := _spots(origin, width, door_x)
		# Three to five pieces, never two of a kind, each where it belongs.
		var chosen: Array[Dictionary] = []
		var picked: Array[String] = []
		var tries := 0
		var wanted := rng.randi_range(3, 5)
		while chosen.size() < wanted and tries < 30:
			tries += 1
			var kind: String = HalloweenArt.CHOICES[rng.randi() % HalloweenArt.CHOICES.size()]
			var where: String = HalloweenArt.PIECES[kind].where
			if picked.has(kind) or not spots.has(where) or spots[where].is_empty():
				continue
			picked.append(kind)
			chosen.append({"kind": kind, "at": spots[where].pop_front()})
		# The garden and the steps first, so they stand BEHIND the fence and never look as if they were put out on
		# the sidewalk; what hangs on the facade and the balcony goes over it.
		for pass_yard in [true, false]:
			for one: Dictionary in chosen:
				var kind: String = one.kind
				var piece: Dictionary = HalloweenArt.PIECES[kind]
				var where: String = piece.where
				if (where == "yard" or where == "step") != pass_yard:
					continue
				var at: Vector2 = one.at
				var size: Vector2 = piece.size
				var k: float = piece.scale
				var sprite := Sprite2D.new()
				sprite.texture = HalloweenArt.texture(kind)
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				sprite.scale = Vector2.ONE * k
				sprite.centered = false
				sprite.position = at
				# A piece stands on its feet; the ones that hang are held by the top of their canvas.
				var anchor: String = piece.get("anchor", "foot")
				var top := anchor != "foot"
				match anchor:
					"corner":
						sprite.offset = Vector2.ZERO
					"top":
						sprite.offset = Vector2(-size.x * 0.5, 0.0)
					_:
						sprite.offset = Vector2(-size.x * 0.5, -size.y)
				if top and (where == "hang" or where == "corner"):
					_hangs.append(sprite)
				if (where == "yard" or where == "step") and slot >= 0:
					scene.add_child(sprite)
					scene.move_child(sprite, slot)
					slot += 1
				else:
					add_child(sprite)
				for g: Vector2 in piece.get("glow", []):
					_lights.pumpkins.append(at + (sprite.offset + g) * k)
			if pass_yard and slot >= 0:
				# Everything the house draws in front of its windows, laid back over the lit glass and the garden.
				var over: Texture2D = scene.over_tex(art)
				if over != null:
					var front := Sprite2D.new()
					front.texture = over
					front.centered = false
					front.scale = Vector2.ONE * StreetScene.HOUSE_SCALE
					front.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					front.position = origin
					front.material = facade.material
					scene.add_child(front)
					scene.move_child(front, slot)
					slot += 1


# Where a house can put things. NOTHING GOES ON THE SIDEWALK: the garden is the strip of soil behind the fence, at
# the foot of the facade (`HOUSE_BASE_Y`), the steps and the porch are beside the front door, and the rest hangs on
# the facade itself. A spot is the point the piece stands on (or hangs from).
func _spots(origin: Vector2, width: float, door_x: float) -> Dictionary:
	var ground := StreetScene.HOUSE_BASE_Y
	# The porch floor, a little under the first-floor door.
	var left := origin.x + 56.0
	var right := origin.x + width - 56.0
	var spots := {
		# At the foot of the front steps, one each side: that is where a Montréal porch keeps its pumpkins.
		"step": [Vector2(door_x - 78.0, ground - 2.0), Vector2(door_x + 78.0, ground - 2.0)],
		"yard": [],
		"wall": [Vector2(origin.x + width - 96.0, ground - 300.0)],
		"corner": [Vector2(origin.x + 26.0, ground - 318.0)],
		"hang": [Vector2(door_x + 4.0, ground - 234.0)],
		"rail": [Vector2(origin.x + width * 0.5, ground - 214.0)],
	}
	# Three places along the garden, well clear of the path up to the door.
	for x: float in [left + 24.0, lerpf(left, right, 0.5), right - 24.0]:
		if absf(x - door_x) > 96.0:
			spots["yard"].append(Vector2(x, ground - 2.0))
	if spots["yard"].is_empty():
		spots["yard"].append(Vector2(left + 24.0, ground - 2.0))
	return spots


# The other children doing the rounds. Nobody goes alone on Halloween night (Julien): they walk in little groups
# of two to five, each with one grown-up and sometimes two, everyone at the same pace and the same way, the
# children ahead with their costume, their bag and their own little light, the parents walking behind them.
func _trick_or_treaters(scene: Node2D, rng: RandomNumberGenerator) -> void:
	# They walk among the grown-ups, not behind the street: slipped into the child order right after the other
	# passersby, so the trees, lamps and poles still pass in front of them.
	var after := -1
	for i in scene.get_child_count():
		if scene.get_child(i) is Passerby:
			after = i
	# Groups are made up first, so that the whole street still has about as many children out as before.
	var span: float = maxf(scene._street_width - 400.0, 600.0)
	var wanted := clampi(int(span / 300.0), 6, CHILDREN_OUT)
	var groups: Array[Vector2i] = []
	var children := 0
	while children < wanted:
		var size := rng.randi_range(2, 5)
		var grown := 1 if size <= 3 else rng.randi_range(1, 2)
		groups.append(Vector2i(grown, size - grown))
		children += size - grown
	for g in groups.size():
		var way := 1 if rng.randf() < 0.5 else -1
		# One pace and one direction for the whole troop, so it stays a troop all evening.
		var pace := rng.randf_range(120.0, 158.0)
		var at := 200.0 + span * (float(g) + rng.randf_range(0.15, 0.85)) / float(groups.size())
		for i in groups[g].x + groups[g].y:
			var is_kid := i < groups[g].y
			var who := Passerby.new()
			who.look = CharacterLook.random(rng, "child" if is_kid else "adult")
			if is_kid:
				who.look.costume = CostumeArt.ORDER[rng.randi() % CostumeArt.ORDER.size()]
			who.walk_speed = pace
			who.position = Vector2(at, StreetScene.NEIGHBOUR_Y)
			who.scale = Vector2.ONE * StreetScene.CHAR_SCALE * (0.94 if is_kid else 1.0)
			who.facing = way
			who.bounds = Vector2(-260.0, scene._street_width + 260.0)
			scene.add_child(who)
			if is_kid:
				CandyBag.give(who, CandyBag.KINDS[rng.randi() % CandyBag.KINDS.size()])
			# The children carry the light; the grown-ups walk close enough to catch its glow too, just
			# dimmer, so a troop's parents don't vanish into the dark between houses.
			_lights.walkers.append({"who": who, "k": 1.0 if is_kid else 0.4})
			if after >= 0:
				after += 1
				scene.move_child(who, after)
			# The next one of the troop a step behind, on the side they came from.
			at -= float(way) * rng.randf_range(46.0, 82.0)


# The moon over the roofs: a cream disc with its craters, under the night like everything else (the light pass adds
# its halo back over it, so it still shines).
class _Moon:
	extends Node2D
	var where := Vector2.ZERO
	## The night's multiply, which this draws through: the moon is painted in its inverse so it comes out cream and
	## not blue like everything else.
	var shade := Color.WHITE

	func _lit(c: Color) -> Color:
		return Color(c.r / shade.r, c.g / shade.g, c.b / shade.b)

	func _draw() -> void:
		draw_circle(where, 36.0, _lit(Color(1.0, 0.99, 0.94)))
		draw_circle(where + Vector2(-9, -8), 7.0, _lit(Color(0.88, 0.87, 0.80)))
		draw_circle(where + Vector2(8, 5), 9.5, _lit(Color(0.89, 0.88, 0.81)))
		draw_circle(where + Vector2(-4, 15), 5.0, _lit(Color(0.90, 0.89, 0.83)))
		draw_circle(where + Vector2(14, -12), 4.0, _lit(Color(0.90, 0.89, 0.83)))


# The glass of every window tonight: painted over the facade but under everything the house draws in front of its
# windows (its stair, its balconies, their railings — `StreetScene.over_tex`). A house that sleeps gets cold dark
# glass; a house that hands out candy gets the warm room behind it, its curtains and, now and then, a shape on the
# sill. Each pane is {rect, bar (the y of its horizontal bar), trim (the frame colour)}, from `art/decor/windows.json`.
class _Shutters:
	extends Node2D
	## The panes of a house that is asleep.
	var panes: Array[Dictionary] = []
	## The panes of a house that hands out candy: warm light behind the glass.
	var lit: Array[Dictionary] = []
	## The night's multiply: a lit window is painted through its inverse, so it really shines instead of going dark
	## blue with the rest of the street.
	var shade := Color.WHITE

	func _lit_color(c: Color) -> Color:
		return Color(c.r / shade.r, c.g / shade.g, c.b / shade.b, c.a)

	# The frame's bars, which the facade drew on the glass we have just painted over.
	func _bars(pane: Dictionary, tint: Color) -> void:
		var rect: Rect2 = pane.rect
		var trim: Color = pane.trim * tint
		var bar: float = pane.bar
		if bar > rect.position.y and bar < rect.end.y:
			draw_rect(Rect2(rect.position.x, bar - 3.0, rect.size.x, 6.0), trim)
			draw_rect(Rect2(rect.get_center().x - 3.0, bar, 6.0, rect.end.y - bar), trim)

	func _draw() -> void:
		for pane in panes:
			var rect: Rect2 = pane.rect
			# Cold glass: the night in it, a little paler at the top where it catches the sky.
			draw_rect(rect, Color(0.09, 0.10, 0.18))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.45)), Color(0.13, 0.15, 0.25))
			draw_colored_polygon(PackedVector2Array([
				rect.position + Vector2(rect.size.x * 0.52, 0.0), rect.position + Vector2(rect.size.x * 0.78, 0.0),
				rect.position + Vector2(rect.size.x * 0.26, rect.size.y), rect.position + Vector2(0.0, rect.size.y)]),
				Color(0.34, 0.40, 0.58, 0.18))
			_bars(pane, Color(0.34, 0.36, 0.44))
		for pane in lit:
			var rect: Rect2 = pane.rect
			var w := rect.size.x
			var h := rect.size.y
			# The room behind the glass: warm, brightest where the lamp is, amber down at the sill.
			draw_rect(rect, _lit_color(Color(0.98, 0.70, 0.32)))
			draw_rect(rect.grow(-minf(w, h) * 0.14), _lit_color(Color(1.0, 0.86, 0.56, 0.9)))
			draw_rect(Rect2(rect.position + Vector2(w * 0.28, 0.0), Vector2(w * 0.44, h * 0.44)),
				_lit_color(Color(1.0, 0.95, 0.76, 0.55)))
			draw_rect(Rect2(rect.position + Vector2(0.0, h * 0.84), Vector2(w, h * 0.16)),
				_lit_color(Color(0.84, 0.48, 0.20, 0.5)))
			# The curtains, drawn back against the jambs and gathered at half their height.
			for side in 2:
				var x0: float = rect.position.x if side == 0 else rect.end.x
				var dir := 1.0 if side == 0 else -1.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(x0, rect.position.y), Vector2(x0 + dir * w * 0.3, rect.position.y),
					Vector2(x0 + dir * w * 0.2, rect.position.y + h * 0.5),
					Vector2(x0 + dir * w * 0.32, rect.end.y), Vector2(x0, rect.end.y)]),
					_lit_color(Color(0.66, 0.37, 0.21, 0.6)))
			# One window in three has something on its sill, a shape against the light.
			var c := Vector2.ZERO
			var r := minf(w, h)
			var ink := _lit_color(Color(0.24, 0.13, 0.06))
			match absi(int(rect.position.x) * 7 + int(rect.position.y)) % 6:
				0:
					# A jack-o'-lantern someone stood in the window.
					c = Vector2(rect.position.x + w * 0.5, rect.end.y - r * 0.16)
					r *= 0.16
					draw_circle(c, r, ink)
					draw_line(c + Vector2(0, -r * 0.9), c + Vector2(0, -r * 1.7), ink, r * 0.3)
				1:
					# A pot plant.
					c = Vector2(rect.position.x + w * 0.74, rect.end.y)
					r *= 0.13
					draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r),
						c + Vector2(r * 0.7, 0), c + Vector2(-r * 0.7, 0)]), ink)
					for leaf in 3:
						draw_line(c + Vector2(0, -r), c + Vector2(-r + leaf * r, -r * 2.9), ink, r * 0.26)
				2:
					# A cat watching the street go by.
					c = Vector2(rect.position.x + w * 0.3, rect.end.y)
					r *= 0.17
					draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.85, 0), c + Vector2(-r * 0.7, -r * 0.95),
						c + Vector2(-r * 0.78, -r * 1.55), c + Vector2(-r * 0.42, -r * 1.2),
						c + Vector2(-r * 0.06, -r * 1.2), c + Vector2(r * 0.22, -r * 1.6),
						c + Vector2(r * 0.3, -r * 0.95), c + Vector2(r * 0.85, 0)]), ink)
				_:
					pass
			_bars(pane, Color(0.5, 0.42, 0.34))


# Bats crossing the sky now and then, as silhouettes against the night.
class _Bats:
	extends Node2D
	var width := 2000.0
	var seed_value := 1
	var _bats: Array = []
	var _t := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in 7:
			_bats.append({
				"x": rng.randf_range(0.0, width), "y": rng.randf_range(60.0, 300.0),
				"speed": rng.randf_range(26.0, 54.0) * (1.0 if rng.randf() < 0.5 else -1.0),
				"size": rng.randf_range(0.5, 1.0), "phase": rng.randf_range(0.0, TAU),
			})

	func _process(delta: float) -> void:
		_t += delta
		for bat: Dictionary in _bats:
			bat.x = wrapf(float(bat.x) + float(bat.speed) * delta, -80.0, width + 80.0)
		queue_redraw()

	func _draw() -> void:
		for bat: Dictionary in _bats:
			var k: float = bat.size
			var flap := sin(_t * 7.0 + float(bat.phase))
			var at := Vector2(bat.x, float(bat.y) + sin(_t * 0.7 + float(bat.phase)) * 12.0)
			var dir := signf(float(bat.speed))
			var wing := 15.0 * k
			var lift := flap * 7.0 * k
			draw_colored_polygon(PackedVector2Array([
				at + Vector2(0, -3 * k),
				at + Vector2(-wing * dir, -lift - 5 * k),
				at + Vector2(-wing * 0.55 * dir, -lift * 0.3 + 2 * k),
				at + Vector2(0, 4 * k),
				at + Vector2(wing * 0.55 * dir, -lift * 0.3 + 2 * k),
				at + Vector2(wing * dir, -lift - 5 * k),
			]), Color(0.09, 0.07, 0.13))


# Every light of the evening, drawn in one additive pass over the dark: the stars, the moon's halo, the lamps and
# their cones, the windows, the porch lights, the pumpkins, the lanterns the children carry, and the mist.
class _Lights:
	extends Node2D
	## x, y, size
	var stars: Array[Vector3] = []
	var moon := Vector2.INF
	var lamps: Array[Vector2] = []
	var windows: Array[Rect2] = []
	var porches: Array[Vector2] = []
	var pumpkins: Array[Vector2] = []
	## Charlotte: her own little lantern lights the few steps around her.
	var lantern: Node2D
	## The other children out tonight, and the grown-ups walking with them: {"who": Node2D, "k": strength},
	## a child's own lantern at full strength, a grown-up catching just its spill.
	var walkers: Array[Dictionary] = []
	var width := 2000.0
	var ground_y := StreetScene.CURB_Y
	var flicker := 0.0

	# A soft round light: no rings, no hard edge.
	func _glow(at: Vector2, radius: float, color: Color) -> void:
		draw_texture_rect(HalloweenNight.glow_texture(), Rect2(at - Vector2(radius, radius),
			Vector2(radius, radius) * 2.0), false, color)

	func _draw() -> void:
		for i in stars.size():
			var star := stars[i]
			var twinkle := 0.55 + 0.45 * sin(flicker * 1.6 + i * 2.3)
			var at := Vector2(star.x, star.y)
			draw_circle(at, star.z * 0.8, Color(1.0, 0.98, 0.9, 0.85 * twinkle))
			if star.z > 1.4:
				_glow(at, star.z * 4.0, Color(0.9, 0.93, 1.0, 0.3 * twinkle))
		if moon != Vector2.INF:
			_glow(moon, 190.0, Color(0.72, 0.78, 1.0, 0.16))
			_glow(moon, 74.0, Color(0.95, 0.96, 1.0, 0.40))
			draw_circle(moon, 36.0, Color(1.0, 0.99, 0.93, 0.30))
		# The lamps: the head itself, the cone of light under it and the pool on the sidewalk.
		for head: Vector2 in lamps:
			var foot := Vector2(head.x, ground_y - 8.0)
			var spread := 96.0
			draw_polygon(PackedVector2Array([head + Vector2(-13, 6), head + Vector2(13, 6),
					foot + Vector2(spread, 0), foot + Vector2(-spread, 0)]),
				PackedColorArray([Color(LAMP_LIGHT, 0.22), Color(LAMP_LIGHT, 0.22),
					Color(LAMP_LIGHT, 0.0), Color(LAMP_LIGHT, 0.0)]))
			_glow(head, 62.0, Color(LAMP_LIGHT, 0.6))
			_glow(foot, 110.0, Color(LAMP_LIGHT, 0.16))
		# Lit windows: the warm pane, and its light spilling onto the brick.
		for rect in windows:
			_glow(rect.get_center(), rect.size.length() * 1.0, Color(WINDOW_LIGHT, 0.3))
			_glow(rect.get_center() + Vector2(0, rect.size.y * 0.7), rect.size.length() * 1.5, Color(WINDOW_LIGHT, 0.09))
		for at: Vector2 in porches:
			var pulse := 1.0 + 0.03 * sin(flicker * 2.3 + at.x * 0.01)
			_glow(at, 46.0 * pulse, Color(1.0, 0.8, 0.45, 0.5))
			_glow(at + Vector2(0, 70.0), 78.0, Color(1.0, 0.8, 0.45, 0.12))
		# Jack-o'-lanterns and candles: a flame never burns steady.
		for at: Vector2 in pumpkins:
			var flame := 0.86 + 0.14 * sin(flicker * 9.0 + at.x) + 0.06 * sin(flicker * 23.0 + at.y)
			_glow(at, 52.0 * flame, Color(PUMPKIN_LIGHT, 0.6))
			_glow(at, 120.0 * flame, Color(PUMPKIN_LIGHT, 0.12))
		for entry: Dictionary in walkers:
			var who: Node2D = entry.who
			if is_instance_valid(who):
				var k: float = entry.k
				_glow(who.position + Vector2(0, -54.0), 70.0 + 20.0 * k, Color(1.0, 0.82, 0.52, 0.1 + 0.12 * k))
		if is_instance_valid(lantern):
			var hand: Vector2 = lantern.position + Vector2(0, -56.0)
			var swing := 1.0 + 0.04 * sin(flicker * 5.0)
			_glow(hand, 44.0 * swing, Color(1.0, 0.86, 0.55, 0.55))
			_glow(hand + Vector2(0, 40.0), 170.0 * swing, Color(1.0, 0.84, 0.56, 0.17))
		# A low mist along the road, so the street has some air in it.
		for i in 7:
			var mx := fmod(flicker * 5.0 + i * 420.0, width + 600.0) - 300.0
			_glow(Vector2(mx, ground_y + 26.0), 190.0, Color(0.62, 0.70, 0.95, 0.055))
