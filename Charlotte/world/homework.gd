class_name Homework
extends RefCounted
## « Les devoirs de la semaine »: the homework Charlotte does at the desk in her bedroom. Julien gives the week's
## homework; a week that was never given keeps the one before it, so there is always something on her desk.
##
## ADDING A WEEK = one more entry at the END of `WEEKS`:
##   {"from": "2026-11-09",                      the Monday it starts (ISO, always a Monday)
##    "title": "Les nombres jusqu'à cent",       what her notebook calls it
##    "exercises": [...]}                        in the order she does them
## The week in force is the last one whose Monday has come (`week()`), so nothing has to be removed.
##
## An exercise is a dictionary:
##   kind    "nombre" (she answers on the number pad), "mot" (she writes it on the keyboard) or "choix"
##   show    what is written on her page
##   say     what the voice reads out loud (the same thing by default). For a dictée, `show` says nothing away
##           ("Écris le mot que tu entends.") and `say` holds the word; with no voice on the computer the pad
##           writes `say` instead, so the homework still works.
##   answer  the right answer, or an array of answers that are all right. Case, spaces, punctuation and even the
##           accents are forgiven (`check`), but a word written without its accents is only "presque".
##   options the choices, for kind "choix"
##   hint    a little help under the question (optional)

const FLAG := "devoirs"
## What a finished week puts in her pocket.
const REWARD := 2.0
const MONTHS := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre",
	"octobre", "novembre", "décembre"]

const WEEKS := [
	{
		"from": "2026-11-02",
		"title": "Arrondir, et écrire les nombres",
		"exercises": [
			# Arrondir à la dizaine près.
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 47 à la dizaine près.", "answer": "50"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 62 à la dizaine près.", "answer": "60"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 85 à la dizaine près.", "answer": "90"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 34 à la dizaine près.", "answer": "30"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 76 à la dizaine près.", "answer": "80"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 18 à la dizaine près.", "answer": "20"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 53 à la dizaine près.", "answer": "50"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 91 à la dizaine près.", "answer": "90"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 25 à la dizaine près.", "answer": "30"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 68 à la dizaine près.", "answer": "70"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 72 à la dizaine près.", "answer": "70"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 39 à la dizaine près.", "answer": "40"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 84 à la dizaine près.", "answer": "80"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 57 à la dizaine près.", "answer": "60"},
			{"kind": "nombre", "part": "Arrondir à la dizaine", "show": "Arrondis 96 à la dizaine près.", "answer": "100"},
			# Arrondir à la centaine près.
			{"kind": "nombre", "part": "Arrondir à la centaine", "show": "Arrondis 240 à la centaine près.", "answer": "200"},
			{"kind": "nombre", "part": "Arrondir à la centaine", "show": "Arrondis 370 à la centaine près.", "answer": "400"},
			{"kind": "nombre", "part": "Arrondir à la centaine", "show": "Arrondis 850 à la centaine près.", "answer": "900"},
			{"kind": "nombre", "part": "Arrondir à la centaine", "show": "Arrondis 612 à la centaine près.", "answer": "600"},
			{"kind": "nombre", "part": "Arrondir à la centaine", "show": "Arrondis 487 à la centaine près.", "answer": "500"},
			# Écrire en chiffres le nombre que la voix dit : les 70, 80, 90 et des centaines.
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre soixante-dix.", "answer": "70"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre soixante-douze.", "answer": "72"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre soixante-quinze.", "answer": "75"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre soixante-dix-huit.", "answer": "78"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre quatre-vingts.", "answer": "80"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre quatre-vingt-trois.", "answer": "83"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre quatre-vingt-sept.", "answer": "87"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre quatre-vingt-dix.", "answer": "90"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre quatre-vingt-quinze.", "answer": "95"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre quatre-vingt-dix-neuf.", "answer": "99"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre cent.", "answer": "100"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre cent quatre.", "answer": "104"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre cent vingt-cinq.", "answer": "125"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre deux cent cinquante.", "answer": "250"},
			{"kind": "nombre", "part": "Écrire les nombres", "show": "Écris le nombre que tu entends.",
				"say": "Écris le nombre trois cent douze.", "answer": "312"},
		],
	},
]


# ── The week in force ───────────────────────────────────────────

## The Monday of the week we are in, "AAAA-MM-JJ" (the week starts on Monday).
static func monday() -> String:
	var today := Time.get_date_dict_from_system()
	var unix := Time.get_unix_time_from_datetime_dict(today)
	# `weekday` is 0 on Sunday, so Sunday belongs to the week that began six days earlier.
	var weekday := int(today.get("weekday", 1))
	var back := 6 if weekday == 0 else weekday - 1
	return Time.get_date_string_from_unix_time(int(unix) - back * 86400)


