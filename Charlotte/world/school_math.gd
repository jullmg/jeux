class_name SchoolMath
extends RefCounted
## Madame Nadia's lessons, the maths of a 3e année (Julien). After the first lesson (which keeps its mix of shapes and sums:
## `School.lesson`), every school day has a THEME, one after the other round `CYCLE`, so two days never ask the same thing:
## rounding to the ten or the hundred, bigger and smaller, additions, subtractions, geometry, multiplication and division,
## the value of the digits, fractions, number patterns, money, time and measures, word problems. A lesson is three questions
## on the theme of the day and one review of the day before's (`lesson`); every question is made up on the spot with its own
## numbers, and the wrong answers are the slips a pupil makes. **A new theme = its id in `CYCLE`, its words in `INFO` and
## a case in `make`.** A question is a `School._question` dictionary: {ask, say, board, shape, answers, right}.

const CYCLE := ["arrondir", "addition", "geometrie", "comparer", "soustraction", "multiplication", "position", "fractions",
	"suites", "argent", "temps", "problemes"]

## id: [what the board says, what Madame Nadia says].
const INFO := {
	"arrondir": ["Arrondir les nombres", "Aujourd'hui, on apprend à arrondir :\nà la dizaine ou à la centaine près !"],
	"comparer": ["Plus petit, plus grand", "Aujourd'hui, on compare des nombres :\nplus petit, plus grand, égal !"],
	"addition": ["Les additions", "Aujourd'hui, on fait des additions,\navec des retenues !"],
	"soustraction": ["Les soustractions", "Aujourd'hui, on fait des soustractions,\navec des emprunts !"],
	"geometrie": ["La géométrie", "Aujourd'hui, de la géométrie :\ndes formes, des solides et des lignes !"],
	"multiplication": ["Multiplier et diviser", "Aujourd'hui, on révise les tables\nde multiplication et la division !"],
	"position": ["La valeur des chiffres", "Aujourd'hui, on regarde les chiffres :\ncentaines, dizaines et unités !"],
	"fractions": ["Les fractions", "Aujourd'hui, les fractions :\nla moitié, le quart et les parts de pizza !"],
	"suites": ["Les suites de nombres", "Aujourd'hui, on découvre les suites :\nquel est le prochain nombre ?"],
	"argent": ["L'argent", "Aujourd'hui, on compte de l'argent :\ntoonies, huards et pièces de 25 sous !"],
	"temps": ["Le temps et les mesures", "Aujourd'hui, le temps et les mesures :\nheures, minutes, mètres et grammes !"],
	"problemes": ["Les problèmes", "Aujourd'hui, des problèmes à résoudre :\nlis bien, pis réfléchis !"],
}

## More geometry questions, after `School.SHAPE_QUESTIONS` (same layout: ask, shape to draw, right answer, two wrong).
const GEO := [
	["Combien de faces a un cube ?", "", "6", "4", "8"],
	["Combien d'arêtes a un cube ?", "", "12", "8", "6"],
	["Combien de sommets a un cube ?", "", "8", "6", "12"],
	["Quel solide ressemble à un ballon ?", "", "une sphère", "un cube", "un cône"],
	["Quel solide ressemble à\nune boîte de conserve ?", "", "un cylindre", "une sphère", "un cube"],
	["Quel solide ressemble à un dé ?", "", "un cube", "un cylindre", "un cône"],
	["Quel solide ressemble à\nun chapeau de fête ?", "", "un cône", "une sphère", "un cube"],
	["Deux droites qui ne se touchent\njamais sont…", "", "parallèles", "perpendiculaires", "obliques"],
	["Deux droites qui se croisent\nà angle droit sont…", "", "perpendiculaires", "parallèles", "égales"],
	["Combien de côtés a un hexagone ?", "", "6", "5", "8"],
	["Combien de côtés a un pentagone ?", "", "5", "6", "4"],
	["Combien de côtés a un octogone ?", "", "8", "6", "10"],
	["Un carré a des côtés de 5 cm.\nQuel est son périmètre ?", "carre", "20 cm", "25 cm", "10 cm"],
	["Un rectangle mesure 6 cm sur 3 cm.\nQuel est son périmètre ?", "rectangle", "18 cm", "9 cm", "12 cm"],
	["Un triangle a des côtés de 4 cm,\n5 cm et 6 cm. Son périmètre ?", "triangle", "15 cm", "10 cm", "20 cm"],
	["Quelle forme a 3 sommets ?", "", "un triangle", "un carré", "un cercle"],
	["Combien de sommets a un cercle ?", "", "0", "1", "4"],
]

