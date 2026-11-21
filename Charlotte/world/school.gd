class_name School
extends RefCounted
## A school day, and the first one (the quest "ecole", in winter after Halloween). A day runs in steps, kept in
## `GameState.flags.ecole_step`:
##   1. in the morning Maman waits at the front door, which leads to the school ("Maman t'accompagne à l'école…") instead of the
##      street: at seven Charlotte may not cross Dandurand by herself (the first day Maman gives the quest; after that the
##      front door asks, once a day, "À l'école" or "Jouer dehors": `available_today`);
##   2. the schoolyard before class (`scenes/cour_ecole.gd`): Maman says goodbye at the gate; on the first day Alyzée, new at
##      school, sits alone on a bench and they make friends and play tag (`Alyzee`); the bell, and in through the pupils' door;
##   3. the classroom (`scenes/classe.gd`): Madame Nadia, her desk beside Alyzée's, three questions at the board (`LESSONS`),
##      a sticker; the bell at the end of the day;
##   4. the service de garde (`scenes/service_de_garde.gd`): crafts, blocks, a snack, a game with Alyzée, until Papa comes to
##      pick her up and takes her home ("Papa te ramène à la maison…"). On the first day, telling Papa about her new friend
##      finishes the quest.
## Meeting Alyzée is `flags.met_alyzee` (the notebook's friends page); a day done is `flags.ecole_today_done`, cleared at bedtime.

const QUEST := "ecole"
const STEP := "ecole_step"
const TODAY_DONE := "ecole_today_done"
## The questions she has already been asked, so a day brings new ones until they have all come round.
const SEEN := "ecole_seen"
## How many stickers Madame Nadia has given her.
const STICKERS := "ecole_stickers"
## How many lessons she has had: the first is the welcome mix, then one theme a day (`SchoolMath.CYCLE`).
const LESSONS := "ecole_lessons"
const YARD := "res://scenes/cour_ecole.tscn"
const CLASS := "res://scenes/classe.tscn"
const GARDE := "res://scenes/service_de_garde.tscn"
const HOME := "res://scenes/house.tscn"
## Where she comes in at home (the vestibule).
const HOME_X := 300.0
## What the notes of its steps are headed with (Notebook.announce).
const HEADING := "🏫  L'école"
const TEACHER := "Madame Nadia"
## How many questions a lesson has: the shapes first (`SHAPES_PER_LESSON`), then the sums.
const PER_LESSON := 4
const SHAPES_PER_LESSON := 2

## Madame Nadia's questions on shapes (Julien: losange, triangle, trapèze, parallélogramme, rectangle, carré): what she asks,
## the shape she draws on the board ("" = none), the right answer, then the wrong ones (shuffled on the card).
## A shape to draw is one of `SHAPES`, drawn by `draw_shape`.
const SHAPE_QUESTIONS := [
	["Quelle est cette forme ?", "carre", "un carré", "un losange", "un rectangle"],
	["Quelle est cette forme ?", "rectangle", "un rectangle", "un carré", "un parallélogramme"],
	["Quelle est cette forme ?", "triangle", "un triangle", "un trapèze", "un losange"],
	["Quelle est cette forme ?", "losange", "un losange", "un carré", "un parallélogramme"],
	["Quelle est cette forme ?", "trapeze", "un trapèze", "un parallélogramme", "un rectangle"],
	["Quelle est cette forme ?", "parallelogramme", "un parallélogramme", "un trapèze", "un losange"],
	["Combien de côtés a un triangle ?", "", "3", "4", "5"],
	["Combien de côtés a un trapèze ?", "trapeze", "4", "3", "5"],
	["Combien de sommets a un losange ?", "losange", "4", "2", "6"],
	["Quelle forme a 4 côtés égaux\net 4 angles droits ?", "", "un carré", "un losange", "un trapèze"],
	["Quelle forme a 4 côtés égaux,\nmais pas d'angles droits ?", "", "un losange", "un carré", "un rectangle"],
	["Quelle forme a 4 angles droits,\n2 longs côtés et 2 courts ?", "", "un rectangle", "un carré", "un losange"],
	["Quelle forme a seulement\n2 côtés parallèles ?", "", "un trapèze", "un parallélogramme", "un carré"],
	["Quelle forme a ses côtés opposés\nparallèles deux à deux, sans angles droits ?", "", "un parallélogramme", "un trapèze", "un triangle"],
	["Un carré, c'est aussi\nune sorte de…", "", "rectangle", "triangle", "trapèze"],
	["Combien d'angles droits\na un rectangle ?", "rectangle", "4", "2", "0"],
]
const SHAPES := ["carre", "rectangle", "triangle", "losange", "trapeze", "parallelogramme"]

## The sums (Julien: additions and subtractions, the level of a 3e année): numbers to 999, carrying and borrowing.
## `SUM_MAX` is the largest answer an addition gives; raise it (and the ranges in `_sum`) for older pupils.
const SUM_MAX := 999


