class_name HalloweenNight
extends Node2D
## The street on Halloween night: everything the evening adds to an ordinary `StreetScene`, built by
## `StreetScene._build_halloween()` while `Halloween.night()`.
##
## The street goes dark under a veil; the houses that hand out candy light their windows, hang their decorations
## (`HalloweenArt`) and wait with a doorbell and a "!", while the dark ones are asleep and give nothing. A few other
## children in costume walk past, and the street lamps and jack-o'-lanterns glow through the dark.

## The dark, deeper over the sky than down at the street where the windows and lamps light things up.
const VEIL_SKY := Color(0.03, 0.04, 0.16, 0.9)
const VEIL_GROUND := Color(0.05, 0.06, 0.19, 0.6)
const WINDOW_LIGHT := Color(1.0, 0.82, 0.42)
## How many houses in three give out candy.
const GIVES := 2
const CANDY_LINES := ["Des bonbons ou un sort !", "Joyeuse Halloween !", "Des bonbons, s'il vous plaît !"]
const NEIGHBOUR_LINES := ["Oh, le beau déguisement ! Tiens, ma belle.", "Joyeuse Halloween ! Sers-toi.",
	"Ben voyons donc, que t'es belle ! Prends-en deux.", "Bonne Halloween, ma chouette !"]
const ASLEEP := ["Pas de lumière… ils dorment déjà.", "Celle-là est éteinte, on passe !", "Personne ici, y'a pas de citrouille."]


## Does this house give candy tonight? Always the same answer for the same house, so the street stays itself.
static func gives(street_key: String, art: String, i: int) -> bool:
	if art.begins_with("rue_") or art.begins_with("coin_") or art == "ecole" or art == "garages":
		return false
	return absi(hash("%s/%s/%d" % [street_key, art, i])) % 3 < GIVES


## Builds the whole evening into `scene` (a StreetScene).
static func build(scene: Node2D) -> void:
	var night := HalloweenNight.new()
	night.name = "HalloweenNight"
	night.z_index = 5
	scene.add_child(night)
	night._build(scene)


var _scene: Node2D
var _lights: _Lights
var _hangs: Array[Sprite2D] = []
var _time := 0.0


func _build(scene: Node2D) -> void:
	_scene = scene
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scene.seed_value) + 777
	# The dark over the whole street, people and props included: night up in the sky, a little softer down at the street.
	var veil := _Veil.new()
	veil.width = scene._street_width + 600.0
	add_child(veil)
	# Everything that shines through it.
	_lights = _Lights.new()
	_lights.z_index = 1
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_lights.material = glow
	add_child(_lights)
	_moon_and_stars(scene, rng)
	_light_the_lamps(scene)
	_dress_the_houses(scene, rng)
	_trick_or_treaters(scene, rng)


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


# The moon over the roofs and a scatter of stars, drawn over the dark.
func _moon_and_stars(scene: Node2D, rng: RandomNumberGenerator) -> void:
	var moon := Vector2(scene._street_width * 0.5, 120.0)
	_lights.moon = moon
	for i in 90:
		_lights.stars.append(Vector2(rng.randf_range(0.0, scene._street_width), rng.randf_range(10.0, 330.0)))


# The street lamps and the glow they throw on the sidewalk.
func _light_the_lamps(scene: Node2D) -> void:
	for x: float in scene._lamp_x:
		_lights.halos.append([Vector2(x - 8.0, 470.0), 70.0, Color(1.0, 0.88, 0.58, 0.5)])
		_lights.halos.append([Vector2(x - 8.0, 650.0), 120.0, Color(1.0, 0.86, 0.55, 0.14)])


# Every house: the ones that give light their windows and put their decorations out, the others stay dark.
func _dress_the_houses(scene: Node2D, rng: RandomNumberGenerator) -> void:
	var panes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/decor/windows.json"))
	var s: float = StreetScene.HOUSE_SCALE
	for i in scene.layout.size():
		var art: String = scene.layout[i]
		if scene.cross_streets.has(art):
			continue
		var origin: Vector2 = scene._house_origin(i)
		if not HalloweenNight.gives(str(scene.street_key), art, i):
			continue
		# Warm light in the windows.
		for w: Dictionary in panes.get(art, []):
			var r: Array = w.pane
			var rect := Rect2(origin + Vector2(float(r[0]), float(r[1])) * s, Vector2(float(r[2]), float(r[3])) * s)
			if rect.position.y > StreetScene.HOUSE_BASE_Y - 40.0:
				continue
			_lights.windows.append(rect)
			_lights.halos.append([rect.get_center(), rect.size.length() * 0.42, Color(1.0, 0.84, 0.5, 0.12)])
		# Its decorations, two or three of them, and the porch light over the door.
		var door_x: float = scene._door_x(art)
		if is_nan(door_x):
			door_x = origin.x + scene._tex(art).get_width() * s * 0.5
		_lights.halos.append([Vector2(door_x, StreetScene.HOUSE_BASE_Y - 150.0), 54.0, Color(1.0, 0.8, 0.45, 0.45)])
		var width: float = scene._tex(art).get_width() * s
		var spots := _spots(origin, width, door_x)
		var how_many := rng.randi_range(2, 3)
		var used := []
		for n in how_many:
			var kind: String = HalloweenArt.CHOICES[rng.randi() % HalloweenArt.CHOICES.size()]
			var piece: Dictionary = HalloweenArt.PIECES[kind]
			var where: String = piece.where
			if used.has(kind) or not spots.has(where) or spots[where].is_empty():
				continue
			used.append(kind)
			var at: Vector2 = spots[where].pop_front()
			var sprite := Sprite2D.new()
			sprite.texture = HalloweenArt.texture(kind)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.scale = Vector2.ONE * float(piece.scale)
			sprite.centered = false
			sprite.position = at
			if where == "hang" or where == "corner":
				sprite.offset = Vector2(-float(piece.size.x) * 0.5, 0.0)
				_hangs.append(sprite)
			add_child(sprite)
			if piece.has("glow"):
				var g: Vector2 = piece.glow
				_lights.halos.append([at + g * float(piece.scale), 46.0, Color(1.0, 0.62, 0.2, 0.55)])