const WORD_PEOPLE := ["Charlotte", "Alyzée", "Constance", "Billie"]
const ITEMS := [["boîtes", "crayons"], ["sacs", "pommes"], ["assiettes", "biscuits"], ["pots", "fleurs"], ["paniers", "oranges"]]
const COINS := [
	["1 toonie, 1 huard et 2 pièces de 25 ¢", 350],
	["2 huards et 3 pièces de 25 ¢", 275],
	["1 toonie et 4 pièces de 10 ¢", 240],
	["3 pièces de 25 ¢ et 2 pièces de 5 ¢", 85],
	["1 huard, 2 pièces de 25 ¢ et 1 pièce de 10 ¢", 160],
	["2 toonies et 2 pièces de 25 ¢", 450],
]
const CONVERSIONS := [
	["Combien de minutes y a-t-il\ndans 1 heure ?", 60, 100, 30],
	["Combien de jours y a-t-il\ndans une semaine ?", 7, 5, 10],
	["Combien de centimètres y a-t-il\ndans 1 mètre ?", 100, 10, 1000],
	["Combien de mètres y a-t-il\ndans 1 kilomètre ?", 1000, 100, 10],
	["Combien de grammes y a-t-il\ndans 1 kilogramme ?", 1000, 100, 10],
	["Combien de mois y a-t-il\ndans une année ?", 12, 10, 52],
	["Combien de minutes y a-t-il\ndans une demi-heure ?", 30, 15, 60],
	["Combien de secondes y a-t-il\ndans 1 minute ?", 60, 100, 30],
	["Combien de centimètres y a-t-il\ndans 3 mètres ?", 300, 30, 3000],
	["Combien de millilitres y a-t-il\ndans 1 litre ?", 1000, 100, 10],
]


static func info(id: String) -> Dictionary:
	var words: Array = INFO[id]
	return {"id": id, "title": words[0], "intro": words[1]}