## 0 = no school today (or the day is over), else the step of the day she is on (1 for the quest switched on by the debug menu).
static func step() -> int:
	if GameState.flags.has(STEP):
		return int(GameState.flags[STEP])
	return 1 if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## Her first day: the quest is on.
static func first_day() -> bool:
	return Quests.active(QUEST)


## After the first day, school is there once a day, in the morning: the front door offers it until she has been (or goes
## to sleep: a new day).
static func available_today() -> bool:
	return Quests.done(QUEST) and step() == 0 and not GameState.flags.get(TODAY_DONE, false)


## The day is over (Papa takes her home): no more school until she has slept.
static func end_day() -> void:
	GameState.flags.erase(STEP)
	GameState.flags[TODAY_DONE] = true


## She may leave the yard (the gate) only when it isn't a school day at all.
static func can_leave() -> bool:
	return step() == 0


## A classmate's look for indoors: no hat or tuque in class (a bow or a headband stays), nothing of Halloween.
static func indoors(look: CharacterLook) -> CharacterLook:
	if look.hat not in ["bow", "headband"]:
		look.hat = ""
	look.scarf = ""
	return look


## The theme of the lesson being given: {id, title, intro}, id "" for the first one (the welcome mix).
static var current := {}


## A lesson is over (the sticker is given): tomorrow's will have the next theme.
static func lesson_done() -> void:
	GameState.flags[LESSONS] = int(GameState.flags.get(LESSONS, 0)) + 1


## The theme of lesson number `n` (0 = the first, "" for the welcome mix, then round `SchoolMath.CYCLE`).
static func theme_of(n: int) -> String:
	return "" if n <= 0 else SchoolMath.CYCLE[(n - 1) % SchoolMath.CYCLE.size()]


## Today's questions: the first lesson is a mix (below); after it each day has a theme of its own (`SchoolMath.lesson`).
static func lesson(rng: RandomNumberGenerator) -> Array:
	var n := int(GameState.flags.get(LESSONS, 0))
	var id := theme_of(n)
	if id == "":
		current = {"id": "", "title": "", "intro": ""}
		return _welcome_lesson(rng)
	current = SchoolMath.info(id)
	return SchoolMath.lesson(id, theme_of(n - 1), rng)


## The first lesson: two on shapes she hasn't had yet (as long as there are), then an addition and a subtraction made up
## for the day, in either order; the order of the answers shuffled. Each is {ask (on the card), say (read out), board (in
## chalk), shape (to draw, or ""), answers, right}.
static func _welcome_lesson(rng: RandomNumberGenerator) -> Array:
	var seen: Array = GameState.flags.get(SEEN, [])
	var fresh: Array = []
	for i in SHAPE_QUESTIONS.size():
		if not seen.has(i):
			fresh.append(i)
	if fresh.size() < SHAPES_PER_LESSON:
		seen = []
		fresh = range(SHAPE_QUESTIONS.size())
	var out: Array = []
	for k in SHAPES_PER_LESSON:
		var i: int = fresh.pop_at(rng.randi_range(0, fresh.size() - 1))
		seen.append(i)
		var q: Array = SHAPE_QUESTIONS[i]
		var ask: String = q[0]
		out.append(_question(ask.replace("\n", " "), ask.replace("\n", " "), ask, q[1], q.slice(2)))
	GameState.flags[SEEN] = seen
	var adding_first := rng.randf() < 0.5
	for k in PER_LESSON - SHAPES_PER_LESSON:
		out.append(_sum(rng, (k % 2 == 0) == adding_first))
	return out


static func _question(ask: String, say: String, board: String, shape: String, answers: Array) -> Dictionary:
	var right: String = answers[0]
	var mixed := answers.duplicate()
	mixed.shuffle()
	return {"ask": ask, "say": say, "board": board, "shape": shape, "answers": mixed, "right": mixed.find(right)}


## An addition with a carry (a 2- or 3-digit number and a 2-digit one), or a subtraction with a borrow; the wrong answers are
## the slips a pupil makes: the carry or the borrow forgotten, ten too many or too few, one off.
static func _sum(rng: RandomNumberGenerator, adding: bool) -> Dictionary:
	var a := 0
	var b := 0
	var answer := 0
	var slip := 0
	if adding:
		# The units add up past ten, so there is something to carry.
		while true:
			a = rng.randi_range(24, 680) if rng.randf() < 0.6 else rng.randi_range(24, 89)
			b = rng.randi_range(13, 89)
			if a % 10 + b % 10 >= 10 and a + b <= SUM_MAX:
				break
		answer = a + b
		slip = answer - 10
	else:
		# The units of the second are bigger, so she has to borrow.
		while true:
			a = rng.randi_range(42, 900) if rng.randf() < 0.6 else rng.randi_range(42, 99)
			b = rng.randi_range(13, mini(a - 10, 89))
			if b % 10 > a % 10 and a - b > 0:
				break
		answer = a - b
		# Taking the small unit from the big one instead of borrowing.
		slip = _no_borrow(a, b)
	var wrong: Array = []
	for w: int in [slip, answer + 10, answer - 1, answer + 1, answer - 10]:
		if w > 0 and w != answer and not wrong.has(w):
			wrong.append(w)
		if wrong.size() == 2:
			break
	var sign := "+" if adding else "−"
	var word := "plus" if adding else "moins"
	return _question("Combien font %d %s %d ?" % [a, sign, b], "Combien font %d %s %d ?" % [a, word, b],
		"%d %s %d = ?" % [a, sign, b], "", [str(answer), str(wrong[0]), str(wrong[1])])


