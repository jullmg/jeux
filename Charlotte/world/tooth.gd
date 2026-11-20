class_name Tooth
extends RefCounted
## The wobbly tooth (quest "dent", winter, after the snow fort; Julien), at home (`house.gd`):
##   1. Maman sees that her front tooth wobbles and tells her to bite into an apple: the fridge gives one, she bites, and
##      the tooth comes out;
##   2. she puts it under her pillow: the bed, at bedtime ("Bonne nuit… pis bonne visite, la fée des dents !"); in the night
##      the tooth fairy flies across the dark (`Fairy`), a tinkle of bells;
##   3. in the morning she lifts her pillow (the bed, a "!"): a two-dollar coin, a "toonie", from the tooth fairy. Done (the
##      quest's reward is the toonie).

const QUEST := "dent"
const STEP := "dent_step"
const HEADING := "🦷  La dent qui branle"


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


static func clear() -> void:
	GameState.flags.erase(STEP)


static func hint() -> String:
	match step():
		1:
			return "Ta dent d'en avant branle ! Croque dans une pomme : il y en a dans le frigo de la cuisine."
		2:
			return "Ta dent est tombée ! Mets-la sous ton oreiller, pis va te coucher."
		3:
			return "Regarde sous ton oreiller : la fée des dents est peut-être passée !"
	return str(Quests.ALL[QUEST].hint)


## Canvas 64 × 64: her little tooth.
static func tooth() -> ImageTexture:
	var s := '<path d="M20 14 Q32 6 44 14 Q50 26 44 36 L40 54 Q37 58 34 52 L32 40 L30 52 Q27 58 24 54 L20 36 Q14 26 20 14 Z" fill="#FFFFFF" stroke="#B8C4D0" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M24 18 Q30 14 34 17" stroke="#E6EEF6" stroke-width="3" fill="none" stroke-linecap="round"/>'
	return InteriorArt.tex(64, 64, s)


## Canvas 64 × 64: the toonie: a silver ring round a gold middle, the bear on it in a few strokes.
static func toonie() -> ImageTexture:
	var s := '<circle cx="32" cy="32" r="27" fill="#C9CED6" stroke="#8E959E" stroke-width="2"/>'
	s += '<circle cx="32" cy="32" r="17" fill="#E2B13C" stroke="#A8801A" stroke-width="2"/>'
	s += '<path d="M22 36 Q24 28 32 28 Q40 27 42 32 L44 36 L40 37 L38 34 L28 35 L26 38 Z" fill="#B8862A"/>'
	s += '<circle cx="26" cy="24" r="4" fill="#FFFFFF" opacity="0.4"/>'
	return InteriorArt.tex(64, 64, s)


## The tooth fairy flying across the night: a little glowing figure with fluttering wings, a trail of sparkles.
class Fairy:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t > 4.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var u := _t / 4.0
		var at := Vector2(lerpf(-80.0, 1360.0, u), 260.0 - sin(u * PI) * 120.0 + sin(_t * 5.0) * 10.0)
		for k in 22:
			var back := at - Vector2(16.0 + k * 14.0, -sin(_t * 5.0 - k * 0.3) * 8.0 + sin(u * PI - k * 0.02) * 0.0)
			draw_circle(back, 3.2 - k * 0.12, Color(1.0, 0.95, 0.7, 0.85 - k * 0.035))
		draw_circle(at, 26.0, Color(1.0, 0.9, 0.6, 0.18))
		var flap := absf(sin(_t * 22.0))
		for side in [-1.0, 1.0]:
			draw_set_transform(at + Vector2(0, -4), side * (0.5 + flap * 0.5), Vector2(1.0, 0.55))
			draw_circle(Vector2(0, -12), 11.0, Color(0.8, 0.9, 1.0, 0.75))
		draw_set_transform(Vector2.ZERO)
		draw_circle(at, 6.0, Color("#FFE9A8"))
		draw_circle(at + Vector2(0, -9), 4.5, Color("#FFF6D8"))
		# Her wand and its star.
		draw_line(at + Vector2(4, 0), at + Vector2(16, -10), Color("#FFFFFF"), 1.6)
		draw_circle(at + Vector2(17, -11), 3.0, Color("#FFF6C8"))
