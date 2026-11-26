class_name Sleepover
extends RefCounted
## The pyjama party that can follow a movie night (Julien's idea, 2026-11-23): at the end of the film she decides whether her
## friends sleep over. They put on pyjamas, spread their sleeping bags on her bedroom floor beside her bed, and do things in the
## lamp's low light: stories by flashlight, shadow puppets on the wall, a pillow fight; then lights out, the night, and the
## morning after (breakfast, goodbyes). The staging is in `house.gd` (`_sleepover_*`); this file holds what is drawn and said.

## Pyjama colours and patterns, one pair per friend in turn.
const COLORS := ["#9DC8F0", "#F7B6D2", "#B6E3B0", "#FFD98A", "#C8B6F2", "#FFB98A", "#8EDDD6"]
const PATTERNS := ["stars", "dots", "hearts", "cats", "clouds", "checks", "rainbow"]

## The shadow puppets, in the order they come: [kind, what the friends guess, what it was].
const SHADOWS := [
	["rabbit", "Un lapin ! Hi hi !", "Oui ! Un lapin qui mange une carotte !"],
	["bird", "Un oiseau qui vole !", "Bravo ! C'est un hibou, en fait !"],
	["dog", "Un chien qui jappe !", "Ouaf ! Presque : c'est un loup !"],
]
const WHISPERS := ["Chut… tu dors ?", "Non… j'ai pas sommeil.", "Moi non plus ! On se raconte une dernière histoire ?", "Chuuut ! Maman va nous entendre…"]
const MORNING := [
	"Bonjour ! J'ai super bien dormi !",
	"Moi aussi ! J'ai rêvé qu'on était dans le film !",
	"Ça sent les crêpes ! Maman a fait un déjeuner !",
]
const GOODBYE := ["Merci pour la soirée pyjama, Chachoue !", "C'était la meilleure ! On recommence bientôt ?", "À bientôt ! Dis merci à tes parents !"]


## `look` in pyjamas (a copy): long sleeves and trousers in the same colour, a pattern, slippers, nothing on the head. `i` picks
## the colour and the pattern.
static func pyjama(look: CharacterLook, i: int) -> CharacterLook:
	var l := look.duplicate() as CharacterLook
	l.outfit = "pyjama"
	l.outfit_color = Color(COLORS[i % COLORS.size()])
	l.legwear = "pants"
	l.legwear_color = l.outfit_color
	l.sleeve = "long"
	l.pattern = PATTERNS[i % PATTERNS.size()]
	l.shoes = "slipper"
	l.hat = ""
	l.scarf = ""
	l.backpack = ""
	l.costume = ""
	l.overrides = {}
	return l