## The answer of a subtraction done without borrowing: in each column the small digit taken from the big one.
static func _no_borrow(a: int, b: int) -> int:
	var out := 0
	var place := 1
	while a > 0 or b > 0:
		out += absi(a % 10 - b % 10) * place
		a /= 10
		b /= 10
		place *= 10
	return out


## Draws one of `SHAPES` in chalk on `canvas`, centred on `at`, about `size` px tall: a wobbly double stroke like chalk, and
## the little squares of the right angles on the square and the rectangle.
static func draw_shape(canvas: CanvasItem, kind: String, at: Vector2, size: float, color := Color(1, 1, 1, 0.92)) -> void:
	var k := size / 100.0
	if kind.begins_with("pie:"):
		_draw_pie(canvas, kind, at, size, color)
		return
	var pts: Array = []
	match kind:
		"carre":
			pts = [Vector2(-50, -50), Vector2(50, -50), Vector2(50, 50), Vector2(-50, 50)]
		"rectangle":
			pts = [Vector2(-90, -45), Vector2(90, -45), Vector2(90, 45), Vector2(-90, 45)]
		"triangle":
			pts = [Vector2(0, -52), Vector2(62, 48), Vector2(-62, 48)]
		"losange":
			pts = [Vector2(0, -52), Vector2(66, 0), Vector2(0, 52), Vector2(-66, 0)]
		"trapeze":
			pts = [Vector2(-45, -45), Vector2(45, -45), Vector2(90, 45), Vector2(-90, 45)]
		"parallelogramme":
			pts = [Vector2(-50, -45), Vector2(95, -45), Vector2(50, 45), Vector2(-95, 45)]
		_:
			return
	var line := PackedVector2Array()
	for p: Vector2 in pts:
		line.append(at + p * k)
	line.append(line[0])
	var faint := Color(color, color.a * 0.35)
	canvas.draw_polyline(line, color, maxf(3.0, 4.0 * k), true)
	var shifted := PackedVector2Array()
	for p: Vector2 in line:
		shifted.append(p + Vector2(1.5, 1.2) * k)
	canvas.draw_polyline(shifted, faint, maxf(1.5, 2.0 * k), true)
	if kind in ["carre", "rectangle"]:
		var m := 12.0 * k
		for i in 4:
			var c: Vector2 = line[i]
			var to_next: Vector2 = (line[i + 1] - c).normalized() * m
			var to_prev: Vector2 = (line[(i + 3) % 4] - c).normalized() * m
			canvas.draw_polyline(PackedVector2Array([c + to_next, c + to_next + to_prev, c + to_prev]), faint, maxf(1.5, 2.0 * k), true)


## A pizza cut in equal slices, some of them coloured in: kind "pie:<slices>:<coloured>".
static func _draw_pie(canvas: CanvasItem, kind: String, at: Vector2, size: float, color: Color) -> void:
	var parts := kind.split(":")
	var n := int(parts[1])
	var lit := int(parts[2])
	var r := size * 0.5
	var faint := Color(color, color.a * 0.35)
	for i in n:
		var a0 := -PI / 2.0 + TAU * i / n
		var a1 := -PI / 2.0 + TAU * (i + 1) / n
		if i < lit:
			var wedge := PackedVector2Array([at])
			for j in 11:
				wedge.append(at + Vector2.from_angle(lerpf(a0, a1, j / 10.0)) * r)
			canvas.draw_colored_polygon(wedge, Color("#E8A33D", 0.85))
		canvas.draw_line(at, at + Vector2.from_angle(a0) * r, color, 3.0, true)
	canvas.draw_arc(at, r, 0.0, TAU, 48, color, 4.0, true)
	canvas.draw_arc(at + Vector2(1.5, 1.2), r, 0.0, TAU, 48, faint, 2.0, true)


## What the notebook says to do next.
static func hint() -> String:
	match step():
		1:
			return "Maman t'attend à la porte d'en avant, dans le vestibule, pour t'amener à l'école."
		2:
			return "Avant la classe, va jouer dans la cour. Quelqu'un est peut-être tout seul…" if not Alyzee.met() \
				else "Quand la cloche sonne, entre dans l'école par la porte des élèves."
		3:
			return "Assieds-toi à ton pupitre, à côté d'Alyzée, et réponds aux questions de %s." % TEACHER
		4:
			return "Au service de garde, amuse-toi en attendant Papa. Raconte-lui ta journée quand il arrive !"
	return str(Quests.ALL[QUEST].hint)
