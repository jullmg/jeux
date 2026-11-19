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
const YARD := "res://scenes/cour_ecole.tscn"
const CLASS := "res://scenes/classe.tscn"
const GARDE := "res://scenes/service_de_garde.tscn"
const HOME := "res://scenes/house.tscn"
## Where she comes in at home (the vestibule).
const HOME_X := 300.0
## What the notes of its steps are headed with (Notebook.announce).
const HEADING := "🏫  L'école"
const TEACHER := "Madame Nadia"
## How many questions a lesson has.
const PER_LESSON := 3

## Madame Nadia's questions at the board: what she says, the right answer first, then the wrong ones (shuffled on the card).
## Grade one and two: counting, letters and sounds, rhymes, the seasons, animals, Montréal and Québec.
const LESSONS := [
	["Combien font 3 + 4 ?", "7", "6", "8"],
	["Combien font 10 − 3 ?", "7", "6", "13"],
	["Combien font 5 + 5 ?", "10", "55", "9"],
	["Combien font 2 + 6 ?", "8", "4", "9"],
	["Combien de pattes a une araignée ?", "8", "6", "4"],
	["Combien de côtés a un triangle ?", "3", "4", "5"],
	["Combien y a-t-il de jours dans une semaine ?", "7", "5", "10"],
	["Quelle lettre vient après B ?", "C", "D", "A"],
	["Quel mot commence par le son « ch » ?", "chat", "rat", "lune"],
	["Quel mot rime avec « bateau » ?", "gâteau", "maison", "soleil"],
	["Quel mot rime avec « souris » ?", "tapis", "chaise", "pomme"],
	["Quel est le pluriel de « un cheval » ?", "des chevaux", "des chevals", "des chevaus"],
	["Quelle saison vient après l'automne ?", "l'hiver", "l'été", "le printemps"],
	["En quelle saison les feuilles tombent-elles ?", "l'automne", "l'été", "l'hiver"],
	["Quel animal pond des œufs ?", "la poule", "le chat", "la vache"],
	["Quel animal fait « meuh » ?", "la vache", "le mouton", "le cochon"],
	["Comment s'appelle la montagne au milieu de Montréal ?", "le mont Royal", "le mont Blanc", "le mont Everest"],
	["De quelles couleurs est le drapeau du Québec ?", "bleu et blanc", "rouge et blanc", "vert et jaune"],
	["Que fait-on quand le feu est rouge ?", "on s'arrête", "on traverse", "on court"],
	["Quel fruit est jaune et courbé ?", "la banane", "la fraise", "le raisin"],
]


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


## Today's questions: ones she hasn't had yet, as long as there are; the order of the answers shuffled.
static func lesson(rng: RandomNumberGenerator) -> Array:
	var seen: Array = GameState.flags.get(SEEN, [])
	var fresh: Array = []
	for i in LESSONS.size():
		if not seen.has(i):
			fresh.append(i)
	if fresh.size() < PER_LESSON:
		seen = []
		fresh = range(LESSONS.size())
	var out: Array = []
	for k in PER_LESSON:
		var i: int = fresh.pop_at(rng.randi_range(0, fresh.size() - 1))
		seen.append(i)
		var q: Array = LESSONS[i]
		var answers: Array = q.slice(1)
		var right: String = answers[0]
		answers.shuffle()
		out.append({"ask": q[0], "answers": answers, "right": answers.find(right)})
	GameState.flags[SEEN] = seen
	return out


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
