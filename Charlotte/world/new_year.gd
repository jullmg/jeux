class_name NewYear
extends RefCounted
## New Year's Eve and Day (quest "jourdelan", after Christmas; Julien: an evening at home), step by step
## (`GameState.flags.jourdelan_step`), in `house.gd`:
##   1. Maman says she may stay up till midnight tonight: they watch the Bye Bye on the hallway TV (`TvShows` "byebye"), the
##      hall dimmed, then the countdown to midnight ("10… 9… BONNE ANNÉE !"), wishes, and the fireworks through the salon
##      window (`Fireworks`);
##   2. off to bed ("Bonne nuit… pis bonne année !");
##   3. New Year's Day: she tells her parents her resolution (`RESOLUTIONS`, kept in `flags.jourdelan_resolution`) and they
##      wish each other the usual "Bonne année, pis la santé !": the quest is done.

const QUEST := "jourdelan"
const STEP := "jourdelan_step"
const RESOLUTION := "jourdelan_resolution"
const HEADING := "🎆  Le jour de l'an"
## In front of the TV: what they say while the show is on, before the countdown ([who: 0 Papa, 1 Maman, -1 Charlotte, line]).
const SHOW := [
	[0, "Le Bye Bye ! Y a rien de plus québécois que ça."],
	[1, "Hi hi ! Regarde le bonhomme de neige qui danse !"],
	[-1, "J'ai vraiment le droit de veiller jusqu'à minuit ?"],
	[1, "Juste à soir, ma chouette !"],
	[0, "C'est presque minuit ! On compte ensemble ?"],
]
const AFTER := [
	[1, "Bonne année, ma Chachoue !"],
	[0, "Bonne année, pis la santé !"],
	[-1, "Bonne année, Papa ! Bonne année, Maman !"],
	[0, "Venez voir les feux d'artifice par la fenêtre !"],
]
## Her resolution for the new year: the card's line, what she says, what her parents answer.
const RESOLUTIONS := [
	["Lire un livre chaque semaine", "Cette année, je vais lire un livre chaque semaine !", "Bravo ! On ira à la bibliothèque."],
	["Toujours nourrir mon hamster", "Je vais toujours nourrir mon hamster sans qu'on me le dise !", "Y va être content, ton p'tit hamster !"],
	["Aider Papa pis Maman", "Je vais vous aider plus souvent dans la maison !", "Oh, que c'est gentil, mon cœur !"],
	["Manger moins de bonbons", "Je vais manger moins de bonbons… un peu moins !", "Hi hi ! Un peu moins, c'est déjà ça !"],
]


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
			return "C'est le soir du 31 décembre ! Va regarder le Bye Bye avec tes parents, à la télé du corridor."
		2:
			return "Il est minuit passé : au lit !"
		3:
			return "C'est le jour de l'an ! Va dire ta bonne résolution à Maman ou à Papa."
	return str(Quests.ALL[QUEST].hint)


## Fireworks seen through a window: the night sky over the glass (`glass`, world rect), bursts of colour opening, falling and
## fading, each with a flash; for `seconds`.
class Fireworks:
	extends Node2D
	var glass := Rect2()
	var seconds := 9.0
	## The room's night (a CanvasModulate): the fireworks are painted through its inverse so they keep their full brightness.
	var night := Color.WHITE
	var _t := 0.0
	var _next := 0.2
	var _bursts: Array = []
	var _rng := RandomNumberGenerator.new()

	func _ready() -> void:
		_rng.seed = 2027

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0 and _t < seconds - 1.5:
			_next = _rng.randf_range(0.35, 0.8)
			var colours := [Color("#FF4D6D"), Color("#FFD23F"), Color("#4DA6FF"), Color("#5BD16E"), Color("#E86BFF"), Color.WHITE]
			var at := Vector2(_rng.randf_range(glass.position.x + 24.0, glass.end.x - 24.0), _rng.randf_range(glass.position.y + 26.0, glass.position.y + glass.size.y * 0.45))
			_bursts.append({"at": at, "t": 0.0, "c": colours[_rng.randi_range(0, colours.size() - 1)], "r": _rng.randf_range(40.0, 64.0)})
			Sfx.play("pop", at, -10.0, _rng.randf_range(0.5, 0.8))
		for b in _bursts:
			b.t += delta
		_bursts = _bursts.filter(func(b: Dictionary) -> bool: return b.t < 1.6)
		if _t > seconds:
			queue_free()
			return
		queue_redraw()

	func _lit(c: Color) -> Color:
		return Color(c.r / night.r, c.g / night.g, c.b / night.b, c.a)

	func _draw() -> void:
		var fade := clampf(minf(_t, seconds - _t), 0.0, 1.0)
		draw_rect(glass, Color(0.04, 0.05, 0.18, 0.95 * fade))
		for i in 14:
			draw_circle(glass.position + Vector2(fmod(i * 37.0, glass.size.x), fmod(i * 53.0, glass.size.y * 0.6)), 1.0, Color(1, 1, 0.9, 0.5 * fade))
		for b: Dictionary in _bursts:
			var u: float = b.t / 1.6
			var flash := clampf(1.0 - b.t * 4.0, 0.0, 1.0)
			if flash > 0.0:
				draw_circle(b.at, b.r * 0.6, _lit(Color(b.c, 0.4 * flash)))
			for k in 16:
				var a := TAU * k / 16.0
				var p: Vector2 = b.at + Vector2(cos(a), sin(a)) * b.r * ease(u, 0.4) + Vector2(0, 30.0 * u * u)
				if glass.has_point(p):
					draw_circle(p, 3.0 * (1.0 - u) + 0.8, _lit(Color(b.c, (1.0 - u) * fade)))
					draw_line(p, p - Vector2(cos(a), sin(a)) * 10.0 * (1.0 - u), _lit(Color(b.c, 0.55 * (1.0 - u) * fade)), 1.6)