## Today's lesson: three questions on `id`, then one review of `before` (the theme of the day before, "" = none).
static func lesson(id: String, before: String, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	if id == "geometrie":
		out = _geometry(3, rng)
	else:
		var taken: Array = []
		for k in 3:
			out.append(make(id, k, rng, taken))
	if before != "":
		var taken2: Array = []
		out.append(make(before, rng.randi_range(0, 2), rng, taken2) if before != "geometrie" else _geometry(1, rng)[0])
	return out


## Question number `k` (0 to 2) of a theme; `taken` keeps the pooled ones (conversions) from coming twice in a lesson.
static func make(id: String, k: int, rng: RandomNumberGenerator, taken: Array) -> Dictionary:
	match id:
		"arrondir":
			return _round(k, rng)
		"comparer":
			return _compare(k, rng)
		"addition":
			return sum(rng, true, k)
		"soustraction":
			return sum(rng, false, k)
		"geometrie":
			return _geometry(1, rng)[0]
		"multiplication":
			return _times(k, rng)
		"position":
			return _position(k, rng)
		"fractions":
			return _fractions(k, rng)
		"suites":
			return _pattern(k, rng)
		"argent":
			return _money(k, rng)
		"temps":
			return _time(k, rng, taken)
		_:
			return _problem(k, rng)


# ── Helpers ─────────────────────────────────────────────────────

## `ask` may have line breaks (kept on the card and the board only when `keep_breaks`).
static func _q(ask: String, board: String, answers: Array, say := "", shape := "", keep_breaks := false) -> Dictionary:
	var flat := ask.replace("\n", " ")
	return School._question(ask if keep_breaks else flat, say if say != "" else flat, board, shape, answers)


## Two wrong numbers from the likeliest slips (`cands`, in order), never the right one, never twice, never below zero.
static func _wrongs(right: int, cands: Array) -> Array:
	var out: Array = []
	for c: int in cands:
		if c != right and c >= 0 and not out.has(c):
			out.append(c)
	var step := 1
	while out.size() < 2:
		for c: int in [right + step, right - step]:
			if c != right and c >= 0 and not out.has(c) and out.size() < 2:
				out.append(c)
		step += 1
	return [str(out[0]), str(out[1])]


static func _wrongs_text(right: String, cands: Array) -> Array:
	var out: Array = []
	for c: String in cands:
		if c != right and not out.has(c):
			out.append(c)
	return [out[0], out[1]]


static func _pick(rng: RandomNumberGenerator, list: Array) -> Variant:
	return list[rng.randi_range(0, list.size() - 1)]


# ── Rounding ────────────────────────────────────────────────────

static func _round(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var n := rng.randi_range(11, 99)
			while n % 10 == 0:
				n = rng.randi_range(11, 99)
			if rng.randf() < 0.4:
				n += rng.randi_range(1, 8) * 100
			var right := ((n + 5) / 10) * 10
			var w := _wrongs(right, [n / 10 * 10, (n / 10 + 1) * 10, right + 10, right - 10])
			return _q("Arrondis %d à la dizaine près." % n, "%d ≈ ?\n(à la dizaine)" % n, [str(right), w[0], w[1]])
		1:
			var n := rng.randi_range(101, 899)
			while n % 100 == 0:
				n = rng.randi_range(101, 899)
			var right := ((n + 50) / 100) * 100
			var w := _wrongs(right, [n / 100 * 100, (n / 100 + 1) * 100, right + 100, right - 100])
			return _q("Arrondis %d à la centaine près." % n, "%d ≈ ?\n(à la centaine)" % n, [str(right), w[0], w[1]])
	var target := rng.randi_range(4, 9) * 10
	var right := target + rng.randi_range(-5, 4)
	var w := _wrongs(right, [target + 5, target - 6, target + 6, target + 15])
	return _q("Quel nombre, arrondi à la dizaine\nprès, donne %d ?" % target, "≈ %d\n(à la dizaine)" % target, [str(right), w[0], w[1]],
		"Quel nombre, arrondi à la dizaine près, donne %d ?" % target)


# ── Bigger and smaller ──────────────────────────────────────────

static func _close_pair(rng: RandomNumberGenerator, equal_chance := 0.0) -> Array:
	var a := rng.randi_range(120, 880)
	if rng.randf() < equal_chance:
		return [a, a]
	var b := a + rng.randi_range(5, 70) * (1 if rng.randf() < 0.5 else -1)
	return [a, b]


static func _compare(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var p := _close_pair(rng)
			var bigger := rng.randf() < 0.5
			var right: int = maxi(p[0], p[1]) if bigger else mini(p[0], p[1])
			var other: int = mini(p[0], p[1]) if bigger else maxi(p[0], p[1])
			var word := "grand" if bigger else "petit"
			return _q("Quel nombre est le plus %s ?" % word, "%d   ou   %d" % [p[0], p[1]], [str(right), str(other), "Ils sont égaux"],
				"Quel nombre est le plus %s : %d ou %d ?" % [word, p[0], p[1]])
		1:
			var p := _close_pair(rng, 0.15)
			var sign := "<" if p[0] < p[1] else (">" if p[0] > p[1] else "=")
			var others: Array = []
			for s: String in ["<", ">", "="]:
				if s != sign:
					others.append(s)
			return _q("Quel signe va entre %d et %d ?" % [p[0], p[1]], "%d  ?  %d" % [p[0], p[1]], [sign, others[0], others[1]],
				"Quel signe va entre %d et %d : plus petit que, plus grand que, ou égal ?" % [p[0], p[1]])
	var base := rng.randi_range(120, 800)
	var nums := [base, base + rng.randi_range(8, 40), base + rng.randi_range(45, 120)]
	var asc := "%d, %d, %d" % [nums[0], nums[1], nums[2]]
	var desc := "%d, %d, %d" % [nums[2], nums[1], nums[0]]
	var swap := "%d, %d, %d" % [nums[1], nums[0], nums[2]]
	var shown := nums.duplicate()
	shown.shuffle()
	return _q("Du plus petit au plus grand,\nquel est le bon ordre ?", "%d   %d   %d" % [shown[0], shown[1], shown[2]], [asc, desc, swap],
		"Range ces nombres du plus petit au plus grand : %d, %d, %d." % [shown[0], shown[1], shown[2]], "", true)


# ── Additions and subtractions ──────────────────────────────────

## An addition with something to carry, or a subtraction with something to borrow. `level`: 0 two digits, 1 a hundreds number and
## a two-digit one, 2 two hundreds numbers. The wrong answers: the carry or the borrow forgotten, ten or a hundred off, one off.
static func sum(rng: RandomNumberGenerator, adding: bool, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var answer := 0
	var slip := 0
	if adding:
		while true:
			match level:
				0:
					a = rng.randi_range(24, 89)
					b = rng.randi_range(13, 89)
				1:
					a = rng.randi_range(110, 880)
					b = rng.randi_range(13, 89)
				_:
					a = rng.randi_range(120, 650)
					b = rng.randi_range(110, 340)
			var carry := a % 10 + b % 10 >= 10 or (level == 2 and (a / 10) % 10 + (b / 10) % 10 >= 10)
			if carry and a + b <= School.SUM_MAX:
				break
		answer = a + b
		slip = _no_carry(a, b)
	else:
		while true:
			match level:
				0:
					a = rng.randi_range(42, 99)
					b = rng.randi_range(13, maxi(14, mini(a - 10, 89)))
				1:
					a = rng.randi_range(150, 900)
					b = rng.randi_range(13, 89)
				_:
					a = rng.randi_range(300, 950)
					b = rng.randi_range(110, a - 60)
			var borrow := b % 10 > a % 10 or (level == 2 and (b / 10) % 10 > (a / 10) % 10)
			if borrow and a - b > 0:
				break
		answer = a - b
		slip = School._no_borrow(a, b)
	var cands: Array = [slip, answer + 10, answer - 1, answer + 1, answer - 10]
	if level > 0:
		cands = [slip, answer + 100, answer + 10, answer - 10, answer - 1]
	var w := _wrongs(answer, cands)
	var sign := "+" if adding else "−"
	var word := "plus" if adding else "moins"
	return _q("Combien font %d %s %d ?" % [a, sign, b], "%d %s %d = ?" % [a, sign, b], [str(answer), w[0], w[1]],
		"Combien font %d %s %d ?" % [a, word, b])


## The sum of the columns with no carry: each digit added alone (the carry forgotten).
static func _no_carry(a: int, b: int) -> int:
	var out := 0
	var place := 1
	while a > 0 or b > 0:
		out += ((a % 10 + b % 10) % 10) * place
		a /= 10
		b /= 10
		place *= 10
	return out


# ── Geometry ────────────────────────────────────────────────────

## `count` questions the pupil hasn't had yet from `School.SHAPE_QUESTIONS` and `GEO` together (the seen ones are remembered).
static func _geometry(count: int, rng: RandomNumberGenerator) -> Array:
	var all: Array = School.SHAPE_QUESTIONS.duplicate()
	all.append_array(GEO)
	var seen: Array = GameState.flags.get(School.SEEN, [])
	var fresh: Array = []
	for i in all.size():
		if not seen.has(i):
			fresh.append(i)
	if fresh.size() < count:
		seen = []
		fresh = range(all.size())
	var out: Array = []
	for k in count:
		var i: int = fresh.pop_at(rng.randi_range(0, fresh.size() - 1))
		seen.append(i)
		var q: Array = all[i]
		var ask: String = q[0]
		out.append(School._question(ask.replace("\n", " "), ask.replace("\n", " "), ask, q[1], q.slice(2)))
	GameState.flags[School.SEEN] = seen
	return out


# ── Multiplication and division ─────────────────────────────────

static func _times(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var a := rng.randi_range(2, 9)
			var b := rng.randi_range(3, 10)
			var right := a * b
			var w := _wrongs(right, [a * (b + 1), a * (b - 1), (a + 1) * b, a + b])
			return _q("Combien font %d × %d ?" % [a, b], "%d × %d = ?" % [a, b], [str(right), w[0], w[1]], "Combien font %d fois %d ?" % [a, b])
		1:
			var items: Array = _pick(rng, ITEMS)
			var a := rng.randi_range(3, 8)
			var b := rng.randi_range(3, 9)
			var right := a * b
			var w := _wrongs(right, [a + b, a * (b + 1), a * (b - 1)])
			return _q("Il y a %d %s, avec %d %s\nchacun(e). Combien en tout ?" % [a, items[0], b, items[1]], "%d × %d = ?" % [a, b],
				[str(right), w[0], w[1]], "Il y a %d %s, avec %d %s dans chacun. Combien de %s en tout ?" % [a, items[0], b, items[1], items[1]], "", true)
	var c := rng.randi_range(2, 9)
	var d := rng.randi_range(2, 9)
	var a := c * d
	var w := _wrongs(c, [c + 1, c - 1, d])
	return _q("Combien font %d ÷ %d ?" % [a, d], "%d ÷ %d = ?" % [a, d], [str(c), w[0], w[1]], "Combien font %d divisé par %d ?" % [a, d])


# ── The value of the digits ─────────────────────────────────────

static func _position(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var digits: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
			digits.shuffle()
			if digits[0] == 0:
				digits.reverse()
			var h: int = digits[0]
			var t: int = digits[1]
			var u: int = digits[2]
			var n := h * 100 + t * 10 + u
			var place := rng.randi_range(0, 2)
			var names := ["centaines", "dizaines", "unités"]
			var all := [h, t, u]
			var right: int = all[place]
			var rest: Array = []
			for i in 3:
				if i != place:
					rest.append(str(all[i]))
			return _q("Dans le nombre %d, quel est\nle chiffre des %s ?" % [n, names[place]], "%d" % n, [str(right), rest[0], rest[1]],
				"Dans le nombre %d, quel est le chiffre des %s ?" % [n, names[place]])
		1:
			var h := rng.randi_range(1, 9)
			var t := rng.randi_range(0, 9)
			var u := rng.randi_range(1, 9)
			var right := h * 100 + t * 10 + u
			var w := _wrongs(right, [h * 100 + u * 10 + t, t * 10 + u, h * 100 + t + u])
			var tens := "%d dizaine%s" % [t, "s" if t > 1 else ""]
			return _q("Quel nombre est formé de %d centaine%s,\n%s et %d unités ?" % [h, "s" if h > 1 else "", tens, u], "%dc  %dd  %du" % [h, t, u],
				[str(right), w[0], w[1]], "Quel nombre est formé de %d centaines, %s et %d unités ?" % [h, tens, u], "", true)
	var h := rng.randi_range(1, 9)
	var t := rng.randi_range(1, 9)
	var u := rng.randi_range(1, 9)
	var right := h * 100 + t * 10 + u
	var w := _wrongs(right, [h * 100 + u * 10 + t, h * 1000 + t * 10 + u, h * 100 + t + u])
	return _q("Combien font %d + %d + %d ?" % [h * 100, t * 10, u], "%d + %d + %d = ?" % [h * 100, t * 10, u], [str(right), w[0], w[1]],
		"Combien font %d plus %d plus %d ?" % [h * 100, t * 10, u])


# ── Fractions ───────────────────────────────────────────────────

static func _fractions(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var n := rng.randi_range(2, 20) * 2
			var right := n / 2
			var w := _wrongs(right, [n * 2, right + 2, right - 1])
			return _q("Quelle est la moitié de %d ?" % n, "½ de %d = ?" % n, [str(right), w[0], w[1]])
		1:
			var n := rng.randi_range(2, 10) * 4
			var right := n / 4
			var w := _wrongs(right, [n / 2, n * 4, right + 1])
			return _q("Quel est le quart de %d ?" % n, "¼ de %d = ?" % n, [str(right), w[0], w[1]])
	var parts: int = _pick(rng, [2, 3, 4, 6, 8])
	var eaten := rng.randi_range(1, parts - 1)
	var right := "%d/%d" % [eaten, parts]
	var w := _wrongs_text(right, ["%d/%d" % [parts - eaten, parts], "%d/%d" % [parts, eaten], "%d/%d" % [eaten, parts + 2], "%d/%d" % [eaten + 1, parts]])
	return _q("Quelle fraction de la pizza\nest coloriée ?", "La pizza", [right, w[0], w[1]], "Quelle fraction de la pizza est coloriée ?",
		"pie:%d:%d" % [parts, eaten], true)


# ── Number patterns ─────────────────────────────────────────────

static func _pattern(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var s: int = _pick(rng, [2, 3, 4, 5, 10])
			var a := rng.randi_range(1, 40)
			var last := a + s * 3
			var right := last + s
			var w := _wrongs(right, [right - 1, right + 1, last + 2 * s])
			return _q("Quel est le prochain nombre\ndans la suite ?", "%d, %d, %d, %d, ?" % [a, a + s, a + 2 * s, last], [str(right), w[0], w[1]],
				"Quel est le prochain nombre dans la suite : %d, %d, %d, %d ?" % [a, a + s, a + 2 * s, last], "", true)
		1:
			var s: int = _pick(rng, [2, 3, 5, 10])
			var a := rng.randi_range(40, 99)
			var last := a - s * 2
			var right := last - s
			var w := _wrongs(right, [right + 1, right - 1, last + s])
			return _q("Cette suite descend.\nQuel est le prochain nombre ?", "%d, %d, %d, ?" % [a, a - s, last], [str(right), w[0], w[1]],
				"Cette suite descend : %d, %d, %d. Quel est le prochain nombre ?" % [a, a - s, last], "", true)
	var s: int = _pick(rng, [5, 10, 20, 25, 100])
	var a := rng.randi_range(1, 6) * s
	var right := a + 2 * s
	var w := _wrongs(right, [right + 1, right - 1, right + s])
	return _q("Quel nombre manque\ndans la suite ?", "%d, %d, ?, %d, %d" % [a, a + s, a + 3 * s, a + 4 * s], [str(right), w[0], w[1]],
		"Quel nombre manque dans la suite : %d, %d, quelque chose, %d, %d ?" % [a, a + s, a + 3 * s, a + 4 * s], "", true)


# ── Money ───────────────────────────────────────────────────────

static func _cash(cents: int) -> String:
	return "%d,%02d $" % [cents / 100, cents % 100]


static func _money(k: int, rng: RandomNumberGenerator) -> Dictionary:
	match k:
		0:
			var have: int = _pick(rng, [500, 1000, 2000])
			var cost := rng.randi_range(2, 19) * 25 + (0 if rng.randf() < 0.6 else 5)
			var right := have - cost
			var slip := School._no_borrow(have, cost)
			var w := _wrongs(right, [slip if slip < have else right + 50, right + 50, right - 100, right + 100])
			return _q("Tu as %s. Tu achètes un jouet\nà %s. Combien te reste-t-il ?" % [_cash(have), _cash(cost)], "%s − %s" % [_cash(have), _cash(cost)],
				[_cash(right), _cash(w[0].to_int()), _cash(w[1].to_int())],
				"Tu as %s. Tu achètes un jouet à %s. Combien te reste-t-il ?" % [_cash(have), _cash(cost)], "", true)
		1:
			var c: Array = _pick(rng, COINS)
			var right: int = c[1]
			var w := _wrongs(right, [right + 50, right - 50, right + 10, right - 25])
			return _q("Combien font %s ?" % c[0], "toonie = 2 $\nhuard = 1 $", [_cash(right), _cash(w[0].to_int()), _cash(w[1].to_int())])
	var cents: int = _pick(rng, [100, 150, 200, 250, 300])
	var right := cents / 25
	var w := _wrongs(right, [right + 2, right - 1, right * 2])
	return _q("Combien de pièces de 25 ¢ faut-il\npour faire %s ?" % _cash(cents), "25 ¢ → %s" % _cash(cents), [str(right), w[0], w[1]],
		"Combien de pièces de 25 sous faut-il pour faire %s ?" % _cash(cents), "", true)


# ── Time and measures ───────────────────────────────────────────

static func _hm(minutes: int) -> String:
	var h := (minutes / 60) % 12
	if h == 0:
		h = 12
	var m := minutes % 60
	return "%d h" % h if m == 0 else "%d h %02d" % [h, m]


static func _time(k: int, rng: RandomNumberGenerator, taken: Array) -> Dictionary:
	match k:
		0:
			var start: int = rng.randi_range(1, 11) * 60 + _pick(rng, [0, 15, 30, 45])
			var add: int = _pick(rng, [15, 30, 45])
			var right := _hm(start + add)
			var w := _wrongs_text(right, [_hm(start + add + 15), _hm(start + add - 15), _hm(start + add + 60), _hm(start - add)])
			return _q("Il est %s. Quelle heure sera-t-il\ndans %d minutes ?" % [_hm(start), add], "%s + %d min" % [_hm(start), add], [right, w[0], w[1]],
				"Il est %s. Quelle heure sera-t-il dans %d minutes ?" % [_hm(start), add], "", true)
		1:
			var i := rng.randi_range(0, CONVERSIONS.size() - 1)
			while taken.has(i):
				i = rng.randi_range(0, CONVERSIONS.size() - 1)
			taken.append(i)
			var c: Array = CONVERSIONS[i]
			return _q(c[0], "1 m = 100 cm\n1 h = 60 min" if i < 3 else "Les mesures", [str(c[1]), str(c[2]), str(c[3])], "", "", true)
	var from := rng.randi_range(1, 5)
	var hours := rng.randi_range(2, 4)
	var w := _wrongs(hours, [hours + 1, hours - 1, from + hours + from])
	return _q("Charlotte joue de %d h à %d h.\nPendant combien d'heures ?" % [from, from + hours], "%d h → %d h" % [from, from + hours],
		[str(hours), w[0], w[1]], "Charlotte joue de %d heures à %d heures. Pendant combien d'heures ?" % [from, from + hours], "", true)


# ── Word problems ───────────────────────────────────────────────

static func _problem(k: int, rng: RandomNumberGenerator) -> Dictionary:
	var who: String = _pick(rng, WORD_PEOPLE)
	match k:
		0:
			var a := rng.randi_range(24, 80)
			var b := rng.randi_range(13, 60)
			while (a % 10) + (b % 10) < 10:
				a = rng.randi_range(24, 80)
				b = rng.randi_range(13, 60)
			var right := a + b
			var w := _wrongs(right, [_no_carry(a, b), right + 10, right - 1, right - 10])
			if rng.randf() < 0.5:
				return _q("%s a %d autocollants. Madame Nadia\nlui en donne %d de plus. Combien en a-t-elle ?" % [who, a, b], "Problème du jour",
					[str(right), w[0], w[1]], "", "", true)
			return _q("Dans la cour, il y a %d enfants. Puis\n%d autres arrivent. Combien y en a-t-il ?" % [a, b], "Problème du jour",
				[str(right), w[0], w[1]], "", "", true)
		1:
			var a := rng.randi_range(52, 97)
			var b := rng.randi_range(13, a - 10)
			while (b % 10) <= (a % 10):
				a = rng.randi_range(52, 97)
				b = rng.randi_range(13, a - 10)
			var right := a - b
			var w := _wrongs(right, [School._no_borrow(a, b), right + 10, right - 1, right - 10])
			if rng.randf() < 0.5:
				return _q("Maman a fait %d biscuits. %s et ses\namies en mangent %d. Combien en reste-t-il ?" % [a, who, b], "Problème du jour",
					[str(right), w[0], w[1]], "", "", true)
			return _q("Il y a %d livres à la bibliothèque. Les\nélèves en empruntent %d. Combien en reste-t-il ?" % [a, b], "Problème du jour",
				[str(right), w[0], w[1]], "", "", true)
	if rng.randf() < 0.5:
		var packs := rng.randi_range(3, 8)
		var per := rng.randi_range(3, 9)
		var right := packs * per
		var w := _wrongs(right, [packs + per, right + per, right - per])
		return _q("Papa achète %d paquets de %d jus.\nCombien de jus a-t-il en tout ?" % [packs, per], "Problème du jour", [str(right), w[0], w[1]], "", "", true)
	var friends := rng.randi_range(2, 6)
	var each := rng.randi_range(2, 8)
	var total := friends * each
	var w := _wrongs(each, [each + 1, each - 1, friends])
	return _q("%s partage %d bonbons également\nentre %d amies. Combien chacune en a-t-elle ?" % [who, total, friends], "Problème du jour",
		[str(each), w[0], w[1]], "", "", true)