## This week's homework: the last week given whose Monday has come, so a week nobody gave keeps the one before
## it. `{}` when there is nothing at all.
static func week() -> Dictionary:
	var here := monday()
	var out: Dictionary = {}
	for one: Dictionary in WEEKS:
		if str(one.from) <= here:
			out = one
	# Only weeks still to come: she does the first one anyway rather than have an empty desk.
	if out.is_empty() and not WEEKS.is_empty():
		out = WEEKS[0]
	return out


static func exercises() -> Array:
	return week().get("exercises", []) as Array


static func title() -> String:
	return str(week().get("title", ""))


## "Semaine du 2 novembre", for the page and the notebook.
static func week_text() -> String:
	var from := str(week().get("from", ""))
	var parts := from.split("-")
	if parts.size() < 3:
		return ""
	return "Semaine du %d %s" % [int(parts[2]), MONTHS[clampi(int(parts[1]) - 1, 0, 11)]]


# ── What she has done ───────────────────────────────────────────

# Her homework, week by week: {"2026-11-02": {"done": [0, 3], "paid": true}}. Saved with the game.
static func _all() -> Dictionary:
	if not GameState.flags.get(FLAG) is Dictionary:
		GameState.flags[FLAG] = {}
	return GameState.flags[FLAG]


static func _this_week() -> Dictionary:
	var all := _all()
	var from := str(week().get("from", "-"))
	if not all.get(from) is Dictionary:
		all[from] = {"done": [], "paid": false}
	return all[from]


## The week in its parts, in order: [{name, count, done}] — what the notebook lists.
static func parts() -> Array:
	var out: Array = []
	var list := exercises()
	for i in list.size():
		var name := str((list[i] as Dictionary).get("part", title()))
		if out.is_empty() or str((out[-1] as Dictionary).name) != name:
			out.append({"name": name, "count": 0, "done": 0})
		var part: Dictionary = out[-1]
		part["count"] = int(part.count) + 1
		if is_done(i):
			part["done"] = int(part.done) + 1
	return out


static func is_done(i: int) -> bool:
	for k in _this_week().get("done", []) as Array:
		if int(k) == i:
			return true
	return false


static func done_count() -> int:
	var n := 0
	for i in exercises().size():
		if is_done(i):
			n += 1
	return n


static func all_done() -> bool:
	return not exercises().is_empty() and done_count() == exercises().size()


## The first exercise she still has to do, or -1 when the week is finished.
static func next_one() -> int:
	for i in exercises().size():
		if not is_done(i):
			return i
	return -1


static func mark_done(i: int) -> void:
	if not is_done(i):
		(_this_week()["done"] as Array).append(i)


## Pays the week's reward, once. Returns what it put in her pocket (0.0 if it was already paid).
static func pay() -> float:
	var mine := _this_week()
	if not all_done() or bool(mine.get("paid", false)):
		return 0.0
	mine["paid"] = true
	GameState.money += REWARD
	return REWARD


## Starts the week over, to practise again. What it paid stays paid: a week is only ever worth REWARD once.
static func forget() -> void:
	var mine := _this_week()
	mine["done"] = []


# ── Her answer ──────────────────────────────────────────────────

## "bon" (right), "presque" (right but for the accents) or "non".
static func check(exercise: Dictionary, given: String) -> String:
	var answers: Array = exercise.answer if exercise.answer is Array else [exercise.answer]
	for one in answers:
		if _plain(str(one)) == _plain(given):
			return "bon"
	for one in answers:
		if _folded(str(one)) == _folded(given):
			return "presque"
	return "non"


## The first right answer, written properly: what the page shows her once she has it.
static func answer_text(exercise: Dictionary) -> String:
	var answers: Array = exercise.answer if exercise.answer is Array else [exercise.answer]
	return str(answers[0]) if not answers.is_empty() else ""


# Down to the letters and the digits: the case, the spaces and the punctuation don't count.
static func _plain(s: String) -> String:
	var out := ""
	for ch in s.strip_edges().to_lower():
		if ch == " " or ch == "-" or ch == "'" or ch == "." or ch == "," or ch == "!" or ch == "?":
			continue
		out += ch
	return out


# The same thing with the accents taken off, so a word written without them is still nearly right.
static func _folded(s: String) -> String:
	var out := _plain(s)
	for pair in [["àáâä", "a"], ["éèêë", "e"], ["îïì", "i"], ["ôöò", "o"], ["ùûü", "u"], ["ç", "c"]]:
		for ch in str(pair[0]):
			out = out.replace(ch, str(pair[1]))
	return out