## The sleeping bags on the floor: one per friend, a pillow at the head end, a zip, and (when `asleep`) a hump of someone under it.
class Camp:
	extends Node2D
	var spots: Array[float] = []
	var colors: Array[Color] = []
	var asleep := false

	func _draw() -> void:
		for k in spots.size():
			var x := spots[k]
			var c := colors[k % colors.size()]
			# A flat bag seen from a little above: a rounded oblong, a lighter inside edge, the pillow, the zip.
			draw_set_transform(Vector2(x, 664.0), 0.0, Vector2(1.0, 0.3))
			draw_circle(Vector2(6, 14), 96.0, Color(0, 0, 0, 0.18))
			draw_set_transform(Vector2.ZERO)
			var bag := PackedVector2Array()
			for i in 28:
				var a := TAU * i / 28.0
				bag.append(Vector2(x + cos(a) * 92.0, 664.0 + sin(a) * 22.0))
			draw_colored_polygon(bag, c.darkened(0.2))
			var inner := PackedVector2Array()
			for i in 28:
				var a := TAU * i / 28.0
				inner.append(Vector2(x + cos(a) * 84.0, 662.0 + sin(a) * 17.0))
			draw_colored_polygon(inner, c)
			draw_polyline(inner + PackedVector2Array([inner[0]]), c.darkened(0.35), 1.5, true)
			draw_line(Vector2(x - 70, 664), Vector2(x + 76, 664), c.darkened(0.3), 1.4)
			for z in 12:
				draw_line(Vector2(x - 66 + z * 12.0, 662), Vector2(x - 66 + z * 12.0, 666), c.lightened(0.3), 1.0)
			draw_colored_polygon(_oval(Vector2(x - 66, 656), 28.0, 11.0), Color("#FFFDF8"))
			draw_polyline(_oval(Vector2(x - 66, 656), 28.0, 11.0) + PackedVector2Array([Vector2(x - 38, 656)]), Color("#DCD2C0"), 1.2, true)
			if asleep:
				# Someone under the cover: a head on the pillow, a long soft hump.
				draw_circle(Vector2(x - 62, 648), 10.0, Color("#3A2A22", 0.9))
				var hump := PackedVector2Array()
				for i in 24:
					var a := PI + PI * i / 23.0
					hump.append(Vector2(x - 20 + cos(a) * 66.0, 662.0 + sin(a) * 20.0))
				draw_colored_polygon(hump, c.lightened(0.12))
				draw_polyline(hump, c.darkened(0.3), 1.4, true)

	func _oval(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return p


## The flashlight's round of light on the wall, with a shadow puppet moving in it.
class ShadowShow:
	extends Node2D
	var kind := "rabbit"
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# The beam on the wall: warm round, soft at the edge.
		for i in 6:
			draw_circle(Vector2.ZERO, 150.0 - i * 16.0, Color(1.0, 0.93, 0.7, 0.10 + i * 0.045))
		var ink := Color(0.1, 0.07, 0.12, 0.92)
		match kind:
			"rabbit":
				# Head, a twitching nose, two long ears, a round body hopping, the carrot.
				var hop := absf(sin(_t * 3.0)) * 14.0
				draw_circle(Vector2(-10, 20 - hop), 44.0, ink)
				draw_circle(Vector2(46, -10 - hop), 26.0, ink)
				for e in [-1.0, 1.0]:
					var base := Vector2(46 + e * 8.0, -26 - hop)
					draw_colored_polygon(PackedVector2Array([base + Vector2(-6, 0), base + Vector2(6, 0), base + Vector2(e * 10.0 + sin(_t * 4.0) * 3.0, -70)]), ink)
				draw_circle(Vector2(72, -6 - hop), 5.0 + sin(_t * 12.0), ink)
				draw_circle(Vector2(-52, 30 - hop), 12.0, ink)
			"bird":
				var flap := sin(_t * 7.0)
				draw_circle(Vector2.ZERO, 26.0, ink)
				draw_circle(Vector2(30, -14), 14.0, ink)
				draw_colored_polygon(PackedVector2Array([Vector2(42, -16), Vector2(64, -10), Vector2(42, -6)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(-8, -6), Vector2(-70, -40 * flap - 10), Vector2(-30, 10)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(6, -6), Vector2(70, -46 * flap - 14), Vector2(26, 12)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(-24, 4), Vector2(-64, 18), Vector2(-26, 14)]), ink)
			_:
				# A dog (or a wolf) barking: a long snout that opens and closes, one ear, a wagging tail.
				var open := absf(sin(_t * 5.0)) * 16.0
				draw_circle(Vector2(0, 0), 30.0, ink)
				draw_colored_polygon(PackedVector2Array([Vector2(20, -12), Vector2(78, -6 - open * 0.3), Vector2(78, 4), Vector2(20, 14)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(20, 14), Vector2(74, 6), Vector2(70, 14 + open), Vector2(22, 24)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(-6, -24), Vector2(10, -56), Vector2(18, -22)]), ink)
				draw_colored_polygon(PackedVector2Array([Vector2(-26, 8), Vector2(-76, -20 + sin(_t * 9.0) * 14.0), Vector2(-30, 22)]), ink)