# Where a house can put things: on the steps either side of its door, hung from the balcony, in the corner of the
# facade, along the railing, in the little garden behind the fence.
func _spots(origin: Vector2, width: float, door_x: float) -> Dictionary:
	var ground := StreetScene.HOUSE_BASE_Y
	return {
		"step": [Vector2(door_x - 78.0, ground - 46.0), Vector2(door_x + 46.0, ground - 46.0)],
		"yard": [Vector2(origin.x + 30.0, ground - 10.0), Vector2(origin.x + width - 90.0, ground - 10.0)],
		"wall": [Vector2(origin.x + width - 110.0, ground - 250.0)],
		"corner": [Vector2(origin.x + 20.0, ground - 290.0)],
		"hang": [Vector2(door_x + 8.0, ground - 230.0)],
		"rail": [Vector2(origin.x + 24.0, ground - 212.0)],
	}


# A few other children doing the rounds, each in a costume of their own.
func _trick_or_treaters(scene: Node2D, rng: RandomNumberGenerator) -> void:
	for i in 4:
		var kid := Passerby.new()
		kid.look = CharacterLook.random(rng, "child")
		kid.look.costume = CostumeArt.ORDER[rng.randi() % CostumeArt.ORDER.size()]
		kid.walk_speed = rng.randf_range(150.0, 200.0)
		kid.position = Vector2(rng.randf_range(260.0, maxf(scene._street_width - 260.0, 400.0)), StreetScene.NEIGHBOUR_Y)
		kid.scale = Vector2.ONE * StreetScene.CHAR_SCALE * 0.94
		kid.facing = 1 if rng.randf() < 0.5 else -1
		kid.bounds = Vector2(-140.0, scene._street_width + 140.0)
		kid.z_index = -1
		scene.add_child(kid)


# Window light, lamp halos and the glow of the pumpkins, all drawn in one additive pass over the dark.
class _Lights:
	extends Node2D
	var windows: Array[Rect2] = []
	## [centre, radius, colour]
	var halos: Array = []
	var stars: Array[Vector2] = []
	var moon := Vector2.INF
	var flicker := 0.0

	func _draw() -> void:
		for i in stars.size():
			var twinkle := 0.55 + 0.45 * sin(flicker * 1.6 + i * 2.3)
			draw_circle(stars[i], 1.6, Color(1.0, 0.98, 0.9, 0.75 * twinkle))
		if moon != Vector2.INF:
			draw_circle(moon, 86.0, Color(0.9, 0.92, 1.0, 0.05))
			draw_circle(moon, 54.0, Color(0.95, 0.96, 1.0, 0.09))
			draw_circle(moon, 34.0, Color(0.99, 0.98, 0.92, 0.85))
		for rect in windows:
			draw_rect(rect, Color(WINDOW_LIGHT, 0.5))
			draw_rect(rect.grow(2.0), Color(WINDOW_LIGHT, 0.18))
		for h: Array in halos:
			var c: Color = h[2]
			var wobble := 1.0 + 0.05 * sin(flicker * 3.1 + (h[0] as Vector2).x * 0.01)
			for ring in 3:
				var t := (ring + 1.0) / 3.0
				draw_circle(h[0], float(h[1]) * t * wobble, Color(c, c.a * (1.0 - t * 0.7)))


# The night itself: darkest up in the sky, lighter down where the windows and the lamps are.
class _Veil:
	extends Node2D
	var width := 2000.0

	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(-300, -400), Vector2(width, -400), Vector2(width, 760), Vector2(-300, 760)])
		draw_polygon(pts, PackedColorArray([VEIL_SKY, VEIL_SKY, VEIL_GROUND, VEIL_GROUND]))
