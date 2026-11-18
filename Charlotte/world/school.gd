class_name School
extends RefCounted
## The first day at school (quest "ecole", in winter after Halloween), step by step:
##   1. Maman gave it (`house.gd _talk_to_mom`): she waits for Charlotte at the front door, and the door leads to the school
##      ("Maman t'accompagne à l'école…"), not to the street: at seven Charlotte may not cross Dandurand by herself;
##   2. the schoolyard at recess (`scenes/cour_ecole.gd`): Maman says goodbye at the gate and goes; Alyzée, new at school,
##      sits alone on a bench; Charlotte goes and says hello, they play tag (`Alyzee`), the bell rings;
##   3. "Après l'école…": Maman takes her home, and when Charlotte goes and tells her about her new friend in the kitchen the
##      quest is done (`house.gd _tell_mom_about_school`).
## The step is `GameState.flags.ecole_step`; meeting Alyzée is `flags.met_alyzee` (the notebook's friends page).

const QUEST := "ecole"
const STEP := "ecole_step"
const YARD := "res://scenes/cour_ecole.tscn"
## Set as she leaves the yard for home: the house has her say she can't wait to tell Maman, and Maman call her (once).
static var just_home := false
## What the notes of its steps are headed with (Notebook.announce).
const HEADING := "🏫  L'école"


## 0 = not started (or done), else the step she is on (1 for a quest switched on by the debug menu).
static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## The recess is over and she may go: she has met Alyzée (or she isn't there for the quest at all).
static func can_leave() -> bool:
	return step() != 2 or Alyzee.met()


## What the notebook says to do next.
static func hint() -> String:
	match step():
		1:
			return "Maman t'attend à la porte d'en avant, dans le vestibule, pour t'amener à l'école."
		2:
			return "C'est la récré ! Va jouer dans la cour. Quelqu'un est peut-être tout seul…"
		3:
			return "Va raconter ta journée d'école à Maman, dans la cuisine !"
	return str(Quests.ALL[QUEST].hint)
